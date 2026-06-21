unit u_SimSessions;

interface

uses System.Classes, System.Types, System.Generics.Collections,
 u_Simulators, u_SimTypes, u_SimDiagnostics, u_SimEventTypes,
 u_SimControllers, u_SessionParameters, u_SessionTOC,
 u_ScratchRecorders, u_SessionEventTypes;

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
    fDiagnostics: ISimEventHub;
    fSessionEvents: ISessionEventHub;
    fScratchRecorder: IScratchRecorder;
    fSessionScratchRecorder: ISessionScratchRecorder;

    fSim: TSimulator;
    fController: TSimController;
    fRecordingBoundaries: TList<TRecordingMarker>;
    fRecording: Boolean;
    function GetEventLog: IEventLog;
    function GetScratchFileName: string;
    function GetScratchLogEnabled: Boolean;
    procedure SetRecording(const Value: Boolean);
    procedure SetScratchLogEnabled(const Value: Boolean);

  public
    constructor Create(const aCommonParams: TCommonSessionParameters;
      const aScratchRecorder: IScratchRecorder);
    destructor Destroy; override;

    procedure AssertScratchLogReadable;
    function ScratchEventCount: Integer;
    property ScratchFileName: string read GetScratchFileName;

    property CommonParams: TCommonSessionParameters read fCommonParams;
    procedure BeginSession;
    procedure EndSession;

    function SaveEventLog(aCallback: TSaveProgressEvent): Integer;

    property Controller: TSimController read fController;
    property EventLog: IEventLog read GetEventLog;
    property Simulator: TSimulator read fSim;
    property Diagnostics: ISimEventHub read fDiagnostics;

    property Recording: Boolean read fRecording write SetRecording;
    property ScratchLogEnabled: Boolean read GetScratchLogEnabled write SetScratchLogEnabled;
  end;

implementation

uses System.SysUtils, System.IOUtils, u_MappedFileSink,
  u_SessionEventHubs;



{ TSimSession }

constructor TSimSession.Create(const aCommonParams: TCommonSessionParameters;
  const aScratchRecorder: IScratchRecorder);
begin
  inherited Create;
  fCommonParams := aCommonParams;
  fRecordingBoundaries := TList<TRecordingMarker>.Create;
  fScratchRecorder := aScratchRecorder;
  Assert(Assigned(fScratchRecorder));

  var hub := TSimDiagnosticsHub.Create;
  fDiagnostics := hub;
  fSim := TSimulator.Create(fDiagnostics as ISimDiagnosticsSink);

  fController := TSimController.Create(fSim.Clock);

  fScratchRecorder.Bind(hub);

  var hub2 := TSessionEventHub.Create;
  fSessionEvents := hub2;
//  var recorder2: ISessionScratchRecorder;
//  recorder2.Bind(hub2);

end;

destructor TSimSession.Destroy;
begin
  fScratchRecorder := nil;

  fController.Free;
  fController := nil;
  if Assigned(fSim) and Assigned(fSim.Runtime) then
    fSim.Runtime.OnPhase := nil;
  fSim.Free;
  fDiagnostics := nil;
  fSessionEvents := nil;
  fRecordingBoundaries.Free;
  inherited;
end;

function TSimSession.GetEventLog: IEventLog;
begin
  Result := fScratchRecorder.Log;
end;

function TSimSession.GetScratchFileName: string;
begin
  Result := fScratchRecorder.ScratchFileName;
end;

function TSimSession.GetScratchLogEnabled: Boolean;
begin
  Result := fScratchRecorder.Enabled;
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
  fScratchRecorder.Enabled := Value;
end;

procedure TSimSession.AssertScratchLogReadable;
begin
  fScratchRecorder.AssertReadable;
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
  Result := fScratchRecorder.EventCount;
end;

procedure TSimSession.SetRecording(const Value: Boolean);
begin
  // if there's no change do nothing
  if Value = fRecording then
    Exit;

  var nextEvent := ScratchEventCount();
  var marker: TRecordingMarker;
  marker.Active := Value;
  marker.EventNumber := nextEvent;
  fRecordingBoundaries.Add(marker);
  fRecording := Value;
end;

end.
