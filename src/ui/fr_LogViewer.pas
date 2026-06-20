unit fr_LogViewer;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.Buttons, Vcl.Grids,
  Vcl.ControlList,

  u_SimEventTypes, u_DiagnosticsHelpers, u_LogTypes, Vcl.StdCtrls, Vcl.CheckLst;

type
  TLogViewer = class(TFrame)
    pnlViewTools: TPanel;
    btnExport: TSpeedButton;
    DetailsView: TControlList;
    lblDetails: TLabel;
    EventList: TControlList;
    lblEventTime: TLabel;
    lblEventContent: TLabel;
    lbEventTypes: TCheckListBox;
    lblDetailBelow: TLabel;
    procedure FilterChanged(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure EventListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure EventListItemClick(Sender: TObject);
    procedure DetailsViewBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure lbEventTypesClickCheck(Sender: TObject);
  private
    ViewDef: TSimEventViewDef;
    EventView: IEventLogView;
    DetailRows: TArray<TLogFields>;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Connect(const aLogEventView: IEventLogView);
    procedure Refresh;
  end;

implementation

uses System.IOUtils, Vcl.Themes;

{$R *.dfm}

type
  TSupportedEventKind = record
    name: string;
    kind: TSimEventKind;
  end;

const
  ar: TSupportedEventKind = (name:'Action Resolved'; kind: sekActionResolved);

  SupportedEventKinds: array[0..1] of TSupportedEventKind = (
    (name: 'Agent Moved'; kind: sekAgentMoved),
    (name: 'Action Resolved'; kind: sekActionResolved)

  );

//   not currently using per-node storage as node.index = view.events[index]
//type
//  TNodeData = record
//    EventType: TSimEventKind; //
//    Conflict: string;
//  end;

type
  { _SimEventKinds helper for TSimEventKinds }
  _SimEventKinds = record helper for TSimEventKinds
    function Contains(aKind: TSimEventKind): Boolean;
    procedure Toggle(aKind: TSimEventKind);
  end;

{ _SimEventKinds }
procedure _SimEventKinds.Toggle(aKind: TSimEventKind);
begin
  // toggle the presence of aKind enum in the set
  if Self.Contains(aKind) then
    Self := Self - [aKind]
  else
    Self := Self + [aKind];
end;

function _SimEventKinds.Contains(aKind: TSimEventKind): Boolean;
begin
  Result := aKind in Self;
end;


{ TLogViewer }

constructor TLogViewer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ViewDef := Default(TSimEventViewDef);
  ViewDef.StartSequence := -1;
  ViewDef.StopSequence := -1;

  lbEventTypes.Items.BeginUpdate;
  try
    for var eventKind in SupportedEventKinds do
      lbEventTypes.Items.Add(eventKind.name);
  finally
    lbEventTypes.Items.EndUpdate;
  end;

  SetLength(DetailRows, 0);
end;

destructor TLogViewer.Destroy;
begin

  inherited;
end;

procedure TLogViewer.DetailsViewBeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  if (AIndex >= 0) and (AIndex <= High(DetailRows)) then
  begin
    lblDetails.Caption := DetailRows[AIndex].AsFieldText;
  end;
end;

procedure TLogViewer.EventListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
  ARect: TRect; AState: TOwnerDrawState);
const
  agent_colors: array of TColor = [clWebWheat, clWebPink, clWebYellow, clWebLightBlue];
begin
  if aIndex < EventView.Count then
  begin
    var event := EventView.Events[AIndex];
    var eventFields := event.AsFields;
    var count := Length(eventFields.Fields);

    // clock info
    if count > 0 then
    begin
      lblEventTime.Caption := eventFields.Fields[0].Value;
      lblEventTime.Font.Color := StyleServices.GetStyleFontColor(sfButtonTextNormal);
    end;
    if count > 1 then
    begin
      lblEventContent.Caption := eventFields.AsFieldText(1, eventFields.Count - 1);

//      var id := EventView.Events[AIndex].DecisionTrace.AgentId;
//      var colorIndex := id mod Length(agent_colors);
//      lblEventContent.Font.Color := StyleServices.GetSystemColor(agent_colors[colorIndex]);
//      lblDetailBelow.Font.Color := lblEventContent.Font.Color;
//      lblDetailBelow.Caption := event.DecisionTrace.Summary.AsFields.AsFieldText();

    end;

  end;
end;

procedure TLogViewer.EventListItemClick(Sender: TObject);
begin
  SetLength(DetailRows, 0);

  if EventList.ItemIndex <> -1 then
  begin
    var event := EventView.Events[EventList.ItemIndex];
//    if event.Header.Kind = sekDecisionTrace then
//    begin
//      SetLength(DetailRows, 2);
//      DetailRows[0] := event.DecisionTrace.Summary.AsFields;
//      DetailRows[1] := event.DecisionTrace.AsEvaluations;
//    end;

  end;

  DetailsView.ItemCount := Length(DetailRows);
  DetailsView.Invalidate;
end;

procedure TLogViewer.btnExportClick(Sender: TObject);
begin
  if EventList.SelectedCount = 0 then
    Exit;

  var builder := TStringBuilder.Create;
  try
    builder.AppendLine('Log created ' + FormatDateTime('yyyy-mm-dd hh:mm:ss:ms', Now));
    for var i := 0 to EventList.ItemCount - 1 do
    begin
      if EventList.Selected[i] then
      begin
        var event := EventView.Events[i];

        var hdrFields := event.AsFields;
        if hdrFields.Count > 1 then
        begin
          builder.AppendLine(hdrFields.Fields[0].Value + ' ' + hdrFields.AsFieldText(1, hdrFields.Count - 1));
        end;

        case event.Header.Kind of

          sekAgentMoved:
            begin
              builder.AppendLine('  move: ' + event.AgentMoved.AsFields.AsFieldText);
            end;

          sekActionResolved:
            begin
              builder.AppendLine(' acrsv: ' + event.ActionResolved.AsFields.AsFieldText);
            end;
        end;
      end;
    end;

    var exportText := builder.ToString;
    var exportPath := TPath.Combine(ExtractFilePath(Application.ExeName), 'log_export.txt');
    TFile.WriteAllText(exportPath, exportText, TEncoding.UTF8);

  finally
    builder.Free;
  end;
end;

procedure TLogViewer.Connect(const aLogEventView: IEventLogView);
begin
  EventView := aLogEventView;

  if Assigned(EventView) then
  begin
    EventList.ItemCount := EventView.Count;
  end
  else
    EventList.ItemCount := 0;
  EventList.Invalidate;
end;

procedure TLogViewer.FilterChanged(Sender: TObject);
begin
  // transfer UI state into the working view definition
  // if a change warrants, call Refresh
  var kinds: TSimEventKinds := [];
  for var i := 0 to lbEventTypes.Items.Count - 1 do
    if lbEventTypes.Checked[i] then
      Include(kinds, SupportedEventKinds[i].kind);

  // if there's a change, update
  if kinds <> ViewDef.Kinds then
  begin
    ViewDef.Kinds := kinds;
    EventView.Define(ViewDef);
    Refresh;
  end;
end;

procedure TLogViewer.lbEventTypesClickCheck(Sender: TObject);
begin
  FilterChanged(Sender);
end;

procedure TLogViewer.Refresh;
begin
  if not Assigned(EventView) then
    Exit;
  EventView.Extend;
  EventList.ItemCount := EventView.Count;
  EventList.ItemIndex := EventList.ItemCount - 1;
  EventList.Invalidate;
end;

end.
