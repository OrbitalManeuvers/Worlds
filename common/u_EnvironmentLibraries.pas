unit u_EnvironmentLibraries;

interface

uses System.Classes, System.SysUtils, System.JSON, System.Generics.Collections,

  u_EditorTypes,
  u_EnvironmentTypes,
  u_BiologyTypes,
  u_Foods,
  u_Seeds,
  u_Biomes,
  u_Regions,
  u_Worlds;

type
  TEnvironmentLibrary = class(TEnvironmentObject)
  private
    fFoods: TObjectList<TFood>;
    fSeeds: TObjectList<TSeed>;
    fBiomes: TObjectList<TBiome>;
    fRegions: TObjectList<TRegion>;
    fMoleculeRatings: TObjectList<TMoleculeRatings>;
    fWorlds: TObjectList<TWorld>;
  private
    // foods
    function GetFood(I: Integer): TFood;
    function GetFoodCount: Integer;

    // biomes
    function GetBiome(I: Integer): TBiome;
    function GetBiomeCount: Integer;

    // seeds
    function GetSeed(I: Integer): TSeed;
    function GetSeedCount: Integer;

    // regions
    function GetRegion(I: Integer): TRegion;
    function GetRegionCount: Integer;

    // ratings
    function GetRatings(I: Integer): TMoleculeRatings;
    function GetRatingsCount: Integer;

    // worlds
    function GetWorld(I: Integer): TWorld;
    function GetWorldCount: Integer;

  protected
    // non property access for descendents/helpers
    property _foodList: TObjectList<TFood> read fFoods;
    property _seedList: TObjectList<TSeed> read fSeeds;
    property _biomeList: TObjectList<TBiome> read fBiomes;
    property _regionList: TObjectList<TRegion> read fRegions;
    property _ratingsList: TObjectList<TMoleculeRatings> read fMoleculeRatings;
    property _worldList: TObjectList<TWorld> read fWorlds;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;

    // foods
    procedure AddFood(aFood: TFood);
    function FindFood(const aName: string): TFood;
    property FoodCount: Integer read GetFoodCount;
    property Foods[I: Integer]: TFood read GetFood;

    // seeds
    procedure AddSeed(aSeed: TSeed);
    function FindSeed(const aName: string): TSeed;
    property SeedCount: Integer read GetSeedCount;
    property Seeds[I: Integer]: TSeed read GetSeed;

    // biomes
    procedure AddBiome(aBiome: TBiome);
    function FindBiome(aMarker: TBiomeMarker): TBiome;
    property BiomeCount: Integer read GetBiomeCount;
    property Biomes[I: Integer]: TBiome read GetBiome;

    // regions
    procedure AddRegion(aRegion: TRegion);
    function FindRegion(const aName: string): TRegion;
    function IndexOfRegion(const aName: string): Integer;
    property RegionCount: Integer read GetRegionCount;
    property Regions[I: Integer]: TRegion read GetRegion;

    // molecule ratings
    procedure AddRatings(aRatings: TMoleculeRatings);
    function FindRatings(const aName: string): TMoleculeRatings;
    property RatingsCount: Integer read GetRatingsCount;
    property Ratings[I: Integer]: TMoleculeRatings read GetRatings;

    // worlds
    procedure AddWorld(aWorld: TWorld);
    property WorldCount: Integer read GetWorldCount;
    property Worlds[I: Integer]: TWorld read GetWorld;

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
  fSeeds := TObjectList<TSeed>.Create(True);
  fBiomes := TObjectList<TBiome>.Create(True);
  fRegions := TObjectList<TRegion>.Create(True);
  fMoleculeRatings := TObjectList<TMoleculeRatings>.Create(True);
  fWorlds := TObjectList<TWorld>.Create(True);
  Clear;
end;

destructor TEnvironmentLibrary.Destroy;
begin
  fWorlds.Free;
  fMoleculeRatings.Free;
  fRegions.Free;
  fBiomes.Free;
  fSeeds.Free;
  fFoods.Free;
  inherited;
end;

