unit u_LogTreeViews;

interface

uses System.Generics.Collections, VirtualTrees, VirtualTrees.DrawTree,

  u_EventSinkIntf, u_SimDiagnosticsIntf;

type
  // Base class: owns the tree wiring, EventMap, and selection export.
  // Subclasses implement AcceptsEvent, NodeDataSize, and the three tree callbacks.
  TLogViewer = class
  private
    FTree: TVirtualDrawTree;
    FEventLog: IEventLog;
    FEventMap: TList<Integer>; // log indexes accepted by this viewer
    FGridWidth: Integer;

    procedure MeasureItem(Sender: TBaseVirtualTree;
      TargetCanvas: TCanvas; Node: PVirtualNode; var NodeHeight: Integer);
  protected
    property Tree: TVirtualDrawTree read FTree;
    property EventLog: IEventLog read FEventLog;
    property EventMap: TList<Integer> read FEventMap;
    property GridWidth: Integer read FGridWidth;

    function AcceptsEvent(const aEvent: TSimEvent): Boolean; virtual; abstract;
    function GetNodeDataSize: Integer; virtual; abstract;

    procedure DoInitNode(ParentNode, Node: PVirtualNode;
      var InitialStates: TVirtualNodeInitStates); virtual; abstract;
    procedure DoInitChildren(Node: PVirtualNode;
      var ChildCount: Cardinal); virtual; abstract;
    procedure DoDrawNode(const PaintInfo: TVTPaintInfo); virtual; abstract;

    procedure ApplyCanvasDefaults(const PaintInfo: TVTPaintInfo);
  public
    constructor Create(aTree: TVirtualDrawTree; const aEventLog: IEventLog;
      aGridWidth: Integer);
    destructor Destroy; override;

    procedure AddEvent(const aEvent: TSimEvent);
    procedure GetSelectedEvents(out aIndexes: TArray<Integer>);
  end;

  TLogViewerClass = class of TLogViewer;

  // Decision trace viewer: one root node per tick, children for evals and conflicts.
  TDecisionTraceViewer = class(TLogViewer)
  private
    FTargetId: Integer;

    procedure InitNode(Sender: TBaseVirtualTree; ParentNode,
      Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
    procedure InitChildren(Sender: TBaseVirtualTree; Node: PVirtualNode;
      var ChildCount: Cardinal);
    procedure DrawNode(Sender: TBaseVirtualTree;
      const PaintInfo: TVTPaintInfo);
  protected
    function AcceptsEvent(const aEvent: TSimEvent): Boolean; override;
    function GetNodeDataSize: Integer; override;

    procedure DoInitNode(ParentNode, Node: PVirtualNode;
      var InitialStates: TVirtualNodeInitStates); override;
    procedure DoInitChildren(Node: PVirtualNode;
      var ChildCount: Cardinal); override;
    procedure DoDrawNode(const PaintInfo: TVTPaintInfo); override;
  public
    constructor Create(aTree: TVirtualDrawTree; const aEventLog: IEventLog;
      aGridWidth: Integer);

    property TargetId: Integer read FTargetId write FTargetId;
  end;


implementation

uses System.SysUtils, Vcl.Graphics,
  u_AgentTypes, u_AgentGenome, u_LogFormatting;

type
  TNodeKind = (nkResult, nkEvaluations, nkConflict);

  TNodeData = record
    Kind: TNodeKind;

    // nkResult
    ResolvedAction: TAgentAction;
    RequestedAction: TAgentAction;   // also drives whether nkConflict child exists
    CellIndex: Integer;              // agent's current cell (for X,Y from GridWidth)
    TargetCell: Integer;             // only meaningful for acMove; -1 otherwise
    EnergyLevel: TEnergyLevel;

    // nkEvaluations
    Evaluations: TActionEvaluations; // array[TAgentAction] of TActionEvalResult
    WinningAction: TAgentAction;     // which score to highlight
  end;


{ TLogViewer }

constructor TLogViewer.Create(aTree: TVirtualDrawTree; const aEventLog: IEventLog;
  aGridWidth: Integer);
begin
  inherited Create;
  FTree := aTree;
  FEventLog := aEventLog;
  FGridWidth := aGridWidth;
  FEventMap := TList<Integer>.Create;

  FTree.RootNodeCount := 0;
  FTree.NodeDataSize := GetNodeDataSize;
  FTree.Font.Size := 10;

  FTree.OnMeasureItem := MeasureItem;
end;

destructor TLogViewer.Destroy;
begin
  FEventMap.Free;
  inherited;
end;

procedure TLogViewer.AddEvent(const aEvent: TSimEvent);
begin
  if AcceptsEvent(aEvent) then
  begin
    FEventMap.Add(FEventLog.Count - 1);
    FTree.RootNodeCount := FEventMap.Count;
  end;
end;

procedure TLogViewer.GetSelectedEvents(out aIndexes: TArray<Integer>);
begin
  SetLength(aIndexes, FTree.SelectedCount);
  var i := 0;
  for var node in FTree.SelectedNodes(False) do
  begin
    // Node.Index is the root-level position; map it to the log index via EventMap
    aIndexes[i] := FEventMap[node.Index];
    Inc(i);
  end;
end;

procedure TLogViewer.ApplyCanvasDefaults(const PaintInfo: TVTPaintInfo);
begin
  PaintInfo.Canvas.Font.Assign(FTree.Font);

  if vsSelected in PaintInfo.Node.States then
  begin
    if FTree.Focused then
      PaintInfo.Canvas.Font.Color := FTree.Colors.GetSelectedNodeFontColor(FTree.Focused)
    else
      PaintInfo.Canvas.Font.Color := FTree.Colors.NodeFontColor;

    if FTree.Focused then
      PaintInfo.Canvas.Brush.Color := FTree.Colors.FocusedSelectionColor
    else
      PaintInfo.Canvas.Brush.Color := FTree.Colors.UnfocusedSelectionColor;
  end
  else
  begin
    PaintInfo.Canvas.Font.Color := FTree.Colors.NodeFontColor;
    PaintInfo.Canvas.Brush.Color := FTree.Colors.BackGroundColor;
  end;

  PaintInfo.Canvas.Brush.Style := bsSolid;
  PaintInfo.Canvas.FillRect(PaintInfo.ContentRect);
end;

procedure TLogViewer.MeasureItem(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; var NodeHeight: Integer);
begin
  NodeHeight := 28;
end;


{ TDecisionTraceViewer }

constructor TDecisionTraceViewer.Create(aTree: TVirtualDrawTree;
  const aEventLog: IEventLog; aGridWidth: Integer);
begin
  inherited Create(aTree, aEventLog, aGridWidth);
  FTargetId := 1; // needs thought, later

  aTree.OnInitNode     := InitNode;
  aTree.OnInitChildren := InitChildren;
  aTree.OnDrawNode     := DrawNode;
end;

function TDecisionTraceViewer.AcceptsEvent(const aEvent: TSimEvent): Boolean;
begin
  Result := (aEvent.Header.Kind = sekDecisionTrace) and
            (aEvent.DecisionTrace.AgentId = FTargetId);
end;

function TDecisionTraceViewer.GetNodeDataSize: Integer;
begin
  Result := SizeOf(TNodeData);
end;

procedure TDecisionTraceViewer.InitNode(Sender: TBaseVirtualTree; ParentNode,
  Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
begin
  DoInitNode(ParentNode, Node, InitialStates);
end;

procedure TDecisionTraceViewer.InitChildren(Sender: TBaseVirtualTree;
  Node: PVirtualNode; var ChildCount: Cardinal);
begin
  DoInitChildren(Node, ChildCount);
end;

procedure TDecisionTraceViewer.DrawNode(Sender: TBaseVirtualTree;
  const PaintInfo: TVTPaintInfo);
begin
  DoDrawNode(PaintInfo);
end;

procedure TDecisionTraceViewer.DoInitNode(ParentNode, Node: PVirtualNode;
  var InitialStates: TVirtualNodeInitStates);
var
  nodeData: TNodeData;
begin
  InitialStates := [];
  nodeData := Default(TNodeData);

  if ParentNode = nil then
  begin
    var logIndex := EventMap[Node.Index];
    var trace := EventLog.Events[logIndex].DecisionTrace;

    Include(InitialStates, ivsHasChildren);

    nodeData.Kind            := nkResult;
    nodeData.ResolvedAction  := trace.ResolvedAction;
    nodeData.RequestedAction := trace.RequestedAction;
    nodeData.CellIndex       := trace.CellIndex;
    nodeData.EnergyLevel     := trace.Summary.EnergyLevel;
    nodeData.Evaluations     := trace.Evaluations;
    nodeData.WinningAction   := trace.ResolvedAction;

    if (trace.ResolvedAction = acMove) and (trace.ResolvedTarget.TType = ttCell) then
      nodeData.TargetCell := trace.ResolvedTarget.Cell
    else
      nodeData.TargetCell := -1;
  end
  else
  begin
    var parentData := ParentNode.GetData<TNodeData>;
    if Node.Index = 0 then
    begin
      nodeData.Kind          := nkEvaluations;
      nodeData.Evaluations   := parentData.Evaluations;
      nodeData.WinningAction := parentData.WinningAction;
    end
    else
    begin
      nodeData.Kind            := nkConflict;
      nodeData.RequestedAction := parentData.RequestedAction;
      nodeData.ResolvedAction  := parentData.ResolvedAction;
    end;
  end;

  Node.SetData(nodeData);
end;

procedure TDecisionTraceViewer.DoInitChildren(Node: PVirtualNode;
  var ChildCount: Cardinal);
var
  nodeData: TNodeData;
begin
  nodeData := Node.GetData<TNodeData>;
  ChildCount := 1;
  if nodeData.RequestedAction <> nodeData.ResolvedAction then
    Inc(ChildCount);
end;

procedure TDecisionTraceViewer.DoDrawNode(const PaintInfo: TVTPaintInfo);
begin
  ApplyCanvasDefaults(PaintInfo);

  var nodeData := PaintInfo.Node.GetData<TNodeData>;

  var R := PaintInfo.ContentRect;
  R.Inflate(-2, 0);

  var S: string;
  case nodeData.Kind of

    nkResult:
      begin
        var displayCell := nodeData.CellIndex;
        if (nodeData.ResolvedAction = acMove) and (nodeData.TargetCell >= 0) then
          displayCell := nodeData.TargetCell;
        S := nodeData.ResolvedAction.AsLabel + ' ' +
             CellIndexToStr(displayCell, GridWidth) + '  ' +
             nodeData.EnergyLevel.AsLabel;
      end;

    nkEvaluations:
      S := EvaluationsAsScoreLine(nodeData.Evaluations, nodeData.WinningAction);

    nkConflict:
      S := 'Wanted: ' + nodeData.RequestedAction.AsLabel +
           '  →  Resolved: ' + nodeData.ResolvedAction.AsLabel;

  end;

  PaintInfo.Canvas.Font.Style := [];
  PaintInfo.Canvas.TextRect(R, S, [tfSingleLine, tfVerticalCenter]);
end;

end.
