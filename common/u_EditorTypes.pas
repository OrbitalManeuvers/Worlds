unit u_EditorTypes;

interface

uses System.Classes, System.SysUtils, System.JSON, Vcl.Graphics,

  u_EnvironmentTypes;

type
  TBiomeColorPalette = array[TBiomeMarker] of TColor;

type
  TRatingHelper = record helper for TRating
  private
    function getText: string;
    procedure setText(const Value: string);
  public
    property AsText: string read getText write setText;
  end;

function MoleculeToStr(aMolecule: TMolecule): string;
function StrToMolecule(const aValue: string; out aMolecule: TMolecule): Boolean;

implementation

function MoleculeToStr(aMolecule: TMolecule): string;
begin
  Result := MOLECULE_NAMES[aMolecule];
end;

function StrToMolecule(const aValue: string; out aMolecule: TMolecule): Boolean;
begin
  for var index := Low(TMolecule) to High(TMolecule) do
    if SameText(MOLECULE_NAMES[index], aValue) then
    begin
      aMolecule := TMolecule(index);
      Exit(True);
    end;
  Result := False;
end;

{ TRatingHelper }
function TRatingHelper.getText: string;
begin
  Result := RATING_NAMES[Self];
end;

procedure TRatingHelper.setText(const Value: string);
begin
  for var candidate := Low(TRating) to High(TRating) do
  begin
    if SameText(Value, candidate.AsText) then
    begin
      Self := candidate;
      Exit;
    end;
  end;
end;

end.
