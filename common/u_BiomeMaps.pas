unit u_BiomeMaps;

interface

uses Vcl.Graphics,
  u_EditorTypes, u_EnvironmentTypes;

type
  TBiomeMap = class(TEnvironmentObject)
  private
    fGrid: array[TGridExtent, TGridExtent] of TBiomeMarker;
    function GetMarker(X, Y: Integer): TBiomeMarker;
    procedure SetMarker(X, Y: Integer; const Value: TBiomeMarker);
  public
    constructor Create;
    procedure Clear;
    destructor Destroy; override;
    property Cells[X, Y: Integer]: TBiomeMarker read GetMarker write SetMarker; default;
  end;


implementation

{ TBiomeMap }

constructor TBiomeMap.Create;
begin
  inherited Create;
  Clear;
end;

destructor TBiomeMap.Destroy;
begin

  inherited;
end;

procedure TBiomeMap.Clear;
begin
  for var x := Low(TGridExtent) to High(TGridExtent) do
    for var y := Low(TGridExtent) to High(TGridExtent) do
      fGrid[x, y] := 0;
  Changed;
end;

function TBiomeMap.GetMarker(X, Y: Integer): TBiomeMarker;
begin
  Result := fGrid[X, Y];
end;

procedure TBiomeMap.SetMarker(X, Y: Integer; const Value: TBiomeMarker);
begin
  fGrid[X, Y] := Value;
  Changed;
end;

end.
