unit fr_LogViewer;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees, Vcl.ExtCtrls,
  VirtualTrees.Export,

  u_SimEventTypes, u_DiagnosticsHelpers, Vcl.Buttons, Vcl.Grids, Vcl.ValEdit;

type
  TLogViewer = class(TFrame)
    pnlViewTools: TPanel;
    Tree: TVirtualStringTree;
    btnIncDT: TSpeedButton;
    vlDetails: TValueListEditor;
    btnExport: TSpeedButton;
    btnIncAR: TSpeedButton;
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure TreeInitNode(Sender: TBaseVirtualTree; ParentNode,
      Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
    procedure FilterChanged(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure TreeSelectionChanged(Sender: TBaseVirtualTree;
      Node: PVirtualNode);
  private
    ViewDef: TSimEventViewDef;
    EventView: IEventLogView;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Connect(const aLogEventView: IEventLogView);
    procedure Refresh;
  end;

implementation

uses System.IOUtils;

{$R *.dfm}


//   not currently using per-node storage as node.index = view.events[index]
//type
//  TNodeData = record
//    EventType: TSimEventKind; //
//    Conflict: string;
//  end;

{ TLogViewer }

constructor TLogViewer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ViewDef := Default(TSimEventViewDef);
  ViewDef.StartSequence := -1;
  ViewDef.StopSequence := -1;

  // toggle buttons
  btnIncDT.Tag := Ord(sekDecisionTrace);
  btnIncAR.Tag := Ord(sekActionResolved);
end;


destructor TLogViewer.Destroy;
begin

  inherited;
end;

procedure TLogViewer.btnExportClick(Sender: TObject);
begin
  var exportText := ContentToUnicodeString(Tree, tstSelected, '');
  var exportPath := TPath.Combine(ExtractFilePath(Application.ExeName), 'log_export.txt');
  TFile.WriteAllText(exportPath, exportText, TEncoding.UTF8);
end;

procedure TLogViewer.Connect(const aLogEventView: IEventLogView);
begin
  EventView := aLogEventView;

  if Assigned(EventView) then
  begin
    Tree.RootNodeCount := EventView.Count;
  end
  else
    Tree.RootNodeCount := 0;
end;

procedure TLogViewer.FilterChanged(Sender: TObject);
begin
  // transfer UI state into the working view definition
  // if a change warrants, call Refresh
  if Sender is TSpeedbutton then
  begin
    var btn := TSpeedbutton(Sender);
    var name: string := btn.Name;
    if name.StartsWith('btnInc') then
    begin
      var kind := TSimEventKind(btn.Tag);
      if btn.Down then
        Include(ViewDef.Kinds, kind)
      else
        Exclude(ViewDef.Kinds, kind);
    end;

  end;

  EventView.Define(ViewDef);
  Refresh;
end;

procedure TLogViewer.Refresh;
begin
  if not Assigned(EventView) then
    Exit;
  EventView.Extend;
  Tree.RootNodeCount := EventView.Count;
end;

procedure TLogViewer.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
begin
  if (Node = nil) or (EventView = nil) then
    Exit;

  if Node.Index >= Cardinal(EventView.Count) then
    Exit;

  var simEvent := EventView.Events[Node.Index];
  CellText := simEvent.AsLogLine;
end;

procedure TLogViewer.TreeInitNode(Sender: TBaseVirtualTree; ParentNode,
  Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
begin
  InitialStates := [ivsHasChildren];

  if ParentNode = nil then
  begin
 //    nodeData.Kind        := nkResult;
  end

end;

procedure TLogViewer.TreeSelectionChanged(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  if Tree.SelectedCount = 1 then
  begin
    var sel := Tree.GetFirstSelected();
    if Assigned(sel) then
    begin
      var event := EventView.Events[sel.Index];
      var s := event.AsDetails;
      vlDetails.Strings.Delimiter := '|';
      vlDetails.Strings.DelimitedText := s;
    end;
  end
  else
  begin
    vlDetails.Strings.Clear;
  end;


end;

end.
