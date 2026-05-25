unit u_SessionComposers;

interface

uses
  u_SimRuntimes, u_SessionComposerIntf,
  u_SessionParameters;

type
  TSessionComposer = class(TInterfacedObject, ISessionComposer)
  private
    fParams: TUpscalerParameters;
    procedure Compose(aRuntime: TSimRuntime);
  public
    constructor Create(const aParams: TUpscalerParameters);
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections,
  u_Foods,
  u_SimPopulators,
  u_SimUpscalers,
  u_WorldLayouts,
  u_EnvironmentTypes,
  u_EnvironmentLibraries;

function BuildRuntimeConfig(const Params: TUpscalerParameters): TRuntimeConfig;
begin
  Result.AgentActivationTick := Params.Population.AgentActivationTick;


end;

{ TSessionComposer }

constructor TSessionComposer.Create(const aParams: TUpscalerParameters);
begin
  inherited Create;
  fParams := aParams;
end;

destructor TSessionComposer.Destroy;
begin

  inherited;
end;

procedure TSessionComposer.Compose(aRuntime: TSimRuntime);
  procedure ApplySeedPolicy;
  begin
    if fParams.Seed <> 0 then
      RandSeed := fParams.Seed;
  end;
begin
  ApplySeedPolicy;
  aRuntime.ConfigureRuntime(BuildRuntimeConfig(fParams));

  var layout := TWorldLayout.Create(fParams.World, WorldLibrary);
  try
    var upscaler := TWorldUpscaler.Create(aRuntime.Environment, fParams);
    try
      upscaler.UpscaleWorld(layout);
    finally
      upscaler.Free;
    end;

    aRuntime.RebuildDeltaPlacementCycles;
  finally
    layout.Free;
  end;

  TWorldPopulator.Populate(aRuntime.Population, aRuntime.Environment, fParams);
end;


end.
