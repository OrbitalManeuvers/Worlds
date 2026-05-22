unit u_SimRuntimes;

interface

uses System.Types,
  u_AgentState, u_SimEventTypes, u_SimEnvironments, u_SimPopulations, u_SimClocks, u_SimQueriesIntf,
  u_SimCommandsIntf, u_AgentBrain, u_AgentTypes, u_SimPhases, u_AgentGenome;

const
  AGENT_BITE_SIZE = 0.1;  // temporary. move to sim params/genome
  AGENT_BASE_MOVE_COST = 0.05; // temporary. move to sim params/genome
  SHELTER_ENTRY_COST = 0.02;
  SHELTER_UPKEEP_MULTIPLIER = 0.35;
  AGENT_BASE_METABOLISM = 0.01;  // physics floor: applies to all agents regardless of genome
  GENE_GENERATION_COST = 0.005;  // upkeep added per generation above A for each gene slot
  REPRODUCTION_DURATION_TICKS = 3;
  REPRODUCTION_CHILD_START_RESERVES = 2.0;
  REPRODUCTION_FATIGUE_BASE = 0.10;
  REPRODUCTION_FATIGUE_STEP = 0.10;
  // Completion still carries the main drain, but gestation now pays meaningful
  // sunk cost before birth so abandoning it is less free.
  REPRODUCTION_PARENT_COST = 3.8;

  // AGENT_MAX_RESERVES: no hard cap currently — tuning unbounded.
  // Target: ~25.0 (covers a half-region round trip on flat terrain at base move cost).
  // Math: 128 cells x 2 (round trip) x 0.05 (move) + 256 ticks x 0.01 (metabolism) ~= 15.
  // Add margin for terrain variation and overhead -> ~25.
  // Grid basis: 32x32 authored region, scale factor 8 -> 256x256 sim cells per region.

type
  TRuntimePhaseEvent = procedure (Sender: TObject; Phase: TSimTickPhase) of object;
  TCellIndexArray = TArray<Integer>;
  TCellIndexCycles = array of TCellIndexArray;

  TRuntimeConfig = record
//    NightfallCacheCount: Integer;
    AgentActivationTick: Integer;
