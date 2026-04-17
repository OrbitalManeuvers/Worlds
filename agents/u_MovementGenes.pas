unit u_MovementGenes;

interface

uses u_AgentTypes, u_AgentGenome;

type
  TMoveEvaluator = class(TMoveEvalGene)
    class function Evaluate(const Input: TMoveEvalInput; var Scratch: TMoveEvalScratch): TActionEvalResult; override;
  end;

implementation

uses u_EnvironmentTypes;

{ TMoveEvaluator }

class function TMoveEvaluator.Evaluate(const Input: TMoveEvalInput; var Scratch: TMoveEvalScratch): TActionEvalResult;
begin
  Scratch := Default(TMoveEvalScratch);
  Result := Default(TActionEvalResult);
  Result.Score := 0.0;
  Result.Target.TType := ttNone;

  if Input.Smell.Count <= 0 then
    Exit;

  // Movement is only interesting when food is not in the current cell.
  for var detail in Input.Smell.Details do
  begin
    if detail.Directions.Distance = 0 then
      Continue;

    var targetSignal := 0.0;
    for var molecule := Low(TMolecule) to High(TMolecule) do
      targetSignal := targetSignal + detail.MoleculeStrength[molecule];

    if targetSignal > Result.Score then
    begin
      Result.Score := targetSignal;
      Result.Target.TType := ttCell;
      Result.Target.Cell := detail.CellIndex;
    end;

    // Preserve a small remote-move affordance when composition exists but strengths are near zero.
    if (targetSignal = 0.0) and (detail.MoleculesPresent <> []) and (Result.Score < 0.01) then
    begin
      Result.Score := 0.01;
      Result.Target.TType := ttCell;
      Result.Target.Cell := detail.CellIndex;
    end;
  end;

end;

initialization
  GlobalGeneRegistry.RegisterGene(TMoveEvaluator);


end.
