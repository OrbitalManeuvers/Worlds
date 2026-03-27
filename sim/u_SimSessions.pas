unit u_SimSessions;

interface

uses u_Worlds, u_EnvironmentTypes, u_EnvironmentLibraries,
 u_Simulators, u_SimParams;

type
  TSimSession = class
  private
    fWorld: TWorld;
    fLibrary: TEnvironmentLibrary;
    fSim: TSimulator;
    fParams: TSimParams;
  public
    constructor Create(aWorld: TWorld; const aParams: TSimParams; aLibrary: TEnvironmentLibrary);
    destructor Destroy; override;

    procedure BeginSession;
    procedure EndSession;

    property Simulator: TSimulator read fSim;
  end;

implementation

uses u_WorldLayouts, u_SimUpscalers;

{ TSimSession }

constructor TSimSession.Create(aWorld: TWorld; const aParams: TSimParams; aLibrary: TEnvironmentLibrary);
begin
  inherited Create;
  fWorld := aWorld;
  fLibrary := aLibrary;
  fParams := aParams;

  //
  fSim := TSimulator.Create;
end;

destructor TSimSession.Destroy;
begin
  fSim.Free;
  inherited;
end;

procedure TSimSession.BeginSession;
begin

  // create the stitched-together world of selected regions
  var layout := TWorldLayout.Create(fWorld, fLibrary);
  try
    // the layout feeds the upscaler
    var upscaler := TWorldUpscaler.Create(fSim.Runtime, fParams);
    try
      upscaler.UpscaleWorld(layout);
    finally
      upscaler.Free;
    end;

    // save off the list of biomes for later instrumentation


  finally
    layout.free;
  end;


end;

procedure TSimSession.EndSession;
begin



end;

end.
