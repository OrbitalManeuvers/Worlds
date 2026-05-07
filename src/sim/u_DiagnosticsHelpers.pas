unit u_DiagnosticsHelpers;

interface

uses System.SysUtils, System.TypInfo,
  u_SimEventTypes, u_AgentTypes;

type
  _simEvent = record helper for TSimEvent
    function AsDebugLine: string;
  end;

  _decisionTraceEvent = record helper for TDecisionTraceEvent
    function AsFields: string;
  end;

//  _agentMovedEvent = record helper for TAgentMovedEvent
//    function AsFields: string;
//  end;

implementation

uses System.Types;

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

function PointToShortStr(aValue: TPoint): string;
begin
  Result := '(' + aValue.X.ToString + ',' + aValue.Y.ToString + ')';
//  Result := Format('%d:%d', [aValue.X, aValue.Y])
end;

//function TargetToShortStr(const Target: TTarget): string;
//begin
//  case Target.TType of
//    ttCell:
//      Result := 'Cell:' + Target.Cell.ToString;
//    ttCache:
//      Result := CacheToShortStr(Target.Cache);
//  else
//    Result := 'None';
//  end;
//end;

function TargetRefToShortStr(const Target: TTargetRef): string;
begin
  case Target.TType of
    ttCell:
      Result := PointToShortStr(Target.Cell);
    ttCache:
      Result := CacheToShortStr(Target.Cache);
  else
    Result := 'None';
  end;
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

function BiomassCreateReasonToShortStr(const Reason: TBiomassCreateReason): string;
const
  reasonStrs: array[TBiomassCreateReason] of string = (
    'Unknown',
    'Nightfall',
    'RandNight',
    'AgentDeath'
  );
begin
  Result := reasonStrs[Reason];
end;

function CellIndexToStr(aCellIndex, aGridWidth: Integer): string;
begin
  Result := Format('(%d, %d)', [aCellIndex mod aGridWidth, aCellIndex div aGridWidth]);
end;

function DecisionTraceToStr(const d: TDecisionTraceEvent): string;
begin
    var did := '';
    if d.RequestedAction = d.ResolvedAction then
    begin
      // did a thing
      case d.ResolvedAction of
        acMove: did := 'moved to ' + PointToShortStr(d.ResolvedTarget.Cell);
        acForage: did := 'ate ' + d.ResolvedTarget.Cache.Index.ToString + ' ' + FloatToLogStr(d.ForageGain);
        acShelter: did := 'zzz';
        acReproduce: ;
        acIdle: ;
      end;
    end;

  Result := Format(
    'A%.02d %s', [d.AgentId, did]);



//          'a:%.02d cell=%d req=%s(%s) res=%s(%s) night=%s in=%s out=%s eff=%s', [
//            DecisionTrace.AgentId,
//            DecisionTrace.CellIndex,
//            ActionToShortStr(DecisionTrace.RequestedAction),
//            TargetToShortStr(DecisionTrace.RequestedTarget),
//            ActionToShortStr(DecisionTrace.ResolvedAction),
//            TargetToShortStr(DecisionTrace.ResolvedTarget),
//            BoolToLogStr(DecisionTrace.IsNight),
//            FloatToLogStr(DecisionTrace.ForageConsumed),
//            FloatToLogStr(DecisionTrace.ForageGain),
//            FloatToLogStr(DecisionTrace.ForageEfficiency)

end;

{ _simEvent }

function _simEvent.AsDebugLine: string;
begin
//  Result := Format('%.04d [%.02d:%.03d] %-16s ', [
  Result := Format('%.04d [%.02d:%.03d] ', [
    Header.Sequence,
    Header.DayNumber,
    Header.DayTick // ,
//    GetEnumName(TypeInfo(TSimEventKind), Ord(Header.Kind))
  ]);

  case Header.Kind of
    sekActionResolved:
      Result := Result + Format(
        'a:%.02d req:%s(%s) res:%s(%s) rsrvs=%s prog=%d note=%d', [
          ActionResolved.AgentId,
          ActionToShortStr(ActionResolved.RequestedAction),
          TargetRefToShortStr(ActionResolved.RequestedTarget),
          ActionToShortStr(ActionResolved.ResolvedAction),
          TargetRefToShortStr(ActionResolved.ResolvedTarget),
          FloatToLogStr(ActionResolved.Reserves),
          ActionResolved.ActionProgress,
          Ord(ActionResolved.Note)
        ]);
    sekDecisionTrace:
      begin
        Result := Result + DecisionTraceToStr(DecisionTrace);
