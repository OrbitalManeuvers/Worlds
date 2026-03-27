unit u_Serialization;

interface

uses
  u_EnvironmentLibraries;

type
  TSerializer = class
    class procedure SaveLibrary(aLibrary: TEnvironmentLibrary; const aFileName: string);
    class procedure LoadLibrary(aLibrary: TEnvironmentLibrary; const aFileName: string);
  end;

implementation

uses System.JSON, System.IOUtils,  System.SysUtils, Vcl.Graphics, Vcl.GraphUtil,
  System.Generics.Collections,

  u_EnvironmentTypes, u_EditorTypes, u_BiologyTypes,
  u_Foods, u_Biomes, u_Regions, u_Worlds;


const
  KEY_NAME = 'name';
  KEY_DESCRIPTION = 'description';

  KEY_MOLECULE = 'molecule';
  KEY_PERCENT = 'percent';
  KEY_RECIPE = 'recipe';

  KEY_MARKER = 'marker';
  KEY_COLOR = 'color';
  KEY_BIOME_GRID = 'biomeGrid';

  KEY_GROWTH_RATE = 'growthRate';
  KEY_CAPACITY = 'capacity';
  KEY_SUNLIGHT = 'sunlight';
  KEY_MOBILITY = 'mobility';

  KEY_ALPHA = 'alpha';
  KEY_BETA = 'beta';
  KEY_GAMMA = 'gamma';
  KEY_BIOMASS = 'biomass';

  KEY_LAYOUT = 'layout';

  KEY_FOODS = 'foods';
  KEY_BIOMES = 'biomes';
  KEY_REGIONS = 'regions';
  KEY_RATINGS = 'ratings';
  KEY_WORLDS = 'worlds';

  REGION_LAYOUT_STRS: array[TRegionLayout] of string = ('Single', 'NorthSouth', 'WestEast', 'Square');

type
  TLibraryHelper = class helper for TEnvironmentLibrary
  private
    function getJSON: TJSONObject;
    procedure setJSON(const Value: TJSONObject);

    procedure LoadFoods(const JSON: TJSONObject);
    procedure LoadBiomes(const JSON: TJSONObject);
    procedure LoadRegions(const JSON: TJSONObject);
    procedure LoadRatings(const JSON: TJSONObject);
    procedure LoadWorlds(const JSON: TJSONObject);

    procedure SaveFoods(const JSON: TJSONObject);
    procedure SaveBiomes(const JSON: TJSONObject);
    procedure SaveRegions(const JSON: TJSONObject);
    procedure SaveRatings(const JSON: TJSONObject);
    procedure SaveWorlds(const JSON: TJSONObject);
  public
    property AsJSON: TJSONObject read getJSON write setJSON;
  end;

  TFoodHelper = class helper for TFood
  private
    function getJSON: TJSONObject;
    procedure setJSON(const Value: TJSONObject);
  public
    property AsJSON: TJSONObject read getJSON write setJSON;
  end;

  TRecipeHelper = class helper for TRecipe
  private
    function getJSON: TJSONObject;
    procedure setJSON(const Value: TJSONObject);
  public
    property AsJSON: TJSONObject read getJSON write setJSON;
  end;

  TBiomeHelper = class helper for TBiome
  private
    function getJSON: TJSONObject;
    procedure setJSON(const Value: TJSONObject);
  public
    property AsJSON: TJSONObject read getJSON write setJSON;
  end;

  TRegionHelper = class helper for TRegion
  private
    function getJSON: TJSONObject;
    procedure setJSON(const Value: TJSONObject);
  public
    property AsJSON: TJSONObject read getJSON write setJSON;
  end;

  TRatingsHelper = class helper for TMoleculeRatings
  private
    function getJSON: TJSONObject;
    procedure setJSON(const Value: TJSONObject);
  public
    property AsJSON: TJSONObject read getJSON write setJSON;
  end;

  TWorldHelper = class helper for TWorld
  private
    function getJSON: TJSONObject;
    procedure setJSON(const Value: TJSONObject);
  public
    property AsJSON: TJSONObject read getJSON write setJSON;
  end;


{ TSerializer }

class procedure TSerializer.LoadLibrary(aLibrary: TEnvironmentLibrary; const aFileName: string);
begin
  if not TFile.Exists(aFileName) then
  begin
    aLibrary.Clear;
    Exit;
  end;

  var json: TJSONObject := TJSONValue.ParseJSONValue(TFile.ReadAllText(aFileName)) as TJSONObject;
  if Assigned(json) then
  begin
    aLibrary.BeginUpdate;
    try
      aLibrary.AsJSON := json;
      aLibrary.Modified := False;
    finally
      aLibrary.EndUpdate;
    end;
  end;
