unit u_SimWatches;

interface

uses System.Math,
  u_AgentState, u_AgentTypes, u_Simulators;

type
  TSimWatch = class;

  TWatchChangedEvent = procedure (Sender: TObject; Watch: TSimWatch) of object;

  TSimWatch = class
  private
    fWatchId: Integer;
    fEnabled: Boolean;
    fOnChange: TWatchChangedEvent;
  protected
    function EvaluateChange(const Sim: TSimulator; const Tick: Cardinal): Boolean; virtual; abstract;
  public
    constructor Create; virtual;
    function Evaluate(const Sim: TSimulator; const Tick: Cardinal): Boolean;
    procedure Reset; virtual;
    procedure Notify(Sender: TObject);
    function ActionToStr(aAction: TAgentAction): string;

    property WatchId: Integer read fWatchId write fWatchId;
    property Enabled: Boolean read fEnabled write fEnabled;
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
    fAgentId: Integer;
    fHasBaseline: Boolean;
    fBaselineState: TAgentState;
    fLastChange: TAgentWatchChange;
    function TryReadState(const Sim: TSimulator; out State: TAgentState): Boolean;
    function BuildChangeSet(const PreviousState, CurrentState: TAgentState): TAgentWatchFields;
    function SameTarget(const A, B: TTarget): Boolean;
  protected
    function EvaluateChange(const Sim: TSimulator; const Tick: Cardinal): Boolean; override;
  public
    constructor Create(aAgentId: Integer); reintroduce;
    procedure Reset; override;

    property AgentId: Integer read fAgentId;
    property LastChange: TAgentWatchChange read fLastChange;
  end;

  TCellWatchChange = record
    Tick: Cardinal;
    PreviousAmount: Single;
    CurrentAmount: Single;
  end;

  TCellWatch = class(TSimWatch)
  private
    fCellIndex: Integer;
    fSubstanceIndex: Integer;
    fMinDelta: Single;
    fHasBaseline: Boolean;
    fBaselineAmount: Single;
    fLastChange: TCellWatchChange;
    function TryReadAmount(const Sim: TSimulator; out Amount: Single): Boolean;
  protected
    function EvaluateChange(const Sim: TSimulator; const Tick: Cardinal): Boolean; override;
  public
    constructor Create(aCellIndex: Integer; aSubstanceIndex: Integer = -1); reintroduce;
    procedure Reset; override;

    property CellIndex: Integer read fCellIndex;
    property SubstanceIndex: Integer read fSubstanceIndex;
    property MinDelta: Single read fMinDelta write fMinDelta;
    property LastChange: TCellWatchChange read fLastChange;
  end;


implementation

{ TSimWatch }

constructor TSimWatch.Create;
begin
  inherited Create;
  fEnabled := True;
end;

function TSimWatch.Evaluate(const Sim: TSimulator; const Tick: Cardinal): Boolean;
begin
  Result := fEnabled and Assigned(Sim) and EvaluateChange(Sim, Tick);
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

{ TAgentWatch }

constructor TAgentWatch.Create(aAgentId: Integer);
begin
  inherited Create;
  fAgentId := aAgentId;
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
      Result := A.CacheId = B.CacheId;
  else
    Result := False;
  end;
end;

function TAgentWatch.TryReadState(const Sim: TSimulator; out State: TAgentState): Boolean;
begin
  Result := Sim.Runtime.Population.TryGetAgentState(fAgentId, State);
end;

{ TCellWatch }

constructor TCellWatch.Create(aCellIndex, aSubstanceIndex: Integer);
begin
  inherited Create;
  fCellIndex := aCellIndex;
  fSubstanceIndex := aSubstanceIndex;
  fMinDelta := 0.000001;
end;

function TCellWatch.EvaluateChange(const Sim: TSimulator; const Tick: Cardinal): Boolean;
begin
  Result := False;

  var amount: Single;
  if not TryReadAmount(Sim, amount) then
    Exit;

  if not fHasBaseline then
  begin
    fBaselineAmount := amount;
    fHasBaseline := True;
    Exit;
  end;

  if Abs(amount - fBaselineAmount) < fMinDelta then
    Exit;

  fLastChange.Tick := Tick;
  fLastChange.PreviousAmount := fBaselineAmount;
  fLastChange.CurrentAmount := amount;

  fBaselineAmount := amount;
  Result := True;
end;

procedure TCellWatch.Reset;
begin
  fHasBaseline := False;
  fBaselineAmount := 0.0;
  fLastChange := Default(TCellWatchChange);
end;

function TCellWatch.TryReadAmount(const Sim: TSimulator; out Amount: Single): Boolean;
begin
  Result := False;
  Amount := 0.0;

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
  end;

  Result := True;
end;

end.
