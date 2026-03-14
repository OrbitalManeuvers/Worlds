unit fr_SimFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.StdCtrls, Vcl.ExtCtrls,

  u_EnvironmentLibraries, u_SimVisualizer, u_Simulators, u_SimLoggers,
  Vcl.Samples.Spin;

type
  TSimFrame = class(TContentFrame)
    cmbRegions: TComboBox;
    btnStep: TButton;
    LogMemo: TMemo;
    btnStart: TButton;
    spStepCount: TSpinEdit;
    pbVisualizer: TPaintBox;
    spnSubstanceIndex: TSpinEdit;
    Label1: TLabel;
    Button1: TButton;
    procedure btnStartClick(Sender: TObject);
    procedure btnStepClick(Sender: TObject);
    procedure spnSubstanceIndexChange(Sender: TObject);
  private
    simulator: TSimulator;
    logger: TSimLogger;
    visualizer: TSubstanceVisualizer;
    procedure Log(const msg: string);
    procedure HandleLogEvent(Sender: TLogger; const aMsg: string);
    procedure BeginLogWrite(Sender: TObject);
    procedure EndLogWrite(Sender: TObject);

  public
    procedure Init; override;
    procedure Done; override;
    procedure ActivateContent; override;
  end;


implementation

{$R *.dfm}

uses System.Types,
  u_SimUpscalers, u_SimRuntimes, u_SimParams,
  u_Regions;

{ TSimFrame }

procedure TSimFrame.Init;
begin
  inherited;

  cmbRegions.Items.BeginUpdate;
  try
    cmbRegions.Items.Clear;

    for var i := 0 to WorldLibrary.RegionCount - 1 do
    begin
      var region := WorldLibrary.Regions[i];
      cmbRegions.Items.AddObject(region.Name, region);
    end;

    if cmbRegions.Items.Count > 0 then
      cmbRegions.ItemIndex := 0;

  finally
    cmbRegions.Items.EndUpdate;
  end;

  btnStart.Enabled := cmbRegions.ItemIndex <> -1;
  btnStep.Enabled := False;
  simulator := TSimulator.Create;

  logger := TSimLogger.Create(simulator);
  logger.OnLog := HandleLogEvent;
  logger.OnBeginOutput := BeginLogWrite;
  logger.OnEndOutput := EndLogWrite;

  visualizer := TSubstanceVisualizer.Create;
  visualizer.Simulator := simulator;
  visualizer.DisplayMode := sdmFill;

end;

procedure TSimFrame.Done;
begin
  logger.free;
  simulator.Free;
  visualizer.Free;
  inherited;
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
const
  colors: array[0..3] of TColor = (clSkyBlue, clMoneyGreen, clWebOrange, clWebGold);
begin
  var newIndex := spnSubstanceIndex.Value;
  visualizer.Color := colors[newIndex];
  visualizer.SubstanceIndex := newIndex;

end;

procedure TSimFrame.ActivateContent;
begin
  inherited;
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

procedure TSimFrame.btnStartClick(Sender: TObject);
begin
  btnStart.Enabled := False;

  var upscaler := simulator.Upscaler();

  var index := cmbRegions.ItemIndex;
  var region := cmbRegions.Items.Objects[index] as TRegion;
  upscaler.UpscaleRegion(region, 8, WorldLibrary);

  spnSubstanceIndex.MinValue := 0;
  spnSubstanceIndex.MaxValue := Length(simulator.Runtime.Environment.Substances);
  spnSubstanceIndex.Value := 0;

  visualizer.PaintBox := pbVisualizer;
  visualizer.Color := clSkyBlue;

  btnStep.Enabled := True;
  pbVisualizer.Invalidate;

  LogMemo.Clear;
  Log('Upscale of ' + region.Name + ' completed.');
  Log('Food caches: ' + simulator.Runtime.Environment.ResourceCount.ToString);

  Log('Substances:');
  logger.LogSubstances;

end;

procedure TSimFrame.btnStepClick(Sender: TObject);
begin

  LogMemo.Lines.BeginUpdate;
  try
    for var stepIndex := 1 to spStepCount.Value do
    begin
      simulator.Clock.Step;
      for var x := 4 to 4 do
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
