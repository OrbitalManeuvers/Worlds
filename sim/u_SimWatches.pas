unit u_SimWatches;

interface

uses System.Math,
  u_AgentState, u_AgentTypes, u_Simulators, u_SimPhases;

type
  TSimWatch = class;
  TCellWatchEmitMode = (cemOnChange, cemAlways);

  TWatchChangedEvent = procedure (Sender: TObject; Watch: TSimWatch) of object;

  TSimWatch = class
  private
    fWatchId: Integer;
    fEnabled: Boolean;
    fLastPhase: TSimTickPhase;
    fPhases: TSimTickPhases;
    fOnChange: TWatchChangedEvent;
  protected
    function EvaluateChange(const Sim: TSimulator; const Tick: Cardinal): Boolean; virtual; abstract;

  public
    constructor Create; virtual;
    function Evaluate(const Sim: TSimulator; const Tick: Cardinal; const Phase: TSimTickPhase): Boolean;
    procedure Reset; virtual;
    function NeedsPrime: Boolean; virtual;
    procedure Prime(const Sim: TSimulator; const Tick: Cardinal); virtual;
    procedure AfterStep(const Sim: TSimulator); virtual;
    procedure Notify(Sender: TObject);
    function ActionToStr(aAction: TAgentAction): string;

    property WatchId: Integer read fWatchId write fWatchId;
    property Enabled: Boolean read fEnabled write fEnabled;
    property LastPhase: TSimTickPhase read fLastPhase;
    property Phases: TSimTickPhases read fPhases write fPhases;
    property OnChange: TWatchChangedEvent read fOnChange write fOnChange;
  end;

  TAgentWatchField = (awfLocation, awfReserves, awfAction, awfTarget, awfAge, awfAlive);
  TAgentWatchFields = set of TAgentWatchField;

  TAgentWatchChange = record
    Tick: Cardinal;
    ChangedFields: TAgentWatchFields;
    PreviousState: TAgentState;
    CurrentState: TAgentState;
  end;

  TAgentWatch = class(TSimWatch)
  private
    fAgentIndex: Integer;
    fHasBaseline: Boolean;
    fBaselineState: TAgentState;
    fLastChange: TAgentWatchChange;
    function TryReadState(const Sim: TSimulator; out State: TAgentState): Boolean;
    function BuildChangeSet(const PreviousState, CurrentState: TAgentState): TAgentWatchFields;
    function SameTarget(const A, B: TTarget): Boolean;
  protected
    function EvaluateChange(const Sim: TSimulator; const Tick: Cardinal): Boolean; override;
  public
    constructor Create(aAgentIndex: Integer); reintroduce;
    procedure Reset; override;

    property AgentIndex: Integer read fAgentIndex;
    property LastChange: TAgentWatchChange read fLastChange;
  end;

  TCellWatchChange = record
    Tick: Cardinal;
    PreviousAmount: Single;
    CurrentAmount: Single;
    PreviousDebt: Single;
    CurrentDebt: Single;
  end;

  TCellWatch = class(TSimWatch)
  private
    fCellIndex: Integer;
    fSubstanceIndex: Integer;
    fMinDelta: Single;
    fHasBaseline: Boolean;
    fBaselineAmount: Single;
    fBaselineDebt: Single;
    fEmitMode: TCellWatchEmitMode;
    fLastChange: TCellWatchChange;
    function TryReadAmount(const Sim: TSimulator; out Amount, Debt: Single): Boolean;
  protected
    procedure SetCellIndex(Value: Integer);
    procedure InvalidateBaseline;
  protected
    function EvaluateChange(const Sim: TSimulator; const Tick: Cardinal): Boolean; override;
  public
    constructor Create(aCellIndex: Integer; aSubstanceIndex: Integer = -1); reintroduce;
    procedure Reset; override;

    property CellIndex: Integer read fCellIndex;
    property SubstanceIndex: Integer read fSubstanceIndex;
    property MinDelta: Single read fMinDelta write fMinDelta;
    property EmitMode: TCellWatchEmitMode read fEmitMode write fEmitMode;
    property LastChange: TCellWatchChange read fLastChange;
  end;

  TFollowingCellWatch = class(TCellWatch)
  private
    fAgentIndex: Integer;
    fNeedsPrime: Boolean;
  protected
  public
    constructor Create(aAgentIndex: Integer; aSubstanceIndex: Integer = -1); reintroduce;
    function NeedsPrime: Boolean; override;
    procedure Prime(const Sim: TSimulator; const Tick: Cardinal); override;
    procedure AfterStep(const Sim: TSimulator); override;

    property AgentIndex: Integer read fAgentIndex;
  end;


