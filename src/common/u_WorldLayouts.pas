unit u_WorldLayouts;

interface

uses System.Types, System.Generics.Collections,
  u_EnvironmentLibraries, u_EnvironmentTypes, u_EditorTypes,
  u_Worlds, u_Regions, u_Biomes, u_Foods;

type
  TBiomeIndex = Byte;
  TFoodIndex = Word;
  TBiomeArray = array of TBiomeIndex; // index into Biomes[]
  TFoodIndexArray = array of TFoodIndex;
  TBiomeFoodIndexArray = array of TFoodIndexArray;

  TWorldLayout = class
  private
    fWorld: TWorld;
    fLibrary: TEnvironmentLibrary;
    fDimensions: TSize;
    fCells: TBiomeArray;
    fBiomes: TList<TBiome>;
    fFoods: TList<TFood>;
    fBiomeMapping: TDictionary<TBiomeMarker, TBiomeIndex>;
    fFoodMapping: TDictionary<TFood, TFoodIndex>;
    fBiomeFoods: TBiomeFoodIndexArray;
    procedure Layout;
    procedure BuildFoodMappings;
    procedure ProcessRegion(aIndex: Integer);
    function MarkerToIndex(aMarker: TBiomeMarker): TBiomeIndex;
    function FoodToIndex(aFood: TFood): TFoodIndex;
  public
    constructor Create(aWorld: TWorld; aLibrary: TEnvironmentLibrary);
    destructor Destroy; override;

    property Dimensions: TSize read fDimensions;
    property Cells: TBiomeArray read fCells;
    property Biomes: TList<TBiome> read fBiomes;
    property Foods: TList<TFood> read fFoods;
    property BiomeFoodIndexes: TBiomeFoodIndexArray read fBiomeFoods;
  end;


implementation

uses System.SysUtils;

const
  REGION_COUNTS: array[TRegionLayout] of TSize = (
    { wlSingle }     (cx:1; cy:1),
    { wlNorthSouth } (cx:1; cy:2),
    { wlWestEast }   (cx:2; cy:1),
    { wlSquare }     (cx:2; cy:2)
  );

  WORLD_OFFSETS: array[1..4] of TPoint = (
    (x:0;  y:0),
    (x:BIOME_GRID_SIZE; y:0),
    (x:0;  y:BIOME_GRID_SIZE),
    (x:BIOME_GRID_SIZE; y:BIOME_GRID_SIZE)
  );

{ TWorldLayout }

constructor TWorldLayout.Create(aWorld: TWorld; aLibrary: TEnvironmentLibrary);
begin
  inherited Create;
  fWorld := aWorld;
  fLibrary := aLibrary;

  fBiomes := TList<TBiome>.Create;
  fFoods := TList<TFood>.Create;
  fBiomeMapping := TDictionary<TBiomeMarker, TBiomeIndex>.Create;
  fFoodMapping := TDictionary<TFood, TFoodIndex>.Create;

  Layout;
end;

destructor TWorldLayout.Destroy;
begin
  fFoodMapping.Free;
  fBiomeMapping.Free;
  fFoods.Free;
  fBiomes.Free;
  inherited;
end;

procedure TWorldLayout.Layout;
begin

  // the size of the world is determined from the .layout property
  fDimensions := REGION_COUNTS[fWorld.Layout];
  fDimensions.cx := fDimensions.cx * BIOME_GRID_SIZE;
  fDimensions.cy := fDimensions.cy * BIOME_GRID_SIZE;
  SetLength(fCells, fDimensions.cx * fDimensions.cy);

  // Concept:
  // The world map given to the upscaler should contain indices into a dense list of biomes, instead
  // of the authoring value of biomeMarker (biome id).

  case fWorld.Layout of
    rlSingle:
      begin
        ProcessRegion(1);
      end;

    rlNorthSouth:
      begin
        ProcessRegion(1);
        ProcessRegion(3);
      end;

    rlWestEast:
      begin
        ProcessRegion(1);
        ProcessRegion(2);
      end;

    rlSquare:
      begin
        for var i := 1 to 4 do
          ProcessRegion(i);
      end;
  end;

  // build list of foods. each biome
  BuildFoodMappings;


end;

procedure TWorldLayout.BuildFoodMappings;
begin
  SetLength(fBiomeFoods, fBiomes.Count);

  for var biomeIndex := 0 to fBiomes.Count - 1 do
  begin
    var biome := fBiomes[biomeIndex];
    SetLength(fBiomeFoods[biomeIndex], biome.FoodCount);

    for var i := 0 to biome.FoodCount - 1 do
      fBiomeFoods[biomeIndex][i] := FoodToIndex(biome.Foods[i]);
  end;
end;

function TWorldLayout.FoodToIndex(aFood: TFood): TFoodIndex;
begin
  if fFoodMapping.TryGetValue(aFood, Result) then
    Exit;

  if fFoods.Count > High(TFoodIndex) then
    raise ERangeError.Create('Exceeded max supported food count for TFoodIndex.');

  Result := fFoods.Count;
  fFoods.Add(aFood);
  fFoodMapping.Add(aFood, Result);


end;

function TWorldLayout.MarkerToIndex(aMarker: TBiomeMarker): TBiomeIndex;
begin
  var biomeIndex: TBiomeIndex;

  // if this biome is already known, return its index value, else record it
  // and create its index value
  if fBiomeMapping.TryGetValue(aMarker, biomeIndex) then
  begin
    Result := biomeIndex;
  end
  else
  begin
    var biome := fLibrary.FindBiome(aMarker);
    if biome = nil then
      raise EArgumentException.CreateFmt('Biome marker %d not found in library.', [Ord(aMarker)]);

    if fBiomes.Count > High(TBiomeIndex) then
      raise ERangeError.Create('Exceeded max supported biome count for TBiomeIndex.');

    Result := fBiomes.Count;
    fBiomes.Add(biome);
    fBiomeMapping.Add(aMarker, Result);
  end;
end;

procedure TWorldLayout.ProcessRegion(aIndex: Integer);
begin
  if not Assigned(fWorld.Regions[aIndex]) then
    Exit;

  // As a biomeMarker is encountered, if it doesn't exist in the dictionary,
  // the biome should be looked up, and added to the dense biomeList, and its index in that
  // list becomes the world map cell value

  var region := fWorld.Regions[aIndex];

  for var regionY := 0 to BIOME_GRID_SIZE - 1 do  // consider TGridExtent
  begin
    for var regionX := 0 to BIOME_GRID_SIZE - 1 do
    begin
      var biomeMarker := region.BiomeMap[regionX, regionY];
      var biomeIndex := MarkerToIndex(biomeMarker);

      var worldCursor := Point(regionX + WORLD_OFFSETS[aIndex].X, regionY + WORLD_OFFSETS[aIndex].Y);
      var worldIndex := (worldCursor.Y * fDimensions.cx) + worldCursor.X;
      fCells[worldIndex] := biomeIndex;
    end;

  end;

end;

end.
