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
  REPRO_RESERVE_BASELINE = 5.0;
  REPRO_RESERVE_RANGE = 5.0;
  REPRO_RECENT_COOLDOWN_TICKS = CLOCK_TICKS_PER_DAY;
  REPRO_SETTLED_COOLDOWN_TICKS = 90;

{ TReproduceEvaluator }

class function TReproduceEvaluator.Evaluate(const Input: TReproduceEvalInput;
  var Scratch: TReproduceEvalScratch): TActionEvalResult;
begin
  Scratch := Default(TReproduceEvalScratch);
  Result.Score := 0.0;
  Result.Target.TType := ttNone;

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

  if Input.TicksSinceReproduction < REPRO_SETTLED_COOLDOWN_TICKS then
    Result.Score := Result.Score - 0.02
  else
    Result.Score := Result.Score + 0.02;

  // First social-pressure pass: isolation increases reproduction pull; heavy crowding dampens it.
  if Input.LocalAgentCount <= 0 then
    Result.Score := Result.Score + 0.08
  else if Input.LocalAgentCount <= 2 then
    Result.Score := Result.Score + 0.06
  else if Input.LocalAgentCount <= 4 then
    Result.Score := Result.Score + 0.02
  else
    Result.Score := Result.Score - 0.06;

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
