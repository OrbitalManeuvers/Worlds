unit u_SimRuntimes;

interface

uses u_AgentState, u_SimEnvironments, u_SimPopulations, u_SimClocks, u_SimQueriesIntf,
  u_SimCommandsIntf, u_AgentBrain, u_AgentTypes, u_SimPhases, u_AgentGenome;

const
  AGENT_BITE_SIZE = 0.1;  // temporary. move to sim params/genome
  AGENT_BASE_MOVE_COST = 0.05; // temporary. move to sim params/genome
  SHELTER_UPKEEP_MULTIPLIER = 0.35;

type
  TRuntimePhaseEvent = procedure (Sender: TObject; Phase: TSimTickPhase) of object;

  TDecisionTrace = record
    DayTick: TDayTick;
    AgentId: Integer;
    IsNight: Boolean;
    RequestedAction: TAgentAction;
    RequestedTarget: TTarget;
    ResolvedAction: TAgentAction;
    ResolvedTarget: TTarget;
    ForageConsumed: Single;
    ForageGain: Single;
    ForageEfficiency: Single;
    Evaluations: TActionEvaluations;
    Summary: TBrainTraceSummary;
  end;

  TSimRuntime = class
  private const
    DEFAULT_DEATH_BIOMASS_AMOUNT = 1.0;
  private
    fCurrentDayTick: TDayTick;
    fEnvironment: TSimEnvironment;
    fHasDecisionTrace: TArray<Boolean>;
    fLastDecisionTraces: TArray<TDecisionTrace>;
    fPopulation: TSimPopulation;
    fSimQuery: ISimQuery;
    fSimCommand: ISimCommand;
    fOnPhase: TRuntimePhaseEvent;
    procedure CaptureDecisionTrace(AgentIndex: Integer; const State: TAgentState; const Input: TBrainTickInput;
      const Requested, Resolved: TBrainTickOutput;
      const ForageConsumed, ForageGain: Single);
    function CalculateAgentTickCost(const State: TAgentState): Single;
    function CalculateMoveCost(FromCell, ToCell: Integer): Single;
    function CalculateForageGain(const State: TAgentState; const Reply: TConsumeCacheReply): Single;
    function ApplyAgentUpkeep(var State: TAgentState): Boolean;
    function ResolveRequestedStep(AgentIndex: Integer; var State: TAgentState; const Requested: TBrainTickOutput;
      out ForageConsumed, ForageGain: Single): TBrainTickOutput;
    procedure ProcessAgentTick(aIndex: Integer; const Input: TBrainTickInput);
    procedure NotifyPhase(const Phase: TSimTickPhase);
    procedure SetDayTick(const Value: TDayTick);
  public
    constructor Create;
    destructor Destroy; override;

    function TryGetLastDecision(AgentIndex: Integer; out Trace: TDecisionTrace): Boolean;

    property Environment: TSimEnvironment read fEnvironment;
    property Population: TSimPopulation read fPopulation;

    property OnPhase: TRuntimePhaseEvent read fOnPhase write fOnPhase;
    property DayTick: TDayTick write SetDayTick;
  end;

implementation

uses System.Math, System.SysUtils, u_SimQueriesImpl,
  u_SimCommandsImpl;

{ TSimRuntime }

constructor TSimRuntime.Create;
begin
  inherited;
  fEnvironment := TSimEnvironment.Create;
  fPopulation := TSimPopulation.Create;
  fSimQuery := TSimQuery.Create(fEnvironment, fPopulation);
  fSimCommand := TSimCommand.Create(fEnvironment, fPopulation);
end;

destructor TSimRuntime.Destroy;
begin
  fSimQuery := nil;
  fSimCommand := nil;
  fEnvironment.Free;
  fPopulation.Free;
  inherited;
end;

procedure TSimRuntime.CaptureDecisionTrace(AgentIndex: Integer; const State: TAgentState; const Input: TBrainTickInput;
  const Requested, Resolved: TBrainTickOutput; const ForageConsumed, ForageGain: Single);
