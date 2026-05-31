unit u_ShelterGenes;

interface

uses u_AgentTypes, u_AgentGenome, u_SimQueriesIntf;

type
  // Gen A: instinctive shelter — darkness and lack of food signal dominate.
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

uses System.Math;

const
  // === Gen A: instinctive shelter constants ===

  // Darkness is the primary driver for gen-A shelter.
  INSTINCT_NO_SOLAR_BASE_BONUS = 0.12;     // strong push toward shelter when dark
  INSTINCT_NO_FOOD_SIGNAL_BONUS = 0.08;    // no food nearby reinforces "hide" instinct
  INSTINCT_FOOD_SIGNAL_RELIEF = 0.06;      // food nearby suppresses shelter even at night

  // Sunlight actively discourages shelter — the sun is up, time to be active.
  INSTINCT_SOLAR_WAKE_PRESSURE = 0.10;     // penalty to shelter score when sun is shining

  // Reserve pressure still contributes but is secondary.
  INSTINCT_RESERVE_COMFORT_LEVEL = 5.0;
  INSTINCT_RESERVE_PRESSURE = 0.06;

  // Panic: if reserves drop below this floor, shelter is forced to zero.
  // The agent must do something or die — staying asleep is not an option.
  INSTINCT_PANIC_FLOOR = 1.5;

  // Action context
  INSTINCT_ENTRY_PENALTY = 0.04;
  INSTINCT_PERSISTENCE_BONUS = 0.04;
  INSTINCT_MIN_VOTE_SCORE = 0.01;

  // Reproduction suppression (shared concept)
  INSTINCT_REPRODUCE_SUPPRESSION = 0.75;
  INSTINCT_REPRODUCE_CRITICAL_FLOOR = 1.5;

  // === Gen B: energy-aware shelter constants ===

  SHELTER_RESERVE_COMFORT_LEVEL = 5.0;
  SHELTER_RESERVE_PRESSURE = 0.12;
  SHELTER_POSITIVE_DELTA_RANGE = 0.12;
  SHELTER_POSITIVE_DELTA_RELIEF = 0.10;
  SHELTER_NEGATIVE_DELTA_GRACE = 0.05;
  SHELTER_NEGATIVE_DELTA_RANGE = 0.20;
  SHELTER_NEGATIVE_DELTA_PRESSURE = 0.05;
  SHELTER_ENTRY_SCORE_PENALTY = 0.04;
  SHELTER_PERSISTENCE_BONUS = 0.04;

  SHELTER_REPRODUCE_SUPPRESSION = 0.75;
  SHELTER_REPRODUCE_CRITICAL_FLOOR = 1.5;

  SHELTER_NO_SOLAR_CEILING = 8.0;
  SHELTER_NO_SOLAR_MAX_BONUS = 0.06;

  SHELTER_MIN_VOTE_SCORE = 0.01;

{ TShelterEvaluator — Gen A: instinctive }

class function TShelterEvaluator.Evaluate(const Input: TShelterEvalInput; var Scratch: TShelterEvalScratch): TActionEvalResult;
begin
  Scratch := Default(TShelterEvalScratch);
  Result.Score := 0.0;

  var reserves := Max(Input.Reserves, 0.0);

  // Panic switch: if reserves are critically low, shelter is not an option.
  // The agent must act or die.
  if reserves < INSTINCT_PANIC_FLOOR then
  begin
    Result.Score := 0.0;
    Result.Target.TType := ttNone;
    Exit;
  end;

  // Darkness is the primary shelter trigger for an instinctive agent.
  if Input.SolarFlux <= 0.0 then
  begin
    Result.Score := Result.Score + INSTINCT_NO_SOLAR_BASE_BONUS;

    // No food signal reinforces the instinct — nothing to do out here.
    if not Input.HasLocalFoodSignal then
      Result.Score := Result.Score + INSTINCT_NO_FOOD_SIGNAL_BONUS;
  end
  else
  begin
    // Sunlight actively discourages shelter — the sun is up, time to be active.
    Result.Score := Result.Score - INSTINCT_SOLAR_WAKE_PRESSURE;
  end;

  // Food signal suppresses shelter even at night — something worth staying up for.
  if Input.HasLocalFoodSignal then
    Result.Score := Result.Score - INSTINCT_FOOD_SIGNAL_RELIEF;

  // Reserve pressure is secondary but still present — a starving agent shelters harder.
  var reservePressure := EnsureRange(
    (INSTINCT_RESERVE_COMFORT_LEVEL - reserves) / INSTINCT_RESERVE_COMFORT_LEVEL,
    0.0, 1.0);
  Result.Score := Result.Score + (reservePressure * INSTINCT_RESERVE_PRESSURE);

  // Action context: purposeful actions resist interruption.
  if Input.CurrentAction in [acForage, acMove] then
    Result.Score := Result.Score - INSTINCT_ENTRY_PENALTY
  else if Input.CurrentAction = acShelter then
    Result.Score := Result.Score + INSTINCT_PERSISTENCE_BONUS;

  // Reproduction suppression.
  if (Input.CurrentAction = acReproduce) and (Input.Reserves > INSTINCT_REPRODUCE_CRITICAL_FLOOR) then
    Result.Score := Result.Score * (1.0 - INSTINCT_REPRODUCE_SUPPRESSION);

  if Result.Score < INSTINCT_MIN_VOTE_SCORE then
    Result.Score := 0.0;

  Result.Score := EnsureRange(Result.Score, 0.0, 0.35);
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

  // Entry friction is tiered by how purposeful the current action is.
  if Input.CurrentAction in [acForage, acMove] then
    Result.Score := Result.Score - SHELTER_ENTRY_SCORE_PENALTY
  else if Input.CurrentAction = acShelter then
    Result.Score := Result.Score + SHELTER_PERSISTENCE_BONUS;

  // While reproducing, suppress shelter pressure — the agent is committed to gestation.
  if (Input.CurrentAction = acReproduce) and (Input.Reserves > SHELTER_REPRODUCE_CRITICAL_FLOOR) then
    Result.Score := Result.Score * (1.0 - SHELTER_REPRODUCE_SUPPRESSION);

  if Result.Score < SHELTER_MIN_VOTE_SCORE then
    Result.Score := 0.0;

  Result.Score := EnsureRange(Result.Score, 0.0, 0.35);
  Result.Target.TType := ttNone;
end;

initialization
  GlobalGeneRegistry.RegisterGene(TShelterEvaluator);
  GlobalGeneRegistry.RegisterGene(TEnergyShelterEvaluator);

end.
