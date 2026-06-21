unit u_PopulationTypes;

interface

uses u_SimTypes, u_AgentGenome, u_EnvironmentTypes, u_RuntimeTypes,
  u_AgentState;

type
  TLifespan = record
    AgentId: TAgentId;
    Age: Integer;
  end;
  TReserveState = record
    AgentId: TAgentId;
    Reserves: Single;
  end;

  TDistanceRecord = record
    AgentId: TAgentId;
    Distance: Integer;
  end;

  // the state of the population at the end of a tick
  TPopulationSummary = record
    // Snapshot stats (computed in one pass after all agents tick)
    Living: Integer;
    Sheltering: Integer;
    LongestLife: TLifespan;
    MaxReserves: TReserveState;
    MaxDistance: TDistanceRecord;
    MeanReserves: Single;
    MaxLiving: Integer;        // high-water mark (persisted across ticks)

    // Per-tick event counters (incremented at point of occurrence)
    NewBirths: Integer;
    NewDeaths: Integer;
  end;

  TMetabolicState = record
    Age: Integer;
    Reserves: Single;
    ReserveDelta: Single;
    GeneSequence: TGeneSequence;
    MoleculeFactors: TMoleculeFactors;
    ForageMoleculeWeights: TMoleculeFactors;
    DecisionWeights: TDecisionWeights;
  end;


implementation

end.
