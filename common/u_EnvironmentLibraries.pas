unit u_EnvironmentLibraries;

interface

uses System.Classes, System.SysUtils, System.JSON, System.Generics.Collections,

  u_EditorObjects,
  u_Worlds.Types,
  u_Environment.Types,
  u_Foods,
  u_Biomes,
  u_Regions;

type
  TEnvironmentLibrary = class(TEditorObject)
  private
    fFoods: TObjectList<TFood>;
    fBiomes: TObjectList<TBiome>;
    fRegions: TObjectList<TRegion>;
  private
    // foods
    function GetFood(I: Integer): TFood;
    function GetFoodCount: Integer;
    procedure LoadFoods(const container: TJSONObject);
    procedure SaveFoods(const container: TJSONObject);

    // biomes
    procedure LoadBiomes(const container: TJSONObject);
    procedure SaveBiomes(const container: TJSONObject);

    // regions
    procedure LoadRegions(const container: TJSONObject);
    procedure SaveRegions(const container: TJSONObject);
    function GetBiome(I: Integer): TBiome;
    function GetBiomeCount: Integer;
    function GetRegion(I: Integer): TRegion;
    function GetRegionCount: Integer;

  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromFile(const aFileName: string);
    procedure SaveToFile(const aFileName: string);

    // foods
    procedure AddFood(aFood: TFood);
    function FindFood(const aName: string): TFood;
    property FoodCount: Integer read GetFoodCount;
    property Foods[I: Integer]: TFood read GetFood;

    // biomes
    procedure AddBiome(aBiome: TBiome);
    property BiomeCount: Integer read GetBiomeCount;
    property Biomes[I: Integer]: TBiome read GetBiome;

    // regions
    procedure AddRegion(aRegion: TRegion);
    property RegionCount: Integer read GetRegionCount;
    property Regions[I: Integer]: TRegion read GetRegion;

    //
    procedure UpdateBiomeColorPalette(var aPalette: TBiomeColorPalette);

  end;

var
  WorldLibrary: TEnvironmentLibrary = nil;

implementation

uses System.IOUtils, Vcl.Graphics,
  u_Foods.JSON,
  u_Biomes.JSON,
  u_Regions.JSON;

const
  KEY_FOODS = 'foods';
  KEY_BIOMES = 'biomes';
  KEY_REGIONS = 'regions';


{ TEnvironmentLibrary }

constructor TEnvironmentLibrary.Create;
begin
  inherited Create;
  fFoods := TObjectList<TFood>.Create(True);
  fBiomes := TObjectList<TBiome>.Create(True);
  fRegions := TObjectList<TRegion>.Create(True);
end;

destructor TEnvironmentLibrary.Destroy;
begin
  fRegions.Free;
  fBiomes.Free;
  fFoods.Free;
  inherited;
end;

{$region 'Load/Save'}
procedure TEnvironmentLibrary.LoadFoods(const container: TJSONObject);
var
  arr: TJSONArray;
begin
  if container.TryGetValue(KEY_FOODS, arr) then
  begin
    for var item in arr do
      if item is TJSONObject then
      begin
        var food := TFood.Create;
        try
          food.AsJSON := TJSONObject(item);
          food.OnChange := ChildChanged;
          fFoods.Add(food);
        except
          food.Free;
          raise;
        end;
      end;
  end;
end;

procedure TEnvironmentLibrary.LoadBiomes(const container: TJSONObject);
var
  arr: TJSONArray;
begin
  if container.TryGetValue(KEY_BIOMES, arr) then
  begin
    for var item in arr do
      if item is TJSONObject then
      begin
        var biome := TBiome.Create;
        try
          biome.AsJSON := TJSONObject(item);
          biome.OnChange := ChildChanged;
          fBiomes.Add(biome);
        except
          biome.Free;
          raise;
        end;
      end;
  end;
end;

procedure TEnvironmentLibrary.LoadRegions(const container: TJSONObject);
var
  arr: TJSONArray;
begin
  if container.TryGetValue(KEY_REGIONS, arr) then
  begin
    for var item in arr do
      if item is TJSONObject then
      begin
        var region := TRegion.Create;
        try
          region.AsJSON := TJSONObject(item);
          region.OnChange := ChildChanged;
          fRegions.Add(region);
        except
          region.Free;
          raise;
        end;
      end;
  end;
