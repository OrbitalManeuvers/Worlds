unit u_MovementGenes;

interface

uses u_AgentTypes, u_AgentGenome;

type
  TMoveEvaluator = class(TMoveEvalGene)
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
  // Already moving: small persistence bonus — stay the course toward a known target.
  MOVE_FORAGE_PENALTY    = 0.04;
  MOVE_SHELTER_PENALTY   = 0.05;
  MOVE_PERSISTENCE_BONUS = 0.02;

{ TMoveEvaluator }

class function TMoveEvaluator.Evaluate(const Input: TMoveEvalInput; var Scratch: TMoveEvalScratch): TActionEvalResult;
begin
  Scratch := Default(TMoveEvalScratch);
  Result := Default(TActionEvalResult);
  Result.Score := 0.0;
  Result.Target.TType := ttNone;

  if Input.Smell.Count <= 0 then
    Exit;

  // Movement is only interesting when food is not in the current cell.
  for var detail in Input.Smell.Details do
  begin
    if detail.Directions.Distance = 0 then
      Continue;

    var targetSignal := 0.0;
    for var molecule := Low(TMolecule) to High(TMolecule) do
      targetSignal := targetSignal + detail.MoleculeStrength[molecule];

    if targetSignal > Result.Score then
    begin
      Result.Score := targetSignal;
      Result.Target.TType := ttCell;
      Result.Target.Cell := detail.CellIndex;
    end;

    // Preserve a small remote-move affordance when composition exists but strengths are near zero.
    if (targetSignal = 0.0) and (detail.MoleculesPresent <> []) and (Result.Score < 0.01) then
    begin
      Result.Score := 0.01;
      Result.Target.TType := ttCell;
      Result.Target.Cell := detail.CellIndex;
    end;
  end;

  // Gestating agents are committed — suppress movement toward remote food.
  // Only an unusually strong signal will overcome this.
  if Input.CurrentAction = acReproduce then
    Result.Score := Result.Score * (1.0 - MOVE_REPRODUCE_SUPPRESSION);

  // Action context shapes entry friction.
  // Signal strength drives the base score; current action shapes how easy it is to act on it.
  // Wander and idle are low-commitment — move competes freely from those states.
  case Input.CurrentAction of
    acForage:  Result.Score := Result.Score - MOVE_FORAGE_PENALTY;
    acShelter: Result.Score := Result.Score - MOVE_SHELTER_PENALTY;
    acMove:    Result.Score := Result.Score + MOVE_PERSISTENCE_BONUS;
  end;

end;

initialization
  GlobalGeneRegistry.RegisterGene(TMoveEvaluator);


end.
