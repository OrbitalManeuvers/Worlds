unit u_ConverterGenes;

interface

uses u_AgentTypes, u_AgentGenome;

type
  TBasicConverter = class(TConverterGene)
  public
    class function Convert(const Input: TConverterInput; var Scratch: TConverterScratch): Single; override;
  end;


implementation

uses System.Math, u_EnvironmentTypes;

{ TBasicConverter }

class function TBasicConverter.Convert(const Input: TConverterInput; var Scratch: TConverterScratch): Single;
begin
  Scratch := Default(TConverterScratch);

  var efficiency := 0.0;
  for var molecule := Low(TMolecule) to High(TMolecule) do
  begin
    var share := Input.Substance[molecule] / 100.0;
    efficiency := efficiency + (share * Input.Ratings[molecule]);
  end;

  Result := Input.ConsumedAmount * Max(0.0, efficiency);
end;


initialization
  GlobalGeneRegistry.RegisterGene(TBasicConverter);


end.