begin
  if (AgentIndex < 0) or (AgentIndex >= Length(fLastDecisionTraces)) then
    Exit;

  fHasDecisionTrace[AgentIndex] := True;

  fLastDecisionTraces[AgentIndex].DayTick := fCurrentDayTick;
  fLastDecisionTraces[AgentIndex].AgentId := State.AgentId;
  fLastDecisionTraces[AgentIndex].IsNight := Input.IsNight;
  fLastDecisionTraces[AgentIndex].RequestedAction := Requested.RequestedAction;
  fLastDecisionTraces[AgentIndex].RequestedTarget := Requested.RequestedTarget;
  fLastDecisionTraces[AgentIndex].ResolvedAction := Resolved.RequestedAction;
  fLastDecisionTraces[AgentIndex].ResolvedTarget := Resolved.RequestedTarget;
  fLastDecisionTraces[AgentIndex].ForageConsumed := ForageConsumed;
  fLastDecisionTraces[AgentIndex].ForageGain := ForageGain;
  if ForageConsumed > 0.0 then
    fLastDecisionTraces[AgentIndex].ForageEfficiency := ForageGain / ForageConsumed
  else
    fLastDecisionTraces[AgentIndex].ForageEfficiency := 0.0;
  fLastDecisionTraces[AgentIndex].Evaluations := Requested.Evaluations;
  fLastDecisionTraces[AgentIndex].Summary := Requested.Trace;
end;

function TSimRuntime.CalculateAgentTickCost(const State: TAgentState): Single;
  function GeneGenerationCost(aGeneClass: TGeneClass): Single;
  begin
    if not Assigned(aGeneClass) then
      Exit(0.0);

    // Placeholder scaling: each generation step above A adds a small upkeep tax.
    Result := (Ord(aGeneClass.GetGenerationCode) - Ord('A') + 1) * 0.01;
    if Result < 0.0 then
      Result := 0.0;
  end;
begin
  // Baseline metabolism comes from genome parameters.
  var baseMetabolism := Max(0.0, State.Genome.Metabolism);

  // Default floor keeps "zeroed" genomes from becoming immortal.
  if baseMetabolism = 0.0 then
    baseMetabolism := 0.05;

  if State.Action = acShelter then
  begin
    // Shelter mode should be materially cheaper and avoid charging inactive systems.
    Result := baseMetabolism
      + GeneGenerationCost(State.Genome.GeneMap.Energy)
      + GeneGenerationCost(State.Genome.GeneMap.ShelterEval)
      + GeneGenerationCost(State.Genome.GeneMap.Cognition);

    Result := Result * SHELTER_UPKEEP_MULTIPLIER;
    Exit;
  end;

  // Sequence-driven upkeep scaffold. Tune weights once behavior loops exist.
  Result := baseMetabolism
    + GeneGenerationCost(State.Genome.GeneMap.Energy)
    + GeneGenerationCost(State.Genome.GeneMap.Smell)
    + GeneGenerationCost(State.Genome.GeneMap.Sight)
    + GeneGenerationCost(State.Genome.GeneMap.MoveEval)
    + GeneGenerationCost(State.Genome.GeneMap.ForageEval)
    + GeneGenerationCost(State.Genome.GeneMap.ShelterEval)
    + GeneGenerationCost(State.Genome.GeneMap.ReproduceEval)
    + GeneGenerationCost(State.Genome.GeneMap.Cognition)
    + GeneGenerationCost(State.Genome.GeneMap.Converter);
end;

function TSimRuntime.ApplyAgentUpkeep(var State: TAgentState): Boolean;
begin
  State.Reserves := State.Reserves - CalculateAgentTickCost(State);
  Result := State.Reserves > 0.0;
  if not Result then
    State.Reserves := 0.0;
end;

function TSimRuntime.CalculateForageGain(const State: TAgentState; const Reply: TConsumeCacheReply): Single;
begin
  var converter := State.Genome.GeneMap.Converter;
  if not Assigned(converter) then
    Exit(Reply.ConsumedAmount);

  var input: TConverterInput;
  input.ConsumedAmount := Reply.ConsumedAmount;
  input.Substance := Reply.Substance;
  input.Ratings := State.Genome.ConverterRatings;

  var scratch: TConverterScratch;
  Result := converter.Convert(input, scratch);
