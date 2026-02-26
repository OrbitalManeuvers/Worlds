unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Menus,
  Vcl.Buttons, PngSpeedButton, Vcl.ComCtrls, Vcl.ControlList, Vcl.AppEvnts,

  fr_WorldFrame,
  u_Worlds;

type
  TMainForm = class(TForm)
    MainMenu: TMainMenu;
    mnuFile: TMenuItem;
    mniFileNew: TMenuItem;
    mniFileOpen: TMenuItem;
    mniFileSave: TMenuItem;
    mniFileSaveAs: TMenuItem;
    mniFileExit: TMenuItem;
    N1: TMenuItem;
    StatusBar: TStatusBar;
    AppEvents: TApplicationEvents;
    Help1: TMenuItem;
    About1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure AppEventsHint(Sender: TObject);
    procedure mniFileExitClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormDestroy(Sender: TObject);
  private
    World: TWorld;
    WorldFrame: TWorldFrame;

    procedure NewWorld;
    procedure CloseWorld;
    procedure UpdateControls;
    procedure WorldCreated;
    procedure LoadWorld(const aFileName: string);
  public

  end;

var
  MainForm: TMainForm;

implementation

uses System.JSON, Vcl.GraphUtil, Vcl.Themes, System.IOUtils, System.Generics.Collections,

  u_Worlds.JSON, u_EnvironmentLibraries;

{$R *.dfm}

function WorldFileName: string;
begin
  Result := TPath.Combine(ExtractFilePath(Application.ExeName), 'default.json');
end;

function LibraryFileName: string;
begin
  Result := TPath.Combine(ExtractFilePath(Application.ExeName), 'library.json');
end;

{ TMainForm }
procedure TMainForm.FormCreate(Sender: TObject);
begin
  // initialization
  World := nil;
  UpdateControls;

  // initialize global library
  InitGlobalLibrary;
  GlobalLibrary.LoadFromFile(LibraryFileName());


  // load state - for now, single world file
  var fName := WorldFileName();
  if TFile.Exists(fName) then
  begin
    LoadWorld(fName);
  end;

  //
  if not Assigned(World) then
  begin
    NewWorld;

  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  CloseWorld;
  DoneGlobalLibrary;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := True;

  if Assigned(World) and World.Modified then
  begin
    var fileName := WorldFileName();

    { !! still single file only here }
//    World.SaveToFile(fileName);
//    TFile.WriteAllText(fileName, World.AsJSON.Format(4));
  end;

  if CanClose and Assigned(World) then
    CloseWorld;
end;

procedure TMainForm.mniFileExitClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TMainForm.NewWorld;
begin
  World := TWorld.Create;
//  World.CreateSampleData;
  WorldCreated;
end;

procedure TMainForm.LoadWorld(const aFileName: string);
begin
  World := TWorld.Create;
  World.BeginUpdate;
  try
//    World.LoadFromFile(aFileName);
    World.Modified := False;
  finally
    World.EndUpdate;
  end;

  WorldCreated;
end;

procedure TMainForm.UpdateControls;
begin
  //
  mniFileSave.Enabled := Assigned(World) and World.Modified;
  mniFileSaveAs.Enabled := Assigned(World);
end;

procedure TMainForm.CloseWorld;
begin
  if Assigned(World) then
  begin
    World.Free;
    World := nil;
  end;
end;

procedure TMainForm.WorldCreated;
begin
  // create main frame
  if not Assigned(WorldFrame) then
  begin
    WorldFrame := TWorldFrame.Create(Self);
    WorldFrame.Align := alClient;
    WorldFrame.Parent := Self;
  end;

  WorldFrame.World := World;
  UpdateControls;
end;


procedure TMainForm.AppEventsHint(Sender: TObject);
begin
  StatusBar.SimpleText := Application.Hint;
end;


end.
