unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.Buttons, Vcl.ComCtrls, Vcl.AppEvnts, Vcl.ExtCtrls, PngSpeedButton,
  System.ImageList, Vcl.ImgList, PngImageList,

  fr_ContentFrames, u_WorldsMessages, u_ProgramSettings;


type
  TContentFrameType = (cfFood, cfBiomes, cfRegions, cfBiology, cfWorlds, cfSession, cfSimulator);

  TMainForm = class(TForm)
    StatusBar: TStatusBar;
    AppEvents: TApplicationEvents;
    pnlTaskbar: TPanel;
    btnFood: TPngSpeedButton;
    btnBiomes: TPngSpeedButton;
    btnWorlds: TPngSpeedButton;
    btnSessions: TPngSpeedButton;
    btnRegions: TPngSpeedButton;
    btnSave: TPngSpeedButton;
    btnBiology: TPngSpeedButton;
    btnSettings: TPngSpeedButton;
    MainToolImages: TPngImageList;
    procedure FormCreate(Sender: TObject);
    procedure AppEventsHint(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure ContentSelectorClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);

    procedure WMSessionSubmitted(var Msg: TMessage); message WM_SESSION_SUBMITTED;
    procedure WMEndSimulation(var Msg: TMessage); message WM_END_SIMULATION;
    procedure btnSettingsClick(Sender: TObject);

  private type
    TWorldsFileType = (ftSettings, ftLibrary, ftDebugLibrary);
  private
    ScenarioFolder: string;
    ActiveFrameType: TContentFrameType;
    ContentFrames: array[TContentFrameType] of TContentFrame;
    Settings: TProgramSettings;
    function GetFileName(aType: TWorldsFileType): string;
    procedure ActivateContent(FrameType: TContentFrameType);
    procedure WorldLibraryModified(Sender: TObject);
    procedure UpdateControls;
    procedure TryLoadSettings;
  public

  end;

var
  MainForm: TMainForm;

implementation

uses System.IOUtils, System.UITypes, Vcl.GraphUtil, Vcl.Themes,
  u_EnvironmentLibraries, u_Serialization, u_AgentTypes,
  fr_FoodEditor,
  fr_BiomeEditor,
  fr_RegionEditor,
  fr_BiologyEditor,
  fr_WorldEditor,
  fr_Session,
  fr_Simulator,
  u_WorldLayouts,
  u_SessionComposers,
  u_DebugSessionComposers,
  u_SessionComposerIntf,
  u_DebugLibraries,
  u_SessionManager,
  u_SessionParameters;

{$R *.dfm}

const
  ContentFrameClasses: array[TContentFrameType] of TContentFrameClass = (
    TFoodEditor,
    TBiomeEditor,
    TRegionEditor,
    TBiologyEditor,
    TWorldEditor,
    TSessionFrame,
    TSimulatorFrame
  );

{ Utility }
function RuntimeFilePath(const aFileName: string): string;
begin
  Result := TPath.Combine(ExtractFilePath(Application.ExeName), aFileName);
end;


{ TMainForm }

function TMainForm.GetFileName(aType: TWorldsFileType): string;
begin
  case aType of
    ftSettings:
      Result := RuntimeFilePath('ProgramSettings.json');
    ftLibrary:
      Result := RuntimeFilePath(TPath.Combine(ScenarioFolder, 'WorldsEnvironmentLibrary.json'));
    ftDebugLibrary:
      Result := RuntimeFilePath(TPath.Combine(ScenarioFolder, 'WorldsDebugLibrary.json'));
  else
    Result := '';
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Settings := Default(TProgramSettings);

  ScenarioFolder := '';
  for var paramIndex := 1 to ParamCount do
  begin
    var param := ParamStr(paramIndex);
    if SameText(Copy(param, 1, 10), '-scenario=') then
    begin
      ScenarioFolder := Trim(Copy(param, 11, MaxInt));
      Break;
    end;
  end;

  // initialize global library
  WorldLibrary := TEnvironmentLibrary.Create;
  TSerializer.LoadLibrary(WorldLibrary, GetFileName(ftLibrary));
  WorldLibrary.Modified := False;
  WorldLibrary.OnChange := WorldLibraryModified;

  // global debug library
  DebugLibrary := TDebugLibrary.Create(GetFileName(ftDebugLibrary));

  // global session manager
  SessionManager := TSessionManager.Create;
  TryLoadSettings;

  pnlTaskbar.StyleElements := pnlTaskbar.StyleElements - [seClient];
  pnlTaskbar.Color := GetHighlightColor(StyleServices.GetSystemColor(clBtnFace), 8);

  btnFood.Tag := Ord(cfFood);
  btnBiomes.Tag := Ord(cfBiomes);
  btnRegions.Tag := Ord(cfRegions);
  btnBiology.Tag := Ord(cfBiology);
  btnWorlds.Tag := Ord(cfWorlds);
  btnSessions.Tag := Ord(cfSession);

  ActiveFrameType := High(TContentFrameType); // ensure a change
  ActivateContent(Low(TContentFrameType));
  UpdateControls;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  for var frameType := Low(TContentFrameType) to High(TContentFrameType) do
    if ContentFrames[frameType] <> nil then
      ContentFrames[frameType].Done;

  SessionManager.Free;
  DebugLibrary.Free;
  WorldLibrary.Free;
