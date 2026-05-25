unit fr_Simulator;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.StdCtrls,
  System.Generics.Collections, Vcl.Menus,
  Vcl.ExtCtrls, Vcl.ComCtrls,

  u_SessionComposerIntf, u_SimSessions, u_SimEventTypes, u_EventLogViews,
  fr_SimController, fr_LogViewer, fr_ResourceVisualizer, u_SimVisualizer,
  u_SessionParameters, Vcl.Grids, Vcl.ValEdit, Vcl.Buttons;

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
    phLogViewer: TShape;
    btnSaveClose: TButton;
    SaveProgress: TProgressBar;
    bvBottom: TBevel;
    phResViewer: TShape;
    phDeltaViewer: TShape;
    vlPopulationStats: TValueListEditor;
    btnCopySummary: TSpeedButton;
    procedure btnCloseClick(Sender: TObject);
    procedure btnCopySummaryClick(Sender: TObject);
  private
    Session: TSimSession;
    EventLog: IEventLog;
    EventLogView: IEventLogView;
    Controller: TControllerFrame;
    LogViewer: TLogViewer;
    ResViewer: TResViewFrame;
    DeltaViewer: TResViewFrame;
    Visualizer: TSubstanceVisualizer;
    DeltaVisualizer: TDeltaVisualizer;

    procedure DestroySession;
    procedure HandleBeforeRun(Sender: TObject);
    procedure HandleAfterRun(Sender: TObject);
    procedure HandleSaveProgress(Sender: TObject; Progress: Integer);
    procedure HandleResViewerPaint(Sender: TObject);
    procedure HandleDeltaViewerPaint(Sender: TObject);

    procedure UpdatePopulationSummary;
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

  { UI for displaying scratch log events }
  LogViewer := TLogViewer.Create(Self);
  InitFrame(LogViewer, phLogViewer);

  { UI for resource visualization }
  ResViewer := TResViewFrame.Create(Self);
  ResViewer.Name := 'rezViewer';
  ResViewer.OnPaint := HandleResViewerPaint;
  InitFrame(ResViewer, phResViewer);

  DeltaViewer := TResViewFrame.Create(Self);
  DeltaViewer.Name := 'deltaViewer';
  DeltaViewer.OnPaint := HandleDeltaViewerPaint;
  InitFrame(DeltaViewer, phDeltaViewer);

  { class to handle drawing resource visualizer frames }
  Visualizer := TSubstanceVisualizer.Create;
  DeltaVisualizer := TDeltaVisualizer.Create;
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

procedure TSimulatorFrame.HandleDeltaViewerPaint(Sender: TObject);
begin
 if Assigned(DeltaVisualizer) then
 begin
   var view := Sender as TResViewFrame;
   if Assigned(view) then
   begin
     DeltaVisualizer.ZoomLevel := TVisualizerZoom(view.ZoomFactor);
     DeltaVisualizer.AnchorCell := view.AnchorCell;
     DeltaVisualizer.Paint(view.Canvas, clWebOrange);
   end;
 end;
end;

procedure TSimulatorFrame.HandleResViewerPaint(Sender: TObject);
begin
  if Assigned(Visualizer) then
  begin
    var view := Sender as TResViewFrame;
    if Assigned(view) then
    begin
      Visualizer.ZoomLevel := TVisualizerZoom(view.ZoomFactor);
      Visualizer.SubstanceIndex := view.SubstanceIndex;
      Visualizer.AnchorCell := view.AnchorCell;
      Visualizer.Paint(view.Canvas, clWebYellow);
    end;
  end;
end;

procedure TSimulatorFrame.HandleSaveProgress(Sender: TObject; Progress: Integer);
begin
  SaveProgress.Position := Progress + 1; // accommodate for 0-based event index
end;

procedure TSimulatorFrame.HandleAfterRun(Sender: TObject);
begin
  if Assigned(Session) then
    Session.AssertScratchLogReadable;
  LogViewer.Refresh;

  if Assigned(ResViewer) then
    ResViewer.Invalidate;
  if Assigned(DeltaViewer) then
    DeltaViewer.Invalidate;

  // population summary
  UpdatePopulationSummary;
end;

procedure TSimulatorFrame.UpdatePopulationSummary;
begin
  var summary := Session.Simulator.Runtime.Population.Summarize;
  var logFields := summary.AsFields;

  var lines := TStringList.Create(dupIgnore, False, False);
  try
    logFields.GetPairs(lines);
    vlPopulationStats.Strings.Assign(lines);
  finally
    lines.Free;
  end;
end;

procedure TSimulatorFrame.DestroySession;
begin
  if not Assigned(Session) then
    Exit;

  Controller.Controller := nil;

  LogViewer.Connect(nil);
  EventLogView := nil;
  EventLog := nil;

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

    SaveProgress.Max := EventLog.Count;
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
  Clipboard.AsText := vlPopulationStats.Strings.Text;
end;

procedure TSimulatorFrame.CreateSession(const aComposer: ISessionComposer;
  const aCommonParams: TCommonSessionParameters);
begin
  DestroySession;

  Session := TSimSession.Create(aCommonParams);
  EventLog := Session.EventLog;
  EventLogView := TEventLogView.Create(EventLog);

  LogViewer.Connect(EventLogView);
  try
    aComposer.Compose(Session.Simulator.Runtime);
    Session.BeginSession;
    Session.AssertScratchLogReadable;
    Controller.Controller := Session.Controller;


    Visualizer.Simulator := Session.Simulator;
    DeltaVisualizer.Simulator := Session.Simulator;

    var env := Session.Simulator.Runtime.Environment;
    var names: TArray<string>;
    SetLength(names, Length(env.SubstanceEntries));
    for var i := 0 to High(env.SubstanceEntries) do
      names[i] := env.SubstanceEntries[i].Name;
    ResViewer.ApplySubstanceNames(names);

  except
    DestroySession;
    raise;
  end;
end;

procedure TSimulatorFrame.DeactivateContent;
begin
  inherited;
  DestroySession;
end;



end.
