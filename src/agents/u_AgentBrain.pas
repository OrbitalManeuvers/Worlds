unit u_AgentBrain;

interface

uses u_AgentTypes, u_AgentState, u_AgentGenome, u_SimQueriesIntf,
  u_SimEnvironments;

type
  TBrainTraceSummary = record
    EnergyLevel: TEnergyLevel;
    ActionProgress: Integer;
    ReserveDelta: Single;
    TicksSinceReproduction: Integer;
    LocalAgentCount: Integer;
    StrongestSmellSignal: Single;
    SmellCandidateCount: Integer;
    TopSmellCache: TCacheRef;
    TopSmellDistance: Integer;
    TopSmellSignal: Single;
    SolarFlux: Single;
    SolarFluxDelta: Single;
    HadSmellTarget: Boolean;
//    HadSightTarget: Boolean;
    Reserves: Single;
  end;

  // Runtime-owned inputs for one brain decision pass.
  TBrainTickInput = record
    IsNight: Boolean;
    SolarFlux: Single;
    SolarFluxDelta: Single;
    Query: ISimQuery;
    GestationDuration: Integer; // total ticks for gestation; supplied by runtime
  end;

  // Result returned by the brain to the population/sim tick routine.
  TBrainTickOutput = record
    RequestedAction: TAgentAction;
    RequestedTarget: TTarget;
    Evaluations: TActionEvaluations;
    Trace: TBrainTraceSummary;
    DecisionBuckets: TDecisionBuckets;
  end;

  // Runtime-owned inputs for one post-resolution reflection pass.
  TBrainReflectInput = record
    ResolvedAction: TAgentAction;
    ResolvedTarget: TTarget;
    ForageOutcome: TForageOutcome;
    GridWidth: Integer;
    PreviousLocation: Integer;
    CurrentLocation: Integer;
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
    class procedure Reflect(var State: TAgentState; const Decision: TBrainTickOutput;
      const Input: TBrainReflectInput; var Scratch: TAgentScratch); static;
  end;

implementation

uses System.SysUtils, System.Math, u_EnvironmentTypes;

const
  FOOD_SIGNAL_STRONG_THRESHOLD = 1.0;
  DECISION_WEIGHT_LEARNING_RATE = 0.20;
  MOLECULE_WEIGHT_LEARNING_RATE = 0.20;

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

function BucketDecisionEnergy(const EnergyLevel: TEnergyLevel): TDecisionEnergy;
begin
  case EnergyLevel of
    elLow:
      Result := elLow;
    elMedium:
      Result := elMedium;
    elHigh:
      Result := elHigh;
    elFull:
      Result := elFull;
  else
    Assert(False, 'Decision buckets require a live agent energy level');
    Result := Low(TDecisionEnergy);
  end;
end;

function BucketDecisionFoodSignal(const Context: TDecisionContext): TDecisionFoodSignal;
begin
  if Context.Smell.Count <= 0 then
    Exit(dfsNone);

  var strongestSignal := CalculateStrongestSmellSignal(Context.Smell);
  if strongestSignal >= FOOD_SIGNAL_STRONG_THRESHOLD then
    Exit(dfsStrong);

  Result := dfsWeak;
end;

function BucketDecisionDayPhase(const Context: TDecisionContext): TDecisionDayPhase;
begin
  if Context.IsNight then
    Exit(ddNight);

  Result := ddDay;
end;

function BuildDecisionBuckets(const Context: TDecisionContext): TDecisionBuckets;
begin
  Result.Energy := BucketDecisionEnergy(Context.EnergyLevel);
  Result.FoodSignal := BucketDecisionFoodSignal(Context);
  Result.DayPhase := BucketDecisionDayPhase(Context);
end;

function BuildTraceSummary(const State: TAgentState; const Context: TDecisionContext;
  const LocalAgentCount: Integer): TBrainTraceSummary;
