unit u_Simulators;

interface

uses u_SimClocks, u_SimDiagnosticsIntf, u_SimRuntimes;

type
  TSimulator = class
  private
    fClock: TSimClock;
    fRuntime: TSimRuntime;
    procedure ClockCallback(Sender: TObject; const NextTick: Cardinal; var CanContinue: Boolean);
    procedure ClockTickHandler(Sender: TObject; GlobalTick: Cardinal; DayTick: TDayTick);
  public
    constructor Create(const aDiagnostics: ISimDiagnosticsSink = nil);
    destructor Destroy; override;

    property Runtime: TSimRuntime read fRuntime;
    property Clock: TSimClock read fClock;
  end;

implementation


{ TSimulator }

constructor TSimulator.Create(const aDiagnostics: ISimDiagnosticsSink);
begin
  inherited Create;
  fClock := TSimClock.Create(ClockCallback);
  fClock.SubscribeTick(ClockTickHandler);
  fRuntime := TSimRuntime.Create(aDiagnostics);
end;

destructor TSimulator.Destroy;
begin
  fRuntime.Free;
  fClock.UnsubscribeTick(ClockTickHandler);
  fClock.Free;
  inherited;
end;

procedure TSimulator.ClockTickHandler(Sender: TObject; GlobalTick: Cardinal; DayTick: TDayTick);
begin
  fRuntime.AdvanceClock(GlobalTick, DayTick);
end;

procedure TSimulator.ClockCallback(Sender: TObject; const NextTick: Cardinal; var CanContinue: Boolean);
begin
  //
end;


end.
