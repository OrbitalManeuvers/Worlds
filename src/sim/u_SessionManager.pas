unit u_SessionManager;

// This class stores the requested session parameters to allow unwinding the stack and
// freeing up resources before launching the simulator frame.

interface

uses u_SessionParameters, u_Worlds, u_WorldsMessages, u_SessionManifest;

type
  TSessionStatus = (ssPending, ssRunning, ssCompleted, ssFailed);

  TSessionRecord = record
    Status: TSessionStatus;
    CommonParams: TCommonSessionParameters;
    SessionTOCFile: string;
    SessionType: TSessionType;
    StandardParams: TUpscalerParameters;  // includes World
    DebugParams: TDebugSessionParameters;
    SavedRecording: Boolean;
    SavedEventCount: Integer;
    SubmittedAtUtc: TDateTime;
    ClosedAtUtc: TDateTime;
    PublishedToManifest: Boolean;
    Notes: string;
  end;

  TSessionManager = class
  private
    fLogFolder: string;
    fScratchFolder: string;
    fManifestFileName: string;
    fManifest: TSessionManifest;
    fSession: TSessionRecord;
    fHasSession: Boolean;
    fLaunchRequest: TSimLaunchRequest;
    function BuildSessionLogFileName(const aSessionTitle: string): string;
    function BuildSessionTOCFileName(const aSessionLogFile: string): string;
    function BuildManifestFileName: string;
    procedure SetLogFolder(const Value: string);
    procedure SetScratchFolder(const Value: string);
    procedure StampSessionPaths(var aCommonParams: TCommonSessionParameters);
    procedure PublishSessionToManifest(const aRecord: TSessionRecord);
    procedure NotifySessionSubmitted;
    function GetConfigured: Boolean;

    function BuildLaunchRequest(const CommonParams: TCommonSessionParameters; const StandardParams: TUpscalerParameters): TSimLaunchRequest; overload;
    function BuildLaunchRequest(const CommonParams: TCommonSessionParameters; const DebugParams: TDebugSessionParameters): TSimLaunchRequest; overload;

  public
    constructor Create;
    destructor Destroy; override;
    property LogFolder: string read fLogFolder write SetLogFolder;
    property ScratchFolder: string read fScratchFolder write SetScratchFolder;

    // These notify the system via WM_SESSION_SUBMITTED
    procedure SubmitStandardSession(const CommonParams: TCommonSessionParameters;
      StandardParams: TUpscalerParameters);
    procedure SubmitDebugSession(const CommonParams: TCommonSessionParameters;
      DebugParams: TDebugSessionParameters);

    // main form calls these
    function GetSession: TSessionRecord;
    function GetLaunchRequest: TSimLaunchRequest;

    // update session status
    procedure UpdateSessionStatus(aStatus: TSessionStatus; aSavedRecording: Boolean;
      aSavedEventCount: Integer; const aNotes: string);

    property Configured: Boolean read GetConfigured;
  end;

var
  SessionManager: TSessionManager = nil;

implementation

uses WinApi.Windows, Vcl.Forms, System.SysUtils, System.IOUtils;

const
  SESSION_MANIFEST_FILE_NAME = 'session-manifest.json';

function SessionTypeToText(aType: TSessionType): string;
begin
  case aType of
    stStandard: Result := 'standard';
    stDebug: Result := 'debug';
  else
    Result := 'unknown';
  end;
end;

function SessionStatusToText(aStatus: TSessionStatus): string;
begin
  case aStatus of
    ssPending: Result := 'pending';
    ssRunning: Result := 'running';
    ssCompleted: Result := 'completed';
    ssFailed: Result := 'failed';
  else
    Result := 'unknown';
  end;
end;

function SanitizeFileToken(const aText: string): string;
begin
  Result := '';
  for var ch in aText do
  begin
    if CharInSet(ch, ['A'..'Z', 'a'..'z', '0'..'9', '-', '_']) then
      Result := Result + ch
    else if ch = ' ' then
      Result := Result + '-';
  end;

  if Result = '' then
    Result := 'session';
