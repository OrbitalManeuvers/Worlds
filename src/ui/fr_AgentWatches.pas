unit fr_AgentWatches;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.ControlList, Vcl.Buttons, Vcl.StdCtrls, Vcl.Samples.Spin,

  u_ControlRendering, u_LogTypes, u_SimEventTypes, u_AgentTypes,
  u_SimPopulations;

type
  TWatchOption = (woTrackOffspring);
  TWatchOptions = set of TWatchOption;

  TWatchFields = record
    Header: TLogFields;
    Weights: TLogFields;
    Action: TLogFields;
    Evals: TLogFields;
  end;

  TAgentWatchEntry = record
    AgentId: TAgentId;
    Options: TWatchOptions;

    // Ring buffer of recent decision traces
//    History: array[0..4] of TDecisionTraceEvent;  // last N decisions
    HistoryCount: Integer;
//    WriteIndex: Integer;

    Fields: TWatchFields;

  end;

  TAgentWatchFrame = class(TFrame, ISimEventConsumer)
    WatchList: TControlList;
    shpCard: TShape;
    edtAgentList: TEdit;
    Label2: TLabel;
    btnUpdateAgents: TSpeedButton;
    pbEvals: TPaintBox;
    pbAction: TPaintBox;
    pbHeader: TPaintBox;
    pbWeights: TPaintBox;
    procedure edtAgentListKeyPress(Sender: TObject; var Key: Char);
    procedure btnUpdateAgentsClick(Sender: TObject);
    procedure WatchListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure FieldPaint(Sender: TObject);
  private
    fWatches: TArray<TAgentWatchEntry>;
    fPopulation: TSimPopulation;  // direct reference for header reads
  private
    procedure Consume(const Event: TSimEvent);
    procedure UpdateAgentList;
    function IndexOf(AgentId: TAgentId): Integer;
  public
    procedure Connect(aPopulation: TSimPopulation);
    procedure Step;
  end;

implementation

{$R *.dfm}

uses System.Types, Vcl.Themes, Vcl.GraphUtil,
  u_DiagnosticsHelpers;

const
  bk_colors: array[0..9] of string = (
    'fec5bb','fcd5ce','fae1dd','f8edeb','e8e8e4','d8e2dc','ece4db','ffe5d9','ffd7ba','fec89a'
  );


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

procedure TAgentWatchFrame.Connect(aPopulation: TSimPopulation);
begin
  fPopulation := aPopulation;
end;

procedure TAgentWatchFrame.Consume(const Event: TSimEvent);
begin

  if Event.Header.Kind = sekDecisionTrace then
  begin
    // look for watch record and update
    var index := IndexOf(Event.DecisionTrace.AgentId);
    if index >= 0 then
    begin
      fWatches[index].Fields.Header := Event.DecisionTrace.AsHeader;
      fWatches[index].Fields.Weights := Default(TLogFields);
      fWatches[index].Fields.Action := Event.DecisionTrace.AsAction;
      fWatches[index].Fields.Evals := Event.DecisionTrace.AsEvaluations;
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
    fWatches[count].AgentId := aId;
    fWatches[count].Options := opts;
    fWatches[count].HistoryCount := 0;
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

    WatchList.ItemCount := Length(fWatches);
    WatchList.Invalidate;
  end;
end;

procedure TAgentWatchFrame.WatchListBeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  shpCard.Brush.Color := StyleServices.GetStyleColor(scButtonNormal);
  shpCard.Pen.Color := StyleServices.GetSystemColor(clBtnHighlight);

  // weights are populated from the state record
  if Assigned(fPopulation) then
  begin
    var agentId := fWatches[AIndex].AgentId;
    if agentId < fPopulation.AgentCount then
    begin
      var state := fPopulation.StatePtr(agentId);
      if Assigned(state) then
      begin
        fWatches[AIndex].Fields.Weights := state.AsMoleculeWeights;
      end;
    end;

  end;

  pbHeader.Tag := aIndex;
  pbHeader.Invalidate;

  pbAction.Tag := aIndex;
  pbAction.Invalidate;

  pbEvals.Tag := aIndex;
  pbEvals.Invalidate;

  pbWeights.Tag := aIndex;
  pbWeights.Invalidate;

end;

procedure TAgentWatchFrame.FieldPaint(Sender: TObject);
begin
  var pb := Sender as TPaintBox;
  if (pb.Tag >= 0) and (pb.Tag < Length(fWatches)) then
  begin
    var c := StyleServices.GetStyleColor(scButtonNormal);
    if pb = pbHeader then
      pb.Render(fWatches[pb.Tag].Fields.Header, c)
    else if pb = pbWeights then
      pb.Render(fWatches[pb.Tag].Fields.Weights, c)
    else if pb = pbAction then
      pb.Render(fWatches[pb.Tag].Fields.Action, c)
    else if pb = pbEvals then
      pb.Render(fWatches[pb.Tag].Fields.Evals, c);
  end;
end;

procedure TAgentWatchFrame.Step;
begin
  WatchList.Invalidate;
end;

end.
