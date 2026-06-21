unit u_SimPopulations;

interface

uses u_SimTypes, u_AgentGenome, u_AgentState, u_AgentBrain, u_BrainProbes,
  u_RuntimeTypes, u_BrainTypes, u_PopulationTypes;

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
    fProbe: TBrainProbe;

    procedure SetAgentCount(aCount: Integer);
    function GetAgentCount: Integer;
    function IsValidCellIndex(aCellIndex: Integer): Boolean;
    procedure InitializeAgentIndexEntry(aAgentIndex: Integer);
    procedure ResizeIndexedAgents(aAgentCount: Integer);
    procedure ResetLocationIndex;
    procedure AddAgentToCell(aAgentIndex, aCellIndex: Integer);
    procedure RemoveAgentFromCell(aAgentIndex: Integer);
    procedure UpdateAgentLocation(aAgentIndex, aOldCell, aNewCell: Integer);
  public
    constructor Create;
    destructor Destroy; override;

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

    property AgentCount: Integer read GetAgentCount write SetAgentCount;
    property Agents: TArray<TAgentState> read fAgents;
    property Probe: TBrainProbe read fProbe;
  end;

implementation

{ TSimPopulation }

constructor TSimPopulation.Create;
begin
  inherited;
  fProbe := TBrainProbe.Create;
end;

destructor TSimPopulation.Destroy;
begin
  fProbe.Free;
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
end;

function TSimPopulation.Think(aIndex: Integer; const Input: TBrainTickInput): TBrainTickOutput;
begin
  var agentId := fAgents[aIndex].AgentId;
  fProbe.BeforeTick(agentId);

  Result := TAgentBrain.Think(fAgents[aIndex], Input, fScratch);

  if fProbe.Active then
  begin
    fProbe.S.RawScores := Result.Scores;
    fProbe.S.DampenedScores := Result.DampenedScores;
    fProbe.S.FinalAction := Result.RequestedAction;
    fProbe.S.FinalTarget := Result.RequestedTarget;
  end;
end;

procedure TSimPopulation.Reflect(aIndex: Integer; const Decision: TBrainTickOutput; const Input: TBrainReflectInput);
begin
  TAgentBrain.Reflect(fAgents[aIndex], Decision, Input, fScratch);

  var agentId := fAgents[aIndex].AgentId;
  fProbe.AfterTick(agentId);
end;

procedure TSimPopulation.ApplyStep(aIndex: Integer; const Output: TBrainTickOutput);
begin
  if fAgents[aIndex].Action = Output.RequestedAction then
    Inc(fAgents[aIndex].ActionAge)
  else
  begin
    fAgents[aIndex].ActionAge := 1;
    fAgents[aIndex].ActionProgress := 0;
  end;

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

end.
