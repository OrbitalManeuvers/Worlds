unit u_SimUpscalers;

interface

uses System.Classes, System.Generics.Collections,
  u_Regions, u_EnvironmentTypes, u_EnvironmentLibraries,
  u_Biomes, u_Foods,
  u_SimParams, u_SimRuntimes, u_WorldLayouts;

type
  TSimUpscaler = class
  private
    Params: TSimParams;
    Runtime: TSimRuntime;
    BiomeMappingOrder: TList<TBiome>;
    FoodMappingOrder: TList<TFood>;
    ReportLines: TStrings;
    BiomeList: TList<TBiome>;
    FoodList: TList<TFood>;
    RequiredResourceCount: Integer; // what the runtime will need space for
    procedure Log(const aMsg: string);
    function GetBiome(RunTimeIndex: Integer): TBiome;
    function GetBiomeCount: Integer;
    function GetFood(RuntimeIndex: Integer): TFood;
    function GetFoodCount: Integer;
    procedure GatherBiomeInfo(aRegion: TRegion; aLibrary: TEnvironmentLibrary);
    function ResourceGrowthRate(aBiomeRating, aFoodRating: TRating): Single;
  public
    constructor Create(aRuntime: TSimRuntime; aParams: TSimParams);
    destructor Destroy; override;

    procedure UpscaleRegion(aRegion: TRegion; aLibrary: TEnvironmentLibrary);

    property BiomeMapping: TList<TBiome> read BiomeMappingOrder;
    property FoodMapping: TList<TFood> read FoodMappingOrder;
    property ResourceCount: Integer read RequiredResourceCount;
    property Report: TStrings read ReportLines;

    // after upscaling, these are the biomes and foods that actually contributed
    // to the runtime image, and are listed in order of runtime index values.
    // Instrumentation should return indexes into these (hopefully)
    property BiomeCount: Integer read GetBiomeCount;
    property Biomes[RunTimeIndex: Integer]: TBiome read GetBiome;

    property FoodCount: Integer read GetFoodCount;
    property Foods[RuntimeIndex: Integer]: TFood read GetFood;

  end;

  TWorldUpscaler = class
  private
    Params: TSimParams;
    Runtime: TSimRuntime;
    RequiredResourceCount: Integer;
    function ResourceGrowthRate(aBiomeRating, aFoodRating: TRating): Single;
  public
    constructor Create(aRuntime: TSimRuntime; aParams: TSimParams);

    procedure UpscaleWorld(aLayout: TWorldLayout);

    property ResourceCount: Integer read RequiredResourceCount;
  end;


implementation

uses System.Types, System.Generics.Defaults, System.SysUtils, System.Math,
  u_EditorTypes, u_SimEnvironments, u_SimPopulations;

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



{ TSimUpscaler }
constructor TSimUpscaler.Create(aRuntime: TSimRuntime; aParams: TSimParams);
begin
  inherited Create;
  Runtime := aRuntime;
  Params := aParams;
  BiomeMappingOrder := TList<TBiome>.Create;
  FoodMappingOrder := TList<TFood>.Create;
  ReportLines := TStringList.Create(dupAccept, False, False);

  // biome list needs to be sorted by marker
  BiomeList := TList<TBiome>.Create(
    TComparer<TBiome>.Construct(
      function(const Left, Right: TBiome): Integer
      begin
        Result := Ord(Left.Marker) - Ord(Right.Marker);
      end
    )
  );

  // food list is not sorted, it's built in sim order
  FoodList := TList<TFood>.Create;
end;

destructor TSimUpscaler.Destroy;
begin
  FoodList.Free;
  BiomeList.Free;
  ReportLines.Free;
  FoodMappingOrder.Free;
  BiomeMappingOrder.Free;
  inherited;
end;

function TSimUpscaler.GetBiome(RunTimeIndex: Integer): TBiome;
begin
  Result := BiomeList[RunTimeIndex];
end;

function TSimUpscaler.GetBiomeCount: Integer;
begin
  Result := BiomeList.Count;
end;

function TSimUpscaler.GetFood(RuntimeIndex: Integer): TFood;
begin
  Result := FoodList[RuntimeIndex];
