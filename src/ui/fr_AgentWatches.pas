unit fr_AgentWatches;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.ControlList, Vcl.Buttons, Vcl.StdCtrls, Vcl.Samples.Spin,

  u_ControlRendering, u_LogTypes, u_SimEventTypes,
  u_SimPopulations, u_SimTypes,
  u_SimRuntimes, u_MulticastEvents, u_DiagnosticsIntf, u_SimDiagnostics;

const
  TICK_HISTORY_LENGTH = 5;
  LINES_PER_TICK = 2;

type
  TWatchOption = (woTrackOffspring);
  TWatchOptions = set of TWatchOption;

  TWatchEvent = record
    Date: TSimDate;
    Fields: array[0..LINES_PER_TICK - 1] of TLogFields;  // action, evals
  end;

  TAgentWatchEntry = record
    Selected: Boolean;
    AgentId: TAgentId;
    Header: TLogFields;

    Options: TWatchOptions;

    // Ring buffer
    History: array[0..TICK_HISTORY_LENGTH - 1] of TWatchEvent;
    HistoryCount: Integer;
    WriteIndex: Integer;
  end;

  TAgentWatchFrame = class(TFrame, ISimEventConsumer, IRuntimeObserver)
    WatchList: TControlList;
    edtAgentList: TEdit;
    Label2: TLabel;
    btnUpdateAgents: TSpeedButton;
    pbContent: TPaintBox;
    lblAgentId: TLabel;
    shAgentId: TShape;
    spnRowCount: TSpinEdit;
    pnlClientArea: TPanel;
    DetailList: TControlList;
    HSplit: TSplitter;
    cbDetails: TCheckBox;
    pbDetailLine: TPaintBox;
    lblDetailLineNumber: TLabel;
    btnExportSelected: TSpeedButton;
    procedure edtAgentListKeyPress(Sender: TObject; var Key: Char);
    procedure btnUpdateAgentsClick(Sender: TObject);
    procedure WatchListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure FieldPaint(Sender: TObject);
    procedure spnRowCountChange(Sender: TObject);
    procedure cbDetailsClick(Sender: TObject);
    procedure WatchListItemClick(Sender: TObject);
    procedure DetailListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure DetailPaint(Sender: TObject);
    procedure btnExportSelectedClick(Sender: TObject);
    procedure lblAgentIdClick(Sender: TObject);
  private
    Runtime: TSimRuntime;
    Watches: TArray<TAgentWatchEntry>;
    WatchDetailTick: Integer;
    WatchDetails: TArray<TLogFields>;
    SubscriptionId: Integer;
  private
    procedure Consume(const Event: TSimEvent);
    procedure UpdateAgentList;
    function IndexOf(AgentId: TAgentId): Integer;

  private
    { IRuntimeObserver }
    procedure ConnectRuntime(aRuntime: TSimRuntime; aDiagnostics: TSimDiagnosticsHub;
      AfterAdvance: TMulticastEvent<TNotifyEvent>);
    procedure DisconnectRuntime(aRuntime: TSimRuntime; aDiagnostics: TSimDiagnosticsHub;
      AfterAdvance: TMulticastEvent<TNotifyEvent>);
    procedure HandleAfterAdvance(Sender: TObject);
    procedure SetSelectedWatch(aWatchIndex: Integer);
    procedure UpdateWatchDetails;

  public
  end;

implementation

{$R *.dfm}

uses System.Types, System.IOUtils, Vcl.Themes, Vcl.GraphUtil,
  u_DiagnosticsHelpers;

const
  bk_colors: array[0..9] of string = (
    'fec5bb','fcd5ce','fae1dd','f8edeb','e8e8e4','d8e2dc','ece4db','ffe5d9','ffd7ba','fec89a'
  );


type
  TWordRec = record
    Low, High: Word;
  end;

{ TAgentWatchFrame }

