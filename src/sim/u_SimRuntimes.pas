unit u_SimRuntimes;

interface

uses System.Types,
  u_AgentState, u_SessionEventTypes, u_SimEnvironments, u_SimPopulations, u_SimClocks, u_SimQueriesIntf,
  u_SimCommandsIntf, u_AgentBrain, u_SimTypes, u_GeneTypes, u_BrainTypes,
  u_EnvironmentTypes, u_RuntimeTypes, u_PopulationTypes;

const
  AGENT_BITE_SIZE = 0.1;  // temporary. move to sim params/genome
  AGENT_BASE_MOVE_COST = 0.05; // temporary. move to sim params/genome
  SHELTER_UPKEEP_MULTIPLIER = 0.35;
  AGENT_BASE_METABOLISM = 0.01;  // physics floor: applies to all agents regardless of genome
  GENE_GENERATION_COST = 0.005;  // upkeep added per generation above A for each gene slot

  STASIS_ENERGY = 5.0;  // reserves granted on full sleep recovery; energy rebalance will revisit
  DIG_TICKS = 3;        // ticks spent digging before action progresses
  DIG_BASE_COST = 0.03; // per-tick energy cost of digging, scaled by cell mobility
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
  TCellAmountArray = TArray<Single>;
  TCellAmountCycles = array of TCellAmountArray;

  TRuntimeConfig = record
    AgentActivationTick: Integer;
  end;

  TGeneMapHelper = record helper for TGeneMap
    function SumGenerationCost(const aCostPerGeneration: Single;
      const aRequiredFlags: TGeneSlotFlags = [];
      const aExcludedFlags: TGeneSlotFlags = []): Single;
  end;

  TSimRuntime = class
  private const
    DEFAULT_DEATH_BIOMASS_AMOUNT = 1.0;   // currently unused
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
    fPopulation: TSimPopulation;
//    fDiagnostics: ISimDiagnosticsSink;
    fSessionEvents: ISessionEventSink;
    fSimQuery: ISimQuery;
    fSimCommand: ISimCommand;
    fOnPhase: TRuntimePhaseEvent;
    fDeltaPlacementCycles: TCellIndexCycles;
    fDeltaPlacementAmounts: TCellAmountCycles;
    fDeltaPlacementCycleIndex: Integer;
    fSeedIndex: Integer;  // strided seeder offset, incremented each seeding pass
    fLastDeltaSpawnCount: Integer;
    fDeltaCleanupGraceTicksRemaining: Integer;

    fPopulationSummary: TPopulationSummary;
    fTickTotalReserves: Single;
    fTotalDeaths: Integer;
    fTotalMutations: Integer;

    function BuildEventHeader(): TSessionEventHeader;
    procedure EmitPrePopulation;
    procedure EmitPostPopulation;
    procedure EmitActionResolved(const StateBeforeResolution, State: TAgentState; const Requested, Resolved: TBrainTickOutput);
    procedure EmitAgentBorn(const OffspringState, ParentState: TAgentState);
    procedure EmitAgentDied(const State: TAgentState; LastAction: TAgentAction);
