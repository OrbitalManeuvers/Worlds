unit u_BiomeMaps;

interface

uses System.Types, Vcl.Graphics,
  u_EditorTypes, u_EnvironmentTypes;

type
  TBiomeMap = class(TEnvironmentObject)
  private
    fGrid: array[TGridExtent, TGridExtent] of TBiomeMarker;
    function GetMarker(X, Y: TGridExtent): TBiomeMarker;
    procedure SetMarker(X, Y: TGridExtent; const Value: TBiomeMarker);
    function GetSize: TSize;
  public
    constructor Create;
    procedure Clear;
    destructor Destroy; override;
    property Cells[X, Y: TGridExtent]: TBiomeMarker read GetMarker write SetMarker; default;
    property Size: TSize read GetSize;
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

function TBiomeMap.GetSize: TSize;
begin
  Result.cx := High(TGridExtent) + 1; // this is cell count not cell index
  Result.cy := Result.cx;
end;

function TBiomeMap.GetMarker(X, Y: TGridExtent): TBiomeMarker;
begin
  Result := fGrid[X, Y];
end;

procedure TBiomeMap.SetMarker(X, Y: TGridExtent; const Value: TBiomeMarker);
begin
  fGrid[X, Y] := Value;
  Changed;
end;

end.