procedure TAgentWatchFrame.btnUpdateAgentsClick(Sender: TObject);
begin
  UpdateAgentList;
end;

function TAgentWatchFrame.IndexOf(AgentId: TAgentId): Integer;
begin
  if Length(Watches) > 0 then
  begin
    for var i := 0 to High(Watches) do
    begin
      if Watches[i].AgentId = AgentId then
        Exit(i);
    end;
  end;
  Result := -1;
end;

procedure TAgentWatchFrame.lblAgentIdClick(Sender: TObject);
begin
//  var index := WatchList.ItemIndex;

  if Watchlist.ItemIndex >= 0 then
  begin
    var linesPerWatch := 1 + LINES_PER_TICK * spnRowCount.Value;
    var watchIndex := Watchlist.ItemIndex div linesPerWatch;
    if Watches[watchIndex].Selected then
      watchIndex := -1;
    SetSelectedWatch(watchIndex);
  end;

//  ShowMessage(index.ToString);
end;

procedure TAgentWatchFrame.spnRowCountChange(Sender: TObject);
begin
  WatchList.ItemCount := Length(Watches) * (1 + LINES_PER_TICK * spnRowCount.Value);
  WatchList.Invalidate;
end;

procedure TAgentWatchFrame.cbDetailsClick(Sender: TObject);
begin
  DetailList.Visible := cbDetails.Checked;
  HSplit.Visible := cbDetails.Checked;
  HSplit.Top := DetailList.Top - 1;
end;

procedure TAgentWatchFrame.ConnectRuntime(aRuntime: TSimRuntime;
  aDiagnostics: TSimDiagnosticsHub; AfterAdvance: TMulticastEvent<TNotifyEvent>);
begin
  Runtime := aRuntime;
  AfterAdvance.Subscribe(HandleAfterAdvance);
  SubscriptionId := aDiagnostics.Subscribe(Self);

  spnRowCount.MinValue := 0;
  spnRowCount.MaxValue := TICK_HISTORY_LENGTH;
  spnRowCount.Value := spnRowCount.MinValue;
end;

procedure TAgentWatchFrame.DetailListBeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  if (AIndex >= 0) and (AIndex < Length(WatchDetails)) then
  begin
    pbDetailLine.Tag := AIndex;
    pbDetailLine.Invalidate;
    lblDetailLineNumber.Caption := AIndex.ToString;
  end;
end;

procedure TAgentWatchFrame.DisconnectRuntime(aRuntime: TSimRuntime;
  aDiagnostics: TSimDiagnosticsHub; AfterAdvance: TMulticastEvent<TNotifyEvent>);
begin
  aDiagnostics.Unsubscribe(SubscriptionId);
  AfterAdvance.Unsubscribe(HandleAfterAdvance);
  Runtime := nil;
end;

procedure TAgentWatchFrame.Consume(const Event: TSimEvent);
begin
  //
end;

procedure TAgentWatchFrame.edtAgentListKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    UpdateAgentList;
  end;
end;

procedure TAgentWatchFrame.UpdateAgentList;

  procedure AddWatch(aId: TAgentId; opts: TWatchOptions);
  begin
    var count := Length(Watches);
    SetLength(Watches, count + 1);

    var watch := Default(TAgentWatchEntry);
    watch.AgentId := aId;
    watch.Options := opts;
    Watches[count] := watch;
  end;

begin
  var line: string := edtAgentList.Text;
  var isAdd := line.StartsWith('+');
  if isAdd then
    line := Copy(line, 2, line.Length);

  var parts := line.Split([',', '.', ' ']);
  if Length(parts) > 0 then
  begin
    // if not adding, then reset the list first
    if not isAdd then
      SetLength(Watches, 0);

    // check each part
    for var i := 0 to High(parts) do
    begin
      var partStr := parts[i];

      var opts: TWatchOptions := [];
      if partStr.EndsWith('c') then
      begin
        opts := [woTrackOffspring];
        SetLength(partStr, partStr.Length - 1);
      end;

      var id: TAgentId := StrToIntDef(partStr, -1);
      if id >= 0 then
      begin
        AddWatch(id, opts);
      end;
    end;

    WatchList.ItemCount := Length(Watches) * (1 + LINES_PER_TICK * spnRowCount.Value);
    WatchList.Invalidate;
  end;
