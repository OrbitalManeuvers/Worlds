unit u_DebugLibraries;

interface

uses System.Classes, System.Types, System.Generics.Collections,
  u_EnvironmentTypes, u_AgentGenome;

// The Debug Library is hand-authored and loaded as records

type
  TDebugGeneFamily = record
    Name: string;
    GeneSequence: TGeneSequence;
  end;

  TDebugAgentProfile = record
    Name: string;
    GeneFamilyName: string;
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

  TDebugDeltaEntry = record
    Location: TPoint;
    Amount: Single;   // initial cache amount in [0..1]; 0 = absent/default
  end;

  TDebugDeltaList = TArray<TDebugDeltaEntry>;

  TDebugScenario = record
    Name: string;
    Seed: Integer;
    Dimensions: TSize;
    DefaultSunlight: TRating;
    DefaultMobility: TRating;
    AgentActivationTick: Integer;
    Foods: TArray<string>;
    Resources: TArray<TDebugResource>;
    Agents: TArray<TDebugAgentPresence>;
    DeltaLists: TArray<TDebugDeltaList>;  // up to 3 pre-defined placement lists; empty = use runtime generation
  end;

  TDebugLibrary = class
  private
    fGeneFamilies: TArray<TDebugGeneFamily>;
    fScenarios: TArray<TDebugScenario>;
    fProfiles: TArray<TDebugAgentProfile>;
  public
    constructor Create(const aFileName: string);
    destructor Destroy; override;

    function FindGeneFamily(const aName: string): TDebugGeneFamily;
    function FindScenario(const aName: string): TDebugScenario;
    function FindProfile(const aName: string): TDebugAgentProfile;
    function ResolveGeneSequence(const aProfile: TDebugAgentProfile): string;

    property GeneFamilies: TArray<TDebugGeneFamily> read fGeneFamilies;
    property Scenarios: TArray<TDebugScenario> read fScenarios;
    property Profiles: TArray<TDebugAgentProfile> read fProfiles;
  end;

var
  DebugLibrary: TDebugLibrary = nil;

implementation

uses System.SysUtils, System.JSON, System.IOUtils,
  u_EditorTypes, u_SimpleJSON;

const
  KEY_AGENT_ACTIVATION_TICK = 'agentActivationTick';
  KEY_AGENTS = 'agents';
  KEY_BASE = 'base';
  KEY_CACHES = 'caches';
  KEY_COGNITION = 'cognition';
  KEY_CONVERT = 'convert';
  KEY_CONVERTER_RATINGS = 'converterRatings';
  KEY_COUNT = 'count';
  KEY_DEFAULT_MOBILITY = 'defaultMobility';
  KEY_DEFAULT_SUNLIGHT = 'defaultSunlight';
  KEY_DIMENSIONS = 'dimensions';
  KEY_ENERGY = 'energy';
  KEY_FOOD = 'food';
  KEY_FOODS = 'foods';
  KEY_FORAGE = 'forage';
  KEY_GENE_FAMILIES = 'geneFamilies';
  KEY_GENE_FAMILY = 'geneFamily';
  KEY_GENES = 'genes';
  KEY_NAME = 'name';
  KEY_GROWTH_RATE = 'growthRate';
  KEY_LOCATION = 'location';
  KEY_MOVEMENT = 'movement';
  KEY_PROFILES = 'profiles';
  KEY_PROFILE = 'profile';
  KEY_REPRODUCE = 'reproduce';
  KEY_RESOURCES = 'resources';
  KEY_SCENARIOS = 'scenarios';
  KEY_SEED = 'seed';
  KEY_SHELTER = 'shelter';
  KEY_SIGHT = 'sight';
  KEY_SMELL = 'smell';
  KEY_SMELL_RATINGS = 'smellRatings';
  KEY_X = 'x';
  KEY_Y = 'y';
  KEY_AMOUNT = 'amount';
  KEY_DELTA = 'delta';
  KEY_DELTA_LIST1 = 'list1';
  KEY_DELTA_LIST2 = 'list2';
  KEY_DELTA_LIST3 = 'list3';

  GENE_INDEX_ENERGY = 1;
  GENE_INDEX_SMELL = 2;
  GENE_INDEX_SIGHT = 3;
  GENE_INDEX_MOVEMENT = 4;
  GENE_INDEX_FORAGE = 5;
  GENE_INDEX_SHELTER = 6;
  GENE_INDEX_REPRODUCE = 7;
  GENE_INDEX_COGNITION = 8;
  GENE_INDEX_CONVERT = 9;

type
  family_loader = record helper for TDebugGeneFamily
    procedure LoadFromJSON(const JSON: TJSONObject);
  end;

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

{ family_loader }

procedure family_loader.LoadFromJSON(const JSON: TJSONObject);
  procedure ApplyCodeFromJSON(const Obj: TJSONObject; const Key: string; const SlotIndex: Integer;
    var SequenceText: string);
  begin
    if not Assigned(Obj) then
      Exit;

    var value := Obj.StrValue(Key);
    if value <> '' then
      SequenceText[SlotIndex] := value[1];
  end;
