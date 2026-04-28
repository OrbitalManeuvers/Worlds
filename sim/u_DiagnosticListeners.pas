unit u_DiagnosticListeners;

interface

uses u_SimDiagnosticsIntf;

type
  TLogEvent = procedure (const Msg: string) of object;

  TAgentListener = class(TInterfacedObject, ISimEventConsumer)
  private
    fOnLog: TLogEvent;
    procedure Consume(const Event: TSimEvent);
  public
    property OnLog: TLogEvent read fOnLog write fOnLog;
  end;

implementation

uses System.SysUtils;

{ TAgentListener }

procedure TAgentListener.Consume(const Event: TSimEvent);
begin
  if Assigned(fOnLog) then
  begin
    var msg := '';

    case Event.Header.Kind of
      sekAgentBorn:
        msg := Format('agent %d born from %d at %d reserves %.3f', [
          Event.AgentBorn.AgentId,
          Event.AgentBorn.ParentAgentId,
          Event.AgentBorn.CellIndex,
          Event.AgentBorn.InitialReserves
        ]);
      sekAgentMoved:
        msg := Format('%d moved from %d to %d cost %f', [
          Event.AgentMoved.AgentId,
          Event.AgentMoved.FromCell,
          Event.AgentMoved.ToCell,
          Event.AgentMoved.MoveCost
        ]);
    end;

    if msg <> '' then
      fOnLog(msg);
  end;

end;

end.