end;

procedure TAgentWatchFrame.WatchListBeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  if (AIndex < 0) or (AIndex >= WatchList.ItemCount) then
    Exit;

  // AIndex → watch index + line within that watch
  var linesPerWatch := 1 + LINES_PER_TICK * spnRowCount.Value;
  var watchIndex := AIndex div linesPerWatch;
  var lineIndex := AIndex mod linesPerWatch;  // 0 = header, 1..N = history lines
  var isHeader := (lineIndex = 0);

  if watchIndex >= Length(Watches) then
    Exit;

  // adjust paintbox for row type
  var r := ARect;
  Inc(r.Top, 2);
  Dec(r.Right, 4);
  Dec(r.Bottom, 2);

  // set up the controls for the header or other lines
  if isHeader then
  begin
    lblAgentId.Caption := 'A' + Watches[watchIndex].AgentId.AsText;
    r.Left := shAgentId.Left + shAgentId.Width + 4;
  end
  else
  begin
    r.Left := shAgentId.Left + (shAgentId.Width div 2);
  end;

  shAgentId.Visible := isHeader;
  if Watches[watchIndex].Selected then
    shAgentId.Brush.Color := clWebRoyalBlue
  else
    shAgentId.Brush.Color := StyleServices.GetSystemColor(clBtnFace);

  lblAgentId.Visible := isHeader;
  pbContent.BoundsRect := r;

  // we have to tell the paintbox which watch and which line to draw.
  var pbTag: Integer := 0;
  TWordRec(pbTag).High := watchIndex;
  TWordRec(pbTag).Low := lineIndex;
  pbContent.Tag := pbTag;

  pbContent.Invalidate;
end;

procedure TAgentWatchFrame.WatchListItemClick(Sender: TObject);
begin
//  if Watchlist.ItemIndex >= 0 then
//  begin
//    var linesPerWatch := 1 + LINES_PER_TICK * spnRowCount.Value;
//    var watchIndex := Watchlist.ItemIndex div linesPerWatch;
//    if Watches[watchIndex].Selected then
//      watchIndex := -1;
//    SetSelectedWatch(watchIndex);
//  end;
end;

procedure TAgentWatchFrame.SetSelectedWatch(aWatchIndex: Integer);
begin
  btnExportSelected.Enabled := False;
  for var index := 0 to High(Watches) do
  begin
    Watches[index].Selected := index = aWatchIndex;
    if Watches[index].Selected then
      btnExportSelected.Enabled := True;
  end;
  WatchList.Invalidate;
  UpdateWatchDetails;
end;

procedure TAgentWatchFrame.DetailPaint(Sender: TObject);
begin
  var pb := Sender as TPaintBox;
  var lineIndex := pb.Tag;
  if lineIndex < Length(WatchDetails) then
    pbDetailLine.Render(WatchDetails[lineIndex], clWindow);
end;

procedure TAgentWatchFrame.FieldPaint(Sender: TObject);
begin
  var pb := Sender as TPaintBox;

  var watchIndex := TWordRec(pb.Tag).High;
  var lineIndex := TWordRec(pb.Tag).Low;

  if watchIndex < Length(Watches) then
  begin
    if lineIndex = 0 then
      pb.Render(Watches[watchIndex].Header, clWindow)
    else
    begin
      var tickOffset := (lineIndex - 1) div LINES_PER_TICK;
      var subLine := (lineIndex - 1) mod LINES_PER_TICK;
      if tickOffset < Watches[watchIndex].HistoryCount then
      begin
        var ringIdx := (Watches[watchIndex].WriteIndex - 1 - tickOffset + TICK_HISTORY_LENGTH) mod TICK_HISTORY_LENGTH;

        var lineFields := Default(TLogFields);
        lineFields.AddFields(Watches[watchIndex].History[ringIdx].Date.AsFields);
        lineFields.AddFields(Watches[watchIndex].History[ringIdx].Fields[subLine]);

        pb.Render(lineFields, clWindow);
      end;
    end;
  end;
