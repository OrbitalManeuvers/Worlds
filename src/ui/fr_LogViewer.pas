unit fr_LogViewer;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.Buttons, Vcl.Grids,
  Vcl.ControlList,

  u_SimEventTypes, u_DiagnosticsHelpers, u_LogTypes, Vcl.StdCtrls;

type
  TLogViewer = class(TFrame)
    pnlViewTools: TPanel;
    btnIncDT: TSpeedButton;
    btnExport: TSpeedButton;
    btnIncAR: TSpeedButton;
    DetailsView: TControlList;
    lblDetails: TLabel;
    EventList: TControlList;
    lblEventTime: TLabel;
    lblEventContent: TLabel;
    procedure FilterChanged(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure EventListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure EventListItemClick(Sender: TObject);
    procedure DetailsViewBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
  private
    ViewDef: TSimEventViewDef;
    EventView: IEventLogView;
    DetailFields: TLogFields;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Connect(const aLogEventView: IEventLogView);
    procedure Refresh;
  end;

implementation

uses System.IOUtils, Vcl.Themes;

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

procedure TLogViewer.DetailsViewBeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  if (AIndex >= 0) and (AIndex < DetailFields.Count) then
  begin
    var event := EventView.Events[EventList.ItemIndex]; // selected event
    var s := '';
    if event.Header.Kind = sekDecisionTrace then
    begin
      s := Format('trace a%.02d: %s',
      [event.DecisionTrace.AgentId, DetailFields.ShortFieldText]);
    end;

    lblDetails.Caption := s; //DetailFields.ShortFieldText;
  end;
end;

procedure TLogViewer.EventListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
  ARect: TRect; AState: TOwnerDrawState);
begin
  if aIndex < EventView.Count then
  begin
    var eventFields := EventView.Events[AIndex].AsFields;
    var count := Length(eventFields.Fields);
    if count > 0 then
    begin
      lblEventTime.Caption := eventFields.Fields[0].Value;
      lblEventTime.Font.Color := StyleServices.GetStyleFontColor(sfButtonTextDisabled);
    end;
    if count > 1 then
    begin
      lblEventContent.Caption := eventFields.Fields[1].Value;
      if Odd(EventView.Events[AIndex].DecisionTrace.AgentId) then
        lblEventContent.Font.Color := StyleServices.GetSystemColor(clWebIvory)
      else
        lblEventContent.Font.Color := StyleServices.GetSystemColor(clWebPaleTurquoise);
    end;

  end;
end;

procedure TLogViewer.EventListItemClick(Sender: TObject);
begin
  DetailFields.Clear;

  if EventList.ItemIndex <> -1 then
  begin
    var event := EventView.Events[EventList.ItemIndex];
    if event.Header.Kind = sekDecisionTrace then
    begin
      DetailFields := event.DecisionTrace.Summary.AsFields;
    end;
  end;
  if DetailFields.Count <> 0 then
    DetailsView.ItemCount := 1;

  DetailsView.Invalidate;

(*
      var event := EventView.Events[sel.Index];
      DetailFields := event.AsFields;
    end;
  end
  else
  begin
    DetailFields := Default(TLogFields);
  end;


*)
end;

procedure TLogViewer.btnExportClick(Sender: TObject);
begin
//  var exportText := ContentToUnicodeString(Tree, tstSelected, '');
//  var exportPath := TPath.Combine(ExtractFilePath(Application.ExeName), 'log_export.txt');
//  TFile.WriteAllText(exportPath, exportText, TEncoding.UTF8);
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
  EventList.ItemCount := EventView.Count;
  EventList.ItemIndex := EventList.ItemCount - 1;
end;

end.
