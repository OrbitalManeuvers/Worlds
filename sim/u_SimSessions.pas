unit u_SimSessions;

interface

uses System.Classes, System.Types, System.Generics.Collections,
 u_Worlds, u_EnvironmentTypes, u_EnvironmentLibraries,
 u_Simulators, u_SimParams, u_Foods, u_SimWatches, u_SimPhases,
 u_SimUpscalers, u_BiologyTypes, u_SimEnvironments, u_SimDiagnostics, u_SimDiagnosticsIntf;

type
  TLogEvent = procedure (Sender: TObject; const aMsg: string) of object;

  // manual authoring for debugging
  TDebugParameters = record
    Dimensions: TSize;
    DefaultSunlight: TRating;
    DefaultMobility: TRating;
    Foods: array of TFood;

    Agents: array of record
      Location: TPoint;
      ConverterRatings: TMoleculeRatings; // can be nil
      SmellRatings: TMoleculeRatings;     // can be nil
      GeneSequence: string;
    end;

    Resources: array of record
      Location: TPoint;        // can be duplicated
      Caches: array of record
        FoodIndex: Word;
        GrowthRate: TRating;
      end;
    end;

    function AddFood(aFood: TFood): Integer;
    procedure AddAgent(aLocation: TPoint; aConverterRatings, aSmellRatings: TMoleculeRatings);
    procedure AddResource(aLocation: TPoint; aFood: TFood; aGrowthRate: TRating);
  end;

  TDebugSetupEvent = procedure (Sender: TObject; var Params: TDebugParameters) of object;

  TSimSession = class
  private
    fWorld: TWorld;
    fLibrary: TEnvironmentLibrary;
    fDiagnostics: TSimDiagnosticsHub;
    fDiagnosticsSink: ISimDiagnosticsSink;
    fSim: TSimulator;
    fParams: TSimParams;
    fSeed: Integer;
    fFoods: TList<TFood>;
    fWatches: TObjectList<TSimWatch>;
    fNextWatchId: Integer;
    fOnLog: TLogEvent;
    fOnBeforeStep: TNotifyEvent;
    fOnAfterStep: TNotifyEvent;
    fOnWatchChange: TWatchChangedEvent;
    fOnDebugSetup: TDebugSetupEvent;
    procedure Log(const aMsg: string); overload;
    procedure Log(const aMsgFmt: string; const Params: array of const); overload;
    procedure EvaluateWatches(const Phase: TSimTickPhase);
    procedure HandleRuntimePhase(Sender: TObject; Phase: TSimTickPhase);
    procedure PrimePendingWatches;
    procedure UpdateWatchBindings;
    function RegisterWatch(AWatch: TSimWatch): TSimWatch;
    procedure PopulateDebugRuntime(const Params: TDebugParameters);
  public
    constructor Create(aWorld: TWorld; const aParams: TSimParams; aLibrary: TEnvironmentLibrary);
    destructor Destroy; override;

    procedure BeginSession;
    procedure EndSession;
    procedure PrimeWatches;

    procedure Step;

    function AddAgentWatch(AgentIndex: Integer; const Callback: TWatchChangedEvent = nil;
      const Phases: TSimTickPhases = [stpPostAgents]): TAgentWatch;
    function AddCellWatch(CellIndex: Integer; SubstanceIndex: Integer = -1;
      const Callback: TWatchChangedEvent = nil;
      const Phases: TSimTickPhases = [stpPostAgents];
      const EmitMode: TCellWatchEmitMode = cemOnChange): TCellWatch;
    function AddFollowingCellWatch(AgentIndex: Integer; SubstanceIndex: Integer = -1;
      const Callback: TWatchChangedEvent = nil;
      const Phases: TSimTickPhases = [stpPostAgents];
      const EmitMode: TCellWatchEmitMode = cemOnChange): TFollowingCellWatch;
    procedure RemoveWatch(AWatch: TSimWatch);
    procedure ClearWatches;

    property Simulator: TSimulator read fSim;
    property Diagnostics: TSimDiagnosticsHub read fDiagnostics;
    property Foods: TList<TFood> read fFoods;
    property Seed: Integer read fSeed;

    property OnLog: TLogEvent read fOnLog write fOnLog;
    property OnBeforeStep: TNotifyEvent read fOnBeforeStep write fOnBeforeStep;
    property OnAfterStep: TNotifyEvent read fOnAfterStep write fOnAfterStep;
    property OnWatchChange: TWatchChangedEvent read fOnWatchChange write fOnWatchChange;

    property OnDebugSetup: TDebugSetupEvent read fOnDebugSetup write fOnDebugSetup;
  end;

