unit u_ScratchRecorders;

interface

uses
  u_SimEventTypes, u_SimDiagnostics;

type
  IScratchRecorder = interface
    ['{3228AF23-3638-4112-8CB3-36FD11CC3A71}']
    function GetLog: IEventLog;
    function GetEnabled: Boolean;
    procedure SetEnabled(const Value: Boolean);
    function GetScratchFileName: string;

    procedure Bind(const aDiagnostics: TSimDiagnosticsHub);
    procedure Unbind;

    procedure AssertReadable;
    function EventCount: Integer;

    property Log: IEventLog read GetLog;
    property Enabled: Boolean read GetEnabled write SetEnabled;
    property ScratchFileName: string read GetScratchFileName;
  end;

function CreateLocalScratchRecorder: IScratchRecorder;
function CreateMappedScratchRecorder(const aScratchFileName: string): IScratchRecorder;

implementation

uses System.SysUtils, System.IOUtils,
  u_LocalEventLogs, u_MappedFileSink;

type
  TScratchRecorderBase = class(TInterfacedObject, IScratchRecorder)
  private
    fDiagnostics: TSimDiagnosticsHub;
    fSubscriptionId: Integer;
    fEnabled: Boolean;
  protected
    function GetConsumer: ISimEventConsumer; virtual; abstract;
    function GetLog: IEventLog; virtual; abstract;
    function GetScratchFileName: string; virtual; abstract;
    procedure Attach;
    procedure Detach;
    function GetEnabled: Boolean;
    procedure SetEnabled(const Value: Boolean);
  public
    destructor Destroy; override;

    procedure Bind(const aDiagnostics: TSimDiagnosticsHub);
    procedure Unbind;

    procedure AssertReadable; virtual; abstract;
    function EventCount: Integer; virtual;
  end;

  TLocalScratchRecorder = class(TScratchRecorderBase)
  private
    fEventConsumer: ISimEventConsumer;
    fEventLog: IEventLog;
  protected
    function GetConsumer: ISimEventConsumer; override;
    function GetLog: IEventLog; override;
    function GetScratchFileName: string; override;
  public
    constructor Create;
    procedure AssertReadable; override;
  end;

  TMappedScratchRecorder = class(TScratchRecorderBase)
  private
    fScratchFileName: string;
    fMappedSink: ISimEventConsumer;
    fMappedLog: IEventLog;
  protected
    function GetConsumer: ISimEventConsumer; override;
    function GetLog: IEventLog; override;
    function GetScratchFileName: string; override;
  public
    constructor Create(const aScratchFileName: string);
    procedure AssertReadable; override;
  end;



{ TScratchRecorderBase }

destructor TScratchRecorderBase.Destroy;
begin
  Unbind;
  inherited;
end;

procedure TScratchRecorderBase.Bind(const aDiagnostics: TSimDiagnosticsHub);
begin
  Assert(Assigned(aDiagnostics));
  Assert(not Assigned(fDiagnostics));

  fDiagnostics := aDiagnostics;
  if fEnabled then
    Attach;
end;

procedure TScratchRecorderBase.Unbind;
begin
  if Assigned(fDiagnostics) then
    Detach;

  fDiagnostics := nil;
end;

procedure TScratchRecorderBase.Attach;
begin
  Assert(Assigned(fDiagnostics));
  Assert(fSubscriptionId = 0);

  fSubscriptionId := fDiagnostics.Subscribe(GetConsumer);
end;

procedure TScratchRecorderBase.Detach;
begin
  Assert(Assigned(fDiagnostics));

  if fSubscriptionId <> 0 then
  begin
    fDiagnostics.Unsubscribe(fSubscriptionId);
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

  if not Assigned(fDiagnostics) then
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

{ TLocalScratchRecorder }

constructor TLocalScratchRecorder.Create;
begin
  inherited Create;
  fEventConsumer := TLocalEventLog.Create as ISimEventConsumer;
  fEventLog := fEventConsumer as IEventLog;
  SetEnabled(True);
end;

function TLocalScratchRecorder.GetConsumer: ISimEventConsumer;
begin
  Result := fEventConsumer;
end;

function TLocalScratchRecorder.GetLog: IEventLog;
begin
  Result := fEventLog;
end;

function TLocalScratchRecorder.GetScratchFileName: string;
begin
  Result := '';
end;

procedure TLocalScratchRecorder.AssertReadable;
begin
  Assert(Assigned(fEventLog));
end;

{ TMappedScratchRecorder }

constructor TMappedScratchRecorder.Create(const aScratchFileName: string);
begin
  inherited Create;
  Assert(aScratchFileName.Trim <> '');

  fScratchFileName := aScratchFileName;
  if TFile.Exists(fScratchFileName) then
    TFile.Delete(fScratchFileName);

  fMappedSink := TMappedFileSink.Create(fScratchFileName);
  fMappedLog := TMappedFileLog.Create(fScratchFileName);
  SetEnabled(True);
end;

function TMappedScratchRecorder.GetConsumer: ISimEventConsumer;
begin
  Result := fMappedSink;
end;

function TMappedScratchRecorder.GetLog: IEventLog;
begin
  Result := fMappedLog;
end;

function TMappedScratchRecorder.GetScratchFileName: string;
begin
  Result := fScratchFileName;
end;

procedure TMappedScratchRecorder.AssertReadable;
var
  count: Integer;
  lastEvent: TSimEvent;
  mappedLog: TMappedFileLog;
  header: TSimLogHeader;
begin
  Assert(Assigned(fMappedLog));

  count := fMappedLog.Count;
  if count = 0 then
    Exit;

  lastEvent := fMappedLog.Events[count - 1];
  Assert(lastEvent.Header.Sequence = count);

  mappedLog := fMappedLog as TMappedFileLog;
  header := mappedLog.Header;
  Assert(header.Signature = EVENT_LOG_FILE_SIGNATURE);
  Assert(header.EventCount = count);
end;

function CreateLocalScratchRecorder: IScratchRecorder;
begin
  Result := TLocalScratchRecorder.Create;
end;

function CreateMappedScratchRecorder(const aScratchFileName: string): IScratchRecorder;
begin
  Result := TMappedScratchRecorder.Create(aScratchFileName);
end;

end.
