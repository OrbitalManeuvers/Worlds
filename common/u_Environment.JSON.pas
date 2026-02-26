unit u_Environment.JSON;

interface

uses System.SysUtils, System.JSON, System.Generics.Collections,

  u_Worlds.Types,
  u_Environment.Types;


implementation

uses System.StrUtils, Vcl.GraphUtil;

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



(*
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

  TBiomeHelper = class helper for TBiome
  private
    function getJSON: TJSONObject;
    procedure setJSON(const Value: TJSONObject);
  public
    property AsJSON: TJSONObject read getJSON write setJSON;
  end;

*)
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

//function TRatingHelper.getText: string;
//begin
//  Result := RATING_NAMES[Self];
//end;
//
//procedure TRatingHelper.setText(const Value: string);
//begin
//  for var candidate := Low(TRating) to High(TRating) do
//    if SameText(Value, candidate.AsText) then
//    begin
//      Self := candidate;
//      Exit;
//    end;
//end;

{ TRecipeHelper }

//function TRecipeHelper.getJSON: TJSONObject;
//begin
//  Result := TJSONObject.Create;
//  for var gm := Low(TGrowableMolecule) to High(TGrowableMolecule) do
//    Result.AddPair(MoleculeToStr(gm), Percents[gm]);
//end;

//procedure TRecipeHelper.setJSON(const Value: TJSONObject);
//begin
//  var pair: TJSONPair;
//  for pair in Value do
//  begin
//    var m: TMolecule;
//    if StrToMolecule(pair.JsonString.Value, m) then
//    begin
//      var percent := 0;
//      if pair.JsonValue is TJSONNumber then
//        percent := TJSONNumber(pair.JSONValue).AsInt;
//      Self.Percents[m] := percent;
//    end;
//  end;
//end;


{ TFoodHelper }

//function TFoodHelper.getJSON: TJSONObject;
//begin
//  Result := TJSONObject.Create;
//  Result.AddPair(KEY_NAME, Self.Name);
//  Result.AddPair(KEY_GROWTH_RATE, Self.GrowthRate.AsText);
//  Result.AddPair(KEY_RECIPE, Recipe.AsJSON);
//end;
//
//procedure TFoodHelper.setJSON(const Value: TJSONObject);
//var
//  sValue: string;
//begin
//  if Value.TryGetValue(KEY_NAME, sValue) then
//    Name := sValue;
//  if Value.TryGetValue(KEY_GROWTH_RATE, sValue) then
//    GrowthRate.AsText := sValue;
//
//  var jObject: TJSONObject;
//  if Value.TryGetValue(KEY_RECIPE, jObject) then
//    Recipe.AsJSON := jObject;
//end;


{ TBiomeHelper }

//function TBiomeHelper.getJSON: TJSONObject;
//begin
//  Result := TJSONObject.Create;
//end;
//
//procedure TBiomeHelper.setJSON(const Value: TJSONObject);
//var
//  strVal: string;
//  intVal: Integer;
//begin
//  if Value.TryGetValue(KEY_NAME, strVal) then
//    Name := strVal;
//  if Value.TryGetValue(KEY_NAME, strVal) then
//    Description := strVal;
//  if Value.TryGetValue(KEY_MARKER, intVal) then
//    Marker := intVal;
//  if Value.TryGetValue(KEY_COLOR, strVal) then
//  begin
//    Color := WebColorStrToColor(strVal);
//  end;
//
//  if Value.TryGetValue(KEY_GROWTH_RATE, strVal) then
//    GrowthRate.AsText := strVal;
//  if Value.TryGetValue(KEY_CAPACITY, strVal) then
//    Capacity.AsText := strVal;
//  if Value.TryGetValue(KEY_SUNLIGHT, strVal) then
//    Sunlight.AsText := strVal;
//  if Value.TryGetValue(KEY_MOBILITY, strVal) then
//    Mobility.AsText := strVal;
//
//  var strArr: TJSONArray;
//  if Value.TryGetValue(KEY_FOODS, strArr) then
//  begin
//
//  end;

(*
  KEY_MARKER = 'marker';
  KEY_COLOR = 'color';

  KEY_GROWTH_RATE = 'growthRate';
  KEY_CAPACITY = 'capacity';
  KEY_SUNLIGHT = 'sunlight';
  KEY_MOBILITY = 'mobility';
  KEY_FOODS = 'foods';


    property Name: string read fName write SetName;
    property Description: string read fDescription write SetDescription;
    property Marker: TBiomeMarker read fMarker write SetMarker;
    property Color: TColor read fColor write SetColor;
    property Sunlight: TRating index 1 read getRating write setRating;
    property Mobility: TRating index 2 read getRating write setRating;
    property GrowthRate: TRating index 3 read getRating write setRating;
    property Capacity: TRating index 4 read getRating write setRating;
    property FoodCount: Integer read GetFoodCount;
    property Foods[I: Integer]: TFood read GetFood;

*)

//end;

end.
