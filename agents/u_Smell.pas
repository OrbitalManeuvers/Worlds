unit u_Smell;

interface

uses u_AgentTypes, u_AgentGenome, u_SimQueriesIntf;

type
  TBasicSmell = class(TSmellGene)
  public
    class function Scan(Location: Cardinal; const Params: TSmellParams; const Query: ISimQuery): TSmellReport; override;
  end;

implementation

uses System.SysUtils, u_EnvironmentTypes;

{ TBasicSmell }

class function TBasicSmell.Scan(Location: Cardinal; const Params: TSmellParams; const Query: ISimQuery): TSmellReport;
begin
  Result.Count := 0;
  SetLength(Result.Details, 0);

  var detailedQuery: IEnvironmentSmellQuery;
  if Supports(Query, IEnvironmentSmellQuery, detailedQuery) then
  begin
    var infos: TSmellCacheInfos;
    var infoCount: Integer := 0;

    detailedQuery.FillLocalFoodCaches(Location, Params.Range, infos, infoCount);
    Result.Count := infoCount;
    SetLength(Result.Details, infoCount);

    for var i := 0 to infoCount - 1 do
    begin
      // Direction scaffolding: local-cell scan currently reports distance 0.
      Result.Details[i].Directions.Direction := mdNorth;
      Result.Details[i].Directions.Distance := 0;

      Result.Details[i].MoleculesPresent := [];
      for var molecule := Low(TMolecule) to High(TMolecule) do
      begin
        var share := infos[i].Substance[molecule] / 100.0;
        Result.Details[i].MoleculeStrength[molecule] := infos[i].Amount * share;
        // Smell ratings are passed through params for future scaling here.
        if infos[i].Substance[molecule] > 0 then
          Include(Result.Details[i].MoleculesPresent, molecule);
      end;
    end;
  end;
end;

initialization
  GlobalGeneRegistry.RegisterGene(TBasicSmell);

end.