begin
  Result.EnergyLevel := Context.EnergyLevel;
  Result.ActionProgress := State.ActionProgress;
  Result.Reserves := State.Reserves;
  Result.ReserveDelta := State.ReserveDelta;
  Result.TicksSinceReproduction := State.TicksSinceReproduction;
  Result.LocalAgentCount := LocalAgentCount;
  Result.StrongestSmellSignal := CalculateStrongestSmellSignal(Context.Smell);
  Result.SmellCandidateCount := Length(Context.Smell.Details);
  Result.TopSmellCache := Default(TCacheRef);
  Result.TopSmellDistance := -1;
  Result.TopSmellSignal := 0.0;
  Result.SolarFlux := Context.SolarFlux;
  Result.SolarFluxDelta := Context.SolarFluxDelta;
  Result.HadSmellTarget := Context.Smell.Count > 0;
//  Result.HadSightTarget := Context.Sight.Count > 0;

  // Smell details are sorted by the smell gene; detail[0] is the chosen/most salient candidate.
  if Length(Context.Smell.Details) > 0 then
  begin
    var top := Context.Smell.Details[0];
    Result.TopSmellCache := top.Cache;
    Result.TopSmellDistance := top.Directions.Distance;
    Result.TopSmellSignal := CalculateDetailSignal(top);
  end;
end;

function BuildForageEvalInput(const State: TAgentState; const Context: TDecisionContext): TForageEvalInput;
begin
  Result.Reserves := State.Reserves;
  Result.ReserveDelta := State.ReserveDelta;
  Result.Smell := Context.Smell;
  Result.MoleculeWeights := State.ForageMoleculeWeights;
end;

function BuildMoveEvalInput(const State: TAgentState; const Context: TDecisionContext): TMoveEvalInput;
begin
  Result.Reserves := State.Reserves;
  Result.ReserveDelta := State.ReserveDelta;
  Result.Smell := Context.Smell;
  Result.MoleculeWeights := State.ForageMoleculeWeights;
end;

function BuildShelterEvalInput(const State: TAgentState; const Context: TDecisionContext): TShelterEvalInput;
begin
  Result.Reserves := State.Reserves;
  Result.ReserveDelta := State.ReserveDelta;
  Result.IsNight := Context.IsNight;
  Result.SolarFlux := Context.SolarFlux;
  Result.CircadianPressure := Context.CircadianPressure;

  Result.HasLocalFoodSignal := False;
  for var detail in Context.Smell.Details do
    if detail.Directions.Distance = 0 then
    begin
      Result.HasLocalFoodSignal := True;
      Break;
    end;
end;

function BuildReproduceEvalInput(const State: TAgentState; const Context: TDecisionContext;
  const LocalAgentCount: Integer; const GestationDuration: Integer): TReproduceEvalInput;
begin
  Result.Reserves := State.Reserves;
  Result.ReserveDelta := State.ReserveDelta;
  Result.TicksSinceReproduction := State.TicksSinceReproduction;
  Result.Age := State.Age;
  Result.LocalAgentCount := LocalAgentCount;
  Result.DeltaWeight := State.ForageMoleculeWeights[Delta];
end;

function BuildEnergyInput(const State: TAgentState): TEnergyInput;
begin
  Result.Reserves := State.Reserves;
end;

function BuildCognitionInput(const Context: TDecisionContext; const ActionEvaluations: TActionEvaluations;
  const CurrentTarget: TTarget; const Reserves: Single; const LastForageCell: TCellIndex): TCognitionInput;
begin
  Result.Context := Context;
  Result.ActionEvaluations := ActionEvaluations;
  Result.CurrentTarget := CurrentTarget;
  Result.Reserves := Reserves;
  Result.LastForageCell := LastForageCell;
end;

function BuildWeightedEvaluations(const State: TAgentState; const Buckets: TDecisionBuckets;
  const BaseEvaluations: TActionEvaluations): TActionEvaluations;
begin
  Result := BaseEvaluations;

  for var action := Low(TDecisionAction) to High(TDecisionAction) do
    Result[action].Score := Result[action].Score
      + State.DecisionWeights[action, Buckets.Energy, Buckets.FoodSignal, Buckets.DayPhase];
