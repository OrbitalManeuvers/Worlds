program Worlds;

uses
  Vcl.Forms,
  Main in 'ui\Main.pas' {MainForm},
  Vcl.Themes,
  Vcl.Styles,
  u_Worlds.Types in 'common\u_Worlds.Types.pas',
  u_Environment.Types in 'common\u_Environment.Types.pas',
  u_Environment.JSON in 'common\u_Environment.JSON.pas',
  fr_WorldFrame in 'ui\fr_WorldFrame.pas' {WorldFrame: TFrame},
  u_Worlds in 'common\u_Worlds.pas',
  fr_ContentFrames in 'ui\fr_ContentFrames.pas' {ContentFrame: TFrame},
  fr_FoodEditor in 'ui\fr_FoodEditor.pas' {FoodEditor: TFrame},
  u_ControlRendering in 'ui\u_ControlRendering.pas',
  u_Worlds.JSON in 'common\u_Worlds.JSON.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Worlds';
  TStyleManager.TrySetStyle('Klondike');
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
