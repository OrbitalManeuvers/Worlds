unit u_ShelterGenes;

interface

uses u_AgentTypes, u_AgentGenome, u_SimQueriesIntf;

type
  TBasicShelter = class(TShelterEvalGene)
  public
    class function Score(const Input: TShelterEvalInput; var Scratch: TShelterEvalScratch): Single; override;
  end;


implementation

uses System.Math;

{ TBasicShelter }

class function TBasicShelter.Score(const Input: TShelterEvalInput; var Scratch: TShelterEvalScratch): Single;
begin
  Scratch := Default(TShelterEvalScratch);
  Result := 0.0;

  if Input.IsNight then
    Result := Result + 0.08
  else
    Result := Result - 0.02;

  Result := Result + (Input.ThreatPressure * 0.60);

  case Input.EnergyLevel of
    elEmpty:
      Result := Result - 0.20;
    elLow:
      Result := Result - 0.10;
    elMedium:
      ;
    elHigh:
      Result := Result + 0.05;
    elFull:
      Result := Result + 0.10;
  end;

  if Input.CurrentAction = acShelter then
    Result := Result + 0.03;

  Result := EnsureRange(Result, 0.0, 0.35);

end;

initialization
  GlobalGeneRegistry.RegisterGene(TBasicShelter);

end.
