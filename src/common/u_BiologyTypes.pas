unit u_BiologyTypes;

interface

uses u_EnvironmentTypes;

type
  TMoleculeRatings = class(TNamedEnvironmentObject)
  private
    fDescription: string;
    fRatings: array[TMolecule] of TRating;
    function GetRating(I: TMolecule): TRating;
    procedure SetRating(I: TMolecule; const Value: TRating);
    procedure SetDescription(const Value: string);
  public
    constructor Create;
    property Ratings[I: TMolecule]: TRating read GetRating write SetRating; default;
    property Description: string read fDescription write SetDescription;
  end;

implementation

{ TMoleculeRatings }

constructor TMoleculeRatings.Create;
begin
  inherited Create;
  for var molecule := Low(TMolecule) to High(TMolecule) do
    fRatings[molecule] := Normal;
  fRatings[Biomass] := Worst;  // worst means cannot convert/detect
end;

function TMoleculeRatings.GetRating(I: TMolecule): TRating;
begin
  Result := fRatings[I];
end;

procedure TMoleculeRatings.SetDescription(const Value: string);
begin
  if Value <> fDescription then
  begin
    fDescription := Value;
    Changed;
  end;
end;

procedure TMoleculeRatings.SetRating(I: TMolecule; const Value: TRating);
begin
  if fRatings[I] <> Value then
  begin
    fRatings[I] := Value;
    Changed;
  end;
end;

end.
