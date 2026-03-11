unit u_EnvironmentLibraries;

interface

uses System.Classes, System.SysUtils, System.JSON, System.Generics.Collections,

  u_EditorTypes,
  u_EnvironmentTypes,
  u_Foods,
  u_Biomes,
  u_Regions;

type
  TEnvironmentLibrary = class(TEnvironmentObject)
  private
    fFoods: TObjectList<TFood>;
    fBiomes: TObjectList<TBiome>;
    fRegions: TObjectList<TRegion>;
  private
    // foods
    function GetFood(I: Integer): TFood;
    function GetFoodCount: Integer;

    // biomes
    function GetBiome(I: Integer): TBiome;
    function GetBiomeCount: Integer;

    // regions
    function GetRegion(I: Integer): TRegion;
    function GetRegionCount: Integer;
  protected
    // non property access for descendents/helpers
    property _foodList: TObjectList<TFood> read fFoods;
    property _biomeList: TObjectList<TBiome> read fBiomes;
    property _regionList: TObjectList<TRegion> read fRegions;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;

    // foods
    procedure AddFood(aFood: TFood);
    function FindFood(const aName: string): TFood;
    property FoodCount: Integer read GetFoodCount;
    property Foods[I: Integer]: TFood read GetFood;

    // biomes
    procedure AddBiome(aBiome: TBiome);
    function FindBiome(aMarker: TBiomeMarker): TBiome;
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

uses System.IOUtils, Vcl.Graphics;

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

procedure TEnvironmentLibrary.Clear;
begin
  fFoods.Clear;
  fBiomes.Clear;
  fRegions.Clear;

  // there's always a default biome
  var ground := TBiome.Create;
  try
    ground.Name := 'Ground';
    ground.Description := 'Default surface, no foods here!';
    ground.Marker := 0;
    ground.Color := clBlack;
    ground.Sunlight := Normal;
    ground.Mobility := Normal;
    ground.Capacity := Worst;
    ground.GrowthRate := Worst;
    AddBiome(ground);
  except
    ground.Free;
    raise;
  end;

end;

procedure TEnvironmentLibrary.UpdateBiomeColorPalette(var aPalette: TBiomeColorPalette);
begin
  for var i := Low(TBiomeMarker) to High(TBiomeMarker) do
    aPalette[i] := clBlack;
  for var biome in fBiomes do
    aPalette[biome.Marker] := biome.Color;
end;

procedure TEnvironmentLibrary.AddBiome(aBiome: TBiome);
begin
  // revisit someday
  Assert(fBiomes.Count < High(TBiomeMarker));

  var nextMarker := Low(TBiomeMarker);
  for var b in fBiomes do
    if (b.Marker >= nextMarker) and (b.Marker < Pred(High(TBiomeMarker))) then
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

function TEnvironmentLibrary.FindBiome(aMarker: TBiomeMarker): TBiome;
begin
  Result := nil;
  for var biome in fBiomes do
    if biome.Marker = aMarker then
      Exit(biome);
end;

function TEnvironmentLibrary.FindFood(const aName: string): TFood;
begin
  Result := nil;
  for var food in fFoods do
    if SameText(Food.Name, aName) then
      Exit(food);
end;

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

end.