end;

class procedure TSerializer.SaveLibrary(aLibrary: TEnvironmentLibrary; const aFileName: string);
begin
  var json := aLibrary.AsJSON;
  try
    TFile.WriteAllText(aFileName, json.Format(4));
  finally
    json.Free;
  end;
end;


{ TLibraryHelper }

function TLibraryHelper.getJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  // SaveHeader(Result); // someday
  SaveFoods(Result);
  SaveBiomes(Result);
  SaveRegions(Result);
  SaveRatings(Result);
  SaveWorlds(Result);
end;

procedure TLibraryHelper.setJSON(const Value: TJSONObject);
begin
//  LoadHeader(Value); // header/version info someday
  LoadFoods(Value);
  LoadBiomes(Value);
  LoadRegions(Value);
  LoadRatings(Value);
  LoadWorlds(Value);
end;


procedure TLibraryHelper.LoadBiomes(const JSON: TJSONObject);
var
  arr: TJSONArray;
begin
  if JSON.TryGetValue(KEY_BIOMES, arr) then
  begin
    for var item in arr do
    begin
      if item is TJSONObject then
      begin
        // check biome marker before creating a biome - remove after save tested to not write biome 0
        var arrObj := TJSONObject(item);
        var marker: TBiomeMarker;
        if arrObj.TryGetValue(KEY_MARKER, marker) and (marker = 0) then
          Continue;

        var biome := TBiome.Create;
        try
          biome.AsJSON := arrObj;

          // re-attach child objects
          var foodArr: TJSONArray;
          if item.TryGetValue(KEY_FOODS, foodArr) then
          begin
            for var foodItem in foodArr do
            begin
              var food := Self.FindFood(foodItem.Value);
              if Assigned(food) then
                biome.AddFood(food);
            end;
          end;

          biome.OnChange := ChildChanged;
          AddBiome(biome);
        except
          biome.Free;
          raise;
        end;
      end;
    end;
  end;
end;

procedure TLibraryHelper.LoadFoods(const JSON: TJSONObject);
var
  arr: TJSONArray;
begin
  if JSON.TryGetValue(KEY_FOODS, arr) then
  begin
    for var item in arr do
    begin
      if item is TJSONObject then
      begin
        var food := TFood.Create;
        try
          food.AsJSON := TJSONObject(item);
          food.OnChange := ChildChanged;
          AddFood(food);
        except
          food.Free;
          raise;
        end;
      end;
    end;
  end;
end;

procedure TLibraryHelper.LoadRatings(const JSON: TJSONObject);
var
  arr: TJSONArray;
begin
  if JSON.TryGetValue(KEY_RATINGS, arr) then
  begin
    for var item in arr do
    begin
      if item is TJSONObject then
      begin
        var rating := TMoleculeRatings.Create;
        try
          rating.AsJSON := TJSONObject(item);
          AddRatings(rating);
        except
          rating.Free;
          raise;
        end;
      end;
    end;
  end;
end;

procedure TLibraryHelper.LoadRegions(const JSON: TJSONObject);
var
  arr: TJSONArray;
begin
  if JSON.TryGetValue(KEY_REGIONS, arr) then
  begin
    for var item in arr do
      if item is TJSONObject then
      begin
        var region := TRegion.Create;
        try
          region.AsJson := TJSONObject(item);
          region.OnChange := ChildChanged;
          AddRegion(region);
        except
          region.Free;
          raise;
        end;
      end;
  end;
end;

procedure TLibraryHelper.LoadWorlds(const JSON: TJSONObject);
var
  arr: TJSONArray;
begin
  if JSON.TryGetValue(KEY_WORLDS, arr) then
  begin
    for var item in arr do
      if item is TJSONObject then
      begin
        var world := TWorld.Create;
        try
          world.AsJSON := TJSONObject(item);

          // re-attach child objects
          var regionArr: TJSONArray;
          if item.TryGetValue(KEY_REGIONS, regionArr) then
          begin
            var arrayIndex: Integer := 1;
            for var regionItem in regionArr do
            begin
              var region := Self.FindRegion(regionItem.Value);
              if Assigned(region) then
                world.Regions[arrayIndex] := region
              else
                world.Regions[arrayIndex] := nil;
              Inc(arrayIndex);
            end;
          end;

          world.OnChange := ChildChanged;
          AddWorld(world);

        except
          world.Free;
          raise;
        end;
      end;
  end;
end;