end;

procedure TMainForm.UpdateControls;
begin
  btnSave.Enabled := WorldLibrary.Modified;
end;

procedure TMainForm.TryLoadSettings;
begin
  SessionManager.LogFolder := '';
  SessionManager.ScratchFolder := '';
  if Settings.LoadFromFile(GetFileName(ftSettings)) then
  begin
    btnSettings.ImageIndex := -1;
    SessionManager.LogFolder := Settings.LogFolder;
    SessionManager.ScratchFolder := Settings.ScratchFolder;
  end
  else
    btnSettings.ImageIndex := 6; // !! blahh
end;

procedure TMainForm.WMSessionSubmitted(var Msg: TMessage);
begin
  var request := SessionManager.GetLaunchRequest;

  ActivateContent(cfSimulator);
  var simFrame: TSimulatorFrame := ContentFrames[cfSimulator] as TSimulatorFrame;
  simFrame.StartFromLaunchRequest(request);
end;

procedure TMainForm.WMEndSimulation(var Msg: TMessage);
begin
  inherited;
  Assert(ActiveFrameType = cfSimulator);
  ActivateContent(cfSession);
end;

procedure TMainForm.WorldLibraryModified(Sender: TObject);
begin
  UpdateControls;
end;

procedure TMainForm.btnSaveClick(Sender: TObject);
begin
  WorldLibrary.BeginUpdate;
  try
    TSerializer.SaveLibrary(WorldLibrary, GetFileName(ftLibrary));
    WorldLibrary.Modified := False;
  finally
    WorldLibrary.EndUpdate;
  end;

  UpdateControls;
end;

procedure TMainForm.btnSettingsClick(Sender: TObject);
begin
  TryLoadSettings;
end;

procedure TMainForm.ContentSelectorClick(Sender: TObject);
begin
  if Sender is TComponent then
  begin
    var frameType := TContentFrameType(TComponent(Sender).Tag);
    ActivateContent(frameType);
  end;
end;

procedure TMainForm.ActivateContent(FrameType: TContentFrameType);
begin
  if FrameType <> ActiveFrameType then
  begin
    // deactivate current content
    if Assigned(ContentFrames[ActiveFrameType]) then
    begin
      ContentFrames[ActiveFrameType].Hide;
      ContentFrames[ActiveFrameType].DeactivateContent;
    end;

    ActiveFrameType := FrameType;
    if ContentFrameClasses[FrameType] = nil then
      Exit;

    if not Assigned(ContentFrames[ActiveFrameType]) then
    begin
      var frame := ContentFrameClasses[ActiveFrameType].Create(Self);
      frame.Align := alClient;
      frame.Parent := Self;
      frame.Init;
      ContentFrames[ActiveFrameType] := frame;
    end;

    ContentFrames[ActiveFrameType].ActivateContent;
    pnlTaskbar.Visible := ActiveFrameType <> cfSimulator;
    ContentFrames[ActiveFrameType].Show;
  end;
  UpdateControls;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
const
  SAVE_PROMPT = 'Save changes?';
begin
  if CanClose and WorldLibrary.Modified then
  begin
    var result := MessageDlg(SAVE_PROMPT, TMsgDlgType.mtConfirmation, [mbYes, mbNo, mbCancel], 0);
    case result of
      mrYes:
        begin
          TSerializer.SaveLibrary(WorldLibrary, GetFileName(ftLibrary));
          CanClose := True;
        end;
      mrNo:
        begin
          CanClose := True;
        end;
      mrCancel:
        begin
          CanClose := False;
        end;
    end;
  end;
end;

procedure TMainForm.AppEventsHint(Sender: TObject);
begin
  StatusBar.SimpleText := Application.Hint;
end;

end.
