unit u_DiagnosticsHelpers;

interface

uses System.Types, System.SysUtils, System.TypInfo,
  u_SimEventTypes, u_AgentTypes, u_AgentBrain,
  u_AgentGenome, u_LogTypes, u_SimPopulations;

(*

Intentions:
  - base types should have an .AsText helper
  - records should have .AsFields helper
*)

type
  // TBrainTraceSummary
  _brainTraceSummary = record helper for TBrainTraceSummary
    function AsFields: TLogFields;
  end;

  // TDecisionTraceEvent field helper
  _decisionTraceEvent = record helper for TDecisionTraceEvent
    function AsFields: TLogFields;
    function AsEvaluationFields: TLogFields;
  end;

  // TAgentMovedEvent field helper
  _agentMovedEvent = record helper for TAgentMovedEvent
    function AsFields: TLogFields;
  end;

  // TActionResolvedEvent helper
  _actionResolvedEvent = record helper for TActionResolvedEvent
    function AsFields: TLogFields;
  end;

  // TSimEvent
  _simEvent = record helper for TSimEvent
    function AsFields: TLogFields;
  end;

  // TPopulationSummary
  _populationSummary = record helper for TPopulationSummary
    function AsFields: TLogFields;
  end;



implementation

// DEV HACK. This needs to be formalized once the session manifest system
// can handle alternate logs, etc
const
  GRID_WIDTH = 256;

const
  CRLF = #13#10;

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

  _energyLevel = record helper for TEnergyLevel
    function AsText: string;
  end;

//  _targetRef = record helper for TTargetRef
//    function AsText: string;
//  end;

  _cacheRef =  record helper for TCacheRef
    function AsText: string;
  end;

  _single = record helper for Single
    function AsText: string;
  end;

  _integer = record helper for Integer
    function AsText: string; overload;
    function AsText(Padding: Integer): string; overload;
  end;

  _boolean = record helper for Boolean
    function AsText: string;
  end;

  _agentId = record helper for TAgentId
    function AsText: string;
  end;

  _cellIndex = record helper for TCellIndex
    function AsText: string;
  end;

  _target = record helper for TTarget
    function AsText: string;
  end;


  _ActionEvalResult = record helper for TActionEvalResult
    function AsFields: TLogFields;
  end;


// -----------

function CellToPoint(aCell: Integer): TPoint;
begin
  Result := Point(aCell mod GRID_WIDTH, aCell div GRID_WIDTH);
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

{ _agentId }

function _agentId.AsText: string;
begin
  Result := Integer(Self).AsText(2);
end;

{ _cellIndex }
function _cellIndex.AsText: string;
begin
  var pt := CellToPoint(Self);
  Result := pt.AsText;
end;




{ _boolean }
function _boolean.AsText: string;
begin
  if Self then Result := 'T'
  else Result := 'F';
end;


{ _cacheRef }
function _cacheRef.AsText: string;
begin
  case Self.Kind of
    ckResource:
      Result := 'r' + Self.Index.AsText;
    ckDelta:
      Result := 'd' + Self.Index.AsText;
  end;
end;

{ _target }
function _target.AsText: string;
begin
  case Self.TType of
    ttNone: ;
    ttCell: Result := Self.Cell.AsText;
    ttCache: Result := Self.Cache.AsText;
    ttWander: ;
  end;
end;


{ _agentAction }

function _agentAction.AsText: string;
const
  actionStrs: array[TAgentAction] of string = ('mov', 'for', 'shl', 'rep', 'idl');
begin
  Result := actionStrs[Self];
end;

{ _point }
function _point.AsText: string;
begin
  Result := X.AsText + ',' + Y.AsText;
end;

{ _energyLevel }
function _energyLevel.AsText: string;
const
  energyLevelStrs: array[TEnergyLevel] of string = ('e', 'l', 'm', 'h', 'f');
begin
  Result := energyLevelStrs[Self];
end;


function _ActionEvalResult.AsFields: TLogFields;
begin
  Result.Add('score', Score.AsText);
  Result.Add('tg', Self.Target.AsText);
end;

//    Score: Single;
//    Target: TTarget;
//  end;



