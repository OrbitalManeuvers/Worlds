unit u_SimPopulations;

interface

uses u_AgentState, u_AgentBrain;

type
  TSimPopulation = class
  private
    fAgents: TArray<TAgentState>;
    fScratch: TAgentScratch;
  public
    constructor Create;

    procedure SetAgentCount(aCount: Integer);

    function TryGetAgentState(aIndex: Integer; out State: TAgentState): Boolean;
    procedure UpdateAgentState(aIndex: Integer; const State: TAgentState);

    function RequestAgentStep(aIndex: Integer; const Input: TBrainTickInput): TBrainTickOutput;
    procedure ApplyAgentStep(aIndex: Integer; const Output: TBrainTickOutput);
    procedure StepAgent(aIndex: Integer; const Input: TBrainTickInput);

    procedure Tick(const Input: TBrainTickInput);

    function AgentCount: Integer;
    property Agents: TArray<TAgentState> read fAgents;

  end;

implementation

{ TSimPopulation }

constructor TSimPopulation.Create;
begin
  inherited;
end;

function TSimPopulation.AgentCount: Integer;
begin
  Result := Length(fAgents);
end;

procedure TSimPopulation.SetAgentCount(aCount: Integer);
begin
  if aCount < 0 then
    aCount := 0;

  SetLength(fAgents, aCount);
end;

function TSimPopulation.TryGetAgentState(aIndex: Integer;
  out State: TAgentState): Boolean;
begin
  Result := (aIndex >= 0) and (aIndex <= High(fAgents));
  if Result then
    State := fAgents[aIndex]
  else
    State := Default(TAgentState);
end;

procedure TSimPopulation.UpdateAgentState(aIndex: Integer;
  const State: TAgentState);
begin
  if (aIndex < 0) or (aIndex > High(fAgents)) then
    Exit;

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