//    procedure EmitAgentMoved(const State: TAgentState; const FromCell, ToCell: Integer; const MoveCost: Single);
//    procedure EmitDeltaConsumed(const State: TAgentState; const Cache: TCacheRef; const ConsumedAmount, GainAmount: Single);

    function BuildDeltaSpawnPlan: TArray<Integer>;
    procedure InjectDeltaAtNightfall;
    procedure HandleDeltaCleanupPolicy(const Report: TDeltaUpkeepReport);

    procedure BeginTickSummary;
    procedure FinalizeTickSummary;

    function CalculateAgentTickCost(const State: TAgentState; const GeneMap: TGeneMap): Single;
    function CalculateMoveCost(FromCell, ToCell: Integer): Single;
    function CalculateForageGain(const State: TAgentState; const GeneMap: TGeneMap; const Reply: TConsumeCacheReply): Single;
    function BuildOffspringState(const ParentState: TAgentState; const OffspringId: Integer): TAgentState;
    function NextAgentId: Integer;
    function ApplyAgentUpkeep(var State: TAgentState; const GeneMap: TGeneMap): Boolean;
    function ResolveRequestedStep(AgentIndex: Integer; var State: TAgentState; const GeneMap: TGeneMap;
      const Requested: TBrainTickOutput; out ForageOutcome: TForageOutcome): TBrainTickOutput;
    procedure ProcessAgentTick(aIndex: Integer; const Input: TBrainTickInput);
    procedure NotifyPhase(const Phase: TSimTickPhase);
    procedure SetDayTick(const Value: TDayTick);
  public
    constructor Create(const aSessionEventSink: ISessionEventSink);
    destructor Destroy; override;

    procedure ConfigureRuntime(const aConfig: TRuntimeConfig);
    procedure RebuildDeltaPlacementCycles;
    procedure SetDeltaPlacementCycles(const aCycles: TCellIndexCycles);
    procedure SetDeltaPlacementCyclesWithAmounts(const aCycles: TCellIndexCycles;
      const aAmounts: TCellAmountCycles);

    procedure AdvanceClock(const GlobalTick: Integer; const DayTick: TDayTick);

    property Environment: TSimEnvironment read fEnvironment;
    property Population: TSimPopulation read fPopulation;
    property LastDeltaSpawnCount: Integer read fLastDeltaSpawnCount;

    property PopulationSummary: TPopulationSummary read fPopulationSummary;
    property OnPhase: TRuntimePhaseEvent read fOnPhase write fOnPhase;
  end;

implementation

uses System.Math, System.SysUtils,
  u_SimQueriesImpl, u_SimCommandsImpl, u_AgentGenome;

{ TGeneMapHelper }

function TGeneMapHelper.SumGenerationCost(const aCostPerGeneration: Single;
  const aRequiredFlags: TGeneSlotFlags; const aExcludedFlags: TGeneSlotFlags): Single;

  function GeneGenerationCost(aGeneClass: TGeneClass): Single;
  begin
    if not Assigned(aGeneClass) then
      Exit(0.0);

    Result := (Ord(aGeneClass.GetGenerationCode) - Ord('A')) * aCostPerGeneration;
    if Result < 0.0 then
      Result := 0.0;
  end;

  procedure AddSlot(aGeneClass: TGeneClass; const aFlags: TGeneSlotFlags);
  begin
    if (aRequiredFlags - aFlags) <> [] then
      Exit;

    if (aFlags * aExcludedFlags) <> [] then
      Exit;

    Result := Result + GeneGenerationCost(aGeneClass);
  end;

begin
  Result := 0.0;

  AddSlot(Energy, [gsfAlwaysOn]);
  AddSlot(Smell, []);
  AddSlot(MoveEval, []);
  AddSlot(ForageEval, []);
  AddSlot(ShelterEval, [gsfAlwaysOn]);
  AddSlot(ReproduceEval, []);
  AddSlot(Cognition, [gsfAlwaysOn]);
  AddSlot(Converter, []);
end;

{ TSimRuntime }

constructor TSimRuntime.Create(const aSessionEventSink: ISessionEventSink);
begin
  inherited Create;
  fRuntimeConfig := Default(TRuntimeConfig);
  fSessionEvents := aSessionEventSink;
//  fDiagnostics := aDiagnostics;
  fDeltaPlacementCycleIndex := 0;
  fLastDeltaSpawnCount := 0;
  fDeltaCleanupGraceTicksRemaining := 0;
  fEnvironment := TSimEnvironment.Create;
  fPopulation := TSimPopulation.Create;
  fSimQuery := TSimQuery.Create(fEnvironment, fPopulation);
  fSimCommand := TSimCommand.Create(fEnvironment, fPopulation);
  fPopulationSummary := Default(TPopulationSummary);
  fTotalDeaths := 0;
  fTotalMutations := 0;
