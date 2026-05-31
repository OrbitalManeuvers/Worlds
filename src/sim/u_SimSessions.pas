unit u_SimSessions;

interface

uses System.Classes, System.Types, System.Generics.Collections,
 u_Simulators, u_SimWatches, u_SimTypes,
 u_SimDiagnostics, u_SimEventTypes,
 u_SimControllers, u_LocalEventLogs,
 u_SessionParameters, u_SessionTOC;

{.define mmf_scratch}

type
  TSimSession = class
  private type
    TRecordingMarker = record
      Active: Boolean;
      EventNumber: Integer;
    end;
  public type
    TSaveProgressEvent = procedure (Sender: TObject; Position: Integer) of object;
  private
    fCommonParams: TCommonSessionParameters;
    fDiagnostics: TSimDiagnosticsHub;
    fScratchFileName: string;
    fDiagnosticSubscriptionId: Integer;

{$ifdef mmf_scratch}
    fMappedFileSink: ISimEventConsumer;
    fMappedFileLog: IEventLog;
{$else}
    fEventConsumer: ISimEventConsumer;
    fEventLog: IEventLog;
{$endif}

    fSim: TSimulator;
    fController: TSimController;
    fRecordingBoundaries: TList<TRecordingMarker>;
    fRecording: Boolean;
    fScratchLogEnabled: Boolean;
    procedure SetRecording(const Value: Boolean);
    procedure SetScratchLogEnabled(const Value: Boolean);

  public
    constructor Create(const aCommonParams: TCommonSessionParameters);
    destructor Destroy; override;

    procedure AssertScratchLogReadable;
    function ScratchEventCount: Integer;
    property ScratchFileName: string read fScratchFileName;

    property CommonParams: TCommonSessionParameters read fCommonParams;
    procedure BeginSession;
    procedure EndSession;

    function SaveEventLog(aCallback: TSaveProgressEvent): Integer;

    property Controller: TSimController read fController;
{$ifdef mmf_scratch}
    property EventLog: IEventLog read fMappedFileLog;
{$else}
    property EventLog: IEventLog read fEventLog;
{$endif}
    property Simulator: TSimulator read fSim;
    property Diagnostics: TSimDiagnosticsHub read fDiagnostics;

    property Recording: Boolean read fRecording write SetRecording;
    property ScratchLogEnabled: Boolean read fScratchLogEnabled write SetScratchLogEnabled;
  end;

implementation

uses System.SysUtils, System.IOUtils,
  u_MappedFileSink;

const
  SCRATCH_FILE_NAME = 'worlds_scratch.simlog';



{ TSimSession }

constructor TSimSession.Create(const aCommonParams: TCommonSessionParameters);
begin
  inherited Create;
  fCommonParams := aCommonParams;
  fRecordingBoundaries := TList<TRecordingMarker>.Create;

  fDiagnostics := TSimDiagnosticsHub.Create;
  fDiagnosticSubscriptionId := 0;

  fSim := TSimulator.Create(fDiagnostics as ISimDiagnosticsSink);
  fController := TSimController.Create(fSim.Clock);

  // set up the session recording file
  fScratchFileName := fCommonParams.ScratchFolder.Trim;
  Assert((fScratchFileName <> '') and TDirectory.Exists(fScratchFileName));
  fScratchFileName := TPath.Combine(fScratchFileName, SCRATCH_FILE_NAME);
  if TFile.Exists(fScratchFileName) then
    TFile.Delete(fScratchFileName);

{$ifdef mmf_scratch}
  fMappedFileSink := TMappedFileSink.Create(fScratchFileName);
  fDiagnosticSubscriptionId := fDiagnostics.Subscribe(fMappedFileSink);
  fScratchLogEnabled := True;
  fMappedFileLog := TMappedFileLog.Create(fScratchFileName);
{$else}
  fEventConsumer := TLocalEventLog.Create as ISimEventConsumer;
  fEventLog := fEventConsumer as IEventLog;
  fDiagnosticSubscriptionId := fDiagnostics.Subscribe(fEventConsumer);
{$endif}

end;

destructor TSimSession.Destroy;
begin
  if Assigned(fDiagnostics) and (fDiagnosticSubscriptionId <> 0) then
  begin
    fDiagnostics.Unsubscribe(fDiagnosticSubscriptionId);
    fDiagnosticSubscriptionId := 0;
  end;

{$ifdef mmf_scratch}
  fMappedFileLog := nil;
  fMappedFileSink := nil;
{$else}
  fEventConsumer := nil;
  fEventLog := nil;
{$endif}

  fController.Free;
  fController := nil;
  if Assigned(fSim) and Assigned(fSim.Runtime) then
    fSim.Runtime.OnPhase := nil;
  fSim.Free;
  fDiagnostics := nil;
  fRecordingBoundaries.Free;
  inherited;
end;

procedure TSimSession.BeginSession;
begin
  fRecordingBoundaries.Clear;
  if (fCommonParams.SessionLogFile <> '') and TFile.Exists(fCommonParams.SessionLogFile) then
    TFile.Delete(fCommonParams.SessionLogFile);
end;

procedure TSimSession.EndSession;
begin
  // close the session's log file