//    DeltaEnabled: Boolean;
//    DeltaNightlyCacheCount: Integer;
//    DeltaInitialAmount: Single;
//    DeltaCycleLength: Integer;
//    DeltaMinSpacingCells: Integer;
//    DeltaCleanupGraceTicks: Integer;
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
    DEFAULT_DELTA_CACHE_AMOUNT = 0.0;
    DELTA_CREATE_TICK = DAYLIGHT_TICKS_PER_DAY;
    DELTA_CLEANUP_GRACE_TICKS = 0;
    DELTA_EXTINCTION_EPSILON = 0.001;
    DELTA_PLACEMENT_CYCLE_COUNT = 3;
    DELTA_MIN_SPACING_CELLS = 4;
    DELTA_MAX_CACHES_PER_NIGHT = 32;
  private
    fCurrentGlobalTick: Integer;
    fCurrentDayTick: TDayTick;
    fRuntimeConfig: TRuntimeConfig;
    fEnvironment: TSimEnvironment;
    fHasDecisionTrace: TArray<Boolean>;
    fLastDecisionTraces: TArray<TDecisionTrace>;
    fPopulation: TSimPopulation;
    fDiagnostics: ISimDiagnosticsSink;
    fSimQuery: ISimQuery;
    fSimCommand: ISimCommand;
    fOnPhase: TRuntimePhaseEvent;
    fTrackedResourceCacheIndex: Integer;
    fDeltaPlacementCycles: TCellIndexCycles;
    fDeltaPlacementCycleIndex: Integer;
    fLastDeltaSpawnCount: Integer;
    fDeltaCleanupGraceTicksRemaining: Integer;
    function BuildEventHeader(aKind: TSimEventKind; const aPhase: TSimTickPhase): TSimEventHeader;
    function BuildDeltaSpawnPlan: TArray<Integer>;
    procedure InjectDeltaAtNightfall;
    procedure HandleDeltaCleanupPolicy(const Report: TDeltaUpkeepReport);
    procedure EmitActionResolved(const StateBeforeResolution, State: TAgentState; const Requested, Resolved: TBrainTickOutput);
    procedure EmitDecisionTrace(const State: TAgentState; const Trace: TDecisionTrace);
    procedure EmitAgentBorn(const OffspringState: TAgentState; const ParentAgentId: Integer);
    procedure EmitAgentDied(const State: TAgentState; const ReservesBeforeDeath: Single);
    procedure EmitAgentMoved(const State: TAgentState; const FromCell, ToCell: Integer; const MoveCost: Single);
    procedure EmitDeltaConsumed(const State: TAgentState; const Cache: TCacheRef; const ConsumedAmount, GainAmount: Single);
    procedure EmitResourceSampled;
    procedure CaptureDecisionTrace(AgentIndex: Integer; const State: TAgentState; const Input: TBrainTickInput;
      const Requested, Resolved: TBrainTickOutput;
      const ForageConsumed, ForageGain: Single);
    function CalculateAgentTickCost(const State: TAgentState): Single;
    function CalculateMoveCost(FromCell, ToCell: Integer): Single;
    function CalculateForageGain(const State: TAgentState; const Reply: TConsumeCacheReply): Single;
    function BuildOffspringState(const ParentState: TAgentState; const OffspringId: Integer): TAgentState;
    function NextAgentId: Integer;
    function ApplyAgentUpkeep(var State: TAgentState): Boolean;
    function ResolveRequestedStep(AgentIndex: Integer; var State: TAgentState; const Requested: TBrainTickOutput;
      out ForageConsumed, ForageGain: Single): TBrainTickOutput;
    procedure ProcessAgentTick(aIndex: Integer; const Input: TBrainTickInput);
    procedure NotifyPhase(const Phase: TSimTickPhase);
    procedure SetDayTick(const Value: TDayTick);
    { conversions for event emission }
    function CellToPoint(aCell: Integer): TPoint;
    function TargetToRef(const aTarget: TTarget): TTargetRef;
  public
    constructor Create(const aDiagnostics: ISimDiagnosticsSink = nil);
    destructor Destroy; override;

    procedure ConfigureRuntime(const aConfig: TRuntimeConfig);
    procedure RebuildDeltaPlacementCycles;

    procedure AdvanceClock(const GlobalTick: Integer; const DayTick: TDayTick);
    function TryGetLastDecision(AgentIndex: Integer; out Trace: TDecisionTrace): Boolean;

    property Environment: TSimEnvironment read fEnvironment;
    property Population: TSimPopulation read fPopulation;
    property LastDeltaSpawnCount: Integer read fLastDeltaSpawnCount;

    property OnPhase: TRuntimePhaseEvent read fOnPhase write fOnPhase;
    property TrackedResourceCacheIndex: Integer read fTrackedResourceCacheIndex write fTrackedResourceCacheIndex;
  end;

implementation

uses System.Math, System.SysUtils, u_SimQueriesImpl,
  u_SimCommandsImpl;

{ TSimRuntime }

constructor TSimRuntime.Create(const aDiagnostics: ISimDiagnosticsSink);
begin
  inherited Create;
  fRuntimeConfig := Default(TRuntimeConfig);
  fDiagnostics := aDiagnostics;
  fTrackedResourceCacheIndex := -1;
  fDeltaPlacementCycleIndex := 0;
  fLastDeltaSpawnCount := 0;
  fDeltaCleanupGraceTicksRemaining := 0;
  fEnvironment := TSimEnvironment.Create;
  fPopulation := TSimPopulation.Create;
  fSimQuery := TSimQuery.Create(fEnvironment, fPopulation);
  fSimCommand := TSimCommand.Create(fEnvironment, fPopulation);
end;

procedure TSimRuntime.ConfigureRuntime(const aConfig: TRuntimeConfig);
begin
  fRuntimeConfig := aConfig;
end;

