unit u_Foods.JSON;

interface

uses System.JSON,
  u_Foods;

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


implementation

uses u_Environment.Types;

{ TRecipeHelper }

function TRecipeHelper.getJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  for var gm := Low(TGrowableMolecule) to High(TGrowableMolecule) do
    Result.AddPair(MoleculeToStr(gm), Percents[gm]);
end;

procedure TRecipeHelper.setJSON(const Value: TJSONObject);
begin
  var pair: TJSONPair;
  for pair in Value do
  begin
    var m: TMolecule;
    if StrToMolecule(pair.JsonString.Value, m) then
    begin
      var percent := 0;
      if pair.JsonValue is TJSONNumber then
        percent := TJSONNumber(pair.JSONValue).AsInt;
      Self.Percents[m] := percent;
    end;
  end;
end;


{ TFoodHelper }

function TFoodHelper.getJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair(KEY_NAME, Self.Name);
  Result.AddPair(KEY_GROWTH_RATE, Self.GrowthRate.AsText);
  Result.AddPair(KEY_RECIPE, Recipe.AsJSON);
end;

procedure TFoodHelper.setJSON(const Value: TJSONObject);
var
  sValue: string;
begin
  if Value.TryGetValue(KEY_NAME, sValue) then
    Name := sValue;
  if Value.TryGetValue(KEY_GROWTH_RATE, sValue) then
    GrowthRate.AsText := sValue;

  var jObject: TJSONObject;
  if Value.TryGetValue(KEY_RECIPE, jObject) then
    Recipe.AsJSON := jObject;
end;


end.