end;

procedure TEnvironmentLibrary.LoadFromFile(const aFileName: string);
var
  json: TJSONObject;
begin
  if TFile.Exists(aFileName) then
  begin
    BeginUpdate;
    try
      fFoods.Clear;
      fBiomes.Clear;
      fRegions.Clear;

      json := TJSONValue.ParseJSONValue(TFile.ReadAllText(aFileName)) as TJSONObject;
      if Assigned(json) then
      begin
        LoadFoods(json);
        LoadBiomes(json);
        LoadRegions(json);
      end;

      Modified := False;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TEnvironmentLibrary.SaveBiomes(const container: TJSONObject);
var
  arr: TJSONArray;
begin
  arr := TJSONArray.Create;
  for var biome in fBiomes do
    arr.AddElement(biome.AsJSON);
  container.AddPair(KEY_BIOMES, arr);
end;

procedure TEnvironmentLibrary.SaveFoods(const container: TJSONObject);
var
  arr: TJSONArray;
begin
  arr := TJSONArray.Create;
  for var food in fFoods do
    arr.AddElement(food.AsJSON);
  container.AddPair(KEY_FOODS, arr);
end;

procedure TEnvironmentLibrary.SaveRegions(const container: TJSONObject);
var
  arr: TJSONArray;
begin
  arr := TJSONArray.Create;
  for var region in fRegions do
    arr.AddElement(region.AsJSON);
  container.AddPair(KEY_REGIONS, arr);
end;

procedure TEnvironmentLibrary.SaveToFile(const aFileName: string);
var
  json: TJSONObject;
begin
  json := TJSONObject.Create;
  try
    SaveFoods(json);
    SaveBiomes(json);
    SaveRegions(json);
    TFile.WriteAllText(aFileName, json.Format(4));
  finally
    json.Free;
  end;
end;

procedure TEnvironmentLibrary.UpdateBiomeColorPalette(var aPalette: TBiomeColorPalette);
begin
  for var i := Low(TBiomeMarker) to High(TBiomeMarker) do
    aPalette[i] := clBlack;
  for var biome in fBiomes do
    aPalette[biome.Marker] := biome.Color;
end;

{$endregion}


{$region 'Utility Methods'}
procedure TEnvironmentLibrary.AddBiome(aBiome: TBiome);
begin
  // !! markers need to be permanent
  var nextMarker := Succ(Low(TBiomeMarker));
  for var b in fBiomes do
    if (b.Marker >= nextMarker) and (b.Marker < Pred(High(TBiomeMarker))) then  // !! edge case
      nextMarker := Succ(b.Marker);

  aBiome.Marker := nextMarker;
  aBiome.OnChange := ChildChanged;
  fBiomes.Add(aBiome);
  Changed;
end;

procedure TEnvironmentLibrary.AddFood(aFood: TFood);
begin
  aFood.OnChange := ChildChanged;
  fFoods.Add(aFood);
  Changed;
end;

procedure TEnvironmentLibrary.AddRegion(aRegion: TRegion);
begin
  aRegion.OnChange := ChildChanged;
  fRegions.Add(aRegion);
  Changed;
end;

function TEnvironmentLibrary.FindFood(const aName: string): TFood;
var
  Food: TFood;
begin
  Result := nil;
  for Food in fFoods do
    if SameText(Food.Name, aName) then
      Exit(Food);
end;
{$endregion}

{$region 'Property Access'}

function TEnvironmentLibrary.GetBiome(I: Integer): TBiome;
begin
  Result := fBiomes[I];
end;

function TEnvironmentLibrary.GetBiomeCount: Integer;
begin
  Result := fBiomes.Count;
end;

function TEnvironmentLibrary.GetFood(I: Integer): TFood;
begin
  Result := fFoods[I];
end;

function TEnvironmentLibrary.GetFoodCount: Integer;
begin
  Result := fFoods.Count;
end;

function TEnvironmentLibrary.GetRegion(I: Integer): TRegion;
begin
  Result := fRegions[I];
end;

function TEnvironmentLibrary.GetRegionCount: Integer;
begin
  Result := fRegions.Count;
end;

{$endregion}

end.
