unit u_SimRuntimes;

interface

uses u_AgentState, u_SimDiagnosticsIntf, u_SimEnvironments, u_SimPopulations, u_SimClocks, u_SimQueriesIntf,
  u_SimCommandsIntf, u_AgentBrain, u_AgentTypes, u_SimPhases, u_AgentGenome;

const
  AGENT_BITE_SIZE = 0.1;  // temporary. move to sim params/genome
  AGENT_BASE_MOVE_COST = 0.05; // temporary. move to sim params/genome
  SHELTER_UPKEEP_MULTIPLIER = 0.35;
  AGENT_BASE_METABOLISM = 0.01;  // physics floor: applies to all agents regardless of genome
  GENE_GENERATION_COST = 0.005;  // upkeep added per generation above A for each gene slot
  AGENT_MAX_RESERVES = 10.0;     // hard ceiling on energy reserves
  REPRODUCTION_PARENT_MIN_RESERVES = 4.0;
  REPRODUCTION_CHILD_START_RESERVES = 2.0;
  REPRODUCTION_PARENT_COST = 2.0;

type
  TRuntimePhaseEvent = procedure (Sender: TObject; Phase: TSimTickPhase) of object;

  TBiomassRuntimeConfig = record
    InjectOnDeath: Boolean;
    InjectAtNightfall: Boolean;
    InjectRandomlyAtNight: Boolean;
    NightfallCacheCount: Integer;
    RandomInjectChancePercent: Integer;
  end;

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
    fCurrentGlobalTick: Cardinal;
    fCurrentDayTick: TDayTick;
    fBiomassConfig: TBiomassRuntimeConfig;
    fEnvironment: TSimEnvironment;
    fHasDecisionTrace: TArray<Boolean>;
    fLastDecisionTraces: TArray<TDecisionTrace>;
    fPopulation: TSimPopulation;
    fDiagnostics: ISimDiagnosticsSink;
    fSimQuery: ISimQuery;
    fSimCommand: ISimCommand;
    fOnPhase: TRuntimePhaseEvent;
    function BuildEventHeader(aKind: TSimEventKind; const aPhase: TSimTickPhase): TSimEventHeader;
    procedure EmitActionResolved(const State: TAgentState; const Requested, Resolved: TBrainTickOutput);
    procedure EmitAgentBorn(const OffspringState: TAgentState; const ParentAgentId: Integer);
    procedure EmitAgentDied(const State: TAgentState; const ReservesBeforeDeath: Single);
    procedure EmitAgentMoved(const State: TAgentState; const FromCell, ToCell: Integer; const MoveCost: Single);
    procedure EmitBiomassConsumed(const State: TAgentState; const Cache: TCacheRef; const ConsumedAmount, GainAmount: Single);
    procedure EmitBiomassCreated(const CellIndex: Integer; const Amount: Single;
      const Reason: TBiomassCreateReason; const SourceAgentId: Integer; const Phase: TSimTickPhase);
    procedure CaptureDecisionTrace(AgentIndex: Integer; const State: TAgentState; const Input: TBrainTickInput;
      const Requested, Resolved: TBrainTickOutput;
      const ForageConsumed, ForageGain: Single);
    function CalculateAgentTickCost(const State: TAgentState): Single;
    function CalculateMoveCost(FromCell, ToCell: Integer): Single;
    function CalculateForageGain(const State: TAgentState; const Reply: TConsumeCacheReply): Single;
    function BuildOffspringState(const ParentState: TAgentState; const OffspringId: Integer): TAgentState;
    function NextAgentId: Integer;
    function ApplyAgentUpkeep(var State: TAgentState): Boolean;
    procedure InjectSimBiomass(const IsNightfall: Boolean);
    function ResolveRequestedStep(AgentIndex: Integer; var State: TAgentState; const Requested: TBrainTickOutput;
      out ForageConsumed, ForageGain: Single): TBrainTickOutput;
    procedure ProcessAgentTick(aIndex: Integer; const Input: TBrainTickInput);
    procedure NotifyPhase(const Phase: TSimTickPhase);
    procedure SetDayTick(const Value: TDayTick);
  public
    constructor Create(const aBiomassConfig: TBiomassRuntimeConfig; const aDiagnostics: ISimDiagnosticsSink = nil);
    destructor Destroy; override;

    procedure AdvanceClock(const GlobalTick: Cardinal; const DayTick: TDayTick);
    function TryGetLastDecision(AgentIndex: Integer; out Trace: TDecisionTrace): Boolean;

    property Environment: TSimEnvironment read fEnvironment;
    property Population: TSimPopulation read fPopulation;

    property OnPhase: TRuntimePhaseEvent read fOnPhase write fOnPhase;
  end;

