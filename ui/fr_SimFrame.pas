unit fr_SimFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.StdCtrls, Vcl.ExtCtrls,

  Vcl.Samples.Spin, Vcl.ControlList, Vcl.ComCtrls, Vcl.Buttons, Vcl.Mask,
  u_EnvironmentLibraries, u_SimVisualizer, u_Simulators, u_SimLoggers,
  u_SimSessions;

type
  TSimFrame = class(TContentFrame)
    LogMemo: TMemo;
    btnCreateSim: TButton;
    pbVisualizer: TPaintBox;
    spnSubstanceIndex: TSpinEdit;
    Label1: TLabel;
    Pages: TPageControl;
    tsNoSelection: TTabSheet;
    tsSelection: TTabSheet;
    WorldList: TControlList;
    Label2: TLabel;
    gbControls: TGroupBox;
    lblClock: TLabel;
    lblTime: TLabel;
    btnStep1: TSpeedButton;
    btnStep5: TSpeedButton;
    btnStep10: TSpeedButton;
    spZoomLevel: TSpinButton;
    lblWorldName: TLabel;
    btnScrollUp: TSpeedButton;
    btnScrollRight: TSpeedButton;
    btnScrollLeft: TSpeedButton;
    btnScrollDown: TSpeedButton;
    gbPopulation: TGroupBox;
    edtAgentCount: TLabeledEdit;
    btnClose: TButton;
    procedure btnCreateSimClick(Sender: TObject);
    procedure btnStepClick(Sender: TObject);
    procedure spnSubstanceIndexChange(Sender: TObject);
    procedure spZoomLevelDownClick(Sender: TObject);
    procedure spZoomLevelUpClick(Sender: TObject);
    procedure pbVisualizerPaint(Sender: TObject);
    procedure WorldListItemClick(Sender: TObject);
    procedure WorldListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure ScrollClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    session: TSimSession;
//    simulator: TSimulator;
    logger: TSimLogger;
//    visualizer: TSubstanceVisualizer;
    function GetVisualizerColor: TColor;
    procedure Log(const msg: string);
    procedure HandleLogEvent(Sender: TLogger; const aMsg: string);
    procedure BeginLogWrite(Sender: TObject);
    procedure EndLogWrite(Sender: TObject);
    procedure UpdateControls;

    procedure InitSimulator;
    procedure DoneSimulator;
    procedure CloseSession;

  public
    procedure Init; override;
    procedure Done; override;
    procedure ActivateContent; override;
  end;


implementation

{$R *.dfm}

uses System.Types, System.Math,
  u_SimUpscalers, u_SimRuntimes, u_SimParams,
  u_Regions;

{ TSimFrame }

procedure TSimFrame.Init;
begin
  inherited;
  Pages.ActivePage := tsNoSelection;
  UpdateControls;
end;

procedure TSimFrame.Done;
begin
  DoneSimulator;
  inherited;
end;

procedure TSimFrame.InitSimulator;
begin
//  simulator := TSimulator.Create;

//  logger := TSimLogger.Create(simulator);
//  logger.OnLog := HandleLogEvent;
//  logger.OnBeginOutput := BeginLogWrite;
//  logger.OnEndOutput := EndLogWrite;
//
//  visualizer := TSubstanceVisualizer.Create;
//  visualizer.Simulator := simulator;
//  visualizer.DisplayMode := sdmFill;
end;

procedure TSimFrame.DoneSimulator;
begin
//  if Assigned(simulator) then
//  begin
//    visualizer.Free;
//    logger.free;
//    simulator.Free;
//    simulator := nil;
//  end;
end;

procedure TSimFrame.pbVisualizerPaint(Sender: TObject);
begin
//  visualizer.Paint(pbVisualizer.Canvas, GetVisualizerColor, pbVisualizer.ClientRect);
end;

procedure TSimFrame.WorldListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
  ARect: TRect; AState: TOwnerDrawState);
begin
  if (AIndex > -1) and (AIndex < WorldLibrary.WorldCount) then
    lblWorldName.Caption := WorldLibrary.Worlds[AIndex].Name;
end;

procedure TSimFrame.WorldListItemClick(Sender: TObject);
begin
  inherited;
  UpdateControls;
end;

procedure TSimFrame.ScrollClick(Sender: TObject);
begin
  if not (Sender is TComponent) then
    Exit;

  var dirFlag := TComponent(Sender).Tag;
  var dir := Point(0, 0);
  case dirFlag of
    1: dir.y := -1;
    2: dir.x := 1;
    3: dir.y := 1;
    4: dir.x := -1;
  end;

//  visualizer.PanByCells(dir);
//  pbVisualizer.Invalidate;
end;

function TSimFrame.GetVisualizerColor: TColor;
const
  Colors: array[0..3] of TColor = (clSkyBlue, clMoneyGreen, clWebOrange, clWebGold);
