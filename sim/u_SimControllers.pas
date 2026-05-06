unit u_SimControllers;

interface

uses System.Classes, System.Generics.Collections,
  u_MulticastEvents,
  u_SimClocks, u_EventSinkIntf, u_SimDiagnosticsIntf;

// The TSimController will be created/owned by TSimSession and a property
// of the session. Session.Step will go away eventually

type
  TSimDate = record
    DayNumber: Cardinal;
    DayTick: TDayTick;

    function NextSunrise: TSimDate;
    function NextSunset: TSimDate;
    function AddTicks(aCount: Cardinal): TSimDate;
  end;

  TSimStopPredicate = reference to procedure (const Date: TSimDate; var CanContinue: Boolean);

  TSegment = record
    StartTime: TSimDate;
    EndTime: TSimDate;
    EndEvents: TSimEventKinds;  // empty = time-only end condition
    Recording: Boolean;
  end;

  TPlaylist = TList<TSegment>;

  TSimController = class
  private
    fClock: TSimClock;
//    fDiagnostics: ISimDiagnosticsSink;
    fRecording: Boolean;
    fRunning: Boolean;
    fCurrentSegmentIndex: Integer;
    fEndEventFired: Boolean;
    fActiveEndEvents: TSimEventKinds;
    fBeforeAdvance: TMulticastEvent<TNotifyEvent>;
    fAfterAdvance: TMulticastEvent<TNotifyEvent>;

    procedure NotifyBeforeAdvance;
    procedure NotifyAfterAdvance;
    function GetCurrentDate: TSimDate;

  public
    constructor Create(aClock: TSimClock);
    destructor Destroy; override;

    procedure Step(Recording: Boolean = False);

    // there is no unbounded run yet, caller provides a stopping mechanism
    procedure Run(aStop: TSimStopPredicate; Recording: Boolean = False);

    // playlist specifies stop definition, optionally provide alternate method
    procedure RunPlaylist(const aPlaylist: TPlaylist; aStop: TSimStopPredicate = nil);

    property CurrentDate: TSimDate read GetCurrentDate;
    property BeforeAdvance: TMulticastEvent<TNotifyEvent> read fBeforeAdvance;
    property AfterAdvance: TMulticastEvent<TNotifyEvent> read fAfterAdvance;
  end;

implementation


{ TSimController }

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
begin
  Assert(not fRunning, 'TSimController.Run called while controller is already running.');
  //
end;

procedure TSimController.RunPlaylist(const aPlaylist: TPlaylist; aStop: TSimStopPredicate);
var
  canContinue: Boolean;
  date: TSimDate;
begin
  Assert(not fRunning, 'TSimController.RunPlaylist called while controller is already running.');
  Assert(Assigned(aPlaylist) and (aPlaylist.Count > 0));

  fRunning := True;
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
      fActiveEndEvents := seg.EndEvents;
      fRecording := seg.Recording;

      // run ticks until EndTime or EndEvents fires
      while not fEndEventFired do
      begin
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

        NotifyBeforeAdvance;
        fClock.Step;
        NotifyAfterAdvance;
      end;

      fRecording := False;
      fEndEventFired := False;
    end;
  finally
    fRunning := False;
    fRecording := False;
    fCurrentSegmentIndex := -1;
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

{ TSimDate }

function TSimDate.AddTicks(aCount: Cardinal): TSimDate;
var
  totalTick: UInt64;
begin
  totalTick := UInt64(DayNumber) * CLOCK_TICKS_PER_DAY + DayTick + aCount;
  Result.DayNumber := Cardinal(totalTick div CLOCK_TICKS_PER_DAY);
  Result.DayTick   := TDayTick(totalTick mod CLOCK_TICKS_PER_DAY);
end;

function TSimDate.NextSunrise: TSimDate;
begin
  // Sunrise is tick 0 of the next day
  Result.DayNumber := DayNumber + 1;
  Result.DayTick   := 0;
end;

function TSimDate.NextSunset: TSimDate;
begin
  // Sunset is the first night tick (DAYLIGHT_TICKS_PER_DAY) of the current day.
  // If we're already at or past sunset, advance to the next day's sunset.
  if DayTick < DAYLIGHT_TICKS_PER_DAY then
  begin
    Result.DayNumber := DayNumber;
    Result.DayTick   := DAYLIGHT_TICKS_PER_DAY;
  end
  else
  begin
    Result.DayNumber := DayNumber + 1;
    Result.DayTick   := DAYLIGHT_TICKS_PER_DAY;
  end;
end;

end.
