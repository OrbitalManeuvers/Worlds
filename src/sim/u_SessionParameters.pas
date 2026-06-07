unit u_SessionParameters;

interface

uses System.Types, u_BiologyTypes, u_EnvironmentTypes, u_Worlds;

type
  TSessionType = (stStandard, stDebug);
  TScratchBackend = (sbDefault, sbMappedFile, sbLocalMemory);

  TCommonSessionParameters = record
    SessionType: TSessionType;
    SessionTitle: string;
    SessionLogFile: string;
    SessionTOCFile: string;
    ScratchFolder: string;
    ScratchBackend: TScratchBackend;
  end;

  { TUpscalerParameters - parameters for a normal (upscaled) session }

  TRuleTarget = (rtSmell, rtConverter);
  TRuleTargets = set of TRuleTarget;
  TPopulationRule = record
    Chance: Integer;               // if Random(100) <= Chance then
    Target: TRuleTarget;
    Ratings: TMoleculeRatings;
  end;

  // revisit this list for non-debugging value
  TPopulationScheme = (psAtZero, psOnSingleResource, psOnMultiResource, psOnBarren,
    psOnBarrenNextToResource, psOnBarrenCloseToResource, psGrouped);

  TUpscalerParameters = record
    World: TWorld;    // the world to upscale
    Seed: Integer;    // 0 = use current RTL seed; non-zero = force deterministic session seed
    Factor: Integer;

    Population: record
      AgentCount: Integer;
      DOAChance: Integer;
      Rules: array of TPopulationRule;
      Scheme: TPopulationScheme;
      AgentActivationTick: Integer;  // 0 = activate from tick 1 (default)
      GroupRect: TRect;
    end;

    Environment: record
      DayDecayRate: TRating;
      NightDecayRate: TRating;
    end;

    procedure InitDefaults;
  end;

  TDebugSessionParameters = record
    ScenarioName: string;
  end;


  TSimLaunchRequest = record
    CommonParams: TCommonSessionParameters;
    SessionType: TSessionType;
    StandardParams: TUpscalerParameters;
    DebugParams: TDebugSessionParameters;
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


//  Delta.Enabled := False;
//  Delta.Density := Normal;
//  Delta.InitialAmount := 1.0;
//  Delta.CycleLength := 3;
//  Delta.MinSpacingCells := 4;
//  Delta.CleanupGraceTicks := 0;
end;

end.
