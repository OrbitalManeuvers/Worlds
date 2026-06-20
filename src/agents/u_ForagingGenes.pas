unit u_ForagingGenes;

interface

uses u_AgentGenome, u_SimQueriesIntf, u_GeneTypes, u_RuntimeTypes;

type
  TForageEvaluator = class(TForageEvalGene)
    class function BuildReport(const Input: TForageEvalInput; var Scratch: TForageEvalScratch): TForageReport; override;
  end;


implementation

uses u_EnvironmentTypes, System.Math, u_Instincts;

const
  FORAGE_WEIGHT_EPSILON = 0.01;         // weights below this are treated as zero (learning asymptote)

{ TForagingGene }

class function TForageEvaluator.BuildReport(const Input: TForageEvalInput; var Scratch: TForageEvalScratch): TForageReport;

  procedure InsertForageOption(const Cache: TCacheRef; const CellIndex: TCellIndex;
    const Distance: Word; const Opportunity: Single);
  begin
    if Opportunity <= 0.0 then
      Exit;

    var insertAt := Result.Count;
    while (insertAt > 0) and (Opportunity > Result.Options[insertAt - 1].Opportunity) do
      Dec(insertAt);

    if (Result.Count >= Length(Result.Options)) and (insertAt >= Length(Result.Options)) then
      Exit;

    if Result.Count < Length(Result.Options) then
      Inc(Result.Count);

    for var idx := Result.Count - 1 downto insertAt + 1 do
      Result.Options[idx] := Result.Options[idx - 1];

    Result.Options[insertAt].Cache := Cache;
    Result.Options[insertAt].CellIndex := CellIndex;
    Result.Options[insertAt].Distance := Distance;
    Result.Options[insertAt].Opportunity := Opportunity;
  end;

begin
  Scratch := Default(TForageEvalScratch);
  Result := Default(TForageReport);

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

    // Instinct: ignore caches that aren't "ripe" yet — too small to be worth eating.
    // Lets tiny caches grow into a real meal instead of being consumed immediately.
    if targetSignal < Instinct.MIN_FORAGE_SIGNAL then
      Continue;

    InsertForageOption(detail.Cache, detail.CellIndex, detail.Directions.Distance, targetSignal);
  end;

end;

initialization
  GlobalGeneRegistry.RegisterGene(TForageEvaluator);

end.
