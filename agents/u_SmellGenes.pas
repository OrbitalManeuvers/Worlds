unit u_SmellGenes;

interface

uses u_AgentTypes, u_AgentGenome, u_SimQueriesIntf;

type
  TBasicSmell = class(TSmellGene)
  public
    class function Scan(Location: Cardinal; const Params: TSmellParams; const Query: ISimQuery;
      var Scratch: TSmellScanScratch): TSmellReport; override;
  end;

implementation

uses System.SysUtils, u_EnvironmentTypes;

{ TBasicSmell }

class function TBasicSmell.Scan(Location: Cardinal; const Params: TSmellParams; const Query: ISimQuery;
  var Scratch: TSmellScanScratch): TSmellReport;
begin
  Result.Count := 0;
  SetLength(Result.Details, 0);
  Scratch.Count := 0;

  var smellQuery: IEnvironmentSmellQuery;
  if Supports(Query, IEnvironmentSmellQuery, smellQuery) then
  begin
    smellQuery.FillLocalFoodCaches(Location, Params.Range, Scratch.Buffer, Scratch.Count);
    Result.Count := Scratch.Count;
    SetLength(Result.Details, Scratch.Count);

    for var i := 0 to Scratch.Count - 1 do
    begin
      // Direction scaffolding: local-cell scan currently reports distance 0.
      Result.Details[i].Directions.Direction := mdNorth;
      Result.Details[i].Directions.Distance := 0;

      Result.Details[i].MoleculesPresent := [];
      for var molecule := Low(TMolecule) to High(TMolecule) do
      begin
        var share := Scratch.Buffer[i].Substance[molecule] / 100.0;
        Result.Details[i].MoleculeStrength[molecule] := Scratch.Buffer[i].Amount * share;
        // Smell ratings are passed through params for future scaling here.
        if Scratch.Buffer[i].Substance[molecule] > 0 then
          Include(Result.Details[i].MoleculesPresent, molecule);
      end;
    end;
  end;
end;

initialization
  GlobalGeneRegistry.RegisterGene(TBasicSmell);

end.
