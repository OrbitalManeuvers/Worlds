unit u_SimpleJSON;

interface

uses System.Types, System.JSON;

type
  { TSimpleJSONReader }
  TSimpleJSONReader = class helper for TJSONObject
    function StrValue(aKey: string): string;
    function IntValue(aKey: string): Integer;
    function PointValue(aKey, aXKey, aYkey: string): TPoint;
  end;



implementation


function TSimpleJSONReader.IntValue(aKey: string): Integer;
begin
  Result := -1;
  var aValue: Integer;
  if Self.TryGetValue(aKey, aValue) then
    Result := aValue;
end;

function TSimpleJSONReader.PointValue(aKey, aXKey, aYkey: string): TPoint;
begin
  Result := Default(TPoint);
  var obj: TJSONObject;
  if Self.TryGetValue(aKey, obj) then
  begin
    Result.x := obj.IntValue(aXKey);
    Result.y := obj.IntValue(aYKey);
  end;
end;

function TSimpleJSONReader.StrValue(aKey: string): string;
begin
  Result := '';
  var aValue: string;
  if Self.TryGetValue(aKey, aValue) then
    Result := aValue;
end;

end.
