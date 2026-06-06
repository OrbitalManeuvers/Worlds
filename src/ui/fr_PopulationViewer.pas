unit fr_PopulationViewer;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ControlList,
  Vcl.StdCtrls,

  u_SimPopulations, u_SimEventTypes;

type
  TPopulationViewFrame = class(TFrame, ISimEventConsumer)
    PopulationList: TControlList;
    lblDetail: TLabel;
    Label2: TLabel;
    lblCount: TLabel;
    lblPopulationCount: TLabel;
    lblReserves: TLabel;
    lblMoleculeWeights: TLabel;
    cbLivingOnly: TCheckBox;
    lblPressures: TLabel;
    lblAction: TLabel;
    procedure PopulationListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure cbLivingOnlyClick(Sender: TObject);
    procedure Consume(const aEvent: TSimEvent);
  private
    DisplayList: TArray<Integer>;
    Population: TSimPopulation;
    fSubscriptionId: Integer;
    procedure BuildDisplayList;
  public
    procedure Step;
    procedure Connect(aPopulation: TSimPopulation);
    property SubscriptionId: Integer read fSubscriptionId write fSubscriptionId;
  end;

implementation

{$R *.dfm}

uses System.Types,
  u_AgentTypes, u_EnvironmentTypes, u_DiagnosticsHelpers;

{ TPopulationViewFrame }
procedure TPopulationViewFrame.cbLivingOnlyClick(Sender: TObject);
begin
  BuildDisplayList;
end;

procedure TPopulationViewFrame.Connect(aPopulation: TSimPopulation);
begin
  Population := aPopulation;
  BuildDisplayList;
end;

procedure TPopulationViewFrame.BuildDisplayList;
begin
  var count := 0;

  if Assigned(Population) then
  begin
    if Length(DisplayList) <> Population.AgentCount then
      SetLength(DisplayList, Population.AgentCount);

    for var index := 0 to Population.AgentCount - 1 do
    begin
      var state := Population.StatePtr(index);
      if (not cbLivingOnly.Checked) or (state.Reserves > 0.0) then
      begin
        DisplayList[count] := index;
        Inc(count);
      end;
    end;
  end;

  SetLength(DisplayList, count);
  PopulationList.ItemCount := count;
  PopulationList.Invalidate;

  lblPopulationCount.Caption := Format('%.04d', [count]);
end;

procedure TPopulationViewFrame.Consume(const aEvent: TSimEvent);
begin
  // on death/birth, rebuild list
//  if aEvent.Header.Kind in [sekAgentBorn, sekAgentDied] then
//    BuildDisplayList;
end;

procedure TPopulationViewFrame.PopulationListBeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  if not Assigned(Population) then
    Exit;

  var state := Population.StatePtr(AIndex); // no data moves, just a pointer

  if state.Reserves <= 0.0 then
  begin
    lblDetail.Font.Color := clGrayText;
    lblReserves.Font.Color := clGrayText;
    lblMoleculeWeights.Font.Color := clGrayText;
    lblAction.Font.Color := clGrayText;
  end
  else
  begin
    lblDetail.Font.Color := clWhite;
    if state.ReserveDelta < 0.0 then
      lblReserves.Font.Color := clWebCoral
    else
      lblReserves.Font.Color := clWebLimeGreen;
    lblMoleculeWeights.Font.Color := clWebLightBlue;
    lblAction.Font.Color := clWebOrange;
  end;

  lblDetail.Caption := Format('%.03d (%s) %.04d', [
    state.AgentId,
    state.Location.AsText,
    state.Age
  ]);

  lblReserves.Caption := state.Reserves.AsText + ' (' + state.ReserveDelta.AsText + ')';
  lblMoleculeWeights.Caption := Format(
    'A:%s B:%s G:%s D:%s',
    [state.ForageMoleculeWeights[Alpha].AsText,
    state.ForageMoleculeWeights[Beta].AsText,
    state.ForageMoleculeWeights[Gamma].AsText,
    state.ForageMoleculeWeights[Delta].AsText]
  );

  lblPressures.Caption := Format('tsf:%.04d tsr:%.04d', [
    state.TicksSinceForage,
    state.TicksSinceReproduction
  ]);

  lblAction.Caption := state.Action.AsText;

end;

procedure TPopulationViewFrame.Step;
begin
  if Assigned(Population) then
    BuildDisplayList;
end;

end.
