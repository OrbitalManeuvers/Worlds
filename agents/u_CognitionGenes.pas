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

  Result.RequestedAction := bestAction;
  Result.RequestedTarget := Input.CurrentTarget;

  // Minimal targeting hook for foraging while movement/pathing is still scaffolded.
  if (bestAction = acForage) and (Input.Context.Smell.Count > 0) then
  begin
    Result.RequestedTarget.TType := ttCache;
    Result.RequestedTarget.CacheId := Input.Context.Smell.Details[0].CacheId;
  end;
end;


initialization
  GlobalGeneRegistry.RegisterGene(TBasicCognition);

end.