implementation

{ TSimWatch }

constructor TSimWatch.Create;
begin
  inherited Create;
  fEnabled := True;
  fLastPhase := stpPostAgents;
  fPhases := [stpPostAgents];
end;

function TSimWatch.Evaluate(const Sim: TSimulator; const Tick: Cardinal;
  const Phase: TSimTickPhase): Boolean;
begin
  Result := fEnabled and (Phase in fPhases) and Assigned(Sim) and EvaluateChange(Sim, Tick);
  if Result then
    fLastPhase := Phase;
end;

function TSimWatch.ActionToStr(aAction: TAgentAction): string;
const
  action_strs: array[TAgentAction] of string = ('Move', 'Forage', 'Shelter', 'Reproduce', 'Idle');
begin
  Result := action_strs[aAction];
end;

procedure TSimWatch.Notify(Sender: TObject);
begin
  if Assigned(fOnChange) then
    fOnChange(Sender, Self);
end;

procedure TSimWatch.Reset;
begin
  // default: descendants can clear baseline state
end;

function TSimWatch.NeedsPrime: Boolean;
begin
  Result := False;
end;

procedure TSimWatch.Prime(const Sim: TSimulator; const Tick: Cardinal);
begin
  if not Assigned(Sim) then
    Exit;

  EvaluateChange(Sim, Tick);
end;

procedure TSimWatch.AfterStep(const Sim: TSimulator);
begin
  // default: descendants can update bindings for next tick
end;

{ TAgentWatch }

constructor TAgentWatch.Create(aAgentIndex: Integer);
begin
  inherited Create;
  fAgentIndex := aAgentIndex;
end;

function TAgentWatch.BuildChangeSet(const PreviousState, CurrentState: TAgentState): TAgentWatchFields;
begin
  Result := [];

  if PreviousState.Location <> CurrentState.Location then
    Include(Result, awfLocation);

  if Abs(PreviousState.Reserves - CurrentState.Reserves) > 0.000001 then
    Include(Result, awfReserves);

  if PreviousState.Action <> CurrentState.Action then
    Include(Result, awfAction);

  if not SameTarget(PreviousState.ActionTarget, CurrentState.ActionTarget) then
    Include(Result, awfTarget);

  if PreviousState.Age <> CurrentState.Age then
    Include(Result, awfAge);

  if (PreviousState.Reserves > 0.0) <> (CurrentState.Reserves > 0.0) then
    Include(Result, awfAlive);
end;

function TAgentWatch.EvaluateChange(const Sim: TSimulator; const Tick: Cardinal): Boolean;
begin
  Result := False;

  var state: TAgentState;
  if not TryReadState(Sim, state) then
    Exit;

  if not fHasBaseline then
  begin
    fBaselineState := state;
    fHasBaseline := True;
    Exit;
  end;

  var changedFields := BuildChangeSet(fBaselineState, state);
  if changedFields = [] then
    Exit;

  fLastChange.Tick := Tick;
  fLastChange.ChangedFields := changedFields;
  fLastChange.PreviousState := fBaselineState;
  fLastChange.CurrentState := state;

  fBaselineState := state;
  Result := True;
end;

procedure TAgentWatch.Reset;
begin
  fHasBaseline := False;
  fBaselineState := Default(TAgentState);
  fLastChange := Default(TAgentWatchChange);
end;

function TAgentWatch.SameTarget(const A, B: TTarget): Boolean;
begin
  Result := A.TType = B.TType;
  if not Result then
    Exit;

  case A.TType of
    ttCell:
      Result := A.Cell = B.Cell;
    ttCache:
      Result := (A.Cache.Kind = B.Cache.Kind) and (A.Cache.Index = B.Cache.Index);
  else
    Result := False;
  end;
end;

