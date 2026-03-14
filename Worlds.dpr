program Worlds;

uses
  Vcl.Forms,
  Main in 'ui\Main.pas' {MainForm},
  Vcl.Themes,
  Vcl.Styles,
  u_EnvironmentTypes in 'common\u_EnvironmentTypes.pas',
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
  u_BiomeMaps in 'common\u_BiomeMaps.pas',
  u_Simulators in 'sim\u_Simulators.pas',
  u_SimParams in 'sim\u_SimParams.pas',
  u_SimControllers in 'sim\u_SimControllers.pas',
  u_SimClocks in 'sim\u_SimClocks.pas',
  u_SimRuntimes in 'sim\u_SimRuntimes.pas',
  u_SimUpscalers in 'sim\u_SimUpscalers.pas',
  u_SimEnvironments in 'sim\u_SimEnvironments.pas',
  u_SimPopulations in 'sim\u_SimPopulations.pas',
  fr_SimFrame in 'ui\fr_SimFrame.pas' {SimFrame: TFrame},
  u_CellVisualizers in 'ui\u_CellVisualizers.pas',
  u_SimLoggers in 'sim\u_SimLoggers.pas',
  u_SimVisualizer in 'ui\u_SimVisualizer.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Worlds';
  TStyleManager.TrySetStyle('Klondike');
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
