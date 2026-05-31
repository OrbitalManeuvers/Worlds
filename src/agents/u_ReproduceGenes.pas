unit u_ReproduceGenes;

interface

uses u_AgentTypes, u_AgentGenome;

type
  TReproduceEvaluator = class(TReproduceEvalGene)
    class function Evaluate(const Input: TReproduceEvalInput; var Scratch: TReproduceEvalScratch): TActionEvalResult; override;
    class function MinimumAge: Integer; override;
  end;


implementation

uses System.Math,
  u_SimTypes, u_SimClocks, u_EnvironmentTypes;

const
  REPRO_MAX_SCORE = 0.25;
  REPRO_RESERVE_DELTA_RANGE = 0.15;
  REPRO_RECENT_COOLDOWN_TICKS = CLOCK_TICKS_PER_DAY * 7;
  REPRO_SETTLED_COOLDOWN_TICKS = 90;
  REPRO_LIGHT_CROWDING_PENALTY = 0.02;
  REPRO_MODERATE_CROWDING_PENALTY = 0.05;
  REPRO_HEAVY_CROWDING_PENALTY = 0.09;
  REPRO_MIN_AGE_TICKS = CLOCK_TICKS_PER_DAY * 5;

  // Persistence bonus ramps with commitment: more ticks remaining = stronger hold.
  // At max remaining ticks the agent is deeply committed; near zero it's almost done anyway.
  REPRO_PERSISTENCE_MIN_BONUS = 0.02;  // bonus when nearly complete (low ticks remaining)
  REPRO_PERSISTENCE_MAX_BONUS = 0.10;  // bonus when just started (high ticks remaining)

  // Nocturnal selfishness: agents that have learned to rely on delta become less
  // willing to invest energy in reproduction. Scales with how far above neutral (1.0)
  // the delta weight has drifted.
  REPRO_DELTA_SELFISHNESS_SCALE = 0.06;

{ TReproduceEvaluator }

class function TReproduceEvaluator.Evaluate(const Input: TReproduceEvalInput;
  var Scratch: TReproduceEvalScratch): TActionEvalResult;
begin
  Scratch := Default(TReproduceEvalScratch);
  Result.Score := 0.0;
  Result.Target.TType := ttNone;

  // Do not ask for reproduction when runtime would reject it on reserve floor alone.
  if Input.Reserves < REPRODUCTION_MIN_ATTEMPT_RESERVES then
    Exit;

  // Minimum age: juveniles cannot reproduce.
  if Input.Age < REPRO_MIN_AGE_TICKS then
    Exit;

  // Recent reproduction is a hard cooldown: do not even consider reproduction yet.
  if Input.TicksSinceReproduction < REPRO_RECENT_COOLDOWN_TICKS then
    Exit;

  // Continuous reserve pressure: negative when depleted, positive when well-fed.
  // Range: -0.20 (empty) to +0.12 (full), crossing zero around mid reserves.
  var energyPressure := EnsureRange(
    -0.20 + (Input.Reserves / 8.0) * 0.32,
    -0.20, 0.12);
  Result.Score := Result.Score + energyPressure;

  // ReserveDelta is a short-horizon body signal, not a learned history. Let a
  // declining reserve trend weigh more strongly than a rising trend helps.
  var reserveTrend := EnsureRange(Input.ReserveDelta / REPRO_RESERVE_DELTA_RANGE, -1.0, 1.0);
  if reserveTrend < 0.0 then
    Result.Score := Result.Score + (reserveTrend * 0.05)
  else
    Result.Score := Result.Score + (reserveTrend * 0.02);

  if Input.TicksSinceReproduction < REPRO_SETTLED_COOLDOWN_TICKS then
    Result.Score := Result.Score - 0.02
  else
    Result.Score := Result.Score + 0.02;

  // For MVP, solitude remains neutral and crowding only dampens reproduction pressure.
  // This keeps crowding as a score modifier without turning it into a hard behavioral gate.
  if Input.LocalAgentCount > 0 then
  begin
    if Input.LocalAgentCount <= 2 then
      Result.Score := Result.Score - REPRO_LIGHT_CROWDING_PENALTY
    else if Input.LocalAgentCount <= 4 then
      Result.Score := Result.Score - REPRO_MODERATE_CROWDING_PENALTY
    else
      Result.Score := Result.Score - REPRO_HEAVY_CROWDING_PENALTY;
  end;

  // Nocturnal selfishness: agents that have learned to rely on delta
  // become less willing to invest energy in reproduction.
  var deltaExcess := Max(0.0, Input.DeltaWeight - 1.0);
  var selfishnessPenalty := EnsureRange(deltaExcess * REPRO_DELTA_SELFISHNESS_SCALE, 0.0, REPRO_DELTA_SELFISHNESS_SCALE);
  Result.Score := Result.Score - selfishnessPenalty;

  if Input.CurrentAction = acReproduce then
  begin
    // Persistence bonus ramps with remaining commitment: deeply invested = stronger hold.
    // High TicksRemainingInGestation means just started — most committed, max bonus.
    // Low remaining means nearly done — modest bonus, almost there regardless.
    var denominator := Max(1, Input.GestationDuration);
    var commitmentRatio := EnsureRange(Input.TicksRemainingInGestation / denominator, 0.0, 1.0);
    var persistenceBonus := REPRO_PERSISTENCE_MIN_BONUS +
      (commitmentRatio * (REPRO_PERSISTENCE_MAX_BONUS - REPRO_PERSISTENCE_MIN_BONUS));
    Result.Score := Result.Score + persistenceBonus;
  end;

  Result.Score := EnsureRange(Result.Score, 0.0, REPRO_MAX_SCORE);
end;

class function TReproduceEvaluator.MinimumAge: Integer;
begin
  Result := REPRO_MIN_AGE_TICKS;
end;

initialization
  GlobalGeneRegistry.RegisterGene(TReproduceEvaluator);

end.