implementation

uses System.SysUtils,
  u_WorldLayouts, u_SimPopulators, u_SimRuntimes, u_AgentState;

const
  NIGHTFALL_CACHE_COUNT: array[TRating] of Integer = (0, 1, 2, 4, 8, 16, 32);
  RANDOM_INJECT_CHANCE: array[TRating] of Integer = (0, 1, 3, 6, 10, 18, 30);

var
  NextSimSessionId: Integer = 0;


{ Utils }
function ResolveBiomassRuntimeConfig(const Params: TSimParams): TBiomassRuntimeConfig;
begin
  Result.InjectOnDeath := bimOnDeath in Params.Biomass.InjectionModes;
  Result.InjectAtNightfall := bimAtNightfall in Params.Biomass.InjectionModes;
  Result.InjectRandomlyAtNight := bimRandom in Params.Biomass.InjectionModes;
  Result.NightfallCacheCount := NIGHTFALL_CACHE_COUNT[Params.Biomass.Density];
  Result.RandomInjectChancePercent := RANDOM_INJECT_CHANCE[Params.Biomass.Density];
end;

function SubstanceToStr(const sub: TSubstance): string;
const
  fmt = 'A%.3d B%.3d G%.3d X%.3d ';
begin
  Result := Format(fmt, [
    sub[Alpha],
    sub[Beta],
    sub[Gamma],
    sub[Biomass]
  ]);
end;

{ TDebugParameters }
function TDebugParameters.AddFood(aFood: TFood): Integer;
begin
  var last := Length(Foods);
  SetLength(Foods, last + 1);
  Foods[last] := aFood;
  Result := last;
end;

procedure TDebugParameters.AddAgent(aLocation: TPoint; aConverterRatings, aSmellRatings: TMoleculeRatings);
begin
  var last := Length(Agents);
  SetLength(Agents, last + 1);
  Agents[last].Location := aLocation;
  Agents[last].ConverterRatings := aConverterRatings;
  Agents[last].SmellRatings := aSmellRatings;
  Agents[last].GeneSequence := 'AAAAAAAAA';
end;

procedure TDebugParameters.AddResource(aLocation: TPoint; aFood: TFood; aGrowthRate: TRating);
begin
  // food has to already exist in the list
  var foodIndex := -1;
  for var i := 0 to Length(Foods) - 1 do
    if Foods[i] = aFood then
    begin
      foodIndex := i;
      Break;
    end;
  Assert(foodIndex <> -1);

  var locationIndex := -1;
  var last := Length(Resources);
  if last > 0 then
  begin
    for var i := 0 to Length(Resources) - 1 do
      if Resources[i].Location = aLocation then
      begin
        locationIndex := i;
        Break;
      end;
  end;

  // if we don't have this location yet, add it
  if locationIndex = -1 then
  begin
    SetLength(Resources, last + 1);
    Resources[last].Location := aLocation;
    SetLength(Resources[last].Caches, 0);
    locationIndex := last;
  end;

  Assert(locationIndex <> -1);

  last := Length(Resources[locationIndex].Caches);
  SetLength(Resources[locationIndex].Caches, last + 1);
  Resources[locationIndex].Caches[last].FoodIndex := foodIndex;
  Resources[locationIndex].Caches[last].GrowthRate := aGrowthRate;
end;

{ TSimSession }

constructor TSimSession.Create(aWorld: TWorld; const aParams: TSimParams; aLibrary: TEnvironmentLibrary);
begin
  inherited Create;
  fWorld := aWorld;
  fLibrary := aLibrary;
  fParams := aParams;
  Inc(NextSimSessionId);
  fDiagnostics := TSimDiagnosticsHub.Create(NextSimSessionId);
  fDiagnosticsSink := fDiagnostics;

  //
  fSim := TSimulator.Create(ResolveBiomassRuntimeConfig(aParams), fDiagnosticsSink);
  fSim.Runtime.OnPhase := HandleRuntimePhase;
  fFoods := TList<TFood>.Create;
  fWatches := TObjectList<TSimWatch>.Create(True);
