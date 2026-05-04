unit u_EventSinks;

interface

uses System.Classes, System.Generics.Collections,
  u_EventSinkIntf, u_SimDiagnosticsIntf, u_MulticastEvents;

type
  TEventSink = class(TInterfacedObject, IEventSink, IEventLog)
  private
    fEvents: TList<TSimEvent>;
    fNotifyEvent: TMulticastEvent<TNotifyEvent>;

    // IEventSink
    procedure Write(aEvent: TSimEvent);

    // IEventLog
    procedure Subscribe(const aHandler: TNotifyEvent);
    procedure Unsubscribe(const aHandler: TNotifyEvent);
    function GetCount: Integer;
    function GetEvent(aIndex: Integer): TSimEvent;

  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TEventSink }

constructor TEventSink.Create;
begin
  inherited Create;
  fEvents := TList<TSimEvent>.Create;
  fNotifyEvent := TMulticastEvent<TNotifyEvent>.Create;
end;

destructor TEventSink.Destroy;
begin
  fNotifyEvent.Free;
  fEvents.Free;
  inherited;
end;

function TEventSink.GetCount: Integer;
begin
  Result := fEvents.Count;
end;

function TEventSink.GetEvent(aIndex: Integer): TSimEvent;
begin
  Result := fEvents[aIndex];
end;

procedure TEventSink.Subscribe(const aHandler: TNotifyEvent);
begin
  fNotifyEvent.Subscribe(aHandler);
end;

procedure TEventSink.Unsubscribe(const aHandler: TNotifyEvent);
begin
  fNotifyEvent.Unsubscribe(aHandler);
end;

procedure TEventSink.Write(aEvent: TSimEvent);
begin
  fEvents.Add(aEvent);
  fNotifyEvent.Notify(
    procedure(Handler: TNotifyEvent)
    begin
      Handler(Self);
    end
  );
end;

end.
