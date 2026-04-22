unit u_CognitionGenes;

interface

uses u_AgentGenome, u_AgentTypes;

type
  TBasicCognition = class(TCognitionGene)
  public
    class function Decide(const Input: TCognitionInput; var Scratch: TCognitionScratch): TCognitionOutput; override;
  end;


implementation

uses System.Math, u_EnvironmentTypes;

const
  // Keep an in-flight move target unless a new option is meaningfully stronger.
  MOVE_TARGET_SWITCH_RATIO = 1.35;
  MOVE_TARGET_SWITCH_ABS_MARGIN = 0.02;

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
        Result.RequestedTarget.CacheId := Input.Context.Smell.Details[i].CacheId;
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

  // Transitional fallback while non-forage evaluators are still wiring explicit targets.
  if (bestAction <> acForage) and (Result.RequestedTarget.TType = ttNone) then
    Result.RequestedTarget := Input.CurrentTarget;

  if Result.RequestedTarget.TType = ttNone then
  begin
    Result.RequestedTarget.TType := ttCell;
    Result.RequestedTarget.Cell := Input.Context.Location;
  end;
end;


initialization
  GlobalGeneRegistry.RegisterGene(TBasicCognition);

end.
