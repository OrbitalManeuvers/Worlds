unit u_SimEventTypes;

interface

uses System.Types,
  u_agentState, u_AgentTypes, u_AgentBrain, u_AgentGenome, u_SimClocks, u_SimTypes;

type
  TSimEventKind = (
    sekActionResolved,
    sekDecisionTrace,
    sekAgentBorn,
    sekAgentMoved,
    sekDeltaConsumed,
    sekAgentDied,
    sekPopulationSummary
  );

  TSimEventKinds = set of TSimEventKind;

// ======== May Logging

  TLifespan = record
    AgentId: TAgentId;
    Age: Integer;
  end;
  TReserveState = record
    AgentId: TAgentId;
    Reserves: Single;
  end;

  // the state of the population at the end of a tick
  TPopulationSummary = record
    // Snapshot stats (computed in one pass after all agents tick)
    Living: Integer;
    LongestLife: TLifespan;
    MaxReserves: TReserveState;
    MeanReserves: Single;
    MaxLiving: Integer;        // high-water mark (persisted across ticks)

    // Per-tick event counters (incremented at point of occurrence)
    NewBirths: Integer;
    NewDeaths: Integer;
  end;

  // births and deaths that occur during the tick
  TPopulationEventKind = (pekBirth, pekDeath);
  TPopulationEvent = record
    Kind: TPopulationEventKind;
    AgentId: TAgentId;
    Age: Integer;
    InitialReserves: Single;
    ParentAgentId: TAgentId;  // from state.ParentId
    Birthplace: TCellIndex;
    Mutation: TGeneSequence;  // check what Default(TGeneSequence) does, use as mutation flag (#0 probably)
  end;

  TMetabolicState = record
    Age: Integer;
    Reserves: Single;
    ReserveDelta: Single;
    GeneSequence: TGeneSequence;
    MoleculeFactors: TMoleculeFactors;
    ForageMoleculeWeights: TMoleculeFactors;
    DecisionWeights: TDecisionWeights;
  end;

// ======== May Logging end



  TSimEventHeader = record
    Sequence: Integer;
    DayNumber: Integer;
    DayTick: TDayTick;
    Phase: TSimTickPhase;
    Kind: TSimEventKind;
  end;

  TActionResolvedEvent = record
    AgentId: TAgentId;
    RequestedAction: TAgentAction;
    RequestedTarget: TTarget;
    ResolvedAction: TAgentAction;
    ResolvedTarget: TTarget;
    Reserves: Single;
    GestationProgress: Integer;
  end;

  TDecisionTraceEvent = record
    AgentId: TAgentId;
    Cell: TCellIndex;
    RequestedAction: TAgentAction;
    RequestedTarget: TTarget;
    ResolvedAction: TAgentAction;
    ResolvedTarget: TTarget;
    ForageOutcome: TForageOutcome;
    Evaluations: TActionEvaluations;
    Summary: TBrainTraceSummary;
  end;

  TAgentMovedEvent = record
    AgentId: TAgentId;
    FromCell: TCellIndex;
    ToCell: TCellIndex;
    MoveCost: Single;
    Reserves: Single;
  end;

  TAgentBornEvent = record
    AgentId: TAgentId;
    ParentAgentId: TAgentId;
    Cell: TCellIndex;
    InitialReserves: Single;
  end;

  TDeltaConsumedEvent = record
    AgentId: TAgentId;
    Cell: TCellIndex;
    Cache: TCacheRef;
    ConsumedAmount: Single;
    GainAmount: Single;
  end;

  TAgentDiedEvent = record
    AgentId: TAgentId;
    Cell: TCellIndex;
    Age: Integer;
    ReservesBeforeDeath: Single;
  end;

  TSimEvent = record
    Header: TSimEventHeader;
    ActionResolved: TActionResolvedEvent;
    DecisionTrace: TDecisionTraceEvent;
    AgentBorn: TAgentBornEvent;
    AgentMoved: TAgentMovedEvent;
    DeltaConsumed: TDeltaConsumedEvent;
    AgentDied: TAgentDiedEvent;
    PopulationSummary: TPopulationSummary;
  end;

  TSimEventFilter = record
    Kinds: TSimEventKinds;
    AgentId: Integer;
    CellIndex: Integer;
  end;

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