implementation

uses System.Math, System.SysUtils, u_SimQueriesImpl,
  u_SimCommandsImpl;

{ TSimRuntime }

constructor TSimRuntime.Create(const aBiomassConfig: TBiomassRuntimeConfig; const aDiagnostics: ISimDiagnosticsSink);
begin
  inherited Create;
  fBiomassConfig := aBiomassConfig;
  fDiagnostics := aDiagnostics;
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

    // Gen-A costs nothing. Each generation above A adds an upkeep tax.
    Result := (Ord(aGeneClass.GetGenerationCode) - Ord('A')) * GENE_GENERATION_COST;
    if Result < 0.0 then
      Result := 0.0;
  end;
begin
  if State.Action = acShelter then
  begin
    // Shelter mode: base physics cost only, plus active genes (energy, shelter, cognition).
    Result := AGENT_BASE_METABOLISM
      + GeneGenerationCost(State.Genome.GeneMap.Energy)
      + GeneGenerationCost(State.Genome.GeneMap.ShelterEval)
      + GeneGenerationCost(State.Genome.GeneMap.Cognition);

    Result := Result * SHELTER_UPKEEP_MULTIPLIER;
    Exit;
  end;

  // Full upkeep: base physics cost plus all active gene generation taxes.
  Result := AGENT_BASE_METABOLISM
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

procedure TSimRuntime.InjectSimBiomass(const IsNightfall: Boolean);
var
  cellCount: Integer;
  width: Integer;
  height: Integer;
  function IsSafeInjectionCell(const CellIndex: Integer): Boolean;
  begin
    Result := (CellIndex >= 0) and (CellIndex < cellCount);
    if not Result then
      Exit;

    var cellX := CellIndex mod width;
    var cellY := CellIndex div width;

    for var agentIndex := 0 to fPopulation.AgentCount - 1 do
    begin
      var state: TAgentState;
      if not fPopulation.TryGetAgentState(agentIndex, state) then
        Continue;

      if state.Reserves <= 0.0 then
        Continue;

      if (state.Location < 0) or (state.Location >= cellCount) then
        Continue;

      var agentX := state.Location mod width;
      var agentY := state.Location div width;
      var distance := Abs(agentX - cellX);
      if Abs(agentY - cellY) > distance then
        distance := Abs(agentY - cellY);

      // Avoid creating biomass in the current cell or immediate neighborhood of a living agent.
      if distance < 2 then
        Exit(False);
    end;
  end;

  function TryFindInjectionCell(out CellIndex: Integer): Boolean;
  begin
    Result := False;
    CellIndex := -1;

    var randomAttempts := cellCount;
    if randomAttempts > 16 then
      randomAttempts := 16;

    for var attempt := 1 to randomAttempts do
    begin
      var candidate := Random(cellCount);
      if IsSafeInjectionCell(candidate) then
      begin
        CellIndex := candidate;
        Exit(True);
      end;
    end;

    var startIndex := Random(cellCount);
    for var offset := 0 to cellCount - 1 do
    begin
      var candidate := (startIndex + offset) mod cellCount;
      if IsSafeInjectionCell(candidate) then
      begin
        CellIndex := candidate;
        Exit(True);
      end;
    end;
  end;

