unit u_SightGenes;

interface

uses u_AgentGenome, u_SimQueriesIntf, u_AgentTypes;

type
  TBasicVision = class(TSightGene)
  public
    class function Scan(Location: Cardinal; Range: Single; const Query: ISimQuery;
      var Scratch: TSightScanScratch): TSightReport; override;
  end;

  TAdvancedVision = class(TSightGene)
  public
    class function Scan(Location: Cardinal; Range: Single; const Query: ISimQuery;
      var Scratch: TSightScanScratch): TSightReport; override;
    class function GetGenerationCode: Char; override;
  end;

implementation

uses System.SysUtils;

{ TBasicVision }

class function TBasicVision.Scan(Location: Cardinal; Range: Single; const Query: ISimQuery;
  var Scratch: TSightScanScratch): TSightReport;
begin
  Scratch.Count := 0;
  Result := Default(TSightReport);
end;

{ TAdvancedVision - testing mutation code path }

class function TAdvancedVision.GetGenerationCode: Char;
begin
  Result := 'B';
end;

class function TAdvancedVision.Scan(Location: Cardinal; Range: Single; const Query: ISimQuery;
  var Scratch: TSightScanScratch): TSightReport;
begin
  Scratch.Count := 0;

  var sightQuery: IPopulationSightQuery;
  if Supports(Query, IPopulationSightQuery, sightQuery) then
  begin
    //
  end;



  Result := Default(TSightReport);
  Result.Count := 1;
  SetLength(Result.Details, 1);
  Result.Details[0].Directions.Direction := mdNorth;
  Result.Details[0].Directions.Distance := 2;
end;

initialization
  GlobalGeneRegistry.RegisterGene(TBasicVision);
  GlobalGeneRegistry.RegisterGene(TAdvancedVision);

end.
