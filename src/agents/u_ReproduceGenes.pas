unit u_ReproduceGenes;

interface

uses u_AgentTypes, u_AgentGenome;

type
  TReproduceEvaluator = class(TReproduceEvalGene)
    class function Evaluate(const Input: TReproduceEvalInput; var Scratch: TReproduceEvalScratch): TActionEvalResult; override;
  end;


implementation

uses System.Math, u_SimClocks;

const
  REPRO_MAX_SCORE = 0.25;
  REPRO_RESERVE_BASELINE = REPRODUCTION_MIN_ATTEMPT_RESERVES;
  REPRO_RESERVE_RANGE = 4.0;
  REPRO_RESERVE_DELTA_RANGE = 0.15;
  REPRO_RECENT_COOLDOWN_TICKS = CLOCK_TICKS_PER_DAY;
  REPRO_SETTLED_COOLDOWN_TICKS = 90;
  REPRO_LIGHT_CROWDING_PENALTY = 0.02;
  REPRO_MODERATE_CROWDING_PENALTY = 0.05;
  REPRO_HEAVY_CROWDING_PENALTY = 0.09;

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

  // Recent reproduction is a hard cooldown: do not even consider reproduction yet.
  if Input.TicksSinceReproduction < REPRO_RECENT_COOLDOWN_TICKS then
    Exit;

  case Input.EnergyLevel of
    elEmpty:
      Result.Score := Result.Score - 0.20;
    elLow:
      Result.Score := Result.Score - 0.06;
    elMedium:
      Result.Score := Result.Score + 0.03;
    elHigh:
      Result.Score := Result.Score + 0.08;
    elFull:
      Result.Score := Result.Score + 0.12;
  end;

  // Energy buckets provide the coarse band; exact reserves refine pressure within that band.
  var reserveHeadroom := EnsureRange(
    (Input.Reserves - REPRO_RESERVE_BASELINE) / REPRO_RESERVE_RANGE,
    -1.0,
    1.0
  );
  Result.Score := Result.Score + (reserveHeadroom * 0.04);

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

  // Keep nighttime pressure slightly lower until explicit mating/safety constraints exist.
  if Input.IsNight then
    Result.Score := Result.Score - 0.02;

  if Input.CurrentAction = acReproduce then
    Result.Score := Result.Score + 0.03;

  Result.Score := EnsureRange(Result.Score, 0.0, REPRO_MAX_SCORE);
end;

initialization
  GlobalGeneRegistry.RegisterGene(TReproduceEvaluator);

end.
