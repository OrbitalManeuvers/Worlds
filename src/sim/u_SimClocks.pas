unit u_SimClocks;

interface

uses
  System.Classes, System.Generics.Collections,
  u_MulticastEvents, u_SimTypes;

type
  TClockInfo = record
    GlobalTick: Integer;
    DayNumber: Integer;
    DayTick: TDayTick;
    IsNight: Boolean;
  end;

  TClockTickEvent = procedure (Sender: TObject; GlobalTick: Integer; DayTick: TDayTick) of object;

  TSimClock = class
  public type
    TClockControlEvent = procedure (Sender: TObject; const NextTick: Integer; var CanContinue: Boolean) of object;
  private
    fTick: Integer;
    fStopped: Boolean;
    fOnControl: TClockControlEvent;
    fTickEvent: TMulticastEvent<TClockTickEvent>;
    procedure Callback;
    procedure NotifyTick;
    function GetDayTick: TDayTick;
    function GetDayNumber: Integer;
  public
    constructor Create(aController: TClockControlEvent);
    destructor Destroy; override;

    procedure SubscribeTick(const AHandler: TClockTickEvent);
    procedure UnsubscribeTick(const AHandler: TClockTickEvent);
    procedure ClearTickSubscribers;

    procedure Step;
    procedure Stop;

    property Tick: Integer read fTick;
    property DayTick: TDayTick read GetDayTick;
    property DayNumber: Integer read GetDayNumber;
  end;

implementation

{ TSimClock }

constructor TSimClock.Create(aController: TClockControlEvent);
begin
  inherited Create;
  fTickEvent := TMulticastEvent<TClockTickEvent>.Create;
  fOnControl := aController;
  FTick := CLOCK_TICKS_PER_DAY; // clock starts
end;

destructor TSimClock.Destroy;
begin
  fTickEvent.Free;
  inherited;
end;

procedure TSimClock.SubscribeTick(const AHandler: TClockTickEvent);
begin
  fTickEvent.Subscribe(aHandler);
end;

procedure TSimClock.UnsubscribeTick(const AHandler: TClockTickEvent);
begin
  fTickEvent.Unsubscribe(aHandler);
end;

procedure TSimClock.ClearTickSubscribers;
begin
  fTickEvent.Clear;
end;

function TSimClock.GetDayNumber: Integer;
begin
  Result := fTick div CLOCK_TICKS_PER_DAY;
end;

function TSimClock.GetDayTick: TDayTick;
begin
  Result := fTick mod CLOCK_TICKS_PER_DAY;
end;

procedure TSimClock.NotifyTick;
begin
  fTickEvent.Notify(
    procedure(Handler: TClockTickEvent)
    begin
      Handler(Self, fTick, DayTick);
    end
  );
end;

procedure TSimClock.Callback;
begin
  if Assigned(fOnControl) then
  begin
    var canContinue := True;
    fOnControl(Self, fTick + 1, canContinue);
    if not canContinue then
      fStopped := True;
  end;
end;

procedure TSimClock.Step;
begin
  Inc(fTick);
  Callback;
  NotifyTick;
end;

procedure TSimClock.Stop;
begin
  fStopped := True;
end;

end.
