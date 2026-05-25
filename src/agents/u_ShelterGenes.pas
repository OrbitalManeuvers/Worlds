unit u_ShelterGenes;

interface

uses u_AgentTypes, u_AgentGenome, u_SimQueriesIntf;

type
  TShelterEvaluator = class(TShelterEvalGene)
  public
    class function Evaluate(const Input: TShelterEvalInput; var Scratch: TShelterEvalScratch): TActionEvalResult; override;
  end;


implementation

uses System.Math;

const
  SHELTER_RESERVE_COMFORT_LEVEL = 5.0;
  SHELTER_RESERVE_PRESSURE = 0.12;
  SHELTER_POSITIVE_DELTA_RANGE = 0.12;
  SHELTER_POSITIVE_DELTA_RELIEF = 0.10;
  SHELTER_NEGATIVE_DELTA_GRACE = 0.05;
  SHELTER_NEGATIVE_DELTA_RANGE = 0.20;
  SHELTER_NEGATIVE_DELTA_PRESSURE = 0.05;
  SHELTER_ENTRY_SCORE_PENALTY = 0.04;
  SHELTER_PERSISTENCE_BONUS = 0.04;

  // While reproducing, shelter pressure is suppressed — the agent is committed.
  // Suppression lifts entirely if reserves fall below the critical floor (near-death panic).
  SHELTER_REPRODUCE_SUPPRESSION = 0.75;
  SHELTER_REPRODUCE_CRITICAL_FLOOR = 1.5;

  // When solar flux is zero, the environment is offering nothing — resting is rational.
  // The bonus scales with how far reserves have fallen below a comfortable ceiling,
  // so a well-fed agent stays idle longer and only shelter pressure builds as
  // reserves deplete. Not a hard night rule — high drain or low reserves still win.
  SHELTER_NO_SOLAR_CEILING = 8.0;   // reserves above this: no bonus
  SHELTER_NO_SOLAR_MAX_BONUS = 0.06; // full bonus at zero reserves

  // Minimum score shelter must reach before it can win. Prevents the no-solar
  // nudge from triggering shelter on a well-fed agent with negligible drain.
  SHELTER_MIN_VOTE_SCORE = 0.01;

{ TBasicShelter }

class function TShelterEvaluator.Evaluate(const Input: TShelterEvalInput; var Scratch: TShelterEvalScratch): TActionEvalResult;
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
  // Purposeful actions (forage, move) resist shelter interruption.
  // Idle and wander are low-commitment — shelter can compete freely from those states.
  // Shelter itself gets a persistence bonus to hold while reserves recover.
  if Input.CurrentAction in [acForage, acMove] then
    Result.Score := Result.Score - SHELTER_ENTRY_SCORE_PENALTY
  else if Input.CurrentAction = acShelter then
    Result.Score := Result.Score + SHELTER_PERSISTENCE_BONUS;
  // acIdle, acWander: no modifier — shelter competes on its own merits

  // While reproducing, suppress shelter pressure — the agent is committed to gestation.
  // The panic switch lifts suppression when reserves are critically low.
  if (Input.CurrentAction = acReproduce) and (Input.Reserves > SHELTER_REPRODUCE_CRITICAL_FLOOR) then
    Result.Score := Result.Score * (1.0 - SHELTER_REPRODUCE_SUPPRESSION);

  // Require a minimum score before shelter can win — prevents the no-solar nudge
  // from triggering shelter on a well-fed agent with negligible drain.
  if Result.Score < SHELTER_MIN_VOTE_SCORE then
    Result.Score := 0.0;

  Result.Score := EnsureRange(Result.Score, 0.0, 0.35);
  Result.Target.TType := ttNone;

end;

initialization
  GlobalGeneRegistry.RegisterGene(TShelterEvaluator);

end.
