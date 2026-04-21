unit u_SimParams;

interface

uses u_BiologyTypes, u_EnvironmentTypes;

// used by the upscaler to configure the runtime

type
  TRuleTarget = (rtSmell, rtConverter);
  TRuleTargets = set of TRuleTarget;
  TPopulationRule = record
    Chance: Integer;               // if Random(100) <= Chance then
    Target: TRuleTarget;
    Ratings: TMoleculeRatings;
  end;

  // revisit this list for non-debugging value
  TPopulationScheme = (psAtZero, psOnSingleResource, psOnMultiResource, psOnBarren, psOnBarrenNextToResource, psOnBarrenCloseToResource);

  TSimParams = record
    Seed: Integer; // 0 = use current RTL seed; non-zero = force deterministic session seed
    Factor: Integer;
    DebugMode: Boolean;

    Population: record
      AgentCount: Integer;
      DOAChance: Integer;
      Rules: array of TPopulationRule;
      Scheme: TPopulationScheme;
    end;

    Environment: record
      DayDecayRate: TRating;
      NightDecayRate: TRating;
//      ExtraBiomass: Single;
    end;

    procedure InitDefaults;
  end;

implementation

procedure TSimParams.InitDefaults;
begin
  Seed := 0;
  Factor := 8;
  Population.AgentCount := 1;
  Population.DOAChance := 0;
  SetLength(Population.Rules, 0);

  Environment.DayDecayRate := Normal;
  Environment.NightDecayRate := Normal;
end;


end.
