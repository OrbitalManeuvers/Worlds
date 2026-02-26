unit u_Regions;

interface

uses u_EditorObjects, u_Environment.Types, u_Worlds.Types,
  u_Biomes;

type

  TRegion = record
    Title: string;
    Description: string;
    Biomes: array of TBiome;
    BiomeMap: TBiomeGrid;
  end;

implementation

end.
