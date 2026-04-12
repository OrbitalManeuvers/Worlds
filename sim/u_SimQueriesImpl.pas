unit u_SimQueriesImpl;

interface

uses System.SysUtils,
  u_EnvironmentTypes, u_SimPopulations, u_SimEnvironments, u_SimQueriesIntf;

type
  TSimQuery = class(TInterfacedObject, ISimQuery, IEnvironmentSmellQuery, IPopulationSightQuery)
  private
    fEnvironment: TSimEnvironment;
    fPopulation: TSimPopulation;

    { IEnvironmentSmellQuery }
    procedure FillLocalFoodCaches(Location: Integer; Range: Single; var Buffer: TSmellCacheInfos; out Count: Integer);

    { IPopulationSightQuery }
    procedure FillLocalAgents(Location: Integer; Range: Single; var Buffer: TSightInfos; out Count: Integer);

  public
    constructor Create(aEnvironment: TSimEnvironment; aPopulation: TSimPopulation);
    destructor Destroy; override;
  end;

implementation

const
  // Ignore trace residue so smell only reports caches with meaningful mass.
  MIN_SMELL_DETECTABLE_AMOUNT = 0.02;

{ TSimQuery }

constructor TSimQuery.Create(aEnvironment: TSimEnvironment; aPopulation: TSimPopulation);
begin
  inherited Create;
  fEnvironment := aEnvironment;
  fPopulation := aPopulation;
end;

destructor TSimQuery.Destroy;
begin

  inherited;
end;


procedure TSimQuery.FillLocalFoodCaches(Location: Integer; Range: Single; var Buffer: TSmellCacheInfos; out Count: Integer);
begin
  Count := 0;

  if not Assigned(fEnvironment) then
    Exit;

  // Current scaffold: treat Location as a flat cell index and scan only that cell.
  // Range support can expand to neighboring cells once movement geometry is finalized.
  if (Location < 0) or (Location > High(fEnvironment.Cells)) then
    Exit;

  var cell := fEnvironment.Cells[Location];
  if Length(Buffer) < cell.ResourceCount then
    SetLength(Buffer, cell.ResourceCount);

  for var i := 0 to cell.ResourceCount - 1 do
  begin
    var resourceIndex := Integer(cell.ResourceStart) + i;
    if (resourceIndex < 0) or (resourceIndex > High(fEnvironment.Resources)) then
      Continue;

    var resource := fEnvironment.Resources[resourceIndex];
    if resource.Amount <= MIN_SMELL_DETECTABLE_AMOUNT then
      Continue;

    Buffer[Count].CacheId := resourceIndex;
    Buffer[Count].Amount := resource.Amount;
    Buffer[Count].Substance := fEnvironment.Substances[resource.SubstanceIndex];

    Inc(Count);
  end;
end;


procedure TSimQuery.FillLocalAgents(Location: Integer; Range: Single; var Buffer: TSightInfos; out Count: Integer);
begin
  Count := 0;

end;

end.