function TAgentWatch.TryReadState(const Sim: TSimulator; out State: TAgentState): Boolean;
begin
  Result := Sim.Runtime.Population.TryGetAgentState(fAgentIndex, State);
end;

{ TCellWatch }

constructor TCellWatch.Create(aCellIndex, aSubstanceIndex: Integer);
begin
  inherited Create;
  fCellIndex := aCellIndex;
  fSubstanceIndex := aSubstanceIndex;
  fMinDelta := 0.000001;
  fEmitMode := cemOnChange;
end;

procedure TCellWatch.SetCellIndex(Value: Integer);
begin
  fCellIndex := Value;
end;

procedure TCellWatch.InvalidateBaseline;
begin
  fHasBaseline := False;
  fBaselineAmount := 0.0;
  fBaselineDebt := 0.0;
end;

function TCellWatch.EvaluateChange(const Sim: TSimulator; const Tick: Cardinal): Boolean;
begin
  Result := False;

  var amount: Single;
  var debt: Single;
  if not TryReadAmount(Sim, amount, debt) then
    Exit;

  if not fHasBaseline then
  begin
    fBaselineAmount := amount;
    fBaselineDebt := debt;
    fHasBaseline := True;
    Exit;
  end;

  var hasChange := (Abs(amount - fBaselineAmount) >= fMinDelta)
    or (Abs(debt - fBaselineDebt) >= fMinDelta);

  if (fEmitMode = cemOnChange) and not hasChange then
    Exit;

  fLastChange.Tick := Tick;
  fLastChange.PreviousAmount := fBaselineAmount;
  fLastChange.CurrentAmount := amount;
  fLastChange.PreviousDebt := fBaselineDebt;
  fLastChange.CurrentDebt := debt;

  fBaselineAmount := amount;
  fBaselineDebt := debt;
  Result := True;
end;

procedure TCellWatch.Reset;
begin
  fHasBaseline := False;
  fBaselineAmount := 0.0;
  fBaselineDebt := 0.0;
  fLastChange := Default(TCellWatchChange);
end;

function TCellWatch.TryReadAmount(const Sim: TSimulator; out Amount, Debt: Single): Boolean;
begin
  Result := False;
  Amount := 0.0;
  Debt := 0.0;

  var env := Sim.Runtime.Environment;
  if (fCellIndex < 0) or (fCellIndex >= Length(env.Cells)) then
    Exit;

  var cell := env.Cells[fCellIndex];
  if cell.ResourceCount = 0 then
  begin
    Result := True;
    Exit;
  end;

  for var i := 0 to cell.ResourceCount - 1 do
  begin
    var resIndex := cell.ResourceStart + i;
    if (resIndex < 0) or (resIndex >= Length(env.Resources)) then
      Continue;

    var res := env.Resources[resIndex];
    if (fSubstanceIndex >= 0) and (res.SubstanceIndex <> fSubstanceIndex) then
      Continue;

    Amount := Amount + res.Amount;
    Debt := Debt + res.RegenDebt;
  end;

  Result := True;
end;

{ TFollowingCellWatch }

constructor TFollowingCellWatch.Create(aAgentIndex: Integer; aSubstanceIndex: Integer);
begin
  inherited Create(0, aSubstanceIndex);
  fAgentIndex := aAgentIndex;
  fNeedsPrime := True;
end;

function TFollowingCellWatch.NeedsPrime: Boolean;
begin
  Result := fNeedsPrime;
end;

procedure TFollowingCellWatch.Prime(const Sim: TSimulator; const Tick: Cardinal);
begin
  inherited Prime(Sim, Tick);
  fNeedsPrime := False;
end;

procedure TFollowingCellWatch.AfterStep(const Sim: TSimulator);
begin
  inherited AfterStep(Sim);

  if not Assigned(Sim) then
    Exit;

  var state: TAgentState;
  if not Sim.Runtime.Population.TryGetAgentState(fAgentIndex, state) then
    Exit;

  var env := Sim.Runtime.Environment;
  if (state.Location < 0) or (state.Location > High(env.Cells)) then
    Exit;

  if state.Location = CellIndex then
    Exit;

  SetCellIndex(state.Location);
  InvalidateBaseline;
  fNeedsPrime := True;
end;

end.
