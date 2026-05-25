unit fr_Session;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.StdCtrls, Vcl.ExtCtrls,
  System.Generics.Collections,
  Vcl.Samples.Spin, Vcl.ControlList, Vcl.ComCtrls, Vcl.Buttons, Vcl.Mask,

  u_EnvironmentLibraries, u_SimVisualizer, u_Simulators,
  u_SimSessions, fr_ResourceVisualizer, u_SimWatches, u_SimRuntimes, u_SimPhases,
  u_SimUpscalers, u_SessionParameters, u_Worlds;

type
  TSessionFrame = class(TContentFrame)
    Label2: TLabel;
    btnCreateSim: TButton;
    pcPages: TPageControl;
    tsStandard: TTabSheet;
    tsDebug: TTabSheet;
    WorldList: TControlList;
    lblWorldName: TLabel;
    Label3: TLabel;
    seAgentCount: TSpinEdit;
    Label1: TLabel;
    Label4: TLabel;
    SeedList: TControlList;
    lblSeedName: TLabel;
    seScaleFactor: TSpinEdit;
    Label5: TLabel;
    ScenarioList: TControlList;
    Label6: TLabel;
    lblScenarioName: TLabel;
    GroupBox1: TGroupBox;
    edtSessionTitle: TEdit;
    Label8: TLabel;
    procedure btnCreateSimClick(Sender: TObject);
    procedure WorldListItemClick(Sender: TObject);
    procedure WorldListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure SeedListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure ScenarioListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure pcPagesChange(Sender: TObject);
  private
    fCommonParameters: TCommonSessionParameters;
    fUpscalerParameters: TUpscalerParameters;
    fDebugSessionParameters: TDebugSessionParameters;

    procedure UpdateControls;
    function BuildCommonParameters: TCommonSessionParameters;
  public
    procedure Init; override;
    procedure Done; override;
    procedure ActivateContent; override;
  end;


implementation

{$R *.dfm}

uses System.Types, System.Math, Vcl.GraphUtil,
  u_EditorTypes, u_Foods,
  u_Regions, u_AgentTypes, u_BiologyTypes, u_EnvironmentTypes,
  u_SimEnvironments, u_SimEventTypes,
  u_DebugLibraries, u_SessionManager;

{ TSimFrame }

procedure TSessionFrame.Init;
begin
  inherited;
  fCommonParameters := Default(TCommonSessionParameters);
  fUpscalerParameters := Default(TUpscalerParameters);
  fDebugSessionParameters := Default(TDebugSessionParameters);

  pcPages.ActivePage := tsStandard;

  UpdateControls;
end;

procedure TSessionFrame.pcPagesChange(Sender: TObject);
begin
  inherited;
  UpdateControls;
end;

procedure TSessionFrame.ScenarioListBeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  if (AIndex >= 0) and (AIndex < Length(DebugLibrary.Scenarios)) then
    lblScenarioName.Caption := DebugLibrary.Scenarios[AIndex].Name;
end;

procedure TSessionFrame.SeedListBeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  if (AIndex >= 0) and (AIndex < WorldLibrary.SeedCount) then
    lblSeedName.Caption := WorldLibrary.Seeds[AIndex].Name;
end;

procedure TSessionFrame.Done;
begin
  inherited;
end;

procedure TSessionFrame.WorldListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
  ARect: TRect; AState: TOwnerDrawState);
begin
  if (AIndex > -1) and (AIndex < WorldLibrary.WorldCount) then
    lblWorldName.Caption := WorldLibrary.Worlds[AIndex].Name;
end;

procedure TSessionFrame.WorldListItemClick(Sender: TObject);
begin
  inherited;
  UpdateControls;
end;

procedure TSessionFrame.UpdateControls;
begin

  var agentCount := seAgentCount.Value;

  // !! change eventually
  var valid := (agentCount < 10);

  if pcPages.ActivePage = tsStandard then
  begin
    valid := valid and (WorldList.ItemIndex >= 0);
  end
  else
  begin
    valid := valid and (ScenarioList.ItemIndex <> -1);
  end;

  btnCreateSim.Enabled := valid and SessionManager.Configured;
end;

procedure TSessionFrame.ActivateContent;
begin
  inherited;

  WorldList.ItemCount := WorldLibrary.WorldCount;
  if WorldList.ItemCount > 0 then
    WorldList.ItemIndex := 0;

  SeedList.ItemCount := WorldLibrary.SeedCount;
  if SeedList.ItemCount > 0 then
    Seedlist.ItemIndex := 0;

  ScenarioList.ItemCount := Length(DebugLibrary.Scenarios);
  if ScenarioList.ItemCount > 0 then
    ScenarioList.ItemIndex := 0;

  UpdateControls;
end;

function TSessionFrame.BuildCommonParameters: TCommonSessionParameters;
begin
  Result := Default(TCommonSessionParameters);

  if pcPages.ActivePage = tsStandard then
    Result.SessionType := stStandard
  else
    Result.SessionType := stDebug;
  Result.SessionTitle := edtSessionTitle.Text;
end;

procedure TSessionFrame.btnCreateSimClick(Sender: TObject);
begin
  if pcPages.ActivePage = tsStandard then
  begin
    fUpscalerParameters.World := WorldLibrary.Worlds[WorldList.ItemIndex];
    fUpscalerParameters.Factor := seScaleFactor.Value;

    fUpscalerParameters.Seed := 0;      // leaves RandSeed untouched
    if SeedList.ItemIndex >= 0 then
      fUpscalerParameters.Seed := WorldLibrary.Seeds[SeedList.ItemIndex].Value;

    // set up population
    fUpscalerParameters.Population.AgentCount := seAgentCount.Value;
    fUpscalerParameters.Population.Scheme := psGrouped;
    fUpscalerParameters.Population.GroupRect := Rect(0, 0, 2, 2);
    fUpscalerParameters.Population.AgentActivationTick := 7;

    SessionManager.SubmitStandardSession(BuildCommonParameters, fUpscalerParameters);

  end
  else if pcPages.ActivePage = tsDebug then
  begin
    fDebugSessionParameters.ScenarioName := DebugLibrary.Scenarios[ScenarioList.ItemIndex].Name;
    SessionManager.SubmitDebugSession(BuildCommonParameters, fDebugSessionParameters);
  end;
end;

end.