end;

function BuildCognitionReflectionInput(const State: TAgentState; const Decision: TBrainTickOutput;
  const Input: TBrainReflectInput): TCognitionReflectionInput;
begin
  Result.DecisionBuckets := Decision.DecisionBuckets;
  Result.RequestedAction := Decision.RequestedAction;
  Result.RequestedTarget := Decision.RequestedTarget;
  Result.ResolvedAction := Input.ResolvedAction;
  Result.ResolvedTarget := Input.ResolvedTarget;
  Result.Evaluations := Decision.Evaluations;
  Result.ReserveDelta := State.ReserveDelta;
  Result.ForageOutcome := Input.ForageOutcome;
  Result.GridWidth := Input.GridWidth;
  Result.PreviousLocation := Input.PreviousLocation;
  Result.CurrentLocation := Input.CurrentLocation;
  Result.CurrentReserves := State.Reserves;
  Result.ActionProgress := State.ActionProgress;
end;

procedure ApplyDecisionWeightUpdate(var State: TAgentState; const Buckets: TDecisionBuckets;
  const Reflection: TCognitionReflectionOutput);
begin
  var expectedOutcome := State.DecisionWeights[
    Reflection.LearnedAction,
    Buckets.Energy,
    Buckets.FoodSignal,
    Buckets.DayPhase
  ];

  var predictionError := Reflection.Outcome - expectedOutcome;
  State.DecisionWeights[
    Reflection.LearnedAction,
    Buckets.Energy,
    Buckets.FoodSignal,
    Buckets.DayPhase
  ] := expectedOutcome + (DECISION_WEIGHT_LEARNING_RATE * predictionError);
end;

procedure ApplyMoleculeWeightUpdate(var State: TAgentState;
  const Reflection: TCognitionReflectionOutput);
begin
  for var molecule := Low(TMolecule) to High(TMolecule) do
  begin
    if not (molecule in Reflection.MoleculesPresent) then
      Continue;

    var expected := State.ForageMoleculeWeights[molecule];
    var error := Reflection.MoleculeOutcomes[molecule] - expected;
    State.ForageMoleculeWeights[molecule] := expected + (MOLECULE_WEIGHT_LEARNING_RATE * error);
  end;
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
  DecisionContext.SolarFlux := Input.SolarFlux;
  DecisionContext.SolarFluxDelta := Input.SolarFluxDelta;
  DecisionContext.CurrentAction := State.Action;
  DecisionContext.CurrentActionAge := State.ActionAge;
  DecisionContext.ActionProgress := State.ActionProgress;
  DecisionContext.EnergyLevel := Low(TEnergyLevel);
  DecisionContext.CircadianPressure := State.CircadianPressure;

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
  Assert(Assigned(State.Genome.GeneMap.ReproduceEval));


  // Observation stage: enrich context from available genes.

  // 1. Energy
  var energyInput := BuildEnergyInput(State);
  Scratch.DecisionContext.EnergyLevel := State.Genome.GeneMap.Energy.EvaluateEnergyLevel(energyInput);

  // 2. Smell
  // allow parameters to adjust the gene's operation
  var smellParams: TSmellParams;
  smellParams.Ratings := State.Genome.SmellRatings;

  // activate the gene and save its reply
  var smellGene := State.Genome.GeneMap.Smell;
  var smellReport := smellGene.Scan(State.Location, smellParams, Input.Query, Scratch.SensorScratch.Smell);

  Scratch.DecisionContext.Smell := smellReport;

  // 3. Sight
//  if Assigned(State.Genome.GeneMap.Sight) then
//  begin
    // for now, sight is being mothballed. for *lack of vision*
    // it may return someday so for now we leave it in the framework, but ignore it

//    var sightGene := State.Genome.GeneMap.Sight;
//    var sightReport := sightGene.Scan(State.Location, State.Genome.SightRange, Input.Query, Scratch.SensorScratch.Sight);

