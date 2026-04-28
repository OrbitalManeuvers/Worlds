unit fr_SimFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.StdCtrls, Vcl.ExtCtrls,
  System.Generics.Collections,

  Vcl.Samples.Spin, Vcl.ControlList, Vcl.ComCtrls, Vcl.Buttons, Vcl.Mask,
  u_EnvironmentLibraries, u_SimVisualizer, u_Simulators,
  u_SimSessions, fr_ResourceVisualizer, u_SimWatches, u_SimRuntimes, u_SimPhases,
  u_SimUpscalers;

type
  TSimFrame = class(TContentFrame)
    AgentLog: TMemo;
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
    LogPages: TPageControl;
    tsAgentLog: TTabSheet;
    TabSheet2: TTabSheet;
    cbDebugSession: TCheckBox;
    CellLog: TMemo;
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

    procedure HandleLogEvent(Sender: TObject; const aMsg: string);
    procedure HandleSessionAfterStep(Sender: TObject);
    procedure HandleWatchChanged(Sender: TObject; Watch: TSimWatch);
    procedure HandleDebugSetup(Sender: TObject;  var Params: TDebugParameters);
    procedure HandleExternalLog(const aMsg: string);

    function FormatActionScores(const Trace: TDecisionTrace): string;
    function FormatDecisionTrace(const Trace: TDecisionTrace): string;

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
  u_SimParams, u_EditorTypes, u_Foods,
  u_Regions, u_AgentTypes, u_BiologyTypes, u_EnvironmentTypes,
  u_SimEnvironments, u_DiagnosticListeners, u_SimDiagnosticsIntf;

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

procedure TSimFrame.Init;
begin
  inherited;
  fViewers := TList<TResViewFrame>.Create;
  CreateViewer(phV1);
  CreateViewer(phV2);

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
  params.Seed := DEFAULT_SEED;
  params.Population.AgentCount := StrToIntDef(edtAgentCount.Text, 0);
  params.Population.Scheme := psOnSingleResource;
  params.DebugMode := cbDebugSession.Checked;


//  if WorldLibrary.RatingsCount > 0 then
//  begin
//    SetLength(params.Population.Rules, 1);
//    params.Population.Rules[0].Chance := 100;
//    params.Population.Rules[0].Target := rtConverter;
//    params.Population.Rules[0].Ratings := WorldLibrary.Ratings[0];
//  end;

  var world := WorldLibrary.Worlds[WorldList.ItemIndex];

  { allocation }
  fSession := TSimSession.Create(world, params, WorldLibrary);
  fSession.OnLog := HandleLogEvent;
  fSession.OnAfterStep := HandleSessionAfterStep;
  fSession.OnWatchChange := HandleWatchChanged;
  fSession.OnDebugSetup := HandleDebugSetup;

  // attempt to set the wheels in motion
  try
    fSession.BeginSession;

    edtSeedName.Text := IntToStr(fSession.Seed);


    fSession.AddAgentWatch(0);
//    fSession.AddAgentWatch(1);

    // add a cell watch that follows agent 0 across moves
//    fSession.AddFollowingCellWatch(0, -1, nil, [stpPostEnvironment, stpPostAgents], cemAlways);

    // add a fixed comparison watch where the agent started
//    var loc := fSession.Simulator.Runtime.Population.Agents[0].Location;
//
//    fSession.AddCellWatch(loc - 1, -1, nil, [stpPostEnvironment, stpPostAgents], cemAlways);
//    fSession.AddCellWatch(loc + 1, -1, nil, [stpPostEnvironment, stpPostAgents], cemAlways);


    // Prime baseline snapshots before first step so tick-1 deltas reflect true initial state.
    fSession.PrimeWatches;

//    for var cellIndex := 0 to Length(fSession.Simulator.Runtime.Environment.Cells) - 1 do
//      if fSession.Simulator.Runtime.Environment.Cells[cellIndex].ResourceCount > 0 then
//      begin
//        fSession.AddCellWatch(cellIndex);
//        Break;
//      end;


  except
    on E: Exception do
    begin
      DoneSession;
      ShowException(E, nil);
      Exit;
    end;
  end;




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

  var agentListener := TAgentListener.Create;
  agentListener.OnLog := HandleExternalLog;

//  TSimEventFilter = record
//    Kinds: TSimEventKinds;
//    AgentId: Integer;
//    CellIndex: Integer;
//  end;
  var filter: TSimEventFilter;
  filter.Kinds := [sekAgentMoved, sekAgentBorn];
  filter.AgentId := -1;
  filter.CellIndex := -1;

  fSession.Diagnostics.Subscribe(filter, agentListener)

end;

procedure TSimFrame.HandleExternalLog(const aMsg: string);
begin
  AgentLog.Lines.Add('[ ' + aMsg + ' ]');
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
  AgentLog.Lines.Add(aMsg);
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

