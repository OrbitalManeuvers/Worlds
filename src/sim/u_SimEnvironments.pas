unit u_SimEnvironments;

interface

uses System.Types,

  u_SimTypes, u_SimClocks, u_EnvironmentTypes;

type
  // something that can be found on the ground
  TSubstance = array[TMolecule] of TPercentage;

  // how natural resources are tracked and managed. upscaler sets this up
  TResourceCache = record
    CellIndex: Integer;      // which cell this belongs to
    SubstanceIndex: Word;    // index into Substances array
    Amount: Single;          // mutable simulation state
    RegenDebt: Single;       // stacked recoil cooldown (in ticks) before regrowth resumes
    GrowthRate: Single;      // incorporates Biome.GrowthRate and Food.GrowthRate
  end;

  // Delta caches are runtime-managed special caches.
  TDeltaCache = record
    CellIndex: Integer;
    Amount: Single;
    RegenDebt: Single;
  end;

  TDeltaUpkeepReport = record
    ActiveCount: Integer;
    ExtinctCount: Integer;
    UpdatedCount: Integer;
  end;

  // Grid is made up of TCell
  TCell = record
    ResourceStart: Integer;
    ResourceCount: Word;
    Sunlight: Single;  // affects resource growth
    Mobility: Single;  // affects movement cost
    DeltaChance: Word; // chance of a cache happening here tonight
  end;

  TCellArray = array of TCell;
  TResourceArray = array of TResourceCache;
  TSubstanceArray = array of TSubstance;
  TDeltaCacheArray = array of TDeltaCache;

  TSubstanceEntry = record
    Substance: TSubstance;
    Name: string;
  end;
  TSubstanceEntries = array of TSubstanceEntry;

  TSimEnvironment = class
  private
    fDimensions: TSize;
    fCells: TCellArray;
    fResources: TResourceArray;
    fResourceCount: Integer; // read only cache for instrumentation
    fSubstanceEntries: TSubstanceEntries;
    fSolarFlux: Single;
    fLunarFlux: Single;
    fDeltaCaches: TDeltaCacheArray;
    fLastDeltaUpkeepReport: TDeltaUpkeepReport;
    procedure SetDayTick(const Value: TDayTick);
    procedure UpdateResources(const aDayTick: TDayTick);
    function CreateDeltaCache(CellIndex: Integer; InitialAmount: Single): Integer;
  public
    constructor Create;
    destructor Destroy; override;

    { runtime lookups built by upscaler }
    procedure SetSubstanceCount(aCount: Integer);
    procedure SetSubstanceEntry(aIndex: Integer; const aSubstance: TSubstance; const aName: string);

    { monolithic allocations }
    procedure SetDimensions(aSize: TSize);
    procedure SetResourceCount(aCount: Integer);

    // Hook for runtime death events. BiomassAmount is currently caller-selected.
    procedure NotifyAgentDeath(Location: Integer; BiomassAmount: Single);

    procedure ApplyDeltaSpawnPlan(const Cells: array of Integer; InitialAmount: Single); overload;
    procedure ApplyDeltaSpawnPlan(const Cells: array of Integer; const Amounts: array of Single); overload;
    function UpdateDelta(const aDayTick: TDayTick): TDeltaUpkeepReport;
    function CleanupExtinctDeltaCaches: Integer;

    property Cells: TCellArray read fCells;
    property Resources: TResourceArray read fResources;
    property ResourceCount: Integer read fResourceCount;
    property SubstanceEntries: TSubstanceEntries read fSubstanceEntries;

    property SolarFlux: Single read fSolarFlux write fSolarFlux;
    property LunarFlux: Single read fLunarFlux write fLunarFlux;
    property DayTick: TDayTick write SetDayTick;
    property Dimensions: TSize read fDimensions;

    property DeltaCaches: TDeltaCacheArray read fDeltaCaches;
    property LastDeltaUpkeepReport: TDeltaUpkeepReport read fLastDeltaUpkeepReport;
  end;

const
  DELTA_SUBSTANCE: TSubstance = (0, 0, 0, 100);

implementation

