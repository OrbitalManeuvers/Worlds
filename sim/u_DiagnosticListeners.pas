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

uses System.SysUtils, u_AgentTypes;

function ActionToShortStr(aAction: TAgentAction): string;
const
  actionStrs: array[TAgentAction] of string = ('Move', 'Forage', 'Shelter', 'Repro', 'Idle');
begin
  Result := actionStrs[aAction];
end;

function CacheToShortStr(const Cache: TCacheRef): string;
begin
  case Cache.Kind of
    ckResource:
      Result := 'Resource:' + Cache.Index.ToString;
    ckBiomass:
      Result := 'Biomass:' + Cache.Index.ToString;
  end;
end;

function TargetToShortStr(const Target: TTarget): string;
begin
  case Target.TType of
    ttCell:
      Result := 'Cell:' + Target.Cell.ToString;
    ttCache:
      Result := CacheToShortStr(Target.Cache);
  else
    Result := 'None';
  end;
end;

function ActionResolutionNoteToShortStr(aNote: TActionResolutionNote): string;
const
  noteStrs: array[TActionResolutionNote] of string = (
    '',
    'LowReserves',
    'GestStart',
    'GestKeep',
    'GestDone'
  );
begin
  Result := noteStrs[aNote];
end;

{ TAgentListener }

procedure TAgentListener.Consume(const Event: TSimEvent);
begin
  if Assigned(fOnLog) then
  begin
    var msg := '';

    case Event.Header.Kind of
      sekActionResolved:
        begin
          msg := Format('%.2d:%.3d agent %d req %s(%s) res %s(%s) reserves %.3f', [
            Event.Header.DayNumber,
            Event.Header.DayTick,
            Event.ActionResolved.AgentId,
            ActionToShortStr(Event.ActionResolved.RequestedAction),
            TargetToShortStr(Event.ActionResolved.RequestedTarget),
            ActionToShortStr(Event.ActionResolved.ResolvedAction),
            TargetToShortStr(Event.ActionResolved.ResolvedTarget),
            Event.ActionResolved.Reserves
          ]);
          var lifecycle := '';
          if (Event.ActionResolved.ActionProgress > 0) or (Event.ActionResolved.Note <> arnNone) then
          begin
            lifecycle := ' ap ' + Event.ActionResolved.ActionProgress.ToString;
            var noteStr := ActionResolutionNoteToShortStr(Event.ActionResolved.Note);
            if noteStr <> '' then
              lifecycle := lifecycle + ' note ' + noteStr;
          end;

          msg := msg + lifecycle;
        end;
      sekAgentBorn:
        msg := Format('%.2d:%.3d agent %d born from %d at %d reserves %.3f', [
          Event.Header.DayNumber,
          Event.Header.DayTick,
          Event.AgentBorn.AgentId,
          Event.AgentBorn.ParentAgentId,
          Event.AgentBorn.CellIndex,
          Event.AgentBorn.InitialReserves
        ]);
      sekAgentMoved:
        msg := Format('%.2d:%.3d %d moved from %d to %d cost %f res %f', [
          Event.Header.DayNumber,
          Event.Header.DayTick,
          Event.AgentMoved.AgentId,
          Event.AgentMoved.FromCell,
          Event.AgentMoved.ToCell,
          Event.AgentMoved.MoveCost,
          Event.AgentMoved.Reserves
        ]);
      sekAgentDied:
        msg := Format('%.2d:%.3d agent %d died at %d age %d reserves-before %.3f', [
          Event.Header.DayNumber,
          Event.Header.DayTick,
          Event.AgentDied.AgentId,
          Event.AgentDied.CellIndex,
          Event.AgentDied.Age,
          Event.AgentDied.ReservesBeforeDeath
        ]);
    end;

    if msg <> '' then
      fOnLog(msg);
  end;

end;

end.
