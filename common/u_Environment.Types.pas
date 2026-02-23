unit u_Environment.Types;

interface

uses System.Generics.Collections, Vcl.Graphics,

  u_Worlds.Types;

const
  BIOME_GRID_SIZE = 32;

type
  TMolecule = (Alpha, Beta, Gamma, Biomass);
  TGrowableMolecule = TMolecule.Alpha .. TMolecule.Gamma;

  TBiomeMarker = Byte;
  TGridExtent = 0 .. BIOME_GRID_SIZE - 1;
  TBiomeGrid = array[TGridExtent, TGridExtent] of TBiomeMarker;

  // usage of TMolecules
  TRecipe = class
  private
    fPercents: array[TGrowableMolecule] of TPercentage;
    function GetPercent(I: TGrowableMolecule): TPercentage;
    procedure SetPrecent(I: TGrowableMolecule; const Value: TPercentage);
  protected
  public
    constructor Create;
    function IsBalanced: Boolean;
    procedure SetPercents(alphaPercent, betaPercent, gammaPercent: TPercentage);
    property Percents[I: TGrowableMolecule]: TPercentage read GetPercent write SetPrecent;
  end;

//

  // a food item
  TFood = class
  private
    fName: string;
    fGrowthRate: TRating;
    fRecipe: TRecipe;
  public
    constructor Create;
    destructor Destroy; override;

    property Name: string read fName write fName;
    property GrowthRate: TRating read fGrowthRate write fGrowthRate;
    property Recipe: TRecipe read fRecipe write fRecipe;
  end;

  TBiome = class
  private
    fName: string;
    fDescription: string;
    fMarker: TBiomeMarker;        // matches a value in a grid map
    fColor: TColor;               // so we can draw grids and show biomes
    fResources: TList<TFood>;     // list of things that grow here
    fSunlight: TRating;
    fMobility: TRating;
    fGrowthRate: TRating;
    fCapacity: TRating;
    function GetResourceCount: Integer;
    function GetResource(I: Integer): TFood;
  public
    constructor Create;
    destructor Destroy; override;
    property Name: string read fName;
    property Description: string read fDescription;
    property Marker: TBiomeMarker read fMarker;
    property Color: TColor read fColor;
    property Sunlight: TRating read fSunlight;
    property Mobility: TRating read fMobility;
    property GrowthRate: TRating read fGrowthRate;
    property Capacity: TRating read fCapacity;
    property ResourceCount: Integer read GetResourceCount;
    property Resources[I: Integer]: TFood read GetResource;
  end;

  TRegion = record
    Title: string;
    Description: string;
    Biomes: array of TBiome;
    BiomeMap: TBiomeGrid;
  end;

const
  RATING_NAMES: array[TRating] of string = ('Worst', 'Horrible', 'Bad', 'Normal', 'Good', 'Great', 'Best');


implementation

{ TRecipe }

constructor TRecipe.Create;
begin
  inherited Create;
  fPercents[Alpha] := 30;
  fPercents[Beta] := 40;
  fPercents[Gamma] := 30;
end;

function TRecipe.GetPercent(I: TGrowableMolecule): TPercentage;
begin
  Result := fPercents[I];
end;

function TRecipe.IsBalanced: Boolean;
begin
  var total := 0;
  for var gm in fPercents do
    total := total + gm;
  Result := total = 100;
end;

procedure TRecipe.SetPercents(alphaPercent, betaPercent, gammaPercent: TPercentage);
begin
  fPercents[Alpha] := alphaPercent;
  fPercents[Beta] := betaPercent;
  fPercents[Gamma] := gammaPercent;
end;

procedure TRecipe.SetPrecent(I: TGrowableMolecule; const Value: TPercentage);
begin
  fPercents[I] := Value;
end;


{ TFood }

constructor TFood.Create;
begin
  inherited Create;
  fGrowthRate := Normal;
  fRecipe := TRecipe.Create;
end;

destructor TFood.Destroy;
begin
  Recipe.Free;
  inherited;
end;


{ TBiome }
constructor TBiome.Create;
begin
  inherited Create;
  fResources := TList<TFood>.Create;
end;

destructor TBiome.Destroy;
begin
  fResources.Free;
  inherited;
end;

function TBiome.GetResource(I: Integer): TFood;
begin
  Result := fResources[I];
end;

function TBiome.GetResourceCount: Integer;
begin
  Result := fResources.Count;
end;

end.
