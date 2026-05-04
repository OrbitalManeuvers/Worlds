unit u_BiomassConfigResolvers;

interface

uses
  u_BiologyTypes,
  u_EnvironmentTypes,
  u_SimRuntimes,
  u_SimParams,
  u_SessionParameters;

function ResolveBiomassRuntimeConfig(const Params: TSimParams): TBiomassRuntimeConfig; overload;
function ResolveBiomassRuntimeConfig(const Params: TSessionParameters): TBiomassRuntimeConfig; overload;

implementation

const
  NIGHTFALL_CACHE_COUNT: array[TRating] of Integer = (0, 1, 2, 4, 8, 16, 32);
  RANDOM_INJECT_CHANCE: array[TRating] of Integer = (0, 1, 3, 6, 10, 18, 30);

function ResolveBiomassRuntimeConfig(const Params: TSimParams): TBiomassRuntimeConfig;
begin
  Result.InjectOnDeath := u_SimParams.bimOnDeath in Params.Biomass.InjectionModes;
  Result.InjectAtNightfall := u_SimParams.bimAtNightfall in Params.Biomass.InjectionModes;
  Result.InjectRandomlyAtNight := u_SimParams.bimRandom in Params.Biomass.InjectionModes;
  Result.NightfallCacheCount := NIGHTFALL_CACHE_COUNT[Params.Biomass.Density];
  Result.RandomInjectChancePercent := RANDOM_INJECT_CHANCE[Params.Biomass.Density];
end;

function ResolveBiomassRuntimeConfig(const Params: TSessionParameters): TBiomassRuntimeConfig;
begin
  Result.InjectOnDeath := u_SessionParameters.bimOnDeath in Params.Biomass.InjectionModes;
  Result.InjectAtNightfall := u_SessionParameters.bimAtNightfall in Params.Biomass.InjectionModes;
  Result.InjectRandomlyAtNight := u_SessionParameters.bimRandom in Params.Biomass.InjectionModes;
  Result.NightfallCacheCount := NIGHTFALL_CACHE_COUNT[Params.Biomass.Density];
  Result.RandomInjectChancePercent := RANDOM_INJECT_CHANCE[Params.Biomass.Density];
end;

end.
