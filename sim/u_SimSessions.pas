unit u_SimSessions;

interface

uses System.Classes, System.Types, System.Generics.Collections,
 u_Simulators, u_SimWatches, u_SimPhases,
 u_SimDiagnostics, u_SimDiagnosticsIntf,
 u_SimControllers, u_EventSinkIntf;

type
  TSimSession = class
  private
    fDiagnostics: TSimDiagnosticsHub;
    fSim: TSimulator;
    fWatches: TObjectList<TSimWatch>;
    fNextWatchId: Integer;
    fOnWatchChange: TWatchChangedEvent;
    fController: TSimController;
    fControllerDiagnosticsSubscriptionId: Integer;

    fSampleRangeStart: Integer;
    fSampleRangeCount: Integer;

    fEventSink: IEventSink; // !! consider passing in and owning externally

    procedure EvaluateWatches(const Phase: TSimTickPhase);
    procedure HandleRuntimePhase(Sender: TObject; Phase: TSimTickPhase);
    procedure HandleControllerBeforeAdvance(Sender: TObject);
    procedure HandleControllerAfterAdvance(Sender: TObject);
    procedure PrimePendingWatches;
    procedure UpdateWatchBindings;
    function RegisterWatch(AWatch: TSimWatch): TSimWatch;
  public
    constructor Create(aSim: TSimulator);
    destructor Destroy; override;

    procedure BeginSession;
    procedure EndSession;
    procedure PrimeWatches;
    property Controller: TSimController read fController;

    function AddAgentWatch(AgentIndex: Integer; const Callback: TWatchChangedEvent = nil;
      const Phases: TSimTickPhases = [stpPostAgents]): TAgentWatch;
    function AddCellWatch(CellIndex: Integer; SubstanceIndex: Integer = -1;
      const Callback: TWatchChangedEvent = nil;
      const Phases: TSimTickPhases = [stpPostAgents];
      const EmitMode: TCellWatchEmitMode = cemOnChange): TCellWatch;
    function AddFollowingCellWatch(AgentIndex: Integer; SubstanceIndex: Integer = -1;
      const Callback: TWatchChangedEvent = nil;
      const Phases: TSimTickPhases = [stpPostAgents];
      const EmitMode: TCellWatchEmitMode = cemOnChange): TFollowingCellWatch;
    procedure RemoveWatch(AWatch: TSimWatch);
    procedure ClearWatches;

    property Simulator: TSimulator read fSim;
    property Diagnostics: TSimDiagnosticsHub read fDiagnostics;
    property OnWatchChange: TWatchChangedEvent read fOnWatchChange write fOnWatchChange;
  end;

implementation

uses u_EventSinks;

var
  NextSimSessionId: Integer = 0;


{ TSimSession }

constructor TSimSession.Create(aSim: TSimulator);
begin
  inherited Create;
  Inc(NextSimSessionId);
  fDiagnostics := TSimDiagnosticsHub.Create(NextSimSessionId);
  fSampleRangeStart := 0;
  fSampleRangeCount := 0;

  if Assigned(aSim) then
    fSim := aSim
  else
    fSim := TSimulator.Create(fDiagnostics as ISimDiagnosticsSink);

  fSim.Runtime.OnPhase := HandleRuntimePhase;
  fWatches := TObjectList<TSimWatch>.Create(True);

  fEventSink := TEventSink.Create;

  fController := TSimController.Create(fSim.Clock, fDiagnostics as ISimDiagnosticsSink, fEventSink);
  fController.BeforeAdvance.Subscribe(HandleControllerBeforeAdvance);
  fController.AfterAdvance.Subscribe(HandleControllerAfterAdvance);
  fControllerDiagnosticsSubscriptionId := fDiagnostics.Subscribe(AnySimEventFilter, fController);
end;

destructor TSimSession.Destroy;
begin
  if Assigned(fController) then
  begin
    fController.BeforeAdvance.Unsubscribe(HandleControllerBeforeAdvance);
    fController.AfterAdvance.Unsubscribe(HandleControllerAfterAdvance);
  end;

  if Assigned(fDiagnostics) and (fControllerDiagnosticsSubscriptionId <> 0) then
  begin
    fDiagnostics.Unsubscribe(fControllerDiagnosticsSubscriptionId);
    fControllerDiagnosticsSubscriptionId := 0;
  end;

  fController.Free;
  fController := nil;
  if Assigned(fSim) and Assigned(fSim.Runtime) then
    fSim.Runtime.OnPhase := nil;
  fWatches.Free;
  fSim.Free;
  fDiagnostics := nil;
  fEventSink := nil;
  inherited;
