unit u_SimPopulations;

interface

uses u_AgentState, u_AgentBrain;

type
  TSimPopulation = class
  private
    const INVALID_INDEX = -1;
  private
    fAgents: TArray<TAgentState>;
    fScratch: TAgentScratch;
    fCellAgents: TArray<TArray<Integer>>;
    fIndexedAgentCell: TArray<Integer>;
    fIndexedAgentSlot: TArray<Integer>;

    procedure SetAgentCount(aCount: Integer);
    function GetAgentCount: Integer;
    function IsValidAgentIndex(aAgentIndex: Integer): Boolean;
    function IsValidCellIndex(aCellIndex: Integer): Boolean;
    procedure InitializeAgentIndexEntry(aAgentIndex: Integer);
    procedure ResizeIndexedAgents(aAgentCount: Integer);
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
    function TryGetAgentState(aIndex: Integer; out State: TAgentState): Boolean;
    procedure UpdateAgentState(aIndex: Integer; const State: TAgentState);

    function RequestAgentStep(aIndex: Integer; const Input: TBrainTickInput): TBrainTickOutput;
    procedure ApplyAgentStep(aIndex: Integer; const Output: TBrainTickOutput);
    procedure StepAgent(aIndex: Integer; const Input: TBrainTickInput);

    procedure Tick(const Input: TBrainTickInput);

    property AgentCount: Integer read GetAgentCount write SetAgentCount;
    property Agents: TArray<TAgentState> read fAgents;

  end;

implementation

{ TSimPopulation }

constructor TSimPopulation.Create;
begin
  inherited;
end;

function TSimPopulation.IsValidAgentIndex(aAgentIndex: Integer): Boolean;
begin
  Result := (aAgentIndex >= 0) and (aAgentIndex <= High(fIndexedAgentCell));
end;

function TSimPopulation.IsValidCellIndex(aCellIndex: Integer): Boolean;
begin
  Result := (aCellIndex >= 0) and (aCellIndex <= High(fCellAgents));
end;

procedure TSimPopulation.InitializeAgentIndexEntry(aAgentIndex: Integer);
begin
  if (aAgentIndex < 0) or (aAgentIndex > High(fIndexedAgentCell)) then
    Exit;

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
  fAgents[Result] := Default(TAgentState);
  UpdateAgentState(Result, State);
end;

procedure TSimPopulation.AddAgentToCell(aAgentIndex, aCellIndex: Integer);
begin
  if not IsValidAgentIndex(aAgentIndex) then
    Exit;

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
  if not IsValidAgentIndex(aAgentIndex) then
    Exit;

  var cellIndex := fIndexedAgentCell[aAgentIndex];
  var slotIndex := fIndexedAgentSlot[aAgentIndex];

  if not IsValidCellIndex(cellIndex) then
  begin
    InitializeAgentIndexEntry(aAgentIndex);
    Exit;
  end;

  var cellAgents := fCellAgents[cellIndex];
  if (slotIndex < 0) or (slotIndex > High(cellAgents)) then
  begin
    InitializeAgentIndexEntry(aAgentIndex);
    Exit;
  end;

  var lastSlot := High(cellAgents);
  if slotIndex <> lastSlot then
  begin
    var swappedAgent := cellAgents[lastSlot];
    cellAgents[slotIndex] := swappedAgent;

    if IsValidAgentIndex(swappedAgent) then
    begin
      fIndexedAgentCell[swappedAgent] := cellIndex;
      fIndexedAgentSlot[swappedAgent] := slotIndex;
    end;
  end;

  SetLength(cellAgents, lastSlot);
  fCellAgents[cellIndex] := cellAgents;
  InitializeAgentIndexEntry(aAgentIndex);
end;

procedure TSimPopulation.UpdateAgentLocation(aAgentIndex, aOldCell, aNewCell: Integer);
begin
  if not IsValidAgentIndex(aAgentIndex) then
    Exit;

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
end;

function TSimPopulation.TryGetAgentState(aIndex: Integer; out State: TAgentState): Boolean;
begin
  Result := (aIndex >= 0) and (aIndex <= High(fAgents));
  if Result then
    State := fAgents[aIndex]
  else
    State := Default(TAgentState);
end;

procedure TSimPopulation.UpdateAgentState(aIndex: Integer; const State: TAgentState);
begin
  if (aIndex < 0) or (aIndex > High(fAgents)) then
    Exit;

  var oldCell := fAgents[aIndex].Location;
  var newCell := State.Location;
  UpdateAgentLocation(aIndex, oldCell, newCell);

  fAgents[aIndex] := State;
end;

function TSimPopulation.RequestAgentStep(aIndex: Integer; const Input: TBrainTickInput): TBrainTickOutput;
begin
  if (aIndex < 0) or (aIndex > High(fAgents)) then
    Exit(Default(TBrainTickOutput));

  Result := TAgentBrain.Think(fAgents[aIndex], Input, fScratch);
end;

procedure TSimPopulation.ApplyAgentStep(aIndex: Integer; const Output: TBrainTickOutput);
begin
  if (aIndex < 0) or (aIndex > High(fAgents)) then
    Exit;

  // Population applies a resolved action. Runtime/sim can adjust Output before this call.
  fAgents[aIndex].Action := Output.RequestedAction;
  fAgents[aIndex].ActionTarget := Output.RequestedTarget;
end;

procedure TSimPopulation.StepAgent(aIndex: Integer; const Input: TBrainTickInput);
begin
  var output := RequestAgentStep(aIndex, Input);
  ApplyAgentStep(aIndex, output);
end;

procedure TSimPopulation.Tick(const Input: TBrainTickInput);
begin
  for var i := 0 to High(fAgents) do
    StepAgent(i, Input);
end;

end.
