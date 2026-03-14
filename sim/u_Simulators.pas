unit u_Simulators;

interface

uses u_SimParams, u_SimClocks, u_SimRuntimes, u_SimUpscalers;

type
  TSimulator = class
  private
    fClock: TSimClock;
    fParams: TSimParams;
    fRuntime: TSimRuntime;
    procedure SetParams(const Value: TSimParams);
    procedure ClockCallback(Sender: TObject; const TimeSlice: TSimClock.TTimeSlice; var CanContinue: Boolean);
  public
    constructor Create;
    destructor Destroy; override;

    function Upscaler: TSimUpscaler;

    property SimParams: TSimParams read fParams write SetParams;
    property Runtime: TSimRuntime read fRuntime;
    property Clock: TSimClock read fClock;
  end;

implementation


{ TSimulator }

constructor TSimulator.Create;
begin
  inherited Create;
  fClock := TSimClock.Create(ClockCallback);
  fRuntime := TSimRuntime.Create;
end;

destructor TSimulator.Destroy;
begin
  fRuntime.Free;
  fClock.Free;
  inherited;
end;

procedure TSimulator.ClockCallback(Sender: TObject; const TimeSlice: TSimClock.TTimeSlice; var CanContinue: Boolean);
begin
  // what does the runtime need to know
  fRuntime.ClockTick := TimeSlice.ClockTick;
  //
end;

procedure TSimulator.SetParams(const Value: TSimParams);
begin
  fParams := Value;
end;

function TSimulator.Upscaler: TSimUpscaler;
begin
  // give the caller an upscaler connected to the runtime data.
  Result := TSimUpscaler.Create(fRuntime, fParams);
end;

end.
