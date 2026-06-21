unit u_Simulators;

interface

uses u_SimTypes, u_SimClocks, u_SessionEventTypes, u_SimRuntimes;

type
  TSimulator = class
  private
    fClock: TSimClock;
    fRuntime: TSimRuntime;
    procedure ClockCallback(Sender: TObject; const NextTick: Integer; var CanContinue: Boolean);
    procedure ClockTickHandler(Sender: TObject; GlobalTick: Integer; DayTick: TDayTick);
  public
    constructor Create(const aSessionEventSink: ISessionEventSink);
    destructor Destroy; override;

    property Runtime: TSimRuntime read fRuntime;
    property Clock: TSimClock read fClock;
  end;

implementation


{ TSimulator }
constructor TSimulator.Create(const aSessionEventSink: ISessionEventSink);
begin
  inherited Create;
  fClock := TSimClock.Create(ClockCallback);
  fClock.SubscribeTick(ClockTickHandler);
  fRuntime := TSimRuntime.Create(aSessionEventSink);
end;

destructor TSimulator.Destroy;
begin
  fRuntime.Free;
  fClock.UnsubscribeTick(ClockTickHandler);
  fClock.Free;
  inherited;
end;

procedure TSimulator.ClockTickHandler(Sender: TObject; GlobalTick: Integer; DayTick: TDayTick);
begin
  fRuntime.AdvanceClock(GlobalTick, DayTick);
end;

procedure TSimulator.ClockCallback(Sender: TObject; const NextTick: Integer; var CanContinue: Boolean);
begin
  //
end;


end.
