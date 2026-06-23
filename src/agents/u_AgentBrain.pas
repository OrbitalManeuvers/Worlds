unit u_AgentBrain;

interface

uses u_SimTypes, u_RuntimeTypes, u_BrainTypes, u_AgentState, u_AgentGenome, u_SimQueriesIntf,
  u_GeneTypes;

type
  // Runtime-owned inputs for one brain decision pass.
  TBrainTickInput = record
    SolarFlux: Single;
    SolarFluxDelta: Single;
    Query: ISimQuery;
    GestationDuration: Integer; // total ticks for gestation; supplied by runtime
    GeneMap: TGeneMap;          // resolved from agent's gene sequence by the runtime
  end;

  TBrainReflectInput = record
    ResolvedAction: TAgentAction;
    ResolvedTarget: TTarget;
    ForageOutcome: TForageOutcome;
    GridWidth: Integer;
    PreviousLocation: Integer;
    CurrentLocation: Integer;
    GeneMap: TGeneMap;
  end;

  TAgentBrain = class
  public
    class function Think(const State: TAgentState; const Input: TBrainTickInput;
      var Scratch: TAgentScratch): TBrainTickOutput; static;
    class procedure Reflect(var State: TAgentState; const Decision: TBrainTickOutput;
      const Input: TBrainReflectInput; var Scratch: TAgentScratch); static;
  end;

implementation

uses System.SysUtils, System.Math,
  u_EnvironmentTypes;

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

function BucketDecisionFoodSignal(const SmellReport: TSmellReport): TDecisionFoodSignal;
begin
  if SmellReport.Count <= 0 then
    Exit(dfsNone);

  var strongestSignal := CalculateStrongestSmellSignal(SmellReport);
  if strongestSignal >= FOOD_SIGNAL_STRONG_THRESHOLD then
    Exit(dfsStrong);

  Result := dfsWeak;
end;

function BucketDecisionDayPhase(IsNight: Boolean): TDecisionDayPhase;
begin
  if IsNight then
    Exit(ddNight);

  Result := ddDay;
end;

function BuildDecisionBuckets(EnergyLevel: TEnergyLevel; const SmellReport: TSmellReport; IsNight: Boolean): TDecisionBuckets;
begin
  Result.Energy := BucketDecisionEnergy(EnergyLevel);
  Result.FoodSignal := BucketDecisionFoodSignal(SmellReport);
  Result.DayPhase := BucketDecisionDayPhase(IsNight);
end;

function BuildForageEvalInput(const State: TAgentState; const SmellReport: TSmellReport): TForageEvalInput;
begin
  Result.Reserves := State.Reserves;
  Result.ReserveDelta := State.ReserveDelta;
  Result.Smell := SmellReport;
  Result.MoleculeWeights := State.Genome.ForageMoleculeWeights;
end;

function BuildMoveEvalInput(const State: TAgentState; const SmellReport: TSmellReport): TMoveEvalInput;
begin
  Result.Reserves := State.Reserves;
  Result.ReserveDelta := State.ReserveDelta;
  Result.Smell := SmellReport;
  Result.MoleculeWeights := State.Genome.ForageMoleculeWeights;
end;

function BuildShelterEvalInput(const State: TAgentState; const Input: TBrainTickInput;
  const SmellReport: TSmellReport): TShelterEvalInput;
begin
  Result.Reserves := State.Reserves;
  Result.ReserveDelta := State.ReserveDelta;
  Result.SolarFlux := Input.SolarFlux;
  Result.CircadianPressure := State.CircadianPressure;

  Result.HasLocalFoodSignal := False;
  for var detail in SmellReport.Details do
    if detail.Directions.Distance = 0 then
    begin
      Result.HasLocalFoodSignal := True;
      Break;
    end;
end;

function BuildReproduceEvalInput(const State: TAgentState;
  const LocalAgentCount: Integer; const GestationDuration: Integer): TReproduceEvalInput;
begin
  Result.Reserves := State.Reserves;
  Result.ReserveDelta := State.ReserveDelta;
  Result.TicksSinceReproduction := State.TicksSinceReproduction;
  Result.Age := State.Age;
  Result.LocalAgentCount := LocalAgentCount;
  Result.DeltaWeight := State.Genome.ForageMoleculeWeights[Delta];
end;

function BuildEnergyInput(const State: TAgentState): TEnergyReserves;
begin
  Result := State.Reserves;
end;

function BuildCognitionInput(const State: TAgentState; const SmellReport: TSmellReport;
  const ActionScores: TActionScores;
  const CurrentTarget: TTarget; const Reserves: Single; const ReserveDelta: Single;
  const LastForageCell: TCellIndex;
  const ForageReport: TForageReport; const MoveReport: TMoveReport): TCognitionInput;
begin
  Result.ActionScores := ActionScores;
  Result.CurrentTarget := CurrentTarget;
  Result.Reserves := Reserves;
  Result.ReserveDelta := ReserveDelta;
  Result.LastForageCell := LastForageCell;
  Result.Location := State.Location;
  Result.CurrentAction := State.Action;
  Result.CurrentActionAge := State.ActionAge;
  Result.CurrentActionProgress := State.ActionProgress;
  Result.CircadianPressure := State.CircadianPressure;
  Result.Smell := SmellReport;
  Result.ForageReport := ForageReport;
  Result.MoveReport := MoveReport;
end;

function BuildWeightedScores(const State: TAgentState; const Buckets: TDecisionBuckets;
  const BaseScores: TActionScores): TActionScores;
