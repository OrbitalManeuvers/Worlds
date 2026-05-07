unit u_SessionManager;

interface

uses System.Generics.Collections,
  u_SessionParameters, u_Worlds, u_WorldsMessages;

type
  TSessionStatus = (ssPending, ssRunning, ssCompleted, ssFailed);

  TSessionRecord = record
    Id: TSessionId;
    Status: TSessionStatus;
    CommonParams: TCommonSessionParameters;
    SessionType: TSessionType;
    StandardParams: TUpscalerParameters;  // includes World
    DebugParams: TDebugSessionParameters;
    Notes: string;
  end;

  TSessionManager = class
  private
    fSessions: TList<TSessionRecord>;
    procedure NotifySessionSubmitted;
  public
    constructor Create;
    destructor Destroy; override;

    // These notify the system via WM_SESSION_SUBMITTED
    function SubmitStandardSession(const CommonParams: TCommonSessionParameters;
      StandardParams: TUpscalerParameters): TSessionId;

    function SubmitDebugSession(const CommonParams: TCommonSessionParameters;
      DebugParams: TDebugSessionParameters): TSessionId;

    // main form calls these
    function GetSession(const aId: TSessionId): TSessionRecord;

    // update session status
    procedure SetSessionStatus(aId: TSessionId; aStatus: TSessionStatus; const aNotes: string);
  end;

var
  SessionManager: TSessionManager = nil;

implementation

uses WinApi.Windows, Vcl.Forms;

{ TSessionManager }

constructor TSessionManager.Create;
begin
  inherited;
  fSessions := TList<TSessionRecord>.Create;
end;

destructor TSessionManager.Destroy;
begin
  fSessions.Free;
  inherited;
end;

function TSessionManager.GetSession(const aId: TSessionId): TSessionRecord;
begin
  Assert((aId >= 0) and (aId < fSessions.Count));
  Result := fSessions[aId];
end;

procedure TSessionManager.NotifySessionSubmitted;
begin
  if fSessions.Count > 0 then
    PostMessage(Application.MainForm.Handle, WM_SESSION_SUBMITTED, fSessions.Last.Id, 0);
end;

procedure TSessionManager.SetSessionStatus(aId: TSessionId; aStatus: TSessionStatus; const aNotes: string);
begin
  var rec := GetSession(aId);
  rec.Status := aStatus;
  rec.Notes := aNotes;
  fSessions[aId] := rec;
end;

function TSessionManager.SubmitDebugSession(const CommonParams: TCommonSessionParameters;
  DebugParams: TDebugSessionParameters): TSessionId;
begin
  var rec := Default(TSessionRecord);
  rec.Id := fSessions.Count;
  rec.SessionType := stDebug;
  rec.CommonParams := CommonParams;
  rec.DebugParams := DebugParams;
  fSessions.Add(rec);

  Result := rec.Id;

  NotifySessionSubmitted;
end;

function TSessionManager.SubmitStandardSession(const CommonParams: TCommonSessionParameters;
  StandardParams: TUpscalerParameters): TSessionId;
begin
  var rec := Default(TSessionRecord);
  rec.Id := fSessions.Count;
  rec.SessionType := stStandard;
  rec.CommonParams := CommonParams;
  rec.StandardParams := StandardParams;
  fSessions.Add(rec);

  Result := rec.Id;

  NotifySessionSubmitted;
end;

end.
