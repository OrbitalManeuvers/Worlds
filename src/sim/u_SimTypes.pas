unit u_SimTypes;

interface

const
  CLOCK_TICKS_PER_DAY = 120;
  NIGHT_TICKS_DENOMINATOR = 3;
  NIGHT_TICKS_NUMERATOR = 1;

  NIGHT_TICKS_PER_DAY = (CLOCK_TICKS_PER_DAY * NIGHT_TICKS_NUMERATOR) div NIGHT_TICKS_DENOMINATOR;
  DAYLIGHT_TICKS_PER_DAY = CLOCK_TICKS_PER_DAY - NIGHT_TICKS_PER_DAY;

  // normal conditions are 1.25 days worth of cycle when pressure builds @ 1.0 per tick
  // This max applies to all agents universally.
  MAX_CIRCADIAN_PRESSURE = CLOCK_TICKS_PER_DAY + (CLOCK_TICKS_PER_DAY div 4);
  CIRCADIAN_COST_PER_TICK = 1.0;
  STANDARD_CIRCADIAN_RELIEF_RATE: Single = MAX_CIRCADIAN_PRESSURE / NIGHT_TICKS_PER_DAY;

type
  TDayTick = 0 .. (CLOCK_TICKS_PER_DAY - 1);           // time "today"
  TDaylightTicks = 0 .. (DAYLIGHT_TICKS_PER_DAY - 1);

type
  TSimTickPhase = (stpPostEnvironment, stpPostAgents);
  TSimTickPhases = set of TSimTickPhase;

  TSimDate = record
    DayNumber: Integer;
    DayTick: TDayTick;

    procedure Clear;
    procedure SetDate(aGlobalTick: Integer);
    function NextSunrise: TSimDate;
    function NextSunset: TSimDate;
    function AddTicks(aCount: Integer): TSimDate;
  end;


implementation

{ TSimDate }

function TSimDate.AddTicks(aCount: Integer): TSimDate;
var
  totalTick: Integer;
begin
  totalTick := DayNumber * CLOCK_TICKS_PER_DAY + DayTick + aCount;
  Result.DayNumber := Integer(totalTick div CLOCK_TICKS_PER_DAY);
  Result.DayTick   := TDayTick(totalTick mod CLOCK_TICKS_PER_DAY);
end;

procedure TSimDate.Clear;
begin
  Self.DayNumber := 0;
  Self.DayTick := Low(TDayTick);
end;

function TSimDate.NextSunrise: TSimDate;
begin
  // Sunrise is tick 0 of the next day
  Result.DayNumber := DayNumber + 1;
  Result.DayTick   := 0;
end;

function TSimDate.NextSunset: TSimDate;
begin
  // Sunset is the first night tick (DAYLIGHT_TICKS_PER_DAY) of the current day.
  // If we're already at or past sunset, advance to the next day's sunset.
  if DayTick < DAYLIGHT_TICKS_PER_DAY then
  begin
    Result.DayNumber := DayNumber;
    Result.DayTick   := DAYLIGHT_TICKS_PER_DAY;
  end
  else
  begin
    Result.DayNumber := DayNumber + 1;
    Result.DayTick   := DAYLIGHT_TICKS_PER_DAY;
  end;
end;

procedure TSimDate.SetDate(aGlobalTick: Integer);
begin
  DayNumber := Integer(aGlobalTick div CLOCK_TICKS_PER_DAY);
  DayTick   := TDayTick(aGlobalTick mod CLOCK_TICKS_PER_DAY); 
end;

end.
