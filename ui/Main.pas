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
    StatusBar: TStatusBar;
    AppEvents: TApplicationEvents;
    procedure FormCreate(Sender: TObject);
    procedure AppEventsHint(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormDestroy(Sender: TObject);
  private
    WorldFrame: TWorldFrame;

  public

  end;

var
  MainForm: TMainForm;

implementation

uses System.JSON, Vcl.GraphUtil, Vcl.Themes, System.IOUtils, System.Generics.Collections,
  u_EnvironmentLibraries, System.UITypes;

{$R *.dfm}

function LibraryFileName: string;
begin
  Result := TPath.Combine(ExtractFilePath(Application.ExeName), 'WorldLibrary.json');
end;

{ TMainForm }
procedure TMainForm.FormCreate(Sender: TObject);
begin
  // initialize global library
  WorldLibrary := TEnvironmentLibrary.Create;
  WorldLibrary.LoadFromFile(LibraryFileName());

  // create main frame
  WorldFrame := TWorldFrame.Create(Self);
  WorldFrame.Align := alClient;
  WorldFrame.Parent := Self;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  WorldLibrary.Free;
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
          WorldLibrary.SaveToFile(LibraryFileName());
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
