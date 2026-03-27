unit u_SimQueriesIntf;

interface

uses u_SimEnvironments;

type
  ISimQuery = interface
    ['{8C77A41D-4AD7-4232-8E5A-6469F16F1D90}']
  end;

  // Marker interface for environment-backed queries (resources, terrain, light, etc.).
  IEnvironmentQuery = interface(ISimQuery)
    ['{E5D69BCA-B100-4C8D-9468-0BE4023459EC}']
  end;

  // Marker interface for future population-backed queries (nearby agents, occupancy, etc.).
  IPopulationQuery = interface(ISimQuery)
    ['{26B58A40-2454-4B93-A77B-039AD0F3AE4E}']
  end;

  TSmellCacheInfo = record
    CacheId: Cardinal;
    SubstanceIndex: Word;
    Amount: Single;
    Substance: TSubstance;
  end;

  TSmellCacheInfos = array of TSmellCacheInfo;

  // Smell contract for environment lookups. Provides composition identity via SubstanceIndex.
  IEnvironmentSmellQuery = interface(IEnvironmentQuery)
    ['{BCFB2EFB-C6F9-4FCA-A4CE-D40CD8A1A72C}']
    // Caller owns Buffer and can reuse it across ticks to reduce allocations.
    // Count is the number of valid items populated in Buffer[0..Count-1].
    procedure FillLocalFoodCaches(Location: Cardinal; Range: Single; var Buffer: TSmellCacheInfos; out Count: Integer);
  end;

implementation

end.