begin
  cellCount := Length(fEnvironment.Cells);
  if cellCount <= 0 then
    Exit;

  width := fEnvironment.Dimensions.cx;
  height := fEnvironment.Dimensions.cy;
  if (width <= 0) or (height <= 0) then
    Exit;

  if IsNightfall and fBiomassConfig.InjectAtNightfall then
  begin
    for var i := 1 to fBiomassConfig.NightfallCacheCount do
    begin
      var cellIndex := -1;
      if TryFindInjectionCell(cellIndex) then
      begin
        fEnvironment.InjectBiomass(cellIndex, DEFAULT_DEATH_BIOMASS_AMOUNT);
        EmitBiomassCreated(cellIndex, DEFAULT_DEATH_BIOMASS_AMOUNT, bcrNightfallInjection, -1, stpPostEnvironment);
      end;
    end;
  end;

  if fBiomassConfig.InjectRandomlyAtNight and (fBiomassConfig.RandomInjectChancePercent > 0) then
  begin
    if Random(100) < fBiomassConfig.RandomInjectChancePercent then
    begin
      var cellIndex := -1;
      if TryFindInjectionCell(cellIndex) then
      begin
        fEnvironment.InjectBiomass(cellIndex, DEFAULT_DEATH_BIOMASS_AMOUNT);
        EmitBiomassCreated(cellIndex, DEFAULT_DEATH_BIOMASS_AMOUNT, bcrRandomNightInjection, -1, stpPostEnvironment);
      end;
    end;
  end;
end;

function TSimRuntime.BuildEventHeader(aKind: TSimEventKind; const aPhase: TSimTickPhase): TSimEventHeader;
begin
  Result := Default(TSimEventHeader);
  Result.DayNumber := fCurrentGlobalTick div CLOCK_TICKS_PER_DAY;
  Result.DayTick := fCurrentDayTick;
  Result.Phase := aPhase;
  Result.Kind := aKind;
end;

procedure TSimRuntime.EmitActionResolved(const State: TAgentState; const Requested,
  Resolved: TBrainTickOutput);
begin
  if not Assigned(fDiagnostics) then
    Exit;

  var event := Default(TSimEvent);
  event.Header := BuildEventHeader(sekActionResolved, stpPostAgents);
  event.ActionResolved.AgentId := State.AgentId;
  event.ActionResolved.RequestedAction := Requested.RequestedAction;
  event.ActionResolved.RequestedTarget := Requested.RequestedTarget;
  event.ActionResolved.ResolvedAction := Resolved.RequestedAction;
  event.ActionResolved.ResolvedTarget := Resolved.RequestedTarget;
  fDiagnostics.Emit(event);
end;

procedure TSimRuntime.EmitAgentBorn(const OffspringState: TAgentState; const ParentAgentId: Integer);
begin
  if not Assigned(fDiagnostics) then
    Exit;

  var event := Default(TSimEvent);
  event.Header := BuildEventHeader(sekAgentBorn, stpPostAgents);
  event.AgentBorn.AgentId := OffspringState.AgentId;
  event.AgentBorn.ParentAgentId := ParentAgentId;
  event.AgentBorn.CellIndex := OffspringState.Location;
  event.AgentBorn.InitialReserves := OffspringState.Reserves;
  fDiagnostics.Emit(event);
end;

procedure TSimRuntime.EmitAgentDied(const State: TAgentState; const ReservesBeforeDeath: Single);
begin
  if not Assigned(fDiagnostics) then
    Exit;

  var event := Default(TSimEvent);
  event.Header := BuildEventHeader(sekAgentDied, stpPostAgents);
  event.AgentDied.AgentId := State.AgentId;
  event.AgentDied.CellIndex := State.Location;
  event.AgentDied.Age := State.Age;
  event.AgentDied.ReservesBeforeDeath := ReservesBeforeDeath;
  fDiagnostics.Emit(event);
end;

procedure TSimRuntime.EmitAgentMoved(const State: TAgentState; const FromCell, ToCell: Integer;
  const MoveCost: Single);
begin
  if not Assigned(fDiagnostics) then
    Exit;

  var event := Default(TSimEvent);
  event.Header := BuildEventHeader(sekAgentMoved, stpPostAgents);
  event.AgentMoved.AgentId := State.AgentId;
  event.AgentMoved.FromCell := FromCell;
  event.AgentMoved.ToCell := ToCell;
  event.AgentMoved.MoveCost := MoveCost;
  fDiagnostics.Emit(event);
end;

procedure TSimRuntime.EmitBiomassConsumed(const State: TAgentState; const Cache: TCacheRef;
  const ConsumedAmount, GainAmount: Single);
