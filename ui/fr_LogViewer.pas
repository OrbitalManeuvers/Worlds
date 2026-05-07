unit fr_LogViewer;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees, Vcl.ExtCtrls,

  u_SimEventTypes, u_DiagnosticsHelpers;

type
  TLogViewer = class(TFrame)
    Panel1: TPanel;
    Tree: TVirtualStringTree;
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure TreeInitNode(Sender: TBaseVirtualTree; ParentNode,
      Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
  private
    fEventLog: IEventLogView;
  public
    procedure Connect(const aLog: IEventLogView);
    procedure Refresh;
  end;

implementation

{$R *.dfm}

type
  TNodeData = record
    EventType: TSimEventKind; //
  end;

{ TLogViewer }
procedure TLogViewer.Connect(const aLog: IEventLogView);
begin
  fEventLog := aLog;
  if Assigned(fEventLog) then
    Tree.RootNodeCount := fEventLog.Count
  else
    Tree.RootNodeCount := 0;
end;

procedure TLogViewer.Refresh;
begin
  if not Assigned(fEventLog) then
    Exit;
  fEventLog.Extend;
  Tree.RootNodeCount := fEventLog.Count;
end;

procedure TLogViewer.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
begin
  if (Node = nil) or (fEventLog = nil) then
    Exit;

  if Node.Index >= Cardinal(fEventLog.Count) then
    Exit;

  var simEvent := fEventLog.Events[Node.Index];
  CellText := simEvent.AsDebugLine;
end;

procedure TLogViewer.TreeInitNode(Sender: TBaseVirtualTree; ParentNode,
  Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
begin
  InitialStates := [];

  if ParentNode = nil then
  begin
 //    nodeData.Kind        := nkResult;
  end

end;

end.
