unit u_WanderGenes;

interface

uses u_AgentTypes, u_AgentGenome;

type
  TWanderEvaluator = class(TWanderEvalGene)
    class function Evaluate(const Input: TWanderEvalInput; var Scratch: TWanderEvalScratch): TActionEvalResult; override;
  end;

implementation

uses System.Math, u_SimClocks;

const
  WANDER_MAX_SCORE = 0.30;
  WANDER_MIN_VOTE_SCORE = 0.02;
  WANDER_RESERVE_DELTA_RANGE = 0.15;
  WANDER_FORAGE_TICKS_RANGE = CLOCK_TICKS_PER_DAY;

{ TWanderEvaluator }

class function TWanderEvaluator.Evaluate(const Input: TWanderEvalInput; var Scratch: TWanderEvalScratch): TActionEvalResult;
begin
  Scratch := Default(TWanderEvalScratch);
  Result := Default(TActionEvalResult);
  Result.Score := 0.0;
  Result.Target.TType := ttNone;

  // Wander is the "no local smell" movement pressure. If smell is present,
  // the smell-follow move evaluator should dominate move scoring.
  if Input.HasSmellSignal then
    Exit;

  case Input.EnergyLevel of
    elEmpty:
      Result.Score := Result.Score + 0.14;
    elLow:
      Result.Score := Result.Score + 0.10;
    elMedium:
      Result.Score := Result.Score + 0.05;
    elHigh:
      Result.Score := Result.Score + 0.01;
    elFull:
      ;
  end;

  // Negative ReserveDelta means the agent is losing ground.
  var reserveTrend := EnsureRange((-Input.ReserveDelta) / WANDER_RESERVE_DELTA_RANGE, 0.0, 1.0);
  Result.Score := Result.Score + (reserveTrend * 0.08);

  var foragePressure := EnsureRange(Input.TicksSinceForage / WANDER_FORAGE_TICKS_RANGE, 0.0, 1.0);
  Result.Score := Result.Score + (foragePressure * 0.12);

  if Input.CurrentAction = acMove then
    Result.Score := Result.Score + 0.015;

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
