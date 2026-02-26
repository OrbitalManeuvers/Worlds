# Worlds Project - Geography/Environment

## World Layout (Regions)

- A **Region** is authored as a 32x32 biome map.
- The simulator **upscales** a Region by 8x to produce a 256x256 simulation grid.
- A **World** is a 3x3 grid of Regions.
  - Region borders should behave seamlessly.
  - “Empty border” Regions can act like world edges (same rules as outer boundary).
- Agent addressing can be thought of as: **RegionId + X,Y** ("R:X,Y").

## Authoring vs Simulating

- Authoring process is "low-resolution" for simplicity
- Loading authored data into the simulator includes an `upscaling` step
- During `upscaling` the simulator performs randomization, smoothing, etc

## Upscaling Rules (English)

The goal of upscaling is: **author low-resolution, simulate high-resolution** while keeping runtime rules simple.

- **Deterministic:** upscaling should use a seeded RNG so the same authored inputs produce the same simulated world (unless the author changes something).
- **Biome smoothing:** smoothing applies to biome borders (to avoid harsh 32x32 blockiness), but should not invent new biome IDs—only soften edges.
- **Per-cell derived values:** the simulator precomputes per-cell values during upscaling (and these are mostly static during runtime, for now):
  - per-cell capacity limits
  - per-cell growth-per-tick numbers
  - per-cell mobility cost modifiers (from biomes)
  - any per-cell noise/jitter (so the world doesn’t look like a tiled pattern)

Runtime should ideally be “one simple operation per tick” using these precomputed values.

## Things You Author

- Resources
- Geography

## Authoring: Weights/Ratings

While the simulator will require the "floats not booleans" mantra everywhere, the authoring process does not. Abstractions and low-resolution values will be used where possible.

```pascal
type
  // this could be expressed in lots of ways - the goal here is a centerpoint that's neutral,
  // and values that are less than and greater than.
  TRating = (Worst, Horrible, Bad, Normal, Good, Great, Best);
```

### Rating Meaning (Guideline)

Ratings exist to keep authoring fast. During upscaling they become simulation-friendly numbers.

- Use ratings for *relative intent* (“this biome grows stuff faster than that one”), not scientific precision.
- When upscaled, each rating should map to:
  - a capacity-style multiplier ("how much can exist here") and/or
  - a growth-style multiplier ("how fast it refills")

The exact mapping can change later for tuning; authored files should not have to change.


## Authoring: Resources

There are five elemental substances. Three of the elements can be assembled into consumables.

For simple naming: you create different types of `food` using the available `proteins` (or `enzymes`?)

So perhaps:

```pascal
type
  // "Material" here means: a constituent channel that can appear in food recipes
  // AND also describes what agents are made of.
  //
  // Key idea: don't bake "living vs dead" into the enum members.
  // Living-vs-dead is a property of the thing you're observing:
  // - an agent is living biomass
  // - a carcass resource cache is dead biomass (and can decay)
  TMaterial = (Alpha, Beta, Gamma, Biomass);

  TBiomassState = (Living, Dead);
```


### Building Food

```pascal
type
  TIngredient = record
    Material: TMaterial;
    Percent: Integer;
  end;

  TConsumable = record
    Name: string;
    Recipe: array of TIngredient; // totals 100%
    GrowthRate: TRating;          // upscales to tick count
  end;
```
When a consumable appears in nature:

```pascal
type
  TResource = record
    Consumable: TConsumable;
    Availability: TRating; // i.e. Density
  end;

```

The authoring UI will allow creating TConsumables.

Somewhere, someday, this will exist:
```pascal
type
  TAbsorptionEfficiency = array[TMaterial] of TRating;
```


## Authoring: Geography

Authoring resolution is 32x32.

```pascal
const
  EDITOR_CELL_COUNT = 32;  // a 32x32 square  
  EDITOR_CELL_SIZE = 32;   // each cell is 32px x 32px

type
  TBiomeMarker = Byte;
  TGridExtent = 0 .. EDITOR_CELL_COUNT - 1;
  TBiomeGrid = array[TGridExtent, TGridExtent] of TBiomeMarker;

  TBiomeMap = class
  strict private
    fMap: TBiomeGrid;
  private
    function GetMarker(XPos, YPos: TGridExtent): TBiomeMarker;
  protected
  public
    constructor Create;
    destructor Destroy; override;
    property Markers[XPos, YPos: TGridExtent]: TBiomeMarker read GetMarker;
    property Map: TBiomeGrid read fMap;
  end;

```

