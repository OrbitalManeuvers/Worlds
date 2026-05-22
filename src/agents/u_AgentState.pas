unit u_AgentState;

interface

uses u_AgentTypes, u_AgentGenome, u_EnvironmentTypes;

type
  TDecisionWeights = array[TDecisionAction, TDecisionEnergy, TDecisionFoodSignal, TDecisionDayPhase] of Single;

  PAgentState = ^TAgentState;
  TAgentState = record
    // Identity
    AgentId: Integer;
    Location: Integer;

    // Lifecycle
    Age: Integer;  // in ticks
    Reserves: Single;  // energy

    // Pressure signals
    ReserveDelta: Single;  // end-of-last-live-tick reserves minus prior tick reserves
    TicksSinceReproduction: Integer;
    TicksSinceForage: Integer;

    // Current action
    Action: TAgentAction;
    ActionProgress: Integer;  // ticks spent on current action
    ActionTarget: TTarget;
    WanderTarget: Integer;

    // Learned state (decision weights)
    DecisionWeights: TDecisionWeights;
    ForageMoleculeWeights: array[TMolecule] of Single;  // to-do

    // Heritable traits (for reproduction + mutation)
    Genome: TAgentGenome;  // sensor ranges, metabolic params, etc.
  end;


implementation

end.
