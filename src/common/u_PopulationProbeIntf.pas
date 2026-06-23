unit u_PopulationProbeIntf;

interface

uses u_SimTypes, u_RuntimeTypes, u_BrainTypes, u_AgentGenome, u_GeneTypes,
  u_AgentState;

type
  TBrainSnapshot = record
    AgentId: TAgentId;
    DampenedScores: TActionScores;   // after continuation pressure applied
    CognitionInput: TCognitionInput;  // includes reports, weighted scores, smell, state context
    FinalAction: TAgentAction;
    FinalTarget: TTarget;
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

  IPopulationProbe = interface
    ['{C5668072-054F-4A2F-A565-A2691116D106}']
    procedure AllocateProbe(AgentId: TAgentId);
    procedure ReleaseProbe(AgentId: TAgentId);
    function GetProbeSnapshot(AgentId: TAgentId): TBrainSnapshot;  // PBrainSnapshot?
    function GetMetabolicState(AgentId: TAgentId): TMetabolicState;
    function GetStatePtr(AgentId: Integer): PAgentState;
  end;

implementation

end.
