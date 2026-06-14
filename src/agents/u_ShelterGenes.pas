unit u_ShelterGenes;

interface

uses u_AgentTypes, u_AgentGenome, u_SimQueriesIntf;

type
  // Gen A: instinctive shelter — circadian cycle, darkness, and lack of food signal dominate.
  // A less evolved agent that hides at night because it can't reason about energy trends.
  TShelterEvaluator = class(TShelterEvalGene)
  public
    class function Evaluate(const Input: TShelterEvalInput; var Scratch: TShelterEvalScratch): TActionEvalResult; override;
  end;

  // Gen B: energy-aware shelter — driven by reserve economics.
  // Darkness is a mild nudge, not a command. Allows nocturnal activity when food is available.
  TEnergyShelterEvaluator = class(TShelterEvalGene)
  public
    class function GetGenerationCode: Char; override;
    class function Evaluate(const Input: TShelterEvalInput; var Scratch: TShelterEvalScratch): TActionEvalResult; override;
  end;


implementation

uses System.Math, u_Instincts, u_SimTypes;

const

  // === Gen B: energy-aware shelter constants ===
  SHELTER_RESERVE_COMFORT_LEVEL = 5.0;
  SHELTER_RESERVE_PRESSURE = 0.12;
  SHELTER_POSITIVE_DELTA_RANGE = 0.12;
  SHELTER_POSITIVE_DELTA_RELIEF = 0.10;
  SHELTER_NEGATIVE_DELTA_GRACE = 0.05;
  SHELTER_NEGATIVE_DELTA_RANGE = 0.20;
  SHELTER_NEGATIVE_DELTA_PRESSURE = 0.05;

  SHELTER_NO_SOLAR_CEILING = 8.0;
  SHELTER_NO_SOLAR_MAX_BONUS = 0.06;

  SHELTER_MIN_VOTE_SCORE = 0.01;

{ TShelterEvaluator — Gen A: instinctive }
class function TShelterEvaluator.Evaluate(const Input: TShelterEvalInput; var Scratch: TShelterEvalScratch): TActionEvalResult;
begin
  Scratch := Default(TShelterEvalScratch);
  Result.Score := 0.0;

  // think in terms of [0 - 1] scores.
  // 0.5 means "This action is about 50% urgent right now"
  // 1.0 means "I can't need this action any more than I need it right now"
  // A full range gives control back to congnition

  // Removed: energy panic. This is negative voting based on someone else's criteria, and it's
  // not an honest evaluation of our need to sleep - MY ONE JOB.

  // this generation considers the darkness a good sign to sleep
  if Input.SolarFlux <= 0.2 then
    Result.Score := Result.Score + Instinct.DARKNESS_DISCOMFORT;

  // No food signal reinforces the instinct — nothing to do out here.
  if not Input.HasLocalFoodSignal then
    Result.Score := Result.Score + Instinct.NO_FOOD_SLEEP_BONUS;

  // The agent's own circadian cycle is the primary driver.
  // Express pressure as a percentage of the global max [0.0 .. 1.0].
  var fatigue := EnsureRange(Input.CircadianPressure / MAX_CIRCADIAN_PRESSURE, 0.0, 1.0);
  Result.Score := Result.Score + fatigue;

  // clean up the result
  Result.Score := EnsureRange(Result.Score, 0.0, 1.0);
  Result.Target.TType := ttNone;
end;

{ TEnergyShelterEvaluator — Gen B: energy-aware }

class function TEnergyShelterEvaluator.GetGenerationCode: Char;
begin
  Result := 'B';
end;

class function TEnergyShelterEvaluator.Evaluate(const Input: TShelterEvalInput; var Scratch: TShelterEvalScratch): TActionEvalResult;
begin
  Scratch := Default(TShelterEvalScratch);
  Result.Score := 0.0;

  var reserves := Max(Input.Reserves, 0.0);
  var reservePressure := EnsureRange(
    (SHELTER_RESERVE_COMFORT_LEVEL - reserves) / SHELTER_RESERVE_COMFORT_LEVEL,
    0.0,
    1.0);
  var positiveRecovery := EnsureRange(Input.ReserveDelta / SHELTER_POSITIVE_DELTA_RANGE, 0.0, 1.0);
  var negativeDrain := EnsureRange(
    ((-Input.ReserveDelta) - SHELTER_NEGATIVE_DELTA_GRACE) / SHELTER_NEGATIVE_DELTA_RANGE,
    0.0,
    1.0);

  // Shelter should be driven primarily by reserve state, not by darkness.
  Result.Score := Result.Score + (reservePressure * SHELTER_RESERVE_PRESSURE);
  Result.Score := Result.Score - (positiveRecovery * SHELTER_POSITIVE_DELTA_RELIEF);
  Result.Score := Result.Score + (negativeDrain * SHELTER_NEGATIVE_DELTA_PRESSURE);

  // No solar income: the environment is offering nothing right now.
  // Bonus scales with reserve depletion — a well-fed agent barely feels it,
  // a hungry one gets a meaningful push toward rest.
  if Input.SolarFlux <= 0.0 then
  begin
    var noSolarPressure := EnsureRange(
      1.0 - (reserves / SHELTER_NO_SOLAR_CEILING),
      0.0, 1.0);
    Result.Score := Result.Score + (noSolarPressure * SHELTER_NO_SOLAR_MAX_BONUS);
  end;

  if Result.Score < SHELTER_MIN_VOTE_SCORE then
    Result.Score := 0.0;

  Result.Score := EnsureRange(Result.Score, 0.0, 1.0);
  Result.Target.TType := ttNone;
end;

initialization
  GlobalGeneRegistry.RegisterGene(TShelterEvaluator);
  GlobalGeneRegistry.RegisterGene(TEnergyShelterEvaluator);

end.
