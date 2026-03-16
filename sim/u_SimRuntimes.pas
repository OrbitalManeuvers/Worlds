unit u_SimRuntimes;

interface

uses u_SimEnvironments, u_SimPopulations, u_SimClocks;

type
  TSimRuntime = class
  private
    fEnvironment: TSimEnvironment;
    fPopulation: TSimPopulation;
    procedure SetDayTick(const Value: TDayTick);
  public
    constructor Create;
    destructor Destroy; override;

    property Environment: TSimEnvironment read fEnvironment;
    property Population: TSimPopulation read fPopulation;
    property DayTick: TDayTick write SetDayTick;
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

procedure TSimRuntime.SetDayTick(const Value: TDayTick);
begin
  fEnvironment.DayTick := Value;
end;

end.
