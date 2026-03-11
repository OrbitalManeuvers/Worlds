unit u_SimClocks;

interface

uses System.Classes;

type
  TClockCallback = procedure (Sender: TObject; var CanContinue: Boolean) of object;

  TSimClock = class
  private type
    TDayTick = 0 .. 99;
  private
    fDayNumber: Cardinal;
    fDayTick: TDayTick;
    fStopped: Boolean;
    fCallback: TClockCallback;
    fOnDayChange: TNotifyEvent;
    fOnTickChange: TNotifyEvent;
    procedure Callback;
  public
    constructor Create(aCallback: TClockCallback);
    destructor Destroy; override;

    procedure Reset;
    procedure Stop;
    procedure SetDate(aDayNumber: Cardinal; aDayTick: TDayTick = 0);

    procedure Step;
    procedure StepToTomorrow;
    procedure RunTo(aDayNumber: Cardinal; aDayTick: TDayTick = 0);

    property DayNumber: Cardinal read fDayNumber;
    property DayTick: TDayTick read fDayTick;

    property OnTickChange: TNotifyEvent read fOnTickChange write fOnTickChange;
    property OnDayChange: TNotifyEvent read fOnDayChange write fOnDayChange;
  end;

implementation

{ TSimClock }

constructor TSimClock.Create(aCallback: TClockCallback);
begin
  inherited Create;
  fCallback := aCallback;
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
  if Assigned(fCallback) then
  begin
    var canContinue := True;
    fCallback(Self, canContinue);
    if not canContinue then
      fStopped := True;
  end;
end;

procedure TSimClock.RunTo(aDayNumber: Cardinal; aDayTick: TDayTick);
begin
  //

end;

procedure TSimClock.SetDate(aDayNumber: Cardinal; aDayTick: TDayTick);
begin
  fDayNumber := aDayNumber;
  fDayTick := aDayTick;
end;

procedure TSimClock.Step;
begin
  if fDayTick < High(TDayTick) then
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

end;

procedure TSimClock.Stop;
begin
  fStopped := True;
end;

end.
