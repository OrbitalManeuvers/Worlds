unit u_SimDiagnostics;

interface

uses
  System.Generics.Collections,
  u_SimDiagnosticsIntf;

type
  TSimEventSubscription = record
    Id: Integer;
    Filter: TSimEventFilter;
    Consumer: ISimEventConsumer;
  end;

  TSimDiagnosticsHub = class(TInterfacedObject, ISimDiagnosticsSink)
  private
    fSessionId: Integer;
    fNextSequence: Int64;
    fNextSubscriptionId: Integer;
    fSubscriptions: TList<TSimEventSubscription>;
    function Matches(const Filter: TSimEventFilter; const Event: TSimEvent): Boolean;
  public
    constructor Create(aSessionId: Integer = 0);
    destructor Destroy; override;

    procedure Emit(const Event: TSimEvent);
    function NextSequence: Int64;

    function Subscribe(const Filter: TSimEventFilter; const Consumer: ISimEventConsumer): Integer;
    procedure Unsubscribe(SubscriptionId: Integer);
  end;


implementation

{ TSimDiagnosticsHub }

constructor TSimDiagnosticsHub.Create(aSessionId: Integer);
begin
  inherited Create;
  fSessionId := aSessionId;
  fSubscriptions := TList<TSimEventSubscription>.Create;
end;

destructor TSimDiagnosticsHub.Destroy;
begin
  fSubscriptions.Free;
  inherited;
end;

procedure TSimDiagnosticsHub.Emit(const Event: TSimEvent);
begin
  var stampedEvent := Event;
  stampedEvent.Header.SessionId := fSessionId;
  stampedEvent.Header.Sequence := NextSequence;

  for var subscription in fSubscriptions do
  begin
    if not Matches(subscription.Filter, stampedEvent) then
      Continue;

    if Assigned(subscription.Consumer) then
      subscription.Consumer.Consume(stampedEvent);
  end;
end;

function TSimDiagnosticsHub.Matches(const Filter: TSimEventFilter; const Event: TSimEvent): Boolean;
begin
  Result := Event.Header.Kind in Filter.Kinds;
  if not Result then
    Exit;

  if (Filter.AgentId <> -1) then
  begin
    case Event.Header.Kind of
      sekActionResolved:
        Result := Event.ActionResolved.AgentId = Filter.AgentId;
      sekDecisionTrace:
        Result := Event.DecisionTrace.AgentId = Filter.AgentId;
      sekAgentBorn:
        Result := (Event.AgentBorn.AgentId = Filter.AgentId)
          or (Event.AgentBorn.ParentAgentId = Filter.AgentId);
      sekAgentMoved:
        Result := Event.AgentMoved.AgentId = Filter.AgentId;
      sekBiomassConsumed:
        Result := Event.BiomassConsumed.AgentId = Filter.AgentId;
      sekAgentDied:
        Result := Event.AgentDied.AgentId = Filter.AgentId;
      sekResourceSampled:
        Result := False;
    else
      Result := Event.BiomassCreated.SourceAgentId = Filter.AgentId;
    end;
  end;

  if Result and (Filter.CellIndex <> -1) then
  begin
    case Event.Header.Kind of
      sekDecisionTrace:
        Result := Event.DecisionTrace.CellIndex = Filter.CellIndex;
      sekAgentBorn:
        Result := Event.AgentBorn.CellIndex = Filter.CellIndex;
      sekAgentMoved:
        Result := (Event.AgentMoved.FromCell = Filter.CellIndex) or (Event.AgentMoved.ToCell = Filter.CellIndex);
      sekBiomassCreated:
        Result := Event.BiomassCreated.CellIndex = Filter.CellIndex;
      sekBiomassConsumed:
        Result := Event.BiomassConsumed.CellIndex = Filter.CellIndex;
      sekAgentDied:
        Result := Event.AgentDied.CellIndex = Filter.CellIndex;
    else
      Result := False;
    end;
  end;
end;

function TSimDiagnosticsHub.NextSequence: Int64;
begin
  Inc(fNextSequence);
  Result := fNextSequence;
end;

function TSimDiagnosticsHub.Subscribe(const Filter: TSimEventFilter;
  const Consumer: ISimEventConsumer): Integer;
begin
  Inc(fNextSubscriptionId);

  var subscription: TSimEventSubscription;
  subscription.Id := fNextSubscriptionId;
  subscription.Filter := Filter;
  subscription.Consumer := Consumer;

  fSubscriptions.Add(subscription);
  Result := subscription.Id;
end;

procedure TSimDiagnosticsHub.Unsubscribe(SubscriptionId: Integer);
begin
  for var i := 0 to fSubscriptions.Count - 1 do
    if fSubscriptions[i].Id = SubscriptionId then
    begin
      fSubscriptions.Delete(i);
      Exit;
    end;
end;

end.