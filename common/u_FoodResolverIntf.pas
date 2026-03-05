unit u_FoodResolverIntf;

interface

uses u_Foods;

type
  IFoodResolver = interface
    ['{6D02ADB0-72AC-47EE-B036-90E9B84D0970}']
    function FindFood(const aId: string): TFood;
  end;

implementation

end.
