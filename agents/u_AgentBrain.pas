unit u_AgentBrain;

interface

uses u_AgentTypes, u_AgentState, u_AgentGenome, u_SimQueriesIntf;

type
//  TActionScores = TCognitionActionScores;

  TBrainTraceSummary = record
    EnergyLevel: TEnergyLevel;
    StrongestSmellSignal: Single;
    SmellCandidateCount: Integer;
    TopSmellCacheId: Integer;
    TopSmellDistance: Integer;
    TopSmellSignal: Single;
    ThreatPressure: Single;
    HadSmellTarget: Boolean;
    HadSightTarget: Boolean;
  end;

  // Runtime-owned inputs for one brain decision pass.
  TBrainTickInput = record
    IsNight: Boolean;
    Query: ISimQuery;
  end;

  // Result returned by the brain to the population/sim tick routine.
  TBrainTickOutput = record
    RequestedAction: TAgentAction;
    RequestedTarget: TTarget;
    Evaluations: TActionEvaluations;
    Trace: TBrainTraceSummary;
  end;

  // Caller-owned per-agent scratch state reused across ticks.
  // This keeps the brain stateless while avoiding per-tick temp allocations.
  TAgentScratch = record
    SensorScratch: TSensorScanScratch;
    EvaluatorScratch: TEvaluatorScratch;
    DecisionContext: TDecisionContext;
    ActionEvaluations: TActionEvaluations;
    procedure BeginTick(const State: TAgentState; const Input: TBrainTickInput);
  end;

  TAgentBrain = class
  public
    class function Think(const State: TAgentState; const Input: TBrainTickInput;
      var Scratch: TAgentScratch): TBrainTickOutput; static;
  end;

implementation

uses u_EnvironmentTypes;

function CalculateStrongestSmellSignal(const Report: TSmellReport): Single;
begin
  Result := 0.0;

  for var detail in Report.Details do
  begin
    var targetSignal := 0.0;
    for var molecule := Low(TMolecule) to High(TMolecule) do
      targetSignal := targetSignal + detail.MoleculeStrength[molecule];

    if targetSignal > Result then
      Result := targetSignal;
  end;
end;

function CalculateDetailSignal(const Detail: TSmellDetails): Single;
begin
  Result := 0.0;
  for var molecule := Low(TMolecule) to High(TMolecule) do
    Result := Result + Detail.MoleculeStrength[molecule];
end;

function BuildTraceSummary(const Context: TDecisionContext): TBrainTraceSummary;
begin
  Result.EnergyLevel := Context.EnergyLevel;
  Result.StrongestSmellSignal := CalculateStrongestSmellSignal(Context.Smell);
  Result.SmellCandidateCount := Length(Context.Smell.Details);
  Result.TopSmellCacheId := -1;
  Result.TopSmellDistance := -1;
  Result.TopSmellSignal := 0.0;
  Result.ThreatPressure := 0.0;
  Result.HadSmellTarget := Context.Smell.Count > 0;
  Result.HadSightTarget := Context.Sight.Count > 0;

  // Smell details are sorted by the smell gene; detail[0] is the chosen/most salient candidate.
  if Length(Context.Smell.Details) > 0 then
  begin
    var top := Context.Smell.Details[0];
    Result.TopSmellCacheId := top.CacheId;
    Result.TopSmellDistance := top.Directions.Distance;
    Result.TopSmellSignal := CalculateDetailSignal(top);
  end;
end;

function BuildForageEvalInput(const Context: TDecisionContext): TForageEvalInput;
begin
  Result.IsNight := Context.IsNight;
  Result.EnergyLevel := Context.EnergyLevel;
  Result.CurrentAction := Context.CurrentAction;
  Result.Smell := Context.Smell;
end;

function BuildMoveEvalInput(const Context: TDecisionContext): TMoveEvalInput;
begin
  Result.IsNight := Context.IsNight;
  Result.EnergyLevel := Context.EnergyLevel;
  Result.CurrentAction := Context.CurrentAction;
  Result.Smell := Context.Smell;
end;

function BuildShelterEvalInput(const Context: TDecisionContext): TShelterEvalInput;
begin
  Result.IsNight := Context.IsNight;
  Result.EnergyLevel := Context.EnergyLevel;
  Result.CurrentAction := Context.CurrentAction;
  // Placeholder until explicit threat modeling is added.
  Result.ThreatPressure := 0.0;
end;

function BuildEnergyInput(const State: TAgentState): TEnergyInput;
begin
  Result.Reserves := State.Reserves;
end;

function BuildCognitionInput(const Context: TDecisionContext; const ActionEvaluations: TActionEvaluations;
  const CurrentTarget: TTarget): TCognitionInput;
begin
  Result.Context := Context;
  Result.ActionEvaluations := ActionEvaluations;
  Result.CurrentTarget := CurrentTarget;
end;

{ TAgentScratch }

