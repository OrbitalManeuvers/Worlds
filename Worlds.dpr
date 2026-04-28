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
  u_SimVisualizer in 'ui\u_SimVisualizer.pas',
  fr_BiologyEditor in 'ui\fr_BiologyEditor.pas' {BiologyEditor: TFrame},
  u_AgentTypes in 'agents\u_AgentTypes.pas',
  u_BiologyTypes in 'common\u_BiologyTypes.pas',
  u_AgentGenome in 'agents\u_AgentGenome.pas',
  u_SightGenes in 'agents\u_SightGenes.pas',
  u_SimQueriesIntf in 'sim\u_SimQueriesIntf.pas',
  u_SmellGenes in 'agents\u_SmellGenes.pas',
  u_AgentState in 'agents\u_AgentState.pas',
  u_SimQueriesImpl in 'sim\u_SimQueriesImpl.pas',
  u_ForagingGenes in 'agents\u_ForagingGenes.pas',
  u_AgentBrain in 'agents\u_AgentBrain.pas',
  fr_WorldEditor in 'ui\fr_WorldEditor.pas' {WorldEditor: TFrame},
  u_Worlds in 'common\u_Worlds.pas',
  u_GraphicButtonBars in 'ui\u_GraphicButtonBars.pas',
  u_WorldLayouts in 'common\u_WorldLayouts.pas',
  u_SimSessions in 'sim\u_SimSessions.pas',
  u_SimWatches in 'sim\u_SimWatches.pas',
  fr_ResourceVisualizer in 'ui\fr_ResourceVisualizer.pas' {ResVisFrame: TFrame},
  u_SimPopulators in 'sim\u_SimPopulators.pas',
  u_EnergyGenes in 'agents\u_EnergyGenes.pas',
  u_CognitionGenes in 'agents\u_CognitionGenes.pas',
  u_SimCommandsIntf in 'sim\u_SimCommandsIntf.pas',
  u_SimCommandsImpl in 'sim\u_SimCommandsImpl.pas',
  u_Seeds in 'common\u_Seeds.pas',
  u_ShelterGenes in 'agents\u_ShelterGenes.pas',
  u_SimPhases in 'sim\u_SimPhases.pas',
  u_MovementGenes in 'agents\u_MovementGenes.pas',
  u_ConverterGenes in 'agents\u_ConverterGenes.pas',
  u_SimDiagnosticsIntf in 'sim\u_SimDiagnosticsIntf.pas',
  u_SimDiagnostics in 'sim\u_SimDiagnostics.pas',
  u_DiagnosticListeners in 'sim\u_DiagnosticListeners.pas',
  u_ReproduceGenes in 'agents\u_ReproduceGenes.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Worlds';
  TStyleManager.TrySetStyle('Klondike');
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
