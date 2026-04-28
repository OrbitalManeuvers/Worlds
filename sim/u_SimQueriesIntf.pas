unit u_SimQueriesIntf;

interface

uses u_AgentTypes, u_SimEnvironments;

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

  // Smell cache info for a single substance at a location. SubstanceIndex provides composition identity.
  TSmellCacheInfo = record
    CellIndex: Integer;
    Cache: TCacheRef;
    Amount: Single;
    Substance: TSubstance;
  end;

  // Caller-owned buffer of smell cache infos. Caller can reuse the buffer across ticks to reduce allocations.
  TSmellCacheInfos = array of TSmellCacheInfo;

  // Smell contract for environment lookups.
  IEnvironmentSmellQuery = interface(IEnvironmentQuery)
    ['{BCFB2EFB-C6F9-4FCA-A4CE-D40CD8A1A72C}']
    // Returns environment grid size used for cell-index coordinate math.
    procedure GetGridSize(out Width, Height: Integer);
    // Caller owns Buffer and can reuse it across ticks to reduce allocations.
    // Count is the number of valid items populated in Buffer[0..Count-1].
    // Range is clamped/quantized by the implementation to a bounded neighborhood tier.
    procedure FillLocalFoodCaches(Location: Integer; Range: Single; var Buffer: TSmellCacheInfos; out Count: Integer);
  end;


  TSightInfo = record
    AgentId: Integer;
    Location: Integer;
    Distance: Integer;
  end;

  TSightInfos = array of TSightInfo;

  IPopulationSightQuery = interface(IPopulationQuery)
    ['{5E8FE2D0-AA3F-4ECC-9258-741C7927128A}']
    // Caller owns Buffer and can reuse it across ticks to reduce allocations.
    // Count is the number of valid items populated in Buffer[0..Count-1].
    // This query returns indexed living agents in the local neighborhood, including distance-0 entries.
    // There is no source-agent parameter, so callers that need to exclude "self" must filter by AgentId.
    procedure FillLocalAgents(Location: Integer; Range: Single; var Buffer: TSightInfos; out Count: Integer);
  end;

  IPopulationCrowdingQuery = interface(IPopulationQuery)
    ['{E64FAE0C-E730-4BFD-8A4A-E208EB8F3D7B}']
    // Returns the count of indexed living agents in a local radius around CellIndex.
    // This count includes any living agent in CellIndex itself.
    function CountAgentsWithinRadius(CellIndex, Radius: Integer): Integer;
  end;

implementation

end.
