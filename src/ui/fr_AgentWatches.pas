unit fr_AgentWatches;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.ControlList, Vcl.Buttons, Vcl.StdCtrls,

  u_SimEventTypes, u_AgentTypes;

type
  TWatchOption = (woTrackOffspring);
  TWatchOptions = set of TWatchOption;

  TAgentWatchFrame = class(TFrame, ISimEventConsumer)
    WatchList: TControlList;
    Shape1: TShape;
    lblAgentId: TLabel;
    edtAgentList: TEdit;
    Label2: TLabel;
    btnUpdateAgents: TSpeedButton;
    lblReserves: TLabel;
    lblMoleculeWeights: TLabel;
    procedure edtAgentListKeyPress(Sender: TObject; var Key: Char);
    procedure btnUpdateAgentsClick(Sender: TObject);
    procedure WatchListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
  private
    procedure Consume(const Event: TSimEvent);
    procedure UpdateAgentList;
    procedure EnsureWatch(AgentId: TAgentId; Options: TWatchOptions);
  public
    //
  end;

implementation

{$R *.dfm}



//["fec5bb","fcd5ce","fae1dd","f8edeb","e8e8e4","d8e2dc","ece4db","ffe5d9","ffd7ba","fec89a"]


{ TAgentWatchFrame }

procedure TAgentWatchFrame.btnUpdateAgentsClick(Sender: TObject);
begin
  UpdateAgentList;
end;

procedure TAgentWatchFrame.Consume(const Event: TSimEvent);
begin
  //
  var wanted: TSimEventKinds := [sekDecisionTrace, sekAgentBorn];
  if Event.Header.Kind in wanted then
  begin

    // look for watch record and update

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

procedure TAgentWatchFrame.EnsureWatch(AgentId: TAgentId; Options: TWatchOptions);
begin
  // create if needed, or update options


end;

procedure TAgentWatchFrame.UpdateAgentList;
var
  adding: Boolean;
begin
  var line: string := edtAgentList.Text;
  adding := line.StartsWith('+');

  if adding then
    line := Copy(line, 1, line.Length);

  var parts := line.Split([',', '.', ' ']);
  if Length(parts) > 0 then
  begin
    if not adding then begin end; // clear the list

    for var i := 0 to High(parts) do
    begin
      var spec := parts[i];
      var opts: TWatchOptions := [];

      if spec.EndsWith('c', True) then
      begin
        SetLength(spec, spec.Length - 1);
        opts := [woTrackOffspring];
      end;

      var id := StrToIntDef(spec, -1);
      if id >= 0 then
      begin
        EnsureWatch(id, opts);
      end;
    end;
  end;
end;

procedure TAgentWatchFrame.WatchListBeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  //
end;

end.