uses System.Math;

function BaseSolarFlux(const DayTick: TDayTick): Single;
var
  Phase: Single;
begin
  if DayTick > High(TDaylightTicks) then
    Exit(0);

  // Convert discrete tick position into a continuous daylight phase.
  Phase := DayTick / High(TDaylightTicks); // 0..1 across daylight ticks
  Result := Sin(Pi * Phase);
  if Result < 0 then
    Result := 0;
end;

function BaseLunarFlux(const DayTick: TDayTick): Single;
var
  NightTick: Integer;
  Phase: Single;
begin
  if DayTick <= High(TDaylightTicks) then
    Exit(0);

  // NightTick: 0 at sunset, NIGHT_TICKS_PER_DAY-1 at end of night
  NightTick := DayTick - DAYLIGHT_TICKS_PER_DAY;

  // Asymmetric curve: fast rise, slow decay.
  // Use a skewed sine: compress the rise into the first 1/3 of the night,
  // let the decay coast through the remaining 2/3.
  Phase := NightTick / (NIGHT_TICKS_PER_DAY - 1); // 0..1 across night
  Result := Sin(Pi * Power(Phase, 0.45));           // exponent < 1 skews peak early
  if Result < 0 then
    Result := 0;
end;


{ TSimEnvironment }

constructor TSimEnvironment.Create;
begin
  inherited;
end;

destructor TSimEnvironment.Destroy;
begin
  //
  inherited;
end;

procedure TSimEnvironment.SetDayTick(const Value: TDayTick);
begin
  fSolarFlux := BaseSolarFlux(Value);
  fLunarFlux := BaseLunarFlux(Value);

  UpdateResources(Value);
  fLastDeltaUpkeepReport := UpdateDelta(Value);
end;

procedure TSimEnvironment.UpdateResources(const aDayTick: TDayTick);
const
  // Growable molecules decay at a constant rate whenever there is no sunlight.
  GROWABLE_NO_SUNLIGHT_DECAY_PER_TICK = 0.056;
  REGEN_DEBT_DECAY_PER_TICK = 1.0;
begin
  // Resource growth pass is driven by current SolarFlux and per-cell modifiers.
  // Growth slows as a cache approaches max amount, making full-cap saturation rarer.
  // Recoil cooldown blocks growth while active and decays each tick.

  for var cellIndex := 0 to High(fCells) do
  begin
    var light := fSolarFlux * fCells[cellIndex].Sunlight;
    var start := fCells[cellIndex].ResourceStart;
    var count := fCells[cellIndex].ResourceCount;

    for var i := 0 to count - 1 do
    begin
      var resIndex := start + i;
      var amount := fResources[resIndex].Amount;
      var debt := fResources[resIndex].RegenDebt;
      var fill := EnsureRange(amount, 0.0, 1.0);

      // Soft cap: growth fades out as the cache fills.
      var growth := light * fResources[resIndex].GrowthRate * (1.0 - fill);

      // Recoil cooldown: no regrowth while debt is active.
      if debt > 0.0 then
      begin
        debt := debt - REGEN_DEBT_DECAY_PER_TICK;
        growth := 0.0;
      end;

      var decay := 0.0;
      if light <= 0 then
        decay := GROWABLE_NO_SUNLIGHT_DECAY_PER_TICK;

      fResources[resIndex].RegenDebt := Max(0.0, debt);

      fResources[resIndex].Amount := EnsureRange(
        amount + growth - decay,
        0.0,
        1.0
      );
    end;
  end;
end;

procedure TSimEnvironment.SetDimensions(aSize: TSize);
begin
  fDimensions := aSize;
  SetLength(fCells, aSize.cx * aSize.cy);
end;

procedure TSimEnvironment.SetResourceCount(aCount: Integer);
begin
  fResourceCount := aCount;
  SetLength(fResources, aCount);
end;

procedure TSimEnvironment.SetSubstanceEntry(aIndex: Integer; const aSubstance: TSubstance; const aName: string);
begin
  fSubstanceEntries[aIndex].Substance := aSubstance;
  fSubstanceEntries[aIndex].Name := aName;