end;

function TSimUpscaler.GetFoodCount: Integer;
begin
  Result := FoodList.Count;
end;

procedure TSimUpscaler.Log(const aMsg: string);
begin
  ReportLines.Add(aMsg);
end;

procedure TSimUpscaler.GatherBiomeInfo(aRegion: TRegion; aLibrary: TEnvironmentLibrary);
type
  TBiomeUsage = record
    Biome: TBiome;
    Count: Integer;
  end;
var
  biomeUsage: array[TBiomeMarker] of TBiomeUsage;
begin
  FillChar(biomeUsage, SizeOf(biomeUsage), 0);

  // mark all the used biomes
  for var gridX := Low(TGridExtent) to High(TGridExtent) do
  begin
    for var gridY := Low(TGridExtent) to High(TGridExtent) do
    begin
      var marker := aRegion.BiomeMap[gridX, gridY];
      if biomeUsage[marker].Count = 0 then
      begin
        biomeUsage[marker].Biome := aLibrary.FindBiome(marker);
        biomeUsage[marker].Count := 1;
      end
      else
        Inc(biomeUsage[marker].Count);
    end;
  end;

  // reduce the biome list to just the used ones
  RequiredResourceCount := 0;
  for var marker := Low(TBiomeMarker) to High(TBiomeMarker) do
  begin
    var biome := biomeUsage[marker].Biome;
    if biome <> nil then
    begin
      BiomeList.Add(biome);
    end;
  end;

  BiomeList.Sort; // put biomes in marker order regardless of found order

  // this does not have to be super performant
  for var biome in BiomeList do
  begin
    for var food in biome.FoodList do  // via helper
    begin
      if FoodList.IndexOf(food) = -1 then  // idc as long as it works
      begin
        FoodList.Add(food);
      end;
    end;
  end;

  for var biomeIndex := 0 to BiomeList.Count - 1 do
  begin
    Log(biomeIndex.ToString + ': ' + BiomeList[biomeIndex].Name);

  end;
end;

function TSimUpscaler.ResourceGrowthRate(aBiomeRating, aFoodRating: TRating): Single;
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

  // Geometric blend keeps a multiplicative feel without extreme compounding.
  combined := Exp((BIOME_WEIGHT * Ln(biomeFactor)) + (FOOD_WEIGHT * Ln(foodFactor)));

  // Two below-average contributors get an extra bounded penalty.
  if (biomeFactor < 1.0) and (foodFactor < 1.0) then
  begin
    biomeDeficit := 1.0 - biomeFactor;
    foodDeficit := 1.0 - foodFactor;
    combined := combined * (1.0 - (BAD_SYNERGY * biomeDeficit * foodDeficit));
  end;

  // Small bounded per-resource variation. Seed control is expected upstream.
  jitterMultiplier := 1.0 + ((Random * 2.0 - 1.0) * JITTER_MAX_PERCENT);
  combined := combined * jitterMultiplier;

  Result := EnsureRange(combined, MIN_RATE, MAX_RATE);
end;

function EdgeFadeByDistance(aDistanceFromEdge: Integer): Single;
begin
  // 2-cell soft edge profile: border cell is sparse, next inward cell is reduced.
  case aDistanceFromEdge of
    0: Result := 0.15;
    1: Result := 0.50;
  else
    Result := 1.0;
  end;
end;