procedure TSimRuntime.RebuildDeltaPlacementCycles;
  function HasMinSpacing(const CandidateCell: Integer; const Selected: TCellIndexArray;
    const SelectedCount, GridWidth: Integer): Boolean;
  begin
    var candidateX := CandidateCell mod GridWidth;
    var candidateY := CandidateCell div GridWidth;

    for var i := 0 to SelectedCount - 1 do
    begin
      var selectedCell := Selected[i];
      var selectedX := selectedCell mod GridWidth;
      var selectedY := selectedCell div GridWidth;

      var chebyshevDistance := Abs(selectedX - candidateX);
      if Abs(selectedY - candidateY) > chebyshevDistance then
        chebyshevDistance := Abs(selectedY - candidateY);

      if chebyshevDistance < DELTA_MIN_SPACING_CELLS then
        Exit(False);
    end;

    Result := True;
  end;
  procedure ShuffleCells(var Cells: TCellIndexArray);
  begin
    for var i := High(Cells) downto 1 do
    begin
      var j := Random(i + 1);
      var temp := Cells[i];
      Cells[i] := Cells[j];
      Cells[j] := temp;
    end;
  end;
  function BuildCycle(const GridWidth: Integer): TCellIndexArray;
  begin
    Result := nil;

    var candidates: TCellIndexArray;
    var candidateCount := 0;
    for var cellIndex := 0 to High(fEnvironment.Cells) do
    begin
      var deltaChance := Integer(fEnvironment.Cells[cellIndex].DeltaChance);
      if deltaChance <= 0 then
        Continue;

      if deltaChance > 100 then
        deltaChance := 100;

      if Random(100) >= deltaChance then
        Continue;

      if candidateCount >= Length(candidates) then
        SetLength(candidates, candidateCount + 128);

      candidates[candidateCount] := cellIndex;
      Inc(candidateCount);
    end;

    if candidateCount = 0 then
      Exit;

    SetLength(candidates, candidateCount);
    ShuffleCells(candidates);

    var selectedCount := 0;
    for var i := 0 to High(candidates) do
    begin
      var candidateCell := candidates[i];
      if not HasMinSpacing(candidateCell, Result, selectedCount, GridWidth) then
        Continue;

      if selectedCount >= Length(Result) then
        SetLength(Result, selectedCount + 16);

      Result[selectedCount] := candidateCell;
      Inc(selectedCount);

      if selectedCount >= DELTA_MAX_CACHES_PER_NIGHT then
        Break;
    end;

    SetLength(Result, selectedCount);
  end;
begin
  SetLength(fDeltaPlacementCycles, 0);
  fDeltaPlacementCycleIndex := 0;
  fLastDeltaSpawnCount := 0;

  var width := fEnvironment.Dimensions.cx;
  var height := fEnvironment.Dimensions.cy;
  if (width <= 0) or (height <= 0) then
    Exit;

  SetLength(fDeltaPlacementCycles, DELTA_PLACEMENT_CYCLE_COUNT);
  for var cycleIndex := 0 to DELTA_PLACEMENT_CYCLE_COUNT - 1 do
    fDeltaPlacementCycles[cycleIndex] := BuildCycle(width);
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

function TSimRuntime.CellToPoint(aCell: Integer): TPoint;
begin
  Result := Point(aCell mod fEnvironment.Dimensions.cx, aCell div fEnvironment.Dimensions.cx);
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
  function GestationFatigueCost: Single;
  begin
    Result := 0.0;

    if (State.Action <> acShelter) or (State.ActionProgress <= 0) then
      Exit;

    Result := REPRODUCTION_FATIGUE_BASE
      + ((State.ActionProgress - 1) * REPRODUCTION_FATIGUE_STEP);
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
    Result := Result + GestationFatigueCost;
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
    + GeneGenerationCost(State.Genome.GeneMap.Converter)
    + GestationFatigueCost;
end;

function TSimRuntime.ApplyAgentUpkeep(var State: TAgentState): Boolean;
begin
  State.Reserves := State.Reserves - CalculateAgentTickCost(State);
  Result := State.Reserves > 0.0;
  if not Result then
    State.Reserves := 0.0;
end;

function TSimRuntime.BuildDeltaSpawnPlan: TArray<Integer>;
begin
  Result := nil;

  var cycleCount := Length(fDeltaPlacementCycles);
  if cycleCount = 0 then
    Exit;

  if fDeltaPlacementCycleIndex < 0 then
    fDeltaPlacementCycleIndex := 0;

  var cycleIndex := fDeltaPlacementCycleIndex mod cycleCount;
  Result := Copy(fDeltaPlacementCycles[cycleIndex]);

  Inc(fDeltaPlacementCycleIndex);
  if fDeltaPlacementCycleIndex >= cycleCount then
    fDeltaPlacementCycleIndex := 0;
end;

