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
  u_Worlds.JSON in 'common\u_Worlds.JSON.pas',
  fr_BiomeEditor in 'ui\fr_BiomeEditor.pas' {BiomeEditor: TFrame},
  u_EditorObjects in 'common\u_EditorObjects.pas',
  u_Foods in 'common\u_Foods.pas',
  u_Biomes in 'common\u_Biomes.pas',
  u_Regions in 'common\u_Regions.pas',
  u_EnvironmentLibraries in 'common\u_EnvironmentLibraries.pas',
  u_Foods.JSON in 'common\u_Foods.JSON.pas',
  u_Biomes.JSON in 'common\u_Biomes.JSON.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Worlds';
  TStyleManager.TrySetStyle('Klondike');
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
