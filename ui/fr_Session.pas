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
    WorldList: TControlList;
    lblWorldName: TLabel;
    btnCreateSim: TButton;
    gbPopulation: TGroupBox;
    edtAgentCount: TLabeledEdit;
    procedure btnCreateSimClick(Sender: TObject);
    procedure WorldListItemClick(Sender: TObject);
    procedure WorldListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
  private
    fWorld: TWorld;
    fSessionParameters: TSessionParameters;

    procedure UpdateControls;
  public
    procedure Init; override;
    procedure Done; override;
    procedure ActivateContent; override;

    { This is the contract with the session creation: a world and params }
    property World: TWorld read fWorld;
    property SessionParameters: TSessionParameters read fSessionParameters;
  end;


implementation

{$R *.dfm}

uses System.Types, System.Math, Vcl.GraphUtil,
  u_SimParams, u_EditorTypes, u_Foods,
  u_Regions, u_AgentTypes, u_BiologyTypes, u_EnvironmentTypes,
  u_SimEnvironments, u_DiagnosticListeners, u_SimDiagnosticsIntf,
  u_WorldsMessages;

const
  DEFAULT_SEED = -1653628502;

var
  LogFormatSettings: TFormatSettings;


type
  TBooleanHelper = record helper for Boolean
    function LogStr: string;
  end;

  TSingleHelper = record helper for Single
    function LogStr: string;
  end;

  TFoodHelper = class helper for TFood
    function ToSubstance: TSubstance;
  end;


{ TBooleanHelper }
function TBooleanHelper.LogStr: string;
begin
  if Self then
    Result := 'T'
  else
    Result := 'F';
end;

{ TSingleHelper }

function TSingleHelper.LogStr: string;
begin
  Result := FloatToStrF(Self, ffFixed, 18, 3, LogFormatSettings);
end;


{ TFoodHelper }

function TFoodHelper.ToSubstance: TSubstance;
begin
  Result[Alpha] := Self.Recipe.Percents[Alpha];
  Result[Beta] := Self.Recipe.Percents[Beta];
  Result[Gamma] := Self.Recipe.Percents[Gamma];
  Result[Biomass] := 0;
end;

{ TSimFrame }

procedure TSessionFrame.Init;
begin
  inherited;
  fSessionParameters := Default(TSessionParameters);

  UpdateControls;
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
  var agentCount := StrToIntDef(edtAgentCount.Text, 0);
  btnCreateSim.Enabled := (WorldList.ItemIndex <> -1) and (agentCount > 0) and (agentCount < 100); // !!
end;

procedure TSessionFrame.ActivateContent;
begin
  inherited;

  if WorldLibrary.WorldCount <> WorldList.ItemCount then
  begin
    WorldList.ItemCount := WorldLibrary.WorldCount;
    if WorldList.ItemCount > 0 then
      WorldList.ItemIndex := 0;
  end;

  UpdateControls;
end;

procedure TSessionFrame.btnCreateSimClick(Sender: TObject);
begin
  PostMessage(Application.MainForm.Handle, WM_BEGIN_SIMULATION, 0, 0);
end;


initialization
  LogFormatSettings := TFormatSettings.Create;
  LogFormatSettings.DecimalSeparator := '.';

end.
