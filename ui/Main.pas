unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.Buttons, Vcl.ComCtrls, Vcl.AppEvnts, Vcl.ExtCtrls, PngSpeedButton,

  fr_ContentFrames;


type
  TContentFrameType = (cfFood, cfBiomes, cfRegions, cfWorlds, cfSimulator);

  TMainForm = class(TForm)
    StatusBar: TStatusBar;
    AppEvents: TApplicationEvents;
    pnlTaskbar: TPanel;
    btnFood: TPngSpeedButton;
    btnBiomes: TPngSpeedButton;
    btnWorlds: TPngSpeedButton;
    btnSimulator: TPngSpeedButton;
    btnRegions: TPngSpeedButton;
    btnSave: TPngSpeedButton;
    procedure FormCreate(Sender: TObject);
    procedure AppEventsHint(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure ContentSelectorClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
  private
    ActiveFrameType: TContentFrameType;
    ContentFrames: array[TContentFrameType] of TContentFrame;
    procedure ActivateContent(FrameType: TContentFrameType);
    procedure WorldLibraryModified(Sender: TObject);
    procedure UpdateControls;
  public

  end;

var
  MainForm: TMainForm;

implementation

uses System.IOUtils, System.UITypes, Vcl.GraphUtil, Vcl.Themes,
  u_EnvironmentLibraries, u_Serialization,
  fr_FoodEditor,
  fr_BiomeEditor,
  fr_RegionEditor,
  fr_SimFrame;

{$R *.dfm}

const
  ContentFrameClasses: array[TContentFrameType] of TContentFrameClass = (
    TFoodEditor,
    TBiomeEditor,
    TRegionEditor,
    nil, { world }
    TSimFrame
  );

{ Utility }
function LibraryFileName: string;
begin
  Result := TPath.Combine(ExtractFilePath(Application.ExeName), 'WorldLibrary.json');
end;



{ TMainForm }
procedure TMainForm.FormCreate(Sender: TObject);
begin
  // initialize global library
  WorldLibrary := TEnvironmentLibrary.Create;
  TSerializer.LoadLibrary(WorldLibrary, LibraryFileName());
  WorldLibrary.Modified := False;
  WorldLibrary.OnChange := WorldLibraryModified;

  pnlTaskbar.StyleElements := pnlTaskbar.StyleElements - [seClient];
  pnlTaskbar.Color := GetHighlightColor(StyleServices.GetSystemColor(clBtnFace), 8);

  btnFood.Tag := Ord(cfFood);
  btnBiomes.Tag := Ord(cfBiomes);
  btnRegions.Tag := Ord(cfRegions);
  btnWorlds.Tag := Ord(cfWorlds);
  btnSimulator.Tag := Ord(cfSimulator);

  ActiveFrameType := High(TContentFrameType); // ensure a change
  ActivateContent(Low(TContentFrameType));
  UpdateControls;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  for var frameType := Low(TContentFrameType) to High(TContentFrameType) do
    if ContentFrames[frameType] <> nil then
      ContentFrames[frameType].Done;

  WorldLibrary.Free;
end;

procedure TMainForm.UpdateControls;
begin
  btnSave.Enabled := WorldLibrary.Modified;
end;

procedure TMainForm.WorldLibraryModified(Sender: TObject);
begin
  UpdateControls;
end;

procedure TMainForm.btnSaveClick(Sender: TObject);
begin
  WorldLibrary.BeginUpdate;
  try
    TSerializer.SaveLibrary(WorldLibrary, LibraryFileName());
    WorldLibrary.Modified := False;
  finally
    WorldLibrary.EndUpdate;
  end;

  UpdateControls;
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
    ContentFrames[ActiveFrameType].Show;

    // if we need to someday, on the sim page we can free the other content pages
    // and nill out the instance pointers.
    // consider adding another virtual pair to TContentFrame for save/restore


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
          TSerializer.SaveLibrary(WorldLibrary, LibraryFileName());
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