procedure TLibraryHelper.SaveBiomes(const JSON: TJSONObject);
var
  arr: TJSONArray;
begin
  arr := TJSONArray.Create;
  for var biome in _biomeList do
  begin
    if biome.Marker > 0 then
      arr.Add(biome.AsJSON);
  end;
  JSON.AddPair(KEY_BIOMES, arr);
end;

procedure TLibraryHelper.SaveFoods(const JSON: TJSONObject);
var
  arr: TJSONArray;
begin
  arr := TJSONArray.Create;
  for var food in _foodList do
  begin
    arr.Add(food.AsJSON);
  end;
  JSON.AddPair(KEY_FOODS, arr);
end;

procedure TLibraryHelper.SaveRegions(const JSON: TJSONObject);
var
  arr: TJSONArray;
begin
  arr := TJSONArray.Create;
  for var region in _regionList do
  begin
    arr.Add(region.AsJSON);
  end;
  JSON.AddPair(KEY_REGIONS, arr);
end;

procedure TLibraryHelper.SaveWorlds(const JSON: TJSONObject);
var
  arr: TJSONArray;
begin
  arr := TJSONArray.Create;
  for var world in _worldList do
  begin
    arr.Add(world.AsJSON);
  end;
  JSON.AddPair(KEY_WORLDS, arr);
end;

procedure TLibraryHelper.SaveRatings(const JSON: TJSONObject);
var
  arr: TJSONArray;
begin
  arr := TJSONArray.Create;
  for var rating in _ratingsList do
  begin
    arr.Add(rating.AsJSON);
  end;
  JSON.AddPair(KEY_RATINGS, arr);
end;


{ TFoodHelper }

function TFoodHelper.getJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair(KEY_NAME, Self.Name);
  Result.AddPair(KEY_GROWTH_RATE, Self.GrowthRate.AsText);
  Result.AddPair(KEY_RECIPE, Recipe.AsJSON);
end;

procedure TFoodHelper.setJSON(const Value: TJSONObject);
var
  sValue: string;
begin
  if Value.TryGetValue(KEY_NAME, sValue) then
    Name := sValue;
  if Value.TryGetValue(KEY_GROWTH_RATE, sValue) then
    GrowthRate.AsText := sValue;

  var jObject: TJSONObject;
  if Value.TryGetValue(KEY_RECIPE, jObject) then
    Recipe.AsJSON := jObject;
end;

{ TRecipeHelper }

function TRecipeHelper.getJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  for var gm := Low(TGrowableMolecule) to High(TGrowableMolecule) do
    Result.AddPair(MoleculeToStr(gm), Percents[gm]);
end;

procedure TRecipeHelper.setJSON(const Value: TJSONObject);
begin
  var pair: TJSONPair;
  for pair in Value do
  begin
    var m: TMolecule;
    if StrToMolecule(pair.JsonString.Value, m) then
    begin
      var percent := 0;
      if pair.JsonValue is TJSONNumber then
        percent := TJSONNumber(pair.JSONValue).AsInt;
      Self.Percents[m] := percent;
    end;
  end;
end;

{ TBiomeHelper }

function TBiomeHelper.getJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair(KEY_NAME, Name);
  Result.AddPair(KEY_DESCRIPTION, Description);
  Result.AddPair(KEY_MARKER, Integer(Marker));
  Result.AddPair(KEY_COLOR, ColorToWebColorStr(Color));

  Result.AddPair(KEY_GROWTH_RATE, GrowthRate.AsText);
  Result.AddPair(KEY_CAPACITY, Capacity.AsText);
  Result.AddPair(KEY_SUNLIGHT, Sunlight.AsText);
  Result.AddPair(KEY_MOBILITY, Mobility.AsText);

  var arr := TJSONArray.Create;
  for var i := 0 to FoodCount - 1 do
    arr.Add(Foods[i].Name);
  Result.AddPair(KEY_FOODS, arr);
end;

procedure TBiomeHelper.setJSON(const Value: TJSONObject);
var
  strVal: string;
  intVal: Integer;
begin
  if Value.TryGetValue(KEY_NAME, strVal) then
    Name := strVal;
  if Value.TryGetValue(KEY_DESCRIPTION, strVal) then
    Description := strVal;
  if Value.TryGetValue(KEY_MARKER, intVal) then
    Marker := intVal;
  if Value.TryGetValue(KEY_COLOR, strVal) then
    Color := WebColorStrToColor(strVal);

  if Value.TryGetValue(KEY_GROWTH_RATE, strVal) then
    GrowthRate.AsText := strVal;
  if Value.TryGetValue(KEY_CAPACITY, strVal) then
    Capacity.AsText := strVal;
  if Value.TryGetValue(KEY_SUNLIGHT, strVal) then
    Sunlight.AsText := strVal;
  if Value.TryGetValue(KEY_MOBILITY, strVal) then
    Mobility.AsText := strVal;
