unit u_Instincts;

interface

type
  Instinct = class
  public const
    // Panic if reserves drop below this floor
    ENERGY_PANIC_FLOOR = 1.5;

    // prefer when it's light out
    DARKNESS_DISCOMFORT = 0.01;

    // no food nearby reinforces sleep instinct
    NO_FOOD_SLEEP_BONUS = 0.01;

  end;

implementation

end.
