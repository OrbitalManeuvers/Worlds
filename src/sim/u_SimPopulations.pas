unit u_SimPopulations;

interface

{.DEFINE AGENT_DEBUG_TRACE}

uses u_AgentTypes, u_AgentGenome, u_AgentState, u_AgentBrain, u_SimEventTypes;

type
{$IFDEF AGENT_DEBUG_TRACE}
  PAgentDecisionDebugTrace = ^TAgentDecisionDebugTrace;
  TAgentDecisionDebugTrace = record
    GlobalTick: Integer;
    AgentIndex: Integer;
    Context: TDecisionContext;
    Requested: TBrainTickOutput;
    Resolved: TBrainTickOutput;
    ForageOutcome: TForageOutcome;
    HasValue: Boolean;
  end;
{$ENDIF}

  TSimPopulation = class
  private
    const INVALID_INDEX = -1;
  private
    fAgents: TArray<TAgentState>;
    fScratch: TAgentScratch;
{$IFDEF AGENT_DEBUG_TRACE}
    fDecisionDebugTraces: TArray<TAgentDecisionDebugTrace>;
{$ENDIF}
    fCellAgents: TArray<TArray<Integer>>;
    fIndexedAgentCell: TArray<Integer>;
    fIndexedAgentSlot: TArray<Integer>;

    procedure SetAgentCount(aCount: Integer);
    function GetAgentCount: Integer;
    function IsValidCellIndex(aCellIndex: Integer): Boolean;
    procedure InitializeAgentIndexEntry(aAgentIndex: Integer);
    procedure ResizeIndexedAgents(aAgentCount: Integer);
  {$IFDEF AGENT_DEBUG_TRACE}
    procedure ResizeDecisionDebugTraces(aAgentCount: Integer);
  {$ENDIF}
    procedure ResetLocationIndex;
    procedure AddAgentToCell(aAgentIndex, aCellIndex: Integer);
    procedure RemoveAgentFromCell(aAgentIndex: Integer);
    procedure UpdateAgentLocation(aAgentIndex, aOldCell, aNewCell: Integer);
  public
    constructor Create;

    procedure SetCellCount(aCellCount: Integer);
    function GetCellAgentCount(aCellIndex: Integer): Integer;
    function TryGetCellAgents(aCellIndex: Integer; out Agents: TArray<Integer>): Boolean;

    function AppendAgent(const State: TAgentState): Integer;
    function GetAgentState(aIndex: Integer): PAgentState;
    procedure NotifyLocationChanged(aIndex: Integer; aOldCell, aNewCell: Integer);

    function Think(aIndex: Integer; const Input: TBrainTickInput): TBrainTickOutput;
    procedure Reflect(aIndex: Integer; const Decision: TBrainTickOutput; const Input: TBrainReflectInput);
    procedure ApplyStep(aIndex: Integer; const Output: TBrainTickOutput);
    procedure StepAgent(aIndex: Integer; const Input: TBrainTickInput);

    procedure Tick(const Input: TBrainTickInput);

    function GetMetabolicState(aAgentId: TAgentId): TMetabolicState;
    function StatePtr(aIndex: Integer): PAgentState;
{$IFDEF AGENT_DEBUG_TRACE}
    function LastDecisionContext: TDecisionContext;
    procedure CaptureDecisionDebugTrace(aIndex, aGlobalTick: Integer; const Context: TDecisionContext;
      const Requested, Resolved: TBrainTickOutput; const ForageOutcome: TForageOutcome);
    function DecisionDebugTracePtr(aIndex: Integer): PAgentDecisionDebugTrace;
{$ENDIF}

    property AgentCount: Integer read GetAgentCount write SetAgentCount;
    property Agents: TArray<TAgentState> read fAgents;
  end;

implementation

{ TSimPopulation }

constructor TSimPopulation.Create;
begin
  inherited;
end;

function TSimPopulation.IsValidCellIndex(aCellIndex: Integer): Boolean;
begin
  Result := (aCellIndex >= 0) and (aCellIndex <= High(fCellAgents));
end;

procedure TSimPopulation.InitializeAgentIndexEntry(aAgentIndex: Integer);
begin
  fIndexedAgentCell[aAgentIndex] := INVALID_INDEX;
  fIndexedAgentSlot[aAgentIndex] := INVALID_INDEX;
end;