end;

{ TRegionHelper }

function TRegionHelper.getJSON: TJSONObject;
var
  rows: TJSONArray;
  rowText: string;
begin
  Result := TJSONObject.Create;
  Result.AddPair(KEY_NAME, Name);
  Result.AddPair(KEY_DESCRIPTION, Description);

  rows := TJSONArray.Create;
  for var y := Low(TGridExtent) to High(TGridExtent) do
  begin
    rowText := '';
    for var x := Low(TGridExtent) to High(TGridExtent) do
      rowText := rowText + BiomeMap[x, y].ToHexString(2);
    rows.Add(rowText);
  end;

  Result.AddPair(KEY_BIOME_GRID, rows);
end;

procedure TRegionHelper.setJSON(const Value: TJSONObject);
var
  sValue: string;
  jValue: TJSONValue;
  rows: TJSONArray;
  rowText: string;
begin
  if Value.TryGetValue(KEY_NAME, sValue) then
    Name := sValue;
  if Value.TryGetValue(KEY_DESCRIPTION, sValue) then
    Description := sValue;

  if Value.TryGetValue(KEY_BIOME_GRID, jValue) and (jValue is TJSONArray) then
  begin
    rows := TJSONArray(jValue);
    for var y := Low(TGridExtent) to High(TGridExtent) do
    begin
      rowText := rows.Items[y].Value;
      for var x := Low(TGridExtent) to High(TGridExtent) do
        BiomeMap[x, y] := StrToIntDef('$' + Copy(rowText, (x * 2) + 1, 2), 0);
    end;
  end;
end;


{ TRatingsHelper }

function TRatingsHelper.getJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair(KEY_NAME, Name);
  Result.AddPair(KEY_DESCRIPTION, Description);
  Result.AddPair(KEY_ALPHA, Ratings[Alpha].AsText);
  Result.AddPair(KEY_BETA, Ratings[Beta].AsText);
  Result.AddPair(KEY_GAMMA, Ratings[Gamma].AsText);
  Result.AddPair(KEY_BIOMASS, Ratings[Biomass].AsText);
end;

procedure TRatingsHelper.setJSON(const Value: TJSONObject);
var
  strVal: string;
  rating: TRating;
begin
  if Value.TryGetValue(KEY_NAME, strVal) then
    Name := strVal;
  if Value.TryGetValue(KEY_DESCRIPTION, strVal) then
    Description := strVal;
  if Value.TryGetValue(KEY_ALPHA, strVal) then
  begin
    rating.AsText := strVal;
    Ratings[Alpha] := rating;
  end;
  if Value.TryGetValue(KEY_BETA, strVal) then
  begin
    rating.AsText := strVal;
    Ratings[Beta] := rating;
  end;
  if Value.TryGetValue(KEY_GAMMA, strVal) then
  begin
    rating.AsText := strVal;
    Ratings[Gamma] := rating;
  end;
  if Value.TryGetValue(KEY_BIOMASS, strVal) then
  begin
    rating.AsText := strVal;
    Ratings[Biomass] := rating;
  end;
  Modified := False;
end;

{ TWorldHelper }

function TWorldHelper.getJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair(KEY_NAME, Name);
  Result.AddPair(KEY_DESCRIPTION, Description);
  Result.AddPair(KEY_LAYOUT, REGION_LAYOUT_STRS[Layout]);

  var arr := TJSONArray.Create;
  for var i := 1 to 4 do
  begin
    var regionName: string;
    if Assigned(Regions[i]) then
      regionName := Regions[i].Name
    else
      regionName := '';
    arr.Add(regionName);
  end;

  Result.AddPair(KEY_REGIONS, arr);
end;

procedure TWorldHelper.setJSON(const Value: TJSONObject);
var
  strVal: string;
begin
  if Value.TryGetValue(KEY_NAME, strVal) then
    Name := strVal;
  if Value.TryGetValue(KEY_DESCRIPTION, strVal) then
    Description := strVal;
  if Value.TryGetValue(KEY_LAYOUT, strVal) then
  begin
    for var l := Low(TRegionLayout) to High(TRegionLayout) do
      if SameText(REGION_LAYOUT_STRS[l], strVal) then
      begin
        Self.Layout := l;
        Break;
      end;
  end;

end;

end.