procedure TAgentScratch.BeginTick(const State: TAgentState; const Input: TBrainTickInput);
begin
  SensorScratch.Smell.Count := 0;
  SensorScratch.Sight.Count := 0;
  EvaluatorScratch := Default(TEvaluatorScratch);

  DecisionContext := Default(TDecisionContext);
  DecisionContext.Location := State.Location;
  DecisionContext.IsNight := Input.IsNight;
  DecisionContext.CurrentAction := State.Action;
  DecisionContext.EnergyLevel := Low(TEnergyLevel);

  for var action := Low(TAgentAction) to High(TAgentAction) do
  begin
    ActionEvaluations[action].Score := 0.0;
    ActionEvaluations[action].Target.TType := ttNone;
  end;
end;

{ TAgentBrain }

class function TAgentBrain.Think(const State: TAgentState; const Input: TBrainTickInput; var Scratch: TAgentScratch): TBrainTickOutput;
begin
  Scratch.BeginTick(State, Input);

  // remove this eventually, but for now make sure what we expect is here.
  // There should not be any unassigned genes (eventually), all should have a Basic implementation.
  Assert(Assigned(State.Genome.GeneMap.Energy));
  Assert(Assigned(State.Genome.GeneMap.Smell));
  Assert(Assigned(State.Genome.GeneMap.ForageEval));
  Assert(Assigned(State.Genome.GeneMap.MoveEval));
  Assert(Assigned(State.Genome.GeneMap.Cognition));


  // Observation stage: enrich context from available genes.

  // 1. Energy
  var energyInput := BuildEnergyInput(State);
  Scratch.DecisionContext.EnergyLevel := State.Genome.GeneMap.Energy.EvaluateEnergyLevel(energyInput);

  // Shelter hold mode: keep expensive sensing/evaluators quiet while sheltered at night
  // unless energy has already dropped to low/empty.
  var shelterHoldMode := (State.Action = acShelter) and Input.IsNight and
    (Scratch.DecisionContext.EnergyLevel > elLow);

  // 2. Smell
  if not shelterHoldMode then
  begin
    // allow parameters to adjust the gene's operation
    var smellParams: TSmellParams;
    smellParams.EdgeRetention := State.Genome.SmellEdgeRetention;
    smellParams.Ratings := State.Genome.SmellRatings;

    // activate the gene and save its reply
    var smellGene := State.Genome.GeneMap.Smell;
    var smellReport := smellGene.Scan(State.Location, smellParams, Input.Query, Scratch.SensorScratch.Smell);

    Scratch.DecisionContext.Smell := smellReport;
  end;

  // 3. Sight
  if (not shelterHoldMode) and Assigned(State.Genome.GeneMap.Sight) then
  begin
    var sightGene := State.Genome.GeneMap.Sight;
    var sightReport := sightGene.Scan(State.Location, State.Genome.SightRange, Input.Query, Scratch.SensorScratch.Sight);

    Scratch.DecisionContext.Sight := sightReport;
  end;

  // Evaluation stage: score available actions.

  // 1. Movement
  if not shelterHoldMode then
  begin
    var moveEval := State.Genome.GeneMap.MoveEval;
    if Assigned(moveEval) then
    begin
      var moveInput := BuildMoveEvalInput(Scratch.DecisionContext);
{.define no_movement}
{$ifdef no_movement}
      Scratch.ActionEvaluations[acMove].Score := 0.0;
{$else}
      Scratch.ActionEvaluations[acMove] := moveEval.Evaluate(moveInput, Scratch.EvaluatorScratch.Movement);
{$endif}
    end;
  end;

  // 2. Foraging
  if not shelterHoldMode then
  begin
    var forageEval := State.Genome.GeneMap.ForageEval;
    if Assigned(forageEval) then
    begin
      var forageInput := BuildForageEvalInput(Scratch.DecisionContext);
      Scratch.ActionEvaluations[acForage] := forageEval.Evaluate(forageInput, Scratch.EvaluatorScratch.Forage);
    end;
  end;

  // 3. Shelter
  var shelterEval := State.Genome.GeneMap.ShelterEval;
  if Assigned(shelterEval) then
  begin
    var shelterInput := BuildShelterEvalInput(Scratch.DecisionContext);
    Scratch.ActionEvaluations[acShelter] := shelterEval.Evaluate(shelterInput, Scratch.EvaluatorScratch.Shelter);
  end;

  // 4. Reproduction
  var reproduceEval := State.Genome.GeneMap.ReproduceEval;
  if Assigned(reproduceEval) then
  begin
    // to do
    Scratch.ActionEvaluations[acReproduce].Score := 0;
    Scratch.ActionEvaluations[acReproduce].Target.TType := ttNone;
  end;


  // finally, Cognition
  var cognitionGene := State.Genome.GeneMap.Cognition;
  if Assigned(cognitionGene) then
  begin
    var cognitionInput := BuildCognitionInput(Scratch.DecisionContext, Scratch.ActionEvaluations, State.ActionTarget);
    var cognitionOutput := cognitionGene.Decide(cognitionInput, Scratch.EvaluatorScratch.Cognition);

    Result.RequestedAction := cognitionOutput.RequestedAction;
    Result.RequestedTarget := cognitionOutput.RequestedTarget;
  end
  else
  begin
    Result.RequestedAction := State.Action;
    Result.RequestedTarget := State.ActionTarget;
  end;

  Result.Evaluations := Scratch.ActionEvaluations;
  Result.Trace := BuildTraceSummary(Scratch.DecisionContext);
end;

end.
