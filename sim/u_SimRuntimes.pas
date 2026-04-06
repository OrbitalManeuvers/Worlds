unit u_SimRuntimes;

interface

uses u_AgentState, u_SimEnvironments, u_SimPopulations, u_SimClocks, u_SimQueriesIntf,
  u_SimCommandsIntf, u_AgentBrain;

const
  AGENT_BITE_SIZE = 0.1;  // temporary. move to sim params/genome

type
  TSimRuntime = class
  private const
    DEFAULT_DEATH_BIOMASS_AMOUNT = 1.0;
  private
    fEnvironment: TSimEnvironment;
    fPopulation: TSimPopulation;
    fSimQuery: ISimQuery;
    fSimCommand: ISimCommand;
    function CalculateAgentTickCost(const State: TAgentState): Single;
    function CalculateForageGain(const Reply: TConsumeCacheReply): Single;
    function ApplyAgentUpkeep(var State: TAgentState): Boolean;
    function ResolveRequestedStep(var State: TAgentState; const Requested: TBrainTickOutput): TBrainTickOutput;
    procedure ProcessAgentTick(aIndex: Integer; const Input: TBrainTickInput);
    procedure SetDayTick(const Value: TDayTick);
  public
    constructor Create;
    destructor Destroy; override;

    property Environment: TSimEnvironment read fEnvironment;
    property Population: TSimPopulation read fPopulation;

    property DayTick: TDayTick write SetDayTick;
  end;

implementation

uses System.Math, System.SysUtils, u_AgentGenome, u_AgentTypes, u_SimQueriesImpl,
  u_SimCommandsImpl;

{ TSimRuntime }

constructor TSimRuntime.Create;
begin
  inherited;
  fEnvironment := TSimEnvironment.Create;
  fPopulation := TSimPopulation.Create;
  fSimQuery := TSimQuery.Create(fEnvironment, fPopulation);
  fSimCommand := TSimCommand.Create(fEnvironment);
end;

destructor TSimRuntime.Destroy;
begin
  fSimQuery := nil;
  fSimCommand := nil;
  fEnvironment.Free;
  fPopulation.Free;
  inherited;
end;

function TSimRuntime.CalculateAgentTickCost(const State: TAgentState): Single;
  function GeneGenerationCost(aGeneClass: TGeneClass): Single;
  begin
    if not Assigned(aGeneClass) then
      Exit(0.0);

    // Placeholder scaling: each generation step above A adds a small upkeep tax.
    Result := (Ord(aGeneClass.GetGenerationCode) - Ord('A') + 1) * 0.01;
    if Result < 0.0 then
      Result := 0.0;
  end;
begin
  // Baseline metabolism comes from genome parameters.
  Result := Max(0.0, State.Genome.Metabolism);

  // Default floor keeps "zeroed" genomes from becoming immortal.
  if Result = 0.0 then
    Result := 0.05;

  // Sequence-driven upkeep scaffold. Tune weights once behavior loops exist.
  Result := Result
    + GeneGenerationCost(State.Genome.GeneMap.Energy)
    + GeneGenerationCost(State.Genome.GeneMap.Smell)
    + GeneGenerationCost(State.Genome.GeneMap.Sight)
    + GeneGenerationCost(State.Genome.GeneMap.MoveEval)
    + GeneGenerationCost(State.Genome.GeneMap.ForageEval)
    + GeneGenerationCost(State.Genome.GeneMap.ShelterEval)
    + GeneGenerationCost(State.Genome.GeneMap.ReproduceEval)
    + GeneGenerationCost(State.Genome.GeneMap.Cognition)
    + GeneGenerationCost(State.Genome.GeneMap.Converter);
end;

function TSimRuntime.ApplyAgentUpkeep(var State: TAgentState): Boolean;
begin
  State.Reserves := State.Reserves - CalculateAgentTickCost(State);
  Result := State.Reserves > 0.0;
  if not Result then
    State.Reserves := 0.0;
end;

function TSimRuntime.CalculateForageGain(const Reply: TConsumeCacheReply): Single;
begin
  // V0 digestion placeholder: reserve gain tracks consumed cache amount.
  Result := Reply.ConsumedAmount;
end;

function TSimRuntime.ResolveRequestedStep(var State: TAgentState;
  const Requested: TBrainTickOutput): TBrainTickOutput;
begin
  // Runtime resolution hook: adjust or reject requested actions based on world rules.
  Result := Requested;

  if (Requested.RequestedAction = acForage) and (Requested.RequestedTarget.TType = ttCache) then
  begin
    var forageCommand: IEnvironmentForageCommand;
    if Supports(fSimCommand, IEnvironmentForageCommand, forageCommand) then
    begin
      var reply: TConsumeCacheReply := Default(TConsumeCacheReply);

      var request: TConsumeCacheRequest;
      request.CacheId := Requested.RequestedTarget.CacheId;
      request.RequestedAmount := AGENT_BITE_SIZE;

      if forageCommand.TryConsumeCache(request, reply) then
      begin
        State.Reserves := State.Reserves + CalculateForageGain(reply);
      end
      else
      begin
        // Failed consume attempts should not pin the agent in an unavailable forage.
        Result.RequestedAction := acIdle;
      end;
    end;
  end;
end;

procedure TSimRuntime.ProcessAgentTick(aIndex: Integer; const Input: TBrainTickInput);
begin
  var state: TAgentState;
  if not fPopulation.TryGetAgentState(aIndex, state) then
    Exit;

  // Dead agents remain in population data but do not age or think.
  var wasAlive := state.Reserves > 0.0;
  if not wasAlive then
    Exit;

  // Age tracks ticks survived; this includes the tick where upkeep may cause death.
  Inc(state.Age);

  if not ApplyAgentUpkeep(state) then
  begin
    // Dead agents do not think or request actions.
    state.Action := acIdle;
    fPopulation.UpdateAgentState(aIndex, state);

    // Notify environment once at transition-to-death.
    fEnvironment.NotifyAgentDeath(state.Location, DEFAULT_DEATH_BIOMASS_AMOUNT);
    Exit;
  end;

  // Commit upkeep effects before the brain reads state.
  fPopulation.UpdateAgentState(aIndex, state);

  var requested := fPopulation.RequestAgentStep(aIndex, Input);
  var resolved := ResolveRequestedStep(state, requested);
  fPopulation.UpdateAgentState(aIndex, state);
  fPopulation.ApplyAgentStep(aIndex, resolved);
end;

procedure TSimRuntime.SetDayTick(const Value: TDayTick);
begin
  fEnvironment.DayTick := Value;

  var input: TBrainTickInput;
  input.IsNight := Value > High(TDaylightTicks);
  input.Query := fSimQuery;

  for var i := 0 to fPopulation.AgentCount - 1 do
    ProcessAgentTick(i, input);
end;

end.
