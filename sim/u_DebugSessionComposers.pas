unit u_DebugSessionComposers;

interface

uses
  u_SimRuntimes, u_SessionComposerIntf, u_EnvironmentLibraries, u_EnvironmentTypes;

type
  TDebugSessionComposer = class(TInterfacedObject, ISessionComposer)
  private
    fLibrary: TEnvironmentLibrary;
    fScenarioFile: string;
    fScenarioName: string;
    procedure Compose(aRuntime: TSimRuntime);
  public
    constructor Create(aLibrary: TEnvironmentLibrary; const aScenarioFile, aScenarioName: string);
    destructor Destroy; override;
  end;

implementation

uses
  System.JSON, System.IOUtils, System.SysUtils, System.Types,
  System.Generics.Collections,
  u_SimpleJSON,
  u_EditorTypes,
  u_BiologyTypes,
  u_Foods,
  u_SimPopulators,
  u_SimUpscalers;

const
  KEY_AGENTS = 'agents';
  KEY_CACHES = 'caches';
  KEY_CONVERTER_RATINGS = 'converterRatings';
  KEY_COUNT = 'count';
  KEY_DEFAULT_MOBILITY = 'defaultMobility';
  KEY_DEFAULT_SUNLIGHT = 'defaultSunlight';
  KEY_DIMENSIONS = 'dimensions';
  KEY_FOOD = 'food';
  KEY_FOODS = 'foods';
  KEY_GENE_SEQUENCE = 'geneSequence';
  KEY_GROWTH_RATE = 'growthRate';
  KEY_LOCATION = 'location';
  KEY_PROFILES = 'profiles';
  KEY_PROFILE = 'profile';
  KEY_RESOURCES = 'resources';
  KEY_SCENARIOS = 'scenarios';
  KEY_SEED = 'seed';
  KEY_SMELL_RATINGS = 'smellRatings';
  KEY_X = 'x';
  KEY_Y = 'y';

type
  TDebugAgentProfileDef = record
    Name: string;
    GeneSequence: string;
    ConverterRatingsName: string;
    SmellRatingsName: string;
    procedure LoadFromJSON(const JSON: TJSONObject);
  end;

  TDebugAgentPresenceDef = record
    ProfileName: string;
    Location: TPoint;
    Count: Integer;
    procedure LoadFromJSON(const JSON: TJSONObject);
  end;

  TDebugCacheDef = record
    FoodName: string;
    GrowthRate: TRating;
    procedure LoadFromJSON(const JSON: TJSONObject);
  end;

  TDebugResourceDef = record
    Location: TPoint;
    Caches: TArray<TDebugCacheDef>;
    procedure LoadFromJSON(const JSON: TJSONObject);
  end;

  TDebugScenarioDef = record
    Name: string;
    Seed: Integer;
    Dimensions: TSize;
    DefaultSunlight: TRating;
    DefaultMobility: TRating;
    Foods: TArray<string>;
    Resources: TArray<TDebugResourceDef>;
    Agents: TArray<TDebugAgentPresenceDef>;
    procedure LoadFromJSON(const JSON: TJSONObject);
  end;

// -- load methods

{ TDebugAgentProfileDef }
procedure TDebugAgentProfileDef.LoadFromJSON(const JSON: TJSONObject);
begin
  GeneSequence := JSON.StrValue(KEY_GENE_SEQUENCE);
  ConverterRatingsName := JSON.StrValue(KEY_CONVERTER_RATINGS);
  SmellRatingsName := JSON.StrValue(KEY_SMELL_RATINGS);
end;

{ TDebugAgentPresenceDef }

procedure TDebugAgentPresenceDef.LoadFromJSON(const JSON: TJSONObject);
begin
  ProfileName := JSON.StrValue(KEY_PROFILE);
  Location := JSON.PointValue(KEY_LOCATION, KEY_X, KEY_Y);
  Count := JSON.IntValue(KEY_COUNT);
end;

{ TDebugCacheDef }
procedure TDebugCacheDef.LoadFromJSON(const JSON: TJSONObject);
begin
  FoodName := JSON.StrValue(KEY_FOOD);
  GrowthRate.AsText := JSON.StrValue(KEY_GROWTH_RATE);
end;

{ TDebugResourceDef }
procedure TDebugResourceDef.LoadFromJSON(const JSON: TJSONObject);
begin
  Location := JSON.PointValue(KEY_LOCATION, KEY_X, KEY_Y);

  var jArr: TJSONArray;
  if JSON.TryGetValue(KEY_CACHES, jArr) then
  begin
    SetLength(Caches, jArr.Count);
    for var i := 0 to jArr.Count - 1 do
      if jArr[i] is TJSONObject then
        Caches[i].LoadFromJSON(jArr[i] as TJSONObject);
  end;
end;

