unit u_DiagnosticsHelpers;

interface

uses System.Types, System.SysUtils, System.TypInfo,
  u_SimEventTypes, u_AgentTypes, u_AgentBrain,
  u_AgentGenome, u_LogTypes, u_SimPopulations, u_EnvironmentTypes,
  u_AgentState, u_SimTypes;

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
    function AsAction: TLogFields;
    function AsEvaluations: TLogFields;
    function AsHeader: TLogFields;
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
    function AsHeaderFields: TLogFields;
  end;

  // TPopulationSummary
  _populationSummary = record helper for TPopulationSummary
    function AsSummaryFields: TLogFields;
    function AsMaxFields: TLogFields;
  end;

  // TMetabolicState
  _metabolicState = record helper for TMetabolicState
    function AsFields: TLogFields;
    function AsMoleculeFactors: TLogFields;
  end;

  _molecule = record helper for TMolecule
    function AsText: string;
  end;

  _single = record helper for Single
    function AsText: string;
  end;

  _cellIndex = record helper for TCellIndex
    function AsText: string;
  end;

  _lifespan = record helper for TLifespan
    function AsFields: TLogFields;
  end;

  _maxReserves = record helper for TReserveState
    function AsFields: TLogFields;
  end;

  // TAgentAction = abbrev
  _agentAction = record helper for TAgentAction
    function AsText: string;
  end;

  _agentId = record helper for TAgentId
    function AsText: string;
  end;

  _agentState = record helper for TAgentState
    function AsMoleculeWeights: TLogFields;
    function AsWatchHeader: TLogFields;
    function AsWatchAction: TLogFields;
  end;

  _simDate = record helper for TSimDate
    function AsFields: TLogFields;
  end;

  _smellReport = record helper for TSmellReport
    function AsFields: TLogFields;
  end;

  _smellDetails = record helper for TSmellDetails
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


  _energyLevel = record helper for TEnergyLevel
    function AsText: string;
  end;

//  _targetRef = record helper for TTargetRef
//    function AsText: string;
//  end;

  _cacheRef =  record helper for TCacheRef
    function AsText: string;
  end;

  _integer = record helper for Integer
    function AsText: string; overload;
    function AsText(Padding: Integer): string; overload;
  end;

  _boolean = record helper for Boolean
    function AsText: string;
  end;

  _target = record helper for TTarget
    function AsText: string;
  end;


  _ActionScore = record helper for TActionScore
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
  Result := Integer(Self).AsText(3);
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
  Result := X.AsText(3) + ',' + Y.AsText(3);
end;

{ _energyLevel }
function _energyLevel.AsText: string;
const
  energyLevelStrs: array[TEnergyLevel] of string = ('l', 'm', 'h', 'f');
begin
  Result := energyLevelStrs[Self];
end;

{ _actionScore }
function _ActionScore.AsFields: TLogFields;
begin
  Result.Add('score', Score.AsText);
end;



{ _brainTraceSummary }
function _brainTraceSummary.AsFields: TLogFields;
begin
  Result.Clear;
  Result.Add('rsrv', Self.Reserves.AsText);
  Result.Add('rsrvDel', Self.ReserveDelta.AsText);
  Result.Add('gest', Self.ActionProgress.AsText);
  Result.Add('hadSm', Self.HadSmellTarget.AsText);
  Result.Add('smSig', Self.StrongestSmellSignal.AsText);
  Result.Add('smCnt', Self.SmellCandidateCount.AsText);
  Result.Add('topSmDst', Self.TopSmellDistance.AsText);
  Result.Add('topSmSig', Self.TopSmellSignal.AsText);
  Result.Add('sol', Self.SolarFlux.AsText);
  Result.Add('solDel', Self.SolarFluxDelta.AsText);

end;

{ _decisionTraceEvent }

function _decisionTraceEvent.AsEvaluations: TLogFields;
begin
  Result.Clear;
  for var action := Low(Self.Scores) to High(Self.Scores) do
  begin
    Result.Add(action.AsText, Self.Scores[action].Score.AsText);
  end;
end;

function _decisionTraceEvent.AsAction: TLogFields;
begin
  Result.Clear;
  Result.Add('loc', Cell.AsText);
  Result.Add('ac', ResolvedAction.AsText);

  case ResolvedAction of
    acMove:
      begin
        Result.Add('to', ResolvedTarget.AsText);
      end;

    acShelter:
      begin

      end;

    acForage:
      begin
        Result.Add('t', ResolvedTarget.AsText);
        Result.Add('con', ForageOutcome.Consumed.AsText);
        Result.Add('gain', ForageOutcome.Gain.AsText);
        var eff: Single := ForageOutcome.Gain / ForageOutcome.Consumed;
        Result.Add('eff', eff.AsText);
      end;
  end;
end;

function _decisionTraceEvent.AsHeader: TLogFields;
begin
  Result.Clear;
  Result.Add('a', Self.AgentId.AsText);
  Result.Add('rsv', Self.Summary.Reserves.AsText);
  Result.Add('rsvd', Self.Summary.ReserveDelta.AsText);
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
  Result.Add('AP', ActionProgress.AsText);
end;


{ _simEvent }
function _simEvent.AsHeaderFields: TLogFields;
begin
  Result.Clear;

  if Header.Kind = sekDecisionTrace then
  begin
//    Result := DecisionTrace.AsHeaderFields;
  end;

