unit u_SimEnvironments;

interface

uses System.Types,

  u_EnvironmentTypes;

type
  // something that can be found on the ground
  TSubstance = array[TMolecule] of TPercentage;

  // how natural resources are tracked and managed. upscaler sets this up
  TResourceCache = record
    SubstanceIndex: Word;    // index into Substances array
    Amount: Single;          // mutable simulation state
    Capacity: Single;        // fixed modifiers...
    GrowthRate: Single;      // incorporates Biome.GrowthRate and Food.GrowthRate
  end;

  // Grid is made up of TCell
  TCell = record
    ResourceStart: Word;  // not all cells have resources. needs to be discussed
    ResourceCount: Word;
    Sunlight: Single;
    Mobility: Single;
  end;

  TCellArray = array of TCell;
  TResourceArray = array of TResourceCache;
  TSubstanceArray = array of TSubstance;

  TSimEnvironment = class
  private
    fDimensions: TSize;
    fCells: TCellArray;
    fResources: TResourceArray;
    fSubstances: TSubstanceArray;
  public
    constructor Create;
    destructor Destroy; override;

    { runtime lookups built by upscaler }
    procedure SetSubstanceCount(aCount: Integer);
    procedure SetSubstance(aIndex: Integer; aSubstance: TSubstance);

    { monolithic allocations }
    procedure SetDimensions(aSize: TSize);
    procedure SetResourceCount(aCount: Integer);

    property Cells: TCellArray read fCells;
    property Resources: TResourceArray read fResources;
    property Substances: TSubstanceArray read fSubstances;
  end;

implementation

{ TSimEnvironment }

constructor TSimEnvironment.Create;
begin
  inherited;

end;

destructor TSimEnvironment.Destroy;
begin
  //
  inherited;
end;

procedure TSimEnvironment.SetDimensions(aSize: TSize);
begin
  fDimensions := aSize;
  SetLength(fCells, aSize.cx * aSize.cy);
end;

procedure TSimEnvironment.SetResourceCount(aCount: Integer);
begin
  SetLength(fResources, aCount);
end;

procedure TSimEnvironment.SetSubstance(aIndex: Integer; aSubstance: TSubstance);
begin
  fSubstances[aIndex] := aSubstance;
end;

procedure TSimEnvironment.SetSubstanceCount(aCount: Integer);
begin
  SetLength(fSubstances, aCount);
end;

end.
