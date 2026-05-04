unit u_SimQueriesImpl;

interface

uses System.SysUtils,
  u_AgentTypes, u_EnvironmentTypes, u_SimPopulations, u_SimEnvironments, u_SimQueriesIntf;

type
  TSimQuery = class(TInterfacedObject, ISimQuery, IEnvironmentSmellQuery, IPopulationSightQuery, IPopulationCrowdingQuery)
  private
    fEnvironment: TSimEnvironment;
    fPopulation: TSimPopulation;

    { IEnvironmentSmellQuery }
    procedure GetGridSize(out Width, Height: Integer);
    procedure FillLocalFoodCaches(Location: Integer; Range: Single; var Buffer: TSmellCacheInfos; out Count: Integer);

    { IPopulationSightQuery }
    procedure FillLocalAgents(Location: Integer; Range: Single; var Buffer: TSightInfos; out Count: Integer);

    { IPopulationCrowdingQuery }
    function CountAgentsWithinRadius(CellIndex, Radius: Integer): Integer;

  public
    constructor Create(aEnvironment: TSimEnvironment; aPopulation: TSimPopulation);
    destructor Destroy; override;
  end;

implementation

uses u_AgentState;

const
  // Ignore trace residue so smell only reports caches with meaningful mass.
  MIN_SMELL_DETECTABLE_AMOUNT = 0.02;

{ TSimQuery }

constructor TSimQuery.Create(aEnvironment: TSimEnvironment; aPopulation: TSimPopulation);
begin
  inherited Create;
  fEnvironment := aEnvironment;
  fPopulation := aPopulation;
end;

destructor TSimQuery.Destroy;
begin

  inherited;
end;

procedure TSimQuery.GetGridSize(out Width, Height: Integer);
begin
  Width := 0;
  Height := 0;

  if not Assigned(fEnvironment) then
    Exit;

  Width := fEnvironment.Dimensions.cx;
  Height := fEnvironment.Dimensions.cy;
end;


procedure TSimQuery.FillLocalFoodCaches(Location: Integer; Range: Single; var Buffer: TSmellCacheInfos; out Count: Integer);
begin
  Count := 0;

  if not Assigned(fEnvironment) then
    Exit;

  var width := fEnvironment.Dimensions.cx;
  var height := fEnvironment.Dimensions.cy;
  if (width <= 0) or (height <= 0) then
    Exit;

  if (Location < 0) or (Location > High(fEnvironment.Cells)) then
    Exit;

  // Clamp and quantize range into bounded neighborhood tiers: 0, 1, 2.
  var clampedRange := Range;
  if clampedRange < 0.0 then
    clampedRange := 0.0
  else if clampedRange > 2.0 then
    clampedRange := 2.0;

  // Tie-at-half rounds up because range is non-negative after clamping.
  var effectiveRadius := Trunc(clampedRange + 0.5);

  var originX := Location mod width;
  var originY := Location div width;

  // First, collect regular resource caches
  for var dy := -effectiveRadius to effectiveRadius do
  begin
    var candidateY := originY + dy;
    if (candidateY < 0) or (candidateY >= height) then
      Continue;

    for var dx := -effectiveRadius to effectiveRadius do
    begin
      if (Abs(dx) > effectiveRadius) or (Abs(dy) > effectiveRadius) then
        Continue;

      var candidateX := originX + dx;
      if (candidateX < 0) or (candidateX >= width) then
        Continue;

      var candidateCellIndex := (candidateY * width) + candidateX;
      var cell := fEnvironment.Cells[candidateCellIndex];
      if cell.ResourceCount <= 0 then
        Continue;

      for var i := 0 to cell.ResourceCount - 1 do
      begin
        var resourceIndex := Integer(cell.ResourceStart) + i;
        if (resourceIndex < 0) or (resourceIndex > High(fEnvironment.Resources)) then
          Continue;

        var resource := fEnvironment.Resources[resourceIndex];
        if resource.Amount <= MIN_SMELL_DETECTABLE_AMOUNT then
          Continue;

        if resource.SubstanceIndex > High(fEnvironment.SubstanceEntries) then
          Continue;

        if Count >= Length(Buffer) then
          SetLength(Buffer, Count + 16);

        Buffer[Count].CellIndex := candidateCellIndex;
        Buffer[Count].Cache.Kind := ckResource;
        Buffer[Count].Cache.Index := resourceIndex;
        Buffer[Count].Amount := resource.Amount;
        Buffer[Count].Substance := fEnvironment.SubstanceEntries[resource.SubstanceIndex].Substance;

        Inc(Count);
      end;
    end;
  end;

  // Then, collect biomass caches as explicit biomass cache references.
  for var cacheIndex := 0 to High(fEnvironment.BiomassCaches) do
  begin
    var cache := fEnvironment.BiomassCaches[cacheIndex];
    if cache.Amount <= MIN_SMELL_DETECTABLE_AMOUNT then
      Continue;

    var cacheCellX := cache.CellIndex mod width;
    var cacheCellY := cache.CellIndex div width;

    var dx := cacheCellX - originX;
    var dy := cacheCellY - originY;

    if (Abs(dx) > effectiveRadius) or (Abs(dy) > effectiveRadius) then
      Continue;

    if (cacheCellX < 0) or (cacheCellX >= width) or (cacheCellY < 0) or (cacheCellY >= height) then
      Continue;

    if Count >= Length(Buffer) then
      SetLength(Buffer, Count + 16);

    Buffer[Count].CellIndex := cache.CellIndex;
    Buffer[Count].Cache.Kind := ckBiomass;
    Buffer[Count].Cache.Index := cacheIndex;
    Buffer[Count].Amount := cache.Amount;
    Buffer[Count].Substance := BIOMASS_SUBSTANCE;

    Inc(Count);
  end;
