unit u_LogExport;

// Exports a curated list of DecisionTrace events from an IEventLog to a
// structured text file suitable for AI review.
//
// Usage:
//   ExportDecisionTraces(EventLog, EventMap.ToArray, GridWidth, 'results.txt');

interface

uses System.Generics.Collections,
  u_EventSinkIntf;

procedure ExportDecisionTraces(
  const aLog: IEventLog;
  const aIndexes: TArray<Integer>;
  aGridWidth: Integer;
  const aFilePath: string);

implementation

uses System.SysUtils, System.Classes,
  u_AgentTypes, u_SimDiagnosticsIntf, u_LogFormatting;

procedure ExportDecisionTraces(
  const aLog: IEventLog;
  const aIndexes: TArray<Integer>;
  aGridWidth: Integer;
  const aFilePath: string);
var
  lines: TStringList;
begin
  lines := TStringList.Create;
  try
    for var idx in aIndexes do
    begin
      var event := aLog.Events[idx];
      var trace := event.DecisionTrace;
      var header := event.Header;

      // root line: tick context + resolved action + location + energy
      var displayCell := trace.CellIndex;
      if (trace.ResolvedAction = acMove) and (trace.ResolvedTarget.TType = ttCell) then
        displayCell := trace.ResolvedTarget.Cell;

      lines.Add(Format('[Day %d | Tick %d]', [header.DayNumber, header.DayTick]));
      lines.Add(Format('  %s %s  %s',
        [trace.ResolvedAction.AsLabel,
         CellIndexToStr(displayCell, aGridWidth),
         trace.Summary.EnergyLevel.AsLabel]));

      // evaluation scores
      lines.Add('  ' + EvaluationsAsScoreLine(trace.Evaluations, trace.ResolvedAction));

      // conflict line only when the brain's request was overridden
      if trace.RequestedAction <> trace.ResolvedAction then
        lines.Add(Format('  Wanted: %s  →  Resolved: %s',
          [trace.RequestedAction.AsLabel, trace.ResolvedAction.AsLabel]));

      lines.Add('');  // blank line between entries
    end;

    lines.SaveToFile(aFilePath, TEncoding.UTF8);
  finally
    lines.Free;
  end;
end;

end.
