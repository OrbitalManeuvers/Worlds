unit u_Worlds.JSON;

interface

uses System.SysUtils, System.JSON,

  u_Worlds,
  u_Worlds.Types,
  u_Environment.Types,
  u_Environment.JSON;

type
  TRatingHelper = record helper for TRating
  private
    function getText: string;
    procedure setText(const Value: string);
  public
    property AsText: string read getText write setText;
  end;


//type
//  TWorldHelper = class helper for TWorld
//  private
//    function getJSON: TJSONObject;
//    procedure setJSON(const Value: TJSONObject);
//  public
//    property AsJSON: TJSONObject read getJSON write setJSON;
//  end;

implementation

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


{ TWorldHelper }

//function TWorldHelper.getJSON: TJSONObject;
//begin
//  Result := TJSONObject.Create;
//  Result.AddPair(KEY_NAME, Name);
//
//  var foodArr := TJSONArray.Create;
//  for var f in _foods do
//    foodArr.Add(f.AsJSON);
//  Result.AddPair(KEY_FOODS, foodArr);
//end;
//
//procedure TWorldHelper.setJSON(const Value: TJSONObject);
//begin
//  Value.TryGetValue(KEY_NAME, Name);
//
//  var foods: TJSONArray;
//  if Value.TryGetValue(KEY_FOODS, foods) then
//  begin
//    for var jValue in foods do
//    begin
//      if jValue is TJSONObject then
//      begin
//        var food := TFood.Create;
//        food.AsJSON := TJSONObject(jValue);
//        food.Modified := False;
//        Self.AddFood(food);
//      end;
//    end;
//  end;
//
//end;

end.
