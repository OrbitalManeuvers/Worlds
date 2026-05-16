unit u_CognitionGenes;

interface

uses u_AgentGenome, u_AgentTypes;

type
  TBasicCognition = class(TCognitionGene)
  public
    class function Decide(const Input: TCognitionInput; var Scratch: TCognitionScratch): TCognitionOutput; override;
  end;

  // consider for mutations
  TLearningCognition = class(TBasicCognition)
  public
    class function GetGenerationCode: Char; override;
    class function Reflect(const Input: TCognitionReflectionInput;
      var Scratch: TReflectionScratch): TCognitionReflectionOutput; override;
  end;  // knows how to incorporate decision weights
  TExploringCognition = class(TCognitionGene); // knows how to wander in good times


implementation

uses System.Math, u_EnvironmentTypes;

const
  // Keep an in-flight move target unless a new option is meaningfully stronger.
  MOVE_TARGET_SWITCH_RATIO = 1.35;
  MOVE_TARGET_SWITCH_ABS_MARGIN = 0.02;

  // Movement must beat the next-best non-move action by this margin to win.
  // Try .04 or .05 if still feels twitchy at times
  MOVE_ACTION_SELECTION_MARGIN = 0.03;

  MOVE_REFLECT_PROGRESS_OUTCOME = 0.06;
  MOVE_REFLECT_NO_PROGRESS_OUTCOME = -0.03;
  MOVE_REFLECT_BLOCKED_OUTCOME = -0.06;

function SmellSignalForCell(const Smell: TSmellReport; const CellIndex: Integer): Single;
begin
  Result := 0.0;

  for var detail in Smell.Details do
  begin
    if detail.CellIndex <> CellIndex then
      Continue;

    for var molecule := Low(TMolecule) to High(TMolecule) do
      Result := Result + detail.MoleculeStrength[molecule];

    Exit;
  end;
end;

function CellDistance(const FromCell, ToCell, GridWidth: Integer): Integer;
begin
  if (GridWidth <= 0) or (FromCell < 0) or (ToCell < 0) then
    Exit(-1);

  var fromX := FromCell mod GridWidth;
  var fromY := FromCell div GridWidth;
  var toX := ToCell mod GridWidth;
  var toY := ToCell div GridWidth;

  Result := Abs(toX - fromX);
  if Abs(toY - fromY) > Result then
    Result := Abs(toY - fromY);
end;

{ TBasicCognition }