Striving for simplicity ...

```pascal
type
  TBiome = record
    Id: TBiomeMarker;
    Name: string;
    Description: string;
    Color: TColor;
    Resources: array of TResource;

    // general
    Sunlight: TRating;
    Mobility: TRating;

    // resource modifiers
    GrowthRate: TRating;
    Capacity: TRating;
  end;

  TRegion = class
  public
    property Title: string read fTitle write SetTitle;
    property Description: string read fDescription write SetDescription;
    property BiomeCount: Integer read GetBiomeCount;
    property Biomes[I: Integer]: TBiome read GetBiome;
    property BiomeMap: TBiomeMap read fBiomeMap;
  end;

```

The UI will allow:
- creating a library of `TConsumable` items 
- creating a library of `TBiome` items
- creating a `TRegion` by painting a 32x32 grid with biomes



## General Simulator Ideas for Resources

- each cell is associated with a cache of resources
- resources are updated by the sim each tick
- a resource has a quantity that
  - can max out at whatever `TResource.Availability` upscales to
  - increases as a factor of sun, biome params, food params, etc
  - (decreases overnight?)

## Runtime Resource Model (Simple, Competitive)

Target behavior: resources are **shared, local, and competitive**.

- Each simulation cell maintains a resource “tonnage” per resource type.
- Each resource type in a cell has:
  - current amount (how much is there right now)
  - max capacity (how much can exist here)
  - refill rate (how much grows back per tick)
- Any agent in the same cell may consume from the same shared pool.
  - This naturally creates competition and scarcity without scripting roles.

During upscaling, compute the per-cell max and per-cell refill so runtime is simple:
- each tick: refill a little (up to max)
- each tick: subtract what agents consumed

## Crowding, Waste, and Decay (simple pressures)

Goal: 1–2 agents feeding from the same cell feels like a clean split; lots of agents feels panicky and wasteful ("bloodbath at the bush", "hyenas on a carcass").

### Crowding waste (applies to ALL resource caches)

When multiple agents consume from the same cell/resource cache on the same tick:
- The cache amount still goes down by the full attempted consumption.
- But each agent’s *effective intake* is reduced when the crowd is large.
- The difference is treated as **waste** (spillage, fighting, trampling, lost opportunity).

This is intentionally separate from the agent’s personal absorption/efficiency.
It is a property of the local feeding situation ("too many mouths here"), not biology.

Implementation note (no math required): make a small efficiency table by consumer count.
Example shape: 1–2 consumers = high efficiency; 3–4 = noticeably worse; 5+ = severe waste.

### Carrion/carcasses (Critter/Carrion)

Carrion participates in the same shared-cache and crowding-waste rules (multiple eaters can make a mess).
Unlike plants:
- there is **no natural refill/growth**
- there is **decay** (a per-tick reduction over time)

So: carrion has “stock goes down when eaten”, “stock goes down when decaying”, and “crowding reduces effective intake”.

### Plants later: add overgrazing/trampling as a second pressure (optional)

If you later want crowds to damage a patch beyond just eating faster, add a separate per-cell “degradation” number for plant-like resources:
- crowds increase degradation quickly
- degradation heals slowly
- while degraded, growth and/or capacity is reduced

This is optional and can be added after the base model is fun.

decided:
- **Night reduces growth** rather than making resources actively shrink.

for a stronger night effect
- **Night growth = zero** (no refill at night)

## Tuning Knobs (Later, without changing authoring)

These are the levers you can adjust later for balance, famine scenarios, and pacing:
- How fast cells refill (refill rate)
- How much a cell can hold (capacity)
- How much an agent consumes per tick while “eating” (consumption rate)
- How long “eating” takes (multi-tick action duration)
- Day/night multipliers for growth and/or for agent efficiency (e.g., harder to forage at night)
- Randomization amplitude during upscaling (how patchy vs uniform the world feels)


