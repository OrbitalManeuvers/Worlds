unit u_MovementGenes;

interface

uses u_AgentTypes, u_AgentGenome;

type
  TMoveEvaluator = class(TMoveEvalGene)
  public
    class function BuildReport(const Input: TMoveEvalInput; var Scratch: TMoveEvalScratch): TMoveReport; override;
  end;

  TDebugMoveEvaluator = class(TMoveEvalGene)
  public
    class function GetGenerationCode: Char; override;
    class function BuildReport(const Input: TMoveEvalInput; var Scratch: TMoveEvalScratch): TMoveReport; override;
  end;

implementation

uses u_EnvironmentTypes;

type
  TMoveWeightMode = (mwUniform, mwLearned);

const
  // Distance discount: remote signals are divided by (1 + distance * factor).
  // A cell 2 away is worth signal/2.0, a cell 4 away is signal/3.0.
  MOVE_DISTANCE_COST_FACTOR = 0.50;

  // Learned molecule weights below this threshold are treated as zero.
  // Prevents near-zero asymptotic weights from creating phantom local food signals.
  MOVE_WEIGHT_EPSILON = 0.01;

function EvaluateMovement(const Input: TMoveEvalInput; var Scratch: TMoveEvalScratch;
  WeightMode: TMoveWeightMode): TMoveReport;

  procedure InsertMoveOption(const Cell: TCellIndex; const Distance: Word; const Opportunity: Single);
  begin
    if Opportunity <= 0.0 then
      Exit;

    // Deduplicate by cell, keeping the strongest opportunity for that cell.
    for var i := 0 to Result.Count - 1 do
      if Result.Options[i].Cell = Cell then
      begin
        if Opportunity <= Result.Options[i].Opportunity then
          Exit;

        Result.Options[i].Opportunity := Opportunity;
        Result.Options[i].Distance := Distance;

        var j := i;
        while (j > 0) and (Result.Options[j].Opportunity > Result.Options[j - 1].Opportunity) do
        begin
          var tmp := Result.Options[j - 1];
          Result.Options[j - 1] := Result.Options[j];
          Result.Options[j] := tmp;
          Dec(j);
        end;
        Exit;
      end;

    var insertAt := Result.Count;
    while (insertAt > 0) and (Opportunity > Result.Options[insertAt - 1].Opportunity) do
      Dec(insertAt);

    if (Result.Count >= Length(Result.Options)) and (insertAt >= Length(Result.Options)) then
      Exit;

    if Result.Count < Length(Result.Options) then
      Inc(Result.Count);

    for var idx := Result.Count - 1 downto insertAt + 1 do
      Result.Options[idx] := Result.Options[idx - 1];

    Result.Options[insertAt].Cell := Cell;
    Result.Options[insertAt].Distance := Distance;
    Result.Options[insertAt].Opportunity := Opportunity;
  end;

  function ResolveWeight(mol: TMolecule): Single;
  begin
    if WeightMode = mwLearned then
    begin
      Result := Input.MoleculeWeights[mol];
      if Result < MOVE_WEIGHT_EPSILON then
        Result := 0.0;
    end
    else
      Result := 1.0;
  end;

begin
  Scratch := Default(TMoveEvalScratch);
  Result := Default(TMoveReport);

  if Input.Smell.Count <= 0 then
    Exit;

  // Score remote movement candidates from smell opportunities.
  for var detail in Input.Smell.Details do
  begin
    if detail.Directions.Distance = 0 then
      Continue;

    var targetSignal := 0.0;
    for var molecule := Low(TMolecule) to High(TMolecule) do
      targetSignal := targetSignal + detail.MoleculeStrength[molecule] * ResolveWeight(molecule);

    // Distance discount: remote signals lose value with distance.
    // A cache 2 cells away is worth half its raw signal; 4 away is a third.
    var adjustedSignal := targetSignal / (1.0 + detail.Directions.Distance * MOVE_DISTANCE_COST_FACTOR);

    InsertMoveOption(detail.CellIndex, detail.Directions.Distance, adjustedSignal);
  end;
end;

{ TMoveEvaluator }

class function TMoveEvaluator.BuildReport(const Input: TMoveEvalInput; var Scratch: TMoveEvalScratch): TMoveReport;
begin
  Result := EvaluateMovement(Input, Scratch, mwLearned);
end;

{ TDebugMoveEvaluator }

class function TDebugMoveEvaluator.BuildReport(const Input: TMoveEvalInput; var Scratch: TMoveEvalScratch): TMoveReport;
begin
  Result := EvaluateMovement(Input, Scratch, mwUniform);
end;

class function TDebugMoveEvaluator.GetGenerationCode: Char;
begin
  Result := 'X';
end;

initialization
  GlobalGeneRegistry.RegisterGene(TMoveEvaluator);
  GlobalGeneRegistry.RegisterGene(TDebugMoveEvaluator);

end.
