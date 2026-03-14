unit u_SimClocks;

interface

uses System.Classes;

const
  CLOCK_TICKS_PER_DAY = 100;
  NIGHT_TICKS_NUMERATOR = 1;
  NIGHT_TICKS_DENOMINATOR = 5; // 20% of the day is night by default
  NIGHT_TICKS_PER_DAY = (CLOCK_TICKS_PER_DAY * NIGHT_TICKS_NUMERATOR) div NIGHT_TICKS_DENOMINATOR;
  DAYLIGHT_TICKS_PER_DAY = CLOCK_TICKS_PER_DAY - NIGHT_TICKS_PER_DAY;

type
  TClockTick = 0 .. (CLOCK_TICKS_PER_DAY - 1);
  TDaylightTicks = 0 .. (DAYLIGHT_TICKS_PER_DAY - 1);

  TSimClock = class
  public type
    TTimeSlice = record
      DayNumber: Integer;
      ClockTick: TClockTick;
    end;
    TControllerCallback = procedure (Sender: TObject; const CurrentTime: TTimeSlice; var CanContinue: Boolean) of object;
  private
    fDayNumber: Cardinal;
    fDayTick: TClockTick;
    fStopped: Boolean;
    fController: TControllerCallback;
    fOnDayChange: TNotifyEvent;
    fOnTickChange: TNotifyEvent;
    procedure Callback;
  public
    constructor Create(aController: TControllerCallback);
    destructor Destroy; override;

    procedure Reset;
    procedure Stop;
    procedure SetDate(aDayNumber: Cardinal; aDayTick: TClockTick = 0);

    procedure Step;
    procedure StepToTomorrow;
    procedure RunTo(aDayNumber: Cardinal; aDayTick: TClockTick = 0);

    property DayNumber: Cardinal read fDayNumber;
    property Tick: TClockTick read fDayTick;

//    property OnTickChange: TNotifyEvent read fOnTickChange write fOnTickChange;
//    property OnDayChange: TNotifyEvent read fOnDayChange write fOnDayChange;
  end;

implementation

{ TSimClock }

constructor TSimClock.Create(aController: TControllerCallback);
begin
  inherited Create;
  fController := aController;
  Reset;
end;

destructor TSimClock.Destroy;
begin
  //
  inherited;
end;

procedure TSimClock.Reset;
begin
  fDayNumber := 0;
  fDayTick := 0;
  fStopped := False;
end;

procedure TSimClock.Callback;
begin
  if Assigned(fController) then
  begin
    var canContinue := True;
    var current: TTimeSlice;
    current.DayNumber := fDayNumber;
    current.ClockTick := fDayTick;
    fController(Self, current, canContinue);
    if not canContinue then
      fStopped := True;
  end;
end;

procedure TSimClock.RunTo(aDayNumber: Cardinal; aDayTick: TClockTick);
begin
  //

end;

procedure TSimClock.SetDate(aDayNumber: Cardinal; aDayTick: TClockTick);
begin
  fDayNumber := aDayNumber;
  fDayTick := aDayTick;
end;

procedure TSimClock.Step;
begin
  if fDayTick < High(TClockTick) then
  begin
    Inc(fDayTick);
    if Assigned(fOnTickChange) then
      fOnTickChange(Self);
  end
  else
  begin
    Inc(fDayNumber);
    fDayTick := 0;
    if Assigned(fOnDayChange) then
      fOnDayChange(Self);
  end;

  Callback;
end;

procedure TSimClock.StepToTomorrow;
begin

  // !! untested
  var tuhDay := fDayNumber;
  while (not fStopped) and (fDayNumber = tuhDay) do
    Step;

end;

procedure TSimClock.Stop;
begin
  fStopped := True;
end;

end.
