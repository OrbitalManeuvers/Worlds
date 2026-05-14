unit u_DiagnosticsHelpers;

interface

uses System.Types, System.SysUtils, System.TypInfo,
  u_SimEventTypes, u_AgentTypes, u_AgentBrain,
  u_AgentGenome, u_LogTypes;


type

  // .AsText helpers for rendering a field value
  // --------------------------------------------

  // TPoint = X,Y
  _point = record helper for TPoint
    function AsText: string;
  end;

  // TAgentAction = abbrev
  _agentAction = record helper for TAgentAction
    function AsText: string;
  end;

  _biomassCreateReason = record helper for TBiomassCreateReason
    function AsText: string;
  end;

  _energyLevel = record helper for TEnergyLevel
    function AsText: string;
  end;

  // .AsField helpers if the type renders label(s) + value(s)
  // --------------------------------------------------------

  _targetRef = record helper for TTargetRef
    function AsText: string;
  end;

  _cacheRef =  record helper for TCacheRef
    function AsText: string;
  end;

  // .AsLogLine helpers for types that produce a complete line
  // ---------------------------------------------------------


  // TDecisionTraceEvent
  _decisionTraceEvent = record helper for TDecisionTraceEvent
    function AsMove: string;
    function AsForage: string;

    function AsLogLine: string;
    function AsFields: TLogFields;
  end;

  // TSimEvent
  _simEvent = record helper for TSimEvent
    function AsLogLine: string;
    function AsFields: TLogFields;
  end;


  // .AsDetails helpers for types that produce detail reports
  // ---------------------------------------------------------

  // TBrainTraceSummary
  _brainTraceSummary = record helper for TBrainTraceSummary
    function AsDetails: TArray<TLogField>;
  end;

  _ActionEvalResult = record helper for TActionEvalResult
    function AsDetails: TArray<TLogField>;
  end;



implementation


const
  CRLF = #13#10;

type
  _single = record helper for Single
    function AsText: string;
  end;

  _integer = record helper for Integer
    function AsText: string; overload;
    function AsText(Padding: Integer): string; overload;
  end;

{ _single }
function _single.AsText: string;
begin
  Result := FloatToStrF(Self, ffFixed, 18, 3);
end;

{ _integer }
function _integer.AsText: string;
begin
  Result := IntToStr(Self);
end;

function _integer.AsText(Padding: Integer): string;
begin
  Result := Format('%.0' + Padding.AsText + 'd', [Self]);
end;


{ _cacheRef }
function _cacheRef.AsText: string;
begin
  case Self.Kind of
    ckResource:
      Result := 'r:' + Self.Index.AsText;
    ckBiomass:
      Result := 'b:' + Self.Index.AsText;
  end;
end;

{ _targetRef }
function _targetRef.AsText: string;
begin
  case Self.TType of
    ttCell:
      Result := Self.Cell.AsText;
    ttCache:
      Result := Self.Cache.AsText;
  else
    Result := '?';
  end;
end;

{ _agentAction }

function _agentAction.AsText: string;
const
  actionStrs: array[TAgentAction] of string = ('mov', 'for', 'she', 'rep', 'idl');
begin
  Result := actionStrs[Self];
end;

{ _point }
function _point.AsText: string;
begin
  Result := X.AsText + ',' + Y.AsText;
end;

{ _biomassCreateReason }

function _biomassCreateReason.AsText: string;
const
  reasonStrs: array[TBiomassCreateReason] of string = (
    'Unknown',
    'Nightfall',
    'RandNight',
    'AgentDeath'
  );
begin
  Result := reasonStrs[Self];
end;

{ _energyLevel }
function _energyLevel.AsText: string;
const
  energyLevelStrs: array[TEnergyLevel] of string = ('e', 'l', 'm', 'h', 'f');
begin
  Result := energyLevelStrs[Self];
end;


{ _decisionTraceEvent }

function _decisionTraceEvent.AsMove: string;
begin
  // assume resolved = requested and it's a move
  Result := Format('%s', [ResolvedTarget.AsText]);
end;

function _decisionTraceEvent.AsForage: string;
begin
  Result := Format('%s con:%s gain:%s eff:%s',
    [ResolvedTarget.AsText,
     self.ForageConsumed.AsText,
     self.ForageGain.AsText,
     self.ForageEfficiency.AsText
    ]);
end;

function _decisionTraceEvent.AsLogLine: string;
begin
  var agentInfo := Format(
    'a:%.02d %s %s ',
    [ AgentId,
      Cell.AsText,
      Summary.EnergyLevel.AsText
    ]);

  var actionInfo := '';
  if ResolvedAction <> RequestedAction then
  begin
    // output line that shows request
  end
  else
  begin
    actionInfo := ResolvedAction.AsText + ' ';

    // otherwise they did what they wanted, so no need to report some stuff
    case ResolvedAction of
      acMove: actionInfo := actionInfo + Self.AsMove;
      acForage: actionInfo := actioninfo + Self.AsForage;
      acShelter: ;
      acReproduce: ;
      acIdle: ;
    end;


  end;

  Result := agentInfo + actioninfo;

//,
//     'a:%.02d %s (%s) rq:%s(%s) rs:%s(%s)',

//      RequestedAction.AsLogLine,
//      RequestedTarget.AsLogLine,
//      ResolvedAction.AsLogLine,
//      ResolvedTarget.AsLogLine
//          ' in=%s out=%s eff=%s', [
//            FloatToLogStr(DecisionTrace.ForageConsumed),
//            FloatToLogStr(DecisionTrace.ForageGain),
//            FloatToLogStr(DecisionTrace.ForageEfficiency)

