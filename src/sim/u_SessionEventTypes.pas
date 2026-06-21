unit u_SessionEventTypes;

interface

uses u_SimTypes, u_AgentGenome, u_EnvironmentTypes, u_RuntimeTypes;

type
  TSessionEventKind = (sekPrePopulation, sekPostPopulation, sekBirth, sekDeath);

  TSessionEventHeader = record
    GlobalTick: Integer;
    Date: TSimDate;
  end;

  TSessionPrePopulationEvent = record
    PopulationSize: Integer;
    DeathsToDate: Integer;
    MutationsToDate: Integer;
    LongestLife: Word;
    MostBirths: Word;
  end;

  TSessionPostPopulationEvent = record
    Births: Word;
    Mutations: Word;
    Deaths: Word;
  end;

  TSessionBirthEvent = record
    AgentId: TAgentId;
    ParentId: TAgentId;
    Sequence: TGeneSequence;
    ParentSequence: TGeneSequence;
    OffspringNumber: Integer;
    Location: TCellIndex;
  end;

  TSessionDeathEvent = record
    AgentId: TAgentId;
    Age: Integer;
    Location: TCellIndex;
    LastAction: TAgentAction;
  end;

  TSessionEvent = record
    Header: TSessionEventHeader;
    case EventKind: TSessionEventKind of
      sekPrePopulation: (Prepop: TSessionPrepopulationEvent);
      sekPostPopulation: (PostPop: TSessionPostPopulationEvent);
      sekBirth: (Birth: TSessionBirthEvent);
      sekDeath: (Death: TSessionDeathEvent);
  end;


  ISessionEventSink = interface
  ['{29ACEA43-F77B-4B76-BA48-7368F515C47F}']
    procedure Emit(const Event: TSessionEvent);
  end;

  ISessionEventConsumer = interface
  ['{C5DA360C-A89F-4810-B9FA-E3C70CBDF217}']
    procedure Consume(const Event: TSessionEvent);
  end;

  ISessionEventHub = interface
  ['{CB4AECE4-1779-41DF-A8A1-46A0929ECA9F}']
    function Subscribe(const Consumer: ISessionEventConsumer): Integer;
    procedure Unsubscribe(SubscriptionId: Integer);
  end;

  ISessionEventLog = interface
  ['{80F74955-E977-4397-B078-4F5E459986F9}']
    function GetCount: Integer;
    function GetEvent(aIndex: Integer): TSessionEvent;
    property Count: Integer read GetCount;
    property Events[aIndex: Integer]: TSessionEvent read GetEvent;
  end;

implementation

end.
