unit u_ForagingGenes;

interface

uses u_AgentTypes, u_AgentGenome, u_SimQueriesIntf;

type
  TForageEvaluator = class(TForageEvalGene)
    class function Evaluate(const Input: TForageEvalInput; var Scratch: TForageEvalScratch): TActionEvalResult; override;
  end;


implementation

uses u_EnvironmentTypes, System.Math;

const
  FORAGE_RESERVE_COMFORT_LEVEL = 8.0;   // above this, forage urgency fades
  FORAGE_HIGH_RESERVE_DISCOUNT = 0.20;  // minimum score multiplier when reserves are full
  FORAGE_PERSISTENCE_BONUS = 0.03;      // already foraging — continue eating
  FORAGE_SEEKING_BONUS = 0.02;          // was moving toward food — reward the find
  FORAGE_SHELTER_PENALTY = 0.05;        // resting agent resists being pulled out by weak signals
  FORAGE_WEIGHT_EPSILON = 0.01;         // weights below this are treated as zero (learning asymptote)

{ TForagingGene }

class function TForageEvaluator.Evaluate(const Input: TForageEvalInput; var Scratch: TForageEvalScratch): TActionEvalResult;
begin
  Scratch := Default(TForageEvalScratch);
  Result := Default(TActionEvalResult);
  Result.Score := 0.0;
  Result.Target.TType := ttNone;

  if Input.Smell.Count <= 0 then
    Exit;

  // Foraging is local-only. Remote food should influence movement, not forage-now.
  for var detail in Input.Smell.Details do
  begin
    if detail.Directions.Distance <> 0 then
      Continue;

    var targetSignal := 0.0;
    for var molecule := Low(TMolecule) to High(TMolecule) do
    begin
      var weight := Input.MoleculeWeights[molecule];
      if weight < FORAGE_WEIGHT_EPSILON then
        weight := 0.0;
      targetSignal := targetSignal + detail.MoleculeStrength[molecule] * weight;
    end;

    if targetSignal > Result.Score then
    begin
      Result.Score := targetSignal;
      Result.Target.TType := ttCache;
      Result.Target.Cache := detail.Cache;
    end;

    if Result.Score >= 1.0 then
      Break;
  end;

  // Continuous reserve discount: urgency fades as reserves fill.
  // At comfort level and above, score is scaled down to FORAGE_HIGH_RESERVE_DISCOUNT.
  // Below comfort level the full signal competes normally.
  var reserveRatio := EnsureRange(Input.Reserves / FORAGE_RESERVE_COMFORT_LEVEL, 0.0, 1.0);
  var discount := 1.0 - (reserveRatio * (1.0 - FORAGE_HIGH_RESERVE_DISCOUNT));
  Result.Score := Result.Score * discount;

  // Action context shapes entry friction — but only when there's a viable target.
  // Without a target, bonuses would create phantom forage scores that the cognition
  // gene's fallback targeting would latch onto.
  if Result.Target.TType <> ttNone then
  case Input.CurrentAction of
    acForage:   Result.Score := Result.Score + FORAGE_PERSISTENCE_BONUS;
    acMove:     Result.Score := Result.Score + FORAGE_SEEKING_BONUS;
    acShelter:  Result.Score := Result.Score - FORAGE_SHELTER_PENALTY;
  end;
end;

initialization
  GlobalGeneRegistry.RegisterGene(TForageEvaluator);

end.
