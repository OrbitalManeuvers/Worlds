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
    Capacity: Single;        // fixed modifiers...
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
    procedure SetClockTick(const Value: TClockTick);
    procedure UpdateResources(const aClockTick: TClockTick);
  public
    constructor Create;
    destructor Destroy; override;

    { runtime lookups built by upscaler }
    procedure SetSubstanceCount(aCount: Integer);
    procedure SetSubstance(aIndex: Integer; aSubstance: TSubstance);

    { monolithic allocations }
    procedure SetDimensions(aSize: TSize);
    procedure SetResourceCount(aCount: Integer);

    property Cells: TCellArray read fCells;

    property Resources: TResourceArray read fResources;
    property ResourceCount: Integer read fResourceCount;

    property Substances: TSubstanceArray read fSubstances;

    property SolarFlux: Single read fSolarFlux write fSolarFlux;
    property ClockTick: TClockTick write SetClockTick;
    property Dimensions: TSize read fDimensions;
  end;

implementation

uses System.Math;

function BaseSolarFlux(const ClockTick: TClockTick): Single;
var
  Phase: Single;
begin
  if ClockTick > High(TDaylightTicks) then
    Exit(0);

  // Convert discrete tick position into a continuous daylight phase.
  Phase := ClockTick / High(TDaylightTicks); // 0..1 across daylight ticks
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

procedure TSimEnvironment.SetClockTick(const Value: TClockTick);
begin
  fSolarFlux := BaseSolarFlux(Value);

  UpdateResources(Value);
  // UpdateBiomass; // planned cache pass
end;

procedure TSimEnvironment.UpdateResources(const aClockTick: TClockTick);
const
  // Percentage decay per tick. Night can be same as day (no-growth-only nights)
  // or higher for stronger overnight collapse.
  DAY_DECAY_RATE = 0.01;
  NIGHT_DECAY_RATE = 0.1;
var
  isNight: Boolean;
begin
  // Resource growth pass is driven by current SolarFlux and per-cell modifiers.
  // Growth slows as a cache approaches capacity, making full-cap saturation rarer.
  isNight := aClockTick > High(TDaylightTicks);

  for var cellIndex := 0 to High(fCells) do
  begin
    var light := fSolarFlux * fCells[cellIndex].Sunlight;
    var start := fCells[cellIndex].ResourceStart;
    var count := fCells[cellIndex].ResourceCount;

    for var i := 0 to count - 1 do
    begin
      var resIndex := start + i;
      var capacity := fResources[resIndex].Capacity;
      var amount := fResources[resIndex].Amount;
      var fill := 0.0;
      if capacity > 0 then
        fill := EnsureRange(amount / capacity, 0.0, 1.0);

      // Soft cap: growth fades out as the cache fills.
      var growth := light * fResources[resIndex].GrowthRate * (1.0 - fill);

      var decayRate := DAY_DECAY_RATE;
      if isNight then
        decayRate := NIGHT_DECAY_RATE;
      var decay := amount * decayRate;

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

end.