end;

destructor TSimSession.Destroy;
begin
  if Assigned(fSim) and Assigned(fSim.Runtime) then
    fSim.Runtime.OnPhase := nil;
  fWatches.Free;
  fFoods.Free;
  fSim.Free;
  fDiagnostics := nil;
  fDiagnosticsSink := nil;
  inherited;
end;

function TSimSession.RegisterWatch(AWatch: TSimWatch): TSimWatch;
begin
  if not Assigned(AWatch) then
    Exit(nil);

  Inc(fNextWatchId);
  AWatch.WatchId := fNextWatchId;
  fWatches.Add(AWatch);
  Result := AWatch;
end;

function TSimSession.AddAgentWatch(AgentIndex: Integer;
  const Callback: TWatchChangedEvent; const Phases: TSimTickPhases): TAgentWatch;
begin
  Result := TAgentWatch(RegisterWatch(TAgentWatch.Create(AgentIndex)));
  if Assigned(Result) then
  begin
    Result.Phases := Phases;
    Result.OnChange := Callback;
  end;
end;

function TSimSession.AddCellWatch(CellIndex, SubstanceIndex: Integer;
  const Callback: TWatchChangedEvent; const Phases: TSimTickPhases;
  const EmitMode: TCellWatchEmitMode): TCellWatch;
begin
  Result := TCellWatch(RegisterWatch(TCellWatch.Create(CellIndex, SubstanceIndex)));
  if Assigned(Result) then
  begin
    Result.Phases := Phases;
    Result.EmitMode := EmitMode;
    Result.OnChange := Callback;
  end;
end;

function TSimSession.AddFollowingCellWatch(AgentIndex, SubstanceIndex: Integer;
  const Callback: TWatchChangedEvent; const Phases: TSimTickPhases;
  const EmitMode: TCellWatchEmitMode): TFollowingCellWatch;
begin
  Result := TFollowingCellWatch(RegisterWatch(TFollowingCellWatch.Create(AgentIndex, SubstanceIndex)));
  if Assigned(Result) then
  begin
    Result.Phases := Phases;
    Result.EmitMode := EmitMode;
    Result.OnChange := Callback;

    // Bind immediately so startup priming targets the tracked agent cell.
    Result.AfterStep(fSim);
  end;
end;

procedure TSimSession.RemoveWatch(AWatch: TSimWatch);
begin
  if not Assigned(AWatch) then
    Exit;

  fWatches.Remove(AWatch);
end;

procedure TSimSession.ClearWatches;
begin
  fWatches.Clear;
end;

procedure TSimSession.BeginSession;
begin
  for var watch in fWatches do
    watch.Reset;

  if fParams.DebugMode then
  begin
    var params := Default(TDebugParameters);
    if Assigned(fOnDebugSetup) then
      fOnDebugSetup(Self, params);

    // populate the runtime according to the debug spec
    PopulateDebugRuntime(params);
  end
  else
  begin
    // Session seed policy:
    // - Params.Seed <> 0: force deterministic run by setting RTL seed.
    // - Params.Seed = 0: preserve current RTL seed and capture it as in-use value.
    if fParams.Seed <> 0 then
    begin
      RandSeed := fParams.Seed;
      fSeed := fParams.Seed;
    end
    else
      fSeed := RandSeed;

    // Environment
    // create the stitched-together world of selected regions
    var layout := TWorldLayout.Create(fWorld, fLibrary);
    try
      // the layout feeds the upscaler
      var upscaler := TWorldUpscaler.Create(fSim.Runtime.Environment, fParams);
      try
        upscaler.UpscaleWorld(layout);
      finally
        upscaler.Free;
      end;

      // save off the list of foods for later instrumentation
      for var f in layout.Foods do
        Self.fFoods.Add(f);
    finally
      layout.free;
    end;

    // Population
    TWorldPopulator.Populate(fSim.Runtime.Population, fSim.Runtime.Environment, fParams);
  end;

  // log resource map
  if Length(fSim.Runtime.Environment.Substances) = Self.Foods.Count then
  begin
    Log(Format('Session started: %s  Seed: %d ', [FormatDateTime('c', Now), fSeed]));
    Log('Substances:');
    for var i := 0 to Self.Foods.Count - 1 do
    begin
      var line := '[%.2d] %s  Food: %s';
      Log(line, [
        i,
        SubstanceToStr(fSim.Runtime.Environment.Substances[i]),
        Foods[i].Name
      ]);
    end;
  end;


