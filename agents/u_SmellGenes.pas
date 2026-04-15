unit u_SmellGenes;

interface

uses u_AgentTypes, u_AgentGenome, u_SimQueriesIntf;

type
  TBasicSmell = class(TSmellGene)
  public
    class function Scan(Location: Cardinal; const Params: TSmellParams; const Query: ISimQuery;
      var Scratch: TSmellScanScratch): TSmellReport; override;
  end;

implementation

uses System.SysUtils, u_EnvironmentTypes;

const
  MAX_SMELL_QUERY_RADIUS = 2.0;
  MOLECULE_PRESENT_EPSILON = 0.000001;
  SIGNAL_COMPARE_EPSILON = 0.000001;

function TotalSignal(const Detail: TSmellDetails): Single;
begin
  Result := 0.0;
  for var molecule := Low(TMolecule) to High(TMolecule) do
    Result := Result + Detail.MoleculeStrength[molecule];
end;

function CompareSmellDetails(const Left, Right: TSmellDetails): Integer;
begin
  // Primary: stronger signal first.
  var signalDiff := TotalSignal(Left) - TotalSignal(Right);
  if Abs(signalDiff) > SIGNAL_COMPARE_EPSILON then
  begin
    if signalDiff > 0.0 then
      Exit(-1);
    Exit(1);
  end;

  // Secondary: shorter distance first.
  if Left.Directions.Distance <> Right.Directions.Distance then
  begin
    if Left.Directions.Distance < Right.Directions.Distance then
      Exit(-1);
    Exit(1);
  end;

  // Tertiary: lower cache id first for deterministic tie-breaking.
  if Left.CacheId < Right.CacheId then
    Exit(-1);
  if Left.CacheId > Right.CacheId then
    Exit(1);

  Result := 0;
end;

procedure SortSmellDetails(var Details: array of TSmellDetails);
begin
  // Insertion sort keeps implementation small and deterministic for tiny local buffers.
  for var i := 1 to High(Details) do
  begin
    var current := Details[i];
    var j := i - 1;
    while (j >= 0) and (CompareSmellDetails(current, Details[j]) < 0) do
    begin
      Details[j + 1] := Details[j];
      Dec(j);
    end;
    Details[j + 1] := current;
  end;
end;

function Clamp01(const Value: Single): Single;
begin
  if Value < 0.0 then
    Exit(0.0);
  if Value > 1.0 then
    Exit(1.0);
  Result := Value;
end;

function QuantizeEffectiveRadius(const Range: Single): Integer;
begin
  var clampedRange := Range;
  if clampedRange < 0.0 then
    clampedRange := 0.0
  else if clampedRange > MAX_SMELL_QUERY_RADIUS then
    clampedRange := MAX_SMELL_QUERY_RADIUS;

  // Tie-at-half rounds up after clamping.
  Result := Trunc(clampedRange + 0.5);
end;

function LinearDistanceFalloff(const Distance, EffectiveRadius: Integer): Single;
begin
  if EffectiveRadius <= 0 then
    Exit(1.0);

  if Distance >= EffectiveRadius then
    Exit(0.0);

  Result := 1.0 - (Distance / EffectiveRadius);
end;

function SignDelta(const Value: Integer): Integer;
begin
  if Value < 0 then
    Exit(-1);
  if Value > 0 then
    Exit(1);
  Result := 0;
end;

function DirectionFromDelta(dx, dy: Integer): TMoveDirection;
begin
  case SignDelta(dy) of
    -1:
      case SignDelta(dx) of
        -1: Result := mdNorthWest;
         0: Result := mdNorth;
      else
        Result := mdNorthEast;
      end;
     0:
      case SignDelta(dx) of
        -1: Result := mdWest;
         0: Result := mdNorth; // placeholder; direction is not semantically valid for distance 0.
      else
        Result := mdEast;
      end;
  else
    case SignDelta(dx) of
      -1: Result := mdSouthWest;
       0: Result := mdSouth;
    else
      Result := mdSouthEast;
    end;
  end;
end;

{ TBasicSmell }

