unit u_SimPopulators;

interface

uses u_SimParams, u_SimPopulations;

type
  TWorldPopulator = class
  public
    class procedure Populate(aPopulation: TSimPopulation; aParams: TSimParams);
  end;

implementation

uses
  u_AgentState, u_AgentGenome;

{ TWorldPopulator }

// to consider:
// agent compositions (molecule ratings applied to smell/converter)
// agent locations
// initial biomass deposits (DOA chance)


class procedure TWorldPopulator.Populate(aPopulation: TSimPopulation; aParams: TSimParams);
var
  state: TAgentState;
  nextId: Cardinal;
  sequence: TGeneSequence;
begin
  aPopulation.AgentCount := aParams.Population.AgentCount;
  nextId := 1;


// Energy, Smell, Sight, Movement, Forage, Shelter, Reproduce, Cognition, Convert
  sequence.AsText := 'AABAAAAAA';

  for var i := 0 to aPopulation.AgentCount - 1 do
  begin
    if aPopulation.TryGetAgentState(i, state) then
    begin
      state.AgentId := nextId;
      Inc(nextId);

      state.Reserves := 10.0;

      TGeneSequencer.Populate(state.Genome.GeneMap, sequence);

      aPopulation.UpdateAgentState(i, state);
    end;
  end;



end;

end.