begin
  Result := BaseScores;
  for var action := Low(TDecisionAction) to High(TDecisionAction) do
    Result[action] := Result[action] +
    State.DecisionWeights[action, Buckets.Energy, Buckets.FoodSignal, Buckets.DayPhase];
end;

function BuildCognitionReflectionInput(const State: TAgentState; const Decision: TBrainTickOutput;
  const Input: TBrainReflectInput): TCognitionReflectionInput;
begin
  Result.DecisionBuckets := Decision.DecisionBuckets;
  Result.RequestedAction := Decision.RequestedAction;
  Result.RequestedTarget := Decision.RequestedTarget;
  Result.ResolvedAction := Input.ResolvedAction;
  Result.ResolvedTarget := Input.ResolvedTarget;
  Result.Scores := Decision.Scores;
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

    var expected := State.Genome.ForageMoleculeWeights[molecule];
    var error := Reflection.MoleculeOutcomes[molecule] - expected;
    State.Genome.ForageMoleculeWeights[molecule] := expected + (MOLECULE_WEIGHT_LEARNING_RATE * error);
  end;
end;

{ TAgentBrain }

class function TAgentBrain.Think(const State: TAgentState; const Input: TBrainTickInput; var Scratch: TAgentScratch): TBrainTickOutput;
begin
  Scratch.EvaluatorScratch := Default(TEvaluatorScratch);
  Scratch.SmellScratch.Count := 0;
  for var action := Low(TAgentAction) to High(TAgentAction) do
    Scratch.ActionScores[action] := 0.0;

  // Observation stage

  // 1. Energy
  var energyInput := BuildEnergyInput(State);
  var energyLevel := Input.GeneMap.Energy.EvaluateEnergyLevel(energyInput);

  // 2. Smell
  var smellParams: TSmellParams;
  smellParams.Ratings := State.Genome.SmellRatings;

  var smellGene := Input.GeneMap.Smell;
  var smellReport := smellGene.Scan(State.Location, smellParams, Input.Query, Scratch.SmellScratch);

  Result.DecisionBuckets := BuildDecisionBuckets(energyLevel, smellReport, Input.SolarFlux <= 0);

  // Evaluation stage

  // 1. Movement
  var moveReport := Default(TMoveReport);
  var moveEval := Input.GeneMap.MoveEval;
  if Assigned(moveEval) then
  begin
    var moveInput := BuildMoveEvalInput(State, smellReport);
    moveReport := moveEval.BuildReport(moveInput, Scratch.EvaluatorScratch.Movement);
  end;

  Scratch.ActionScores[acMove] := 0.0;
  if moveReport.Count > 0 then
    Scratch.ActionScores[acMove] := moveReport.Options[0].Opportunity;

  // 2. Foraging
  var forageReport := Default(TForageReport);
  var forageEval := Input.GeneMap.ForageEval;
  if Assigned(forageEval) then
  begin
    var forageInput := BuildForageEvalInput(State, smellReport);
    forageReport := forageEval.BuildReport(forageInput, Scratch.EvaluatorScratch.Forage);
  end;

  Scratch.ActionScores[acForage] := 0.0;
  if forageReport.Count > 0 then
    Scratch.ActionScores[acForage] := forageReport.Options[0].Opportunity;

  // 3. Shelter
  var shelterEval := Input.GeneMap.ShelterEval;
  if Assigned(shelterEval) then
  begin
    var shelterInput := BuildShelterEvalInput(State, Input, smellReport);
    Scratch.ActionScores[acShelter] := shelterEval.Evaluate(shelterInput, Scratch.EvaluatorScratch.Shelter);
  end;

  // 4. Reproduction
  var localAgentCount := 0;
  var reproduceEval := Input.GeneMap.ReproduceEval;
  if Assigned(reproduceEval) and (State.Action <> acShelter) then
  begin
    if state.Age >= reproduceEval.MinimumAge then
    begin
      var crowdingQuery: IPopulationCrowdingQuery;
      if Supports(Input.Query, IPopulationCrowdingQuery, crowdingQuery) then
      begin
        localAgentCount := crowdingQuery.CountAgentsWithinRadius(State.Location, 1);
        if localAgentCount > 0 then
          Dec(localAgentCount);
      end;
    end;

    var reproduceInput := BuildReproduceEvalInput(State, localAgentCount, Input.GestationDuration);
    Scratch.ActionScores[acReproduce] := reproduceEval.Evaluate(reproduceInput, Scratch.EvaluatorScratch.Reproduce);
  end;

  // Cognition
  var cognitionGene := Input.GeneMap.Cognition;
  if Assigned(cognitionGene) then
  begin
    var weightedScores := BuildWeightedScores(State, Result.DecisionBuckets, Scratch.ActionScores);
    var cognitionInput := BuildCognitionInput(State, smellReport, weightedScores,
      State.ActionTarget, State.Reserves, State.ReserveDelta, State.LastForageCell, forageReport, moveReport);
    var cognitionOutput := cognitionGene.Decide(cognitionInput, Scratch.EvaluatorScratch.Cognition);

    Result.RequestedAction := cognitionOutput.RequestedAction;
    Result.RequestedTarget := cognitionOutput.RequestedTarget;
    Result.DampenedScores := cognitionOutput.DampenedScores;
  end
  else
  begin
    Result.RequestedAction := State.Action;
    Result.RequestedTarget := State.ActionTarget;
  end;

  Result.Scores := Scratch.ActionScores;
end;

class procedure TAgentBrain.Reflect(var State: TAgentState; const Decision: TBrainTickOutput;
  const Input: TBrainReflectInput; var Scratch: TAgentScratch);
begin
  var cognitionGene := Input.GeneMap.Cognition;
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