procedure TSimPopulation.ResizeIndexedAgents(aAgentCount: Integer);
begin
  if aAgentCount < 0 then
    aAgentCount := 0;

  var oldCount := Length(fIndexedAgentCell);

  // Remove indexed entries for agents that are being trimmed from the population.
  for var i := aAgentCount to oldCount - 1 do
    RemoveAgentFromCell(i);

  SetLength(fIndexedAgentCell, aAgentCount);
  SetLength(fIndexedAgentSlot, aAgentCount);

  for var i := oldCount to aAgentCount - 1 do
    InitializeAgentIndexEntry(i);
end;

{$IFDEF AGENT_DEBUG_TRACE}
procedure TSimPopulation.ResizeDecisionDebugTraces(aAgentCount: Integer);
begin
  if aAgentCount < 0 then
    aAgentCount := 0;

  SetLength(fDecisionDebugTraces, aAgentCount);
end;
{$ENDIF}

procedure TSimPopulation.ResetLocationIndex;
begin
  for var cellIndex := 0 to High(fCellAgents) do
    SetLength(fCellAgents[cellIndex], 0);

  for var agentIndex := 0 to High(fIndexedAgentCell) do
    InitializeAgentIndexEntry(agentIndex);
end;

procedure TSimPopulation.SetCellCount(aCellCount: Integer);
begin
  if aCellCount < 0 then
    aCellCount := 0;

  SetLength(fCellAgents, aCellCount);

  // Cell-geometry changes are a reset boundary for occupancy indexing.
  ResetLocationIndex;
end;

function TSimPopulation.GetCellAgentCount(aCellIndex: Integer): Integer;
begin
  if not IsValidCellIndex(aCellIndex) then
    Exit(0);

  Result := Length(fCellAgents[aCellIndex]);
end;

function TSimPopulation.TryGetCellAgents(aCellIndex: Integer; out Agents: TArray<Integer>): Boolean;
begin
  Result := IsValidCellIndex(aCellIndex);
  if Result then
    Agents := fCellAgents[aCellIndex]
  else
    SetLength(Agents, 0);
end;

function TSimPopulation.AppendAgent(const State: TAgentState): Integer;
begin
  Result := Length(fAgents);
  SetLength(fAgents, Result + 1);
  ResizeIndexedAgents(Result + 1);
{$IFDEF AGENT_DEBUG_TRACE}
  ResizeDecisionDebugTraces(Result + 1);
{$ENDIF}
  fAgents[Result] := State;
  UpdateAgentLocation(Result, INVALID_INDEX, State.Location);
end;

function TSimPopulation.GetAgentState(aIndex: Integer): PAgentState;
begin
  if (aIndex >= 0) and (aIndex <= High(fAgents)) then
    Result := @fAgents[aIndex]
  else
    Result := nil;
end;

procedure TSimPopulation.NotifyLocationChanged(aIndex: Integer; aOldCell, aNewCell: Integer);
begin
  UpdateAgentLocation(aIndex, aOldCell, aNewCell);
end;

procedure TSimPopulation.AddAgentToCell(aAgentIndex, aCellIndex: Integer);
begin
  if not IsValidCellIndex(aCellIndex) then
  begin
    InitializeAgentIndexEntry(aAgentIndex);
    Exit;
  end;

  if fIndexedAgentCell[aAgentIndex] <> INVALID_INDEX then
    RemoveAgentFromCell(aAgentIndex);

  var slotIndex := Length(fCellAgents[aCellIndex]);
  SetLength(fCellAgents[aCellIndex], slotIndex + 1);
  fCellAgents[aCellIndex][slotIndex] := aAgentIndex;
  fIndexedAgentCell[aAgentIndex] := aCellIndex;
  fIndexedAgentSlot[aAgentIndex] := slotIndex;
end;

procedure TSimPopulation.RemoveAgentFromCell(aAgentIndex: Integer);
begin
  var cellIndex := fIndexedAgentCell[aAgentIndex];
  var slotIndex := fIndexedAgentSlot[aAgentIndex];

  if not IsValidCellIndex(cellIndex) then
  begin
    InitializeAgentIndexEntry(aAgentIndex);
    Exit;
  end;

  var cellAgents := fCellAgents[cellIndex];
  var lastSlot := High(cellAgents);
  if slotIndex <> lastSlot then
  begin
    var swappedAgent := cellAgents[lastSlot];
    cellAgents[slotIndex] := swappedAgent;
    fIndexedAgentCell[swappedAgent] := cellIndex;
    fIndexedAgentSlot[swappedAgent] := slotIndex;
  end;

  SetLength(cellAgents, lastSlot);
  fCellAgents[cellIndex] := cellAgents;
  InitializeAgentIndexEntry(aAgentIndex);
