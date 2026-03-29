unit fr_SimFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.StdCtrls, Vcl.ExtCtrls,
  System.Generics.Collections,

  Vcl.Samples.Spin, Vcl.ControlList, Vcl.ComCtrls, Vcl.Buttons, Vcl.Mask,
  u_EnvironmentLibraries, u_SimVisualizer, u_Simulators, u_SimLoggers,
  u_SimSessions, fr_ResourceVisualizer;

type
  TSimFrame = class(TContentFrame)
    LogMemo: TMemo;
    btnCreateSim: TButton;
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
    lblWorldName: TLabel;
    gbPopulation: TGroupBox;
    edtAgentCount: TLabeledEdit;
    btnClose: TButton;
    phV1: TShape;
    phV2: TShape;
    procedure btnCreateSimClick(Sender: TObject);
    procedure btnStepClick(Sender: TObject);
    procedure WorldListItemClick(Sender: TObject);
    procedure WorldListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure btnCloseClick(Sender: TObject);
  private
    fSession: TSimSession;
    fViewers: TList<TResViewFrame>;

    fLogger: TSimLogger;
    fVisualizer: TSubstanceVisualizer;
    procedure Log(const msg: string);
    procedure HandleLogEvent(Sender: TLogger; const aMsg: string);
    procedure BeginLogWrite(Sender: TObject);
    procedure EndLogWrite(Sender: TObject);
    procedure UpdateControls;

    procedure InitSession;
    procedure DoneSession;
    function CreateViewer(aPlaceholder: TShape): TResViewFrame;
    procedure HandleViewerPaint(Sender: TObject);

  public
    procedure Init; override;
    procedure Done; override;
    procedure ActivateContent; override;
  end;


implementation

{$R *.dfm}

uses System.Types, System.Math, Vcl.GraphUtil,
  u_SimUpscalers, u_SimRuntimes, u_SimParams, u_EditorTypes,
  u_Regions;

{ TSimFrame }

procedure TSimFrame.Init;
begin
  inherited;
  fViewers := TList<TResViewFrame>.Create;
  var f := CreateViewer(phV1);
  f := CreateViewer(phV2);



//  fVisualizer := TResVisFrame.Create(Self);
//  fVisualizer.Parent := Self;
//  fVisualizer.BoundsRect := Shape1.BoundsRect;

  Pages.ActivePage := tsNoSelection;
  UpdateControls;
end;

procedure TSimFrame.Done;
begin
  DoneSession;
  inherited;
end;

function TSimFrame.CreateViewer(aPlaceholder: TShape): TResViewFrame;
begin
  aPlaceholder.Visible := False;

  Result := TResViewFrame.Create(Self);
  Result.Name := 'resview' + fViewers.Count.ToString;
  Result.IsActive := False;
  Result.Parent := aPlaceholder.Parent;
  Result.BoundsRect := aPlaceholder.BoundsRect;
  Result.Visible := True;
  Result.OnPaint := HandleViewerPaint;
  fViewers.Add(Result);
end;

procedure TSimFrame.InitSession;
begin
  Pages.ActivePage := tsSelection;

  // convert UI settings to sim params
  var params: TSimParams;
  params.InitDefaults;
  params.Population.AgentCount := StrToIntDef(edtAgentCount.Text, 1);

  var world := WorldLibrary.Worlds[WorldList.ItemIndex];

  { allocation }
  fSession := TSimSession.Create(world, params, WorldLibrary);

  { allocation }
  fLogger := TSimLogger.Create(fSession.Simulator);
  fLogger.OnLog := HandleLogEvent;
  fLogger.OnBeginOutput := BeginLogWrite;
  fLogger.OnEndOutput := EndLogWrite;

  // attempt to set the wheels in motion
  try
    fSession.BeginSession;
  except
    on E: Exception do
    begin
      DoneSession;
      ShowException(E, nil);
      Exit;
    end;
  end;

  Log('Session created using ' + world.Name);

  Log('Substances:');
  fLogger.LogSubstances;

  fVisualizer := TSubstanceVisualizer.Create;
  fVisualizer.Simulator := fSession.Simulator;

  var foodNames := TStringList.Create(dupAccept, False, False);
  try
    for var food in fSession.Foods do
      foodNames.Add(food.Name);

    // connect the substance viewer frames
    for var viewer in fViewers do
    begin
      viewer.IsActive := True;
      viewer.SubstanceNames := foodNames;
      viewer.OnPaint := HandleViewerPaint;
    end;

  finally
    foodNames.Free;
  end;

end;

procedure TSimFrame.DoneSession;
begin
  Pages.ActivePage := tsNoSelection;
  if Assigned(fSession) then
  begin
    for var view in fViewers do
      view.IsActive := False;

    fSession.EndSession;

    fVisualizer.Free;
    fVisualizer := nil;

    fLogger.Free;
    fLogger := nil;

    fSession.Free;
    fSession := nil;
  end;
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

procedure TSimFrame.HandleLogEvent(Sender: TLogger; const aMsg: string);
begin
  Log(aMsg);
end;

procedure TSimFrame.HandleViewerPaint(Sender: TObject);
const
  FOOD_COLORS: array[0..5] of TColor = (clWebDodgerBlue, clWebDarkSeaGreen, clWebDarkKhaki, clWebGold, clWebTomato, clWebSienna);
begin
  if not (Sender is TResViewFrame) then
    Exit;

  var view := TResViewFrame(Sender);
  fVisualizer.ZoomLevel := TVisualizerZoom(view.ZoomFactor);
  fVisualizer.SubstanceIndex := view.SubstanceIndex;

  var food := fSession.Foods[view.SubstanceIndex];
  var foodColor: TColor := FOOD_COLORS[view.SubstanceIndex];

//  food.Recipe.Percents[]
//   MOLECULE_COLORS: array[TMolecule] of string = ('#6FA8DC', '#93C47D', '#E69138', '#D3A29C');


  fVisualizer.Paint(view.Canvas, foodColor);
end;

procedure TSimFrame.Log(const msg: string);
begin
  LogMemo.Lines.Add(msg);
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
  DoneSession;
end;

procedure TSimFrame.btnCreateSimClick(Sender: TObject);
begin
  LogMemo.Clear;
  InitSession;

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
      fSession.simulator.Clock.Step;
      lblTime.Caption := Format('%.02d:%.03d', [fSession.simulator.Clock.DayNumber, fSession.simulator.Clock.DayTick]);
//      for var x := 3 to 3 do
//        fLogger.LogCell(point(x, 0));
    end;

    for var f in fViewers do
      f.pbVis.Invalidate;  // replace this with a public method

  finally
    LogMemo.Lines.EndUpdate;
  end;

  LogMemo.SelStart := Length(LogMemo.Text);
  LogMemo.SelLength := 0;
  LogMemo.Perform(EM_SCROLLCARET, 0, 0);
end;

end.