end;

function TSimRuntime.CalculateMoveCost(FromCell, ToCell: Integer): Single;
begin
  Result := AGENT_BASE_MOVE_COST;

  if (ToCell < 0) or (ToCell > High(fEnvironment.Cells)) then
    Exit;

  // Mobility stores terrain penalty in [0..1].
  // Best terrain (0) adds no extra cost; worst terrain (1) doubles baseline.
  var terrainPenalty := EnsureRange(fEnvironment.Cells[ToCell].Mobility, 0.0, 1.0);
  Result := AGENT_BASE_MOVE_COST * (1.0 + terrainPenalty);
end;

function TSimRuntime.ResolveRequestedStep(AgentIndex: Integer; var State: TAgentState;
  const Requested: TBrainTickOutput; out ForageConsumed, ForageGain: Single): TBrainTickOutput;
begin
  // Runtime resolution hook: adjust or reject requested actions based on world rules.
  Result := Requested;
  ForageConsumed := 0.0;
  ForageGain := 0.0;

  if Requested.RequestedAction = acMove then
  begin
    if Requested.RequestedTarget.TType <> ttCell then
    begin
      Result.RequestedAction := acIdle;
      Result.RequestedTarget.TType := ttCell;
      Result.RequestedTarget.Cell := State.Location;
      Exit;
    end;

    var moveCommand: IMoveAgentCommand;
    if Supports(fSimCommand, IMoveAgentCommand, moveCommand) then
    begin
      var moveRequest: TMoveAgentRequest;
      moveRequest.AgentIndex := AgentIndex;
      moveRequest.DestinationCell := Requested.RequestedTarget.Cell;

      var moveReply: TMoveAgentReply := Default(TMoveAgentReply);
      if moveCommand.TryMoveAgent(moveRequest, moveReply) then
      begin
        // Keep local runtime copy aligned with command-applied population state.
        var moveCost := CalculateMoveCost(moveReply.PreviousCell, moveReply.NewCell);
        State.Reserves := State.Reserves - moveCost;
        if State.Reserves < 0.0 then
          State.Reserves := 0.0;

        State.Location := moveReply.NewCell;
        Result.RequestedAction := acMove;
        Result.RequestedTarget.TType := ttCell;
        Result.RequestedTarget.Cell := moveReply.NewCell;
      end
      else
      begin
        Result.RequestedAction := acIdle;
        Result.RequestedTarget.TType := ttCell;
        Result.RequestedTarget.Cell := State.Location;
      end;
    end
    else
    begin
      Result.RequestedAction := acIdle;
      Result.RequestedTarget.TType := ttCell;
      Result.RequestedTarget.Cell := State.Location;
    end;

    Exit;
  end;

  if (Requested.RequestedAction = acForage) and (Requested.RequestedTarget.TType = ttCache) then
  begin
    var cacheId := Requested.RequestedTarget.CacheId;
    var isLocalCache := False;

    if (State.Location >= 0) and (State.Location <= High(fEnvironment.Cells)) then
    begin
      var cell := fEnvironment.Cells[State.Location];
      for var i := 0 to cell.ResourceCount - 1 do
        if (Integer(cell.ResourceStart) + i) = cacheId then
        begin
          isLocalCache := True;
          Break;
        end;
    end;

    // Smell can detect remote opportunities, but foraging is local-only until movement/pathing is resolved.
    if not isLocalCache then
    begin
      Result.RequestedAction := acIdle;
      Result.RequestedTarget.TType := ttCell;
      Result.RequestedTarget.Cell := State.Location;
      Exit;
    end;

    var forageCommand: IEnvironmentForageCommand;
    if Supports(fSimCommand, IEnvironmentForageCommand, forageCommand) then
    begin
      var reply: TConsumeCacheReply := Default(TConsumeCacheReply);

      var request: TConsumeCacheRequest;
      request.CacheId := cacheId;
      request.RequestedAmount := AGENT_BITE_SIZE;

      if forageCommand.TryConsumeCache(request, reply) then
      begin
        ForageConsumed := reply.ConsumedAmount;
        ForageGain := CalculateForageGain(State, reply);
        State.Reserves := State.Reserves + ForageGain;
      end
      else
      begin
        // Failed consume attempts should not pin the agent in an unavailable forage.
        Result.RequestedAction := acIdle;
        Result.RequestedTarget.TType := ttCell;
        Result.RequestedTarget.Cell := State.Location;
      end;
    end;
  end;
