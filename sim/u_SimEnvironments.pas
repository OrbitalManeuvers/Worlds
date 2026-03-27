unit u_SimEnvironments;

interface

uses System.Types, u_SimClocks,

  u_EnvironmentTypes;

const
  DEFAULT_RESOURCE_CACHE_MAX_AMOUNT = 1.0;

type
  // something that can be found on the ground
  TSubstance = array[TMolecule] of TPercentage;

  // how natural resources are tracked and managed. upscaler sets this up
  TResourceCache = record
    SubstanceIndex: Word;    // index into Substances array
    Amount: Single;          // mutable simulation state
    GrowthRate: Single;      // incorporates Biome.GrowthRate and Food.GrowthRate
  end;

  // Grid is made up of TCell
  TCell = record
    ResourceStart: Word;  // not all cells have resources. needs to be discussed
    ResourceCount: Word;
    Sunlight: Single;
    Mobility: Single;
  end;

  TCellArray = array of TCell;
  TResourceArray = array of TResourceCache;
  TSubstanceArray = array of TSubstance;

  TSimEnvironment = class
  private
    fDimensions: TSize;
    fCells: TCellArray;
    fResources: TResourceArray;
    fResourceCount: Integer; // read only cache for instrumentation
    fSubstances: TSubstanceArray;
    fSolarFlux: Single;
    fResourceCacheMaxAmount: Single;
    procedure SetDayTick(const Value: TDayTick);
    procedure UpdateResources(const aDayTick: TDayTick);
  public
    constructor Create;
    destructor Destroy; override;

    { runtime lookups built by upscaler }
    procedure SetSubstanceCount(aCount: Integer);
    procedure SetSubstance(aIndex: Integer; aSubstance: TSubstance);

    { monolithic allocations }
    procedure SetDimensions(aSize: TSize);
    procedure SetResourceCount(aCount: Integer);

    // Hook for runtime death events. BiomassAmount is currently caller-selected.
    // Future expansion: derive this from richer agent death metadata (mass, composition, etc.).
    procedure NotifyAgentDeath(Location: Cardinal; BiomassAmount: Single);

    property Cells: TCellArray read fCells;

    property Resources: TResourceArray read fResources;
    property ResourceCount: Integer read fResourceCount;

    property Substances: TSubstanceArray read fSubstances;

    property ResourceCacheMaxAmount: Single read fResourceCacheMaxAmount write fResourceCacheMaxAmount;

    property SolarFlux: Single read fSolarFlux write fSolarFlux;
    property DayTick: TDayTick write SetDayTick;
    property Dimensions: TSize read fDimensions;
  end;

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
  fResourceCacheMaxAmount := DEFAULT_RESOURCE_CACHE_MAX_AMOUNT;

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
  // UpdateBiomass; // planned cache pass
end;

procedure TSimEnvironment.UpdateResources(const aDayTick: TDayTick);
const
  // Growable molecules decay at a constant rate whenever there is no sunlight.
  GROWABLE_NO_SUNLIGHT_DECAY_PER_TICK = 0.056;
begin
  // Resource growth pass is driven by current SolarFlux and per-cell modifiers.
  // Growth slows as a cache approaches max amount, making full-cap saturation rarer.

  for var cellIndex := 0 to High(fCells) do
  begin
    var light := fSolarFlux * fCells[cellIndex].Sunlight;
    var start := fCells[cellIndex].ResourceStart;
    var count := fCells[cellIndex].ResourceCount;

    for var i := 0 to count - 1 do
    begin
      var resIndex := start + i;
      var capacity := fResourceCacheMaxAmount;
      var amount := fResources[resIndex].Amount;
      var fill := 0.0;
      if capacity > 0 then
        fill := EnsureRange(amount / capacity, 0.0, 1.0);

      // Soft cap: growth fades out as the cache fills.
      var growth := light * fResources[resIndex].GrowthRate * (1.0 - fill);

      var decay := 0.0;
      if light <= 0 then
        decay := GROWABLE_NO_SUNLIGHT_DECAY_PER_TICK;

      fResources[resIndex].Amount := EnsureRange(
        amount + growth - decay,
        0.0,
        capacity
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

procedure TSimEnvironment.NotifyAgentDeath(Location: Cardinal; BiomassAmount: Single);
begin
  // Biomass insertion is intentionally deferred; runtime now has a formal hook.
  // TODO: route to biomass store when that subsystem is implemented.
end;

end.
