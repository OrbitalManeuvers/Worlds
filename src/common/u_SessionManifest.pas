unit u_SessionManifest;

interface

uses System.Generics.Collections;

type
  TSessionManifestEntry = record
    SessionTitle: string;
    SessionLogFile: string;
    SessionTOCFile: string;
    SessionType: string;
    Status: string;
    SavedRecording: Boolean;
    SavedEventCount: Integer;
    SubmittedAtUtc: TDateTime;
    ClosedAtUtc: TDateTime;
    Notes: string;
  end;

  TSessionManifest = class
  private
    fItems: TList<TSessionManifestEntry>;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    procedure Add(const aEntry: TSessionManifestEntry);
    function ToArray: TArray<TSessionManifestEntry>;

    function LoadFromFile(const aFileName: string): Boolean;
    procedure SaveToFile(const aFileName: string);

    property Count: Integer read GetCount;
  end;

implementation

uses System.SysUtils, System.JSON, System.IOUtils, System.DateUtils;

const
  SESSION_MANIFEST_VERSION = 1;
  KEY_VERSION = 'version';
  KEY_SESSIONS = 'sessions';
  KEY_SESSION_TITLE = 'sessionTitle';
  KEY_SESSION_LOG_FILE = 'sessionLogFile';
  KEY_SESSION_TOC_FILE = 'sessionTOCFile';
  KEY_SESSION_TYPE = 'sessionType';
  KEY_STATUS = 'status';
  KEY_SAVED_RECORDING = 'savedRecording';
  KEY_SAVED_EVENT_COUNT = 'savedEventCount';
  KEY_SUBMITTED_AT_UTC = 'submittedAtUtc';
  KEY_CLOSED_AT_UTC = 'closedAtUtc';
  KEY_NOTES = 'notes';

function Iso8601OrEmpty(aValue: TDateTime): string;
begin
  if aValue = 0 then
    Exit('');
  Result := DateToISO8601(aValue, True);
end;

function TryParseIso8601OrEmpty(const aValue: string; out aParsed: TDateTime): Boolean;
begin
  if aValue.Trim.IsEmpty then
  begin
    aParsed := 0;
    Exit(True);
  end;

  Result := TryISO8601ToDate(aValue, aParsed, True);
end;

{ TSessionManifest }

constructor TSessionManifest.Create;
begin
  inherited;
  fItems := TList<TSessionManifestEntry>.Create;
end;

destructor TSessionManifest.Destroy;
begin
  fItems.Free;
  inherited;
end;

procedure TSessionManifest.Clear;
begin
  fItems.Clear;
end;

procedure TSessionManifest.Add(const aEntry: TSessionManifestEntry);
begin
  fItems.Add(aEntry);
end;

function TSessionManifest.GetCount: Integer;
begin
  Result := fItems.Count;
end;

function TSessionManifest.ToArray: TArray<TSessionManifestEntry>;
begin
  Result := fItems.ToArray;
end;

function TSessionManifest.LoadFromFile(const aFileName: string): Boolean;
begin
  Clear;
  Result := False;

  if not TFile.Exists(aFileName) then
    Exit;

  var json := TJSONObject.ParseJSONValue(TFile.ReadAllText(aFileName, TEncoding.UTF8)) as TJSONObject;
  try
    if not Assigned(json) then
      Exit;

    var arrayValue: TJSONArray;
    if not json.TryGetValue<TJSONArray>(KEY_SESSIONS, arrayValue) then
      Exit;

    for var index := 0 to arrayValue.Count - 1 do
    begin
      var item := arrayValue.Items[index] as TJSONObject;
      if not Assigned(item) then
        Continue;

      var entry := Default(TSessionManifestEntry);
      item.TryGetValue<string>(KEY_SESSION_TITLE, entry.SessionTitle);
      item.TryGetValue<string>(KEY_SESSION_LOG_FILE, entry.SessionLogFile);
      item.TryGetValue<string>(KEY_SESSION_TOC_FILE, entry.SessionTOCFile);
      item.TryGetValue<string>(KEY_SESSION_TYPE, entry.SessionType);
      item.TryGetValue<string>(KEY_STATUS, entry.Status);
      item.TryGetValue<Boolean>(KEY_SAVED_RECORDING, entry.SavedRecording);
      item.TryGetValue<Integer>(KEY_SAVED_EVENT_COUNT, entry.SavedEventCount);
      item.TryGetValue<string>(KEY_NOTES, entry.Notes);

      var dtText := '';
      if item.TryGetValue<string>(KEY_SUBMITTED_AT_UTC, dtText) then
        TryParseIso8601OrEmpty(dtText, entry.SubmittedAtUtc);

      dtText := '';
      if item.TryGetValue<string>(KEY_CLOSED_AT_UTC, dtText) then
        TryParseIso8601OrEmpty(dtText, entry.ClosedAtUtc);

      Add(entry);
    end;

    Result := True;
  finally
    json.Free;
  end;
end;

procedure TSessionManifest.SaveToFile(const aFileName: string);
begin
  Assert(not aFileName.Trim.IsEmpty);

  var root := TJSONObject.Create;
  try
    root.AddPair(KEY_VERSION, TJSONNumber.Create(SESSION_MANIFEST_VERSION));

    var sessions := TJSONArray.Create;
    for var entry in fItems do
    begin
      var item := TJSONObject.Create;
      item.AddPair(KEY_SESSION_TITLE, entry.SessionTitle);
      item.AddPair(KEY_SESSION_LOG_FILE, entry.SessionLogFile);
      item.AddPair(KEY_SESSION_TOC_FILE, entry.SessionTOCFile);
      item.AddPair(KEY_SESSION_TYPE, entry.SessionType);
      item.AddPair(KEY_STATUS, entry.Status);
      item.AddPair(KEY_SAVED_RECORDING, TJSONBool.Create(entry.SavedRecording));
      item.AddPair(KEY_SAVED_EVENT_COUNT, TJSONNumber.Create(entry.SavedEventCount));
      item.AddPair(KEY_SUBMITTED_AT_UTC, Iso8601OrEmpty(entry.SubmittedAtUtc));
      item.AddPair(KEY_CLOSED_AT_UTC, Iso8601OrEmpty(entry.ClosedAtUtc));
      item.AddPair(KEY_NOTES, entry.Notes);
      sessions.AddElement(item);
    end;

    root.AddPair(KEY_SESSIONS, sessions);

    var folder := TPath.GetDirectoryName(aFileName);
    if (folder <> '') and not TDirectory.Exists(folder) then
      TDirectory.CreateDirectory(folder);

    TFile.WriteAllText(aFileName, root.Format(4), TEncoding.UTF8);
  finally
    root.Free;
  end;
end;

end.
