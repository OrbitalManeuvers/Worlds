unit u_Regions;

interface

uses System.Generics.Collections,
  u_EditorObjects, u_Environment.Types, u_Worlds.Types, u_Biomes;

type
  TRegion = class(TEditorObject)
  private
    fName: string;
    fDescription: string;
    procedure SetDescription(const Value: string);
    procedure SetName(const Value: string);
    function GetBiomeGridPtr: PBiomeGrid;
  public
    BiomeGrid: TBiomeGrid;
    constructor Create;
    destructor Destroy; override;

    property Name: string read fName write SetName;
    property Description: string read FDescription write SetDescription;
    property BiomeGridPtr: PBiomeGrid read GetBiomeGridPtr;
  end;

implementation

{ TRegion }

constructor TRegion.Create;
begin
  inherited Create;
  for var x := Low(TGridExtent) to High(TGridExtent) do
    for var y := Low(TGridExtent) to High(TGridExtent) do
      BiomeGrid[x, y] := 0;
end;

destructor TRegion.Destroy;
begin
  inherited;
end;

function TRegion.GetBiomeGridPtr: PBiomeGrid;
begin
  Result := @BiomeGrid;
end;

procedure TRegion.SetDescription(const Value: string);
begin
  if Value <> fDescription then
  begin
    fDescription := Value;
    Changed;
  end;
end;

procedure TRegion.SetName(const Value: string);
begin
  if Value <> fName then
  begin
    fName := Value;
    Changed;
  end;
end;

end.