end;

procedure TSimPopulation.UpdateAgentLocation(aAgentIndex, aOldCell, aNewCell: Integer);
begin
  if (aOldCell = aNewCell) and (fIndexedAgentCell[aAgentIndex] = aNewCell) then
    Exit;

  if not IsValidCellIndex(aNewCell) then
  begin
    RemoveAgentFromCell(aAgentIndex);
    Exit;
  end;

  if fIndexedAgentCell[aAgentIndex] = aNewCell then
    Exit;

  RemoveAgentFromCell(aAgentIndex);
  AddAgentToCell(aAgentIndex, aNewCell);
end;

function TSimPopulation.GetAgentCount: Integer;
begin
  Result := Length(fAgents);
end;

procedure TSimPopulation.SetAgentCount(aCount: Integer);
begin
  if aCount < 0 then
    aCount := 0;

  SetLength(fAgents, aCount);
  ResizeIndexedAgents(aCount);
{$IFDEF AGENT_DEBUG_TRACE}
  ResizeDecisionDebugTraces(aCount);
{$ENDIF}
end;

function TSimPopulation.Think(aIndex: Integer; const Input: TBrainTickInput): TBrainTickOutput;
begin
  Result := TAgentBrain.Think(fAgents[aIndex], Input, fScratch);
end;

procedure TSimPopulation.Reflect(aIndex: Integer; const Decision: TBrainTickOutput; const Input: TBrainReflectInput);
begin
  TAgentBrain.Reflect(fAgents[aIndex], Decision, Input, fScratch);
end;

procedure TSimPopulation.ApplyStep(aIndex: Integer; const Output: TBrainTickOutput);
begin
  if fAgents[aIndex].Action = Output.RequestedAction then
    Inc(fAgents[aIndex].ActionAge)
  else
    fAgents[aIndex].ActionAge := 0;

  fAgents[aIndex].Action := Output.RequestedAction;
  fAgents[aIndex].ActionTarget := Output.RequestedTarget;
end;

procedure TSimPopulation.StepAgent(aIndex: Integer; const Input: TBrainTickInput);
begin
  ApplyStep(aIndex, Think(aIndex, Input));
end;

procedure TSimPopulation.Tick(const Input: TBrainTickInput);
begin
  for var i := 0 to High(fAgents) do
    StepAgent(i, Input);
end;

function TSimPopulation.GetMetabolicState(aAgentId: TAgentId): TMetabolicState;
begin
  Result := Default(TMetabolicState);
  Assert(aAgentId <= High(fAgents));

  Result.Age := fAgents[aAgentId].Age;
  Result.Reserves := fAgents[aAgentId].Reserves;
  Result.ReserveDelta := fAgents[aAgentId].ReserveDelta;
  Result.GeneSequence := fAgents[aAgentId].Genome.Sequence;
  Result.MoleculeFactors := fAgents[aAgentId].Genome.ConverterRatings;
  Result.ForageMoleculeWeights := fAgents[aAgentId].Genome.ForageMoleculeWeights;
  Result.DecisionWeights := fAgents[aAgentId].DecisionWeights;
end;

function TSimPopulation.StatePtr(aIndex: Integer): PAgentState;
begin
  Result := @fAgents[aIndex];
end;

{$IFDEF AGENT_DEBUG_TRACE}
function TSimPopulation.LastDecisionContext: TDecisionContext;
begin
  Result := fScratch.DecisionContext;
end;

procedure TSimPopulation.CaptureDecisionDebugTrace(aIndex, aGlobalTick: Integer;
  const Context: TDecisionContext; const Requested, Resolved: TBrainTickOutput;
  const ForageOutcome: TForageOutcome);
begin
  var trace: PAgentDecisionDebugTrace;
  trace := @fDecisionDebugTraces[aIndex];
  trace^.GlobalTick := aGlobalTick;
  trace^.AgentIndex := aIndex;
  trace^.Context := Context;
  trace^.Requested := Requested;
  trace^.Resolved := Resolved;
  trace^.ForageOutcome := ForageOutcome;
  trace^.HasValue := True;
end;

function TSimPopulation.DecisionDebugTracePtr(aIndex: Integer): PAgentDecisionDebugTrace;
begin
  Result := @fDecisionDebugTraces[aIndex];
end;
{$ENDIF}

end.