procedure TSimUpscaler.UpscaleRegion(aRegion: TRegion; aLibrary: TEnvironmentLibrary);

  function CacheOccupancyChance(const aBiome: TBiome; const aEdgeFactor: Single): Single;
  begin
    Result := EnsureRange(CAPACITY_DENSITY_FACTOR[aBiome.Capacity] * aEdgeFactor, 0.0, 1.0);
  end;

  function ShouldPlaceCache(const aBiome: TBiome; const aEdgeFactor: Single): Boolean;
  begin
    var roll := Random;
    Result := roll < CacheOccupancyChance(aBiome, aEdgeFactor);
  end;

  function ComputeEdgeFactor(const aSourceX, aSourceY, aLocalX, aLocalY: Integer;
    const aBiomeMarker: TBiomeMarker; const aSourceSize: TSize): Single;
  begin
    Result := 1.0;
    if Params.Factor <= 1 then
      Exit;

    // Preserve region boundaries for future stitching. Only soften interior biome boundaries.
    if (aSourceX > 0) and (aRegion.BiomeMap[aSourceX - 1, aSourceY] <> aBiomeMarker) then
      Result := Min(Result, EdgeFadeByDistance(aLocalX));

    if (aSourceX < aSourceSize.cx - 1) and (aRegion.BiomeMap[aSourceX + 1, aSourceY] <> aBiomeMarker) then
      Result := Min(Result, EdgeFadeByDistance((Params.Factor - 1) - aLocalX));

    if (aSourceY > 0) and (aRegion.BiomeMap[aSourceX, aSourceY - 1] <> aBiomeMarker) then
      Result := Min(Result, EdgeFadeByDistance(aLocalY));

    if (aSourceY < aSourceSize.cy - 1) and (aRegion.BiomeMap[aSourceX, aSourceY + 1] <> aBiomeMarker) then
      Result := Min(Result, EdgeFadeByDistance((Params.Factor - 1) - aLocalY));
  end;

  function InitialCacheAmount: Single;
  begin
    // Capacity is normalized to 1.0; initial fill is randomized across full range.
    Result := Runtime.Environment.ResourceCacheMaxAmount * Random;
  end;

begin

  // determine upscaled sim size
  var simSize := aRegion.BiomeMap.Size;
  simSize.cx := simSize.cx * Params.Factor;
  simSize.cy := simSize.cy * Params.Factor;

  // scan the region to extract the biome list we'll need
  GatherBiomeInfo(aRegion, aLibrary);

  // populate substances
  Runtime.Environment.SetSubstanceCount(FoodList.Count);
  for var subIndex := 0 to FoodList.Count - 1 do
    Runtime.Environment.SetSubstance(subIndex, FoodList[subIndex].ToSubstance);

  // set the sim runtime dimensions up front; resource count is determined by sparse placement pass
  Runtime.Environment.SetDimensions(simSize);
  Runtime.Environment.ResourceCacheMaxAmount := DEFAULT_RESOURCE_CACHE_MAX_AMOUNT;

  // need a lookup between the authored biomemap and the index of the biome in the dense list
  var markerToIndex := TDictionary<TBiomeMarker, Integer>.Create;
  var sourceSize := aRegion.BiomeMap.Size;
  try
    for var i := 0 to BiomeList.Count - 1 do
      markerToIndex.Add(BiomeList[i].Marker, i);

    // pass 1: compute worst-case resource slots (all food caches present)
    RequiredResourceCount := 0;
    for var cellY := 0 to simSize.cy - 1 do
    begin
      for var cellX := 0 to simSize.cx - 1 do
      begin
        var sourceX := cellX div Params.Factor;
        var sourceY := cellY div Params.Factor;

        var biomeMarker := aRegion.BiomeMap[sourceX, sourceY];
        var biomeIndex := markerToIndex[biomeMarker];
        var biome := BiomeList[biomeIndex];

        Inc(RequiredResourceCount, biome.FoodCount);
      end;
    end;

    Runtime.Environment.SetResourceCount(RequiredResourceCount);

    var resourceWriteIndex := 0; // current resource array index
    for var cellY := 0 to simSize.cy - 1 do
    begin
      for var cellX := 0 to simSize.cx - 1 do
      begin
        // linear index into cells
        var cellIndex := (cellY * simSize.cx) + cellX;

        // retrieve the biomeMarker from the region
        var sourceX := cellX div Params.Factor;
        var sourceY := cellY div Params.Factor;
        var localX := cellX mod Params.Factor;
        var localY := cellY mod Params.Factor;

        var biomeMarker := aRegion.BiomeMap[sourceX, sourceY];
        var biomeIndex := markerToIndex[biomeMarker];
        var biome := BiomeList[biomeIndex];

        var edgeFactor := ComputeEdgeFactor(sourceX, sourceY, localX, localY, biomeMarker, sourceSize);


        // this is not needed currently, or ever
        // Runtime.Environment.Cells[cellIndex].BiomeIndex := biomeIndex;

        // agent interaction params for the cell
        Runtime.Environment.Cells[cellIndex].Sunlight := SUNLIGHT_FACTOR[biome.Sunlight];
        Runtime.Environment.Cells[cellIndex].Mobility := MOBILITY_COST_PENALTY[biome.Mobility];

        Runtime.Environment.Cells[cellIndex].ResourceStart := resourceWriteIndex;
        Runtime.Environment.Cells[cellIndex].ResourceCount := 0;

        // set sparse cache topology + cache state for this cell
        for var foodIndex := 0 to biome.FoodCount - 1 do
        begin
          if not ShouldPlaceCache(biome, edgeFactor) then
            Continue;

          var resIndex := resourceWriteIndex;

          // the foodList and the substances are in the same order
          Runtime.Environment.Resources[resIndex].SubstanceIndex := FoodList.IndexOf(biome.Foods[foodIndex]);

          Runtime.Environment.Resources[resIndex].Amount := InitialCacheAmount;
          Runtime.Environment.Resources[resIndex].GrowthRate := ResourceGrowthRate(biome.GrowthRate, biome.Foods[foodIndex].GrowthRate) * edgeFactor;

          Inc(resourceWriteIndex);
          Inc(Runtime.Environment.Cells[cellIndex].ResourceCount);
        end;


      end; { grid for }

    end;
    // Trim to actual sparse cache count now that placement is finalized.
    RequiredResourceCount := resourceWriteIndex;
    Runtime.Environment.SetResourceCount(RequiredResourceCount);

  finally
    markerToIndex.Free;
  end;
