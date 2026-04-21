unit u_SimUpscalers;

interface

uses System.Types, System.Classes, System.Generics.Collections,
  u_Regions, u_EnvironmentTypes, u_EnvironmentLibraries,
  u_Biomes, u_Foods,
  u_SimParams, u_SimEnvironments, u_WorldLayouts;

type
  TWorldUpscaler = class
  private
    Params: TSimParams;
    Environment: TSimEnvironment;
    RequiredResourceCount: Integer;
    function ResourceGrowthRate(aBiomeRating, aFoodRating: TRating): Single;
  public
    constructor Create(aEnvironment: TSimEnvironment; aParams: TSimParams);

    procedure UpscaleWorld(aLayout: TWorldLayout);
    property ResourceCount: Integer read RequiredResourceCount;
  end;

  TDebugUpscaler = class
  private
    Environment: TSimEnvironment;
    ResourceIndex: Integer;
  public
    constructor Create(aEnvironment: TSimEnvironment; aDimensions: TSize; aSunlight, aMobility: TRating);
    procedure SetFoods(const Foods: array of TFood);
    procedure SetCellResourceCount(aCellX, aCellY: Integer; aCount: Integer); // creates empty resource cache records
    procedure SetTotalResourceCount(aCount: Integer);
    procedure SetResource(aCellX, aCellY: Integer; aResourceIndex: Word; aSubstanceIndex: Integer; aGrowthRate: TRating);
  end;


implementation

uses System.Generics.Defaults, System.SysUtils, System.Math,
  u_EditorTypes, u_SimPopulations;

type
  TBiomeUsage = record
    Marker: TBiomeMarker;
    Count: Integer;
    Biome: TBiome;
  end;

  TBiomeHelper = class helper for TBiome
  private
    function _getFoodList: TList<TFood>;
  public
    property FoodList: TList<TFood> read _getFoodList;
  end;

  TFoodHelper = class helper for TFood
    function ToSubstance: TSubstance;
  end;

const
  // Sunlight rating: from no sun to baseline sun.
  // E.g. yourSunlight = globalSunlight * SUNLIGHT_FACTOR[rating]
  SUNLIGHT_FACTOR: array[TRating] of Single = (0.00, 0.10, 0.25, 0.50, 0.75, 0.90, 1.00);

  // Mobility rating: from heavy terrain penalty to no extra penalty.
  // Terrain cannot be better than baseline movement cost.
  // E.g. yourCost = normalMovementCost + (normalMovementCost * MOBILITY_COST_PENALTY[rating])
  // Best = normal + 0 penalty.
  MOBILITY_COST_PENALTY: array[TRating] of Single = (1.00, 0.90, 0.75, 0.50, 0.25, 0.10, 0.00);

  // GrowthRate Rating: from below sim avg to above sim avg
  // E.g. yourRate = normalRate * GROWTH_FACTOR[rating]
  GROWTH_FACTOR: array[TRating] of Single = (0.10, 0.35, 0.60, 1.00, 1.10, 1.18, 1.35);

  // Capacity Rating controls cache occurrence density (sparse vs abundant).
  // E.g. yourDensityChance = baseChance * CAPACITY_DENSITY_FACTOR[rating]
  CAPACITY_DENSITY_FACTOR: array[TRating] of Single = (0.01, 0.03, 0.06, 0.10, 0.11, 0.118, 0.135);


{ TBiomeHelper }

function TBiomeHelper._getFoodList: TList<TFood>;
begin
  Result := _foodList;
end;

{ TFoodHelper }

function TFoodHelper.ToSubstance: TSubstance;
begin
  Result[Alpha] := Self.Recipe.Percents[Alpha];
  Result[Beta] := Self.Recipe.Percents[Beta];
  Result[Gamma] := Self.Recipe.Percents[Gamma];
  Result[Biomass] := 0;
end;


{ TWorldUpscaler }

constructor TWorldUpscaler.Create(aEnvironment: TSimEnvironment; aParams: TSimParams);
begin
  inherited Create;
  Environment := aEnvironment;
  Params := aParams;
end;