function TSimFrame.FormatActionScores(const Trace: TDecisionTrace): string;
  function CacheToShortStr(const Cache: TCacheRef): string;
  begin
    case Cache.Kind of
      ckResource:
        Result := 'Resource:' + Cache.Index.ToString;
      ckBiomass:
        Result := 'Biomass:' + Cache.Index.ToString;
    end;
  end;

  function TargetToShortStr(const Target: TTarget): string;
  begin
    case Target.TType of
      ttCell:
        Result := 'Cell:' + Target.Cell.ToString;
      ttCache:
        Result := CacheToShortStr(Target.Cache);
    else
      Result := 'None';
    end;
  end;
begin
  Result := Format(
    '    Scores M:%s(%s) F:%s(%s) S:%s(%s) R:%s(%s) I:%s(%s)',
    [
      Trace.Evaluations[acMove].Score.LogStr,
      TargetToShortStr(Trace.Evaluations[acMove].Target),
      Trace.Evaluations[acForage].Score.LogStr,
      TargetToShortStr(Trace.Evaluations[acForage].Target),
      Trace.Evaluations[acShelter].Score.LogStr,
      TargetToShortStr(Trace.Evaluations[acShelter].Target),
      Trace.Evaluations[acReproduce].Score.LogStr,
      TargetToShortStr(Trace.Evaluations[acReproduce].Target),
      Trace.Evaluations[acIdle].Score.LogStr,
      TargetToShortStr(Trace.Evaluations[acIdle].Target)
    ]
  );
end;

function TSimFrame.FormatDecisionTrace(const Trace: TDecisionTrace): string;

  function CacheToShortStr(const Cache: TCacheRef): string;
  begin
    case Cache.Kind of
      ckResource:
        Result := 'Resource:' + Cache.Index.ToString;
      ckBiomass:
        Result := 'Biomass:' + Cache.Index.ToString;
    end;
  end;

  function ActionToShortStr(aAction: TAgentAction): string;
  const
    action_strs: array[TAgentAction] of string = ('Move', 'Forage', 'Shelter', 'Repro', 'Idle');
  begin
    Result := action_strs[aAction];
  end;

  function TargetToShortStr(const Target: TTarget): string;
  begin
    case Target.TType of
      ttCell:
        Result := 'Cell:' + Target.Cell.ToString;
      ttCache:
        Result := CacheToShortStr(Target.Cache);
    else
      Result := 'None';
    end;
  end;

  function EnergyLevelToStr(aEnergyLevel: TEnergyLevel): string;
  const
    energy_strs: array[TEnergyLevel] of string = ('Empty', 'Low', 'Medium', 'High', 'Full');
  begin
    Result := energy_strs[aEnergyLevel];
  end;
begin
  Result := Format(
    '    Trace Req:%s(%s) Res:%s(%s) Night:%s Flux:%s dFlux:%s Energy:%s TSR:%d Local:%d SmellMax:%s SmellTop:[N:%d C:%s D:%d S:%s] Threat:%s Smell:%s Sight:%s Conv:[In:%s Out:%s Eff:%s]',
    [
      ActionToShortStr(Trace.RequestedAction),
      TargetToShortStr(Trace.RequestedTarget),
      ActionToShortStr(Trace.ResolvedAction),
      TargetToShortStr(Trace.ResolvedTarget),
      Trace.IsNight.LogStr,
      Trace.Summary.SolarFlux.LogStr,
      Trace.Summary.SolarFluxDelta.LogStr,
      EnergyLevelToStr(Trace.Summary.EnergyLevel),
      Trace.Summary.TicksSinceReproduction,
      Trace.Summary.LocalAgentCount,
      // SmellMax
      Trace.Summary.StrongestSmellSignal.LogStr,
      // SmellTop
      Trace.Summary.SmellCandidateCount,   // N:
      CacheToShortStr(Trace.Summary.TopSmellCache), // C:
      Trace.Summary.TopSmellDistance,      // D:
      Trace.Summary.TopSmellSignal.LogStr, // S:
      //
      Trace.Summary.ThreatPressure.LogStr,
      Trace.Summary.HadSmellTarget.LogStr,
      Trace.Summary.HadSightTarget.LogStr,
      Trace.ForageConsumed.LogStr,
      Trace.ForageGain.LogStr,
      Trace.ForageEfficiency.LogStr
    ]
  );
end;

procedure TSimFrame.HandleWatchChanged(Sender: TObject; Watch: TSimWatch);
  function PhaseToShortStr(const Phase: TSimTickPhase): string;
  begin
    case Phase of
      stpPostEnvironment:
        Result := 'PreA';
      stpPostAgents:
        Result := 'PostA';
    else
      Result := '?';
    end;
  end;