end;

destructor TSimRuntime.Destroy;
begin
  fSimQuery := nil;
  fSimCommand := nil;
  fEnvironment.Free;
  fPopulation.Free;
  inherited;
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
  SetLength(fDeltaPlacementAmounts, 0);
  fLastDeltaSpawnCount := 0;

  var width := fEnvironment.Dimensions.cx;
  var height := fEnvironment.Dimensions.cy;
  if (width <= 0) or (height <= 0) then
    Exit;

  SetLength(fDeltaPlacementCycles, DELTA_PLACEMENT_CYCLE_COUNT);
  for var cycleIndex := 0 to DELTA_PLACEMENT_CYCLE_COUNT - 1 do
    fDeltaPlacementCycles[cycleIndex] := BuildCycle(width);
end;

procedure TSimRuntime.SetDeltaPlacementCycles(const aCycles: TCellIndexCycles);
begin
  fDeltaPlacementCycles := Copy(aCycles);
  SetLength(fDeltaPlacementAmounts, 0);  // no per-entry amounts; injection uses DEFAULT_DELTA_CACHE_AMOUNT
  fDeltaPlacementCycleIndex := 0;
  fLastDeltaSpawnCount := 0;
end;

procedure TSimRuntime.SetDeltaPlacementCyclesWithAmounts(const aCycles: TCellIndexCycles;
  const aAmounts: TCellAmountCycles);
begin
  fDeltaPlacementCycles := Copy(aCycles);
  fDeltaPlacementAmounts := Copy(aAmounts);
  fDeltaPlacementCycleIndex := 0;
  fLastDeltaSpawnCount := 0;
end;

function TSimRuntime.CalculateAgentTickCost(const State: TAgentState; const GeneMap: TGeneMap): Single;

  function GestationFatigueCost(aProgress: Integer): Single;
  begin
    Result := REPRODUCTION_FATIGUE_BASE + ((aProgress - 1) * REPRODUCTION_FATIGUE_STEP);
  end;

  function DigCost(aLocation: TCellIndex): Single;
  begin
    var terrainPenalty := EnsureRange(fEnvironment.Cells[aLocation].Mobility, 0.0, 1.0);
    Result := DIG_BASE_COST * (1.0 + terrainPenalty);
  end;

begin
  Result := AGENT_BASE_METABOLISM;
  var flags: TGeneSlotFlags := [];

  // Shelter: two phases — digging (elevated cost) and underground (reduced metabolism)
  if State.Action = acShelter then
  begin
    if State.ActionAge < DIG_TICKS then
      Result := Result + DigCost(State.Location)
    else
    begin
      Result := Result * SHELTER_UPKEEP_MULTIPLIER;
      flags := [gsfAlwaysOn];
    end;
  end;

  // Reproduce: same two-phase structure
  if State.Action = acReproduce then
  begin
    if State.ActionAge < DIG_TICKS then
      Result := Result + DigCost(State.Location)
    else
    begin
      Result := Result + GestationFatigueCost(State.ActionProgress);
      flags := [gsfAlwaysOn];
    end;
  end;

  // and the cost everyone pays for their gene usage
  Result := Result + GeneMap.SumGenerationCost(GENE_GENERATION_COST, flags);
end;

function TSimRuntime.ApplyAgentUpkeep(var State: TAgentState; const GeneMap: TGeneMap): Boolean;
begin
  State.Reserves := State.Reserves - CalculateAgentTickCost(State, GeneMap);
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

  // Use per-entry amounts if available (debug path), otherwise uniform default.
  // Note: BuildDeltaSpawnPlan already advanced the index, so look at the previous one.
  var prevCycleIndex := (fDeltaPlacementCycleIndex - 1 + Max(1, Length(fDeltaPlacementCycles)))
    mod Max(1, Length(fDeltaPlacementCycles));

  if (Length(fDeltaPlacementAmounts) > prevCycleIndex)
    and (Length(fDeltaPlacementAmounts[prevCycleIndex]) > 0) then
    fEnvironment.ApplyDeltaSpawnPlan(spawnPlan, fDeltaPlacementAmounts[prevCycleIndex])
  else
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

