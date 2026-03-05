unit u_Regions.JSON;

interface

uses System.JSON,
  u_Regions;

type
  TRegionHelper = class helper for TRegion
  private
    function getJSON: TJSONObject;
    procedure setJSON(const Value: TJSONObject);
  public
    property AsJSON: TJSONObject read getJSON write setJSON;
  end;


implementation

uses
  System.SysUtils, System.Generics.Collections,
    u_Environment.Types;

//const
//  KEY_NAME = 'name';
//  KEY_DESCRIPTION = 'description';
//  KEY_BIOME_GRID = 'biomeGrid';


{ TRegionHelper }

function TRegionHelper.getJSON: TJSONObject;
var
  rows: TJSONArray;
  rowText: string;
begin
  Result := TJSONObject.Create;
  Result.AddPair(KEY_NAME, Name);
  Result.AddPair(KEY_DESCRIPTION, Description);

  rows := TJSONArray.Create;
  for var y := Low(BiomeGrid[Low(BiomeGrid)]) to High(BiomeGrid[Low(BiomeGrid)]) do
  begin
    rowText := '';
    for var x := Low(BiomeGrid) to High(BiomeGrid) do
      rowText := rowText + BiomeGrid[x, y].ToHexString(2);
    rows.Add(rowText);
  end;

  Result.AddPair(KEY_BIOME_GRID, rows);
end;

procedure TRegionHelper.setJSON(const Value: TJSONObject);
var
  sValue: string;
  jValue: TJSONValue;
  rows: TJSONArray;
  rowText: string;
begin
  if Value.TryGetValue(KEY_NAME, sValue) then
    Name := sValue;
  if Value.TryGetValue(KEY_DESCRIPTION, sValue) then
    Description := sValue;

  if Value.TryGetValue(KEY_BIOME_GRID, jValue) and (jValue is TJSONArray) then
  begin
    rows := TJSONArray(jValue);
    for var y := Low(BiomeGrid[Low(BiomeGrid)]) to High(BiomeGrid[Low(BiomeGrid)]) do
    begin
      rowText := rows.Items[y].Value;
      for var x := Low(BiomeGrid) to High(BiomeGrid) do
        BiomeGrid[x, y] := StrToIntDef('$' + Copy(rowText, (x * 2) + 1, 2), 0);
    end;
  end;
end;



end.