end;

procedure TSimSession.EndSession;
begin
  for var watch in fWatches do
    watch.Reset;
end;

procedure TSimSession.EvaluateWatches(const Phase: TSimTickPhase);
begin
  for var watch in fWatches do
  begin
    if not watch.Evaluate(fSim, fSim.Clock.Tick, Phase) then
      Continue;

    watch.Notify(Self);
    if Assigned(fOnWatchChange) then
      fOnWatchChange(Self, watch);
  end;
end;

procedure TSimSession.HandleRuntimePhase(Sender: TObject; Phase: TSimTickPhase);
begin
  EvaluateWatches(Phase);
end;

procedure TSimSession.PrimePendingWatches;
begin
  for var watch in fWatches do
    if watch.NeedsPrime then
      watch.Prime(fSim, fSim.Clock.Tick);
end;

procedure TSimSession.UpdateWatchBindings;
begin
  for var watch in fWatches do
    watch.AfterStep(fSim);
end;

procedure TSimSession.PrimeWatches;
begin
  // Capture initial baselines without emitting watch change callbacks.
  for var watch in fWatches do
    watch.Prime(fSim, fSim.Clock.Tick);
end;

procedure TSimSession.Log(const aMsgFmt: string; const Params: array of const);
begin
  Log(Format(aMsgFmt, Params));
end;

procedure TSimSession.Log(const aMsg: string);
begin
  if Assigned(fOnLog) then
    fOnLog(Self, aMsg);
end;

procedure TSimSession.Step;
begin
  if Assigned(fOnBeforeStep) then
    fOnBeforeStep(Self);

  // Apply selective baseline priming for watches that were rebound after prior step.
  PrimePendingWatches;

  fSim.Clock.Step;

  // Rebind follow-style watches after full phase evaluation so they start next tick on target cell.
  UpdateWatchBindings;

  if Assigned(fOnAfterStep) then
    fOnAfterStep(Self);

end;

procedure TSimSession.PopulateDebugRuntime(const Params: TDebugParameters);
begin

  // configure environment
  var env := fSim.Runtime.Environment;

  var upscaler := TDebugUpscaler.Create(env, Params.Dimensions, Params.DefaultSunlight, Params.DefaultMobility);
  try
    upscaler.SetFoods(Params.Foods);
    Self.Foods.AddRange(Params.Foods);

    var resourceCount := 0;
    for var def in Params.Resources do
      resourceCount := resourceCount + Length(def.Caches);
    upscaler.SetTotalResourceCount(resourceCount);

    for var def in Params.Resources do
    begin
      upscaler.SetCellResourceCount(def.Location.X, def.Location.Y, Length(def.Caches));
      for var i := 0 to Length(def.Caches) - 1 do
      begin
        upscaler.SetResource(def.Location.x, def.Location.Y, i,
          def.Caches[i].FoodIndex, def.Caches[i].GrowthRate);
      end;
    end;
  finally
    upscaler.Free;
  end;


  // configure population
  var population := fSim.Runtime.Population;
  var nextId: Cardinal := 1;

  population.SetCellCount(Length(env.Cells));
  population.AgentCount := Length(Params.Agents);

  for var agentIndex := 0 to Length(Params.Agents) - 1 do
  begin
    var agent := Params.Agents[agentIndex];
    var cellIndex := (agent.Location.Y * env.Dimensions.cx) + agent.Location.X;
    TDebugPopulator.PopulateAgent(population, agentIndex, nextId, cellIndex,
      agent.ConverterRatings, agent.SmellRatings, agent.GeneSequence);
  end;
end;


end.
