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

  Result.Score := EnsureRange(Result.Score, 0.0, 0.35);
  Result.Target.TType := ttNone;

end;

initialization
  GlobalGeneRegistry.RegisterGene(TShelterEvaluator);

end.
