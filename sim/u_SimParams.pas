unit u_SimParams;

interface

type
  TSimParams = record
    DayDecayRate: Single;
    NightDecayRate: Single;
    ExtraBiomass: Single;

    // Cache size controls ("bush size").
    // Capacity rating now controls cache occurrence density, not this size.
    BaseCacheCapacity: Single;
    CacheCapacityJitterPct: Single;
    CacheInitialFillMin: Single;
    CacheInitialFillMax: Single;

    // list of absorption spectra
    // agent starting conditions

  end;

implementation

end.
