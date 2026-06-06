unit fr_Simulator;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.StdCtrls,
  System.Generics.Collections, Vcl.Menus,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Grids, Vcl.ValEdit, Vcl.Buttons,

  u_SessionComposerIntf, u_SimSessions, u_SimEventTypes, u_EventLogViews,
  fr_StepControls, fr_LogViewer, fr_ResourceVisualizer, u_SimVisualizer,
  u_AgentGenome, u_AgentTypes, u_SimPopulations,
  fr_PopulationViewer, fr_PopulationSummary,
  u_SessionParameters, fr_AgentWatches, fr_Exploration;

(*

To-do:

  - This content frame is presented modally. Creation/teardown desperately needs review here.

*)

type
  TSimulatorFrame = class(TContentFrame)
    btnClose: TButton;
    ViewPopup: TPopupMenu;
    mniExport: TMenuItem;
    phStepper: TShape;
    phAgentWatches: TShape;
    btnSaveClose: TButton;
    SaveProgress: TProgressBar;
    bvBottom: TBevel;
    phResViewer1: TShape;
    phResViewer2: TShape;
    btnCopySummary: TSpeedButton;
    phPopulationViewer: TShape;
    phPopulationSummary: TShape;
    phExplorer: TShape;
    procedure btnCloseClick(Sender: TObject);
    procedure btnCopySummaryClick(Sender: TObject);
  private
    LaunchRequest: TSimLaunchRequest;
    Session: TSimSession;
    Stepper: TStepperFrame;
    Explorer: TExplorationFrame;

    ResViewer1: TResViewFrame;
    ResViewer2: TResViewFrame;
    Visualizer: TSubstanceVisualizer;
    DeltaVisualizer: TDeltaVisualizer;
    PopulationViewer: TPopulationViewFrame;
    PopulationSummary: TPopulationSummaryFrame;
    AgentWatches: TAgentWatchFrame;

    // session lifetime
    procedure CreateSession;
    procedure DestroySession;

    function BuildComposer: ISessionComposer;
    procedure ConnectViewers;
    procedure DisconnectViewers;

    procedure HandleBeforeRun(Sender: TObject);
    procedure HandleAfterRun(Sender: TObject);
    procedure HandleSaveProgress(Sender: TObject; Progress: Integer);
    procedure HandleResViewerPaint(Sender: TObject);
    procedure HandleScratchChange(Sender: TObject);
    procedure HandleReset(Sender: TObject);
  public
    procedure Init; override;
    procedure Done; override;

    { called externally }
    procedure StartFromLaunchRequest(const aRequest: TSimLaunchRequest);
  end;


implementation

{$R *.dfm}

uses System.IOUtils, Vcl.Graphics, Vcl.Themes, Vcl.Clipbrd,
  u_WorldsMessages, u_SessionManager, u_LogTypes, u_DiagnosticsHelpers,
  u_SessionComposers,
  u_DebugSessionComposers;

{ TSimulatorFrame }

procedure TSimulatorFrame.Init;

  procedure InitFrame(aFrame: TFrame; aPlaceholder: TShape);
  begin
    aFrame.Visible := False;
    aFrame.BoundsRect := aPlaceholder.BoundsRect;
    aFrame.Parent := aPlaceholder.Parent;
    aFrame.Anchors := aPlaceholder.Anchors;
    aPlaceholder.Hide;
    aFrame.Show;
  end;

