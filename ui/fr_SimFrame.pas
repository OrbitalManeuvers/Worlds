unit fr_SimFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.StdCtrls, Vcl.ExtCtrls,
  System.Generics.Collections,

  Vcl.Samples.Spin, Vcl.ControlList, Vcl.ComCtrls, Vcl.Buttons, Vcl.Mask,
  u_EnvironmentLibraries, u_SimVisualizer, u_Simulators,
  u_SimSessions, fr_ResourceVisualizer, u_SimWatches;

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
    lblStep: TLabel;
    grpSeeds: TGroupBox;
    Label1: TLabel;
    edtSeedName: TEdit;
    btnSaveSeed: TSpeedButton;
    ViewerGridPanel: TGridPanel;
    procedure btnCreateSimClick(Sender: TObject);
    procedure btnStepClick(Sender: TObject);
    procedure WorldListItemClick(Sender: TObject);
    procedure WorldListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure btnCloseClick(Sender: TObject);
  private
    fSession: TSimSession;
    fViewers: TList<TResViewFrame>;

    fVisualizer: TSubstanceVisualizer;
//    procedure Log(const msg: string);

    procedure HandleLogEvent(Sender: TObject; const aMsg: string);
    procedure HandleSessionAfterStep(Sender: TObject);
    procedure HandleWatchChanged(Sender: TObject; Watch: TSimWatch);

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
  CreateViewer(phV1);
  CreateViewer(phV2);



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
const
  VIEWER_SIZE_X = 300;
  VIEWER_SIZE_Y = 330;
begin
  aPlaceholder.Visible := False;

  Result := TResViewFrame.Create(Self);
  Result.Name := 'resview' + fViewers.Count.ToString;
  Result.IsActive := False;
  Result.Width := VIEWER_SIZE_X;
  Result.Height := VIEWER_SIZE_Y;

  Result.Parent := ViewerGridPanel;

//  Result.Parent := aPlaceholder.Parent;
//  Result.BoundsRect := aPlaceholder.BoundsRect;

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
  fSession.OnLog := HandleLogEvent;
  fSession.OnAfterStep := HandleSessionAfterStep;
  fSession.OnWatchChange := HandleWatchChanged;

  // attempt to set the wheels in motion
  try
    fSession.BeginSession;

    var w := fSession.AddAgentWatch(0);

    // add a cell watch where the agent ended up
    var loc := fSession.Simulator.Runtime.Population.Agents[0].Location;
    var c := fSession.AddCellWatch(loc);


  except
    on E: Exception do
    begin
      DoneSession;
      ShowException(E, nil);
      Exit;
    end;
  end;

//  Log('Session created using ' + world.Name);

//  Log('Substances:');
//  fLogger.LogSubstances;

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

procedure TSimFrame.HandleLogEvent(Sender: TObject; const aMsg: string);
begin
  LogMemo.Lines.Add(aMsg);
end;

procedure TSimFrame.HandleSessionAfterStep(Sender: TObject);
begin
  for var viewer in fViewers do
    viewer.InvalidateView;
end;

procedure TSimFrame.HandleViewerPaint(Sender: TObject);
const
  // !! needs refactor
  FOOD_COLORS: array[0..5] of TColor = (clWebDodgerBlue, clWebDarkSeaGreen, clWebDarkKhaki, clWebGold, clWebTomato, clWebSienna);
begin
  if not (Sender is TResViewFrame) then
    Exit;

  var view := TResViewFrame(Sender);
  fVisualizer.ZoomLevel := TVisualizerZoom(view.ZoomFactor);
  fVisualizer.SubstanceIndex := view.SubstanceIndex;

  var foodColor: TColor := clLime;
  if view.SubstanceIndex <= High(FOOD_COLORS) then
    foodColor := FOOD_COLORS[view.SubstanceIndex];

  fVisualizer.Paint(view.Canvas, foodColor);
end;

procedure TSimFrame.HandleWatchChanged(Sender: TObject; Watch: TSimWatch);
begin

  if Watch is TAgentWatch then
  begin
    var w := TAgentWatch(Watch);
    var line := Format('[A%d] R:%4f ', [w.AgentId, w.LastChange.CurrentState.Reserves]);
    LogMemo.Lines.Add(line);
  end
  else if Watch is TCellWatch then
  begin
    var c := TCellWatch(Watch);
    var line := Format('[C%d] A:%4f', [c.CellIndex, c.LastChange.CurrentAmount]);
    LogMemo.Lines.Add(line);
  end;

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
      fSession.Step;
      lblTime.Caption := Format('%.02d:%.03d', [fSession.simulator.Clock.DayNumber, fSession.simulator.Clock.DayTick]);
    end;

  finally
    LogMemo.Lines.EndUpdate;
  end;

  LogMemo.SelStart := Length(LogMemo.Text);
  LogMemo.SelLength := 0;
  LogMemo.Perform(EM_SCROLLCARET, 0, 0);
end;

end.
