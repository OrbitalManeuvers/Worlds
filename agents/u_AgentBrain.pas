unit u_AgentBrain;

interface

uses u_AgentTypes, u_AgentState, u_AgentGenome, u_SimQueriesIntf;

type
  TActionScores = array[TAgentAction] of Single;

  // Runtime-owned inputs for one brain decision pass.
  TBrainTickInput = record
    IsNight: Boolean;
    Query: ISimQuery;
  end;

  // Result returned by the brain to the population/sim tick routine.
  TBrainTickOutput = record
    RequestedAction: TAgentAction;
    RequestedTarget: TTarget;
    Scores: TActionScores;
  end;

  // Caller-owned per-agent scratch state reused across ticks.
  // This keeps the brain stateless while avoiding per-tick temp allocations.
  TAgentScratch = record
    SensorScratch: TSensorScanScratch;
    EvaluatorScratch: TEvaluatorScratch;
    DecisionContext: TDecisionContext;
    ActionScores: TActionScores;
    procedure BeginTick(const State: TAgentState; const Input: TBrainTickInput);
  end;

  TAgentBrain = class
  public
    class function Think(const State: TAgentState; const Input: TBrainTickInput;
      var Scratch: TAgentScratch): TBrainTickOutput; static;
  end;

implementation

function BuildForageEvalInput(const Context: TDecisionContext): TForageEvalInput;
begin
  Result.IsNight := Context.IsNight;
  Result.Reserves := Context.Reserves;
  Result.CurrentAction := Context.CurrentAction;
  Result.Smell := Context.Smell;
end;

function DeriveReserveLevel(const Reserves: Single): TEnergyLevel;
begin
  // Placeholder buckets while reserves are treated as the canonical energy state.
  if Reserves <= 0.0 then
    Exit(elEmpty);

  if Reserves < 25.0 then
    Exit(elLow);

  if Reserves < 50.0 then
    Exit(elMedium);

  if Reserves < 75.0 then
    Exit(elHigh);

  Result := elFull;
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
  DecisionContext.Reserves := DeriveReserveLevel(State.Reserves);

  for var action := Low(TAgentAction) to High(TAgentAction) do
    ActionScores[action] := 0.0;
end;

{ TAgentBrain }

class function TAgentBrain.Think(const State: TAgentState; const Input: TBrainTickInput; var Scratch: TAgentScratch): TBrainTickOutput;
begin
  Scratch.BeginTick(State, Input);

  // Observation stage: enrich context from available genes.

  // 1. Energy

  // 2. Smell
  if Assigned(State.Genome.GeneMap.Smell) then
  begin
    // allow parameters to adjust the gene's operation
    var smellParams: TSmellParams;
    smellParams.Range := State.Genome.SmellRange;
    smellParams.Ratings := State.Genome.SmellRatings;

    // activate the gene and save its reply
    var smellGene := State.Genome.GeneMap.Smell;
    var smellReport := smellGene.Scan(State.Location, smellParams, Input.Query, Scratch.SensorScratch.Smell);

    Scratch.DecisionContext.Smell := smellReport;
  end;

  // 3. Sight
  if Assigned(State.Genome.GeneMap.Sight) then
  begin
    var sightGene := State.Genome.GeneMap.Sight;
    var sightReport := sightGene.Scan(State.Location, State.Genome.SightRange, Input.Query, Scratch.SensorScratch.Sight);

    Scratch.DecisionContext.Sight := sightReport;
  end;

  // Evaluation stage: score available actions.

//    MoveEval: TMoveEvalGeneClass;

  // Foraging
  var forageEval := State.Genome.GeneMap.ForageEval;
  if Assigned(forageEval) then
  begin
    var forageInput := BuildForageEvalInput(Scratch.DecisionContext);
    Scratch.ActionScores[acForage] := forageEval.Score(forageInput, Scratch.EvaluatorScratch.Forage);
  end;

  // shelter
  var shelterEval := State.Genome.GeneMap.ShelterEval;
  if Assigned(shelterEval) then
    Scratch.ActionScores[acShelter] := 0; // shelterEval.

  // reproduction
  var reproduceEval := State.Genome.GeneMap.ReproduceEval;
  if Assigned(reproduceEval) then
    Scratch.ActionScores[acReproduce] := 0; // reproduceEval.


  // cognition



  // Decision stage placeholder: keep current action until cognition is wired.
  Result.RequestedAction := State.Action;
  Result.RequestedTarget := State.ActionTarget;
  Result.Scores := Scratch.ActionScores;
end;

end.