begin
  if not Assigned(fDiagnostics) then
    Exit;

  var event := Default(TSimEvent);
  event.Header := BuildEventHeader(sekBiomassConsumed, stpPostAgents);
  event.BiomassConsumed.AgentId := State.AgentId;
  event.BiomassConsumed.CellIndex := State.Location;
  event.BiomassConsumed.Cache := Cache;
  event.BiomassConsumed.ConsumedAmount := ConsumedAmount;
  event.BiomassConsumed.GainAmount := GainAmount;
  fDiagnostics.Emit(event);
end;

procedure TSimRuntime.EmitBiomassCreated(const CellIndex: Integer; const Amount: Single;
  const Reason: TBiomassCreateReason; const SourceAgentId: Integer; const Phase: TSimTickPhase);
begin
  if not Assigned(fDiagnostics) then
    Exit;

  var event := Default(TSimEvent);
  event.Header := BuildEventHeader(sekBiomassCreated, Phase);
  event.BiomassCreated.CellIndex := CellIndex;
  event.BiomassCreated.Amount := Amount;
  event.BiomassCreated.Reason := Reason;
  event.BiomassCreated.SourceAgentId := SourceAgentId;
  fDiagnostics.Emit(event);
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

function TSimRuntime.BuildOffspringState(const ParentState: TAgentState;
  const OffspringId: Integer): TAgentState;
begin
  Result := Default(TAgentState);
  Result.AgentId := OffspringId;
  Result.Location := ParentState.Location;
  Result.Age := 0;
  Result.Reserves := REPRODUCTION_CHILD_START_RESERVES;
  Result.TicksSinceReproduction := 0;
  Result.Action := acIdle;
  Result.ActionProgress := 0;
  Result.ActionTarget.TType := ttCell;
  Result.ActionTarget.Cell := ParentState.Location;
  Result.Genome := ParentState.Genome;
end;

