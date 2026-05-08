unit u_SimDiagnostics;

interface

uses
  System.Generics.Collections,
  u_SimEventTypes;

type
  TSimEventSubscription = record
    Id: Integer;
    Consumer: ISimEventConsumer;
  end;

  TSimDiagnosticsHub = class(TInterfacedObject, ISimDiagnosticsSink)
  private
    fSessionId: Integer;
    fNextSequence: Integer;
    fNextSubscriptionId: Integer;
    fSubscriptions: TList<TSimEventSubscription>;
  public
    constructor Create(aSessionId: Integer = 0);
    destructor Destroy; override;

    procedure Emit(const Event: TSimEvent);
    function NextSequence: Integer;

    function Subscribe(const Consumer: ISimEventConsumer): Integer;
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
    if Assigned(subscription.Consumer) then
      subscription.Consumer.Consume(stampedEvent);
  end;
end;

function TSimDiagnosticsHub.NextSequence: Integer;
begin
  Inc(fNextSequence);
  Result := fNextSequence;
end;

function TSimDiagnosticsHub.Subscribe(const Consumer: ISimEventConsumer): Integer;
begin
  Inc(fNextSubscriptionId);

  var subscription: TSimEventSubscription;
  subscription.Id := fNextSubscriptionId;
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