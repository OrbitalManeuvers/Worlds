unit u_ExplorationEvaluators;

interface

uses
  u_SimEventTypes, u_SimPopulations, u_ExplorationTypes;

type
  TExplorationEvaluator = class(TNoRefCountObject, ISimEventConsumer)
  private const
    NOT_TRIGGERED = -1;
  private
    fQuery: TExplorationQuery;
    fStopCondition: Integer;
    fPopulation: TSimPopulation;
    procedure Consume(const aEvent: TSimEvent);
  public
    constructor Create;
    procedure Prepare(const aQuery: TExplorationQuery);
    procedure TickComplete;

    property StopCondition: Integer read fStopCondition;
    property Population: TSimPopulation read fPopulation write fPopulation;
  end;


implementation

{ TExplorationEvaluator }

constructor TExplorationEvaluator.Create;
begin
  inherited;
  fStopCondition := NOT_TRIGGERED;
end;

procedure TExplorationEvaluator.Consume(const aEvent: TSimEvent);
begin
  // only need to examine if stop hasn't already been triggered
  if fStopCondition = NOT_TRIGGERED then
  begin

  end;
end;

procedure TExplorationEvaluator.TickComplete;
begin
  if Assigned(fPopulation) then
  begin

  end;
end;

procedure TExplorationEvaluator.Prepare(const aQuery: TExplorationQuery);
begin
  fQuery := aQuery;
  fStopCondition := NOT_TRIGGERED;  // caller has query, only needs index of which condition tripped
end;

end.
