unit u_SimEventTypes;

interface

uses System.Types,
  u_AgentTypes, u_AgentBrain, u_AgentGenome, u_SimClocks, u_SimPhases;

type
  TSimEventKind = (
    sekActionResolved,
    sekDecisionTrace,
    sekAgentBorn,
    sekAgentMoved,
    sekBiomassCreated,
    sekBiomassConsumed,
    sekAgentDied,
    sekResourceSampled
  );

  TSimEventKinds = set of TSimEventKind;

  TBiomassCreateReason = (
    bcrUnknown,
    bcrNightfallInjection,
    bcrRandomNightInjection,
    bcrAgentDeath
  );

  TActionResolutionNote = (
    arnNone,
    arnReproduceBlockedLowReserves,
    arnGestationStarted,
    arnGestationContinuing,
    arnGestationCompleted
  );

  TSimEventHeader = record
    Sequence: Integer;
    DayNumber: Integer;
    DayTick: TDayTick;
    Phase: TSimTickPhase;
    Kind: TSimEventKind;
  end;

  TTargetRef = record
    case TType: TTargetType of
      ttNone: ();
      ttCell: (Cell: TPoint);
      ttCache: (Cache: TCacheRef);
  end;

  TActionResolvedEvent = record
    AgentId: Integer;
    RequestedAction: TAgentAction;
    RequestedTarget: TTargetRef;
    ResolvedAction: TAgentAction;
    ResolvedTarget: TTargetRef;
    Reserves: Single;
    ActionProgress: Integer;
    Note: TActionResolutionNote;
  end;

  TDecisionTraceEvent = record
    AgentId: Integer;
    Cell: TPoint;
    RequestedAction: TAgentAction;
    RequestedTarget: TTargetRef;
    ResolvedAction: TAgentAction;
    ResolvedTarget: TTargetRef;
    ForageConsumed: Single;
    ForageGain: Single;
    ForageEfficiency: Single;
    Evaluations: TActionEvaluations;
    Summary: TBrainTraceSummary;
  end;

  TAgentMovedEvent = record
    AgentId: Integer;
    FromCell: TPoint;
    ToCell: TPoint;
    MoveCost: Single;
    Reserves: Single;
  end;

  TAgentBornEvent = record
    AgentId: Integer;
    ParentAgentId: Integer;
    Cell: TPoint;
    InitialReserves: Single;
  end;

  TBiomassCreatedEvent = record
    Cell: TPoint;
    Amount: Single;
    Reason: TBiomassCreateReason;
    SourceAgentId: Integer;
  end;

  TBiomassConsumedEvent = record
    AgentId: Integer;
    Cell: TPoint;
    Cache: TCacheRef;
    ConsumedAmount: Single;
    GainAmount: Single;
  end;

  TAgentDiedEvent = record
    AgentId: Integer;
    Cell: TPoint;
    Age: Integer;
    ReservesBeforeDeath: Single;
  end;

  TResourceSampledEvent = record
    CacheIndex: Integer;
    Amount: Single;
    RegenDebt: Single;
  end;

  TSimEvent = record
    Header: TSimEventHeader;
    ActionResolved: TActionResolvedEvent;
    DecisionTrace: TDecisionTraceEvent;
    AgentBorn: TAgentBornEvent;
    AgentMoved: TAgentMovedEvent;
    BiomassCreated: TBiomassCreatedEvent;
    BiomassConsumed: TBiomassConsumedEvent;
    AgentDied: TAgentDiedEvent;
    ResourceSampled: TResourceSampledEvent;
  end;

//  TSimEventFilter = record
//    Kinds: TSimEventKinds;
//    AgentId: Integer;
//    CellIndex: Integer;
//  end;

  TSimEventViewDef = record
    Kinds: TSimEventKinds;
    AgentIds: TArray<Integer>;
    StartSequence: Integer; // < 0 means unbounded start
    StopSequence: Integer;  // < 0 means unbounded stop
  end;

  ISimDiagnosticsSink = interface
    ['{E9073AA2-4F5D-47F3-BD9E-711D2DB53F9D}']
    procedure Emit(const Event: TSimEvent);
  end;

  ISimEventConsumer = interface
    ['{0FF03D6F-0DBE-4924-9771-2D658A479FD5}']
    procedure Consume(const Event: TSimEvent);
  end;

  IEventSink = interface
    ['{E42567E7-85F6-4C87-90BE-B00699011824}']
    procedure Write(aEvent: TSimEvent);
  end;

  IEventLog = interface
    ['{3894A514-3F88-4E07-9618-1A1E588CE60C}']
    function GetCount: Integer;
    function GetEvent(aIndex: Integer): TSimEvent;
    property Count: Integer read GetCount;
    property Events[aIndex: Integer]: TSimEvent read GetEvent;
  end;

  // parameterized view onto an event log
  IEventLogView = interface
    ['{11664E6F-DDB0-4C5B-B0E9-57587E32AEC2}']
    function GetCount: Integer;
    function GetEvent(aIndex: Integer): TSimEvent; // indirection through internal list
    procedure Define(const aViewDef: TSimEventViewDef);
    procedure Extend; // scan new log entries since last Define/Extend
    property Count: Integer read GetCount;
    property Events[aIndex: Integer]: TSimEvent read GetEvent;
  end;


function AnySimEventKinds: TSimEventKinds;
//function AnySimEventFilter: TSimEventFilter;
function AnySimEventViewDef: TSimEventViewDef;


implementation

function AnySimEventKinds: TSimEventKinds;
begin
  Result := [Low(TSimEventKind)..High(TSimEventKind)];
end;

//function AnySimEventFilter: TSimEventFilter;
//begin
//  Result.Kinds := AnySimEventKinds;
//  Result.AgentId := -1;
//  Result.CellIndex := -1;
//end;

function AnySimEventViewDef: TSimEventViewDef;
begin
  Result.Kinds := AnySimEventKinds;
  SetLength(Result.AgentIds, 0);
  Result.StartSequence := -1;
  Result.StopSequence := -1;
end;

end.