//        Result := Result + Format(
//          'a:%.02d %s req=%s%s res=%s%s night=%s in=%s out=%s eff=%s', [
//            DecisionTrace.AgentId,
//            PointToShortStr(DecisionTrace.Cell),
//            ActionToShortStr(DecisionTrace.RequestedAction),
//            TargetRefToShortStr(DecisionTrace.RequestedTarget),
//            ActionToShortStr(DecisionTrace.ResolvedAction),
//            TargetRefToShortStr(DecisionTrace.ResolvedTarget),
//            BoolToLogStr(DecisionTrace.IsNight),
//            FloatToLogStr(DecisionTrace.ForageConsumed),
//            FloatToLogStr(DecisionTrace.ForageGain),
//            FloatToLogStr(DecisionTrace.ForageEfficiency)
//          ]);
      end;
    sekAgentBorn:
      Result := Result + Format('agent=%d parent=%d cell=%d:%d reserves=%s', [
        AgentBorn.AgentId,
        AgentBorn.ParentAgentId,
        AgentBorn.Cell.X, AgentBorn.Cell.Y,
        FloatToLogStr(AgentBorn.InitialReserves)
      ]);
    sekAgentMoved:
      Result := Result + Format('agent=%d from=%d:%d to=%d:%d moveCost=%s reserves=%s', [
        AgentMoved.AgentId,
        AgentMoved.FromCell.X, AgentMoved.FromCell.Y,
        AgentMoved.ToCell.X, AgentMoved.ToCell.Y,
        FloatToLogStr(AgentMoved.MoveCost),
        FloatToLogStr(AgentMoved.Reserves)
      ]);
    sekBiomassCreated:
      Result := Result + Format('cell=%s amount=%s reason=%s sourceAgent=%d', [
        PointToShortStr(BiomassCreated.Cell),
        FloatToLogStr(BiomassCreated.Amount),
        BiomassCreateReasonToShortStr(BiomassCreated.Reason),
        BiomassCreated.SourceAgentId
      ]);
    sekBiomassConsumed:
      Result := Result + Format('agent=%d cell=%s cache=%s consumed=%s gain=%s', [
        BiomassConsumed.AgentId,
        PointToShortStr(BiomassConsumed.Cell),
        CacheToShortStr(BiomassConsumed.Cache),
        FloatToLogStr(BiomassConsumed.ConsumedAmount),
        FloatToLogStr(BiomassConsumed.GainAmount)
      ]);
    sekAgentDied:
      Result := Result + Format('agent=%d cell=%s age=%d reservesBefore=%s', [
        AgentDied.AgentId,
        PointToShortStr(AgentDied.Cell),
        AgentDied.Age,
        FloatToLogStr(AgentDied.ReservesBeforeDeath)
      ]);
    sekResourceSampled:
      Result := Result + Format('cache=%d amount=%s regenDebt=%s', [
        ResourceSampled.CacheIndex,
        FloatToLogStr(ResourceSampled.Amount),
        FloatToLogStr(ResourceSampled.RegenDebt)
      ]);
  end;
end;

(*

  TAgentMovedEvent = record
    AgentId: Integer;
    FromCell: Integer;
    ToCell: Integer;
    MoveCost: Single;
    Reserves: Single;
  end;
  TDecisionTraceEvent = record
    AgentId: Integer;
    CellIndex: Integer;
    IsNight: Boolean;
    RequestedAction: TAgentAction;
    RequestedTarget: TTarget;
    ResolvedAction: TAgentAction;
    ResolvedTarget: TTarget;
    ForageConsumed: Single;
    ForageGain: Single;
    ForageEfficiency: Single;
    Evaluations: TActionEvaluations;
    Summary: TBrainTraceSummary;
  end;

*)

{ _decisionTraceEvent }

function _decisionTraceEvent.AsFields: string;
begin
  Result := '';
end;

end.
