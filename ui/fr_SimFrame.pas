unit fr_SimFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.StdCtrls, Vcl.ExtCtrls,

  u_EnvironmentLibraries, u_SimVisualizer, u_Simulators, u_SimLoggers,
  Vcl.Samples.Spin, Vcl.ControlList, Vcl.ComCtrls, Vcl.Buttons;

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
    RegionList: TControlList;
    Label2: TLabel;
    gbControls: TGroupBox;
    lblClock: TLabel;
    lblTime: TLabel;
    btnStep1: TSpeedButton;
    btnStep5: TSpeedButton;
    btnStep10: TSpeedButton;
    spZoomLevel: TSpinButton;
    lblRegionName: TLabel;
    btnScrollUp: TSpeedButton;
    btnScrollRight: TSpeedButton;
    btnScrollLeft: TSpeedButton;
    btnScrollDown: TSpeedButton;
    procedure btnCreateSimClick(Sender: TObject);
    procedure btnStepClick(Sender: TObject);
    procedure spnSubstanceIndexChange(Sender: TObject);
    procedure spZoomLevelDownClick(Sender: TObject);
    procedure spZoomLevelUpClick(Sender: TObject);
    procedure pbVisualizerPaint(Sender: TObject);
    procedure RegionListItemClick(Sender: TObject);
    procedure RegionListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure ScrollClick(Sender: TObject);
  private
    simulator: TSimulator;
    logger: TSimLogger;
    visualizer: TSubstanceVisualizer;
    function GetVisualizerColor: TColor;
    procedure Log(const msg: string);
    procedure HandleLogEvent(Sender: TLogger; const aMsg: string);
    procedure BeginLogWrite(Sender: TObject);
    procedure EndLogWrite(Sender: TObject);
    procedure UpdateControls;
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
  simulator := TSimulator.Create;

  logger := TSimLogger.Create(simulator);
  logger.OnLog := HandleLogEvent;
  logger.OnBeginOutput := BeginLogWrite;
  logger.OnEndOutput := EndLogWrite;

  visualizer := TSubstanceVisualizer.Create;
  visualizer.Simulator := simulator;
  visualizer.DisplayMode := sdmFill;

  Pages.ActivePage := tsNoSelection;
  UpdateControls;
end;

procedure TSimFrame.Done;
begin
  visualizer.Free;
  logger.free;
  simulator.Free;
  inherited;
end;

procedure TSimFrame.pbVisualizerPaint(Sender: TObject);
begin
  visualizer.Paint(pbVisualizer.Canvas, GetVisualizerColor, pbVisualizer.ClientRect);
end;

procedure TSimFrame.RegionListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
  ARect: TRect; AState: TOwnerDrawState);
begin
  if (AIndex > -1) and (AIndex < WorldLibrary.RegionCount) then
    lblRegionName.Caption := WorldLibrary.Regions[AIndex].Name;
end;

procedure TSimFrame.RegionListItemClick(Sender: TObject);
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

  visualizer.PanByCells(dir);
  pbVisualizer.Invalidate;
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
  var newIndex := spnSubstanceIndex.Value;
  visualizer.SubstanceIndex := newIndex;
  pbVisualizer.Invalidate;
end;

procedure TSimFrame.spZoomLevelDownClick(Sender: TObject);
begin
  if visualizer.ZoomLevel > Low(TVisualizerZoom) then
  begin
    visualizer.ZoomOut;
    pbVisualizer.Invalidate;
  end;
end;

procedure TSimFrame.spZoomLevelUpClick(Sender: TObject);
begin
  if visualizer.ZoomLevel < High(TVisualizerZoom) then
  begin
    visualizer.ZoomIn;
    pbVisualizer.Invalidate;
  end;
end;

procedure TSimFrame.UpdateControls;
begin
//  btnStart.Enabled := cmbRegions.ItemIndex <> -1;

  btnCreateSim.Enabled := RegionList.ItemIndex <> -1;
end;

procedure TSimFrame.ActivateContent;
begin
  inherited;

  if Pages.ActivePage = tsNoSelection then
  begin

    if WorldLibrary.RegionCount <> RegionList.ItemCount then
    begin
      RegionList.ItemCount := WorldLibrary.RegionCount;
      if RegionList.ItemCount > 0 then
        RegionList.ItemIndex := 0;
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

procedure TSimFrame.btnCreateSimClick(Sender: TObject);
begin
  Pages.ActivePage := tsSelection;

  var upscaler := simulator.Upscaler();

  var region := WorldLibrary.Regions[RegionList.ItemIndex];
  upscaler.UpscaleRegion(region, 8, WorldLibrary);

  // set up UI controls
  spnSubstanceIndex.MinValue := 0;
  spnSubstanceIndex.MaxValue := Length(simulator.Runtime.Environment.Substances);
  spnSubstanceIndex.Value := 0;


  LogMemo.Clear;
  Log('Upscale of ' + region.Name + ' completed.');
  Log('Food caches: ' + simulator.Runtime.Environment.ResourceCount.ToString);

  Log('Substances:');
  logger.LogSubstances;

  pbVisualizer.Invalidate;

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
      simulator.Clock.Step;
      lblTime.Caption := Format('%.02d:%.03d', [simulator.Clock.DayNumber, simulator.Clock.DayTick]);
      for var x := 3 to 3 do
        logger.LogCell(point(x, 0));
    end;

    pbVisualizer.Invalidate;

  finally
    LogMemo.Lines.EndUpdate;
  end;

  LogMemo.SelStart := Length(LogMemo.Text);
  LogMemo.SelLength := 0;
  LogMemo.Perform(EM_SCROLLCARET, 0, 0);

end;

end.
