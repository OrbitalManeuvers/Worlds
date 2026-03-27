unit u_SimParams;

interface

uses u_BiologyTypes, u_EnvironmentTypes;

// used by the upscaler to configure the runtime

type
  TRuleTarget = (rtSmell, rtVision);
  TPopulationRule = record
    Chance: Integer;               // if Random(100) <= Chance then
    Target: TRuleTarget;
    Ratings: TMoleculeRatings;
  end;

  TSimParams = record

    Factor: Integer;

    Population: record
      AgentCount: Integer;
      DOAChance: Integer;
      Rules: array of TPopulationRule;
    end;

    Environment: record
      DayDecayRate: TRating;
      NightDecayRate: TRating;
//    ExtraBiomass: Single;
    end;

    procedure InitDefaults;
  end;

implementation

procedure TSimParams.InitDefaults;
begin
  Factor := 8;
  Population.AgentCount := 1;
  Population.DOAChance := 0;
  SetLength(Population.Rules, 0);

  Environment.DayDecayRate := Normal;
  Environment.NightDecayRate := Normal;
end;


end.
