unit u_SimSessions;

interface

uses System.Classes, System.Generics.Collections,
 u_Worlds, u_EnvironmentTypes, u_EnvironmentLibraries,
 u_Simulators, u_SimParams, u_Foods, u_SimWatches;

type
  TLogEvent = procedure (Sender: TObject; const aMsg: string) of object;

  TSimSession = class
  private
    fWorld: TWorld;
    fLibrary: TEnvironmentLibrary;
    fSim: TSimulator;
    fParams: TSimParams;
    fSeed: Integer;
    fFoods: TList<TFood>;
    fWatches: TObjectList<TSimWatch>;
    fNextWatchId: Integer;
    fOnLog: TLogEvent;
    fOnBeforeStep: TNotifyEvent;
    fOnAfterStep: TNotifyEvent;
    fOnWatchChange: TWatchChangedEvent;
    procedure Log(const aMsg: string); overload;
    procedure Log(const aMsgFmt: string; const Params: array of const); overload;
    procedure EvaluateWatches;
    function RegisterWatch(AWatch: TSimWatch): TSimWatch;
  public
    constructor Create(aWorld: TWorld; const aParams: TSimParams; aLibrary: TEnvironmentLibrary);
    destructor Destroy; override;

    procedure BeginSession;
    procedure EndSession;

    procedure Step;

    function AddAgentWatch(AgentId: Integer; const Callback: TWatchChangedEvent = nil): TAgentWatch;
    function AddCellWatch(CellIndex: Integer; SubstanceIndex: Integer = -1;
      const Callback: TWatchChangedEvent = nil): TCellWatch;
    procedure RemoveWatch(AWatch: TSimWatch);
    procedure ClearWatches;

    property Simulator: TSimulator read fSim;
    property Foods: TList<TFood> read fFoods;
    property Seed: Integer read fSeed;

    property OnLog: TLogEvent read fOnLog write fOnLog;
    property OnBeforeStep: TNotifyEvent read fOnBeforeStep write fOnBeforeStep;
    property OnAfterStep: TNotifyEvent read fOnAfterStep write fOnAfterStep;
    property OnWatchChange: TWatchChangedEvent read fOnWatchChange write fOnWatchChange;
  end;

implementation

uses System.SysUtils,
  u_WorldLayouts, u_SimUpscalers, u_SimPopulators, u_SimEnvironments;

{ Utils }
function SubstanceToStr(const sub: TSubstance): string;
const
  fmt = 'A%.3d B%.3d G%.3d X%.3d ';
begin
  Result := Format(fmt, [
    sub[Alpha],
    sub[Beta],
    sub[Gamma],
    sub[Biomass]
  ]);
end;


{ TSimSession }

constructor TSimSession.Create(aWorld: TWorld; const aParams: TSimParams; aLibrary: TEnvironmentLibrary);
begin
  inherited Create;
  fWorld := aWorld;
  fLibrary := aLibrary;
  fParams := aParams;

  //
  fSim := TSimulator.Create;
  fFoods := TList<TFood>.Create;
  fWatches := TObjectList<TSimWatch>.Create(True);
end;

destructor TSimSession.Destroy;
begin
  fWatches.Free;
  fFoods.Free;
  fSim.Free;
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

function TSimSession.AddAgentWatch(AgentId: Integer;
  const Callback: TWatchChangedEvent): TAgentWatch;
begin
  Result := TAgentWatch(RegisterWatch(TAgentWatch.Create(AgentId)));
  if Assigned(Result) then
    Result.OnChange := Callback;
end;

function TSimSession.AddCellWatch(CellIndex, SubstanceIndex: Integer;
  const Callback: TWatchChangedEvent): TCellWatch;
begin
  Result := TCellWatch(RegisterWatch(TCellWatch.Create(CellIndex, SubstanceIndex)));
  if Assigned(Result) then
    Result.OnChange := Callback;
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
  // Session seed policy:
  // - Params.Seed <> 0: force deterministic run by setting RTL seed.
  // - Params.Seed = 0: preserve current RTL seed and capture it as in-use value.
  if fParams.Seed <> 0 then
  begin
    RandSeed := fParams.Seed;
    fSeed := fParams.Seed;
  end
  else
    fSeed := RandSeed;

  // Environment
  // create the stitched-together world of selected regions
  var layout := TWorldLayout.Create(fWorld, fLibrary);
  try
    // the layout feeds the upscaler
    var upscaler := TWorldUpscaler.Create(fSim.Runtime.Environment, fParams);
    try
      upscaler.UpscaleWorld(layout);
    finally
      upscaler.Free;
    end;

    // save off the list of foods for later instrumentation
    for var f in layout.Foods do
      Self.fFoods.Add(f);
  finally
    layout.free;
  end;

  // Population
  TWorldPopulator.Populate(fSim.Runtime.Population, fParams);

  // for early development only ...
  if fParams.Population.AgentCount = 1 then
  begin
    // move the agent onto a cell that has resources
    for var cellIndex := 0 to Length(fSim.Runtime.Environment.Cells) - 1 do
      if fSim.Runtime.Environment.Cells[cellIndex].ResourceCount > 0 then
      begin
        var agent := fSim.Runtime.Population.Agents[0];
        agent.Location := cellIndex;
        fsim.Runtime.Population.UpdateAgentState(0, agent);
        Break;
      end;
  end;

  // log resource map
  if Length(fSim.Runtime.Environment.Substances) = Self.Foods.Count then
  begin
    Log('Substances:');
    for var i := 0 to Self.Foods.Count - 1 do
    begin
      var line := '[%.2d] %s  Food: %s';
      Log(line, [
        i,
        SubstanceToStr(fSim.Runtime.Environment.Substances[i]),
        Foods[i].Name
      ]);
    end;
  end;

  for var watch in fWatches do
    watch.Reset;
end;

procedure TSimSession.EndSession;
begin

  for var watch in fWatches do
    watch.Reset;

end;

procedure TSimSession.EvaluateWatches;
begin
  for var watch in fWatches do
  begin
    if not watch.Evaluate(fSim, fSim.Clock.Tick) then
      Continue;

    watch.Notify(Self);
    if Assigned(fOnWatchChange) then
      fOnWatchChange(Self, watch);
  end;
end;

procedure TSimSession.Log(const aMsgFmt: string; const Params: array of const);
begin
  Log(Format(aMsgFmt, Params));
end;

procedure TSimSession.Log(const aMsg: string);
begin
  if Assigned(fOnLog) then
    fOnLog(Self, aMsg);
end;

procedure TSimSession.Step;
begin
  if Assigned(fOnBeforeStep) then
    fOnBeforeStep(Self);

  fSim.Clock.Step;

  EvaluateWatches;

  if Assigned(fOnAfterStep) then
    fOnAfterStep(Self);

end;

end.