begin
  inherited;

  { UI for controlling the session }
  Stepper := TStepperFrame.Create(Self);
  InitFrame(Stepper, phStepper);
  Stepper.OnBeforeRun := HandleBeforeRun;
  Stepper.OnAfterRun := HandleAfterRun;
  Stepper.OnScratchChange := HandleScratchChange;
  Stepper.OnReset := HandleReset;

  Explorer := TExplorationFrame.Create(Self);
  InitFrame(Explorer, phExplorer);
  // to-do


  { population summary }
  PopulationSummary := TPopulationSummaryFrame.Create(Self);
  PopulationSummary.Name := 'popSummary';
  InitFrame(PopulationSummary, phPopulationSummary);

  { UI for resource visualization }
  ResViewer1 := TResViewFrame.Create(Self);
  ResViewer1.Name := 'resViewer1';
  ResViewer1.OnPaint := HandleResViewerPaint;
  InitFrame(ResViewer1, phResViewer1);

  ResViewer2 := TResViewFrame.Create(Self);
  ResViewer2.Name := 'resViewer2';
  ResViewer2.OnPaint := HandleResViewerPaint;
  InitFrame(ResViewer2, phResViewer2);

  { Population Viewer }
  PopulationViewer := TPopulationViewFrame.Create(Self);
  PopulationViewer.Name := 'popViewer';
  InitFrame(PopulationViewer, phPopulationViewer);

  { agent watches }
  AgentWatches := TAgentWatchFrame.Create(Self);
  AgentWatches.Name := 'agentWatches';
  InitFrame(AgentWatches, phAgentWatches);

  { class to handle drawing resource visualizer frames }
  Visualizer := TSubstanceVisualizer.Create;
  DeltaVisualizer := TDeltaVisualizer.Create;

end;

procedure TSimulatorFrame.Done;
begin
  DestroySession;

  Visualizer.Free;
  DeltaVisualizer.Free;

  inherited;
end;

procedure TSimulatorFrame.StartFromLaunchRequest(const aRequest: TSimLaunchRequest);
begin
  LaunchRequest := aRequest;
  CreateSession;
end;

procedure TSimulatorFrame.CreateSession;
begin
  DestroySession;

  Session := TSimSession.Create(LaunchRequest.CommonParams);

  var composer: ISessionComposer := BuildComposer;
  composer.Compose(Session.Simulator.Runtime);

  Session.BeginSession;
  Session.AssertScratchLogReadable;
  Stepper.Controller := Session.Controller;
  Stepper.ScratchEnabled := Session.ScratchLogEnabled;

  // to-do
//  Explorer.Controller := Session.Controller;


  ConnectViewers;
end;

procedure TSimulatorFrame.ConnectViewers;
begin
  Visualizer.Simulator := Session.Simulator;
  DeltaVisualizer.Simulator := Session.Simulator;

  var env := Session.Simulator.Runtime.Environment;
  var names: TArray<string>;

  // over-allocate whatever is needed by 1 to add Delta
  SetLength(names, Length(env.SubstanceEntries) + 1);

  // fill in regular resources
  for var i := 0 to High(env.SubstanceEntries) do
    names[i] := env.SubstanceEntries[i].Name;

  // add delta unconditionally as the last item
  names[Length(names) - 1] := 'Delta';
  ResViewer1.ApplySubstanceNames(names);
  ResViewer2.ApplySubstanceNames(names);

  if Assigned(PopulationSummary) then
  begin
    PopulationSummary.SubscriptionId := Session.Diagnostics.Subscribe(PopulationSummary);
  end;

  if Assigned(PopulationViewer) then
  begin
    PopulationViewer.SubscriptionId := Session.Diagnostics.Subscribe(PopulationViewer);
    PopulationViewer.Connect(Session.Simulator.Runtime.Population);
  end;

  if Assigned(AgentWatches) then
  begin
    AgentWatches.SubscriptionId := Session.Diagnostics.Subscribe(AgentWatches);
    AgentWatches.Connect(Session.Simulator.Runtime.Population);
  end;
end;

procedure TSimulatorFrame.DisconnectViewers;
begin
  DeltaVisualizer.Simulator := nil;
  Visualizer.Simulator := nil;
  ResViewer1.InvalidateView;
  ResViewer2.InvalidateView;

  if PopulationSummary.SubscriptionId <> 0 then
    Session.Diagnostics.Unsubscribe(PopulationSummary.SubscriptionId);
  PopulationSummary.SubscriptionId := 0;

  if PopulationViewer.SubscriptionId <> 0 then
    Session.Diagnostics.Unsubscribe(PopulationViewer.SubscriptionId);
  PopulationViewer.SubscriptionId := 0;
  PopulationViewer.Connect(nil);

  if AgentWatches.SubscriptionId <> 0 then
    Session.Diagnostics.Unsubscribe(AgentWatches.SubscriptionId);
  AgentWatches.SubscriptionId := 0;
  AgentWatches.Connect(nil);
end;