end;

function TSimQuery.CountAgentsWithinRadius(CellIndex, Radius: Integer): Integer;
begin
  Result := 0;

  if not Assigned(fEnvironment) or not Assigned(fPopulation) then
    Exit;

  var width := fEnvironment.Dimensions.cx;
  var height := fEnvironment.Dimensions.cy;
  if (width <= 0) or (height <= 0) then
    Exit;

  if (CellIndex < 0) or (CellIndex > High(fEnvironment.Cells)) then
    Exit;

  var effectiveRadius := Radius;
  if effectiveRadius < 0 then
    effectiveRadius := 0
  else if effectiveRadius > 2 then
    effectiveRadius := 2;

  var originX := CellIndex mod width;
  var originY := CellIndex div width;

  for var dy := -effectiveRadius to effectiveRadius do
  begin
    var candidateY := originY + dy;
    if (candidateY < 0) or (candidateY >= height) then
      Continue;

    for var dx := -effectiveRadius to effectiveRadius do
    begin
      if (Abs(dx) > effectiveRadius) or (Abs(dy) > effectiveRadius) then
        Continue;

      var candidateX := originX + dx;
      if (candidateX < 0) or (candidateX >= width) then
        Continue;

      var candidateCellIndex := (candidateY * width) + candidateX;
      var cellAgents: TArray<Integer>;
      if not fPopulation.TryGetCellAgents(candidateCellIndex, cellAgents) then
        Continue;

      for var i := 0 to High(cellAgents) do
      begin
        var state: TAgentState;
        if not fPopulation.TryGetAgentState(cellAgents[i], state) then
          Continue;

        if state.Reserves <= 0.0 then
          Continue;

        Inc(Result);
      end;
    end;
  end;
end;

procedure TSimQuery.FillLocalAgents(Location: Integer; Range: Single; var Buffer: TSightInfos; out Count: Integer);
begin
  Count := 0;

  if not Assigned(fEnvironment) or not Assigned(fPopulation) then
    Exit;

  var width := fEnvironment.Dimensions.cx;
  var height := fEnvironment.Dimensions.cy;
  if (width <= 0) or (height <= 0) then
    Exit;

  if (Location < 0) or (Location > High(fEnvironment.Cells)) then
    Exit;

  // Keep range behavior aligned with smell for bounded local-neighborhood queries.
  var clampedRange := Range;
  if clampedRange < 0.0 then
    clampedRange := 0.0
  else if clampedRange > 2.0 then
    clampedRange := 2.0;

  var effectiveRadius := Trunc(clampedRange + 0.5);

  var originX := Location mod width;
  var originY := Location div width;

  for var dy := -effectiveRadius to effectiveRadius do
  begin
    var candidateY := originY + dy;
    if (candidateY < 0) or (candidateY >= height) then
      Continue;

    for var dx := -effectiveRadius to effectiveRadius do
    begin
      if (Abs(dx) > effectiveRadius) or (Abs(dy) > effectiveRadius) then
        Continue;

      var candidateX := originX + dx;
      if (candidateX < 0) or (candidateX >= width) then
        Continue;

      var candidateCellIndex := (candidateY * width) + candidateX;

      var cellAgents: TArray<Integer>;
      if not fPopulation.TryGetCellAgents(candidateCellIndex, cellAgents) then
        Continue;

      var distance := Abs(dx);
      if Abs(dy) > distance then
        distance := Abs(dy);

      for var i := 0 to High(cellAgents) do
      begin
        var agentIndex := cellAgents[i];
        var state: TAgentState;
        if not fPopulation.TryGetAgentState(agentIndex, state) then
          Continue;

        // Dead agents remain in population storage but do not participate in local-agent sensing.
        if state.Reserves <= 0.0 then
          Continue;

        if Count >= Length(Buffer) then
          SetLength(Buffer, Count + 16);

        Buffer[Count].AgentId := state.AgentId;
        Buffer[Count].Location := state.Location;
        Buffer[Count].Distance := distance;
        Inc(Count);
      end;
    end;
  end;

end;

end.
