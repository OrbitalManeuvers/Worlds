unit u_CognitionGenes;

interface

uses u_AgentGenome, u_AgentTypes;

type
  TBasicCognition = class(TCognitionGene)
  public
    class function Decide(const Input: TCognitionInput; var Scratch: TCognitionScratch): TCognitionOutput; override;
  end;


implementation

{ TBasicCognition }

class function TBasicCognition.Decide(const Input: TCognitionInput; var Scratch: TCognitionScratch): TCognitionOutput;
begin
  Scratch := Default(TCognitionScratch);

  var bestAction := Input.Context.CurrentAction;
  var bestScore := Input.ActionScores[bestAction];

  for var action := Low(TAgentAction) to High(TAgentAction) do
    if Input.ActionScores[action] > bestScore then
    begin
      bestAction := action;
      bestScore := Input.ActionScores[action];
    end;

  // Avoid sticky carry-over actions when no action has positive support this tick.
  if bestScore <= 0.0 then
  begin
    Result.RequestedAction := acIdle;
    Result.RequestedTarget.TType := ttCell;
    Result.RequestedTarget.Cell := Input.Context.Location;
    Exit;
  end;

  Result.RequestedAction := bestAction;
  Result.RequestedTarget := Input.CurrentTarget;

  // Minimal targeting hook for foraging while movement/pathing is still scaffolded.
  // Smell details are expected to arrive pre-sorted by the smell gene.
  // While movement is unresolved, only local (distance 0) cache targets are actionable.
  if (bestAction = acForage) and (Input.Context.Smell.Count > 0) and (Length(Input.Context.Smell.Details) > 0) then
  begin
    var foundLocal := False;
    for var i := 0 to Length(Input.Context.Smell.Details) - 1 do
      if Input.Context.Smell.Details[i].Directions.Distance = 0 then
      begin
        Result.RequestedTarget.TType := ttCache;
        Result.RequestedTarget.CacheId := Input.Context.Smell.Details[i].CacheId;
        foundLocal := True;
        Break;
      end;

    if not foundLocal then
    begin
      Result.RequestedAction := acIdle;
      Result.RequestedTarget.TType := ttCell;
      Result.RequestedTarget.Cell := Input.Context.Location;
    end;
  end;
end;


initialization
  GlobalGeneRegistry.RegisterGene(TBasicCognition);

end.
