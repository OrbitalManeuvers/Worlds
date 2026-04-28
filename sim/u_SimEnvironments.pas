unit u_SimEnvironments;

interface

uses System.Types, u_SimClocks,

  u_EnvironmentTypes;

type
  // something that can be found on the ground
  TSubstance = array[TMolecule] of TPercentage;

  // how natural resources are tracked and managed. upscaler sets this up
  TResourceCache = record
    SubstanceIndex: Word;    // index into Substances array
    Amount: Single;          // mutable simulation state
    RegenDebt: Single;       // stacked recoil cooldown (in ticks) before regrowth resumes
    GrowthRate: Single;      // incorporates Biome.GrowthRate and Food.GrowthRate
  end;

  // biomass caches are separate from growable resources - dynamic and temporary
  TBiomassCache = record
    CellIndex: Integer;
    Amount: Single;
    RegenDebt: Single;
  end;

  // Grid is made up of TCell
  TCell = record
    ResourceStart: Integer;
    ResourceCount: Word;
    Sunlight: Single;
    Mobility: Single;
  end;

  TCellArray = array of TCell;
  TResourceArray = array of TResourceCache;
  TSubstanceArray = array of TSubstance;
  TBiomassCacheArray = array of TBiomassCache;

  TSimEnvironment = class
  private
    fDimensions: TSize;
    fCells: TCellArray;
    fResources: TResourceArray;
    fResourceCount: Integer; // read only cache for instrumentation
    fSubstances: TSubstanceArray;
    fSolarFlux: Single;
    fBiomassCaches: TBiomassCacheArray;
    procedure SetDayTick(const Value: TDayTick);
    procedure UpdateResources(const aDayTick: TDayTick);
    procedure UpdateBiomass(const aDayTick: TDayTick);
    function CreateBiomassCache(CellIndex: Integer; InitialAmount: Single): Integer;
  public
    constructor Create;
    destructor Destroy; override;

    { runtime lookups built by upscaler }
    procedure SetSubstanceCount(aCount: Integer);
    procedure SetSubstance(aIndex: Integer; aSubstance: TSubstance);

    { monolithic allocations }
    procedure SetDimensions(aSize: TSize);
    procedure SetResourceCount(aCount: Integer);

    // Public biomass insertion path for runtime-controlled deposits.
    procedure InjectBiomass(Location: Integer; BiomassAmount: Single);

    // Hook for runtime death events. BiomassAmount is currently caller-selected.
    // Future expansion: derive this from richer agent death metadata (mass, composition, etc.).
    procedure NotifyAgentDeath(Location: Integer; BiomassAmount: Single);

    property Cells: TCellArray read fCells;

    property Resources: TResourceArray read fResources;
    property ResourceCount: Integer read fResourceCount;

    property Substances: TSubstanceArray read fSubstances;

    property SolarFlux: Single read fSolarFlux write fSolarFlux;
    property DayTick: TDayTick write SetDayTick;
    property Dimensions: TSize read fDimensions;

    property BiomassCaches: TBiomassCacheArray read fBiomassCaches;
  end;

const
  BIOMASS_SUBSTANCE: TSubstance = (0, 0, 0, 100);

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

  UpdateResources(Value);
  UpdateBiomass(Value);
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

procedure TSimEnvironment.SetSubstance(aIndex: Integer; aSubstance: TSubstance);
begin
  fSubstances[aIndex] := aSubstance;
end;

procedure TSimEnvironment.SetSubstanceCount(aCount: Integer);
begin
  SetLength(fSubstances, aCount);
end;

procedure TSimEnvironment.NotifyAgentDeath(Location: Integer; BiomassAmount: Single);
begin
  InjectBiomass(Location, BiomassAmount);
end;

procedure TSimEnvironment.InjectBiomass(Location: Integer; BiomassAmount: Single);
begin
  // Bounds-check Location against valid cell indices.
  if (Location < 0) or (Location > High(fCells)) then
    Exit;

  CreateBiomassCache(Location, BiomassAmount);
end;

function TSimEnvironment.CreateBiomassCache(CellIndex: Integer; InitialAmount: Single): Integer;
var
  NewCache: TBiomassCache;
begin
  NewCache.CellIndex := CellIndex;
  NewCache.Amount := EnsureRange(InitialAmount, 0.0, 1.0);
  NewCache.RegenDebt := 0.0;
  
  SetLength(fBiomassCaches, Length(fBiomassCaches) + 1);
  fBiomassCaches[High(fBiomassCaches)] := NewCache;
  
  Result := High(fBiomassCaches);
end;

procedure TSimEnvironment.UpdateBiomass(const aDayTick: TDayTick);
const
  BIOMASS_SUNLIGHT_DECAY_RATE = 0.08;
  BIOMASS_NIGHT_DECAY_RATE = 0.002;
var
  decay: Single;
begin
  for var cacheIndex := 0 to High(fBiomassCaches) do
  begin
    decay := fSolarFlux * BIOMASS_SUNLIGHT_DECAY_RATE + BIOMASS_NIGHT_DECAY_RATE;
    fBiomassCaches[cacheIndex].Amount := EnsureRange(
      fBiomassCaches[cacheIndex].Amount - decay,
      0.0,
      1.0
    );
  end;
end;

end.