procedure TEnvironmentLibrary.Clear;
begin
  fFoods.Clear;
  fSeeds.Clear;
  fBiomes.Clear;
  fRegions.Clear;
  fMoleculeRatings.Clear;
  fWorlds.Clear;

  // there's always a default biome
  var ground := TBiome.Create;
  try
    ground.Name := 'Ground';
    ground.Description := 'Default surface, no foods here!';
    ground.Marker := 0;
    ground.Color := clBlack;
    ground.Sunlight := Best;    // i.e. unmodified
    ground.Mobility := Best;    // i.e. unmodified
    ground.Density := Worst;   // doesn't really matter
    ground.GrowthRate := Worst; // doesn't really matter
    AddBiome(ground);
  except
    ground.Free;
    raise;
  end;

  // there's always a random seed
  var seed := TSeed.Create;
  try
    seed.Name := 'Random';
    seed.Value := 0;
    AddSeed(seed);
  except
    seed.Free;
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

procedure TEnvironmentLibrary.AddSeed(aSeed: TSeed);
begin
  aSeed.OnChange := ChildChanged;
  fSeeds.Add(aSeed);
  Changed;
end;

procedure TEnvironmentLibrary.AddRatings(aRatings: TMoleculeRatings);
begin
  aRatings.OnChange := ChildChanged;
  fMoleculeRatings.Add(aRatings);
  Changed;
end;

procedure TEnvironmentLibrary.AddRegion(aRegion: TRegion);
begin
  aRegion.OnChange := ChildChanged;
  fRegions.Add(aRegion);
  Changed;
end;

procedure TEnvironmentLibrary.AddWorld(aWorld: TWorld);
begin
  aWorld.OnChange := ChildChanged;
  fWorlds.Add(aWorld);
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
    if SameText(food.Name, aName) then
      Exit(food);
end;

function TEnvironmentLibrary.FindSeed(const aName: string): TSeed;
begin
  Result := nil;
  for var seed in fSeeds do
    if SameText(seed.Name, aName) then
      Exit(seed);
end;

function TEnvironmentLibrary.FindRatings(const aName: string): TMoleculeRatings;
begin
  Result := nil;
  for var ratings in fMoleculeRatings do
    if SameText(ratings.Name, aName) then
      Exit(ratings);
end;

function TEnvironmentLibrary.FindRegion(const aName: string): TRegion;
begin
  var index := IndexOfRegion(aName);
  if index <> -1 then
    Result := Regions[index]
  else
    Result := nil;
end;

function TEnvironmentLibrary.IndexOfRegion(const aName: string): Integer;
begin
  Result := -1;
  for var index := 0 to Self.RegionCount - 1 do
    if SameText(Regions[index].Name, aName) then
      Exit(Index);
end;

function TEnvironmentLibrary.GetBiome(I: Integer): TBiome;
begin
  Result := fBiomes[I];
end;

function TEnvironmentLibrary.GetBiomeCount: Integer;
begin
  Result := fBiomes.Count;
end;

function TEnvironmentLibrary.GetSeed(I: Integer): TSeed;
begin
  Result := fSeeds[I];
end;

function TEnvironmentLibrary.GetSeedCount: Integer;
begin
  Result := fSeeds.Count;
end;

function TEnvironmentLibrary.GetFood(I: Integer): TFood;
begin
  Result := fFoods[I];
end;

function TEnvironmentLibrary.GetFoodCount: Integer;
begin
  Result := fFoods.Count;
end;

function TEnvironmentLibrary.GetRatings(I: Integer): TMoleculeRatings;
begin
  Result := fMoleculeRatings[I];
end;

function TEnvironmentLibrary.GetRatingsCount: Integer;
begin
  Result := fMoleculeRatings.Count;
end;

function TEnvironmentLibrary.GetRegion(I: Integer): TRegion;
begin
  Result := fRegions[I];
end;

function TEnvironmentLibrary.GetRegionCount: Integer;
begin
  Result := fRegions.Count;
end;

function TEnvironmentLibrary.GetWorld(I: Integer): TWorld;
begin
  Result := fWorlds[I];
end;

function TEnvironmentLibrary.GetWorldCount: Integer;
begin
  Result := fWorlds.Count;
end;

end.
