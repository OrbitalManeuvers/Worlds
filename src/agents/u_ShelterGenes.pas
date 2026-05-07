unit u_ShelterGenes;

interface

uses u_AgentTypes, u_AgentGenome, u_SimQueriesIntf;

type
  TShelterEvaluator = class(TShelterEvalGene)
  public
    class function Evaluate(const Input: TShelterEvalInput; var Scratch: TShelterEvalScratch): TActionEvalResult; override;
  end;


implementation

uses System.Math;

const
  SHELTER_FLUX_DELTA_PRESSURE = 2.0;
  SHELTER_WAKE_FLUX_THRESHOLD = 0.08;

{ TBasicShelter }

class function TShelterEvaluator.Evaluate(const Input: TShelterEvalInput; var Scratch: TShelterEvalScratch): TActionEvalResult;
begin
  Scratch := Default(TShelterEvalScratch);
  Result.Score := 0.0;

  var flux := EnsureRange(Input.SolarFlux, 0.0, 1.0);
  var darkness := 1.0 - flux;

  // Darker conditions increase shelter pull; brighter conditions reduce it.
  Result.Score := Result.Score + (darkness * 0.12) - (flux * 0.06);

  // Falling light increases shelter pressure; rising light increases wake pressure.
  Result.Score := Result.Score - (Input.SolarFluxDelta * SHELTER_FLUX_DELTA_PRESSURE);

  Result.Score := Result.Score + (Input.ThreatPressure * 0.60);

  case Input.EnergyLevel of
    elEmpty:
      Result.Score := Result.Score - 0.14;
    elLow:
      Result.Score := Result.Score - 0.05;
    elMedium:
      ;
    elHigh:
      Result.Score := Result.Score + 0.02;
    elFull:
      Result.Score := Result.Score + 0.06;
  end;

  if Input.CurrentAction = acShelter then
  begin
    // Shelter persistence should be strong, but break quickly on daylight or deep energy deficit.
    Result.Score := Result.Score + 0.12;

    if (flux >= SHELTER_WAKE_FLUX_THRESHOLD) and (Input.SolarFluxDelta >= 0.0) then
      Result.Score := Result.Score - 0.14;

    if Input.EnergyLevel in [elEmpty, elLow] then
      Result.Score := Result.Score - 0.10;
  end;

  Result.Score := EnsureRange(Result.Score, 0.0, 0.35);
  Result.Target.TType := ttNone;

end;

initialization
  GlobalGeneRegistry.RegisterGene(TShelterEvaluator);

end.
