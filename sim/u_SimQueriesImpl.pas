unit u_SimQueriesImpl;

interface

uses System.SysUtils,
  u_EnvironmentTypes, u_SimPopulations, u_SimEnvironments, u_SimQueriesIntf;

type
  TSimQuery = class(TInterfacedObject, ISimQuery, IEnvironmentSmellQuery, IPopulationSightQuery)
  private
    fEnvironment: TSimEnvironment;
    fPopulation: TSimPopulation;

    { IEnvironmentSmellQuery }
    procedure GetGridSize(out Width, Height: Integer);
    procedure FillLocalFoodCaches(Location: Integer; Range: Single; var Buffer: TSmellCacheInfos; out Count: Integer);

    { IPopulationSightQuery }
    procedure FillLocalAgents(Location: Integer; Range: Single; var Buffer: TSightInfos; out Count: Integer);

  public
    constructor Create(aEnvironment: TSimEnvironment; aPopulation: TSimPopulation);
    destructor Destroy; override;
  end;

implementation

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

        if resource.SubstanceIndex > High(fEnvironment.Substances) then
          Continue;

        if Count >= Length(Buffer) then
          SetLength(Buffer, Count + 16);

        Buffer[Count].CellIndex := candidateCellIndex;
        Buffer[Count].CacheId := resourceIndex;
        Buffer[Count].Amount := resource.Amount;
        Buffer[Count].Substance := fEnvironment.Substances[resource.SubstanceIndex];

        Inc(Count);
      end;
    end;
  end;
end;

procedure TSimQuery.FillLocalAgents(Location: Integer; Range: Single; var Buffer: TSightInfos; out Count: Integer);
begin
  Count := 0;

end;

end.
