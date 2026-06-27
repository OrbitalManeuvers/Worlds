unit fr_AgentWatches;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.ControlList, Vcl.Buttons, Vcl.StdCtrls, Vcl.Samples.Spin,
  System.Generics.Collections, VirtualTrees, VirtualTrees.DrawTree,

  u_LogTypes, u_SimPopulations, u_SimTypes,
  u_SimRuntimes, u_MulticastEvents, u_DiagnosticsIntf, u_BrainProbes,
  u_FieldRendering;


const
  TICK_HISTORY_LENGTH = 5;

type
  THistoryEntry = record
    Date: TSimDate;
    Snapshot: TBrainSnapshot;
  end;

  TAgentWatch = record
    AgentId: TAgentId;
    // Ring buffer
    History: array[0..TICK_HISTORY_LENGTH - 1] of THistoryEntry;
    HistoryCount: Integer;
    WriteIndex: Integer;
  end;

  TNodeKind = (nkRoot, nkTick, nkDampenedScores, nkActionScores);

  TAgentWatchFrame = class(TFrame, IRuntimeObserver)
    edtAgentList: TEdit;
    Label2: TLabel;
    btnUpdateAgents: TSpeedButton;
    pnlClientArea: TPanel;
    btnExport: TSpeedButton;
    Tree: TVirtualDrawTree;
    spnTickCount: TSpinEdit;
    procedure edtAgentListKeyPress(Sender: TObject; var Key: Char);
    procedure btnUpdateAgentsClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure pbTestPaint(Sender: TObject);
    procedure TreeDrawNode(Sender: TBaseVirtualTree;
      const PaintInfo: TVTPaintInfo);
    procedure TreeGetNodeDataSize(Sender: TBaseVirtualTree;
      var NodeDataSize: Integer);
    procedure TreeInitChildren(Sender: TBaseVirtualTree; Node: PVirtualNode;
      var ChildCount: Cardinal);
    procedure TreeInitNode(Sender: TBaseVirtualTree; ParentNode,
      Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
    procedure TreeMeasureItem(Sender: TBaseVirtualTree; TargetCanvas: TCanvas;
      Node: PVirtualNode; var NodeHeight: Integer);
    procedure spnTickCountChange(Sender: TObject);
  private
    Runtime: TSimRuntime;
    Watches: TList<TAgentWatch>;
  private
    procedure UpdateAgentList;
    function IndexOf(AgentId: TAgentId): Integer;
    function GetHistorySlot(const Watch: TAgentWatch; DisplayIndex: Integer): Integer;
    function GetDisplayFields(WatchIndex: Integer; NodeKind: TNodeKind; NodeIndex, ParentNodeIndex: Integer): TDisplayFields;
  private
    { IRuntimeObserver }
    procedure ConnectRuntime(aRuntime: TSimRuntime; aEvents: TNotificationEvents);
    procedure DisconnectRuntime(aRuntime: TSimRuntime; aEvents: TNotificationEvents);
    procedure HandleAfterRun(Sender: TObject);
    function CreateDisplayPalette: TArray<TColor>;
    function CreateDisplayDefaults: TDefaultColors;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

{$R *.dfm}

uses System.Types, System.IOUtils, Vcl.Themes, System.Math, Vcl.GraphUtil,
  u_DiagnosticsHelpers;

const
  bk_colors: array[0..9] of string = (
    'fec5bb','fcd5ce','fae1dd','f8edeb','e8e8e4','d8e2dc','ece4db','ffe5d9','ffd7ba','fec89a'
  );

type
  PNodeData = ^TNodeData;
  TNodeData = record
    BkColor: TColor;
    Kind: TNodeKind;
    WatchIndex: Integer;
  end;

const
  pal_name = 0;
  pal_value = 1;
  pal_negative = 2;
  pal_positive = 3;


{ TAgentWatchFrame }

constructor TAgentWatchFrame.Create(AOwner: TComponent);
begin
  inherited;
  Watches := TList<TAgentWatch>.Create;
  spnTickCount.MaxValue := TICK_HISTORY_LENGTH;
  spnTickCount.MinValue := 0;
  spnTickCount.Value := 0;
end;

destructor TAgentWatchFrame.Destroy;
begin
  Watches.Free;
  inherited;
end;

procedure TAgentWatchFrame.btnUpdateAgentsClick(Sender: TObject);
begin
  UpdateAgentList;

end;

function TAgentWatchFrame.IndexOf(AgentId: TAgentId): Integer;
begin
  for var i := 0 to Watches.Count - 1 do
    if Watches[i].AgentId = AgentId then
      Exit(i);
  Result := -1;
end;

procedure TAgentWatchFrame.pbTestPaint(Sender: TObject);
const
  _name = 0;
  _value = 1;
  _positive = 2;
  _negative = 3;

  function stdPalette: TArray<TColor>;
  begin
    SetLength(Result, 4);
    Result[_name] := clWebCornFlowerBlue;
    Result[_value] := StyleServices.GetSystemColor(clWindowText);
    Result[_positive] := clWebGreenYellow;
    Result[_negative] := clWebTomato;
  end;

begin
  var df := Default(TDisplayFields);
  df.Palette := stdPalette;
  df.Defaults.Bk := StyleServices.GetSystemColor(clWindow);
  df.Defaults.NameColor := df.Palette[_name];
  df.Defaults.ValueColor := df.Palette[_value];

  df.AddField('rsrv', '6.30', _name, _value);
  df.AddField('', '2.4', _name, _negative);
  df.addField('loc', '(3,23)', _name, _value);

//  TFieldDisplayEngine.RenderFields(df, pbTest.Canvas, pbTest.ClientRect);

end;

procedure TAgentWatchFrame.spnTickCountChange(Sender: TObject);
begin
  Tree.ReinitNode(nil, True);
  Tree.Invalidate;
end;

procedure TAgentWatchFrame.TreeDrawNode(Sender: TBaseVirtualTree;
  const PaintInfo: TVTPaintInfo);
begin
  var nodeData := PaintInfo.Node.GetData<TNodeData>;

  var R := PaintInfo.CellRect;
  R.Left := R.Left + PaintInfo.Offsets[ofsLabel];
  var parentNodeIndex := -1;
  if PaintInfo.Node.Parent <> nil then
    parentNodeIndex := PaintInfo.Node.Parent.Index;

  var df := GetDisplayFields(nodeData.WatchIndex, nodeData.Kind, PaintInfo.Node.Index, parentNodeIndex);

  TFieldDisplayEngine.RenderFields(df, PaintInfo.Canvas, R);
end;

procedure TAgentWatchFrame.TreeGetNodeDataSize(Sender: TBaseVirtualTree;
  var NodeDataSize: Integer);
begin
  NodeDataSize := SizeOf(TNodeData);
end;

procedure TAgentWatchFrame.TreeInitChildren(Sender: TBaseVirtualTree;
  Node: PVirtualNode; var ChildCount: Cardinal);
begin
  var nodeData := Node.GetData<TNodeData>;
  case nodeData.Kind of
    nkRoot: ChildCount := Min(spnTickCount.Value,
      Min(Watches[nodeData.WatchIndex].HistoryCount, TICK_HISTORY_LENGTH));

    nkTick: ChildCount := 2;
  end;

end;

procedure TAgentWatchFrame.TreeInitNode(Sender: TBaseVirtualTree; ParentNode,
  Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
begin
  var nodeData := Node.GetData<TNodeData>;
  InitialStates := [];

  if ParentNode = nil then
  begin
    nodeData.Kind := nkRoot;
    nodeData.WatchIndex := Node.Index;
    if (spnTickCount.Value > 0) and (Watches[Node.Index].HistoryCount <> 0) then
    begin
      Include(InitialStates, ivsHasChildren);
      Include(InitialStates, ivsExpanded);
    end;
  end
  else
  begin
    var parentNodeData := ParentNode.GetData<TNodeData>;

    case parentNodeData.Kind of

      nkRoot:
        begin
          nodeData.WatchIndex := parentNodeData.WatchIndex;
          nodeData.Kind := nkTick;
          Include(InitialStates, ivsHasChildren);
          Include(InitialStates, ivsExpanded);
        end;

      nkTick:
        begin
          // nodeIndex indicates which type of detail
          case Node.Index of
            0: nodeData.Kind := nkDampenedScores;
            1: nodeData.Kind := nkActionScores;
          end;


        end;

    end;

  end;

  Node.SetData(nodeData);
end;

procedure TAgentWatchFrame.TreeMeasureItem(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; var NodeHeight: Integer);
begin
  NodeHeight := 25;
end;

procedure TAgentWatchFrame.ConnectRuntime(aRuntime: TSimRuntime; aEvents: TNotificationEvents);
begin
  Runtime := aRuntime;
  aEvents.OnRun.After.Subscribe(HandleAfterRun);
end;

procedure TAgentWatchFrame.DisconnectRuntime(aRuntime: TSimRuntime; aEvents: TNotificationEvents);
begin
  aEvents.OnRun.After.Unsubscribe(HandleAfterRun);
  Runtime := nil;
end;

procedure TAgentWatchFrame.edtAgentListKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    UpdateAgentList;
  end;
end;

function TAgentWatchFrame.CreateDisplayPalette(): TArray<TColor>;
begin
  SetLength(Result, 4);
  Result[pal_name] := clWebCornFlowerBlue;
  Result[pal_value] := StyleServices.GetSystemColor(clWindowText);
  Result[pal_negative] := clWebTomato;
  Result[pal_positive] := clWebGreenYellow;
end;

function TAgentWatchFrame.CreateDisplayDefaults(): TDefaultColors;
begin
  Result := Default(TDefaultColors);
  Result.Bk := StyleServices.GetSystemColor(clWindow);
  Result.NameColor := clWebCornFlowerBlue;
  Result.ValueColor := StyleServices.GetSystemColor(clWindowText);
end;

function TAgentWatchFrame.GetHistorySlot(const Watch: TAgentWatch; DisplayIndex: Integer): Integer;
begin
  // DisplayIndex 0 = most recent, 1 = second most recent, etc.
  Result := (Watch.WriteIndex - 1 - DisplayIndex + TICK_HISTORY_LENGTH * 2) mod TICK_HISTORY_LENGTH;
end;

function TAgentWatchFrame.GetDisplayFields(WatchIndex: Integer; NodeKind: TNodeKind; NodeIndex, ParentNodeIndex: Integer): TDisplayFields;
begin
  Result := Default(TDisplayFields);
  var agentId := Watches[WatchIndex].AgentId;

  Result.Palette := CreateDisplayPalette();
  Result.Defaults := CreateDisplayDefaults();

  if NodeKind = nkRoot then
  begin
    Result.AddField('', agentId.AsText);
    if agentId < Runtime.Population.AgentCount then
    begin
      var state := Runtime.Population.GetAgentState(agentId);
      Result.AddField('', Format('%.03d', [state.Age]));
      Result.AddField('', state.Location.AsText);
      Result.AddField('', state.Reserves.AsText);
      var rsrvDeltaIndex := pal_positive;
      if state.ReserveDelta < 0 then
        rsrvDeltaIndex := pal_negative;
      Result.AddField('', state.ReserveDelta.AsText, pal_name, rsrvDeltaIndex);
    end
    else
    begin
      Result.AddField('', 'Does not exist')
    end;
  end;

  if NodeKind = nkTick then
  begin
    var slot := GetHistorySlot(Watches[WatchIndex], NodeIndex);
//    Result.AddField('slot', slot.ToString);
    var date := Watches[WatchIndex].History[slot].Date;
    var dateStr := Format('%.03d:%.03d', [date.DayNumber, date.DayTick]);
//    Result.AddField('', '  ');
    Result.AddField('', dateStr);

    // action + target
    var finalAction := Watches[WatchIndex].History[slot].Snapshot.AsFinalAction;
    for var f in finalAction.Fields do
      Result.AddField(f.Name, f.Value);
  end;

  if NodeKind = nkDampenedScores then
  begin
    var slot := GetHistorySlot(Watches[WatchIndex], ParentNodeIndex);
    var scores := Watches[WatchIndex].History[slot].Snapshot.DampenedScores;
    Result.AddField('dmp', '');
    for var action := Low(TAgentAction) to High(TAgentAction) do
    begin
      var value: Single := scores[action];
      Result.AddField(action.AsText, value.AsText);
    end;
  end;

  if NodeKind = nkActionScores then
  begin
    var slot := GetHistorySlot(Watches[WatchIndex], ParentNodeIndex);
    var scores := Watches[WatchIndex].History[slot].Snapshot.CognitionInput.ActionScores;
    Result.AddField('acs', '');
    for var action := Low(TAgentAction) to High(TAgentAction) do
    begin
      var value: Single := scores[action];
      Result.AddField(action.AsText, value.AsText);
    end;
  end;

end;

procedure TAgentWatchFrame.UpdateAgentList;
begin
  var line := Trim(edtAgentList.Text);
  var parts := line.Split([' ', ',']);
  if Length(parts) = 0 then
    Exit;

  var idList := TList<TAgentId>.Create;
  try
    for var part in parts do
    begin
      var id: TAgentId := StrToIntDef(part, -1);
      if id <> -1 then
        idList.Add(id);
    end;

    // iterate over the watches and remove ones no longer needed
    for var i := Watches.Count - 1 downto 0 do
    begin
      if idList.IndexOf(Watches[i].AgentId) = -1 then
      begin
        Runtime.Population.Probe.Unwatch(Watches[i].AgentId);
        Watches.Delete(i);
      end;
    end;

    // create the new ones
    for var id in idList do
    begin
      if IndexOf(id) = -1 then
      begin
        var watch := Default(TAgentWatch);
        watch.AgentId := id;
        Runtime.Population.Probe.Watch(id);
        Watches.Add(watch);
      end;
    end;

  finally
    idList.Free;
  end;

  Tree.RootNodeCount := Watches.Count;
  Tree.Invalidate;
end;

procedure TAgentWatchFrame.HandleAfterRun(Sender: TObject);
begin
  if Assigned(Runtime) then
  begin

    for var i := 0 to Watches.Count - 1 do
    begin
      var agentId := Watches[i].AgentId;

      if Runtime.Population.Probe.IsWatching(agentId) then
      begin
        var watch := Watches[i];
        watch.History[watch.WriteIndex].Date := Runtime.Date;
        watch.History[watch.WriteIndex].Snapshot := Runtime.Population.Probe.GetSnapshot(agentId);
        watch.HistoryCount := Min(watch.HistoryCount + 1, TICK_HISTORY_LENGTH);
        Inc(watch.WriteIndex);
        if watch.WriteIndex >= TICK_HISTORY_LENGTH then
          watch.WriteIndex := 0;

        Watches[i] := watch;
      end;
    end;

    Tree.ReinitChildren(nil, True);
    Tree.Invalidate;
  end;
end;

procedure TAgentWatchFrame.btnExportClick(Sender: TObject);
const
  CRLF = #13#10;
begin

  var lines := TStringList.Create(dupAccept, False, True);
  try
    for var watchIndex := 0 to Watches.Count - 1 do
    begin
      lines.add(Format('Generated: %s', [FormatDateTime('yy-mm-dd hh:mm:ss', Now)]) + CRLF);

      var f := GetDisplayFields(watchIndex, nkRoot, watchIndex, 0);
      lines.Add('ID  Age Loc     Rsrv  Delta');
      lines.Add(f.LogFields.AsFieldText + CRLF);

      // write history
      for var tickOffset := 0 to Watches[watchIndex].HistoryCount - 1 do
      begin
        var ringIdx := (Watches[watchIndex].WriteIndex - 1 - tickOffset + TICK_HISTORY_LENGTH) mod TICK_HISTORY_LENGTH;
        var hist := Watches[watchIndex].History[ringIdx];
        f := GetDisplayFields(watchIndex, nkTick, tickOffset, watchIndex);
        lines.Add(f.LogFields.AsFieldText);
        for var nodeKind: TNodeKind := nkDampenedScores to nkActionScores do
        begin
          f := GetDisplayFields(watchindex, nodeKind, 0, tickOffset);
          lines.Add('  ' + f.LogFields.AsFieldText);
        end;
        lines.Add('');
      end;
      lines.Add('');
    end;

    var fileName := TPath.Combine(ExtractFilePath(Application.ExeName), 'agent_watch.txt');
    TFile.WriteAllText(fileName, lines.Text);

  finally
    lines.Free;
  end;


end;

end.
