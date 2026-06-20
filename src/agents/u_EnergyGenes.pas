unit u_EnergyGenes;

interface

uses u_AgentGenome, u_GeneTypes, u_RuntimeTypes, u_SimTypes;

type
  TBasicEnergy = class(TEnergyGene)
  public
    class function EvaluateEnergyLevel(const Input: TEnergyReserves): TEnergyLevel; override;
  end;

implementation

const
  // Reserve scale is currently tuned around agents starting near 10.0 reserves,
  // with per-tick upkeep and forage gains both around tenths.
  ENERGY_LOW_THRESHOLD = 2.5;
  ENERGY_MEDIUM_THRESHOLD = 5.0;
  ENERGY_HIGH_THRESHOLD = 8.0;

{ TBasicEnergy }

class function TBasicEnergy.EvaluateEnergyLevel(const Input: TEnergyReserves): TEnergyLevel;
begin
//  if Input.Reserves <= 0.0 then
//    Exit(elEmpty);

  if Input < ENERGY_LOW_THRESHOLD then
    Exit(elLow);

  if Input < ENERGY_MEDIUM_THRESHOLD then
    Exit(elMedium);

  if Input < ENERGY_HIGH_THRESHOLD then
    Exit(elHigh);

  Result := elFull;
end;

initialization
  GlobalGeneRegistry.RegisterGene(TBasicEnergy);

end.
