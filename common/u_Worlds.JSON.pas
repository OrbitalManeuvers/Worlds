unit u_Worlds.JSON;

interface

uses System.SysUtils, System.JSON,

  u_Worlds,
  u_Worlds.Types,
  u_Environment.Types,
  u_Environment.JSON;


type
  TWorldHelper = class helper for TWorld
  private
    function getJSON: TJSONObject;
    procedure setJSON(const Value: TJSONObject);
  public
    property AsJSON: TJSONObject read getJSON write setJSON;
  end;

implementation

const
  KEY_NAME = 'name';
  KEY_FOODS = 'foods';

{ TWorldHelper }

function TWorldHelper.getJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair(KEY_NAME, Name);

  var foodArr := TJSONArray.Create;
  for var f in Foods do
    foodArr.Add(f.AsJSON);
  Result.AddPair(KEY_FOODS, foodArr);
end;

procedure TWorldHelper.setJSON(const Value: TJSONObject);
begin

end;

end.
