unit u_AgentState;

interface

uses u_AgentTypes, u_AgentGenome;

type
  (*
  Energy:     4 buckets (low, medium, high, full)
  FoodSignal: 3 buckets (none, weak, strong)
  DayPhase:   2 buckets (day, night)
              -------------------------------
              4 x 3 x 2 = 24 contexts
              x 4 actions = 96 weights total
  *)
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

    // Heritable traits (for reproduction + mutation)
    Genome: TAgentGenome;  // sensor ranges, metabolic params, etc.
  end;


implementation

end.
