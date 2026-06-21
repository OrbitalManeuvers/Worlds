unit u_ScratchRecorders;

interface

uses
  u_SessionEventTypes;

type
  ISessionScratchRecorder = interface
    ['{A7E2D641-8B3F-4C1A-9D05-6E4F82B1C790}']
    function GetLog: ISessionEventLog;
    function GetEnabled: Boolean;
    procedure SetEnabled(const Value: Boolean);
    function GetScratchFileName: string;

    procedure Bind(const aHub: ISessionEventHub);
    procedure Unbind;

    procedure AssertReadable;
    function EventCount: Integer;

    property Log: ISessionEventLog read GetLog;
    property Enabled: Boolean read GetEnabled write SetEnabled;
    property ScratchFileName: string read GetScratchFileName;
  end;

function CreateLocalSessionScratchRecorder: ISessionScratchRecorder;
function CreateSessionScratchRecorder(const aScratchFileName: string): ISessionScratchRecorder;

implementation

uses System.SysUtils, System.IOUtils,
  u_LocalEventLogs, u_SessionFileSink;

type
  TScratchRecorderBase = class(TInterfacedObject, ISessionScratchRecorder)
  private
    fEventHub: ISessionEventHub;
    fSubscriptionId: Integer;
    fEnabled: Boolean;
  protected
    function GetConsumer: ISessionEventConsumer; virtual; abstract;
    function GetLog: ISessionEventLog; virtual; abstract;
    function GetScratchFileName: string; virtual; abstract;
    procedure Attach;
    procedure Detach;
    function GetEnabled: Boolean;
    procedure SetEnabled(const Value: Boolean);
  public
    destructor Destroy; override;

    procedure Bind(const aEventHub: ISessionEventHub);
    procedure Unbind;

    procedure AssertReadable; virtual; abstract;
    function EventCount: Integer; virtual;
  end;

  TSessionScratchRecorder = class(TScratchRecorderBase)
  private
    fScratchFileName: string;
    fSink: ISessionEventConsumer;
    fLog: ISessionEventLog;
  protected
    function GetConsumer: ISessionEventConsumer; override;
    function GetLog: ISessionEventLog; override;
    function GetScratchFileName: string; override;
  public
    constructor Create(const aScratchFileName: string);
    procedure AssertReadable; override;
  end;

  TLocalSessionScratchRecorder = class(TScratchRecorderBase)
  private
    fEventConsumer: ISessionEventConsumer;
    fEventLog: ISessionEventLog;
  protected
    function GetConsumer: ISessionEventConsumer; override;
    function GetLog: ISessionEventLog; override;
    function GetScratchFileName: string; override;
  public
    constructor Create;
    procedure AssertReadable; override;
  end;


{ TScratchRecorderBase }

destructor TScratchRecorderBase.Destroy;
begin
  Unbind;
  inherited;
end;

procedure TScratchRecorderBase.Bind(const aEventHub: ISessionEventHub);
begin
  Assert(Assigned(aEventHub));
  Assert(not Assigned(fEventHub));
  fEventHub := aEventHub;
  if fEnabled then
    Attach;
end;

procedure TScratchRecorderBase.Unbind;
begin
  if Assigned(fEventHub) then
    Detach;
  fEventHub := nil;
end;

procedure TScratchRecorderBase.Attach;
begin
  Assert(Assigned(fEventHub));
  Assert(fSubscriptionId = 0);

  fSubscriptionId := fEventHub.Subscribe(GetConsumer);
end;

procedure TScratchRecorderBase.Detach;
begin
  Assert(Assigned(fEventHub));

  if fSubscriptionId <> 0 then
  begin
    fEventHub.Unsubscribe(fSubscriptionId);
    fSubscriptionId := 0;
  end;
end;

function TScratchRecorderBase.GetEnabled: Boolean;
begin
  Result := fEnabled;
end;

procedure TScratchRecorderBase.SetEnabled(const Value: Boolean);
begin
  if Value = fEnabled then
    Exit;

  fEnabled := Value;

  if not Assigned(fEventHub) then
    Exit;

  if fEnabled then
    Attach
  else
    Detach;
end;

function TScratchRecorderBase.EventCount: Integer;
begin
  Result := GetLog.Count;
end;

function CreateSessionScratchRecorder(const aScratchFileName: string): ISessionScratchRecorder;
begin
  Result := TSessionScratchRecorder.Create(aScratchFileName);
end;

{ TSessionScratchRecorder }

constructor TSessionScratchRecorder.Create(const aScratchFileName: string);
begin
  inherited Create;
  Assert(aScratchFileName.Trim <> '');

  fScratchFileName := aScratchFileName;
  if TFile.Exists(fScratchFileName) then
    TFile.Delete(fScratchFileName);

  fSink := TSessionFileSink.Create(fScratchFileName);
  fLog := TSessionFileLog.Create(fScratchFileName);
  SetEnabled(True);
end;

function TSessionScratchRecorder.GetConsumer: ISessionEventConsumer;
begin
  Result := fSink;
end;

function TSessionScratchRecorder.GetLog: ISessionEventLog;
begin
  Result := fLog;
end;

function TSessionScratchRecorder.GetScratchFileName: string;
begin
  Result := fScratchFileName;
end;

procedure TSessionScratchRecorder.AssertReadable;
var
  count: Integer;
  header: TSessionLogHeader;
  fileLog: TSessionFileLog;
begin
  Assert(Assigned(fLog));

  count := fLog.Count;
  if count = 0 then
    Exit;

  fileLog := (fLog as TSessionFileLog);
  header := fileLog.Header;
  Assert(header.Signature = SESSION_LOG_SIGNATURE);
  Assert(header.EventCount = count);
end;

{ TLocalSessionScratchRecorder }

constructor TLocalSessionScratchRecorder.Create;
begin
  inherited Create;
  fEventConsumer := TLocalEventLog.Create as ISessionEventConsumer;
  fEventLog := fEventConsumer as ISessionEventLog;
  SetEnabled(True);

end;

procedure TLocalSessionScratchRecorder.AssertReadable;
begin
  Assert(Assigned(fEventLog));
end;


function TLocalSessionScratchRecorder.GetConsumer: ISessionEventConsumer;
begin
  Result := fEventConsumer;
end;

function TLocalSessionScratchRecorder.GetLog: ISessionEventLog;
begin
  Result := fEventLog;
end;

function TLocalSessionScratchRecorder.GetScratchFileName: string;
begin
  Result := '';
end;

function CreateLocalSessionScratchRecorder: ISessionScratchRecorder;
begin
  Result := TLocalSessionScratchRecorder.Create;
end;

end.
