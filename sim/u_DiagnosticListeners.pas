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

uses System.SysUtils, u_AgentTypes, u_AgentGenome;

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

function EnergyLevelToShortStr(aEnergyLevel: TEnergyLevel): string;
const
  energyStrs: array[TEnergyLevel] of string = ('Empty', 'Low', 'Medium', 'High', 'Full');
begin
  Result := energyStrs[aEnergyLevel];
end;

function BoolToLogStr(const Value: Boolean): string;
begin
  if Value then
    Result := 'T'
  else
    Result := 'F';
end;

function FloatToLogStr(const Value: Single): string;
begin
  Result := FloatToStrF(Value, ffFixed, 18, 3);
end;

function FormatActionEvaluations(const Evaluations: TActionEvaluations): string;
begin
  Result := Format('scores M:%s(%s) F:%s(%s) S:%s(%s) R:%s(%s) I:%s(%s)', [
    FloatToLogStr(Evaluations[acMove].Score),
    TargetToShortStr(Evaluations[acMove].Target),
    FloatToLogStr(Evaluations[acForage].Score),
    TargetToShortStr(Evaluations[acForage].Target),
    FloatToLogStr(Evaluations[acShelter].Score),
    TargetToShortStr(Evaluations[acShelter].Target),
    FloatToLogStr(Evaluations[acReproduce].Score),
    TargetToShortStr(Evaluations[acReproduce].Target),
    FloatToLogStr(Evaluations[acIdle].Score),
    TargetToShortStr(Evaluations[acIdle].Target)
  ]);
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
      sekDecisionTrace:
        msg := Format(
          '%.2d:%.3d trace agent %d cell %d req %s(%s) res %s(%s) night %s flux %s dFlux %s dRes %s energy %s ap %d tsr %d local %d smellMax %s smellTop [n:%d c:%s d:%d s:%s] threat %s smell %s sight %s conv [in:%s out:%s eff:%s] %s',
          [
            Event.Header.DayNumber,
            Event.Header.DayTick,
            Event.DecisionTrace.AgentId,
            Event.DecisionTrace.CellIndex,
            ActionToShortStr(Event.DecisionTrace.RequestedAction),
            TargetToShortStr(Event.DecisionTrace.RequestedTarget),
            ActionToShortStr(Event.DecisionTrace.ResolvedAction),
            TargetToShortStr(Event.DecisionTrace.ResolvedTarget),
            BoolToLogStr(Event.DecisionTrace.IsNight),
            FloatToLogStr(Event.DecisionTrace.Summary.SolarFlux),
            FloatToLogStr(Event.DecisionTrace.Summary.SolarFluxDelta),
            FloatToLogStr(Event.DecisionTrace.Summary.ReserveDelta),
            EnergyLevelToShortStr(Event.DecisionTrace.Summary.EnergyLevel),
            Event.DecisionTrace.Summary.ActionProgress,
            Event.DecisionTrace.Summary.TicksSinceReproduction,
            Event.DecisionTrace.Summary.LocalAgentCount,
            FloatToLogStr(Event.DecisionTrace.Summary.StrongestSmellSignal),
            Event.DecisionTrace.Summary.SmellCandidateCount,
            CacheToShortStr(Event.DecisionTrace.Summary.TopSmellCache),
            Event.DecisionTrace.Summary.TopSmellDistance,
            FloatToLogStr(Event.DecisionTrace.Summary.TopSmellSignal),
            FloatToLogStr(Event.DecisionTrace.Summary.ThreatPressure),
            BoolToLogStr(Event.DecisionTrace.Summary.HadSmellTarget),
            BoolToLogStr(Event.DecisionTrace.Summary.HadSightTarget),
            FloatToLogStr(Event.DecisionTrace.ForageConsumed),
            FloatToLogStr(Event.DecisionTrace.ForageGain),
            FloatToLogStr(Event.DecisionTrace.ForageEfficiency),
            FormatActionEvaluations(Event.DecisionTrace.Evaluations)
          ]);
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
      sekResourceSampled:
        msg := Format('%.2d:%.3d resource cache %d amount %.4f debt %.4f', [
          Event.Header.DayNumber,
          Event.Header.DayTick,
          Event.ResourceSampled.CacheIndex,
          Event.ResourceSampled.Amount,
          Event.ResourceSampled.RegenDebt
        ]);
    end;

    if msg <> '' then
      fOnLog(msg);
  end;

end;

end.