//    Scratch.DecisionContext.Sight := Default(TSightReport);
//  end;

  Result.DecisionBuckets := BuildDecisionBuckets(Scratch.DecisionContext);

  // Evaluation stage: score available actions.

  // 1. Movement
  var bestMove := Default(TActionEvalResult);
  bestMove.Score := 0.0;
  bestMove.Target.TType := ttNone;
  var moveEval := State.Genome.GeneMap.MoveEval;
  if Assigned(moveEval) then
  begin
    var moveInput := BuildMoveEvalInput(State, Scratch.DecisionContext);
    bestMove := moveEval.Evaluate(moveInput, Scratch.EvaluatorScratch.Movement);
  end;

  Scratch.ActionEvaluations[acMove] := bestMove;

  // 2. Foraging
  var forageEval := State.Genome.GeneMap.ForageEval;
  if Assigned(forageEval) then
  begin
    var forageInput := BuildForageEvalInput(State, Scratch.DecisionContext);
    Scratch.ActionEvaluations[acForage] := forageEval.Evaluate(forageInput, Scratch.EvaluatorScratch.Forage);
  end;

  // 3. Shelter
  var shelterEval := State.Genome.GeneMap.ShelterEval;
  if Assigned(shelterEval) then
  begin
    var shelterInput := BuildShelterEvalInput(State, Scratch.DecisionContext);
    Scratch.ActionEvaluations[acShelter] := shelterEval.Evaluate(shelterInput, Scratch.EvaluatorScratch.Shelter);
  end;

  // 4. Reproduction
  var localAgentCount := 0;
  var reproduceEval := State.Genome.GeneMap.ReproduceEval;
  if Assigned(reproduceEval) and (State.Action <> acShelter) then
  begin
    // don't run the sight query if it's not needed
    if state.Age >= reproduceEval.MinimumAge then
    begin
      var crowdingQuery: IPopulationCrowdingQuery;
      if Supports(Input.Query, IPopulationCrowdingQuery, crowdingQuery) then
      begin
        localAgentCount := crowdingQuery.CountAgentsWithinRadius(State.Location, 1);
        // Query counts local living agents in the source cell too, so drop self for social pressure.
        if localAgentCount > 0 then
          Dec(localAgentCount);
      end;
    end;

    var reproduceInput := BuildReproduceEvalInput(State, Scratch.DecisionContext, localAgentCount, Input.GestationDuration);
    Scratch.ActionEvaluations[acReproduce] := reproduceEval.Evaluate(reproduceInput, Scratch.EvaluatorScratch.Reproduce);
  end;


  // finally, Cognition
  var cognitionGene := State.Genome.GeneMap.Cognition;
  if Assigned(cognitionGene) then
  begin
    var weightedEvaluations := BuildWeightedEvaluations(State, Result.DecisionBuckets, Scratch.ActionEvaluations);
    var cognitionInput := BuildCognitionInput(Scratch.DecisionContext, weightedEvaluations,
      State.ActionTarget, State.Reserves, State.LastForageCell);
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
  Result.Trace := BuildTraceSummary(State, Scratch.DecisionContext, localAgentCount);
end;

class procedure TAgentBrain.Reflect(var State: TAgentState; const Decision: TBrainTickOutput;
  const Input: TBrainReflectInput; var Scratch: TAgentScratch);
begin
  var cognitionGene := State.Genome.GeneMap.Cognition;
  if not Assigned(cognitionGene) then
    Exit;

  var reflectionInput := BuildCognitionReflectionInput(State, Decision, Input);
  var reflectionOutput := cognitionGene.Reflect(reflectionInput, Scratch.EvaluatorScratch.Reflection);

  if reflectionOutput.HasWeightUpdate then
    ApplyDecisionWeightUpdate(State, Decision.DecisionBuckets, reflectionOutput);

  if reflectionOutput.HasMoleculeUpdate then
    ApplyMoleculeWeightUpdate(State, reflectionOutput);
end;

end.
