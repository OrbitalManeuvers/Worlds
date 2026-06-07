unit u_ExplorationTypes;

interface

uses System.Generics.Collections,
  u_SimTypes, u_SimEventTypes, u_AgentTypes;

type
  TSubjectFilter = (sfAny, sfInclude, sfExclude, sfOffspringOf);
  TSubject = record
    Filter: TSubjectFilter;
    Agents: TArray<TAgentId>;
  end;

  TPredicateKind = (
    // no arguments
    pkBorn, pkDies,

    // action + target
    pkActionSelected,

    // int
    pkAwakePastTick, pkReachesAge,

    // float
    pkExceedsReserves
  );

  TActionPredicate = record
    Action: TAgentAction;
    Target: TTarget;
  end;

  TPredicate = record
    Kind: TPredicateKind;
    Action: TActionPredicate;
    IntParam: Integer;
    FloatParam: Single;
  end;

  TEndCondition = record
    Subject: TSubject;
    Predicates: TArray<TPredicate>;
  end;

  TExplorationRun = record
    Conditions: TArray<TEndCondition>;
    HardStopTicks: Integer;         // runaway guard
    FIFOCapacity: Integer;          // ring buffer size (0 = disabled)
  end;

  TExplorationResult = record
    Stopped: Boolean;               // True = condition fired; False = hard stop
    FiredConditionIndex: Integer;   // which condition triggered (-1 if hard stop)
    FinalDate: TSimDate;            // sim date at stop
    TicksElapsed: Integer;          // how many ticks ran
    EventBuffer: TArray<TSimEvent>; // FIFO contents at stop, oldest-first
  end;


implementation

end.