procedure TSimRuntime.InjectDeltaAtNightfall;
begin
  if fCurrentDayTick <> DELTA_CREATE_TICK then
    Exit;

  var spawnPlan := BuildDeltaSpawnPlan;
  fLastDeltaSpawnCount := Length(spawnPlan);
  if fLastDeltaSpawnCount = 0 then
    Exit;

  fEnvironment.ApplyDeltaSpawnPlan(spawnPlan, DEFAULT_DELTA_CACHE_AMOUNT);
end;

procedure TSimRuntime.HandleDeltaCleanupPolicy(const Report: TDeltaUpkeepReport);
begin
  if DELTA_EXTINCTION_EPSILON <= 0.0 then
    Exit;

  if DELTA_CLEANUP_GRACE_TICKS <= 0 then
  begin
    if (Report.ActiveCount = 0) and (Report.ExtinctCount > 0) then
      fEnvironment.CleanupExtinctDeltaCaches;
    Exit;
  end;

  if (Report.ActiveCount = 0) and (Report.ExtinctCount > 0) then
    fDeltaCleanupGraceTicksRemaining := DELTA_CLEANUP_GRACE_TICKS;

  if fDeltaCleanupGraceTicksRemaining > 0 then
  begin
    Dec(fDeltaCleanupGraceTicksRemaining);
    if fDeltaCleanupGraceTicksRemaining = 0 then
      fEnvironment.CleanupExtinctDeltaCaches;
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

procedure TSimRuntime.EmitActionResolved(const StateBeforeResolution, State: TAgentState;
  const Requested, Resolved: TBrainTickOutput);
begin
  if not Assigned(fDiagnostics) then
    Exit;

  var event := Default(TSimEvent);
  event.Header := BuildEventHeader(sekActionResolved, stpPostAgents);
  event.ActionResolved.AgentId := State.AgentId;
  event.ActionResolved.RequestedAction := Requested.RequestedAction;
  event.ActionResolved.RequestedTarget := TargetToRef(Requested.RequestedTarget);
  event.ActionResolved.ResolvedAction := Resolved.RequestedAction;
  event.ActionResolved.ResolvedTarget := TargetToRef(Resolved.RequestedTarget);
  event.ActionResolved.Reserves := State.Reserves;
  event.ActionResolved.ActionProgress := State.ActionProgress;

  if (Requested.RequestedAction = acReproduce)
    and (Resolved.RequestedAction = acIdle)
    and (StateBeforeResolution.Action <> acShelter)
    and (StateBeforeResolution.Reserves < REPRODUCTION_MIN_ATTEMPT_RESERVES) then
    event.ActionResolved.Note := arnReproduceBlockedLowReserves
  else if (Requested.RequestedAction = acReproduce)
    and (Resolved.RequestedAction = acShelter)
    and (StateBeforeResolution.Action <> acShelter)
    and (State.ActionProgress > 0) then
    event.ActionResolved.Note := arnGestationStarted
  else if (StateBeforeResolution.Action = acShelter)
    and (StateBeforeResolution.ActionProgress > 0)
    and (Resolved.RequestedAction = acShelter)
    and (State.ActionProgress > 0) then
    event.ActionResolved.Note := arnGestationContinuing
  else if (StateBeforeResolution.Action = acShelter)
    and (StateBeforeResolution.ActionProgress > 0)
    and (Resolved.RequestedAction = acIdle)
    and (State.ActionProgress = 0) then
    event.ActionResolved.Note := arnGestationCompleted;

  fDiagnostics.Emit(event);
end;

procedure TSimRuntime.EmitDecisionTrace(const State: TAgentState; const Trace: TDecisionTrace);
begin
  if not Assigned(fDiagnostics) then
    Exit;

  var event := Default(TSimEvent);
  event.Header := BuildEventHeader(sekDecisionTrace, stpPostAgents);
  event.DecisionTrace.AgentId := Trace.AgentId;
  event.DecisionTrace.Cell := CellToPoint(State.Location);
  event.DecisionTrace.RequestedAction := Trace.RequestedAction;
  event.DecisionTrace.RequestedTarget := TargetToRef(Trace.RequestedTarget);
  event.DecisionTrace.ResolvedAction := Trace.ResolvedAction;
  event.DecisionTrace.ResolvedTarget := TargetToRef(Trace.ResolvedTarget);
  event.DecisionTrace.ForageConsumed := Trace.ForageConsumed;
  event.DecisionTrace.ForageGain := Trace.ForageGain;
  event.DecisionTrace.ForageEfficiency := Trace.ForageEfficiency;
  event.DecisionTrace.Evaluations := Trace.Evaluations;
  event.DecisionTrace.Summary := Trace.Summary;
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
  event.AgentBorn.Cell := CellToPoint(OffspringState.Location);
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
  event.AgentDied.Cell := CellToPoint(State.Location);
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
  event.AgentMoved.FromCell := CellToPoint(FromCell);
  event.AgentMoved.ToCell := CellToPoint(ToCell);
  event.AgentMoved.MoveCost := movecost;
  event.AgentMoved.Reserves := State.Reserves;
  fDiagnostics.Emit(event);
