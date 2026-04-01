unit u_Foraging;

interface

uses u_AgentTypes, u_AgentGenome, u_SimQueriesIntf;

type
  TForagingGene = class(TForageEvalGene)
    class function Score(const Input: TForageEvalInput; var Scratch: TForageEvalScratch): Single; override;
  end;


implementation

uses u_EnvironmentTypes;

{ TForagingGene }

class function TForagingGene.Score(const Input: TForageEvalInput; var Scratch: TForageEvalScratch): Single;
begin
  Scratch := Default(TForageEvalScratch);
  Result := 0.0;

  if Input.Smell.Count <= 0 then
    Exit;

  // Evaluator focuses on opportunity strength; cognition handles broader trade-offs.
  for var detail in Input.Smell.Details do
  begin
    var targetSignal := 0.0;
    for var molecule := Low(TMolecule) to High(TMolecule) do
      targetSignal := targetSignal + detail.MoleculeStrength[molecule];

    if targetSignal > Result then
      Result := targetSignal;

    // Keep legacy/noise-tolerant behavior if strengths are absent.
    if (targetSignal = 0.0) and (detail.MoleculesPresent <> []) then
      if Result < 0.01 then
        Result := 0.01;

    if Result >= 1.0 then
      Break;
  end;

  // If count exists but details are not populated yet, keep a small positive affordance.
  if (Result = 0.0) and (Input.Smell.Count > 0) then
    Result := 0.01;
end;

initialization
  GlobalGeneRegistry.RegisterGene(TForagingGene);

end.
