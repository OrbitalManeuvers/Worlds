unit u_SessionComposers;

interface

uses
  u_SimRuntimes, u_SessionComposerIntf,
  u_SessionParameters;

type
  TSessionComposer = class(TInterfacedObject, ISessionComposer)
  private
    fParams: TUpscalerParameters;
    procedure Compose(aRuntime: TSimRuntime);
  public
    constructor Create(const aParams: TUpscalerParameters);
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections,
  u_BiomassConfigResolvers,
  u_Foods,
  u_SimParams,
  u_SimPopulators,
  u_SimUpscalers,
  u_WorldLayouts,
  u_EnvironmentLibraries;

{ TSessionComposer }

constructor TSessionComposer.Create(const aParams: TUpscalerParameters);
begin
  inherited Create;
  fParams := aParams;
end;

destructor TSessionComposer.Destroy;
begin

  inherited;
end;

procedure TSessionComposer.Compose(aRuntime: TSimRuntime);
  function BuildSimParams: TSimParams;
  begin
    Result.InitDefaults;
    Result.DebugMode := False;
    Result.Seed := fParams.Seed;
    Result.Factor := fParams.Factor;

    Result.Population.AgentCount := fParams.Population.AgentCount;
    Result.Population.DOAChance := fParams.Population.DOAChance;
    Result.Population.Scheme := u_SimParams.TPopulationScheme(Ord(fParams.Population.Scheme));
    SetLength(Result.Population.Rules, Length(fParams.Population.Rules));
    for var i := 0 to High(fParams.Population.Rules) do
    begin
      Result.Population.Rules[i].Chance := fParams.Population.Rules[i].Chance;
      Result.Population.Rules[i].Target := u_SimParams.TRuleTarget(Ord(fParams.Population.Rules[i].Target));
      Result.Population.Rules[i].Ratings := fParams.Population.Rules[i].Ratings;
    end;

    Result.Environment.DayDecayRate := fParams.Environment.DayDecayRate;
    Result.Environment.NightDecayRate := fParams.Environment.NightDecayRate;

    Result.Biomass.InjectionModes := [];
    if u_SessionParameters.bimOnDeath in fParams.Biomass.InjectionModes then
      Include(Result.Biomass.InjectionModes, u_SimParams.bimOnDeath);
    if u_SessionParameters.bimAtNightfall in fParams.Biomass.InjectionModes then
      Include(Result.Biomass.InjectionModes, u_SimParams.bimAtNightfall);
    if u_SessionParameters.bimRandom in fParams.Biomass.InjectionModes then
      Include(Result.Biomass.InjectionModes, u_SimParams.bimRandom);
    Result.Biomass.Density := fParams.Biomass.Density;
  end;

  procedure ApplySeedPolicy;
  begin
    if fParams.Seed <> 0 then
      RandSeed := fParams.Seed;
  end;
begin
  if not Assigned(aRuntime) then
    raise EArgumentNilException.Create('Runtime is required.');

  var simParams := BuildSimParams;

  ApplySeedPolicy;
  aRuntime.ConfigureBiomass(ResolveBiomassRuntimeConfig(fParams));

  var layout := TWorldLayout.Create(fParams.World, WorldLibrary);
  try
    var upscaler := TWorldUpscaler.Create(aRuntime.Environment, simParams);
    try
      upscaler.UpscaleWorld(layout);
    finally
      upscaler.Free;
    end;
  finally
    layout.Free;
  end;

  TWorldPopulator.Populate(aRuntime.Population, aRuntime.Environment, simParams);
end;


end.