function TSimRuntime.BuildEventHeader(): TSessionEventHeader;
begin
  Result := Default(TSessionEventHeader);
  Result.GlobalTick := fCurrentGlobalTick;
  Result.Date.DayNumber := fCurrentGlobalTick div CLOCK_TICKS_PER_DAY;
  Result.Date.DayTick := fCurrentDayTick;
end;

procedure TSimRuntime.EmitPrePopulation;
begin
  var event := Default(TSessionEvent);
  event.Header := BuildEventHeader();
  event.EventKind := sekPrePopulation;
  event.Prepop.PopulationSize := fPopulation.AgentCount;
  event.Prepop.DeathsToDate := fTotalDeaths;
  event.Prepop.MutationsToDate := fTotalMutations;
  event.Prepop.LongestLife := Word(fPopulationSummary.LongestLife.Age);
  event.Prepop.MostBirths := 0; // TODO: track when birth counting is added
  fSessionEvents.Emit(event);
end;

procedure TSimRuntime.EmitPostPopulation;
begin
  var event := Default(TSessionEvent);
  event.Header := BuildEventHeader();
  event.EventKind := sekPostPopulation;
  event.PostPop.Births := fPopulationSummary.NewBirths;
  event.PostPop.Mutations := 0; // TODO: mutation tracking
  event.PostPop.Deaths := fPopulationSummary.NewDeaths;
  fSessionEvents.Emit(event);
end;

procedure TSimRuntime.EmitActionResolved(const StateBeforeResolution, State: TAgentState;
  const Requested, Resolved: TBrainTickOutput);
begin
  // don't think we need this ...?

//  var event := Default(TSessionEvent);
//  event.Header := BuildEventHeader();
//
//  event.ActionResolved.AgentId := State.AgentId;
//  event.ActionResolved.RequestedAction := Requested.RequestedAction;
//  event.ActionResolved.RequestedTarget := Requested.RequestedTarget;
//  event.ActionResolved.ResolvedAction := Resolved.RequestedAction;
//  event.ActionResolved.ResolvedTarget := Resolved.RequestedTarget;
//  event.ActionResolved.Reserves := State.Reserves;
//  event.ActionResolved.ActionProgress := State.ActionProgress;
//
//  fDiagnostics.Emit(event);
end;

procedure TSimRuntime.EmitAgentBorn(const OffspringState, ParentState: TAgentState);
begin
  var event := Default(TSessionEvent);
  event.Header := BuildEventHeader();
  event.EventKind := sekBirth;
  event.Birth.AgentId := OffspringState.AgentId;
  event.Birth.ParentId := ParentState.AgentId;
  event.Birth.Sequence := OffspringState.Genome.Sequence;
  event.Birth.ParentSequence := ParentState.Genome.Sequence;
  event.Birth.Location := OffspringState.Location;

// consider adding:
//  event.Birth.OffspringNumber := ParentState.ChildCount;

  fSessionEvents.Emit(event);
end;

procedure TSimRuntime.EmitAgentDied(const State: TAgentState; LastAction: TAgentAction);
begin
  var event := Default(TSessionEvent);
  event.Header := BuildEventHeader();
  event.EventKind := sekDeath;
  event.Death.AgentId := State.AgentId;
  event.Death.Age := State.Age;
  event.Death.Location := State.Location;
  event.Death.LastAction := LastAction;
  fSessionEvents.Emit(event);
end;