end;

{ TSessionManager }

constructor TSessionManager.Create;
begin
  inherited;
  fManifest := TSessionManifest.Create;
  fManifestFileName := '';
  fSession := Default(TSessionRecord);
  fHasSession := False;
end;

destructor TSessionManager.Destroy;
begin
  fManifest.Free;
  inherited;
end;

function TSessionManager.BuildManifestFileName: string;
begin
  Assert(not fLogFolder.IsEmpty);
  Result := TPath.Combine(fLogFolder, SESSION_MANIFEST_FILE_NAME);
end;

function TSessionManager.BuildSessionLogFileName(const aSessionTitle: string): string;
begin
  Assert(not fLogFolder.IsEmpty);

  var token := SanitizeFileToken(aSessionTitle.Trim);
  var stamp := FormatDateTime('yyyy-mm-dd-hhnnss', Now);
  var baseName := stamp + '-' + token;

  Result := TPath.Combine(fLogFolder, baseName + '.simlog');
  var suffix := 2;
  while TFile.Exists(Result) do
  begin
    Result := TPath.Combine(fLogFolder, baseName + '-' + suffix.ToString + '.simlog');
    Inc(suffix);
  end;
end;

function TSessionManager.BuildSessionTOCFileName(const aSessionLogFile: string): string;
begin
  Assert(not aSessionLogFile.Trim.IsEmpty);
  Result := ChangeFileExt(aSessionLogFile, '.toc.json');
end;

function TSessionManager.GetConfigured: Boolean;
begin
  Result := not fLogFolder.IsEmpty;
end;

function TSessionManager.GetLaunchRequest: TSimLaunchRequest;
begin
  Assert(fHasSession);
  Result := fLaunchRequest;
end;

function TSessionManager.GetSession: TSessionRecord;
begin
  Assert(fHasSession);
  Result := fSession;
end;

procedure TSessionManager.SetLogFolder(const Value: string);
begin
  fLogFolder := Value.Trim;
  fManifest.Clear;
  fManifestFileName := '';

  if fLogFolder.IsEmpty then
    Exit;

  Assert(TDirectory.Exists(fLogFolder));
  fManifestFileName := BuildManifestFileName;
  fManifest.LoadFromFile(fManifestFileName);
end;

procedure TSessionManager.SetScratchFolder(const Value: string);
begin
  fScratchFolder := Value.Trim;

  if fScratchFolder.IsEmpty then
    Exit;

  Assert(TDirectory.Exists(fScratchFolder));
end;

procedure TSessionManager.StampSessionPaths(var aCommonParams: TCommonSessionParameters);
begin
  aCommonParams.SessionLogFile := BuildSessionLogFileName(aCommonParams.SessionTitle);
  aCommonParams.SessionTOCFile := BuildSessionTOCFileName(aCommonParams.SessionLogFile);

  if aCommonParams.ScratchBackend = sbDefault then
  begin
    if aCommonParams.SessionType = stDebug then
      aCommonParams.ScratchBackend := sbLocalMemory
    else
      aCommonParams.ScratchBackend := sbMappedFile;
  end;

  if aCommonParams.ScratchFolder.Trim.IsEmpty then
  begin
    if not fScratchFolder.IsEmpty then
      aCommonParams.ScratchFolder := fScratchFolder
    else
      aCommonParams.ScratchFolder := fLogFolder;
  end;
end;

procedure TSessionManager.PublishSessionToManifest(const aRecord: TSessionRecord);
begin
  Assert(not fManifestFileName.IsEmpty);

  var entry := Default(TSessionManifestEntry);
  entry.SessionTitle := aRecord.CommonParams.SessionTitle;
  entry.SessionLogFile := aRecord.CommonParams.SessionLogFile;
  entry.SessionTOCFile := aRecord.SessionTOCFile;
  entry.SessionType := SessionTypeToText(aRecord.SessionType);
  entry.Status := SessionStatusToText(aRecord.Status);
  entry.SavedRecording := aRecord.SavedRecording;
  entry.SavedEventCount := aRecord.SavedEventCount;
  entry.SubmittedAtUtc := aRecord.SubmittedAtUtc;
  entry.ClosedAtUtc := aRecord.ClosedAtUtc;
  entry.Notes := aRecord.Notes;

  fManifest.Add(entry);
  fManifest.SaveToFile(fManifestFileName);
