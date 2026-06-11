unit u_CognitionGenes;

interface

uses u_AgentGenome, u_AgentTypes;

type
  TBasicCognition = class(TCognitionGene)
  public
    class function Decide(const Input: TCognitionInput; var Scratch: TCognitionScratch): TCognitionOutput; override;
    class function Reflect(const Input: TCognitionReflectionInput; var Scratch: TReflectionScratch): TCognitionReflectionOutput; override;
  end;


  // knows how to incorporate decision weights
  TLearningCognition = class(TBasicCognition)
  private
    class function MoveReflection(const Input: TCognitionReflectionInput;
      var Scratch: TReflectionScratch): TCognitionReflectionOutput;

    class function ForageReflection(const Input: TCognitionReflectionInput;
      var Scratch: TReflectionScratch): TCognitionReflectionOutput;
    class function ShelterReflection(const Input: TCognitionReflectionInput;
      var Scratch: TReflectionScratch): TCognitionReflectionOutput;
    class function ReproduceReflection(const Input: TCognitionReflectionInput;
      var Scratch: TReflectionScratch): TCognitionReflectionOutput;
  public
    class function GetGenerationCode: Char; override;
    class function Reflect(const Input: TCognitionReflectionInput;
      var Scratch: TReflectionScratch): TCognitionReflectionOutput; override;
  end;

  // knows how to explore in good times
  TExploringCognition = class(TCognitionGene);


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

  // Forage reflection: small signal tied to realized gain.
  // Keep magnitudes modest so forage learning doesn't drown out move learning.
  FORAGE_REFLECT_GAIN_OUTCOME = 0.05;
  FORAGE_REFLECT_NO_GAIN_OUTCOME = -0.04;

  // Shelter reflection: reward when reserves are recovering while sheltered.
  // No negative signal — flat/declining reserves while sheltered may still be
  // better than the alternative, so silence is more honest than punishment.
  SHELTER_REFLECT_RECOVERY_OUTCOME = 0.04;

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
    and (Input.CurrentTarget.Cell <> Result.RequestedTarget.Cell) then
  begin
    // Two cases:
    // 1. In transit (target ≠ location): keep heading to current target unless new is much better.
    // 2. Just arrived (target = location): the agent chose to come here — require a strong
    //    signal to leave immediately, using the local smell as the anchor.
    var anchorSignal := SmellSignalForCell(Input.Context.Smell, Input.CurrentTarget.Cell);
    if anchorSignal > 0.0 then
    begin
      var newSignal := Input.ActionEvaluations[acMove].Score;
      var switchThreshold := Max(anchorSignal * MOVE_TARGET_SWITCH_RATIO,
        anchorSignal + MOVE_TARGET_SWITCH_ABS_MARGIN);

      if newSignal < switchThreshold then
      begin
        // In transit: keep the old target. At arrival: suppress movement entirely.
        if Input.CurrentTarget.Cell <> Input.Context.Location then
          Result.RequestedTarget.Cell := Input.CurrentTarget.Cell
        else
        begin
          // Arrived but nothing strong enough to justify leaving — don't move.
          Result.RequestedAction := acIdle;
          Result.RequestedTarget.TType := ttCell;
          Result.RequestedTarget.Cell := Input.Context.Location;
        end;
      end;
    end;
  end;

  // Minimal targeting hook for foraging when the evaluator does not emit a target.
  // Smell details are expected to arrive pre-sorted by the smell gene.
  // Forage execution is local-only: only distance-0 cache targets are actionable.
  // Guard: only fire when the evaluator produced a real base score (target assigned).
  // If the evaluator returned ttNone, it found nothing worth eating — learned
  // decision weights alone should not override that by grabbing the first local cache.
  if (bestAction = acForage)
    and (Result.RequestedTarget.TType = ttNone) then
  begin
    // Evaluator didn't find viable food. Fall back to idle.
    Result.RequestedAction := acIdle;
    Result.RequestedTarget.TType := ttCell;
    Result.RequestedTarget.Cell := Input.Context.Location;
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

