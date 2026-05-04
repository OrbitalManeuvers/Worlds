unit u_SimDiagnosticsIntf;

interface

uses
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
    SessionId: Integer;
    Sequence: Int64;
    DayNumber: Cardinal;
    DayTick: TDayTick;
    Phase: TSimTickPhase;
    Kind: TSimEventKind;
  end;

  TActionResolvedEvent = record
    AgentId: Integer;
    RequestedAction: TAgentAction;
    RequestedTarget: TTarget;
    ResolvedAction: TAgentAction;
    ResolvedTarget: TTarget;
    Reserves: Single;
    ActionProgress: Integer;
    Note: TActionResolutionNote;
  end;

  TDecisionTraceEvent = record
    AgentId: Integer;
    CellIndex: Integer;
    IsNight: Boolean;
    RequestedAction: TAgentAction;
    RequestedTarget: TTarget;
    ResolvedAction: TAgentAction;
    ResolvedTarget: TTarget;
    ForageConsumed: Single;
    ForageGain: Single;
    ForageEfficiency: Single;
    Evaluations: TActionEvaluations;
    Summary: TBrainTraceSummary;
  end;

  TAgentMovedEvent = record
    AgentId: Integer;
    FromCell: Integer;
    ToCell: Integer;
    MoveCost: Single;
    Reserves: Single;
  end;

  TAgentBornEvent = record
    AgentId: Integer;
    ParentAgentId: Integer;
    CellIndex: Integer;
    InitialReserves: Single;
  end;

  TBiomassCreatedEvent = record
    CellIndex: Integer;
    Amount: Single;
    Reason: TBiomassCreateReason;
    SourceAgentId: Integer;
  end;

  TBiomassConsumedEvent = record
    AgentId: Integer;
    CellIndex: Integer;
    Cache: TCacheRef;
    ConsumedAmount: Single;
    GainAmount: Single;
  end;

  TAgentDiedEvent = record
    AgentId: Integer;
    CellIndex: Integer;
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

  TSimEventFilter = record
    Kinds: TSimEventKinds;
    AgentId: Integer;
    CellIndex: Integer;
  end;

  ISimDiagnosticsSink = interface
    ['{E9073AA2-4F5D-47F3-BD9E-711D2DB53F9D}']
    procedure Emit(const Event: TSimEvent);
  end;

  ISimEventConsumer = interface
    ['{0FF03D6F-0DBE-4924-9771-2D658A479FD5}']
    procedure Consume(const Event: TSimEvent);
  end;

function AnySimEventKinds: TSimEventKinds;
function AnySimEventFilter: TSimEventFilter;


implementation

function AnySimEventKinds: TSimEventKinds;
begin
  Result := [Low(TSimEventKind)..High(TSimEventKind)];
end;

function AnySimEventFilter: TSimEventFilter;
begin
  Result.Kinds := AnySimEventKinds;
  Result.AgentId := -1;
  Result.CellIndex := -1;
end;

end.