end;

{ _brainTraceSummary }
function _brainTraceSummary.AsDetails: TArray<TLogField>;
begin
  SetLength(Result, 0);


(*
  Result := Format(
   'e-delta=%s|hadsmell=%s|smell-sig=%s',
   [
     self.ReserveDelta.AsText,
     self.HadSmellTarget.ToString(TUseBoolStrs.True),
     self.StrongestSmellSignal.AsText

   ]);

*)
end;

(*
  TActionEvalResult = record
    Score: Single;
    Target: TTarget;
  end;
  TActionEvaluations = array[TAgentAction] of TActionEvalResult;

*)

{ _ActionEvalResult }
function _ActionEvalResult.AsDetails: TArray<TLogField>;
begin
  SetLength(Result, 0);
//    Result := Self.Score.AsText;
end;


{ _simEvent }
function _simEvent.AsFields: TLogFields;
begin
  Result.Add('', Format('%.04d [%.02d:%.03d] ',
    [Header.Sequence, Header.DayNumber, Header.DayTick]));

  case Header.Kind of
    sekActionResolved: ;
    sekDecisionTrace:
      Result.Add('c', DecisionTrace.AsFields.ShortFieldText);
    sekAgentBorn: ;
    sekAgentMoved: ;
    sekBiomassCreated: ;
    sekBiomassConsumed: ;
    sekAgentDied: ;
    sekResourceSampled: ;
  end;

end;


function _simEvent.AsLogLine: string;
begin
  Result := Format('%.04d [%.02d:%.03d] ', [
    Header.Sequence,
    Header.DayNumber,
    Header.DayTick
  ]);

  case Header.Kind of
    sekActionResolved:
      Result := Result + Format(
        'a:%.02d req:%s(%s) res:%s(%s) rsrvs=%s prog=%d note=%d', [
          ActionResolved.AgentId,
          ActionResolved.RequestedAction.AsText,
          ActionResolved.RequestedTarget.AsText,
          ActionResolved.ResolvedAction.AsText,
          ActionResolved.ResolvedTarget.AsText,
          ActionResolved.Reserves.AsText,
          ActionResolved.ActionProgress,
          Ord(ActionResolved.Note)
        ]);
    sekDecisionTrace:
      begin
        Result := Result + DecisionTrace.AsFields.ShortFieldText();
//        decisionTrace.Summary.
//        Result := Result + DecisionTraceToStr(DecisionTrace);
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
      Result := Result + Format('agent=%d parent=%d cell=%s reserves=%s', [
        AgentBorn.AgentId,
        AgentBorn.ParentAgentId,
        AgentBorn.Cell.AsText,
        AgentBorn.InitialReserves.AsText
      ]);
    sekAgentMoved:
      Result := Result + Format('agent=%d from=%d:%d to=%d:%d moveCost=%s reserves=%s', [
        AgentMoved.AgentId,
        AgentMoved.FromCell.X, AgentMoved.FromCell.Y,
        AgentMoved.ToCell.X, AgentMoved.ToCell.Y,
        AgentMoved.MoveCost.AsText,
        AgentMoved.Reserves.AsText
      ]);
    sekBiomassCreated:
      Result := Result + Format('cell=%s amount=%s reason=%s sourceAgent=%d', [
        BiomassCreated.Cell.AsText,
        BiomassCreated.Amount.AsText,
        BiomassCreated.Reason.AsText,
        BiomassCreated.SourceAgentId
      ]);
    sekBiomassConsumed:
      Result := Result + Format('agent=%d cell=%s cache=%s consumed=%s gain=%s', [
        BiomassConsumed.AgentId,
        BiomassConsumed.Cell.AsText,
        BiomassConsumed.Cache.AsText,
        BiomassConsumed.ConsumedAmount.AsText,
        BiomassConsumed.GainAmount.AsText
      ]);
    sekAgentDied:
      Result := Result + Format('agent=%d cell=%s age=%d reservesBefore=%s', [
        AgentDied.AgentId,
        AgentDied.Cell.AsText,
        AgentDied.Age,
        AgentDied.ReservesBeforeDeath.AsText
      ]);
    sekResourceSampled:
      Result := Result + Format('cache=%d amount=%s regenDebt=%s', [
        ResourceSampled.CacheIndex,
        ResourceSampled.Amount.AsText,
        ResourceSampled.RegenDebt.AsText
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

function ProjectDecisionTrace(const E: TDecisionTraceEvent): TLogRow;
begin
*)

function _decisionTraceEvent.AsFields: TLogFields;
begin
  Result.Add('a', AgentId.AsText(2));
  Result.Add('cell', Cell.AsText);
  Result.Add('e',  Summary.EnergyLevel.AsText);
  Result.Add('act', ResolvedAction.AsText);

  case ResolvedAction of
    acMove:
      Result.Add('tg', ResolvedTarget.AsText);

    acForage:
      begin
        Result.Add('tg', ResolvedTarget.AsText);
        Result.Add('con', ForageConsumed.AsText);
        Result.Add('gain', ForageGain.AsText);
        Result.Add('eff', ForageEfficiency.AsText);
      end;
  end;

//  Result.Summary := Format(
//    'a:%s %s %s',
//    [
//      E.AgentId.AsText(2),
//      E.Cell.AsText,
//      E.ResolvedAction.AsText
//    ]);

//  Result.Summary := Result.GetFieldText;

end;



end.
