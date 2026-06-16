unit fr_PopulationViewer;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ControlList,
  Vcl.StdCtrls,

  u_SimRuntimes, u_MulticastEvents, u_DiagnosticsIntf, u_SimDiagnostics;

type
  TPopulationViewFrame = class(TFrame, IRuntimeObserver, IDiagnosticsView)
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
  private
    { IRuntimeObserver }
    procedure ConnectRuntime(aRuntime: TSimRuntime; aDiagnostics: TSimDiagnosticsHub;
      AfterAdvance: TMulticastEvent<TNotifyEvent>);
    procedure DisconnectRuntime(aRuntime: TSimRuntime; aDiagnostics: TSimDiagnosticsHub;
      AfterAdvance: TMulticastEvent<TNotifyEvent>);

    { IDiagnosticsView }
    procedure BeginRun;
    procedure EndRun;
  private
    Runtime: TSimRuntime;
    fRunning: Boolean;
    DisplayList: TArray<Integer>;
    procedure HandleAfterAdvance(Sender: TObject);
    procedure BuildDisplayList;
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

procedure TPopulationViewFrame.BuildDisplayList;
begin
  var count := 0;

  if Assigned(Runtime) then
  begin
    if Length(DisplayList) <> Runtime.Population.AgentCount then
      SetLength(DisplayList, Runtime.Population.AgentCount);

    for var index := 0 to Runtime.Population.AgentCount - 1 do
    begin
      var state := Runtime.Population.StatePtr(index);
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

procedure TPopulationViewFrame.ConnectRuntime(aRuntime: TSimRuntime;
  aDiagnostics: TSimDiagnosticsHub; AfterAdvance: TMulticastEvent<TNotifyEvent>);
begin
  Runtime := aRuntime;
  AfterAdvance.Subscribe(HandleAfterAdvance);
end;

procedure TPopulationViewFrame.DisconnectRuntime(aRuntime: TSimRuntime;
  aDiagnostics: TSimDiagnosticsHub; AfterAdvance: TMulticastEvent<TNotifyEvent>);
begin
  Runtime := nil;
  AfterAdvance.Unsubscribe(HandleAfterAdvance);
  BuildDisplayList;
end;

procedure TPopulationViewFrame.HandleAfterAdvance(Sender: TObject);
begin
  if fRunning then
    Exit;

  BuildDisplayList;
end;

procedure TPopulationViewFrame.BeginRun;
begin
  fRunning := True;
end;

procedure TPopulationViewFrame.EndRun;
begin
  fRunning := False;
  BuildDisplayList;
end;

procedure TPopulationViewFrame.PopulationListBeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  if not Assigned(Runtime) then
    Exit;

  var state := Runtime.Population.StatePtr(AIndex); // no data moves, just a pointer

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
    [state.Genome.ForageMoleculeWeights[Alpha].AsText,
    state.Genome.ForageMoleculeWeights[Beta].AsText,
    state.Genome.ForageMoleculeWeights[Gamma].AsText,
    state.Genome.ForageMoleculeWeights[Delta].AsText]
  );

  lblPressures.Caption := Format('tsf:%.04d tsr:%.04d cp:%s', [
    state.TicksSinceForage,
    state.TicksSinceReproduction,
    state.CircadianPressure.AsText
  ]);

  lblAction.Caption := state.Action.AsText;

end;


end.
