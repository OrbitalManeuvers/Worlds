unit fr_Simulator;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.StdCtrls,
  System.Generics.Collections, Vcl.Menus,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Grids, Vcl.ValEdit, Vcl.Buttons,

  u_SessionComposerIntf, u_SimSessions, u_SimEventTypes, u_EventLogViews,
  fr_SimController, fr_LogViewer, fr_ResourceVisualizer, u_SimVisualizer,
  u_AgentGenome, u_AgentTypes, u_SimPopulations,
  fr_PopulationViewer, fr_PopulationSummary,
  u_SessionParameters, fr_AgentWatches;

(*

To-do:

  - This content frame is presented modally. Creation/teardown desperately needs review here.

*)

type
  TSimulatorFrame = class(TContentFrame)
    btnClose: TButton;
    ViewPopup: TPopupMenu;
    mniExport: TMenuItem;
    phController: TShape;
    phAgentWatches: TShape;
    btnSaveClose: TButton;
    SaveProgress: TProgressBar;
    bvBottom: TBevel;
    phResViewer1: TShape;
    phResViewer2: TShape;
    btnCopySummary: TSpeedButton;
    phPopulationViewer: TShape;
    phPopulationSummary: TShape;
    procedure btnCloseClick(Sender: TObject);
    procedure btnCopySummaryClick(Sender: TObject);
  private
    Session: TSimSession;
    Controller: TControllerFrame;

    ResViewer1: TResViewFrame;
    ResViewer2: TResViewFrame;
    Visualizer: TSubstanceVisualizer;
    DeltaVisualizer: TDeltaVisualizer;
    PopulationViewer: TPopulationViewFrame;
    PopulationSummary: TPopulationSummaryFrame;
    AgentWatches: TAgentWatchFrame;

    procedure DestroySession;
    procedure HandleBeforeRun(Sender: TObject);
    procedure HandleAfterRun(Sender: TObject);
    procedure HandleSaveProgress(Sender: TObject; Progress: Integer);
    procedure HandleResViewerPaint(Sender: TObject);
    procedure HandleScratchChange(Sender: TObject);
  public
    procedure Init; override;
    procedure Done; override;
    procedure DeactivateContent; override;    // eliminate, this is doubling up

    { called externally }
    procedure CreateSession(const aComposer: ISessionComposer;
      const aCommonParams: TCommonSessionParameters);
  end;


implementation

{$R *.dfm}

uses System.IOUtils, Vcl.Graphics, Vcl.Themes, Vcl.Clipbrd,
  u_WorldsMessages, u_SessionManager, u_LogTypes, u_DiagnosticsHelpers;

{ TSimulatorFrame }

procedure TSimulatorFrame.Init;

  procedure InitFrame(aFrame: TFrame; aPlaceholder: TShape);
  begin
    aFrame.BoundsRect := aPlaceholder.BoundsRect;
    aFrame.Parent := aPlaceholder.Parent;
    aFrame.Anchors := aPlaceholder.Anchors;
    aPlaceholder.Hide;
    aFrame.Show;
  end;

begin
  inherited;

  { UI for controlling the session }
  Controller := TControllerFrame.Create(Self);
  InitFrame(Controller, phController);
  Controller.OnBeforeRun := HandleBeforeRun;
  Controller.OnAfterRun := HandleAfterRun;
  Controller.OnScratchChange := HandleScratchChange;

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


  { class to handle drawing resource visualizer frames }
  Visualizer := TSubstanceVisualizer.Create;
  DeltaVisualizer := TDeltaVisualizer.Create;

  { Population Viewer }
  PopulationViewer := TPopulationViewFrame.Create(Self);
  PopulationViewer.Name := 'popViewer';
  InitFrame(PopulationViewer, phPopulationViewer);

  { agent watches }
  AgentWatches := TAgentWatchFrame.Create(Self);
  AgentWatches.Name := 'agentWatches';
  InitFrame(AgentWatches, phAgentWatches);

end;

procedure TSimulatorFrame.Done;
begin
  DestroySession;
  inherited;
end;

procedure TSimulatorFrame.HandleBeforeRun(Sender: TObject);
begin
  Session.Recording := Controller.Recording;
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
  Session.ScratchLogEnabled := Controller.ScratchEnabled;
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



procedure TSimulatorFrame.DestroySession;
begin
  if not Assigned(Session) then
    Exit;
  Controller.Controller := nil;

  Session.EndSession;
  Session.Free;
  Session := nil;

  Visualizer.Free;
  DeltaVisualizer.Free;
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

procedure TSimulatorFrame.CreateSession(const aComposer: ISessionComposer;
  const aCommonParams: TCommonSessionParameters);
begin
  DestroySession;

  Session := TSimSession.Create(aCommonParams);
//  EventLog := Session.EventLog;
//  EventLogView := TEventLogView.Create(EventLog);

//  LogViewer.Connect(EventLogView);
//  try

  aComposer.Compose(Session.Simulator.Runtime);
  Session.BeginSession;
  Session.AssertScratchLogReadable;
  Controller.Controller := Session.Controller;
  Controller.ScratchEnabled := Session.ScratchLogEnabled;

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
    Session.Diagnostics.Subscribe(PopulationSummary);
  end;

  if Assigned(PopulationViewer) then
  begin
    PopulationViewer.Connect(Session.Simulator.Runtime.Population);
    Session.Diagnostics.Subscribe(PopulationViewer);
  end;

  if Assigned(AgentWatches) then
  begin
    Session.Diagnostics.Subscribe(AgentWatches);
    AgentWatches.Connect(Session.Simulator.Runtime.Population);

  end;

end;

procedure TSimulatorFrame.DeactivateContent;
begin
  inherited;
  DestroySession;
end;



end.
