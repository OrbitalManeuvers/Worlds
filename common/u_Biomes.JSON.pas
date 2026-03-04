unit u_Biomes.JSON;

interface

uses System.JSON,
  u_Biomes;

type
  TBiomeHelper = class helper for TBiome
  private
    function getJSON: TJSONObject;
    procedure setJSON(const Value: TJSONObject);
  public
    property AsJSON: TJSONObject read getJSON write setJSON;
  end;

implementation

uses Vcl.GraphUtil, u_Worlds.Types, u_Worlds.JSON, u_EnvironmentLibraries;

const
  KEY_NAME = 'name';
  KEY_DESCRIPTION = 'description';

  KEY_MARKER = 'marker';
  KEY_COLOR = 'color';

  KEY_GROWTH_RATE = 'growthRate';
  KEY_CAPACITY = 'capacity';
  KEY_SUNLIGHT = 'sunlight';
  KEY_MOBILITY = 'mobility';
  KEY_FOODS = 'foods';


{ TBiomeHelper }

function TBiomeHelper.getJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair(KEY_NAME, Name);
  Result.AddPair(KEY_DESCRIPTION, Description);
  Result.AddPair(KEY_MARKER, Integer(Marker));
  Result.AddPair(KEY_COLOR, ColorToWebColorStr(Color));

  Result.AddPair(KEY_GROWTH_RATE, GrowthRate.AsText);
  Result.AddPair(KEY_CAPACITY, Capacity.AsText);
  Result.AddPair(KEY_SUNLIGHT, Sunlight.AsText);
  Result.AddPair(KEY_MOBILITY, Mobility.AsText);

  var arr := TJSONArray.Create;
  for var i := 0 to FoodCount - 1 do
    arr.Add(Foods[i].Name);
  Result.AddPair(KEY_FOODS, arr);
end;

procedure TBiomeHelper.setJSON(const Value: TJSONObject);
var
  strVal: string;
  intVal: Integer;
begin
  if Value.TryGetValue(KEY_NAME, strVal) then
    Name := strVal;
  if Value.TryGetValue(KEY_DESCRIPTION, strVal) then
    Description := strVal;
  if Value.TryGetValue(KEY_MARKER, intVal) then
    Marker := intVal;
  if Value.TryGetValue(KEY_COLOR, strVal) then
  begin
    Color := WebColorStrToColor(strVal);
  end;

  if Value.TryGetValue(KEY_GROWTH_RATE, strVal) then
    GrowthRate.AsText := strVal;
  if Value.TryGetValue(KEY_CAPACITY, strVal) then
    Capacity.AsText := strVal;
  if Value.TryGetValue(KEY_SUNLIGHT, strVal) then
    Sunlight.AsText := strVal;
  if Value.TryGetValue(KEY_MOBILITY, strVal) then
    Mobility.AsText := strVal;

  var strArr: TJSONArray;
  if Value.TryGetValue(KEY_FOODS, strArr) then
  begin
    for var v in strArr do
    begin
      var food := WorldLibrary.FindFood(v.Value);
      if Assigned(food) then
        AddFood(food);
    end;
  end;
end;

end.
