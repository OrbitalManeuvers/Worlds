unit u_ShelterGenes;

interface

uses u_SimTypes, u_GeneTypes, u_RuntimeTypes, u_BrainTypes, u_SimQueriesIntf;

type
  // Gen A: primarily circadian cycle-driven
  TShelterEvaluator = class(TShelterEvalGene)
  public
    class function Evaluate(const Input: TShelterEvalInput; var Scratch: TShelterEvalScratch): TActionScore; override;
  end;


implementation

uses System.Math, u_Instincts, u_AgentGenome;

{ TShelterEvaluator — Gen A: circadian cycle-driven }
class function TShelterEvaluator.Evaluate(const Input: TShelterEvalInput; var Scratch: TShelterEvalScratch): TActionScore;
begin
  Scratch := Default(TShelterEvalScratch);
  Result := 0.0;

  // think in terms of [0 - 1] scores.
  // 0.5 means "This action is about 50% urgent right now"
  // 1.0 means "I can't need this action any more than I need it right now"
  // A full range gives control back to congnition

  // Removed: energy panic. This is negative voting based on someone else's criteria, and it's
  // not an honest evaluation of our need to sleep - MY ONE JOB.

  // this generation considers the darkness a good sign to sleep
  if Input.SolarFlux <= 0.2 then
    Result := Result + Instinct.DARKNESS_DISCOMFORT;

  // No food signal reinforces the instinct — nothing to do out here.
  if not Input.HasLocalFoodSignal then
    Result := Result + Instinct.NO_FOOD_SLEEP_BONUS;

  // The agent's own circadian cycle is the primary driver.
  // Fatigue is imperceptible for the majority of the cycle, then ramps steeply.
  var rawFatigue := EnsureRange(Input.CircadianPressure / MAX_CIRCADIAN_PRESSURE, 0.0, 1.0);

  var fatigue: Single;
  if rawFatigue < Instinct.FATIGUE_ONSET then
    fatigue := 0.0
  else
  begin
    // Remap [onset..1.0] → [0.0..1.0], then square for steep late ramp
    var normalized := (rawFatigue - Instinct.FATIGUE_ONSET) / (1.0 - Instinct.FATIGUE_ONSET);
    fatigue := normalized * normalized;
  end;

  Result := Result + fatigue;

  // clean up the result
  Result := EnsureRange(Result, 0.0, 1.0);
end;


initialization
  GlobalGeneRegistry.RegisterGene(TShelterEvaluator);

end.
