unit u_DebugSessionComposers;

interface

uses
  u_SimRuntimes, u_SessionComposerIntf;

type
  TDebugSessionComposer = class(TInterfacedObject, ISessionComposer)
  private
    fScenarioName: string;
    procedure Compose(aRuntime: TSimRuntime);
  public
    constructor Create(const aScenarioName: string);
    destructor Destroy; override;
  end;

implementation

uses
  System.JSON, System.IOUtils, System.SysUtils, System.Types,
  System.Generics.Collections,
  u_SimpleJSON,
  u_EnvironmentLibraries,
  u_EnvironmentTypes,
  u_EditorTypes,
  u_BiologyTypes,
  u_Foods,
  u_SimPopulators,
  u_DebugLibraries,
  u_SimUpscalers;

{ TDebugSessionComposer }

constructor TDebugSessionComposer.Create(const aScenarioName: string);
begin
  inherited Create;
  fScenarioName := aScenarioName;
end;

destructor TDebugSessionComposer.Destroy;
begin

  inherited;
end;

procedure TDebugSessionComposer.Compose(aRuntime: TSimRuntime);
begin

  var scenario := DebugLibrary.FindScenario(fScenarioName);
  Assert(scenario.Dimensions.cx = 256); // !! temp

  // resolve foods from library
  var foods: TArray<TFood>;
  SetLength(foods, Length(scenario.Foods));
  for var i := 0 to High(foods) do
  begin
    foods[i] := WorldLibrary.FindFood(scenario.Foods[i]);
    Assert(Assigned(foods[i]));
  end;

  // seed policy
  if scenario.Seed <> 0 then
    RandSeed := scenario.Seed;

  // environment
  var upscaler := TDebugUpscaler.Create(aRuntime.Environment,
    scenario.Dimensions, scenario.DefaultSunlight, scenario.DefaultMobility);
  try
    upscaler.SetFoods(foods);

    var totalCacheCount := 0;
    for var resource in scenario.Resources do
      Inc(totalCacheCount, Length(resource.Caches));
    upscaler.SetTotalResourceCount(totalCacheCount);

    for var resource in scenario.Resources do
    begin
      upscaler.SetCellResourceCount(resource.Location.X, resource.Location.Y, Length(resource.Caches));
      for var cacheIndex := 0 to High(resource.Caches) do
      begin
        var cache := resource.Caches[cacheIndex];
        var foodIndex := -1;
        for var fi := 0 to High(scenario.Foods) do
          if SameText(scenario.Foods[fi], cache.FoodName) then
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
  for var agentDef in scenario.Agents do
    Inc(totalAgentCount, agentDef.Count);
  population.AgentCount := totalAgentCount;

  var nextId: Cardinal := 1;
  var agentIndex := 0;
  for var i := 0 to High(scenario.Agents) do
  begin
    var agent := scenario.Agents[i];
    var profile := DebugLibrary.FindProfile(agent.ProfileName);

    var converterRatings: TMoleculeRatings := nil;
    if profile.ConverterRatingsName <> '' then
      converterRatings := WorldLibrary.FindRatings(profile.ConverterRatingsName);

    var smellRatings: TMoleculeRatings := nil;
    if profile.SmellRatingsName <> '' then
      smellRatings := WorldLibrary.FindRatings(profile.SmellRatingsName);

    var cellIndex := (agent.Location.Y * aRuntime.Environment.Dimensions.cx) + agent.Location.X;
    for var count := 1 to agent.Count do
    begin
      TDebugPopulator.PopulateAgent(population, agentIndex, nextId, cellIndex,
        converterRatings, smellRatings, profile.GeneSequence);
      Inc(agentIndex);
      Inc(nextId);
    end;
  end;
end;

end.
