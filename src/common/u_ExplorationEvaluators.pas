unit u_ExplorationEvaluators;

interface

uses

  u_SimEventTypes, u_SimPopulations;

type
  TExplorationEvaluator = class(TNoRefCountObject, ISimEventConsumer)
  private
    fPopulation: TSimPopulation;
    procedure Consume(const aEvent: TSimEvent);
  public
    property Population: TSimPopulation read fPopulation write fPopulation;
  end;


implementation

{ TExplorationEvaluator }

procedure TExplorationEvaluator.Consume(const aEvent: TSimEvent);
begin
  //
end;

end.
