unit u_AgentState;

interface

uses u_AgentTypes, u_AgentGenome, u_EnvironmentTypes;

type
  TDecisionWeights = array[TDecisionAction, TDecisionEnergy, TDecisionFoodSignal, TDecisionDayPhase] of Single;

  PAgentState = ^TAgentState;
  TAgentState = record
    // Identity
    AgentId: TAgentId;
    ParentId: TAgentId;
    Generation: Integer;
    Birthplace: TCellIndex;

    Location: TCellIndex;

    // Lifecycle
    Age: Integer;  // in ticks
    Reserves: Single;  // energy
    CircadianPressure: Single;  // builds towards global max at 1.0 per tick universally
    CircadianRelief: Single;    // per-tick decrement to pressure while sleeping

    // Pressure signals
    ReserveDelta: Single;  // end-of-last-live-tick reserves minus prior tick reserves
    TicksSinceReproduction: Integer;
    TicksSinceForage: Integer;

    TicksSinceShelter: Integer; // replaced by CircadianPressure

    // Current action
    Action: TAgentAction;
    ActionTarget: TTarget;
    ActionAge: Integer;          // number of ticks spent doing current action
    ActionProgress: Integer;  // progress made on action, post-entry phase

    // Learned state (decision weights)
    DecisionWeights: TDecisionWeights;
    ForageMoleculeWeights: TMoleculeFactors;  // learned preference per molecule

    // Heritable traits (for reproduction + mutation)
    Genome: TAgentGenome;
  end;


implementation

end.
