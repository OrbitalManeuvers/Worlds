unit u_SimRuntimes;

interface

uses u_SimEnvironments, u_SimPopulations, u_SimClocks;

type
  TSimRuntime = class
  private
    fEnvironment: TSimEnvironment;
    fPopulation: TSimPopulation;
    procedure SetClockTick(const Value: TClockTick);
  public
    constructor Create;
    destructor Destroy; override;

    property Environment: TSimEnvironment read fEnvironment;
    property Population: TSimPopulation read fPopulation;
    property ClockTick: TClockTick write SetClockTick;
  end;

implementation

{ TSimRuntime }

constructor TSimRuntime.Create;
begin
  inherited;
  fEnvironment := TSimEnvironment.Create;
  fPopulation := TSimPopulation.Create;
end;

destructor TSimRuntime.Destroy;
begin
  fEnvironment.Free;
  fPopulation.Free;
  inherited;
end;

procedure TSimRuntime.SetClockTick(const Value: TClockTick);
begin
  fEnvironment.ClockTick := Value;
end;

end.