end;

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
        Result.AddFields(DecisionTrace.AsAction);
      end;
    sekAgentBorn: ;
    sekAgentMoved:
      begin
        Result.AddFields(AgentMoved.AsFields);
      end;
    sekDeltaConsumed: ;
    sekAgentDied: ;
  end;

end;

{ _populationSummary }

//function _populationSummary.AsFields: TLogFields;
//begin
//  Result.Clear;
//  Result.Add('live',         Self.Living.AsText);
//  Result.Add('dead',         Self.TotalDeaths.AsText);
//  Result.Add('total',        Self.TotalSlots.AsText);
//  Result.Add('maxAge',       Self.MaxAge.AsText);
//  Result.Add('maxReserves',  Self.MaxReserves.AsText);
//  Result.Add('meanReserves', Self.MeanReserves.AsText);
//end;

{ _metabolicState }
function _metabolicState.AsFields: TLogFields;
begin
  Result.Clear;
  Result.Add('age', Age.AsText);
  Result.Add('rsrv', Self.Reserves.AsText);
  Result.Add('rsvD', Self.ReserveDelta.AsText);
  Result.Add('gene', Self.GeneSequence.AsText);
  Result.Add('mw', Self.AsMoleculeFactors.AsFieldText);
end;

function _metabolicState.AsMoleculeFactors: TLogFields;
begin
  Result.Clear;
  for var molecule := Low(TMolecule) to High(TMolecule) do
    Result.Add(molecule.AsText, Self.ForageMoleculeWeights[molecule].AsText);
end;

{ _molecule }

function _molecule.AsText: string;
const
  short_codes: array[TMolecule] of string = ('A', 'B', 'G', 'D');
begin
  Result := short_codes[Self];
end;

{ _populationSummary }

function _populationSummary.AsSummaryFields: TLogFields;
begin
  Result.Clear;
  Result.Add('Living', Living.AsText);
  Result.Add('Births', NewBirths.AsText);
  Result.Add('Deaths', NewDeaths.AsText);
  Result.Add('Avg Rsrv', Self.MeanReserves.AsText);
end;

function _populationSummary.AsMaxFields: TLogFields;
begin
  Result.Clear;
  Result.Add('Longest', Self.LongestLife.AsFields.AsFieldText);
  Result.Add('MaxRsrv', Self.MaxReserves.AsFields.AsFieldText);
end;


{ _lifespan }

function _lifespan.AsFields: TLogFields;
begin
  Result.Clear;
  Result.Add('', Format(
    '%s(%s)', [AgentId.AsText, Age.AsText]));
end;

//  _maxReserves = record helper for TReserveState
function _maxReserves.AsFields: TLogFields;
begin
  Result.Clear;
  Result.Add('', Format(
    '%s(%s)', [AgentId.AsText, Reserves.AsText]));
end;


{  _agentState }
function _agentState.AsMoleculeWeights: TLogFields;
begin
  Result.Clear;
  for var molecule := Low(TMolecule) to High(TMolecule) do
    Result.Add(molecule.AsText, Self.Genome.ForageMoleculeWeights[molecule].AsText);
end;

function _agentState.AsWatchAction: TLogFields;
begin
  Result.Clear;

  var s := Self.Action.AsText;
  if Self.Action in [acMove, acForage] then
    s := s + '(' + Self.ActionTarget.AsText + ')';

  Result.Add('', s);
end;

function _agentState.AsWatchHeader: TLogFields;
begin
  Result.Clear;
  Result.Add('r', Self.Reserves.AsText);
  Result.Add('d', Self.ReserveDelta.AsText);
  Result.Add('l', Self.Location.AsText);
  Result.Add('', Self.AsWatchAction.AsFieldText);
  Result.Add('w', Self.AsMoleculeWeights.AsFieldText);

end;

{ _simDate }
function _simDate.AsFields: TLogFields;
begin
  Result.Clear;
  Result.Add('', Self.DayNumber.AsText(3) + ':' + Integer(Ord(Self.DayTick)).AsText(3));
end;


{ _smellReport }

function _smellReport.AsFields: TLogFields;
const
  molecule_label: array[TMolecule] of string = ('mA', 'mB', 'mG', 'mD');
begin
  Result.Clear;
  for var i := 0 to Length(Self.Details) - 1 do
  begin
    var detail := Self.Details[i];

    var sub: TLogFields;
    sub.Clear;
    sub.Add('', detail.Cache.AsText);
    sub.Add('dis', detail.Directions.Distance.ToString);

    for var m := Low(TMolecule) to High(TMolecule) do
    begin
      if m in detail.MoleculesPresent then
        sub.Add(molecule_label[m], detail.MoleculeStrength[m].AsText);
    end;

    Result.Add('[' + i.AsText(2) + ']', sub.AsFieldText);
  end;

(*
  TSmellDetails = record
    Cache: TCacheRef;
    CellIndex: TCellIndex;
    Directions: TDirections;
    MoleculesPresent: TMolecules;
    MoleculeStrength: array[TMolecule] of Single;

*)
end;

{ _smellDetails }
function _smellDetails.AsFields: TLogFields;
const
  molecule_label: array[TMolecule] of string = ('mA', 'mB', 'mG', 'mD');
begin
  Result.Clear;
  Result.Add('cache', Self.Cache.AsText);
  Result.Add('loc', CellIndex.AsText);
  Result.Add('dis', Self.Directions.Distance.ToString);
  for var m := Low(TMolecule) to High(TMolecule) do
  begin
    if m in MoleculesPresent then
      Result.Add(molecule_label[m], MoleculeStrength[m].AsText);
  end;
end;

end.