function TSimRuntime.NextAgentId: Integer;
begin
  Result := 1;

  for var agentIndex := 0 to fPopulation.AgentCount - 1 do
  begin
    var state: TAgentState;
    if not fPopulation.TryGetAgentState(agentIndex, state) then
      Continue;

    if state.AgentId >= Result then
      Result := state.AgentId + 1;
  end;
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

  if Requested.RequestedAction = acReproduce then
  begin
    if State.Reserves < REPRODUCTION_PARENT_MIN_RESERVES then
    begin
      Result.RequestedAction := acIdle;
      Result.RequestedTarget.TType := ttCell;
      Result.RequestedTarget.Cell := State.Location;
      Exit;
    end;

    var offspringState := BuildOffspringState(State, NextAgentId);
    State.Reserves := State.Reserves - REPRODUCTION_PARENT_COST;
    if State.Reserves < 0.0 then
      State.Reserves := 0.0;
    State.TicksSinceReproduction := 0;
    fPopulation.AppendAgent(offspringState);
    EmitAgentBorn(offspringState, State.AgentId);

    Result.RequestedAction := acReproduce;
    Result.RequestedTarget.TType := ttCell;
    Result.RequestedTarget.Cell := State.Location;
    Exit;
  end;

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
      var moveDestination := Requested.RequestedTarget.Cell;

      // Decompose remote intent into a legal one-step move while preserving the
      // original destination as the action target for continuity across ticks.
      var width := fEnvironment.Dimensions.cx;
      var height := fEnvironment.Dimensions.cy;
      if (width > 0) and (height > 0) then
      begin
        var fromX := State.Location mod width;
        var fromY := State.Location div width;
        var toX := moveDestination mod width;
        var toY := moveDestination div width;

        var dx := toX - fromX;
        var dy := toY - fromY;

        if Max(Abs(dx), Abs(dy)) > 1 then
        begin
          var stepX := fromX;
          var stepY := fromY;

          if dx < 0 then
            Dec(stepX)
          else if dx > 0 then
            Inc(stepX);

          if dy < 0 then
            Dec(stepY)
          else if dy > 0 then
            Inc(stepY);

          moveDestination := (stepY * width) + stepX;
        end;
      end;

      var moveRequest: TMoveAgentRequest;
      moveRequest.AgentIndex := AgentIndex;
      moveRequest.DestinationCell := moveDestination;

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
        Result.RequestedTarget := Requested.RequestedTarget;
        EmitAgentMoved(State, moveReply.PreviousCell, moveReply.NewCell, moveCost);
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
    var cacheRef := Requested.RequestedTarget.Cache;
    var isLocalCache := False;

    if (State.Location >= 0) and (State.Location <= High(fEnvironment.Cells)) then
    begin
      case cacheRef.Kind of
        ckResource:
          begin
            var cell := fEnvironment.Cells[State.Location];
            for var i := 0 to cell.ResourceCount - 1 do
              if (Integer(cell.ResourceStart) + i) = cacheRef.Index then
              begin
                isLocalCache := True;
                Break;
              end;
          end;
        ckBiomass:
          begin
            if (cacheRef.Index >= 0) and (cacheRef.Index <= High(fEnvironment.BiomassCaches)) then
              isLocalCache := fEnvironment.BiomassCaches[cacheRef.Index].CellIndex = State.Location;
          end;
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
      request.Cache := cacheRef;
      request.RequestedAmount := AGENT_BITE_SIZE;

      if forageCommand.TryConsumeCache(request, reply) then
      begin
        ForageConsumed := reply.ConsumedAmount;
        ForageGain := CalculateForageGain(State, reply);
        State.Reserves := State.Reserves + ForageGain;
        if State.Reserves > AGENT_MAX_RESERVES then
          State.Reserves := AGENT_MAX_RESERVES;

        if cacheRef.Kind = ckBiomass then
          EmitBiomassConsumed(State, cacheRef, ForageConsumed, ForageGain);
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
  Inc(state.TicksSinceReproduction);

  var reservesBeforeUpkeep := state.Reserves;

  if not ApplyAgentUpkeep(state) then
  begin
    // Dead agents do not think or request actions.
    state.Action := acIdle;
    fPopulation.UpdateAgentState(aIndex, state);
    EmitAgentDied(state, reservesBeforeUpkeep);

    // Notify environment once at transition-to-death.
    if fBiomassConfig.InjectOnDeath then
    begin
      fEnvironment.NotifyAgentDeath(state.Location, DEFAULT_DEATH_BIOMASS_AMOUNT);
      EmitBiomassCreated(state.Location, DEFAULT_DEATH_BIOMASS_AMOUNT, bcrAgentDeath, state.AgentId, stpPostAgents);
    end;
    Exit;
  end;

  // Commit upkeep effects before the brain reads state.
  fPopulation.UpdateAgentState(aIndex, state);

  var requested := fPopulation.RequestAgentStep(aIndex, Input);
  var forageConsumed: Single := 0.0;
  var forageGain: Single := 0.0;
  var resolved := ResolveRequestedStep(aIndex, state, requested, forageConsumed, forageGain);
  CaptureDecisionTrace(aIndex, state, Input, requested, resolved, forageConsumed, forageGain);
  EmitActionResolved(state, requested, resolved);
  fPopulation.UpdateAgentState(aIndex, state);
  fPopulation.ApplyAgentStep(aIndex, resolved);
end;

procedure TSimRuntime.AdvanceClock(const GlobalTick: Cardinal; const DayTick: TDayTick);
begin
  fCurrentGlobalTick := GlobalTick;
  SetDayTick(DayTick);
end;

procedure TSimRuntime.NotifyPhase(const Phase: TSimTickPhase);
begin
  if Assigned(fOnPhase) then
    fOnPhase(Self, Phase);
end;

procedure TSimRuntime.SetDayTick(const Value: TDayTick);
begin
  var previousSolarFlux := fEnvironment.SolarFlux;

  fCurrentDayTick := Value;
  fEnvironment.DayTick := Value;
  var currentSolarFlux := fEnvironment.SolarFlux;

  var isNightTick := Value > High(TDaylightTicks);
  var isNightfall := isNightTick and (previousSolarFlux > 0.0) and (currentSolarFlux = 0.0);
  if isNightTick then
    InjectSimBiomass(isNightfall);

  NotifyPhase(stpPostEnvironment);

  if Length(fLastDecisionTraces) <> fPopulation.AgentCount then
  begin
    SetLength(fLastDecisionTraces, fPopulation.AgentCount);
    SetLength(fHasDecisionTrace, fPopulation.AgentCount);
  end;

  var input: TBrainTickInput;
  input.IsNight := isNightTick;
  input.SolarFlux := currentSolarFlux;
  input.SolarFluxDelta := currentSolarFlux - previousSolarFlux;
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