end;

procedure TSessionManager.NotifySessionSubmitted;
begin
  if fHasSession then
    PostMessage(Application.MainForm.Handle, WM_SESSION_SUBMITTED, 0, 0);
end;

procedure TSessionManager.UpdateSessionStatus(aStatus: TSessionStatus; aSavedRecording: Boolean;
  aSavedEventCount: Integer; const aNotes: string);
begin
  fSession.Status := aStatus;
  fSession.SavedRecording := aSavedRecording;
  fSession.Notes := aNotes;
  fSession.SavedEventCount := aSavedEventCount;

  if aStatus in [ssCompleted, ssFailed] then
    fSession.ClosedAtUtc := Now;

  if (aStatus = ssCompleted) and fSession.SavedRecording and (not fSession.PublishedToManifest) then
  begin
    PublishSessionToManifest(fSession);
    fSession.PublishedToManifest := True;
  end;
end;

function TSessionManager.BuildLaunchRequest(const CommonParams: TCommonSessionParameters; const StandardParams: TUpscalerParameters): TSimLaunchRequest;
begin
  fLaunchRequest := Default(TSimLaunchRequest);
  fLaunchRequest.SessionType := stStandard;
  fLaunchRequest.CommonParams := CommonParams;
  fLaunchRequest.StandardParams := StandardParams;
  Result := fLaunchRequest;
end;

function TSessionManager.BuildLaunchRequest(const CommonParams: TCommonSessionParameters; const DebugParams: TDebugSessionParameters): TSimLaunchRequest;
begin
  fLaunchRequest := Default(TSimLaunchRequest);
  fLaunchRequest.SessionType := stDebug;
  fLaunchRequest.CommonParams := CommonParams;
  fLaunchRequest.DebugParams := DebugParams;
  Result := fLaunchRequest;
end;

procedure TSessionManager.SubmitDebugSession(const CommonParams: TCommonSessionParameters;
  DebugParams: TDebugSessionParameters);
begin
  var rec := Default(TSessionRecord);
  rec.Status := ssPending;
  rec.SessionType := stDebug;
  rec.CommonParams := CommonParams;
  StampSessionPaths(rec.CommonParams);
  rec.SessionTOCFile := rec.CommonParams.SessionTOCFile;
  rec.DebugParams := DebugParams;
  rec.SubmittedAtUtc := Now;
  rec.ClosedAtUtc := 0;
  rec.SavedRecording := False;
  rec.SavedEventCount := 0;
  rec.PublishedToManifest := False;
  fSession := rec;
  fHasSession := True;

  BuildLaunchRequest(rec.CommonParams, DebugParams);

  NotifySessionSubmitted;
end;

procedure TSessionManager.SubmitStandardSession(const CommonParams: TCommonSessionParameters;
  StandardParams: TUpscalerParameters);
begin
  var rec := Default(TSessionRecord);
  rec.Status := ssPending;
  rec.SessionType := stStandard;
  rec.CommonParams := CommonParams;
  StampSessionPaths(rec.CommonParams);
  rec.SessionTOCFile := rec.CommonParams.SessionTOCFile;
  rec.StandardParams := StandardParams;
  rec.SubmittedAtUtc := Now;
  rec.ClosedAtUtc := 0;
  rec.SavedRecording := False;
  rec.SavedEventCount := 0;
  rec.PublishedToManifest := False;
  fSession := rec;
  fHasSession := True;

  BuildLaunchRequest(rec.CommonParams, StandardParams);

  NotifySessionSubmitted;
end;

end.
