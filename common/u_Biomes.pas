unit u_Biomes;

interface

uses System.Generics.Collections, System.JSON, Vcl.Graphics,
  u_EditorObjects, u_Environment.Types, u_Worlds.Types,
  u_Foods;

type
  TBiome = class(TEditorObject)
  private
    fName: string;
    fDescription: string;
    fMarker: TBiomeMarker;        // matches a value in a grid map
    fColor: TColor;               // so we can draw grids and show biomes
    fFoods: TList<TFood>;     // list of things that grow here
    fSunlight: TRating;
    fMobility: TRating;
    fGrowthRate: TRating;
    fCapacity: TRating;
    function GetFoodCount: Integer;
    function GetFood(I: Integer): TFood;

//    function getRating(const Index: Integer): TRating;
//    procedure setRating(const Index: Integer; const Value: TRating);

    procedure SetColor(const Value: TColor);
    procedure SetDescription(const Value: string);
    procedure SetMarker(const Value: TBiomeMarker);
    procedure SetName(const Value: string);
    procedure SetCapcity(const Value: TRating);
    procedure SetGrowthRate(const Value: TRating);
    procedure SetMobility(const Value: TRating);
    procedure SetSunlight(const Value: TRating);
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddFood(aFood: TFood);
    procedure RemoveFood(aFood: TFood);
    function FoodActive(aFood: TFood): Boolean;

    property Name: string read fName write SetName;
    property Description: string read fDescription write SetDescription;
    property Marker: TBiomeMarker read fMarker write SetMarker;
    property Color: TColor read fColor write SetColor;
    property Sunlight: TRating read fSunlight write SetSunlight;
    property Mobility: TRating read fMobility write SetMobility;
    property GrowthRate: TRating read fGrowthRate write SetGrowthRate;
    property Capacity: TRating read fCapacity write SetCapcity;
    property FoodCount: Integer read GetFoodCount;
    property Foods[I: Integer]: TFood read GetFood;
  end;


implementation

uses System.SysUtils;

{ TBiome }
constructor TBiome.Create;
begin
  inherited Create;
  fFoods := TList<TFood>.Create; // objects we don't own
  Sunlight := Normal;
  Mobility := Normal;
  Capacity := Normal;
  GrowthRate := Normal;
end;

destructor TBiome.Destroy;
begin
  fFoods.Free;
  inherited;
end;

function TBiome.FoodActive(aFood: TFood): Boolean;
begin
  Result := fFoods.IndexOf(aFood) <> -1;
end;

procedure TBiome.AddFood(aFood: TFood);
begin
  fFoods.Add(aFood);
  Changed;
end;

function TBiome.GetFood(I: Integer): TFood;
begin
  Result := fFoods[I];
end;

function TBiome.GetFoodCount: Integer;
begin
  Result := fFoods.Count;
end;

procedure TBiome.RemoveFood(aFood: TFood);
begin
  var i := fFoods.IndexOf(aFood);
  if i <> -1 then
  begin
    fFoods.Delete(i);
    Changed;
  end;
end;

procedure TBiome.SetCapcity(const Value: TRating);
begin
  if Value <> fCapacity then
  begin
    fCapacity := Value;
    Changed;
  end;
end;

procedure TBiome.SetColor(const Value: TColor);
begin
  if Value <> fColor then
  begin
    fColor := Value;
    Changed;
  end;
end;

procedure TBiome.SetDescription(const Value: string);
begin
  if not SameStr(Value, fDescription) then
  begin
    fDescription := Value;
    Changed;
  end;
end;

procedure TBiome.SetGrowthRate(const Value: TRating);
begin
  if Value <> fGrowthRate then
  begin
    fGrowthRate := Value;
    Changed;
  end;
end;

procedure TBiome.SetMarker(const Value: TBiomeMarker);
begin
  if Value <> fMarker then
  begin
    fMarker := Value;
    Changed;
  end;
end;

procedure TBiome.SetMobility(const Value: TRating);
begin
  if Value <> fMobility then
  begin
    fMobility := Value;
    Changed;
  end;
end;

procedure TBiome.SetName(const Value: string);
begin
  if not SameStr(Value, fName) then
  begin
    fName := Value;
    Changed;
  end;
end;

procedure TBiome.SetSunlight(const Value: TRating);
begin
  if Value <> fSunlight then
  begin
    fSunlight := Value;
    Changed;
  end;
end;

end.