//procedure TSimRuntime.EmitAgentMoved(const State: TAgentState; const FromCell, ToCell: Integer;
//  const MoveCost: Single);
//begin
//  if not Assigned(fDiagnostics) then
//    Exit;
//
//  var event := Default(TSimEvent);
//  event.Header := BuildEventHeader(sekAgentMoved, stpPostAgents);
//  event.AgentMoved.AgentId := State.AgentId;
//  event.AgentMoved.FromCell := FromCell;
//  event.AgentMoved.ToCell := ToCell;
//  event.AgentMoved.MoveCost := movecost;
//  event.AgentMoved.Reserves := State.Reserves;
//  fDiagnostics.Emit(event);
//end;

//procedure TSimRuntime.EmitDeltaConsumed(const State: TAgentState; const Cache: TCacheRef;
//  const ConsumedAmount, GainAmount: Single);
//begin
//  if not Assigned(fDiagnostics) then
//    Exit;
//
//  var event := Default(TSimEvent);
//  event.Header := BuildEventHeader(sekDeltaConsumed, stpPostAgents);
//  event.DeltaConsumed.AgentId := State.AgentId;
//  event.DeltaConsumed.Cell := State.Location;
//  event.DeltaConsumed.Cache := Cache;
//  event.DeltaConsumed.ConsumedAmount := ConsumedAmount;
//  event.DeltaConsumed.GainAmount := GainAmount;
//  fDiagnostics.Emit(event);
//end;

procedure TSimRuntime.BeginTickSummary;
begin
  // Reset per-tick counters and snapshot accumulators.
  // MaxLiving is a high-water mark — never reset.
  fPopulationSummary.NewBirths := 0;
  fPopulationSummary.NewDeaths := 0;
  fPopulationSummary.Living := 0;
  fPopulationSummary.Sheltering := 0;
  fPopulationSummary.LongestLife := Default(TLifespan);
  fPopulationSummary.MaxReserves := Default(TReserveState);
  fPopulationSummary.MaxDistance := Default(TDistanceRecord);
  fTickTotalReserves := 0.0;
end;

procedure TSimRuntime.FinalizeTickSummary;
begin
  if fPopulationSummary.Living > 0 then
    fPopulationSummary.MeanReserves := fTickTotalReserves / fPopulationSummary.Living
  else
    fPopulationSummary.MeanReserves := 0.0;

  if fPopulationSummary.Living > fPopulationSummary.MaxLiving then
    fPopulationSummary.MaxLiving := fPopulationSummary.Living;
end;

function TSimRuntime.CalculateForageGain(const State: TAgentState; const GeneMap: TGeneMap; const Reply: TConsumeCacheReply): Single;
begin
  var converter := GeneMap.Converter;
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
  Result.InitAgent;
  Result.AgentId := OffspringId;
  Result.ParentId := ParentState.AgentId;
  Result.Generation := ParentState.Generation + 1;
  Result.Birthplace := ParentState.Location;
  Result.Location := ParentState.Location;
  Result.Age := 0;
  Result.Reserves := REPRODUCTION_CHILD_START_RESERVES;
  Result.TicksSinceReproduction := 0;
  Result.Action := acIdle;
  Result.ActionAge := 0;
  Result.ActionProgress := 0;
  Result.ActionTarget.TType := ttCell;
  Result.ActionTarget.Cell := ParentState.Location;
  Result.Genome := ParentState.Genome;

  // !! inheritance?
  FillChar(Result.DecisionWeights, SizeOf(Result.DecisionWeights), 0);

  // Offspring inherit parent's learned molecule preferences — same genome means
  // same conversion chemistry, so parent's experience is the best prior.
  Result.Genome.ForageMoleculeWeights := ParentState.Genome.ForageMoleculeWeights;
end;

function TSimRuntime.NextAgentId: Integer;
begin
  Result := 0;

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
  const GeneMap: TGeneMap; const Requested: TBrainTickOutput; out ForageOutcome: TForageOutcome): TBrainTickOutput;
