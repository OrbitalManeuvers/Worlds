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
  public

  end;

var
  MainForm: TMainForm;

implementation

uses Vcl.GraphUtil, Vcl.Themes, System.IOUtils, System.Generics.Collections,

  u_Worlds.JSON;

{$R *.dfm}

{ TMainForm }
procedure TMainForm.FormCreate(Sender: TObject);
begin
  // initialization
  World := nil;
  UpdateControls;

  // load state

  //
  if not Assigned(World) then
  begin
    NewWorld;

  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  CloseWorld;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := True;

  if Assigned(World) {and World.Modified} then
  begin
    var fileName := TPath.Combine(ExtractFilePath(Application.ExeName), 'default.json');
    TFile.WriteAllText(fileName, World.AsJSON.Format(4));
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