function TWorldUpscaler.ResourceGrowthRate(aBiomeRating, aFoodRating: TRating): Single;
const
  BIOME_WEIGHT = 0.45;
  FOOD_WEIGHT = 0.55;
  BAD_SYNERGY = 0.60;
  JITTER_MAX_PERCENT = 0.08;
  MIN_RATE = 0.05;
  MAX_RATE = 2.00;
var
  biomeFactor: Single;
  foodFactor: Single;
  combined: Single;
  biomeDeficit: Single;
  foodDeficit: Single;
  jitterMultiplier: Single;
begin
  biomeFactor := GROWTH_FACTOR[aBiomeRating];
  foodFactor := GROWTH_FACTOR[aFoodRating];

  combined := Exp((BIOME_WEIGHT * Ln(biomeFactor)) + (FOOD_WEIGHT * Ln(foodFactor)));

  if (biomeFactor < 1.0) and (foodFactor < 1.0) then
  begin
    biomeDeficit := 1.0 - biomeFactor;
    foodDeficit := 1.0 - foodFactor;
    combined := combined * (1.0 - (BAD_SYNERGY * biomeDeficit * foodDeficit));
  end;

  jitterMultiplier := 1.0 + ((Random * 2.0 - 1.0) * JITTER_MAX_PERCENT);
  combined := combined * jitterMultiplier;

  Result := EnsureRange(combined, MIN_RATE, MAX_RATE);
end;

procedure TWorldUpscaler.UpscaleWorld(aLayout: TWorldLayout);

  function CacheOccupancyChance(const aBiome: TBiome): Single;
  begin
    Result := EnsureRange(CAPACITY_DENSITY_FACTOR[aBiome.Capacity], 0.0, 1.0);
  end;

  function ShouldPlaceCache(const aBiome: TBiome): Boolean;
  begin
    Result := Random < CacheOccupancyChance(aBiome);
  end;

begin
  if not Assigned(aLayout) then
    raise EArgumentNilException.Create('World layout is required.');

  if Params.Factor <= 0 then
    raise EArgumentOutOfRangeException.Create('Scale factor must be greater than zero.');

  var sourceSize := aLayout.Dimensions;
  var simSize := sourceSize;
  simSize.cx := simSize.cx * Params.Factor;
  simSize.cy := simSize.cy * Params.Factor;

  Environment.SetSubstanceCount(aLayout.Foods.Count);
  for var subIndex := 0 to aLayout.Foods.Count - 1 do
    Environment.SetSubstance(subIndex, aLayout.Foods[subIndex].ToSubstance);

  Environment.SetDimensions(simSize);

  RequiredResourceCount := 0;
  for var cellY := 0 to simSize.cy - 1 do
  begin
    for var cellX := 0 to simSize.cx - 1 do
    begin
      var sourceX := cellX div Params.Factor;
      var sourceY := cellY div Params.Factor;
      var sourceCellIndex := (sourceY * sourceSize.cx) + sourceX;

      var biomeIndex := aLayout.Cells[sourceCellIndex];
      Inc(RequiredResourceCount, Length(aLayout.BiomeFoodIndexes[biomeIndex]));
    end;
  end;

  Environment.SetResourceCount(RequiredResourceCount);

  var resourceWriteIndex := 0;
  for var cellY := 0 to simSize.cy - 1 do
  begin
    for var cellX := 0 to simSize.cx - 1 do
    begin
      var cellIndex := (cellY * simSize.cx) + cellX;

      var sourceX := cellX div Params.Factor;
      var sourceY := cellY div Params.Factor;
      var sourceCellIndex := (sourceY * sourceSize.cx) + sourceX;

      var biomeIndex := aLayout.Cells[sourceCellIndex];
      var biome := aLayout.Biomes[biomeIndex];

      if resourceWriteIndex > High(Word) then
        raise ERangeError.Create('ResourceStart exceeds TCell.Word range.');

      Environment.Cells[cellIndex].Sunlight := SUNLIGHT_FACTOR[biome.Sunlight];
      Environment.Cells[cellIndex].Mobility := MOBILITY_COST_PENALTY[biome.Mobility];
      Environment.Cells[cellIndex].ResourceStart := resourceWriteIndex;
      Environment.Cells[cellIndex].ResourceCount := 0;

      var biomeFoods := aLayout.BiomeFoodIndexes[biomeIndex];
      for var i := 0 to Length(biomeFoods) - 1 do
      begin
        if not ShouldPlaceCache(biome) then
          Continue;

        var resIndex := resourceWriteIndex;
        var foodIndex := biomeFoods[i];

        Environment.Resources[resIndex].SubstanceIndex := foodIndex;
        Environment.Resources[resIndex].Amount := 0.0;
        Environment.Resources[resIndex].RegenDebt := 0.0;
        Environment.Resources[resIndex].GrowthRate :=
          ResourceGrowthRate(biome.GrowthRate, aLayout.Foods[foodIndex].GrowthRate);

        Inc(resourceWriteIndex);

        if Environment.Cells[cellIndex].ResourceCount = High(Word) then
          raise ERangeError.Create('ResourceCount exceeds TCell.Word range.');
        Inc(Environment.Cells[cellIndex].ResourceCount);
      end;
    end;
  end;

  RequiredResourceCount := resourceWriteIndex;
  Environment.SetResourceCount(RequiredResourceCount);
