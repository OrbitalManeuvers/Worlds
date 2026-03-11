unit u_SimRuntimes;

interface

uses u_SimEnvironments, u_SimPopulations;

type
  TSimRuntime = class
  private
    fEnvironment: TSimEnvironment;
    fPopulation: TSimPopulation;
  public
    constructor Create;
    destructor Destroy; override;

    property Environment: TSimEnvironment read fEnvironment;
    property Population: TSimPopulation read fPopulation;
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

end.
