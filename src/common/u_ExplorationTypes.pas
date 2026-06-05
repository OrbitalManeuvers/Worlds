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
    pkAwake, pkAge,

    // range
    pkReserves
  );

  TActionPredicate = record
    Action: TAgentAction;
    Target: TTarget;
  end;

  TIntegerPredicate = record
    Value: Integer;
  end;

  TCompareOp = (coLess, coGreater, coAtLeast, coAtMost);

  TRangePredicate = record
    Op: TCompareOp;
    Value: Single;
  end;

  TPredicate = record
    Kind: TPredicateKind;
    Action: TActionPredicate;
    Awake: TIntegerPredicate;
    Age: TIntegerPredicate;
    Reserves: TRangePredicate;
  end;

  TEndKind = (ekTime, ekQuery);

  TEndCondition = record
    Subject: TSubject;
    Predicates: TArray<TPredicate>;
  end;


implementation

end.
