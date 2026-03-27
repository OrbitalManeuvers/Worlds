unit u_Sight;

interface

uses u_AgentGenome;

type
  TBasicVision = class(TSightGene)
  public
//    class procedure Scan(Range: Single; Location: Cardinal); override;
  end;

  TAdvancedVision = class(TSightGene)
  public
//    class procedure Scan(Range: Single; Location: Cardinal); override;
    class function GetGenerationCode: Char; override;
  end;

implementation

{ TBasicVision }

//class procedure TBasicVision.Scan(Range: Single; Location: Cardinal);
//begin
//  inherited;
//end;

{ TAdvancedVision }

class function TAdvancedVision.GetGenerationCode: Char;
begin
  Result := 'B';
end;

//class procedure TAdvancedVision.Scan(Range: Single; Location: Cardinal);
//begin
//  inherited;
//end;

initialization
  GlobalGeneRegistry.RegisterGene(TBasicVision);
  GlobalGeneRegistry.RegisterGene(TAdvancedVision);

end.