begin
  // Runtime resolution hook: adjust or reject requested actions based on world rules.
  Result := Requested;
  ForageOutcome := Default(TForageOutcome);

  if (State.Action = acReproduce) and (State.ActionProgress > 0) then
  begin
    Result.RequestedTarget.TType := ttCell;
    Result.RequestedTarget.Cell := State.Location;

    if State.ActionProgress > REPRODUCTION_DURATION_TICKS then
    begin
      var offspringState := BuildOffspringState(State, NextAgentId);
      State.Reserves := State.Reserves - REPRODUCTION_PARENT_COST;
      if State.Reserves < 0.0 then
        State.Reserves := 0.0;
      State.TicksSinceReproduction := 0;
      State.ActionProgress := 0;

      fPopulation.AppendAgent(offspringState);
      Inc(fPopulationSummary.NewBirths);
      Inc(fPopulationSummary.Living);

      // Newborn's initial state contributes to this tick's snapshot.
      fTickTotalReserves := fTickTotalReserves + offspringState.Reserves;
      if offspringState.Reserves > fPopulationSummary.MaxReserves.Reserves then
      begin
        fPopulationSummary.MaxReserves.AgentId := offspringState.AgentId;
        fPopulationSummary.MaxReserves.Reserves := offspringState.Reserves;
      end;

      EmitAgentBorn(offspringState, State);

      Result.RequestedAction := acIdle;
      Exit;
    end;

    Inc(State.ActionProgress);
    Result.RequestedAction := acReproduce;
    Exit;
  end;

  if Requested.RequestedAction = acReproduce then
  begin
    Result.RequestedTarget.TType := ttCell;
    Result.RequestedTarget.Cell := State.Location;

    if State.Action <> acReproduce then
    begin
      if State.Reserves < REPRODUCTION_MIN_ATTEMPT_RESERVES then
      begin
        Result.RequestedAction := acIdle;
        Exit;
      end;

      State.ActionProgress := 1;
      Result.RequestedAction := acReproduce;
      Exit;
    end;
  end;

  if Requested.RequestedAction = acShelter then
  begin
    Result.RequestedTarget.TType := ttCell;
    Result.RequestedTarget.Cell := State.Location;
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

        // Clear the action target when the agent arrives at its destination,
        // so cognition doesn't carry a stale target into the next tick.
        if (Result.RequestedTarget.TType = ttCell)
          and (State.Location = Result.RequestedTarget.Cell) then
        begin
          Result.RequestedTarget.TType := ttNone;
          Result.RequestedTarget.Cell := -1;
        end;

        Result.RequestedAction := acMove;
        Result.RequestedTarget := Requested.RequestedTarget;
//        EmitAgentMoved(State, moveReply.PreviousCell, moveReply.NewCell, moveCost);

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
        ForageOutcome.Consumed := reply.ConsumedAmount;
        ForageOutcome.Gain := CalculateForageGain(State, GeneMap, reply);
        ForageOutcome.Substance := reply.Substance;
        State.Reserves := State.Reserves + ForageOutcome.Gain;

        // Delta buys a small amount of circadian runway after net energy gain is applied.
        if ForageOutcome.Gain > 0.0 then
        begin
          var deltaConsumed := reply.ConsumedAmount * (reply.Substance[Delta] / 100.0);
          if deltaConsumed > 0.0 then
          begin
            var deltaRelief := deltaConsumed * DELTA_CIRCADIAN_RELIEF_RATE;
            State.CircadianPressure := Max(0.0, State.CircadianPressure - deltaRelief);
          end;
        end;

        State.TicksSinceForage := 0;
        State.LastForageCell := State.Location;

//        if cacheRef.Kind = ckDelta then
//          EmitDeltaConsumed(State, cacheRef, ForageOutcome.Consumed, ForageOutcome.Gain);
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
var
  agentInput: TBrainTickInput;