class function TBasicCognition.Reflect(const Input: TCognitionReflectionInput;
  var Scratch: TReflectionScratch): TCognitionReflectionOutput;
begin
  Scratch := Default(TReflectionScratch);
  Result := Default(TCognitionReflectionOutput);
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

  case Input.RequestedAction of
    acMove: Result := MoveReflection(Input, Scratch);
    acForage: Result := ForageReflection(Input, Scratch);
    acShelter: Result := ShelterReflection(Input, Scratch);
    acReproduce: Result := ReproduceReflection(Input, Scratch);
    acIdle: begin  end;
  else
    Assert(False, 'unknown learned action');
  end;
end;

class function TLearningCognition.ForageReflection(
  const Input: TCognitionReflectionInput;
  var Scratch: TReflectionScratch): TCognitionReflectionOutput;
begin
  Result := Default(TCognitionReflectionOutput);
  Result.LearnedAction := acForage;

  // Skip update if the action was downgraded — agent didn't actually forage.
  if Input.ResolvedAction <> acForage then
  begin
    Result.HasWeightUpdate := False;
    Result.HasMoleculeUpdate := False;
    Exit;
  end;

  // Decision weight update: positive outcome when forage produced a gain.
  Result.HasWeightUpdate := True;
  if Input.ForageOutcome.Gain > 0.0 then
    Result.Outcome := FORAGE_REFLECT_GAIN_OUTCOME
  else
    Result.Outcome := FORAGE_REFLECT_NO_GAIN_OUTCOME;

  // Molecule weight update: attribute conversion efficiency to each molecule present.
  // Efficiency = energy gained per unit consumed. Each molecule gets the overall
  // efficiency as its outcome — the share weighting happens naturally because molecules
  // absent from the substance get skipped (their percentage is 0).
  // Zero or near-zero gain still produces a valid (low) efficiency signal, teaching
  // the agent that those molecules are poor food sources.
  if Input.ForageOutcome.Consumed > 0.0 then
  begin
    Result.HasMoleculeUpdate := True;
    Result.MoleculesPresent := [];
    var efficiency := Input.ForageOutcome.Gain / Input.ForageOutcome.Consumed;

    for var molecule := Low(TMolecule) to High(TMolecule) do
    begin
      if Input.ForageOutcome.Substance[molecule] > 0 then
      begin
        Include(Result.MoleculesPresent, molecule);
        Result.MoleculeOutcomes[molecule] := efficiency;
      end
      else
        Result.MoleculeOutcomes[molecule] := 0.0;
    end;
  end
  else
    Result.HasMoleculeUpdate := False;
end;

class function TLearningCognition.MoveReflection(
  const Input: TCognitionReflectionInput;
  var Scratch: TReflectionScratch): TCognitionReflectionOutput;
begin
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

class function TLearningCognition.ReproduceReflection(
  const Input: TCognitionReflectionInput;
  var Scratch: TReflectionScratch): TCognitionReflectionOutput;
begin
  Result := Default(TCognitionReflectionOutput);
  Result.LearnedAction := acReproduce;
  Result.HasWeightUpdate := False;
end;

class function TLearningCognition.ShelterReflection(
  const Input: TCognitionReflectionInput;
  var Scratch: TReflectionScratch): TCognitionReflectionOutput;
begin
  Result := Default(TCognitionReflectionOutput);
  Result.LearnedAction := acShelter;

  // Skip update if the action was downgraded — agent didn't actually shelter.
  if Input.ResolvedAction <> acShelter then
  begin
    Result.HasWeightUpdate := False;
    Exit;
  end;

  // Reward shelter when reserves are visibly recovering.
  // Flat or negative delta gets silence — not a punishment.
  if Input.ReserveDelta > 0.0 then
  begin
    Result.HasWeightUpdate := True;
    Result.Outcome := SHELTER_REFLECT_RECOVERY_OUTCOME;
  end
  else
    Result.HasWeightUpdate := False;
end;

initialization
  GlobalGeneRegistry.RegisterGene(TBasicCognition);
  GlobalGeneRegistry.RegisterGene(TLearningCognition);

end.
