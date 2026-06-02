unit fr_AgentViewer;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Mask,
  Vcl.ExtCtrls, Vcl.Buttons, Vcl.ControlList,
  System.Generics.Collections,

  u_AgentTypes, u_AgentGenome, u_SimEventTypes, u_SimPopulations;

type
  TAgentViewerFrame = class(TFrame)
    edtAgentIds: TLabeledEdit;
    AgentList: TControlList;
    btnApply: TSpeedButton;
    lblAgentId: TLabel;
    procedure btnApplyClick(Sender: TObject);
    procedure AgentListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
  public type
    TDataRequiredEvent = procedure (Sender: TObject; AgentId: TAgentId; out Found: Boolean; out Data: TMetabolicState) of object;
  private type
    TAgentEntry = record
      Id: TAgentId;
      State: TMetabolicState;
    end;
  private
    fOnDataRequired: TDataRequiredEvent;
    fAgents: TArray<TAgentEntry>;
  public
    procedure UpdateDisplay;
    property OnDataRequired: TDataRequiredEvent read fOnDataRequired write fOnDataRequired;
  end;

implementation

{$R *.dfm}

uses
  u_DiagnosticsHelpers;


procedure TAgentViewerFrame.AgentListBeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  if AgentList.ItemIndex <= High(fAgents) then
  begin
    var fields := fAgents[AIndex].State.AsFields;
    lblAgentId.Caption := Format('%.02d %s', [
      fAgents[AIndex].Id,
      fields.AsFieldText]);


  end;
end;

procedure TAgentViewerFrame.btnApplyClick(Sender: TObject);
begin
  var s: string := edtAgentIds.Text;
  var parts := s.Split([',', ' ']);

  // parse the text and come up with a list of ids
  var agentIdList := TList<TAgentId>.Create;
  try
    for var part in parts do
    begin
      var id: TAgentId := StrToIntDef(part, 0);
      if id > 0 then
        agentIdList.Add(id);
    end;

    // now allocate/init storage
    SetLength(fAgents, agentIdList.Count);
    for var i := 0 to High(fAgents) do
    begin
      fAgents[i].Id := agentIdList[i];
      fAgents[i].State := Default(TMetabolicState);
    end;
    AgentList.ItemCount := Length(fAgents);

  finally
    agentIdList.Free;
  end;
  UpdateDisplay;
end;

procedure TAgentViewerFrame.UpdateDisplay;
begin
  if Assigned(fOnDataRequired) then
  begin
    for var index := 0 to High(fAgents) do
    begin
      var state := Default(TMetabolicState);
      var found := False;
      fOnDataRequired(Self, fAgents[index].Id, found, state);
      if found then
        fAgents[index].State := state;
    end;
  end;

  AgentList.ItemIndex := -1;
  AgentList.Invalidate;
end;

end.