end;

function TSimSession.RegisterWatch(AWatch: TSimWatch): TSimWatch;
begin
  if not Assigned(AWatch) then
    Exit(nil);

  Inc(fNextWatchId);
  AWatch.WatchId := fNextWatchId;
  fWatches.Add(AWatch);
  Result := AWatch;
end;

function TSimSession.AddAgentWatch(AgentIndex: Integer;
  const Callback: TWatchChangedEvent; const Phases: TSimTickPhases): TAgentWatch;
begin
  Result := TAgentWatch(RegisterWatch(TAgentWatch.Create(AgentIndex)));
  if Assigned(Result) then
  begin
    Result.Phases := Phases;
    Result.OnChange := Callback;
  end;
end;

function TSimSession.AddCellWatch(CellIndex, SubstanceIndex: Integer;
  const Callback: TWatchChangedEvent; const Phases: TSimTickPhases;
  const EmitMode: TCellWatchEmitMode): TCellWatch;
begin
  Result := TCellWatch(RegisterWatch(TCellWatch.Create(CellIndex, SubstanceIndex)));
  if Assigned(Result) then
  begin
    Result.Phases := Phases;
    Result.EmitMode := EmitMode;
    Result.OnChange := Callback;
  end;
end;

function TSimSession.AddFollowingCellWatch(AgentIndex, SubstanceIndex: Integer;
  const Callback: TWatchChangedEvent; const Phases: TSimTickPhases;
  const EmitMode: TCellWatchEmitMode): TFollowingCellWatch;
begin
  Result := TFollowingCellWatch(RegisterWatch(TFollowingCellWatch.Create(AgentIndex, SubstanceIndex)));
  if Assigned(Result) then
  begin
    Result.Phases := Phases;
    Result.EmitMode := EmitMode;
    Result.OnChange := Callback;

    // Bind immediately so startup priming targets the tracked agent cell.
    Result.AfterStep(fSim);
  end;
end;

procedure TSimSession.RemoveWatch(AWatch: TSimWatch);
begin
  if not Assigned(AWatch) then
    Exit;

  fWatches.Remove(AWatch);
end;

procedure TSimSession.ClearWatches;
begin
  fWatches.Clear;
end;

procedure TSimSession.BeginSession;
begin
  for var watch in fWatches do
    watch.Reset;
end;

procedure TSimSession.EndSession;
begin
  for var watch in fWatches do
    watch.Reset;
end;

procedure TSimSession.EvaluateWatches(const Phase: TSimTickPhase);
begin
  for var watch in fWatches do
  begin
    if not watch.Evaluate(fSim, fSim.Clock.Tick, Phase) then
      Continue;

    watch.Notify(Self);
    if Assigned(fOnWatchChange) then
      fOnWatchChange(Self, watch);
  end;
end;

procedure TSimSession.HandleRuntimePhase(Sender: TObject; Phase: TSimTickPhase);
begin
  EvaluateWatches(Phase);
end;

procedure TSimSession.HandleControllerBeforeAdvance(Sender: TObject);
begin
  // Apply selective baseline priming for watches that were rebound after prior step.
  PrimePendingWatches;

  if fSampleRangeCount > 0 then
  begin
    var tick := Integer(fSim.Clock.Tick);
    var target := fSampleRangeStart + (tick mod fSampleRangeCount);
    fSim.Runtime.TrackedResourceCacheIndex := target;
  end;
end;

procedure TSimSession.HandleControllerAfterAdvance(Sender: TObject);
begin
  // Rebind follow-style watches after full phase evaluation so they start next tick on target cell.
  UpdateWatchBindings;
end;

procedure TSimSession.PrimePendingWatches;
begin
  for var watch in fWatches do
    if watch.NeedsPrime then
      watch.Prime(fSim, fSim.Clock.Tick);
end;

procedure TSimSession.UpdateWatchBindings;
begin
  for var watch in fWatches do
    watch.AfterStep(fSim);
end;

procedure TSimSession.PrimeWatches;
begin
  // Capture initial baselines without emitting watch change callbacks.
  for var watch in fWatches do
    watch.Prime(fSim, fSim.Clock.Tick);
end;

end.
