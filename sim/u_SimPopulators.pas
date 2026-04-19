unit u_SimPopulators;

interface

uses u_SimParams, u_SimPopulations, u_SimEnvironments;

type
  TWorldPopulator = class
  private
    class function FindBarrenCell(aEnvironment: TSimEnvironment; aBarrenRadius: Integer): Integer;
    class function FindResourceCell(aEnvironment: TSimEnvironment; aMinResources: Integer): Integer;
  public
    class procedure Populate(aPopulation: TSimPopulation; aEnvironment: TSimEnvironment; aParams: TSimParams);
  end;

implementation

uses
  u_AgentState, u_AgentGenome, u_EnvironmentTypes;

const
  // convert TMoleculeRating to TMoleculeFactor
  RATING_FACTOR: array[TRating] of Single = (0.00, 0.30, 0.65, 1.00, 1.25, 1.50, 1.80);


{ TWorldPopulator }

// to consider:
// agent compositions (molecule ratings applied to smell/converter)
// agent locations
// initial biomass deposits (DOA chance)


// find a cell. optionally called once at startup.
// aBarrenRadius:
// = 0 means no neighbor checking
// > 0 means check there's no food within radius
class function TWorldPopulator.FindBarrenCell(aEnvironment: TSimEnvironment; aBarrenRadius: Integer): Integer;
begin
  Result := 0;
  
  if not Assigned(aEnvironment) then
    Exit;
  
  var width := aEnvironment.Dimensions.cx;
  var height := aEnvironment.Dimensions.cy;
  if (width <= 0) or (height <= 0) then
    Exit;
  
  if aBarrenRadius < 0 then
    aBarrenRadius := 0;

  for var cellIndex := 0 to High(aEnvironment.Cells) do
  begin
    // Anchor cell must be barren regardless of neighborhood policy.
    if aEnvironment.Cells[cellIndex].ResourceCount > 0 then
      Continue;
  
    var hasNearbyResources := False;
    if aBarrenRadius > 0 then
    begin
      var originX := cellIndex mod width;
      var originY := cellIndex div width;
  
      for var dy := -aBarrenRadius to aBarrenRadius do
      begin
        var y := originY + dy;
        if (y < 0) or (y >= height) then
          Continue;
  
        for var dx := -aBarrenRadius to aBarrenRadius do
        begin
          var x := originX + dx;
          if (x < 0) or (x >= width) then
            Continue;
  
          var neighborIndex := (y * width) + x;
          if aEnvironment.Cells[neighborIndex].ResourceCount > 0 then
          begin
            hasNearbyResources := True;
            Break;
          end;
        end;
  
        if hasNearbyResources then
          Break;
      end;
    end;
  
    if hasNearbyResources then
      Continue;

    Exit(cellIndex);
  end;
  
  // If strict radius produced no candidates, fall back to any barren anchor cell.
  if aBarrenRadius > 0 then
    Exit(FindBarrenCell(aEnvironment, 0));

end;

class function TWorldPopulator.FindResourceCell(aEnvironment: TSimEnvironment; aMinResources: Integer): Integer;
begin
  Result := 0;

  if not Assigned(aEnvironment) then
    Exit;

  for var cellIndex := 0 to High(aEnvironment.Cells) do
  begin
    if aEnvironment.Cells[cellIndex].ResourceCount > aMinResources then
      Exit(cellIndex);
  end;

end;

class procedure TWorldPopulator.Populate(aPopulation: TSimPopulation; aEnvironment: TSimEnvironment; aParams: TSimParams);
var
  state: TAgentState;
  nextId: Cardinal;
  sequence: TGeneSequence;
  location: Integer;
begin
  aPopulation.AgentCount := aParams.Population.AgentCount;
  nextId := 1;


// Energy, Smell, Sight, Movement, Forage, Shelter, Reproduce, Cognition, Convert
//  sequence.AsText := 'AABAAAAAA';
  sequence.AsText := 'AAAAAAAAA';

  // for now, all agents go to the same location
  case aParams.Population.Scheme of
    psOnSingleResource: location := FindResourceCell(aEnvironment, 1);
    psOnMultiResource: location := FindResourceCell(aEnvironment, 2);
    psOnBarren: location := FindBarrenCell(aEnvironment, 0);
    psOnBarrenNextToResource: location := FindBarrenCell(aEnvironment, 1);
    psOnBarrenCloseToResource: location := FindBarrenCell(aEnvironment, 2);
  else
    location := 0;
  end;

  for var i := 0 to aPopulation.AgentCount - 1 do
  begin
    if aPopulation.TryGetAgentState(i, state) then
    begin
      state.AgentId := nextId;
      Inc(nextId);

      state.Location := location;
      state.Reserves := 5.0;
      TGeneSequencer.Populate(state.Genome.GeneMap, sequence);

      state.Genome.SmellRange := 2.0;
      state.Genome.Metabolism := 0.05;

      // assign default smell and digestion profiles
      for var molecule := Low(TMolecule) to High(TMolecule) do
        state.Genome.SmellRatings[molecule] := 1.0;
      for var molecule := Low(TMolecule) to High(TMolecule) do
        state.Genome.ConverterRatings[molecule] := 1.0;

      var targetsApplied: TRuleTargets := [];
      for var rule in aParams.Population.Rules do
      begin
        if (not (rule.Target in targetsApplied)) and (rule.Chance > 0) then
        begin
          var dice := Random(100);
          if dice < rule.Chance then
          begin
            case rule.Target of
              rtSmell:
                begin
                  if Assigned(rule.Ratings) then
                  begin
                    for var molecule := Low(TMolecule) to High(TMolecule) do
                      state.Genome.SmellRatings[molecule] := RATING_FACTOR[rule.Ratings[molecule]];

                    Include(targetsApplied, rtSmell);
                  end;
                end;
              rtConverter:
                begin
                  if Assigned(rule.Ratings) then
                  begin
                    for var molecule := Low(TMolecule) to High(TMolecule) do
                      state.Genome.ConverterRatings[molecule] := RATING_FACTOR[rule.Ratings[molecule]];

                    Include(targetsApplied, rtConverter);
                  end;
                end;
            end;

          end;
        end;
      end;

      aPopulation.UpdateAgentState(i, state);
    end;
  end;

end;

end.
