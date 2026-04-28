unit u_ForagingGenes;

interface

uses u_AgentTypes, u_AgentGenome, u_SimQueriesIntf;

type
  TForageEvaluator = class(TForageEvalGene)
    class function Evaluate(const Input: TForageEvalInput; var Scratch: TForageEvalScratch): TActionEvalResult; override;
  end;


implementation

uses u_EnvironmentTypes;

{ TForagingGene }

class function TForageEvaluator.Evaluate(const Input: TForageEvalInput; var Scratch: TForageEvalScratch): TActionEvalResult;
begin
  Scratch := Default(TForageEvalScratch);
  Result := Default(TActionEvalResult);
  Result.Score := 0.0;
  Result.Target.TType := ttNone;

  if Input.Smell.Count <= 0 then
    Exit;

  // Foraging is local-only. Remote food should influence movement, not forage-now.
  for var detail in Input.Smell.Details do
  begin
    if detail.Directions.Distance <> 0 then
      Continue;

    var targetSignal := 0.0;
    for var molecule := Low(TMolecule) to High(TMolecule) do
      targetSignal := targetSignal + detail.MoleculeStrength[molecule];

    if targetSignal > Result.Score then
    begin
      Result.Score := targetSignal;
      Result.Target.TType := ttCache;
      Result.Target.Cache := detail.Cache;
    end;

    // Keep legacy/noise-tolerant behavior if strengths are absent.
    if (targetSignal = 0.0) and (detail.MoleculesPresent <> []) then
      if Result.Score < 0.01 then
        Result.Score := 0.01;

    if Result.Score >= 1.0 then
      Break;
  end;

  // Keep a tiny local affordance when a local cache is present but strengths are not populated yet.
  if (Result.Score = 0.0) and (Length(Input.Smell.Details) > 0) then
    for var detail in Input.Smell.Details do
      if detail.Directions.Distance = 0 then
      begin
        Result.Score := 0.01;
        Result.Target.TType := ttCache;
        Result.Target.Cache := detail.Cache;
        Break;
      end;

  // Discount forage urgency when reserves are already high � other actions can outcompete.
  case Input.EnergyLevel of
    elFull: Result.Score := Result.Score * 0.2;
    elHigh: Result.Score := Result.Score * 0.6;
  end;
end;

initialization
  GlobalGeneRegistry.RegisterGene(TForageEvaluator);

end.
