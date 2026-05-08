unit fr_Simulator;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.StdCtrls,
  System.Generics.Collections, Vcl.Menus,
  VirtualTrees, VirtualTrees.DrawTree, Vcl.ExtCtrls,

  u_SessionComposerIntf, u_SimSessions, u_SimEventTypes, u_EventLogViews,
  fr_SimController, fr_LogViewer,
  u_SessionParameters, Vcl.ComCtrls;

type
  TSimulatorFrame = class(TContentFrame)
    btnClose: TButton;
    ViewPopup: TPopupMenu;
    mniExport: TMenuItem;
    phController: TShape;
    phLogViewer: TShape;
    btnSaveClose: TButton;
    SaveProgress: TProgressBar;
    procedure btnCloseClick(Sender: TObject);
    procedure mniExportClick(Sender: TObject);
  private
    Session: TSimSession;
    EventLog: IEventLog;
    EventLogView: IEventLogView;
    Controller: TControllerFrame;
    LogViewer: TLogViewer;

    procedure DestroySession;
    procedure HandleBeforeRun(Sender: TObject);
    procedure HandleAfterRun(Sender: TObject);

  public
    procedure Init; override;
    procedure Done; override;
    procedure DeactivateContent; override;

    { called externally }
    procedure CreateSession(const aComposer: ISessionComposer;
      const aCommonParams: TCommonSessionParameters);
  end;


implementation

{$R *.dfm}

uses u_WorldsMessages, {u_LogExport,} System.IOUtils;

{ TSimulatorFrame }

procedure TSimulatorFrame.Init;

  procedure InitFrame(aFrame: TFrame; aPlaceholder: TShape);
  begin
    aFrame.BoundsRect := aPlaceholder.BoundsRect;
    aFrame.Parent := aPlaceholder.Parent;
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


end;

procedure TSimulatorFrame.mniExportClick(Sender: TObject);
begin
  inherited;
  //
end;

procedure TSimulatorFrame.Done;
begin
  DestroySession;
  inherited;
end;

procedure TSimulatorFrame.HandleBeforeRun(Sender: TObject);
begin
  LogViewer.Tree.BeginUpdate;
end;

procedure TSimulatorFrame.HandleAfterRun(Sender: TObject);
begin
  if Assigned(Session) then
    Session.AssertScratchLogReadable;

  LogViewer.Refresh;
  LogViewer.Tree.EndUpdate;
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
end;

procedure TSimulatorFrame.btnCloseClick(Sender: TObject);
begin
  inherited;

  if (Sender is TComponent) and (TComponent(Sender).Tag <> 0) then
  begin
//    SaveProgress.pos
    // show progress bar
    // try
    //   Session.SaveLog(callback);
    // finally
    //   HideProgress Bar

  end;

  PostMessage(Application.MainForm.Handle, WM_END_SIMULATION, 0, 0);
end;

procedure TSimulatorFrame.CreateSession(const aComposer: ISessionComposer;
  const aCommonParams: TCommonSessionParameters);
begin
  DestroySession;

  Session := TSimSession.Create(aCommonParams);
  EventLog := Session.EventLog;
  EventLogView := TEventLogView.Create(EventLog);

  // view definition
  var def := Default(TSimEventViewDef);
  def.StartSequence := -1;
  def.StopSequence := -1;
  def.Kinds := [sekDecisionTrace];
  EventLogView.Define(def);

  //  EventLogView.Define(AnySimEventViewDef);


  LogViewer.Connect(EventLogView);
  try
    aComposer.Compose(Session.Simulator.Runtime);
    Session.BeginSession;
    Session.AssertScratchLogReadable;
    Controller.Controller := Session.Controller;
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
