unit u_EnvironmentLibraries;

interface

uses System.Classes, System.SysUtils, System.JSON, System.Generics.Collections,

  u_Worlds.Types,
  u_Environment.Types,
  u_Foods,
  u_Biomes;

type
  TEnvironmentLibrary = class
  private
    fFoods: TObjectList<TFood>;
    fBiomes: TObjectList<TBiome>;
  private
    // foods
    function GetFood(I: Integer): TFood;
    function GetFoodCount: Integer;
    procedure LoadFoods(const container: TJSONObject);

    // biomes
    procedure LoadBiomes(const container: TJSONObject);

    // regions
    procedure LoadRegions(const container: TJSONObject);
    function GetBiome(I: Integer): TBiome;
    function GetBiomeCount: Integer;

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
    property BiomeCount: Integer read GetBiomeCount;
    property Biomes[I: Integer]: TBiome read GetBiome;

    // regions

  end;

procedure InitGlobalLibrary;
procedure DoneGlobalLibrary;
function GlobalLibrary: TEnvironmentLibrary;

implementation

uses System.IOUtils,
  u_Foods.JSON,
  u_Biomes.JSON;

const
  KEY_FOODS = 'foods';
  KEY_BIOMES = 'biomes';
  KEY_REGIONS = 'regions';

var
  _globalLibrary: TEnvironmentLibrary = nil;

procedure InitGlobalLibrary;
begin
  if not Assigned(_globalLibrary) then
    _globalLibrary := TEnvironmentLibrary.Create;
end;

procedure DoneGlobalLibrary;
begin
  _globalLibrary.Free;
  _globalLibrary := nil;
end;

function GlobalLibrary: TEnvironmentLibrary;
begin
  Result := _globalLibrary;
end;

{ TEnvironmentLibrary }

constructor TEnvironmentLibrary.Create;
begin
  inherited Create;
  fFoods := TObjectList<TFood>.Create(True);
  fBiomes := TObjectList<TBiome>.Create(True);
end;

destructor TEnvironmentLibrary.Destroy;
begin
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
          fBiomes.Add(biome);
        except
          biome.Free;
          raise;
        end;
      end;
  end;
end;

procedure TEnvironmentLibrary.LoadRegions(const container: TJSONObject);
begin
  //
end;

procedure TEnvironmentLibrary.LoadFromFile(const aFileName: string);
var
  json: TJSONObject;
begin
  if TFile.Exists(aFileName) then
  begin
    json := TJSONValue.ParseJSONValue(TFile.ReadAllText(aFileName)) as TJSONObject;
    if Assigned(json) then
    begin
      LoadFoods(json);
      LoadBiomes(json);
      LoadRegions(json);
    end;
  end;
end;

procedure TEnvironmentLibrary.SaveToFile(const aFileName: string);
begin

end;
{$endregion}


{$region 'Utility Methods'}
procedure TEnvironmentLibrary.AddFood(aFood: TFood);
begin
  fFoods.Add(aFood);
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

{$endregion}

end.