begin
  var state := fPopulation.GetAgentState(aIndex);

  // Dead agents remain in population data but do not age or think.
  if state.Reserves <= 0.0 then
    Exit;

  // Resolve gene sequence to class pointers for this agent's tick.
  agentInput := Input;
  TGeneSequencer.Populate(agentInput.GeneMap, state.Genome.Sequence);

  // This agent is alive at tick start — count it.
  Inc(fPopulationSummary.Living);

  // Age tracks ticks survived; this includes the tick where upkeep may cause death.
  Inc(state.Age);
  Inc(state.TicksSinceReproduction);
  Inc(state.TicksSinceForage);

  // Circadian pressure: accumulate while awake, relieve while sleeping underground
  if (state.Action = acShelter) then
  begin
    if state.ActionProgress > 0 then
    begin
      // Already underground — relieve pressure and advance sleep progress
      state.CircadianPressure := state.CircadianPressure - state.CircadianRelief;
      if state.CircadianPressure < 0.0 then
        state.CircadianPressure := 0.0;
      Inc(state.ActionProgress);
    end
    else if state.ActionAge >= DIG_TICKS then
    begin
      // Just finished digging — transition to underground
      state.ActionProgress := 1;
    end
    else
    begin
      // Still digging — pressure builds normally
      state.CircadianPressure := state.CircadianPressure + CIRCADIAN_COST_PER_TICK;
      if state.CircadianPressure > MAX_CIRCADIAN_PRESSURE then
        state.CircadianPressure := MAX_CIRCADIAN_PRESSURE;
    end;
  end
  else
  begin
    // Awake and active — pressure builds toward global max
    state.CircadianPressure := state.CircadianPressure + CIRCADIAN_COST_PER_TICK;
    if state.CircadianPressure > MAX_CIRCADIAN_PRESSURE then
      state.CircadianPressure := MAX_CIRCADIAN_PRESSURE;
  end;

  var reservesAtTickStart := state.Reserves;

  if not ApplyAgentUpkeep(state^, agentInput.GeneMap) then
  begin
    // Dead agents do not think or request actions.
    var lastAction := state.Action;
    state.ReserveDelta := state.Reserves - reservesAtTickStart;
    state.Action := acIdle;
    state.ActionAge := 0;
    state.ActionProgress := 0;
    EmitAgentDied(state^, lastAction);
    Inc(fPopulationSummary.NewDeaths);
    Inc(fTotalDeaths);
    Dec(fPopulationSummary.Living);

    // Notify environment once at transition-to-death.
    fEnvironment.NotifyAgentDeath(state.Location, DEFAULT_DEATH_BIOMASS_AMOUNT);
    Exit;
  end;

  var requested := fPopulation.Think(aIndex, agentInput);
  var forageOutcome := Default(TForageOutcome);
  var stateBeforeResolution := state^;
  var resolved := ResolveRequestedStep(aIndex, state^, agentInput.GeneMap, requested, forageOutcome);
  state.ReserveDelta := state.Reserves - reservesAtTickStart;

  // Post-resolution death (e.g. move cost or reproduction cost drained reserves)
  if state.Reserves <= 0.0 then
  begin
    Inc(fPopulationSummary.NewDeaths);
    Inc(fTotalDeaths);
    Dec(fPopulationSummary.Living);
  end
  else
  begin
    // Accumulate snapshot stats for surviving agents at their settled end-of-tick state.
    fTickTotalReserves := fTickTotalReserves + state.Reserves;

    if state.Age > fPopulationSummary.LongestLife.Age then
    begin
      fPopulationSummary.LongestLife.AgentId := state.AgentId;
      fPopulationSummary.LongestLife.Age := state.Age;
    end;

    if state.Reserves > fPopulationSummary.MaxReserves.Reserves then
    begin
      fPopulationSummary.MaxReserves.AgentId := state.AgentId;
      fPopulationSummary.MaxReserves.Reserves := state.Reserves;
    end;

    if state.Action = acShelter then
      Inc(fPopulationSummary.Sheltering);

    // Chebyshev distance from birthplace to current location.
    var gridWidth := fEnvironment.Dimensions.cx;
    if gridWidth > 0 then
    begin
      var bx := state.Birthplace mod gridWidth;
      var by := state.Birthplace div gridWidth;
      var lx := state.Location mod gridWidth;
      var ly := state.Location div gridWidth;
      var dist := Abs(lx - bx);
      if Abs(ly - by) > dist then
        dist := Abs(ly - by);
      if dist > fPopulationSummary.MaxDistance.Distance then
      begin
        fPopulationSummary.MaxDistance.AgentId := state.AgentId;
        fPopulationSummary.MaxDistance.Distance := dist;
      end;
    end;
  end;

  // Skip learning during sleep — agent learns what sleep did for them on the waking tick.
  if not ((state.Action = acShelter) and (state.ActionAge >= DIG_TICKS)) then
  begin
    var reflectInput: TBrainReflectInput;
    reflectInput.ResolvedAction := resolved.RequestedAction;
    reflectInput.ResolvedTarget := resolved.RequestedTarget;
    reflectInput.ForageOutcome := forageOutcome;
    reflectInput.GridWidth := fEnvironment.Dimensions.cx;
    reflectInput.PreviousLocation := stateBeforeResolution.Location;
    reflectInput.CurrentLocation := state.Location;
    reflectInput.GeneMap := agentInput.GeneMap;
    fPopulation.Reflect(aIndex, requested, reflectInput);
  end;

  EmitActionResolved(stateBeforeResolution, state^, requested, resolved);

  // Stasis reset on wake: when transitioning out of shelter after sleeping,
  // grant reserves proportional to how much pressure was relieved.
  if (state.Action = acShelter) and (state.ActionAge >= DIG_TICKS)
    and (resolved.RequestedAction <> acShelter) then
  begin
    var recoveryRatio := 1.0 - EnsureRange(state.CircadianPressure / MAX_CIRCADIAN_PRESSURE, 0.0, 1.0);
    state.Reserves := STASIS_ENERGY * recoveryRatio;
  end;

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
const
  SEED_STRIDE = 7;          // visit every 7th cache per pass — full coverage in 7 passes
  SEED_INTERVAL = 5;        // seed every 5 ticks during the seeding window
  SEED_AMOUNT = 0.05;       // initial sprout amount planted by the seeder
  SEED_WINDOW = DAYLIGHT_TICKS_PER_DAY div 2;  // seed during first half of daylight