end;

procedure TSimRuntime.EmitDeltaConsumed(const State: TAgentState; const Cache: TCacheRef;
  const ConsumedAmount, GainAmount: Single);
begin
  if not Assigned(fDiagnostics) then
    Exit;

  var event := Default(TSimEvent);
  event.Header := BuildEventHeader(sekDeltaConsumed, stpPostAgents);
  event.DeltaConsumed.AgentId := State.AgentId;
  event.DeltaConsumed.Cell := CellToPoint(State.Location);
  event.DeltaConsumed.Cache := Cache;
  event.DeltaConsumed.ConsumedAmount := ConsumedAmount;
  event.DeltaConsumed.GainAmount := GainAmount;
  fDiagnostics.Emit(event);
end;

procedure TSimRuntime.EmitResourceSampled;
begin
  if not Assigned(fDiagnostics) then
    Exit;
  if fTrackedResourceCacheIndex < 0 then
    Exit;
  if fTrackedResourceCacheIndex >= Length(fEnvironment.Resources) then
    Exit;

  var event := Default(TSimEvent);
  event.Header := BuildEventHeader(sekResourceSampled, stpPostEnvironment);
  event.ResourceSampled.CacheIndex := fTrackedResourceCacheIndex;
  event.ResourceSampled.Amount := fEnvironment.Resources[fTrackedResourceCacheIndex].Amount;
  event.ResourceSampled.RegenDebt := fEnvironment.Resources[fTrackedResourceCacheIndex].RegenDebt;
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
  Result.WanderTarget := -1;
  Result.Genome := ParentState.Genome;
  FillChar(Result.DecisionWeights, SizeOf(Result.DecisionWeights), 0);
end;

