unit u_ExplorationTypes;

interface

uses System.Generics.Collections,
  u_SimTypes, u_SimEventTypes, u_AgentTypes;

type
  TExplorationConditionKind = (
    // args: none
    ekBorn, ekDies,

    // args: action + target
    ekActionSelected,

    // args: int
    ekAwakePastTick, ekReachesAge, ekTravelsDistance,

    // args: float
    ekExceedsReserves
  );

  TActionParameter = record
    Action: TAgentAction;
    Target: TTarget;
  end;

  TExplorationCondition = record
    Kind: TExplorationConditionKind;

    // arguments per kind, only one valid
    Action: TActionParameter;
    IntParam: Integer;
    FloatParam: Single;
  end;

  TExplorationQuery = record
    Agents: TArray<TAgentId>;
    IncludeMode: Boolean;
    Conditions: TArray<TExplorationCondition>;
  end;


implementation

end.
