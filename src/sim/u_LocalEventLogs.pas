unit u_LocalEventLogs;

interface

uses System.Classes, System.Generics.Collections,
  u_SessionEventTypes;

type
  TLocalEventLog = class(TInterfacedObject, ISessionEventConsumer, ISessionEventLog)
  private
    fEvents: TList<TSessionEvent>;

    // ISessionEventConsumer
    procedure Consume(const aEvent: TSessionEvent);

    // ISessionEventLog
    function GetCount: Integer;
    function GetEvent(aIndex: Integer): TSessionEvent;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TLocalEventLog }

constructor TLocalEventLog.Create;
begin
  inherited Create;
  fEvents := TList<TSessionEvent>.Create;
end;

destructor TLocalEventLog.Destroy;
begin
  fEvents.Free;
  inherited;
end;

function TLocalEventLog.GetCount: Integer;
begin
  Result := fEvents.Count;
end;

function TLocalEventLog.GetEvent(aIndex: Integer): TSessionEvent;
begin
  Result := fEvents[aIndex];
end;

procedure TLocalEventLog.Consume(const aEvent: TSessionEvent);
begin
  //
end;


end.
