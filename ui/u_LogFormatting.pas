unit u_LogFormatting;

// Display-oriented formatting helpers for agent log data.
// Shared by u_LogTreeViews (canvas rendering) and u_LogExport (text export).

interface

uses u_AgentTypes, u_AgentGenome;

type
  TAgentActionHelper = record helper for TAgentAction
    function AsLabel: string;
  end;

  TEnergyLevelHelper = record helper for TEnergyLevel
    function AsLabel: string;
  end;

  TActionEvalResultHelper = record helper for TActionEvalResult
    function AsPercent: string;
  end;

function EvaluationsAsScoreLine(const aEvals: TActionEvaluations;
  aWinner: TAgentAction): string;

function CellIndexToStr(aCellIndex, aGridWidth: Integer): string;

implementation

uses System.SysUtils;

{ TAgentActionHelper }

function TAgentActionHelper.AsLabel: string;
begin
  case Self of
    acMove:      Result := 'Move';
    acForage:    Result := 'Forage';
    acShelter:   Result := 'Shelter';
    acReproduce: Result := 'Reproduce';
    acIdle:      Result := 'Idle';
  else
    Result := '?';
  end;
end;

{ TEnergyLevelHelper }

function TEnergyLevelHelper.AsLabel: string;
const
  LABELS: array[TEnergyLevel] of string = ('Empty', 'Low', 'Med', 'High', 'Full');
begin
  Result := LABELS[Self];
end;

{ TActionEvalResultHelper }

function TActionEvalResultHelper.AsPercent: string;
begin
  Result := IntToStr(Round(Self.Score * 100)) + '%';
end;

{ EvaluationsAsScoreLine }

function EvaluationsAsScoreLine(const aEvals: TActionEvaluations;
  aWinner: TAgentAction): string;
const
  LABELS: array[TAgentAction] of string = ('M', 'F', 'S', 'R', 'I');
begin
  Result := '';
  for var action := Low(TAgentAction) to High(TAgentAction) do
  begin
    if Result <> '' then
      Result := Result + '  ';
    Result := Result + LABELS[action] + ':' + aEvals[action].AsPercent;
  end;
end;

{ CellIndexToStr }

function CellIndexToStr(aCellIndex, aGridWidth: Integer): string;
begin
  Result := Format('(%d, %d)', [aCellIndex mod aGridWidth, aCellIndex div aGridWidth]);
end;

end.
