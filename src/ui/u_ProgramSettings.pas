unit u_ProgramSettings;

interface

type
  TProgramSettings = record
    LogFolder: string;
    ScratchFolder: string;
    function LoadFromFile(const aFileName: string): Boolean;
  end;


implementation

uses System.SysUtils, System.IOUtils, System.JSON;

const
  KEY_LOG_FOLDER = 'logFolder';
  KEY_SCRATCH_FOLDER = 'scratchFolder';

function ValidatePath(const aPath: string): string;
begin
  Result := '';
  if not aPath.IsEmpty then
  begin
    var fullPath := TPath.GetFullPath(aPath);
    if TDirectory.Exists(fullPath) then
      Exit(fullPath);
  end;

  if aPath.IsEmpty and TDirectory.Exists(aPath) then Result := aPath
  else Result := '';
end;

{ TProgramSettings }

function TProgramSettings.LoadFromFile(const aFileName: string): Boolean;
begin
  Result := False;
  if not TFile.Exists(aFileName) then
    Exit;

  var json := TJSONValue.ParseJSONValue(TFile.ReadAllText(aFileName)) as TJSONObject;
  if Assigned(json) then
  begin
    var strVal: string;
    if json.TryGetValue(KEY_LOG_FOLDER, strVal) then
      Self.LogFolder := ValidatePath(strVal.Trim);
    if json.TryGetValue(KEY_SCRATCH_FOLDER, strVal) then
      Self.ScratchFolder := ValidatePath(strVal.Trim);
  end;

  Result := TDirectory.Exists(LogFolder) and TDirectory.Exists(ScratchFolder);
end;

end.
