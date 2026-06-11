unit u_MovementGenes;

interface

uses u_AgentTypes, u_AgentGenome;

type
  TMoveEvaluator = class(TMoveEvalGene)
    class function Evaluate(const Input: TMoveEvalInput; var Scratch: TMoveEvalScratch): TActionEvalResult; override;
  end;

  TLearningMoveEvaluator = class(TMoveEvalGene)
  public
    class function GetGenerationCode: Char; override;
    class function Evaluate(const Input: TMoveEvalInput; var Scratch: TMoveEvalScratch): TActionEvalResult; override;
  end;

implementation

uses u_EnvironmentTypes;

const
  // While reproducing, movement toward remote food is heavily suppressed.
  // A very strong signal can still win, but routine smell-following won't interrupt gestation.
  MOVE_REPRODUCE_SUPPRESSION = 0.90;

  // Action context modifiers.
  // Foraging: don't abandon a meal for a distant smell.
  // Sheltering: resting agent resists being pulled out by remote signals.
  // Already moving: persistence bonus when no local food — stay the course.
  //   But if local food exists, flip to a penalty: you arrived, stop and eat.
  MOVE_FORAGE_PENALTY    = 0.04;
  MOVE_SHELTER_PENALTY   = 0.05;
  MOVE_PERSISTENCE_BONUS = 0.02;
  MOVE_ARRIVAL_PENALTY   = 0.04;

  // Distance discount: remote signals are divided by (1 + distance * factor).
  // A cell 2 away is worth signal/2.0, a cell 4 away is signal/3.0.
  MOVE_DISTANCE_COST_FACTOR = 0.50;

  // Learned molecule weights below this threshold are treated as zero.
  // Prevents near-zero asymptotic weights from creating phantom local food signals.
  MOVE_WEIGHT_EPSILON = 0.01;

  // Local food suppression: when edible food is in the current cell, remote
  // movement scores are heavily discounted. A bird in the hand...
  MOVE_LOCAL_FOOD_SUPPRESSION = 0.35;

  // Extra suppression when reserves are declining — chasing remote food while
  // burning energy is a bad gamble when local food is available.
  MOVE_NEGATIVE_DELTA_EXTRA_SUPPRESSION = 0.50;

{ TMoveEvaluator }

class function TMoveEvaluator.Evaluate(const Input: TMoveEvalInput; var Scratch: TMoveEvalScratch): TActionEvalResult;
begin
  Scratch := Default(TMoveEvalScratch);
  Result := Default(TActionEvalResult);
  Result.Score := 0.0;
  Result.Target.TType := ttNone;

  if Input.Smell.Count <= 0 then
    Exit;

  // Single pass: detect local food and score remote candidates simultaneously.
  // Local food only counts if its weighted signal is positive — a cache the agent
  // has learned to ignore (molecule weight = 0) should not suppress movement.
  var hasLocalFood := False;
  for var detail in Input.Smell.Details do
  begin
    if detail.Directions.Distance = 0 then
    begin
      var weightedLocal := 0.0;
      for var mol := Low(TMolecule) to High(TMolecule) do
      begin
        var weight := Input.MoleculeWeights[mol];
        if weight < MOVE_WEIGHT_EPSILON then
          weight := 0.0;
        weightedLocal := weightedLocal + detail.MoleculeStrength[mol] * weight;
      end;
      if weightedLocal > 0.0 then
        hasLocalFood := True;
      Continue;
    end;

    var targetSignal := 0.0;
    for var molecule := Low(TMolecule) to High(TMolecule) do
    begin
      var weight := Input.MoleculeWeights[molecule];
      if weight < MOVE_WEIGHT_EPSILON then
        weight := 0.0;
      targetSignal := targetSignal + detail.MoleculeStrength[molecule] * weight;
    end;

    // Distance discount: remote signals lose value with distance.
    // A cache 2 cells away is worth half its raw signal; 4 away is a third.
    var adjustedSignal := targetSignal / (1.0 + detail.Directions.Distance * MOVE_DISTANCE_COST_FACTOR);

    if adjustedSignal > Result.Score then
    begin
      Result.Score := adjustedSignal;
      Result.Target.TType := ttCell;
      Result.Target.Cell := detail.CellIndex;
    end;

    // Preserve a small remote-move affordance when composition exists but strengths are near zero.
    if (adjustedSignal = 0.0) and (detail.MoleculesPresent <> []) and (Result.Score < 0.01) then
    begin
      Result.Score := 0.01;
      Result.Target.TType := ttCell;
      Result.Target.Cell := detail.CellIndex;
    end;
  end;

  // Local food suppression: when there's food right here, remote movement is a gamble.
  // The agent can still chase a truly strong remote signal, but weak ones lose hard.
  if hasLocalFood then
  begin
    Result.Score := Result.Score * MOVE_LOCAL_FOOD_SUPPRESSION;

    // Extra suppression when reserves are declining — leaving known food while
    // burning energy is especially risky.
    if Input.ReserveDelta < 0.0 then
      Result.Score := Result.Score * MOVE_NEGATIVE_DELTA_EXTRA_SUPPRESSION;
  end;

  // Gestating agents are committed — suppress movement toward remote food.
  // Only an unusually strong signal will overcome this.
  if Input.CurrentAction = acReproduce then
    Result.Score := Result.Score * (1.0 - MOVE_REPRODUCE_SUPPRESSION);

  // Action context shapes entry friction.
  // Signal strength drives the base score; current action shapes how easy it is to act on it.
  case Input.CurrentAction of
    acForage:  Result.Score := Result.Score - MOVE_FORAGE_PENALTY;
    acShelter: Result.Score := Result.Score - MOVE_SHELTER_PENALTY;
    acMove:
      begin
        // If local food exists the agent has arrived — penalize continued movement
        // so it stops and eats. Otherwise reward staying the course toward a target.
        if hasLocalFood then
          Result.Score := Result.Score - MOVE_ARRIVAL_PENALTY
        else
          Result.Score := Result.Score + MOVE_PERSISTENCE_BONUS;
      end;
  end;

end;

{ TLearningMoveEvaluator }
class function TLearningMoveEvaluator.Evaluate(const Input: TMoveEvalInput; var Scratch: TMoveEvalScratch): TActionEvalResult;
begin
  Result := TMoveEvaluator.Evaluate(Input, Scratch);
end;

class function TLearningMoveEvaluator.GetGenerationCode: Char;
begin
  Result := 'B';
end;

initialization
  GlobalGeneRegistry.RegisterGene(TMoveEvaluator);
  GlobalGeneRegistry.RegisterGene(TLearningMoveEvaluator);


end.