end;

{ TWorldUpscaler }

constructor TWorldUpscaler.Create(aRuntime: TSimRuntime; aParams: TSimParams);
begin
  inherited Create;
  Runtime := aRuntime;
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

  function InitialCacheAmount: Single;
  begin
    Result := Runtime.Environment.ResourceCacheMaxAmount * Random;
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

  Runtime.Environment.SetSubstanceCount(aLayout.Foods.Count);
  for var subIndex := 0 to aLayout.Foods.Count - 1 do
    Runtime.Environment.SetSubstance(subIndex, aLayout.Foods[subIndex].ToSubstance);

  Runtime.Environment.SetDimensions(simSize);
  Runtime.Environment.ResourceCacheMaxAmount := DEFAULT_RESOURCE_CACHE_MAX_AMOUNT;

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

  Runtime.Environment.SetResourceCount(RequiredResourceCount);

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

      Runtime.Environment.Cells[cellIndex].Sunlight := SUNLIGHT_FACTOR[biome.Sunlight];
      Runtime.Environment.Cells[cellIndex].Mobility := MOBILITY_COST_PENALTY[biome.Mobility];
      Runtime.Environment.Cells[cellIndex].ResourceStart := resourceWriteIndex;
      Runtime.Environment.Cells[cellIndex].ResourceCount := 0;

      var biomeFoods := aLayout.BiomeFoodIndexes[biomeIndex];
      for var i := 0 to Length(biomeFoods) - 1 do
      begin
        if not ShouldPlaceCache(biome) then
          Continue;

        var resIndex := resourceWriteIndex;
        var foodIndex := biomeFoods[i];

        Runtime.Environment.Resources[resIndex].SubstanceIndex := foodIndex;
        Runtime.Environment.Resources[resIndex].Amount := InitialCacheAmount;
        Runtime.Environment.Resources[resIndex].GrowthRate :=
          ResourceGrowthRate(biome.GrowthRate, aLayout.Foods[foodIndex].GrowthRate);

        Inc(resourceWriteIndex);

        if Runtime.Environment.Cells[cellIndex].ResourceCount = High(Word) then
          raise ERangeError.Create('ResourceCount exceeds TCell.Word range.');
        Inc(Runtime.Environment.Cells[cellIndex].ResourceCount);
      end;
    end;
  end;

  RequiredResourceCount := resourceWriteIndex;
  Runtime.Environment.SetResourceCount(RequiredResourceCount);
end;



end.
