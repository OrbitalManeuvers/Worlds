unit u_EnergyGenes;

interface

uses u_AgentGenome, u_AgentTypes;

type
  TBasicEnergy = class(TEnergyGene)
  public
    class function EvaluateEnergyLevel(const Input: TEnergyInput): TEnergyLevel; override;
  end;

implementation

{ TBasicEnergy }

class function TBasicEnergy.EvaluateEnergyLevel(const Input: TEnergyInput): TEnergyLevel;
begin
  if Input.Reserves <= 0.0 then
    Exit(elEmpty);

  if Input.Reserves < 25.0 then
    Exit(elLow);

  if Input.Reserves < 50.0 then
    Exit(elMedium);

  if Input.Reserves < 75.0 then
    Exit(elHigh);

  Result := elFull;
end;

initialization
  GlobalGeneRegistry.RegisterGene(TBasicEnergy);

end.
