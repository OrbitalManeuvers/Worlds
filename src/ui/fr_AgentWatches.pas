unit fr_AgentWatches;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.ControlList, Vcl.Buttons, Vcl.StdCtrls, Vcl.Samples.Spin,

  u_ControlRendering, u_LogTypes, u_SimEventTypes, u_AgentTypes,
  u_SimPopulations, u_SimTypes;

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
    AgentId: TAgentId;
    Header: TLogFields;

    Options: TWatchOptions;

    // Ring buffer
    History: array[0..TICK_HISTORY_LENGTH - 1] of TWatchEvent;
    HistoryCount: Integer;
    WriteIndex: Integer;
  end;

  TAgentWatchFrame = class(TFrame, ISimEventConsumer)
    WatchList: TControlList;
    edtAgentList: TEdit;
    Label2: TLabel;
    btnUpdateAgents: TSpeedButton;
    pbContent: TPaintBox;
    lblAgentId: TLabel;
    shAgentId: TShape;
    spnRowCount: TSpinEdit;
    procedure edtAgentListKeyPress(Sender: TObject; var Key: Char);
    procedure btnUpdateAgentsClick(Sender: TObject);
    procedure WatchListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure FieldPaint(Sender: TObject);
    procedure spnRowCountChange(Sender: TObject);
  private
    fWatches: TArray<TAgentWatchEntry>;
    fPopulation: TSimPopulation;  // direct reference for header reads
  private
    fSubscriptionId: Integer;
    procedure Consume(const Event: TSimEvent);
    procedure UpdateAgentList;
    function IndexOf(AgentId: TAgentId): Integer;
  public
    procedure Connect(aPopulation: TSimPopulation);
    procedure Step;
    property SubscriptionId: Integer read fSubscriptionId write fSubscriptionId;
  end;

implementation

{$R *.dfm}

uses System.Types, Vcl.Themes, Vcl.GraphUtil,
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
  if Length(fWatches) > 0 then
  begin
    for var i := 0 to High(fWatches) do
    begin
      if fWatches[i].AgentId = AgentId then
        Exit(i);
    end;
  end;
  Result := -1;
end;

procedure TAgentWatchFrame.spnRowCountChange(Sender: TObject);
begin
  WatchList.ItemCount := Length(fWatches) * (1 + LINES_PER_TICK * spnRowCount.Value);
  WatchList.Invalidate;
end;

procedure TAgentWatchFrame.Connect(aPopulation: TSimPopulation);
begin
  fPopulation := aPopulation;
  spnRowCount.MinValue := 0;
  spnRowCount.MaxValue := TICK_HISTORY_LENGTH;
  spnRowCount.Value := spnRowCount.MinValue;
end;

procedure TAgentWatchFrame.Consume(const Event: TSimEvent);
begin

  if Event.Header.Kind = sekDecisionTrace then
  begin
    // look for watch record and update
    var index := IndexOf(Event.DecisionTrace.AgentId);
    if index >= 0 then
    begin
      var data := Default(TWatchEvent);
      data.Date.DayNumber := Event.Header.DayNumber;
      data.Date.DayTick := Event.Header.DayTick;
      data.Fields[0] := Event.DecisionTrace.AsAction;
      data.Fields[1] := Event.DecisionTrace.AsEvaluations;

      // write to ring buffer
      fWatches[index].History[fWatches[index].WriteIndex] := data;
      fWatches[index].WriteIndex := (fWatches[index].WriteIndex + 1) mod TICK_HISTORY_LENGTH;
      if fWatches[index].HistoryCount < TICK_HISTORY_LENGTH then
        Inc(fWatches[index].HistoryCount);
    end;
  end;
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
    var count := Length(fWatches);
    SetLength(fWatches, count + 1);

    var watch := Default(TAgentWatchEntry);
    watch.AgentId := aId;
    watch.Options := opts;
    fWatches[count] := watch;
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
      SetLength(fWatches, 0);

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

    WatchList.ItemCount := Length(fWatches) * (1 + LINES_PER_TICK * spnRowCount.Value);
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

  if watchIndex >= Length(fWatches) then
    Exit;

  // adjust paintbox for row type
  var r := ARect;
  Inc(r.Top, 2);
  Dec(r.Right, 4);
  Dec(r.Bottom, 2);

  // set up the controls for the header or other lines
  if isHeader then
  begin
    lblAgentId.Caption := 'A' + fWatches[watchIndex].AgentId.AsText;
    r.Left := shAgentId.Left + shAgentId.Width + 4;
  end
  else
  begin
    r.Left := shAgentId.Left + (shAgentId.Width div 2);
  end;

  shAgentId.Visible := isHeader;
  shAgentId.Brush.Color := StyleServices.GetSystemColor(clBtnFace);
  lblAgentId.Visible := isHeader;
  pbContent.BoundsRect := r;

  // we have to tell the paintbox which watch to draw, but ALSO which line to draw.
  var pbTag: Integer := 0;
  TWordRec(pbTag).High := watchIndex;
  TWordRec(pbTag).Low := lineIndex;
  pbContent.Tag := pbTag;

  pbContent.Invalidate;
end;

procedure TAgentWatchFrame.FieldPaint(Sender: TObject);
begin
  var pb := Sender as TPaintBox;

  var watchIndex := TWordRec(pb.Tag).High;
  var lineIndex := TWordRec(pb.Tag).Low;

  if watchIndex < Length(fWatches) then
  begin
    if lineIndex = 0 then
      pb.Render(fWatches[watchIndex].Header, clWindow)
    else
    begin
      var tickOffset := (lineIndex - 1) div LINES_PER_TICK;
      var subLine := (lineIndex - 1) mod LINES_PER_TICK;
      if tickOffset < fWatches[watchIndex].HistoryCount then
      begin
        var ringIdx := (fWatches[watchIndex].WriteIndex - 1 - tickOffset + TICK_HISTORY_LENGTH) mod TICK_HISTORY_LENGTH;

        var lineFields := Default(TLogFields);
        lineFields.AddFields(fWatches[watchIndex].History[ringIdx].Date.AsFields);
        lineFields.AddFields(fWatches[watchIndex].History[ringIdx].Fields[subLine]);

        pb.Render(lineFields, clWindow);
      end;
    end;
  end;
end;

procedure TAgentWatchFrame.Step;
begin
  // apply updates from state
  if Assigned(fPopulation) then
  begin

    for var watchIndex := 0 to High(fWatches) do
    begin
      var agentId := fWatches[watchIndex].AgentId;
      if agentId < fPopulation.AgentCount then
      begin
        var state := fPopulation.StatePtr(agentId);
        if Assigned(state) then
        begin
          fWatches[watchIndex].Header := state.AsWatchHeader;
        end;

      end;

    end;

    WatchList.Invalidate;

  end;
end;

end.
