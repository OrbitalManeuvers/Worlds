unit u_Regions;

interface

uses
  u_EnvironmentTypes, u_BiomeMaps;

type
  TRegion = class(TNamedEnvironmentObject)
  private
    fMap: TBiomeMap;
    fDescription: string;
    procedure SetDescription(const Value: string);
  public
    constructor Create;
    destructor Destroy; override;

    property Description: string read FDescription write SetDescription;
    property BiomeMap: TBiomeMap read fMap;
  end;

implementation

uses System.SysUtils, System.Generics.Collections;

{ TRegion }

constructor TRegion.Create;
begin
  inherited Create;
  fMap := TBiomeMap.Create;
  fMap.OnChange := ChildChanged;
end;

destructor TRegion.Destroy;
begin
  inherited;
end;

procedure TRegion.SetDescription(const Value: string);
begin
  if Value <> fDescription then
  begin
    fDescription := Value;
    Changed;
  end;
end;

end.
