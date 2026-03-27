unit u_Worlds;

interface

uses System.SysUtils, System.Generics.Collections,
  u_EnvironmentTypes, u_Regions;

type
  TRegionLayout = (rlSingle, rlNorthSouth, rlWestEast, rlSquare); // layout implies count: 1, 2, 2, 4
  TRegionLayouts = set of TRegionLayout;

type
  TWorld = class(TNamedEnvironmentObject)
  private
    fDescription: string;
    fLayout: TRegionLayout;
    fRegions: array[1..4] of TRegion;
    procedure SetLayout(const Value: TRegionLayout);
    procedure SetDescription(const Value: string);
    function GetRegion(I: Integer): TRegion;
    procedure SetRegion(I: Integer; const Value: TRegion);
  public
    constructor Create;
    destructor Destroy; override;
    property Description: string read fDescription write SetDescription;
    property Layout: TRegionLayout read fLayout write SetLayout;
    property Regions[I: Integer]: TRegion read GetRegion write SetRegion;
  end;


implementation

uses System.Math;

{ TWorld }

constructor TWorld.Create;
begin
  inherited Create;
  fLayout := rlSingle;
  for var i := Low(fRegions) to High(fRegions) do
    fRegions[i] := nil;
end;

destructor TWorld.Destroy;
begin

  inherited;
end;

function TWorld.GetRegion(I: Integer): TRegion;
begin
  Result := fRegions[I];
end;

procedure TWorld.SetDescription(const Value: string);
begin
  if Value <> fDescription then
  begin
    fDescription := Value;
    Changed;
  end;
end;

procedure TWorld.SetLayout(const Value: TRegionLayout);
begin
  if Value <> fLayout then
  begin
    fLayout := Value;
    Changed;
  end;
end;


procedure TWorld.SetRegion(I: Integer; const Value: TRegion);
begin
  if fRegions[I] <> Value then
  begin
    fRegions[I] := Value;
    Changed;
  end;
end;

end.
