unit u_SimClocks;

interface

uses
  System.Classes,
  System.Generics.Collections;

const
  CLOCK_TICKS_PER_DAY = 120;
  NIGHT_TICKS_DENOMINATOR = 3;
  NIGHT_TICKS_NUMERATOR = 1;

  NIGHT_TICKS_PER_DAY = (CLOCK_TICKS_PER_DAY * NIGHT_TICKS_NUMERATOR) div NIGHT_TICKS_DENOMINATOR;
  DAYLIGHT_TICKS_PER_DAY = CLOCK_TICKS_PER_DAY - NIGHT_TICKS_PER_DAY;

type
  TDayTick = 0 .. (CLOCK_TICKS_PER_DAY - 1);           // time "today"
  TDaylightTicks = 0 .. (DAYLIGHT_TICKS_PER_DAY - 1);

  TClockInfo = record
    GlobalTick: Cardinal;
    DayNumber: Cardinal;
    DayTick: TDayTick;
    IsNight: Boolean;
  end;

  TClockTickEvent = procedure (Sender: TObject; GlobalTick: Cardinal; DayTick: TDayTick) of object;

  TSimClock = class
  public type
    TClockControlEvent = procedure (Sender: TObject; const NextTick: Cardinal; var CanContinue: Boolean) of object;
  private
    fTick: Cardinal;
//    fInfo: TClockInfo; // not implemented
    fStopped: Boolean;
    fOnControl: TClockControlEvent;
    fTickSubscribers: TList<TClockTickEvent>;
    procedure Callback;
    function IndexOfTickHandler(const AHandler: TClockTickEvent): Integer;
    procedure NotifyTick;
    function GetDayTick: TDayTick;
    function GetDayNumber: Cardinal;
  public
    constructor Create(aController: TClockControlEvent);
    destructor Destroy; override;

    procedure SubscribeTick(const AHandler: TClockTickEvent);
    procedure UnsubscribeTick(const AHandler: TClockTickEvent);
    procedure ClearTickSubscribers;

    procedure Step;
    procedure Stop;

    property Tick: Cardinal read fTick;
    property DayTick: TDayTick read GetDayTick;
    property DayNumber: Cardinal read GetDayNumber;


  end;

implementation

{ TSimClock }

constructor TSimClock.Create(aController: TClockControlEvent);
begin
  inherited Create;
  fTickSubscribers := TList<TClockTickEvent>.Create;
  fOnControl := aController;
  FTick := 0;
end;

destructor TSimClock.Destroy;
begin
  fTickSubscribers.Free;
  inherited;
end;

procedure TSimClock.SubscribeTick(const AHandler: TClockTickEvent);
begin
  if Assigned(AHandler) and (IndexOfTickHandler(AHandler) = -1) then
    fTickSubscribers.Add(AHandler);
end;

procedure TSimClock.UnsubscribeTick(const AHandler: TClockTickEvent);
var
  Index: Integer;
begin
  if Assigned(AHandler) then
  begin
    Index := IndexOfTickHandler(AHandler);
    if Index > -1 then
      fTickSubscribers.Delete(Index);
  end;
end;

procedure TSimClock.ClearTickSubscribers;
begin
  fTickSubscribers.Clear;
end;

function TSimClock.GetDayNumber: Cardinal;
begin
  Result := fTick div CLOCK_TICKS_PER_DAY;
end;

function TSimClock.GetDayTick: TDayTick;
begin
  Result := fTick mod CLOCK_TICKS_PER_DAY;
end;

function TSimClock.IndexOfTickHandler(const AHandler: TClockTickEvent): Integer;
var
  I: Integer;
  AMethod: TMethod;
  ExistingMethod: TMethod;
begin
  AMethod := TMethod(AHandler);
  for I := 0 to fTickSubscribers.Count - 1 do
  begin
    ExistingMethod := TMethod(fTickSubscribers[I]);
    if (AMethod.Code = ExistingMethod.Code) and (AMethod.Data = ExistingMethod.Data) then
      Exit(I);
  end;

  Result := -1;
end;

procedure TSimClock.NotifyTick;
var
  Handlers: TArray<TClockTickEvent>;
  Handler: TClockTickEvent;
begin
  Handlers := fTickSubscribers.ToArray;
  for Handler in Handlers do
    Handler(Self, fTick, DayTick);
end;

procedure TSimClock.Callback;
begin
  if Assigned(fOnControl) then
  begin
    var canContinue := True;
    fOnControl(Self, fTick + 1, canContinue);
    if not canContinue then
      fStopped := True;
  end;
end;

procedure TSimClock.Step;
begin
  Inc(fTick);
  Callback;
  NotifyTick;
end;

procedure TSimClock.Stop;
begin
  fStopped := True;
end;

end.
