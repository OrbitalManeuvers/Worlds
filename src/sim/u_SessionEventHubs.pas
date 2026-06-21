unit u_SessionEventHubs;

interface

uses System.Generics.Collections,
  u_SessionEventTypes;

type
  TSessionEventSubscription = record
    Id: Integer;
    Consumer: ISessionEventConsumer;
  end;

  TSessionEventHub = class(TInterfacedObject, ISessionEventSink, ISessionEventHub)
  private
    procedure Emit(const Event: TSessionEvent);
  private
    fNextSubscriptionId: Integer;
    fSubscriptions: TList<TSessionEventSubscription>;
  public
    constructor Create;
    destructor Destroy; override;

    function Subscribe(const Consumer: ISessionEventConsumer): Integer;
    procedure Unsubscribe(SubscriptionId: Integer);
  end;

implementation

{ TSessionEventHub }

constructor TSessionEventHub.Create;
begin
  inherited Create;
  fSubscriptions := TList<TSessionEventSubscription>.Create;
end;

destructor TSessionEventHub.Destroy;
begin
  fSubscriptions.Free;
  inherited;
end;

procedure TSessionEventHub.Emit(const Event: TSessionEvent);
begin
  var stampedEvent := Event;

  for var subscription in fSubscriptions do
  begin
    if Assigned(subscription.Consumer) then
      subscription.Consumer.Consume(stampedEvent);
  end;
end;

function TSessionEventHub.Subscribe(const Consumer: ISessionEventConsumer): Integer;
begin
  Inc(fNextSubscriptionId);

  var subscription: TSessionEventSubscription;
  subscription.Id := fNextSubscriptionId;
  subscription.Consumer := Consumer;

  fSubscriptions.Add(subscription);
  Result := subscription.Id;
end;

procedure TSessionEventHub.Unsubscribe(SubscriptionId: Integer);
begin
  for var i := 0 to fSubscriptions.Count - 1 do
    if fSubscriptions[i].Id = SubscriptionId then
    begin
      fSubscriptions.Delete(i);
      Exit;
    end;
end;

end.
