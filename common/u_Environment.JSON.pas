unit u_Environment.JSON;

interface

uses System.SysUtils, System.JSON,

  u_Worlds.Types,
  u_Environment.Types;

type
  TRecipeHelper = class helper for TRecipe
  private
    function getJSON: TJSONObject;
    procedure setJSON(const Value: TJSONObject);
  public
    property AsJSON: TJSONObject read getJSON write setJSON;
  end;

  TFoodHelper = class helper for TFood
  private
    function getJSON: TJSONObject;
    procedure setJSON(const Value: TJSONObject);
  public
    property AsJSON: TJSONObject read getJSON write setJSON;
  end;

  TRatingHelper = record helper for TRating
  private
    function getText: string;
    procedure setText(const Value: string);
  public
    property AsText: string read getText write setText;
  end;

implementation

uses System.StrUtils;

const
  KEY_NAME = 'name';
  KEY_MOLECULE = 'molecule';
  KEY_PERCENT = 'percent';
  KEY_RECIPE = 'recipe';
  KEY_GROWTH_RATE = 'growthRate';

const
  MOLECULE_NAMES: array[TMolecule] of string = ('Alpha', 'Beta', 'Gamma', 'Biomass');


// utility functions
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

{ TRecipeHelper }

function TRecipeHelper.getJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  for var gm := Low(TGrowableMolecule) to High(TGrowableMolecule) do
    Result.AddPair(MoleculeToStr(gm), Percents[gm]);
end;

procedure TRecipeHelper.setJSON(const Value: TJSONObject);
begin
//  if Assigned(Value) then
//  begin
//    var s: string;
//    if Value.TryGetValue<string>(KEY_MOLECULE, s) then
//    begin
//      var m: TMolecule;
//      if StrToMolecule(s, m) then
//        Self.Item := m;
//    end;
//  end;
end;



{ TFoodHelper }

function TFoodHelper.getJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair(KEY_NAME, Self.Name);
  Result.AddPair(KEY_RECIPE, Recipe.AsJSON);
  Result.AddPair(KEY_GROWTH_RATE, Self.GrowthRate.AsText);
end;

procedure TFoodHelper.setJSON(const Value: TJSONObject);
begin
//  Self.GrowthRate.AsText := '';

end;


end.