end;



{ TDebugUpscaler }

constructor TDebugUpscaler.Create(aEnvironment: TSimEnvironment;
  aDimensions: TSize; aSunlight, aMobility: TRating);
begin
  inherited Create;
  Environment := aEnvironment;
  ResourceIndex := 0;

  // create initial cells
  Environment.SetDimensions(aDimensions);

  for var cellY := 0 to aDimensions.cy - 1 do
  begin
    for var cellX := 0 to aDimensions.cx - 1 do
    begin
      var cellIndex := (cellY * aDimensions.cx) + cellX;
      Environment.Cells[cellIndex].Sunlight := SUNLIGHT_FACTOR[aSunlight];
      Environment.Cells[cellIndex].Mobility := MOBILITY_COST_PENALTY[aMobility];
      Environment.Cells[cellIndex].ResourceStart := 0;
      Environment.Cells[cellIndex].ResourceCount := 0;
    end;
  end;
end;

procedure TDebugUpscaler.SetFoods(const Foods: array of TFood);
begin
  Environment.SetSubstanceCount(Length(Foods));
  for var i := 0 to Length(Foods) - 1 do
  begin
    var food := Foods[i];
    Environment.SetSubstance(i, food.ToSubstance);
  end;
end;

procedure TDebugUpscaler.SetCellResourceCount(aCellX, aCellY, aCount: Integer);
begin
  var cellIndex := (aCellY * Environment.Dimensions.cx) + aCellX;
  Assert((cellIndex >= 0) and (cellIndex < Length(Environment.Cells)));
  Assert(aCount <= Length(Environment.Substances));

  // can only do this once
  Assert(Environment.Cells[cellIndex].ResourceCount = 0);

  // add resource slots
  Environment.Cells[cellIndex].ResourceStart := ResourceIndex;
  Environment.Cells[cellIndex].ResourceCount := aCount;

  Inc(ResourceIndex, aCount);
end;

procedure TDebugUpscaler.SetResource(aCellX, aCellY: Integer;
  aResourceIndex: Word; aSubstanceIndex: Integer; aGrowthRate: TRating);
begin
  var cellIndex := (aCellY * Environment.Dimensions.cx) + aCellX;
  Assert((cellIndex >= 0) and (cellIndex < Length(Environment.Cells)));
  Assert(Environment.Cells[cellIndex].ResourceCount > 0);

  var index := Environment.Cells[cellIndex].ResourceStart + aResourceIndex;
  Assert((index >= 0) and (index < Environment.ResourceCount));

  Environment.Resources[index].SubstanceIndex := aSubstanceIndex;
  Environment.Resources[index].GrowthRate := GROWTH_FACTOR[aGrowthRate];
end;

procedure TDebugUpscaler.SetTotalResourceCount(aCount: Integer);
begin
  Environment.SetResourceCount(aCount);
  ResourceIndex := 0;
end;

end.
