unit u_SessionParameters;

interface

uses System.Types, u_BiologyTypes, u_EnvironmentTypes, u_Worlds;

type
  TSessionType = (stStandard, stDebug);

  TCommonSessionParameters = record
    SessionType: TSessionType;
    SessionName: string;
    SessionLogFile: string;
    ScratchFolder: string;
  end;

  { TUpscalerParameters - parameters for a normal (upscaled) session }

  TBiomassInjectionMode = (bimOnDeath, bimAtNightfall, bimRandom);
  TBiomassInjectionModes = set of TBiomassInjectionMode;

  TRuleTarget = (rtSmell, rtConverter);
  TRuleTargets = set of TRuleTarget;
  TPopulationRule = record
    Chance: Integer;               // if Random(100) <= Chance then
    Target: TRuleTarget;
    Ratings: TMoleculeRatings;
  end;

  // revisit this list for non-debugging value
  TPopulationScheme = (psAtZero, psOnSingleResource, psOnMultiResource, psOnBarren, psOnBarrenNextToResource, psOnBarrenCloseToResource);

  TUpscalerParameters = record
    World: TWorld;    // the world to upscale
    Seed: Integer;    // 0 = use current RTL seed; non-zero = force deterministic session seed
    Factor: Integer;

    Population: record
      AgentCount: Integer;
      DOAChance: Integer;
      Rules: array of TPopulationRule;
      Scheme: TPopulationScheme;
    end;

    Environment: record
      DayDecayRate: TRating;
      NightDecayRate: TRating;
    end;

    Biomass: record
      InjectionModes: TBiomassInjectionModes;
      Density: TRating;
    end;

    procedure InitDefaults;
  end;

  TDebugSessionParameters = record
    ScenarioName: string;
  end;


implementation

{ TUpscalerParameters }

procedure TUpscalerParameters.InitDefaults;
begin
  Seed := 0;
  Factor := 8;
  Population.AgentCount := 1;
  Population.DOAChance := 0;
  SetLength(Population.Rules, 0);

  Environment.DayDecayRate := Normal;
  Environment.NightDecayRate := Normal;

  Biomass.InjectionModes := [bimOnDeath];
  Biomass.Density := Normal;
end;

end.