class function TBasicCognition.Decide(const Input: TCognitionInput; var Scratch: TCognitionScratch): TCognitionOutput;
begin
  Scratch := Default(TCognitionScratch);

  var bestAction := Input.Context.CurrentAction;
  var bestScore := Input.ActionEvaluations[bestAction].Score;

  for var action := Low(TAgentAction) to High(TAgentAction) do
    if Input.ActionEvaluations[action].Score > bestScore then
    begin
      bestAction := action;
      bestScore := Input.ActionEvaluations[action].Score;
    end;

  // Require a modest lead for move decisions to avoid oscillation on near-ties.
  if bestAction = acMove then
  begin
    var bestNonMoveAction := acIdle;
    var bestNonMoveScore := -1.0;

    for var action := Low(TAgentAction) to High(TAgentAction) do
    begin
      if action = acMove then
        Continue;

      if Input.ActionEvaluations[action].Score > bestNonMoveScore then
      begin
        bestNonMoveAction := action;
        bestNonMoveScore := Input.ActionEvaluations[action].Score;
      end;
    end;

    if bestScore < (bestNonMoveScore + MOVE_ACTION_SELECTION_MARGIN) then
    begin
      bestAction := bestNonMoveAction;
      bestScore := bestNonMoveScore;
    end;
  end;

  // Avoid sticky carry-over actions when no action has positive support this tick.
  if bestScore <= 0.0 then
  begin
    Result.RequestedAction := acIdle;
    Result.RequestedTarget.TType := ttCell;
    Result.RequestedTarget.Cell := Input.Context.Location;
    Exit;
  end;

  Result.RequestedAction := bestAction;
  Result.RequestedTarget := Input.ActionEvaluations[bestAction].Target;

  // Move-target affinity: maintain destination continuity across ticks unless
  // a new move candidate is clearly better.
  if (Result.RequestedAction = acMove)
    and (Input.Context.CurrentAction = acMove)
    and (Input.CurrentTarget.TType = ttCell)
    and (Result.RequestedTarget.TType = ttCell)
    and (Input.CurrentTarget.Cell <> Input.Context.Location)
    and (Input.CurrentTarget.Cell <> Result.RequestedTarget.Cell) then
  begin
    var currentSignal := SmellSignalForCell(Input.Context.Smell, Input.CurrentTarget.Cell);
    if currentSignal > 0.0 then
    begin
      var newSignal := Input.ActionEvaluations[acMove].Score;
      var switchThreshold := Max(currentSignal * MOVE_TARGET_SWITCH_RATIO,
        currentSignal + MOVE_TARGET_SWITCH_ABS_MARGIN);

      if newSignal < switchThreshold then
        Result.RequestedTarget.Cell := Input.CurrentTarget.Cell;
    end;
  end;

  // Minimal targeting hook for foraging when the evaluator does not emit a target.
  // Smell details are expected to arrive pre-sorted by the smell gene.
  // Forage execution is local-only: only distance-0 cache targets are actionable.
  if (bestAction = acForage)
    and (Result.RequestedTarget.TType = ttNone)
    and (Input.Context.Smell.Count > 0)
    and (Length(Input.Context.Smell.Details) > 0) then
  begin
    var foundLocal := False;
    for var i := 0 to Length(Input.Context.Smell.Details) - 1 do
      if Input.Context.Smell.Details[i].Directions.Distance = 0 then
      begin
        Result.RequestedTarget.TType := ttCache;
        Result.RequestedTarget.Cache := Input.Context.Smell.Details[i].Cache;
        foundLocal := True;
        Break;
      end;

    if not foundLocal then
    begin
      Result.RequestedAction := acIdle;
      Result.RequestedTarget.TType := ttCell;
      Result.RequestedTarget.Cell := Input.Context.Location;
    end;
  end;

  // Transitional fallback while evaluators are still wiring explicit targets.
  // Only move should inherit an in-flight target; shelter/reproduce/idle act on the current cell.
  if Result.RequestedTarget.TType = ttNone then
  begin
    if bestAction = acMove then
      Result.RequestedTarget := Input.CurrentTarget
    else
    begin
      Result.RequestedTarget.TType := ttCell;
      Result.RequestedTarget.Cell := Input.Context.Location;
    end;
  end;

  if Result.RequestedTarget.TType = ttNone then
  begin
    Result.RequestedTarget.TType := ttCell;
    Result.RequestedTarget.Cell := Input.Context.Location;
  end;
end;

{ TLearningCognition }

class function TLearningCognition.GetGenerationCode: Char;
begin
  Result := 'B';
end;

class function TLearningCognition.Reflect(const Input: TCognitionReflectionInput;
  var Scratch: TReflectionScratch): TCognitionReflectionOutput;
begin
  Scratch := Default(TReflectionScratch);
  Result := Default(TCognitionReflectionOutput);

  if Input.RequestedAction <> acMove then
    Exit;

  Result.LearnedAction := acMove;
  Result.HasWeightUpdate := True;

  if Input.ResolvedAction <> acMove then
  begin
    Result.Outcome := MOVE_REFLECT_BLOCKED_OUTCOME;
    Exit;
  end;

  if Input.RequestedTarget.TType <> ttCell then
  begin
    Result.HasWeightUpdate := False;
    Exit;
  end;

  var beforeDistance := CellDistance(Input.PreviousLocation, Input.RequestedTarget.Cell, Input.GridWidth);
  var afterDistance := CellDistance(Input.CurrentLocation, Input.RequestedTarget.Cell, Input.GridWidth);
  if (beforeDistance <= 0) or (afterDistance < 0) then
  begin
    Result.HasWeightUpdate := False;
    Exit;
  end;

  if afterDistance < beforeDistance then
    Result.Outcome := MOVE_REFLECT_PROGRESS_OUTCOME
  else
    Result.Outcome := MOVE_REFLECT_NO_PROGRESS_OUTCOME;
end;


initialization
  GlobalGeneRegistry.RegisterGene(TBasicCognition);
  GlobalGeneRegistry.RegisterGene(TLearningCognition);

end.