begin
  var idx := EnsureRange(spnSubstanceIndex.Value, Low(Colors), High(Colors));
  Result := Colors[idx];
end;

procedure TSimFrame.HandleLogEvent(Sender: TLogger; const aMsg: string);
begin
  Log(aMsg);
end;

procedure TSimFrame.Log(const msg: string);
begin
  LogMemo.Lines.Add(msg);
end;

procedure TSimFrame.spnSubstanceIndexChange(Sender: TObject);
begin
//  var newIndex := spnSubstanceIndex.Value;
//  visualizer.SubstanceIndex := newIndex;
//  pbVisualizer.Invalidate;
end;

procedure TSimFrame.spZoomLevelDownClick(Sender: TObject);
begin
//  if visualizer.ZoomLevel > Low(TVisualizerZoom) then
//  begin
//    visualizer.ZoomOut;
//    pbVisualizer.Invalidate;
//  end;
end;

procedure TSimFrame.spZoomLevelUpClick(Sender: TObject);
begin
//  if visualizer.ZoomLevel < High(TVisualizerZoom) then
//  begin
//    visualizer.ZoomIn;
//    pbVisualizer.Invalidate;
//  end;
end;

procedure TSimFrame.UpdateControls;
begin
  var agentCount := StrToIntDef(edtAgentCount.Text, 0);
  btnCreateSim.Enabled := (WorldList.ItemIndex <> -1) and (agentCount > 0) and (agentCount < 100); // !!
end;

procedure TSimFrame.ActivateContent;
begin
  inherited;

  if Pages.ActivePage = tsNoSelection then
  begin
    if WorldLibrary.WorldCount <> WorldList.ItemCount then
    begin
      WorldList.ItemCount := WorldLibrary.WorldCount;
      if WorldList.ItemCount > 0 then
        WorldList.ItemIndex := 0;
    end;
  end;

  UpdateControls;
end;

procedure TSimFrame.BeginLogWrite(Sender: TObject);
begin
  LogMemo.Lines.BeginUpdate;
end;

procedure TSimFrame.EndLogWrite(Sender: TObject);
begin
  LogMemo.Lines.EndUpdate;
  LogMemo.SelStart := Length(LogMemo.Text);
  LogMemo.SelLength := 0;
  LogMemo.Perform(EM_SCROLLCARET, 0, 0);
end;

procedure TSimFrame.btnCloseClick(Sender: TObject);
begin
  // stop the session
  CloseSession;
end;

procedure TSimFrame.CloseSession;
begin
  Pages.ActivePage := tsNoSelection;
  logger.Free;
  logger := nil;
  session.EndSession;
  session.Free;
  session := nil;
end;

procedure TSimFrame.btnCreateSimClick(Sender: TObject);
begin
  Pages.ActivePage := tsSelection;

  // convert UI settings to sim params
  var params: TSimParams;
  params.InitDefaults;
  params.Population.AgentCount := StrToIntDef(edtAgentCount.Text, 1);

  var world := WorldLibrary.Worlds[WorldList.ItemIndex];

  { allocation }
  session := TSimSession.Create(world, params, WorldLibrary);

  { allocation }
  logger := TSimLogger.Create(session.Simulator);
  logger.OnLog := HandleLogEvent;
  logger.OnBeginOutput := BeginLogWrite;
  logger.OnEndOutput := EndLogWrite;

  // attempt to set the wheels in motion
  try
    session.BeginSession;
  except
    on E: Exception do
    begin
      CloseSession;
      ShowException(E, nil);
      Exit;
    end;
  end;


//  // set up UI controls
//  spnSubstanceIndex.MinValue := 0;
//  spnSubstanceIndex.MaxValue := Length(simulator.Runtime.Environment.Substances);
//  spnSubstanceIndex.Value := 0;

  LogMemo.Clear;
  Log('Session created using ' + world.Name);

//  Log('Food caches: ' + simulator.Runtime.Environment.ResourceCount.ToString);

  Log('Substances:');
  logger.LogSubstances;

//  pbVisualizer.Invalidate;

end;

procedure TSimFrame.btnStepClick(Sender: TObject);
begin
  if not (Sender is TComponent) then
    Exit;
  var count := Max(1, TComponent(Sender).Tag);

  LogMemo.Lines.BeginUpdate;
  try
    for var stepIndex := 1 to count do
    begin
      session.simulator.Clock.Step;
      lblTime.Caption := Format('%.02d:%.03d', [session.simulator.Clock.DayNumber, session.simulator.Clock.DayTick]);
      for var x := 3 to 3 do
        logger.LogCell(point(x, 0));
    end;
//
//    pbVisualizer.Invalidate;

  finally
    LogMemo.Lines.EndUpdate;
  end;

  LogMemo.SelStart := Length(LogMemo.Text);
  LogMemo.SelLength := 0;
  LogMemo.Perform(EM_SCROLLCARET, 0, 0);
end;

end.