function TSimRuntime.NextAgentId: Integer;
begin
  Result := 1;

  for var agentIndex := 0 to fPopulation.AgentCount - 1 do
  begin
    var state := fPopulation.GetAgentState(agentIndex);
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

  if (State.Action = acShelter) and (State.ActionProgress > 0) then
  begin
    Result.RequestedTarget.TType := ttCell;
    Result.RequestedTarget.Cell := State.Location;

    if State.ActionProgress >= REPRODUCTION_DURATION_TICKS then
      State.ActionProgress := REPRODUCTION_DURATION_TICKS - 1;

    if State.ActionProgress >= (REPRODUCTION_DURATION_TICKS - 1) then
    begin
      var offspringState := BuildOffspringState(State, NextAgentId);
      State.Reserves := State.Reserves - REPRODUCTION_PARENT_COST;
      if State.Reserves < 0.0 then
        State.Reserves := 0.0;
      State.TicksSinceReproduction := 0;
      State.ActionProgress := 0;
      fPopulation.AppendAgent(offspringState);
      EmitAgentBorn(offspringState, State.AgentId);

      Result.RequestedAction := acIdle;
      Exit;
    end;

    Inc(State.ActionProgress);
    Result.RequestedAction := acShelter;
    Exit;
  end;

  if State.ActionProgress <> 0 then
    State.ActionProgress := 0;

  if Requested.RequestedAction = acReproduce then
  begin
    Result.RequestedTarget.TType := ttCell;
    Result.RequestedTarget.Cell := State.Location;

    if State.Action <> acShelter then
    begin
      if State.Reserves < REPRODUCTION_MIN_ATTEMPT_RESERVES then
      begin
        Result.RequestedAction := acIdle;
        Exit;
      end;

      State.ActionProgress := 1;
      Result.RequestedAction := acShelter;
      Exit;
    end;
  end;

  if Requested.RequestedAction = acShelter then
  begin
    Result.RequestedTarget.TType := ttCell;
    Result.RequestedTarget.Cell := State.Location;

    if State.Action <> acShelter then
    begin
      State.Reserves := State.Reserves - SHELTER_ENTRY_COST;
      if State.Reserves < 0.0 then
        State.Reserves := 0.0;
    end;

    Result.RequestedAction := acShelter;
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
      var isWanderMove := Requested.Evaluations[acMove].Target.TType = ttWander;
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

        var oldCell := State.Location;
        State.Location := moveReply.NewCell;
        fPopulation.NotifyLocationChanged(AgentIndex, oldCell, State.Location);

        if isWanderMove then
          State.WanderTarget := Requested.RequestedTarget.Cell;

        if (State.WanderTarget >= 0) and (State.Location = State.WanderTarget) then
          State.WanderTarget := -1;

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
        ckDelta:
          begin
            if (cacheRef.Index >= 0) and (cacheRef.Index <= High(fEnvironment.DeltaCaches)) then
              isLocalCache := fEnvironment.DeltaCaches[cacheRef.Index].CellIndex = State.Location;
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
        State.TicksSinceForage := 0;

        if cacheRef.Kind = ckDelta then
          EmitDeltaConsumed(State, cacheRef, ForageConsumed, ForageGain);
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

  var state := fPopulation.GetAgentState(aIndex);

  // Dead agents remain in population data but do not age or think.
  if state.Reserves <= 0.0 then
    Exit;

  // Age tracks ticks survived; this includes the tick where upkeep may cause death.
  Inc(state.Age);
  Inc(state.TicksSinceReproduction);
  Inc(state.TicksSinceForage);

  var reservesAtTickStart := state.Reserves;
  var reservesBeforeUpkeep := state.Reserves;

  if not ApplyAgentUpkeep(state^) then
  begin
    // Dead agents do not think or request actions.
    state.ReserveDelta := state.Reserves - reservesAtTickStart;
    state.Action := acIdle;
    EmitAgentDied(state^, reservesBeforeUpkeep);

    // Notify environment once at transition-to-death.
    fEnvironment.NotifyAgentDeath(state.Location, DEFAULT_DEATH_BIOMASS_AMOUNT);
    Exit;
  end;

  var requested := fPopulation.Think(aIndex, Input);
  var forageConsumed: Single := 0.0;
  var forageGain: Single := 0.0;
  var stateBeforeResolution := state^;
  var resolved := ResolveRequestedStep(aIndex, state^, requested, forageConsumed, forageGain);
  state.ReserveDelta := state.Reserves - reservesAtTickStart;

  var reflectInput: TBrainReflectInput;
  reflectInput.ResolvedAction := resolved.RequestedAction;
  reflectInput.ResolvedTarget := resolved.RequestedTarget;
  reflectInput.ForageConsumed := forageConsumed;
  reflectInput.ForageGain := forageGain;
  reflectInput.GridWidth := fEnvironment.Dimensions.cx;
  reflectInput.PreviousLocation := stateBeforeResolution.Location;
  reflectInput.CurrentLocation := state.Location;
  fPopulation.Reflect(aIndex, requested, reflectInput);

  CaptureDecisionTrace(aIndex, state^, Input, requested, resolved, forageConsumed, forageGain);
  EmitActionResolved(stateBeforeResolution, state^, requested, resolved);
  if (aIndex >= 0) and (aIndex < Length(fLastDecisionTraces)) and fHasDecisionTrace[aIndex] then
    EmitDecisionTrace(state^, fLastDecisionTraces[aIndex]);
  fPopulation.ApplyStep(aIndex, resolved);
end;

procedure TSimRuntime.AdvanceClock(const GlobalTick: Integer; const DayTick: TDayTick);
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

  InjectDeltaAtNightfall;
  HandleDeltaCleanupPolicy(fEnvironment.LastDeltaUpkeepReport);

  var currentSolarFlux := fEnvironment.SolarFlux;

  var isNightTick := Value > High(TDaylightTicks);

  EmitResourceSampled;
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
  if (agentCount > 0) and (fCurrentGlobalTick >= fRuntimeConfig.AgentActivationTick) then
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

function TSimRuntime.TargetToRef(const aTarget: TTarget): TTargetRef;
begin
  Result.TType := aTarget.TType;
  case Result.TType of
    ttNone: ;
    ttCell: Result.Cell := CellToPoint(aTarget.Cell);
    ttCache: Result.Cache := aTarget.Cache;
  end;
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
