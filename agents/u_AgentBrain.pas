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
    RequestedTarget: TAgentTarget;
    Scores: TActionScores;
  end;

  // Caller-owned per-agent scratch state reused across ticks.
  // This keeps the brain stateless while avoiding per-tick temp allocations.
  TAgentScratch = record
    SmellCacheBuffer: TSmellCacheInfos;
    SmellCacheCount: Integer;
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
  SmellCacheCount := 0;

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
  if Assigned(State.Genome.GeneMap.Smell) then
  begin
    var smellParams: TSmellParams;
    smellParams.Range := State.Genome.SmellRange;
    smellParams.Ratings := State.Genome.SmellRatings;

    Scratch.DecisionContext.Smell := State.Genome.GeneMap.Smell.Scan(
      State.Location,
      smellParams,
      Input.Query);
  end;

  if Assigned(State.Genome.GeneMap.Sight) then
    Scratch.DecisionContext.Sight := State.Genome.GeneMap.Sight.Scan(
      State.Location,
      State.Genome.SightRange,
      Input.Query);

  // Evaluation stage: score available actions.
  if Assigned(State.Genome.GeneMap.ForageEval) then
    Scratch.ActionScores[acForage] :=
      State.Genome.GeneMap.ForageEval.Score(Scratch.DecisionContext);

  // Decision stage placeholder: keep current action until cognition is wired.
  Result.RequestedAction := State.Action;
  Result.RequestedTarget := State.ActionTarget;
  Result.Scores := Scratch.ActionScores;
end;

end.
