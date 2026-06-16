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

uses System.Math, u_EnvironmentTypes, u_SimTypes, u_Instincts;

type
  TActionContinuationParams = record
    MaxDampening: Single;       // ceiling — how much competing scores can be suppressed
    RampRate: Single;           // dampening increase per tick of ActionProgress
    PressureWeighted: Boolean;  // if true, dampening scales with CircadianPressure ratio
  end;

const
  // Continuation dampening table: defines how strongly each action resists interruption
  // once ActionProgress > 0 (i.e. past the dig/entry phase).
  ActionContinuation: array[TAgentAction] of TActionContinuationParams = (
    (MaxDampening: 0.0;  RampRate: 0.0;  PressureWeighted: False),  // acMove — no progressive phase
    (MaxDampening: 0.0;  RampRate: 0.0;  PressureWeighted: False),  // acForage — no progressive phase
    (MaxDampening: 0.95; RampRate: 0.08; PressureWeighted: True),   // acShelter — deep, scales with fatigue
    (MaxDampening: 0.70; RampRate: 0.05; PressureWeighted: False),  // acReproduce — linear commitment ramp
    (MaxDampening: 0.0;  RampRate: 0.0;  PressureWeighted: False)   // acIdle — nothing
  );

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

  // Opportunity arbitration moved from evaluators into cognition.
  FORAGE_RESERVE_COMFORT_LEVEL = 8.0;
  FORAGE_HIGH_RESERVE_DISCOUNT = 0.20;
  MOVE_LOCAL_FOOD_SUPPRESSION = 0.35;
  MOVE_NEGATIVE_DELTA_EXTRA_SUPPRESSION = 0.50;

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

function TryGetMoveOpportunity(const Report: TMoveReport; const CellIndex: TCellIndex;
  out Opportunity: Single): Boolean;
begin
  for var i := 0 to Report.Count - 1 do
    if Report.Options[i].Cell = CellIndex then
    begin
      Opportunity := Report.Options[i].Opportunity;
      Exit(True);
    end;

  Opportunity := 0.0;
  Result := False;
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

procedure ApplyOpportunityArbitration(const Input: TCognitionInput;
  var EffectiveScores: TActionScores);
begin
  // Forage urgency fades as reserves fill.
  var reserveRatio := EnsureRange(Input.Reserves / FORAGE_RESERVE_COMFORT_LEVEL, 0.0, 1.0);
  var forageDiscount := 1.0 - (reserveRatio * (1.0 - FORAGE_HIGH_RESERVE_DISCOUNT));
  EffectiveScores[acForage].Score := EffectiveScores[acForage].Score * forageDiscount;

  // When viable local forage exists, remote movement is a gamble.
  if Input.ForageReport.Count > 0 then
  begin
    EffectiveScores[acMove].Score := EffectiveScores[acMove].Score * MOVE_LOCAL_FOOD_SUPPRESSION;
    if Input.ReserveDelta < 0.0 then
      EffectiveScores[acMove].Score := EffectiveScores[acMove].Score * MOVE_NEGATIVE_DELTA_EXTRA_SUPPRESSION;
  end;
end;

{ TBasicCognition }

class function TBasicCognition.Decide(const Input: TCognitionInput; var Scratch: TCognitionScratch): TCognitionOutput;
var
  effectiveScores: TActionScores;
begin
  Scratch := Default(TCognitionScratch);

  // Start from raw evaluator scores
  effectiveScores := Input.ActionScores;

  // Opportunity arbitration belongs in cognition: evaluators report what is available,
  // cognition decides what matters given current body state.
  ApplyOpportunityArbitration(Input, effectiveScores);

  // Continuation pressure: when ActionProgress > 0, the agent is invested in a
  // progressive action (past the dig/entry phase). Dampen competing scores so that
  // only genuinely strong signals can interrupt.
  if Input.Context.ActionProgress > 0 then
  begin
    var params := ActionContinuation[Input.Context.CurrentAction];
    var dampening := Min(params.RampRate * Input.Context.ActionProgress, params.MaxDampening);
    if params.PressureWeighted then
      dampening := dampening * EnsureRange(
        Input.Context.CircadianPressure / MAX_CIRCADIAN_PRESSURE, 0.0, 1.0);

    for var action := Low(TAgentAction) to High(TAgentAction) do
      if action <> Input.Context.CurrentAction then
        effectiveScores[action].Score := effectiveScores[action].Score * (1.0 - dampening);
  end;

  var bestAction := Input.Context.CurrentAction;
  var bestScore := effectiveScores[bestAction].Score;

  for var action := Low(TAgentAction) to High(TAgentAction) do
    if effectiveScores[action].Score > bestScore then
    begin
      bestAction := action;
      bestScore := effectiveScores[action].Score;
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

      if effectiveScores[action].Score > bestNonMoveScore then
      begin
        bestNonMoveAction := action;
        bestNonMoveScore := effectiveScores[action].Score;
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
    // Forage memory fallback: if the agent has nowhere to go and remembers where it
    // last ate, head there. Comfortable agents wait a tick first (food might appear
    // locally); hungry agents go immediately.
    if (Input.LastForageCell >= 0)
      and (Input.LastForageCell <> Input.Context.Location) then
    begin
      var patient := (Input.Reserves >= Instinct.ENERGY_COMFORT_LEVEL)
        and (Input.Context.CurrentActionAge < 2);

      if not patient then
      begin
        Result.RequestedAction := acMove;
        Result.RequestedTarget.TType := ttCell;
        Result.RequestedTarget.Cell := Input.LastForageCell;
        Exit;
      end;
    end;

    Result.RequestedAction := acIdle;
    Result.RequestedTarget.TType := ttCell;
    Result.RequestedTarget.Cell := Input.Context.Location;
    Exit;
  end;

  Result.RequestedAction := bestAction;
  Result.RequestedTarget.TType := ttNone;

  case bestAction of
    acMove:
      begin
        if Input.MoveReport.Count > 0 then
        begin
          Result.RequestedTarget.TType := ttCell;
          Result.RequestedTarget.Cell := Input.MoveReport.Options[0].Cell;
        end;
      end;
    acForage:
      begin
        if Input.ForageReport.Count > 0 then
        begin
          Result.RequestedTarget.TType := ttCache;
          Result.RequestedTarget.Cache := Input.ForageReport.Options[0].Cache;
        end;
      end;
  else
    begin
      Result.RequestedTarget.TType := ttCell;
      Result.RequestedTarget.Cell := Input.Context.Location;
    end;
  end;

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
    var anchorSignal: Single := 0.0;
    var hasAnchor := TryGetMoveOpportunity(Input.MoveReport, Input.CurrentTarget.Cell, anchorSignal);
    if (not hasAnchor) then
    begin
      // Fallback for in-transit targets that may have fallen outside the curated list.
      anchorSignal := SmellSignalForCell(Input.Context.Smell, Input.CurrentTarget.Cell);
      hasAnchor := anchorSignal > 0.0;
    end;

    if hasAnchor then
    begin
      var newSignal: Single := effectiveScores[acMove].Score;
      if not TryGetMoveOpportunity(Input.MoveReport, Result.RequestedTarget.Cell, newSignal) then
        newSignal := effectiveScores[acMove].Score;

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
