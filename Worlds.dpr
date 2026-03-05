program Worlds;

uses
  Vcl.Forms,
  Main in 'ui\Main.pas' {MainForm},
  Vcl.Themes,
  Vcl.Styles,
  u_EnvironmentTypes in 'common\u_EnvironmentTypes.pas',
  fr_WorldFrame in 'ui\fr_WorldFrame.pas' {WorldFrame: TFrame},
  fr_ContentFrames in 'ui\fr_ContentFrames.pas' {ContentFrame: TFrame},
  fr_FoodEditor in 'ui\fr_FoodEditor.pas' {FoodEditor: TFrame},
  u_ControlRendering in 'ui\u_ControlRendering.pas',
  fr_BiomeEditor in 'ui\fr_BiomeEditor.pas' {BiomeEditor: TFrame},
  u_EditorTypes in 'common\u_EditorTypes.pas',
  u_Foods in 'common\u_Foods.pas',
  u_Biomes in 'common\u_Biomes.pas',
  u_Regions in 'common\u_Regions.pas',
  u_EnvironmentLibraries in 'common\u_EnvironmentLibraries.pas',
  fr_RatingEditor in 'ui\fr_RatingEditor.pas' {RatingEditorFrame: TFrame},
  fr_RegionEditor in 'ui\fr_RegionEditor.pas' {RegionEditor: TFrame},
  u_MapEditors in 'ui\u_MapEditors.pas',
  u_Serialization in 'common\u_Serialization.pas',
  u_BiomeMaps in 'common\u_BiomeMaps.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Worlds';
  TStyleManager.TrySetStyle('Klondike');
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
