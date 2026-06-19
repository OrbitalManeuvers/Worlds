unit u_Instincts;

interface

type
  Instinct = class
  public const
    // Panic if reserves drop below this floor
    ENERGY_PANIC_FLOOR = 1.5;

    // Above this, agent can afford to wait — no urgency to act on uncertain information
    ENERGY_COMFORT_LEVEL = 5.0;

    // Cache signal below this is "not ripe" — don't bother eating it, let it grow.
    // Prevents agents from consuming tiny sprouts and resetting regen debt on near-empty caches.
    MIN_FORAGE_SIGNAL = 0.3;

    // prefer when it's light out
    DARKNESS_DISCOMFORT = 0.01;

    // no food nearby reinforces sleep instinct
    NO_FOOD_SLEEP_BONUS = 0.01;

    // Fatigue is imperceptible until this fraction of the circadian cycle is spent.
    // After this point, fatigue ramps steeply (quadratic curve).
    FATIGUE_ONSET = 0.70;

  end;

implementation

end.
