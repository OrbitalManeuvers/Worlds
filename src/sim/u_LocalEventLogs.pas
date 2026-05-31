unit u_LocalEventLogs;

interface

uses System.Classes, System.Generics.Collections,
  u_SimEventTypes;

type
  TLocalEventLog = class(TInterfacedObject, ISimEventConsumer, IEventLog)
  private
    fEvents: TList<TSimEvent>;

    // ISimEventConsumer
    procedure Consume(const aEvent: TSimEvent);

    // IEventLog
    function GetCount: Integer;
    function GetEvent(aIndex: Integer): TSimEvent;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TLocalEventLog }

constructor TLocalEventLog.Create;
begin
  inherited Create;
  fEvents := TList<TSimEvent>.Create;
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

function TLocalEventLog.GetEvent(aIndex: Integer): TSimEvent;
begin
  Result := fEvents[aIndex];
end;

procedure TLocalEventLog.Consume(const aEvent: TSimEvent);
begin
  //
end;


end.
