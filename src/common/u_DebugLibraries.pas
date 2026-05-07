unit u_DebugLibraries;

interface

uses System.Classes, System.Types, System.Generics.Collections,
  u_EnvironmentTypes;

// The Debug Library is hand-authored and loaded as records

type
  TDebugAgentProfile = record
    Name: string;
    GeneSequence: string;
    ConverterRatingsName: string;
    SmellRatingsName: string;
  end;

  TDebugAgentPresence = record
    ProfileName: string;
    Location: TPoint;
    Count: Integer;
  end;

  TDebugCache = record
    FoodName: string;
    GrowthRate: TRating;
  end;

  TDebugResource = record
    Location: TPoint;
    Caches: TArray<TDebugCache>;
  end;

  TDebugScenario = record
    Name: string;
    Seed: Integer;
    Dimensions: TSize;
    DefaultSunlight: TRating;
    DefaultMobility: TRating;
    Foods: TArray<string>;
    Resources: TArray<TDebugResource>;
    Agents: TArray<TDebugAgentPresence>;
  end;

  TDebugLibrary = class
  private
    fScenarios: TArray<TDebugScenario>;
    fProfiles: TArray<TDebugAgentProfile>;
  public
    constructor Create(const aFileName: string);
    destructor Destroy; override;

    function FindScenario(const aName: string): TDebugScenario;
    function FindProfile(const aName: string): TDebugAgentProfile;

    property Scenarios: TArray<TDebugScenario> read fScenarios;
    property Profiles: TArray<TDebugAgentProfile> read fProfiles;
  end;

var
  DebugLibrary: TDebugLibrary = nil;

implementation

uses System.SysUtils, System.JSON, System.IOUtils,
  u_EditorTypes, u_SimpleJSON;

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
  KEY_NAME = 'name';
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
  agent_loader = record helper for TDebugAgentProfile
    procedure LoadFromJSON(const JSON: TJSONObject);
  end;

  presence_loader = record helper for TDebugAgentPresence
    procedure LoadFromJSON(const JSON: TJSONObject);
  end;

  cache_loader = record helper for TDebugCache
    procedure LoadFromJSON(const JSON: TJSONObject);
  end;

  resource_loader = record helper for TDebugResource
    procedure LoadFromJSON(const JSON: TJSONObject);
  end;

  scenario_loader = record helper for TDebugScenario
    procedure LoadFromJSON(const JSON: TJSONObject);
  end;

{ agent_loader }
procedure agent_loader.LoadFromJSON(const JSON: TJSONObject);
begin
  Name := JSON.StrValue(KEY_NAME);
  GeneSequence := JSON.StrValue(KEY_GENE_SEQUENCE);
  ConverterRatingsName := JSON.StrValue(KEY_CONVERTER_RATINGS);
  SmellRatingsName := JSON.StrValue(KEY_SMELL_RATINGS);
end;

{ presence_loader }
procedure presence_loader.LoadFromJSON(const JSON: TJSONObject);
begin
  ProfileName := JSON.StrValue(KEY_PROFILE);
  Location := JSON.PointValue(KEY_LOCATION, KEY_X, KEY_Y);
  Count := JSON.IntValue(KEY_COUNT);
end;

{ cache_loader }
procedure cache_loader.LoadFromJSON(const JSON: TJSONObject);
begin
  FoodName := JSON.StrValue(KEY_FOOD);
  GrowthRate.AsText := JSON.StrValue(KEY_GROWTH_RATE);
end;

{ resource_loader }
procedure resource_loader.LoadFromJSON(const JSON: TJSONObject);
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


{ scenario_loader }
procedure scenario_loader.LoadFromJSON(const JSON: TJSONObject);
begin
  Name := JSON.StrValue(KEY_NAME);
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

{ TDebugLibrary }

constructor TDebugLibrary.Create(const aFileName: string);
begin
  inherited Create;
  SetLength(fProfiles, 0);
  SetLength(fScenarios, 0);

  if TFile.Exists(aFileName) then
  begin
    var json := TJSONValue.ParseJSONValue(TFile.ReadAllText(aFileName));
    if Assigned(json) and (json is TJSONObject) then
    begin
      var jsonObject := TJSONObject(json);
      var jArr: TJSONArray;

      // load profiles
      if jsonObject.TryGetValue(KEY_PROFILES, jArr) then
      begin
        SetLength(fProfiles, jArr.Count);
        for var i := 0 to jArr.Count - 1 do
          if jArr[i] is TJSONObject then
            fProfiles[i].LoadFromJSON(jArr[i] as TJSONObject)
      end;

      // load scenarios
      if jsonObject.TryGetValue(KEY_SCENARIOS, jArr) then
      begin
        SetLength(fScenarios, jArr.Count);
        for var i := 0 to jArr.Count - 1 do
          if jArr[i] is TJSONObject then
            fScenarios[i].LoadFromJSON(jArr[i] as TJSONObject);
      end;

    end;
  end;
end;

destructor TDebugLibrary.Destroy;
begin
  //
  inherited;
end;

function TDebugLibrary.FindProfile(const aName: string): TDebugAgentProfile;
begin
  Result := Default(TDebugAgentProfile);
  for var i := 0 to High(fProfiles) do
    if SameText(fProfiles[i].Name, aName) then
      Exit(fProfiles[i]);
end;

function TDebugLibrary.FindScenario(const aName: string): TDebugScenario;
begin
  Result := Default(TDebugScenario);

  for var i := 0 to High(fScenarios) do
    if SameText(fScenarios[i].Name, aName) then
      Exit(fScenarios[i]);
end;

end.