end;

procedure TAgentWatchFrame.HandleAfterAdvance(Sender: TObject);
begin
  if Assigned(Runtime) then
  begin
    for var watchIndex := 0 to High(Watches) do
    begin
      var agentId := Watches[watchIndex].AgentId;
      if agentId < Runtime.Population.AgentCount then
      begin
        var state := Runtime.Population.StatePtr(agentId);
        if Assigned(state) then
        begin
          Watches[watchIndex].Header := state.AsWatchHeader;
        end;
      end;
    end;

    UpdateWatchDetails;
    WatchList.Invalidate;
  end;
end;

procedure TAgentWatchFrame.UpdateWatchDetails;
begin
  SetLength(WatchDetails, 0);

//  for var watchIndex := 0 to High(Watches) do
//  begin
//    if Watches[watchIndex].Selected then
//    begin
//      var debug := Runtime.Population.DecisionDebugTracePtr(Watches[watchIndex].AgentId);
//
//      var detailCount := debug.Context.Smell.Count;
//      SetLength(WatchDetails, detailCount);
//      for var i := 0 to detailCount - 1 do
//        WatchDetails[i] := debug.Context.Smell.Details[i].AsFields;
//      WatchDetailTick := debug.GlobalTick;
//      Break;
//    end;
//  end;

  DetailList.ItemCount := Length(WatchDetails);
end;

procedure TAgentWatchFrame.btnExportSelectedClick(Sender: TObject);
const
  CRLF = #13#10;
begin
  // find the selected watch
  for var watchIndex := 0 to High(Watches) do
  begin
    if Watches[watchIndex].Selected then
    begin

      var lines := TStringList.Create(dupAccept, False, True);
      try
        lines.add(Format('AgentId: %.03d  Generated: %s', [
          Watches[watchIndex].AgentId,
          FormatDateTime('yy-mm-dd hh:mm:ss', Now)
        ]) + CRLF);

        lines.Add(Watches[watchIndex].Header.AsFieldText);

        // write the detail lines
        var simDate: TSimDate;
        simDate.SetDate(WatchDetailTick);
        lines.add('Details from tick: ' + simDate.AsFields.AsFieldText);

        for var dIndex := 0 to High(WatchDetails) do
        begin
          lines.Add(Format('%0.2d %s', [dIndex, WatchDetails[dIndex].AsFieldText]));
        end;
        lines.Add('');

        // write history
        lines.Add('History (newest first):');
        for var tickOffset := 0 to Watches[watchIndex].HistoryCount - 1 do
        begin
          var ringIdx := (Watches[watchIndex].WriteIndex - 1 - tickOffset + TICK_HISTORY_LENGTH) mod TICK_HISTORY_LENGTH;
          var hist := Watches[watchIndex].History[ringIdx];

          for var subLine := 0 to LINES_PER_TICK - 1 do
          begin
            var lineFields := Default(TLogFields);
            lineFields.AddFields(hist.Date.AsFields);
            lineFields.AddFields(hist.Fields[subLine]);
            lines.Add(Format('%0.2d.%d %s', [tickOffset, subLine, lineFields.AsFieldText]));
          end;
        end;
        lines.Add('');

        var fileName := TPath.Combine(ExtractFilePath(Application.ExeName), 'agent_watch.txt');
        TFile.WriteAllText(fileName, lines.Text);

      finally
        lines.Free;
      end;

      Break;
    end;
  end;




end;

end.