begin
  var previousSolarFlux := fEnvironment.SolarFlux;

  fCurrentDayTick := Value;
  fEnvironment.DayTick := Value;

  // Strided resource seeder: plant seed amounts in caches over the first half of the day.
  if (Value < SEED_WINDOW) and (Value mod SEED_INTERVAL = 0) then
  begin
    fEnvironment.SeedResources(fSeedIndex, SEED_STRIDE, SEED_AMOUNT);
    Inc(fSeedIndex);
    if fSeedIndex >= SEED_STRIDE then
      fSeedIndex := 0;
  end;

  fCurrentDayTick := Value;
  fEnvironment.DayTick := Value;

  // Reset per-tick event counters and snapshot accumulators
  BeginTickSummary;

  InjectDeltaAtNightfall;
  HandleDeltaCleanupPolicy(fEnvironment.LastDeltaUpkeepReport);

  var currentSolarFlux := fEnvironment.SolarFlux;

  NotifyPhase(stpPostEnvironment);

  EmitPrePopulation;

  var input: TBrainTickInput;
  input.SolarFlux := currentSolarFlux;
  input.SolarFluxDelta := currentSolarFlux - previousSolarFlux;
  input.Query := fSimQuery;
  input.GestationDuration := REPRODUCTION_DURATION_TICKS;

  var agentCount := fPopulation.AgentCount;
  if (agentCount > 0) and (fCurrentGlobalTick >= CLOCK_TICKS_PER_DAY + fRuntimeConfig.AgentActivationTick) then
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

  // Finalize snapshot stats from inline tracking
  FinalizeTickSummary;

  EmitPostPopulation;

  NotifyPhase(stpPostAgents);
end;

end.