begin
  Name := JSON.StrValue(KEY_NAME);

  var baseCode: Char := 'A';
  var baseText := JSON.StrValue(KEY_BASE);
  if baseText <> '' then
    baseCode := baseText[1];

  var sequenceText := StringOfChar(baseCode, GENE_SEQUENCE_LENGTH);

  var genes: TJSONObject;
  if JSON.TryGetValue(KEY_GENES, genes) then
  begin
    ApplyCodeFromJSON(genes, KEY_ENERGY, GENE_INDEX_ENERGY, sequenceText);
    ApplyCodeFromJSON(genes, KEY_SMELL, GENE_INDEX_SMELL, sequenceText);
    ApplyCodeFromJSON(genes, KEY_SIGHT, GENE_INDEX_SIGHT, sequenceText);
    ApplyCodeFromJSON(genes, KEY_MOVEMENT, GENE_INDEX_MOVEMENT, sequenceText);
    ApplyCodeFromJSON(genes, KEY_FORAGE, GENE_INDEX_FORAGE, sequenceText);
    ApplyCodeFromJSON(genes, KEY_SHELTER, GENE_INDEX_SHELTER, sequenceText);
    ApplyCodeFromJSON(genes, KEY_REPRODUCE, GENE_INDEX_REPRODUCE, sequenceText);
    ApplyCodeFromJSON(genes, KEY_COGNITION, GENE_INDEX_COGNITION, sequenceText);
    ApplyCodeFromJSON(genes, KEY_CONVERT, GENE_INDEX_CONVERT, sequenceText);
  end;

  GeneSequence.AsText := sequenceText;
end;

{ agent_loader }
procedure agent_loader.LoadFromJSON(const JSON: TJSONObject);
begin
  Name := JSON.StrValue(KEY_NAME);
  GeneFamilyName := JSON.StrValue(KEY_GENE_FAMILY);
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
const
  LIST_KEYS: array[0..2] of string = (KEY_DELTA_LIST1, KEY_DELTA_LIST2, KEY_DELTA_LIST3);
begin
  Name := JSON.StrValue(KEY_NAME);
  Seed := JSON.IntValue(KEY_SEED);

  var p := JSON.PointValue(KEY_DIMENSIONS, KEY_X, KEY_Y);
  Dimensions := TSize.Create(p.X, p.Y);

  DefaultSunlight.AsText := JSON.StrValue(KEY_DEFAULT_SUNLIGHT);
  DefaultMobility.AsText := JSON.StrValue(KEY_DEFAULT_MOBILITY);
  AgentActivationTick := JSON.IntValue(KEY_AGENT_ACTIVATION_TICK);

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

  var deltaObj: TJSONObject;
  if JSON.TryGetValue(KEY_DELTA, deltaObj) then
  begin
    SetLength(DeltaLists, Length(LIST_KEYS));
    for var listIndex := 0 to High(LIST_KEYS) do
    begin
      SetLength(DeltaLists[listIndex], 0);
      if deltaObj.TryGetValue(LIST_KEYS[listIndex], jArr) then
      begin
        SetLength(DeltaLists[listIndex], jArr.Count);
        for var i := 0 to jArr.Count - 1 do
        begin
          if not (jArr[i] is TJSONObject) then
            Continue;
          var entryObj := jArr[i] as TJSONObject;
          DeltaLists[listIndex][i].Location.X := entryObj.IntValue(KEY_X);
          DeltaLists[listIndex][i].Location.Y := entryObj.IntValue(KEY_Y);
          // amount is optional; missing or null defaults to 0.0
          var amountVal: TJSONValue;
          if entryObj.TryGetValue(KEY_AMOUNT, amountVal) and (amountVal is TJSONNumber) then
            DeltaLists[listIndex][i].Amount := (amountVal as TJSONNumber).AsDouble
          else
            DeltaLists[listIndex][i].Amount := 0.0;
        end;
      end;
    end;
  end;
end;

{ TDebugLibrary }

constructor TDebugLibrary.Create(const aFileName: string);
begin
  inherited Create;
  SetLength(fGeneFamilies, 0);
  SetLength(fProfiles, 0);
  SetLength(fScenarios, 0);

  if TFile.Exists(aFileName) then
  begin
    var json := TJSONValue.ParseJSONValue(TFile.ReadAllText(aFileName));
    if Assigned(json) and (json is TJSONObject) then
    begin
      var jsonObject := TJSONObject(json);
      var jArr: TJSONArray;

      // load gene families
      if jsonObject.TryGetValue(KEY_GENE_FAMILIES, jArr) then
      begin
        SetLength(fGeneFamilies, jArr.Count);
        for var i := 0 to jArr.Count - 1 do
          if jArr[i] is TJSONObject then
            fGeneFamilies[i].LoadFromJSON(jArr[i] as TJSONObject)
      end;

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

function TDebugLibrary.FindGeneFamily(const aName: string): TDebugGeneFamily;
begin
  Result := Default(TDebugGeneFamily);
  for var i := 0 to High(fGeneFamilies) do
    if SameText(fGeneFamilies[i].Name, aName) then
      Exit(fGeneFamilies[i]);
  Assert(False, 'geneFamily: ' + aName);
end;

function TDebugLibrary.FindProfile(const aName: string): TDebugAgentProfile;
begin
  Result := Default(TDebugAgentProfile);
  for var i := 0 to High(fProfiles) do
    if SameText(fProfiles[i].Name, aName) then
      Exit(fProfiles[i]);
end;

function TDebugLibrary.ResolveGeneSequence(const aProfile: TDebugAgentProfile): string;
begin
  var family := FindGeneFamily(aProfile.GeneFamilyName);
  Result := family.GeneSequence.AsText;
end;

function TDebugLibrary.FindScenario(const aName: string): TDebugScenario;
begin
  Result := Default(TDebugScenario);

  for var i := 0 to High(fScenarios) do
    if SameText(fScenarios[i].Name, aName) then
      Exit(fScenarios[i]);
end;

end.