end;

procedure TSimRuntime.ProcessAgentTick(aIndex: Integer; const Input: TBrainTickInput);
begin
  // Trace availability is per-tick; clear first so dead/idle paths do not leak stale traces.
  if (aIndex >= 0) and (aIndex < Length(fHasDecisionTrace)) then
    fHasDecisionTrace[aIndex] := False;

  var state: TAgentState;
  if not fPopulation.TryGetAgentState(aIndex, state) then
    Exit;

  // Dead agents remain in population data but do not age or think.
  var wasAlive := state.Reserves > 0.0;
  if not wasAlive then
    Exit;

  // Age tracks ticks survived; this includes the tick where upkeep may cause death.
  Inc(state.Age);

  if not ApplyAgentUpkeep(state) then
  begin
    // Dead agents do not think or request actions.
    state.Action := acIdle;
    fPopulation.UpdateAgentState(aIndex, state);

    // Notify environment once at transition-to-death.
    fEnvironment.NotifyAgentDeath(state.Location, DEFAULT_DEATH_BIOMASS_AMOUNT);
    Exit;
  end;

  // Commit upkeep effects before the brain reads state.
  fPopulation.UpdateAgentState(aIndex, state);

  var requested := fPopulation.RequestAgentStep(aIndex, Input);
  var forageConsumed: Single := 0.0;
  var forageGain: Single := 0.0;
  var resolved := ResolveRequestedStep(aIndex, state, requested, forageConsumed, forageGain);
  CaptureDecisionTrace(aIndex, state, Input, requested, resolved, forageConsumed, forageGain);
  fPopulation.UpdateAgentState(aIndex, state);
  fPopulation.ApplyAgentStep(aIndex, resolved);
end;

procedure TSimRuntime.NotifyPhase(const Phase: TSimTickPhase);
begin
  if Assigned(fOnPhase) then
    fOnPhase(Self, Phase);
end;

procedure TSimRuntime.SetDayTick(const Value: TDayTick);
begin
  fCurrentDayTick := Value;
  fEnvironment.DayTick := Value;
  NotifyPhase(stpPostEnvironment);

  if Length(fLastDecisionTraces) <> fPopulation.AgentCount then
  begin
    SetLength(fLastDecisionTraces, fPopulation.AgentCount);
    SetLength(fHasDecisionTrace, fPopulation.AgentCount);
  end;

  var input: TBrainTickInput;
  input.IsNight := Value > High(TDaylightTicks);
  input.Query := fSimQuery;

  var agentCount := fPopulation.AgentCount;
  if agentCount > 0 then
  begin
    // Fairness pass: randomize both start index and traversal direction each tick.
    var startIndex := Random(agentCount);
    var direction := 1;
    if Random(2) = 0 then
      direction := -1;

    for var pass := 0 to agentCount - 1 do
    begin
      var agentIndex := (startIndex + (direction * pass)) mod agentCount;
      if agentIndex < 0 then
        agentIndex := agentIndex + agentCount;

      ProcessAgentTick(agentIndex, input);
    end;
  end;

  NotifyPhase(stpPostAgents);
end;

function TSimRuntime.TryGetLastDecision(AgentIndex: Integer; out Trace: TDecisionTrace): Boolean;
begin
  Result := (AgentIndex >= 0) and (AgentIndex < Length(fLastDecisionTraces));
  if not Result then
  begin
    Trace := Default(TDecisionTrace);
    Exit;
  end;

  Result := fHasDecisionTrace[AgentIndex];
  if Result then
    Trace := fLastDecisionTraces[AgentIndex]
  else
    Trace := Default(TDecisionTrace);
end;

end.
