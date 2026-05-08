unit u_SimSessions;

interface

uses System.Classes, System.Types, System.Generics.Collections,
 u_Simulators, u_SimWatches, u_SimPhases,
 u_SimDiagnostics, u_SimEventTypes,
 u_SimControllers,
 u_SessionParameters;

type
  TSimSession = class
  private type
    TRecordingMarker = record
      Active: Boolean;
      EventNumber: Integer;
    end;
  private
    fCommonParams: TCommonSessionParameters;
    fDiagnostics: TSimDiagnosticsHub;
    fScratchFileName: string;
    fMappedFileSubscriptionId: Integer;
    fMappedFileSink: ISimEventConsumer;
    fMappedFileLog: IEventLog;
    fSim: TSimulator;
    fController: TSimController;
    fManifest: TList<TRecordingMarker>;
    fRecording: Boolean;
    procedure SetRecording(const Value: Boolean);

  public
    constructor Create(const aCommonParams: TCommonSessionParameters);
    destructor Destroy; override;

    procedure AssertScratchLogReadable;
    function ScratchEventCount: Integer;
    property ScratchFileName: string read fScratchFileName;

    property CommonParams: TCommonSessionParameters read fCommonParams;
    procedure BeginSession;
    procedure EndSession;

    property Controller: TSimController read fController;
    property EventLog: IEventLog read fMappedFileLog;
    property Simulator: TSimulator read fSim;
    property Diagnostics: TSimDiagnosticsHub read fDiagnostics;

    property Recording: Boolean read fRecording write SetRecording;
  end;

implementation

uses System.SysUtils, System.IOUtils,
  u_MappedFileSink;

const
  SCRATCH_FILE_NAME = 'scratch.simlog';

var
  NextSimSessionId: Integer = 0;


{ TSimSession }

constructor TSimSession.Create(const aCommonParams: TCommonSessionParameters);
begin
  inherited Create;
  fCommonParams := aCommonParams;
  fManifest := TList<TRecordingMarker>.Create;

  Inc(NextSimSessionId);

  fDiagnostics := TSimDiagnosticsHub.Create(NextSimSessionId);
  fMappedFileSubscriptionId := 0;

  fSim := TSimulator.Create(fDiagnostics as ISimDiagnosticsSink);
  fController := TSimController.Create(fSim.Clock);

  // set up the session recording file
  fScratchFileName := fCommonParams.ScratchFolder.Trim;
  Assert((fScratchFileName <> '') and TDirectory.Exists(fScratchFileName));
  fScratchFileName := TPath.Combine(fScratchFileName, SCRATCH_FILE_NAME);
  if TFile.Exists(fScratchFileName) then
    TFile.Delete(fScratchFileName);
  fMappedFileSink := TMappedFileSink.Create(fScratchFileName);
  fMappedFileSubscriptionId := fDiagnostics.Subscribe(fMappedFileSink);
  fMappedFileLog := TMappedFileLog.Create(fScratchFileName);
end;

destructor TSimSession.Destroy;
begin
  if Assigned(fDiagnostics) and (fMappedFileSubscriptionId <> 0) then
  begin
    fDiagnostics.Unsubscribe(fMappedFileSubscriptionId);
    fMappedFileSubscriptionId := 0;
  end;

  fMappedFileLog := nil;
  fMappedFileSink := nil;

  fController.Free;
  fController := nil;
  if Assigned(fSim) and Assigned(fSim.Runtime) then
    fSim.Runtime.OnPhase := nil;
  fSim.Free;
  fDiagnostics := nil;
  fManifest.Free;
  inherited;
end;

procedure TSimSession.BeginSession;
begin
  fManifest.Clear;
  if (fCommonParams.SessionLogFile <> '') and TFile.Exists(fCommonParams.SessionLogFile) then
    TFile.Delete(fCommonParams.SessionLogFile);
end;

procedure TSimSession.EndSession;
begin
  // close the session's log file


end;

procedure TSimSession.AssertScratchLogReadable;
begin
  Assert(Assigned(fMappedFileLog));

  var count := fMappedFileLog.Count;
  if count = 0 then
    Exit;

  var lastEvent := fMappedFileLog.Events[count - 1];
  Assert(lastEvent.Header.Sequence = count);

  var mappedLog := fMappedFileLog as TMappedFileLog;
  var header := mappedLog.Header;
  Assert(header.Magic = $534C4F47);
  Assert(header.EventCount = count);
end;

function TSimSession.ScratchEventCount: Integer;
begin
  Assert(Assigned(fMappedFileLog));
  Result := fMappedFileLog.Count;
end;

procedure TSimSession.SetRecording(const Value: Boolean);
begin
  if Value <> fRecording then
  begin
    fRecording := Value;
    var nextEvent := ScratchEventCount();

    // if there's already an entry and we haven't moved, don't add a dupe
    var lastIndex := fManifest.Count - 1;
    if (lastIndex >= 0) and (fManifest[lastIndex].EventNumber = nextEvent) then
    begin
      var event := fManifest[lastIndex];
      event.Active := Value;
      fManifest[lastIndex] := event;
    end
    else
    begin
      var event: TRecordingMarker;
      event.Active := Value;
      event.EventNumber := nextEvent;
      fManifest.Add(event);
    end;
  end;
end;

end.