class function TBasicSmell.Scan(Location: Cardinal; const Params: TSmellParams; const Query: ISimQuery;
  var Scratch: TSmellScanScratch): TSmellReport;
begin
  Result.Count := 0;
  SetLength(Result.Details, 0);
  Scratch.Count := 0;

  var smellQuery: IEnvironmentSmellQuery;
  if Supports(Query, IEnvironmentSmellQuery, smellQuery) then
  begin
    var effectiveRadius := QuantizeEffectiveRadius(Params.Range);

    var width := 0;
    var height := 0;
    smellQuery.GetGridSize(width, height);

    smellQuery.FillLocalFoodCaches(Location, Params.Range, Scratch.Buffer, Scratch.Count);
    Result.Count := Scratch.Count;
    SetLength(Result.Details, Scratch.Count);

    var originX := 0;
    var originY := 0;
    if (width > 0) and (height > 0) then
    begin
      originX := Integer(Location) mod width;
      originY := Integer(Location) div width;
    end;

    for var i := 0 to Scratch.Count - 1 do
    begin
      var distance := 0;
      var direction := mdNorth; // placeholder for local-cell/no-grid cases.

      if (width > 0) and (height > 0) then
      begin
        var cacheX := Scratch.Buffer[i].CellIndex mod width;
        var cacheY := Scratch.Buffer[i].CellIndex div width;

        var dx := cacheX - originX;
        var dy := cacheY - originY;

        distance := Abs(dx);
        if Abs(dy) > distance then
          distance := Abs(dy);

        direction := DirectionFromDelta(dx, dy);
      end;

      Result.Details[i].Directions.Direction := direction;
      if distance > High(Word) then
        Result.Details[i].Directions.Distance := High(Word)
      else
        Result.Details[i].Directions.Distance := distance;

      var distanceFalloff := LinearDistanceFalloff(distance, effectiveRadius);

      Result.Details[i].CacheId := Scratch.Buffer[i].CacheId;

      Result.Details[i].MoleculesPresent := [];

      var ratedStrength: array[TMolecule] of Single;
      var shareByMolecule: array[TMolecule] of Single;
      var totalBaseSignal := 0.0;
      var totalRatedSignal := 0.0;
      var presentCount := 0;

      for var molecule := Low(TMolecule) to High(TMolecule) do
      begin
        shareByMolecule[molecule] := Scratch.Buffer[i].Substance[molecule] / 100.0;

        if shareByMolecule[molecule] > 0.0 then
          Inc(presentCount);

        var rating := Params.Ratings[molecule];
        if rating < 0.0 then
          rating := 0.0;

        var baseStrength := Scratch.Buffer[i].Amount * shareByMolecule[molecule];
        ratedStrength[molecule] := baseStrength * rating;

        totalBaseSignal := totalBaseSignal + baseStrength;
        totalRatedSignal := totalRatedSignal + ratedStrength[molecule];
      end;

      var fidelity := 0.0;
      if totalBaseSignal > 0.0 then
        fidelity := Clamp01(totalRatedSignal / totalBaseSignal);

      var uniformShare := 0.0;
      if presentCount > 0 then
        uniformShare := 1.0 / presentCount;

      for var molecule := Low(TMolecule) to High(TMolecule) do
      begin
        if shareByMolecule[molecule] <= 0.0 then
        begin
          Result.Details[i].MoleculeStrength[molecule] := 0.0;
          Continue;
        end;

        var ratedShare := uniformShare;
        if totalRatedSignal > 0.0 then
          ratedShare := ratedStrength[molecule] / totalRatedSignal;

        var perceivedShare := (fidelity * ratedShare) + ((1.0 - fidelity) * uniformShare);
        var attenuatedStrength := (totalRatedSignal * perceivedShare) * distanceFalloff;

        Result.Details[i].MoleculeStrength[molecule] := attenuatedStrength;
        if attenuatedStrength > MOLECULE_PRESENT_EPSILON then
          Include(Result.Details[i].MoleculesPresent, molecule);
      end;
    end;

    if Result.Count > 1 then
      SortSmellDetails(Result.Details);
  end;
end;

initialization
  GlobalGeneRegistry.RegisterGene(TBasicSmell);

end.
