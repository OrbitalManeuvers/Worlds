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

{ TBasicShelter }

class function TShelterEvaluator.Evaluate(const Input: TShelterEvalInput; var Scratch: TShelterEvalScratch): TActionEvalResult;
begin
  Scratch := Default(TShelterEvalScratch);
  Result.Score := 0.0;

  if Input.IsNight then
    Result.Score := Result.Score + 0.10
  else
    Result.Score := Result.Score - 0.06;

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
      Result.Score := Result.Score + 0.04;
  end;

  if Input.CurrentAction = acShelter then
  begin
    // Shelter persistence should be strong, but break quickly on daylight or deep energy deficit.
    Result.Score := Result.Score + 0.12;

    if not Input.IsNight then
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
