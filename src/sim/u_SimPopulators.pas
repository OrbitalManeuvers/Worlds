unit u_SimPopulators;

interface

uses System.Types,
  u_SessionParameters, u_SimPopulations, u_SimEnvironments, u_BiologyTypes;

type
  TWorldPopulator = class
  private
    class function FindBarrenCell(aEnvironment: TSimEnvironment; aBarrenRadius: Integer): Integer;
    class function FindResourceCell(aEnvironment: TSimEnvironment; aMinResources: Integer): Integer;
    class function FindGroupCell(aEnvironment: TSimEnvironment;
      const aGroupRect: TRect; aFactor: Integer): Integer; static;
  public
    class procedure Populate(aPopulation: TSimPopulation; aEnvironment: TSimEnvironment; aParams: TUpscalerParameters);
  end;

  TDebugPopulator = class
  public
    class procedure PopulateAgent(aPopulation: TSimPopulation; aAgentIndex, aAgentId, aLocation: Integer;
      aConverterRatings, aSmellRatings: TMoleculeRatings; const aGeneSequence: string);
  end;

implementation

uses System.Math,
  u_AgentState, u_AgentGenome, u_EnvironmentTypes;

const
  // converter efficiency scale (energy gain weighting)
  CONVERTER_RATING_FACTOR: array[TRating] of Single = (0.00, 0.20, 0.45, 0.75, 0.88, 0.95, 1.00);
  // smell sensitivity scale (detection weighting)
  SMELL_RATING_FACTOR: array[TRating] of Single = (0.00, 0.35, 0.65, 1.00, 1.20, 1.40, 1.60);
  INITIAL_TICKS_SINCE_REPRODUCTION = 0;

procedure ApplyDeltaGeneGates(var State: TAgentState);
begin
  if Assigned(State.Genome.GeneMap.Smell) and (State.Genome.GeneMap.Smell.GetGenerationCode = 'A') then
    State.Genome.SmellRatings[Delta] := 0.0;

  if Assigned(State.Genome.GeneMap.Converter) and (State.Genome.GeneMap.Converter.GetGenerationCode = 'A') then
    State.Genome.ConverterRatings[Delta] := 0.0;
end;


{ TWorldPopulator }

// to consider:
// agent compositions (molecule ratings applied to smell/converter)
// agent locations

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

class function TWorldPopulator.FindGroupCell(aEnvironment: TSimEnvironment;
  const aGroupRect: TRect; aFactor: Integer): Integer;
begin
  Result := 0;

  if not Assigned(aEnvironment) then
    Exit;

  var width := aEnvironment.Dimensions.cx;
  var height := aEnvironment.Dimensions.cy;
  if (width <= 0) or (height <= 0) then
    Exit;

  var factor := Max(1, aFactor);

  // Convert authored rect to sim coordinates.
  var simLeft   := aGroupRect.Left   * factor;
  var simTop    := aGroupRect.Top    * factor;
  var simRight  := aGroupRect.Right  * factor - 1;
  var simBottom := aGroupRect.Bottom * factor - 1;

  // Clamp to valid sim bounds.
  simLeft   := Max(0, Min(simLeft,   width  - 1));
  simTop    := Max(0, Min(simTop,    height - 1));
  simRight  := Max(0, Min(simRight,  width  - 1));
  simBottom := Max(0, Min(simBottom, height - 1));

  if (simRight < simLeft) or (simBottom < simTop) then
    Exit;

  // Pick a random cell within the sim-space rect.
  var x := simLeft + Random(simRight - simLeft + 1);
  var y := simTop  + Random(simBottom - simTop  + 1);
  Result := (y * width) + x;
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

class procedure TWorldPopulator.Populate(aPopulation: TSimPopulation; aEnvironment: TSimEnvironment; aParams: TUpscalerParameters);
const
  INVALID_CELL = -1;
var
  nextId: Integer;
  sequence: TGeneSequence;
  location: Integer;
begin
  if Assigned(aEnvironment) then
    aPopulation.SetCellCount(Length(aEnvironment.Cells))
  else
    aPopulation.SetCellCount(0);

  aPopulation.AgentCount := aParams.Population.AgentCount;
  nextId := 1;

  sequence.Init;

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
    var state := aPopulation.GetAgentState(i);
    state.AgentId := nextId;
    Inc(nextId);

    if aParams.Population.Scheme = psGrouped then
      state.Location := FindGroupCell(aEnvironment, aParams.Population.GroupRect, aParams.Factor)
    else
      state.Location := location;

    state.WanderTarget := -1;

    state.Reserves := 5.0;
    state.TicksSinceReproduction := INITIAL_TICKS_SINCE_REPRODUCTION;
    TGeneSequencer.Populate(state.Genome.GeneMap, sequence);

    state.Genome.SmellEdgeRetention := 0.25;

    // assign default smell and digestion profiles
    for var molecule := Low(TMolecule) to High(TMolecule) do
      state.Genome.SmellRatings[molecule] := SMELL_RATING_FACTOR[Normal];
    for var molecule := Low(TMolecule) to High(TMolecule) do
      state.Genome.ConverterRatings[molecule] := CONVERTER_RATING_FACTOR[Normal];

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
                    state.Genome.SmellRatings[molecule] := SMELL_RATING_FACTOR[rule.Ratings[molecule]];

                  Include(targetsApplied, rtSmell);
                end;
              end;
            rtConverter:
              begin
                if Assigned(rule.Ratings) then
                begin
                  for var molecule := Low(TMolecule) to High(TMolecule) do
                    state.Genome.ConverterRatings[molecule] := CONVERTER_RATING_FACTOR[rule.Ratings[molecule]];

                  Include(targetsApplied, rtConverter);
                end;
              end;
          end;

        end;
      end;
    end;

    ApplyDeltaGeneGates(state^);

    aPopulation.NotifyLocationChanged(i, INVALID_CELL, state.Location);
  end;

end;

{ TDebugPopulator }

class procedure TDebugPopulator.PopulateAgent(aPopulation: TSimPopulation;
  aAgentIndex, aAgentId, aLocation: Integer;
  aConverterRatings, aSmellRatings: TMoleculeRatings; const aGeneSequence: string);
var
  sequence: TGeneSequence;
begin
  var state := aPopulation.GetAgentState(aAgentIndex);

  state.AgentId := aAgentId;
  state.Location := aLocation;
  state.WanderTarget := -1;
  state.Reserves := 5.0;
  state.TicksSinceReproduction := INITIAL_TICKS_SINCE_REPRODUCTION;

  state.Genome.SmellEdgeRetention := 0.25;
  sequence.AsText := aGeneSequence;
  TGeneSequencer.Populate(state.Genome.GeneMap, sequence);

  // converter
  for var convertMolecule := Low(TMolecule) to High(TMolecule) do
  begin
    var value: Single := CONVERTER_RATING_FACTOR[Normal];
    if Assigned(aConverterRatings) then
      value := CONVERTER_RATING_FACTOR[aConverterRatings[convertMolecule]];
    state.Genome.ConverterRatings[convertMolecule] := value;
  end;

  // smell
  for var smellMolecule := Low(TMolecule) to High(TMolecule) do
  begin
    var value: Single := SMELL_RATING_FACTOR[Normal];
    if Assigned(aSmellRatings) then
      value := SMELL_RATING_FACTOR[aSmellRatings[smellMolecule]];
    state.Genome.SmellRatings[smellMolecule] := value;
  end;

  ApplyDeltaGeneGates(state^);
end;

end.
