unit u_AgentState;

interface

uses u_RunTimeTypes, u_EnvironmentTypes, u_SimTypes, u_BrainTypes, u_AgentGenome;

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

    // Current action
    Action: TAgentAction;
    ActionTarget: TTarget;
    ActionAge: Integer;          // number of ticks spent doing current action
    ActionProgress: Integer;  // progress made on action, post-entry phase

    // Short-term memory
    LastForageCell: TCellIndex;  // cell where last successful forage occurred

    // Learned state (decision weights)
    DecisionWeights: TDecisionWeights;

    // Heritable traits (for reproduction + mutation)
    Genome: TAgentGenome;

    // Initialization
    procedure InitAgent;
  end;


implementation

{ TAgentState }

procedure TAgentState.InitAgent;
begin
  Self := Default(TAgentState);
  LastForageCell := -1;
  CircadianRelief := STANDARD_CIRCADIAN_RELIEF_RATE;
end;

end.
