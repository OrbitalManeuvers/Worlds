unit u_ConverterGenes;

interface

uses u_AgentTypes, u_AgentGenome;

type
  TBasicConverter = class(TConverterGene)
  public
    class function Convert(const Input: TConverterInput; var Scratch: TConverterScratch): Single; override;
  end;

  TDeltaConverter = class(TBasicConverter)
  public
    class function GetGenerationCode: Char; override;
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

{ TDeltaConverter }

class function TDeltaConverter.GetGenerationCode: Char;
begin
  Result := 'B';
end;

class function TDeltaConverter.Convert(const Input: TConverterInput; var Scratch: TConverterScratch): Single;
const
  DELTA_ENERGY_DENSITY_FACTOR = 1.8;  // delta yields more energy per unit for capable converters
begin
  Scratch := Default(TConverterScratch);

  var efficiency := 0.0;
  for var molecule := Low(TMolecule) to High(TMolecule) do
  begin
    var share := Input.Substance[molecule] / 100.0;
    var rating := Input.Ratings[molecule];

    // Delta's higher energy density compounds with the agent's conversion ability.
    if molecule = Delta then
      rating := rating * DELTA_ENERGY_DENSITY_FACTOR;

    efficiency := efficiency + (share * rating);
  end;

  Result := Input.ConsumedAmount * Max(0.0, efficiency);
end;


initialization
  GlobalGeneRegistry.RegisterGene(TBasicConverter);
  GlobalGeneRegistry.RegisterGene(TDeltaConverter);


end.
