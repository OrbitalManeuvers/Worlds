unit u_WanderGenes;

interface

uses u_AgentTypes, u_AgentGenome;

type
  TWanderEvaluator = class(TWanderEvalGene)
    class function Evaluate(const Input: TWanderEvalInput; var Scratch: TWanderEvalScratch): TActionEvalResult; override;
  end;

implementation

uses System.Math,
  u_SimTypes, u_SimClocks;

const
  WANDER_MAX_SCORE = 0.30;
  WANDER_MIN_VOTE_SCORE = 0.02;
  WANDER_RESERVE_COMFORT_LEVEL = 8.0;  // above this, wander urgency fades
  WANDER_RESERVE_PRESSURE = 0.10;      // max contribution from low reserves
  WANDER_RESERVE_DELTA_RANGE = 0.15;
  WANDER_FORAGE_TICKS_RANGE = CLOCK_TICKS_PER_DAY;

  // Action context modifiers.
  // Sheltering: resting agent should not wander without real pressure.
  // Foraging: eating right now — wander should not interrupt a meal.
  // Already moving: small persistence bonus — keep going.
  WANDER_SHELTER_PENALTY   = 0.05;
  WANDER_FORAGE_PENALTY    = 0.04;
  WANDER_PERSISTENCE_BONUS = 0.015;

  // When solar flux is zero and there's no smell signal, movement has no expected
  // payoff — reduce wander urgency so shelter can compete.
  // Penalty scales with reserve depletion to mirror the shelter bonus shape.
  // Does not apply when already moving toward a committed wander target.
  WANDER_NO_SOLAR_CEILING     = 8.0;
  WANDER_NO_SOLAR_MAX_PENALTY = 0.06;

  // Recently-fed suppression: if the agent ate within this many ticks, wander is
  // heavily penalized. The food source is likely still here and will regrow — don't
  // walk away from a known resource just because the cache is momentarily depleted.
  WANDER_RECENT_FORAGE_TICKS = 3;
  WANDER_RECENT_FORAGE_PENALTY = 0.20;

{ TWanderEvaluator }

class function TWanderEvaluator.Evaluate(const Input: TWanderEvalInput; var Scratch: TWanderEvalScratch): TActionEvalResult;
begin
  Scratch := Default(TWanderEvalScratch);
  Result := Default(TActionEvalResult);
  Result.Score := 0.0;
  Result.Target.TType := ttNone;

  // Wander is the "no remote smell" movement pressure. If there's a remote smell
  // signal worth chasing, the smell-follow move evaluator should dominate instead.
  if Input.HasRemoteSmellSignal then
    Exit;

  // An agent in gestation does not wander — no score, no target.
  if Input.CurrentAction = acReproduce then
    Exit;

  // Continuous reserve pressure: wander is a desperation move.
  // Low reserves push urgency up; comfortable reserves let other actions compete.
  var reservePressure := EnsureRange(
    1.0 - (Input.Reserves / WANDER_RESERVE_COMFORT_LEVEL),
    0.0, 1.0);
  Result.Score := Result.Score + (reservePressure * WANDER_RESERVE_PRESSURE);

  // Negative ReserveDelta means the agent is losing ground — adds urgency on top of level.
  var reserveTrend := EnsureRange((-Input.ReserveDelta) / WANDER_RESERVE_DELTA_RANGE, 0.0, 1.0);
  Result.Score := Result.Score + (reserveTrend * 0.08);

  var foragePressure := EnsureRange(Input.TicksSinceForage / WANDER_FORAGE_TICKS_RANGE, 0.0, 1.0);
  Result.Score := Result.Score + (foragePressure * 0.12);

  // Action context shapes entry friction.
  // Sheltering and foraging resist wander interruption.
  // Already moving: small persistence bonus — keep going.
  // Idle: no modifier — wander competes freely.
  case Input.CurrentAction of
    acShelter: Result.Score := Result.Score - WANDER_SHELTER_PENALTY;
    acForage:  Result.Score := Result.Score - WANDER_FORAGE_PENALTY;
    acMove:    Result.Score := Result.Score + WANDER_PERSISTENCE_BONUS;
  end;

  // No solar income and no food signal: movement has no expected payoff.
  // Penalty scales with reserve depletion — mirrors the shelter bonus shape so
  // the two signals stay balanced as reserves fall.
  // Does not apply when already moving toward a committed wander target.
  if (Input.SolarFlux <= 0.0) and (Input.CurrentAction <> acMove) then
  begin
    var noSolarPressure := EnsureRange(
      1.0 - (Input.Reserves / WANDER_NO_SOLAR_CEILING),
      0.0, 1.0);
    Result.Score := Result.Score - (noSolarPressure * WANDER_NO_SOLAR_MAX_PENALTY);
  end;

  // Recently-fed suppression: don't wander away from a food source that just fed you.
  // The cache will likely regrow within a few ticks — stay put.
  if Input.TicksSinceForage <= WANDER_RECENT_FORAGE_TICKS then
    Result.Score := Result.Score - WANDER_RECENT_FORAGE_PENALTY;

  // Future: TicksSinceShelter as a fatigue-based suppression amplifier.
  // Unlike TicksSinceForage (which drives wander *toward* food), shelter deprivation
  // should *dampen* wander — an exhausted agent shouldn't keep running around.
  // Two possible uses:
  //   1. Scale the existing WANDER_SHELTER_PENALTY higher when TicksSinceShelter is
  //      large — "you finally lay down after 200 ticks, absolutely do not get up."
  //   2. Apply a fatigue ceiling that reduces max wander score as time-without-rest
  //      grows, creating soft indirect pressure toward shelter by making the competing
  //      action less appealing.
  // The positive pressure to shelter belongs in the shelter evaluator; here we only
  // reduce wander's competitiveness so the shelter signal can win.

  Result.Score := EnsureRange(Result.Score, 0.0, WANDER_MAX_SCORE);

  if Result.Score < WANDER_MIN_VOTE_SCORE then
  begin
    Result.Score := 0.0;
    Exit;
  end;

  Result.Target.TType := ttWander;
end;

initialization
  GlobalGeneRegistry.RegisterGene(TWanderEvaluator);

end.