end;

procedure TSimEnvironment.SetSubstanceCount(aCount: Integer);
begin
  SetLength(fSubstanceEntries, aCount);
end;

procedure TSimEnvironment.NotifyAgentDeath(Location: Integer; BiomassAmount: Single);
begin
  // kept for future consideration
end;

function TSimEnvironment.CreateDeltaCache(CellIndex: Integer; InitialAmount: Single): Integer;
var
  NewCache: TDeltaCache;
begin
  NewCache.CellIndex := CellIndex;
  NewCache.Amount := EnsureRange(InitialAmount, 0.0, 1.0);
  NewCache.RegenDebt := 0.0;

  SetLength(fDeltaCaches, Length(fDeltaCaches) + 1);
  fDeltaCaches[High(fDeltaCaches)] := NewCache;

  Result := High(fDeltaCaches);
end;

procedure TSimEnvironment.ApplyDeltaSpawnPlan(const Cells: array of Integer; InitialAmount: Single);
begin
  for var i := 0 to High(Cells) do
    if (Cells[i] >= 0) and (Cells[i] <= High(fCells)) then
      CreateDeltaCache(Cells[i], InitialAmount);
end;

procedure TSimEnvironment.ApplyDeltaSpawnPlan(const Cells: array of Integer; const Amounts: array of Single);
begin
  for var i := 0 to High(Cells) do
    if (Cells[i] >= 0) and (Cells[i] <= High(fCells)) then
    begin
      var amount := 0.0;
      if i <= High(Amounts) then
        amount := Amounts[i];
      CreateDeltaCache(Cells[i], amount);
    end;
end;

function TSimEnvironment.UpdateDelta(const aDayTick: TDayTick): TDeltaUpkeepReport;
const
  DELTA_GROWTH_RATE = 0.04;
  DELTA_NO_MOON_DECAY_PER_TICK = 0.088;
  REGEN_DEBT_DECAY_PER_TICK = 1.0;
  DELTA_EXTINCTION_EPSILON = 0.001;
begin
  Result := Default(TDeltaUpkeepReport);
  Result.UpdatedCount := Length(fDeltaCaches);

  // Mirror core resource dynamics using lunar flux: soft-cap growth under moonlight,
  // no-moon decay when flux is absent, and debt-gated regrowth.
  for var i := 0 to High(fDeltaCaches) do
  begin
    var amount := fDeltaCaches[i].Amount;
    var debt   := fDeltaCaches[i].RegenDebt;
    var fill   := EnsureRange(amount, 0.0, 1.0);

    var growth := fLunarFlux * DELTA_GROWTH_RATE * (1.0 - fill);

    if debt > 0.0 then
    begin
      debt   := debt - REGEN_DEBT_DECAY_PER_TICK;
      growth := 0.0;
    end;

    var decay := 0.0;
    if fLunarFlux <= 0.0 then
      decay := DELTA_NO_MOON_DECAY_PER_TICK;

    fDeltaCaches[i].RegenDebt := Max(0.0, debt);
    fDeltaCaches[i].Amount    := EnsureRange(amount + growth - decay, 0.0, 1.0);
  end;

  for var i := 0 to High(fDeltaCaches) do
    if fDeltaCaches[i].Amount > DELTA_EXTINCTION_EPSILON then
      Inc(Result.ActiveCount)
    else
      Inc(Result.ExtinctCount);
end;

function TSimEnvironment.CleanupExtinctDeltaCaches: Integer;
const
  DELTA_EXTINCTION_EPSILON = 0.001;
begin
  Result := 0;
  var writeIndex := 0;

  for var i := 0 to High(fDeltaCaches) do
  begin
    if fDeltaCaches[i].Amount > DELTA_EXTINCTION_EPSILON then
    begin
      if i <> writeIndex then
        fDeltaCaches[writeIndex] := fDeltaCaches[i];
      Inc(writeIndex);
    end
    else
      Inc(Result);
  end;

  if writeIndex <> Length(fDeltaCaches) then
    SetLength(fDeltaCaches, writeIndex);
end;

end.