end;

procedure TSimSession.SetScratchLogEnabled(const Value: Boolean);
begin
  if Value = fScratchLogEnabled then
    Exit;
  fScratchLogEnabled := Value;

  if Value then
  begin
    // Re-subscribe the sink
{$ifdef mmf_scratch}
    if fDiagnosticSubscriptionId = 0 then
      fDiagnosticSubscriptionId := fDiagnostics.Subscribe(fMappedFileSink);
{$else}
    if fDiagnosticSubscriptionId = 0 then
      fDiagnosticSubscriptionId := fDiagnostics.Subscribe(fEventConsumer);
{$endif}
  end
  else
  begin
    // Unsubscribe — events no longer reach the file
    if fDiagnosticSubscriptionId <> 0 then
    begin
      fDiagnostics.Unsubscribe(fDiagnosticSubscriptionId);
      fDiagnosticSubscriptionId := 0;
    end;
  end;
end;

procedure TSimSession.AssertScratchLogReadable;
begin
{$ifdef mmf_scratch}
  Assert(Assigned(fMappedFileLog));

  var count := fMappedFileLog.Count;
  if count = 0 then
    Exit;

  var lastEvent := fMappedFileLog.Events[count - 1];
  Assert(lastEvent.Header.Sequence = count);

  var mappedLog := fMappedFileLog as TMappedFileLog;
  var header := mappedLog.Header;
  Assert(header.Signature = EVENT_LOG_FILE_SIGNATURE);
  Assert(header.EventCount = count);
{$endif}
end;

function TSimSession.SaveEventLog(aCallback: TSaveProgressEvent): Integer;
var
  eventsWritten: Integer;
begin
  Assert(fCommonParams.SessionLogFile <> '');

  var toc := TSessionTOC.Create;
  var logFile := TFileStream.Create(fCommonParams.SessionLogFile, fmCreate);
  try
    // save space for the header
    var header := StandardEventLogHeader();
    logFile.Write(header, SizeOf(header));

    var markerCursor := 0;
    var writing := False;
    eventsWritten := 0;
    var segmentIndex := -1;
    var segmentOpen := False;
    var currentSegment := Default(TSessionTOCSegment);

    for var index := 0 to EventLog.Count - 1 do
    begin
      // let caller know we're working on this one
      if Assigned(aCallback) then
        aCallback(Self, index);

      // if the index is the event number listed in the next manifest record, then
      // update writing flag and move the manifest cursor
      if (fRecordingBoundaries.Count > markerCursor) and (index = fRecordingBoundaries[markerCursor].EventNumber) then
      begin
        writing := fRecordingBoundaries[markerCursor].Active;

        if writing and (not segmentOpen) then
        begin
          Inc(segmentIndex);
          currentSegment := Default(TSessionTOCSegment);
          currentSegment.SegmentIndex := segmentIndex;
          currentSegment.SavedStartEventIndex := eventsWritten;
          currentSegment.SavedEventCount := 0;
          segmentOpen := True;
        end
        else if (not writing) and segmentOpen then
        begin
          if currentSegment.SavedEventCount > 0 then
            toc.AddSegment(currentSegment);
          segmentOpen := False;
        end;

        Inc(markerCursor);
      end;

      if writing then
      begin
        var event := EventLog.Events[index];

        if currentSegment.SavedEventCount = 0 then
        begin
          currentSegment.FirstSequence := event.Header.Sequence;
          currentSegment.FirstDayNumber := event.Header.DayNumber;
          currentSegment.FirstDayTick := event.Header.DayTick;
        end;

        currentSegment.LastSequence := event.Header.Sequence;
        currentSegment.LastDayNumber := event.Header.DayNumber;
        currentSegment.LastDayTick := event.Header.DayTick;

        logFile.Write(event, SizeOf(event));
        Inc(eventsWritten);
        Inc(currentSegment.SavedEventCount);
      end;
    end;

    if segmentOpen and (currentSegment.SavedEventCount > 0) then
      toc.AddSegment(currentSegment);

    // patch the header record
    header.EventCount := eventsWritten;
    logfile.Seek(0, soBeginning);
    logFile.Write(header, SizeOf(header));

    var tocFileName := fCommonParams.SessionTOCFile;
    if tocFileName.Trim.IsEmpty then
      tocFileName := ChangeFileExt(fCommonParams.SessionLogFile, '.toc.json');
    toc.SaveToFile(tocFileName);
  finally
    toc.Free;
    logFile.Free;
  end;

  Result := eventsWritten;
end;

function TSimSession.ScratchEventCount: Integer;
begin
{$ifdef mmf_scratch}
  Assert(Assigned(fMappedFileLog));
  Result := fMappedFileLog.Count;
{$else}
  Result := fEventLog.Count;
{$endif}
end;

procedure TSimSession.SetRecording(const Value: Boolean);
begin
  // if there's no change do nothing
  if Value <> fRecording then
    Exit;

  var nextEvent := ScratchEventCount();
  var marker: TRecordingMarker;
  marker.Active := Value;
  marker.EventNumber := nextEvent;
  fRecordingBoundaries.Add(marker);
  fRecording := Value;
end;

end.
