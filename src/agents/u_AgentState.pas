unit u_AgentState;

interface

uses u_AgentTypes, u_AgentGenome;

type
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
    DecisionWeights: array of Single;  // indexed by (action x context)

    // Heritable traits (for reproduction + mutation)
    Genome: TAgentGenome;  // sensor ranges, metabolic params, etc.
  end;


implementation

end.