{ _brainTraceSummary }
function _brainTraceSummary.AsFields: TLogFields;
begin
  Result.Clear;
  Result.Add('rsrv', Self.Reserves.AsText);
  Result.Add('rsrvDel', Self.ReserveDelta.AsText);
  Result.Add('gest', Self.GestationProgress.AsText);
  Result.Add('hadSm', Self.HadSmellTarget.AsText);
  Result.Add('smSig', Self.StrongestSmellSignal.AsText);
  Result.Add('smCnt', Self.SmellCandidateCount.AsText);
  Result.Add('topSmDst', Self.TopSmellDistance.AsText);
  Result.Add('topSmSig', Self.TopSmellSignal.AsText);
  Result.Add('sol', Self.SolarFlux.AsText);
  Result.Add('solDel', Self.SolarFluxDelta.AsText);

end;

function _decisionTraceEvent.AsEvaluationFields: TLogFields;
begin
  Result.Clear;
  for var action := Low(Self.Evaluations) to High(Self.Evaluations) do
  begin
    var fldName := action.AsText;

    // does the action have a target?
    if Self.Evaluations[action].Target.TType in [ttCell, ttCache] then
      fldName := fldName + '(' + Self.Evaluations[action].Target.AsText + ')';
    Result.Add(fldName, Self.Evaluations[action].Score.AsText);

  end;

end;

function _decisionTraceEvent.AsFields: TLogFields;
begin
  Result.Clear;
  Result.Add('A', AgentId.AsText);
  Result.Add('L', Cell.AsText);
  Result.Add('E',  Summary.Reserves.AsText);
  Result.Add('AC', ResolvedAction.AsText);

  case ResolvedAction of
    acMove:
      begin
        Result.Add('t', ResolvedTarget.AsText);
      end;

    acForage:
      begin
        Result.Add('t', ResolvedTarget.AsText);
        Result.Add('con', ForageConsumed.AsText);
        Result.Add('gain', ForageGain.AsText);
        Result.Add('eff', ForageEfficiency.AsText);
      end;
  end;
end;

  // TAgentMovedEvent field helper
function _agentMovedEvent.AsFields: TLogFields;
begin
  Result.Add('A', AgentId.AsText);
  Result.Add('F', FromCell.AsText);
  Result.Add('T', ToCell.AsText);
  Result.Add('C', MoveCost.AsText);

end;


// TActionResolvedEvent helper
function _actionResolvedEvent.AsFields: TLogFields;
begin
  Result.Add('A', AgentId.AsText);
  Result.Add('RQ', RequestedAction.AsText + '(' + RequestedTarget.AsText + ')');
  Result.Add('RS', ResolvedAction.AsText + '(' + ResolvedTarget.AsText + ')');
  Result.Add('E', Reserves.AsText);
  Result.Add('GP', GestationProgress.AsText);

(*
    AgentId: TAgentId;
    RequestedAction: TAgentAction;
    RequestedTarget: TTarget;
    ResolvedAction: TAgentAction;
    ResolvedTarget: TTarget;
    Reserves: Single;
    GestationProgress: Integer;

*)
end;


{ _simEvent }
function _simEvent.AsFields: TLogFields;
begin
  Result.Clear;

  // first field is tick/clock info
  Result.Add('tick', Format('%.04d [%.02d:%.03d] ',
    [Header.Sequence, Header.DayNumber, Header.DayTick]));

  case Header.Kind of
    sekActionResolved:
      begin
        Result.AddFields(ActionResolved.AsFields);
      end;
    sekDecisionTrace:
      begin
        Result.AddFields(DecisionTrace.AsFields);
      end;
    sekAgentBorn: ;
    sekAgentMoved:
      begin
        Result.AddFields(AgentMoved.AsFields);
      end;
    sekDeltaConsumed: ;
    sekAgentDied: ;
    sekResourceSampled: ;
  end;

end;

{ _populationSummary }

function _populationSummary.AsFields: TLogFields;
begin
  Result.Clear;
  Result.Add('live',         Self.LiveCount.AsText);
  Result.Add('dead',         Self.DeadCount.AsText);
  Result.Add('total',        Self.TotalSlots.AsText);
  Result.Add('maxAge',       Self.MaxAge.AsText);
  Result.Add('maxReserves',  Self.MaxReserves.AsText);
  Result.Add('meanReserves', Self.MeanReserves.AsText);
end;

end.
