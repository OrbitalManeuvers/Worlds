unit u_AgentState;

interface

uses u_AgentTypes, u_AgentGenome, u_EnvironmentTypes;

type
  TDecisionWeights = array[TDecisionAction, TDecisionEnergy, TDecisionFoodSignal, TDecisionDayPhase] of Single;

  PAgentState = ^TAgentState;
  TAgentState = record
    // Identity
    AgentId: TAgentId;
    Location: TCellIndex;

    // Lifecycle
    Age: Integer;  // in ticks
    Reserves: Single;  // energy

    // Pressure signals
    ReserveDelta: Single;  // end-of-last-live-tick reserves minus prior tick reserves
    TicksSinceReproduction: Integer;
    TicksSinceForage: Integer;

    // Current action
    Action: TAgentAction;
    ActionTarget: TTarget;
    ActionAge: Integer;          // number of ticks spent doing current action
    WanderTarget: Integer;
    GestationProgress: Integer;  // ticks spent in gestation

    // Learned state (decision weights)
    DecisionWeights: TDecisionWeights;
    ForageMoleculeWeights: TMoleculeFactors;  // learned preference per molecule

    // Heritable traits (for reproduction + mutation)
    Genome: TAgentGenome;  // sensor ranges, metabolic params, etc.
  end;


implementation

end.
