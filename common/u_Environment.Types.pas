unit u_Environment.Types;

interface

uses Vcl.Graphics,

  u_Worlds.Types;

const
  BIOME_GRID_SIZE = 32;

type
  TMolecule = (Alpha, Beta, Gamma, Biomass);
  TGrowableMolecule = TMolecule.Alpha .. TMolecule.Gamma;

  TBiomeMarker = Byte;
  TGridExtent = 0 .. BIOME_GRID_SIZE - 1;
  TBiomeGrid = array[TGridExtent, TGridExtent] of TBiomeMarker;

const
  RATING_NAMES: array[TRating] of string = ('Worst', 'Horrible', 'Bad', 'Normal', 'Good', 'Great', 'Best');
  MOLECULE_NAMES: array[TMolecule] of string = ('Alpha', 'Beta', 'Gamma', 'Biomass');

const
  KEY_NAME = 'name';
  KEY_DESCRIPTION = 'description';
  KEY_MOLECULE = 'molecule';
  KEY_PERCENT = 'percent';
  KEY_RECIPE = 'recipe';

  KEY_MARKER = 'marker';
  KEY_COLOR = 'color';

  KEY_GROWTH_RATE = 'growthRate';
  KEY_CAPACITY = 'capacity';
  KEY_SUNLIGHT = 'sunlight';
  KEY_MOBILITY = 'mobility';
  KEY_FOODS = 'foods';

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

uses System.SysUtils;

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
    if SameText(Value, candidate.AsText) then
    begin
      Self := candidate;
      Exit;
    end;
end;

end.
