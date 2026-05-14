unit u_AgentState;

interface

uses u_AgentTypes, u_AgentGenome;

type
  TContextIndex = 0..23;

(*
Reserves:     4 buckets (0-25%, 25-50%, 50-75%, 75-100%)
FoodSignal:   3 buckets (none, weak, strong)
DayPhase:     2 buckets (day, night)
              --------------------------
              4 × 3 × 2 = 24 contexts
              × 4 actions = 96 weights total

*)
  TDecisionWeights = array[TAgentAction, TContextIndex] of Single;

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

    function GetContextIndex: TContextIndex;
  end;


implementation

{ TAgentState }
function TAgentState.GetContextIndex: TContextIndex;
begin
  // to-do
  Result := Low(TContextIndex);
end;


end.