procedure TSimulatorFrame.DestroySession;
begin
  if not Assigned(Session) then
    Exit;
  Stepper.Controller := nil;
  DisconnectViewers;

  Session.EndSession;
  Session.Free;
  Session := nil;
end;

function TSimulatorFrame.BuildComposer: ISessionComposer;
begin
  case LaunchRequest.SessionType of
    stStandard:
      result := TSessionComposer.Create(LaunchRequest.StandardParams);
    stDebug:
      result := TDebugSessionComposer.Create(LaunchRequest.DebugParams.ScenarioName);
  end;
end;

procedure TSimulatorFrame.HandleBeforeRun(Sender: TObject);
begin
  Session.Recording := Stepper.Recording;
end;

procedure TSimulatorFrame.HandleReset(Sender: TObject);
begin
  CreateSession;
end;

procedure TSimulatorFrame.HandleResViewerPaint(Sender: TObject);
const
  substance_colors: array[0..3] of TColor = (clWebOrange, clWebGreen, clWebBrown, clWebPurple);
begin
  if Assigned(Visualizer) and Assigned(DeltaVisualizer) then
  begin
    var view := Sender as TResViewFrame;
    if Assigned(view) then
    begin
      // if the view's substance index is beyond the regular resource list, show delta
      var resourceCount := Length(Self.Session.Simulator.Runtime.Environment.SubstanceEntries);

      if view.SubstanceIndex < resourceCount then
      begin
        Visualizer.ZoomLevel := TVisualizerZoom(view.ZoomFactor);
        Visualizer.SubstanceIndex := view.SubstanceIndex;
        Visualizer.AnchorCell := view.AnchorCell;
        var colorIndex := view.SubstanceIndex mod Length(substance_colors);
        Visualizer.Paint(view.Canvas, substance_colors[colorIndex]);
      end
      else
      begin
        DeltaVisualizer.ZoomLevel := TVisualizerZoom(view.ZoomFactor);
        DeltaVisualizer.AnchorCell := view.AnchorCell;
        DeltaVisualizer.Paint(view.Canvas, clWebRoyalBlue);
      end;
    end;
  end;
end;

procedure TSimulatorFrame.HandleSaveProgress(Sender: TObject; Progress: Integer);
begin
  SaveProgress.Position := Progress + 1; // accommodate for 0-based event index
end;

procedure TSimulatorFrame.HandleScratchChange(Sender: TObject);
begin
  Session.ScratchLogEnabled := Stepper.ScratchEnabled;
end;

procedure TSimulatorFrame.HandleAfterRun(Sender: TObject);
begin
  if Assigned(Session) then
    Session.AssertScratchLogReadable;

  if Assigned(PopulationViewer) then
    PopulationViewer.Step;

  // agent watches
  if Assigned(AgentWatches) then
    AgentWatches.Step;

  if Assigned(ResViewer1) then
    ResViewer1.Invalidate;
  if Assigned(ResViewer2) then
    ResViewer2.Invalidate;
end;


procedure TSimulatorFrame.btnCloseClick(Sender: TObject);
begin
  inherited;

  Assert(Assigned(Session));

  // non-zero Tag on closing control signals Save
  var savedRecording := (Sender is TComponent) and (TComponent(Sender).Tag <> 0);
  var savedEventCount := 0;

  if savedRecording then
  begin
    Session.AssertScratchLogReadable;

    SaveProgress.Max := Session.EventLog.Count;
    SaveProgress.Min := 0;
    SaveProgress.Position := 0;
    SaveProgress.Visible := True;
    try
      savedEventCount := Session.SaveEventLog(HandleSaveProgress);
    finally
      SaveProgress.Visible := False;
    end;
  end;

  if savedRecording then
    SessionManager.UpdateSessionStatus(ssCompleted, True, savedEventCount, 'Save and close')
  else
    SessionManager.UpdateSessionStatus(ssCompleted, False, 0, 'Discard and close');

  PostMessage(Application.MainForm.Handle, WM_END_SIMULATION, 0, 0);
end;

procedure TSimulatorFrame.btnCopySummaryClick(Sender: TObject);
begin
  inherited;
//  Clipboard.AsText := vlPopulationStats.Strings.Text;
end;





end.
