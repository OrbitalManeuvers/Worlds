unit u_SimControllers;

interface

uses System.Classes, System.Generics.Collections,
  u_MulticastEvents,
  u_SimClocks, u_SimTypes, u_Playlists;

type
  TSimStopPredicate = reference to procedure (const Date: TSimDate; var CanContinue: Boolean);


  TSimController = class
  private
    fClock: TSimClock;
    fRecording: Boolean;
    fRunning: Boolean;
    fCurrentSegmentIndex: Integer;
    fEndEventFired: Boolean;
    fOnBeforeRun: TNotifyEvent;
    fOnAfterRun: TNotifyEvent;
    fBeforeAdvance: TMulticastEvent<TNotifyEvent>;
    fAfterAdvance: TMulticastEvent<TNotifyEvent>;

    procedure BeforeRun;
    procedure AfterRun;
    procedure NotifyBeforeAdvance;
    procedure NotifyAfterAdvance;
    function GetCurrentDate: TSimDate;

  public
    constructor Create(aClock: TSimClock);
    destructor Destroy; override;

    procedure Step(Recording: Boolean = False);

    // there is no unbounded run yet, caller must provide a stopping mechanism
    procedure Run(aStop: TSimStopPredicate; Recording: Boolean = False);

    // playlist specifies stop definition, optionally provide alternate method
    procedure RunPlaylist(const aPlaylist: TPlaylist; aStop: TSimStopPredicate = nil);

    // these bracket Run() and RunPlaylist()
    property OnBeforeRun: TNotifyEvent read fOnBeforeRun write fOnBeforeRun;
    property OnAfterRun: TNotifyEvent read fOnAfterRun write fOnAfterRun;

    property CurrentDate: TSimDate read GetCurrentDate;
    property BeforeAdvance: TMulticastEvent<TNotifyEvent> read fBeforeAdvance;
    property AfterAdvance: TMulticastEvent<TNotifyEvent> read fAfterAdvance;
  end;

implementation


{ TSimController }

procedure TSimController.AfterRun;
begin
  if Assigned(fOnAfterRun) then
    fOnAfterRun(Self);
end;

procedure TSimController.BeforeRun;
begin
  if Assigned(fOnBeforeRun) then
    fOnBeforeRun(Self);
end;

constructor TSimController.Create(aClock: TSimClock);
begin
  inherited Create;
  fClock := aClock;
  fBeforeAdvance := TMulticastEvent<TNotifyEvent>.Create;
  fAfterAdvance := TMulticastEvent<TNotifyEvent>.Create;
end;

destructor TSimController.Destroy;
begin
  fAfterAdvance.Free;
  fBeforeAdvance.Free;

  inherited;
end;

function TSimController.GetCurrentDate: TSimDate;
begin
  Result.DayNumber := fClock.DayNumber;
  Result.DayTick   := fClock.DayTick;
end;

procedure TSimController.NotifyBeforeAdvance;
begin
  fBeforeAdvance.Notify(
    procedure(Handler: TNotifyEvent)
    begin
      Handler(Self);
    end
  );
end;

procedure TSimController.NotifyAfterAdvance;
begin
  fAfterAdvance.Notify(
    procedure(Handler: TNotifyEvent)
    begin
      Handler(Self);
    end
  );
end;

procedure TSimController.Run(aStop: TSimStopPredicate; Recording: Boolean);
var
  canContinue: Boolean;
  date: TSimDate;
begin
  Assert(not fRunning, 'TSimController.Run called while controller is already running.');
  Assert(Assigned(aStop), 'TSimController.Run requires a stop predicate.');

  fRunning := True;
  fRecording := Recording;
  BeforeRun;
  try
    while True do
    begin
      NotifyBeforeAdvance;
      fClock.Step;
      NotifyAfterAdvance;

      date.DayNumber := fClock.DayNumber;
      date.DayTick := fClock.DayTick;

      canContinue := True;
      aStop(date, canContinue);
      if not canContinue then
        Break;
    end;
  finally
    AfterRun;
    fRunning := False;
    fRecording := False;
  end;
end;

procedure TSimController.RunPlaylist(const aPlaylist: TPlaylist; aStop: TSimStopPredicate);
var
  canContinue: Boolean;
  date: TSimDate;
begin
  Assert(not fRunning, 'TSimController.RunPlaylist called while controller is already running.');
  Assert(Assigned(aPlaylist) and (aPlaylist.Count > 0));

  fRunning := True;
  BeforeRun;
  try
    for var segIndex := 0 to aPlaylist.Count - 1 do
    begin
      var seg := aPlaylist[segIndex];
      Assert(
        (seg.EndTime.DayNumber > seg.StartTime.DayNumber) or
        ((seg.EndTime.DayNumber = seg.StartTime.DayNumber) and (seg.EndTime.DayTick >= seg.StartTime.DayTick)),
        'TSegment.EndTime must be >= StartTime.'
      );

      fCurrentSegmentIndex := segIndex;
      fEndEventFired := False;
      fRecording := seg.Recording;

      // run ticks until EndTime or EndEvents fires
      while not fEndEventFired do
      begin
        NotifyBeforeAdvance;
        fClock.Step;
        NotifyAfterAdvance;

        date.DayNumber := fClock.DayNumber;
        date.DayTick := fClock.DayTick;

        // check time-based end condition
        if (date.DayNumber > seg.EndTime.DayNumber) or
           ((date.DayNumber = seg.EndTime.DayNumber) and (date.DayTick >= seg.EndTime.DayTick)) then
          Break;

        // check predicate-based abort
        if Assigned(aStop) then
        begin
          canContinue := True;
          aStop(date, canContinue);
          if not canContinue then
            Exit;  // abort entire playlist
        end;
      end;

      fRecording := False;
      fEndEventFired := False;
    end;
  finally
    fRunning := False;
    fRecording := False;
    fCurrentSegmentIndex := -1;
    AfterRun;
  end;
end;

procedure TSimController.Step(Recording: Boolean);
begin
  Assert(not fRunning, 'TSimController.Step called while controller is already running.');
  NotifyBeforeAdvance;

  fRecording := Recording;
  try
    fClock.Step;
  finally
    fRecording := False;
  end;

  NotifyAfterAdvance;
end;


end.