{ TDebugScenarioDef }
procedure TDebugScenarioDef.LoadFromJSON(const JSON: TJSONObject);
begin
  Seed := JSON.IntValue(KEY_SEED);

  var p := JSON.PointValue(KEY_DIMENSIONS, KEY_X, KEY_Y);
  Dimensions := TSize.Create(p.X, p.Y);

  DefaultSunlight.AsText := JSON.StrValue(KEY_DEFAULT_SUNLIGHT);
  DefaultMobility.AsText := JSON.StrValue(KEY_DEFAULT_MOBILITY);

  var jArr: TJSONArray;
  if JSON.TryGetValue(KEY_FOODS, jArr) then
  begin
    SetLength(Foods, jArr.Count);
    for var i := 0 to jArr.Count - 1 do
      Foods[i] := jArr[i].Value;
  end;

  if JSON.TryGetValue(KEY_RESOURCES, jArr) then
  begin
    SetLength(Resources, jArr.Count);
    for var i := 0 to jArr.Count - 1 do
      if jArr[i] is TJSONObject then
        Resources[i].LoadFromJSON(jArr[i] as TJSONObject);
  end;

  if JSON.TryGetValue(KEY_AGENTS, jArr) then
  begin
    SetLength(Agents, jArr.Count);
    for var i := 0 to jArr.Count - 1 do
      if jArr[i] is TJSONObject then
        Agents[i].LoadFromJSON(jArr[i] as TJSONObject);
  end;
end;

{ TDebugSessionComposer }

constructor TDebugSessionComposer.Create(aLibrary: TEnvironmentLibrary; const aScenarioFile, aScenarioName: string);
begin
  inherited Create;
  fLibrary := aLibrary;
  fScenarioFile := aScenarioFile;
  fScenarioName := aScenarioName;
end;

destructor TDebugSessionComposer.Destroy;
begin

  inherited;
end;

procedure TDebugSessionComposer.Compose(aRuntime: TSimRuntime);
begin
  if not TFile.Exists(fScenarioFile) then
    Exit;

  var jsonFile := TJSONValue.ParseJSONValue(TFile.ReadAllText(fScenarioFile));
  try
    Assert(Assigned(jsonFile));
    Assert(jsonFile is TJSONObject);

    var root: TJSONObject := jsonFile as TJSONObject;
    var scenario := root.FindValue(KEY_SCENARIOS + '.' + fScenarioName);
    Assert(Assigned(scenario));

    var scenarioDef := Default(TDebugScenarioDef);
    scenarioDef.LoadFromJSON(scenario as TJSONObject);

    // the scenario's agents array lists the agent profiles needed
    var agentProfiles: TArray<TDebugAgentProfileDef>;
    SetLength(agentProfiles, Length(scenarioDef.Agents));
    for var i := 0 to High(agentProfiles) do
    begin
      var profileNode := root.FindValue(KEY_PROFILES + '.' + scenarioDef.Agents[i].ProfileName);
      Assert(Assigned(profileNode));
      agentProfiles[i].LoadFromJSON(profileNode as TJSONObject);
    end;

    // resolve foods from library
    var foods: TArray<TFood>;
    SetLength(foods, Length(scenarioDef.Foods));
    for var i := 0 to High(foods) do
    begin
      foods[i] := fLibrary.FindFood(scenarioDef.Foods[i]);
      Assert(Assigned(foods[i]));
    end;

    // seed policy
    if scenarioDef.Seed <> 0 then
      RandSeed := scenarioDef.Seed;

    // environment
    var upscaler := TDebugUpscaler.Create(aRuntime.Environment,
      scenarioDef.Dimensions, scenarioDef.DefaultSunlight, scenarioDef.DefaultMobility);
    try
      upscaler.SetFoods(foods);

      var totalCacheCount := 0;
      for var resource in scenarioDef.Resources do
        Inc(totalCacheCount, Length(resource.Caches));
      upscaler.SetTotalResourceCount(totalCacheCount);

      for var resource in scenarioDef.Resources do
      begin
        upscaler.SetCellResourceCount(resource.Location.X, resource.Location.Y, Length(resource.Caches));
        for var cacheIndex := 0 to High(resource.Caches) do
        begin
          var cache := resource.Caches[cacheIndex];
          var foodIndex := -1;
          for var fi := 0 to High(scenarioDef.Foods) do
            if SameText(scenarioDef.Foods[fi], cache.FoodName) then
            begin
              foodIndex := fi;
              Break;
            end;
          Assert(foodIndex >= 0);
          upscaler.SetResource(resource.Location.X, resource.Location.Y, cacheIndex,
            foodIndex, cache.GrowthRate);
        end;
      end;
    finally
      upscaler.Free;
    end;

    // population
    var population := aRuntime.Population;
    population.SetCellCount(Length(aRuntime.Environment.Cells));

    var totalAgentCount := 0;
    for var agentDef in scenarioDef.Agents do
      Inc(totalAgentCount, agentDef.Count);
    population.AgentCount := totalAgentCount;

    var nextId: Cardinal := 1;
    var agentIndex := 0;
    for var i := 0 to High(scenarioDef.Agents) do
    begin
      var agentDef := scenarioDef.Agents[i];
      var profile := agentProfiles[i];

      var converterRatings: TMoleculeRatings := nil;
      if profile.ConverterRatingsName <> '' then
        converterRatings := fLibrary.FindRatings(profile.ConverterRatingsName);

      var smellRatings: TMoleculeRatings := nil;
      if profile.SmellRatingsName <> '' then
        smellRatings := fLibrary.FindRatings(profile.SmellRatingsName);

      var cellIndex := (agentDef.Location.Y * aRuntime.Environment.Dimensions.cx) + agentDef.Location.X;
      for var count := 1 to agentDef.Count do
      begin
        TDebugPopulator.PopulateAgent(population, agentIndex, nextId, cellIndex,
          converterRatings, smellRatings, profile.GeneSequence);
        Inc(agentIndex);
        Inc(nextId);
      end;
    end;

  finally
    jsonFile.Free;
  end;
end;

end.
