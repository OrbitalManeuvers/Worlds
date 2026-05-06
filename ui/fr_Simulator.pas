unit fr_Simulator;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.StdCtrls,
  System.Generics.Collections,
  VirtualTrees, VirtualTrees.DrawTree,

  u_SessionComposerIntf, u_SimSessions, u_SimDiagnosticsIntf,
  fr_SimController, u_EventSinkIntf, u_LogTreeViews, Vcl.Menus,
  u_SessionParameters;

type
  TStepViewerInstance = record
    Viewer: TLogViewer;
    Treeview: TVirtualDrawTree;
    ExportFileName: string;
  end;

  TSimulatorFrame = class(TContentFrame)
    btnClose: TButton;
    AgentTree: TVirtualDrawTree;
    StepViewPopup: TPopupMenu;
    mniExport: TMenuItem;
    LifetimeTree: TVirtualDrawTree;
    procedure btnCloseClick(Sender: TObject);
    procedure mniExportClick(Sender: TObject);
  private
    fSession: TSimSession;
    fEventLog: IEventLog;
    fControllerFrame: TControllerFrame;

    fStepViewers: TList<TStepViewerInstance>;


    procedure DestroySession;
    procedure HandleBeforeRun(Sender: TObject);
    procedure HandleAfterRun(Sender: TObject);

//    procedure CreateStepViewer(aTree: TVirtualDrawTree; aViewerClass: TLogViewerClass;
//      const aExportFileName: string);
  public
    procedure Init; override;
    procedure Done; override;
    procedure DeactivateContent; override;

    procedure CreateSession(const aComposer: ISessionComposer;
      const aCommonParams: TCommonSessionParameters);

    property Session: TSimSession read fSession;
  end;


implementation

{$R *.dfm}

uses u_WorldsMessages, u_LogExport, System.IOUtils;

{ TSimulatorFrame }

procedure TSimulatorFrame.Init;
begin
  inherited;
  //
  fStepViewers := TList<TStepViewerInstance>.Create;

  fControllerFrame := TControllerFrame.Create(Self);
  fControllerFrame.Parent := Self;
  fControllerFrame.Show;
  fControllerFrame.OnBeforeRun := HandleBeforeRun;
  fControllerFrame.OnAfterRun := HandleAfterRun;
end;

procedure TSimulatorFrame.mniExportClick(Sender: TObject);
begin
  inherited;

  var sourceTree := StepViewPopup.PopupComponent as TVirtualDrawTree;
  if not Assigned(sourceTree) then
    Exit;

  for var viewerInstance in fStepViewers do
    if viewerInstance.Treeview = sourceTree then
    begin
      var eventMap: TArray<Integer>;
      SetLength(eventMap, 0);
      viewerInstance.Viewer.GetSelectedEvents(eventMap);

      var fileName := TPath.Combine(ExtractFilePath(Application.ExeName), viewerInstance.ExportFileName);
      u_LogExport.ExportDecisionTraces(fEventLog, eventMap,
        fSession.Simulator.Runtime.Environment.Dimensions.cx,
        fileName);

      Break;
    end;
end;

procedure TSimulatorFrame.Done;
begin
  for var viewerInstance in fStepViewers do
    viewerInstance.Viewer.Free;
  fStepViewers.Free;
  fStepViewers := nil;

  fControllerFrame.Controller := nil;
  DestroySession;
  inherited;
end;

procedure TSimulatorFrame.HandleBeforeRun(Sender: TObject);
begin
  for var viewerInstance in fStepViewers do
    viewerInstance.Treeview.BeginUpdate;
end;

procedure TSimulatorFrame.HandleAfterRun(Sender: TObject);
begin
  if Assigned(fSession) then
    fSession.AssertScratchLogReadable;

  for var viewerInstance in fStepViewers do
    viewerInstance.Treeview.EndUpdate;
end;

procedure TSimulatorFrame.DestroySession;
begin
  if not Assigned(fSession) then
    Exit;

  fEventLog := nil;

  // clean up viewers tied to this session
  if Assigned(fStepViewers) then
  begin
    for var viewerInstance in fStepViewers do
      viewerInstance.Viewer.Free;
    fStepViewers.Clear;
  end;

  fSession.EndSession;
  fSession.Free;
  fSession := nil;
end;

procedure TSimulatorFrame.btnCloseClick(Sender: TObject);
begin
  inherited;
  PostMessage(Application.MainForm.Handle, WM_END_SIMULATION, 0, 0);
end;

procedure TSimulatorFrame.CreateSession(const aComposer: ISessionComposer;
  const aCommonParams: TCommonSessionParameters);
begin
  DestroySession;

  fSession := TSimSession.Create(aCommonParams);
  fEventLog := fSession.EventLog;
  try
    aComposer.Compose(fSession.Simulator.Runtime);
    fSession.BeginSession;
    fSession.AssertScratchLogReadable;
    fControllerFrame.Controller := fSession.Controller;
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