begin
  var dayNumber := fSession.simulator.Clock.DayNumber;
  var dayTick := fSession.simulator.Clock.DayTick;
  var phaseStr := PhaseToShortStr(Watch.LastPhase);

  if Watch is TAgentWatch then
  begin
    var w := TAgentWatch(Watch);
    var actionStr := w.ActionToStr(w.LastChange.CurrentState.Action);

    var line := Format(
      '[%.2d:%.3d %s] A:%d C:%d R:%s D:%s  (%s)',
      [
        dayNumber,
        dayTick,
        phaseStr,
        w.AgentIndex,
        w.LastChange.PreviousState.Location,
        w.LastChange.CurrentState.Reserves.LogStr,
        Single(w.LastChange.CurrentState.Reserves - w.LastChange.PreviousState.Reserves).LogStr,
        actionStr
      ]
    );
    AgentLog.Lines.Add(line);

    var trace: TDecisionTrace;
    if fSession.Simulator.Runtime.TryGetLastDecision(w.AgentIndex, trace) then
    begin
      AgentLog.Lines.Add(FormatActionScores(trace));
      AgentLog.Lines.Add(FormatDecisionTrace(trace));
    end;
  end
  else if Watch is TCellWatch then
  begin
    var c := TCellWatch(Watch);

    var line := Format(
      '[%.2d:%.3d %s] C:%d CA:%s DA:%s  CD:%s DD:%s',
      [
        dayNumber,
        dayTick,
        phaseStr,
        c.CellIndex,
        c.LastChange.CurrentAmount.LogStr,
        Single(c.LastChange.CurrentAmount - c.LastChange.PreviousAmount).LogStr,
        c.LastChange.CurrentDebt.LogStr,
        Single(c.LastChange.CurrentDebt - c.LastChange.PreviousDebt).LogStr
      ]
    );
    CellLog.Lines.Add(line);

    var env := fSession.Simulator.Runtime.Environment;
    if (c.CellIndex >= 0) and (c.CellIndex < Length(env.Cells)) then
    begin
      var cell := env.Cells[c.CellIndex];
      if cell.ResourceCount > 0 then
      begin
        var cacheLine := '    Caches';
        for var i := 0 to cell.ResourceCount - 1 do
        begin
          var cacheIndex := Integer(cell.ResourceStart) + i;
          if (cacheIndex < 0) or (cacheIndex >= Length(env.Resources)) then
            Continue;

          var cache := env.Resources[cacheIndex];
          cacheLine := cacheLine + Format(' [#%d SI:%d A:%s D:%s]', [
            cacheIndex,
            cache.SubstanceIndex,
            cache.Amount.LogStr,
            cache.RegenDebt.LogStr
          ]);
        end;

        CellLog.Lines.Add(cacheLine);
      end;
    end;
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
  AgentLog.Clear;
  InitSession;
end;

procedure TSimFrame.btnStepClick(Sender: TObject);
begin
  if not (Sender is TComponent) then
    Exit;
  var count := Max(1, TComponent(Sender).Tag);

  AgentLog.Lines.BeginUpdate;
  try
    for var stepIndex := 1 to count do
    begin
      fSession.Step;
      lblTime.Caption := Format('%.02d:%.03d', [fSession.simulator.Clock.DayNumber, fSession.simulator.Clock.DayTick]);
    end;

  finally
    AgentLog.Lines.EndUpdate;
  end;

  AgentLog.SelStart := Length(AgentLog.Text);
  AgentLog.SelLength := 0;
  AgentLog.Perform(EM_SCROLLCARET, 0, 0);
end;

procedure TSimFrame.HandleDebugSetup(Sender: TObject; var Params: TDebugParameters);
begin
  Params.Dimensions.cx := 256;
  Params.Dimensions.cy := 256;
  Params.DefaultSunlight := Normal;
  Params.DefaultMobility := Normal;

  var A100 := WorldLibrary.FindFood('A100');
  Assert(Assigned(A100));
  Params.AddFood(A100);

  var B100 := WorldLibrary.FindFood('B100');
  Assert(Assigned(B100));
  Params.AddFood(B100);

  // place two caches
  Params.AddResource(Point(10, 10), A100, Normal);
  Params.AddResource(Point(12, 10), B100, Normal);

  var loc := TPoint.Create(14, 10);

//  var smellRatings := WorldLibrary.FindRatings('OnlyBeta');
//  Assert(Assigned(smellRatings));
//  Params.AddAgent(loc, nil, smellRatings);
  Params.AddAgent(loc, nil, nil);



end;


initialization
  LogFormatSettings := TFormatSettings.Create;
  LogFormatSettings.DecimalSeparator := '.';

end.
