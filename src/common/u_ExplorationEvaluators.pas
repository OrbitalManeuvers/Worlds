unit u_ExplorationEvaluators;

interface

uses
  u_SimPopulations, u_ExplorationTypes, u_SimTypes,
  u_PopulationTypes;

type
  TExplorationEvaluator = class
  private const
    NOT_TRIGGERED = -1;
  private
    fSubscriptionId: Integer;
    fQuery: TExplorationQuery;
    fStopCondition: Integer;
    fPopulation: TSimPopulation;
    fGridWidth: Integer;
    fDayTick: Integer;

    // Pre-computed in Prepare
    fIsAnyAgent: Boolean;
    fSortedAgents: TArray<TAgentId>;
    fEventConditions: TArray<Integer>;   // indices into fQuery.Conditions
    fStateConditions: TArray<Integer>;   // indices into fQuery.Conditions

    function IsAgentInScope(aAgentId: TAgentId): Boolean;
  public
    constructor Create;
    procedure Prepare(const aQuery: TExplorationQuery);
    procedure TickComplete(const aSummary: TPopulationSummary);

    property StopCondition: Integer read fStopCondition;
    property Population: TSimPopulation read fPopulation write fPopulation;
    property GridWidth: Integer read fGridWidth write fGridWidth;
    property DayTick: Integer read fDayTick write fDayTick;
    property SubscriptionId: Integer read fSubscriptionId write fSubscriptionId;
  end;


implementation

uses u_AgentState, u_RuntimeTypes;

{ TExplorationEvaluator }

constructor TExplorationEvaluator.Create;
begin
  inherited;
  fStopCondition := NOT_TRIGGERED;
  fGridWidth := 0;
end;

function TExplorationEvaluator.IsAgentInScope(aAgentId: TAgentId): Boolean;
begin
  if fIsAnyAgent then
    Exit(True);

  // Binary search on sorted agent list.
  var lo := 0;
  var hi := High(fSortedAgents);
  var found := False;

  while lo <= hi do
  begin
    var mid := (lo + hi) shr 1;
    if Integer(fSortedAgents[mid]) < Integer(aAgentId) then
      lo := mid + 1
    else if Integer(fSortedAgents[mid]) > Integer(aAgentId) then
      hi := mid - 1
    else
    begin
      found := True;
      Break;
    end;
  end;

  // If Exclude is set, the list means "everyone except these".
  if fQuery.Exclude then
    Result := not found
  else
    Result := found;
end;

//procedure TExplorationEvaluator.Consume(const aEvent: TSimEvent);
//begin
//  if fStopCondition <> NOT_TRIGGERED then
//    Exit;
//
//  // Track DayTick from incoming events so TickComplete can use it.
//  fDayTick := aEvent.Header.DayTick;
//
//  for var i := 0 to High(fEventConditions) do
//  begin
//    var condIndex := fEventConditions[i];
//    var cond := fQuery.Conditions[condIndex];
//
//    case cond.Kind of
//      ekBorn:
//        if aEvent.Header.Kind = sekAgentBorn then
//        begin
//          if IsAgentInScope(aEvent.AgentBorn.AgentId) then
//          begin
//            fStopCondition := condIndex;
//            Exit;
//          end;
//        end;
//
//      ekDies:
//        if aEvent.Header.Kind = sekAgentDied then
//        begin
//          if IsAgentInScope(aEvent.AgentDied.AgentId) then
//          begin
//            fStopCondition := condIndex;
//            Exit;
//          end;
//        end;
//
//      ekActionSelected:
//        if aEvent.Header.Kind = sekActionResolved then
//        begin
//          if IsAgentInScope(aEvent.ActionResolved.AgentId) then
//          begin
//            if aEvent.ActionResolved.ResolvedAction <> cond.Action.Action then
//              Continue;
//
//            // If target is specified (TType <> ttNone), also match target.
//            if cond.Action.Target.TType <> ttNone then
//            begin
//              if aEvent.ActionResolved.ResolvedTarget.TType <> cond.Action.Target.TType then
//                Continue;
//
//              case cond.Action.Target.TType of
//                ttCell:
//                  if aEvent.ActionResolved.ResolvedTarget.Cell <> cond.Action.Target.Cell then
//                    Continue;
//                ttCache:
//                  begin
//                    // Cache index -1 means "any cache of this kind"
//                    if (cond.Action.Target.Cache.Index >= 0) and
//                       (aEvent.ActionResolved.ResolvedTarget.Cache.Index <> cond.Action.Target.Cache.Index) then
//                      Continue;
//                    if aEvent.ActionResolved.ResolvedTarget.Cache.Kind <> cond.Action.Target.Cache.Kind then
//                      Continue;
//                  end;
//              end;
//            end;
//
//            fStopCondition := condIndex;
//            Exit;
//          end;
//        end;
//    end;
//  end;
//end;

procedure TExplorationEvaluator.TickComplete(const aSummary: TPopulationSummary);

  function ChebyshevDistance(aCell1, aCell2: Integer): Integer;
  begin
    var x1 := aCell1 mod fGridWidth;
    var y1 := aCell1 div fGridWidth;
    var x2 := aCell2 mod fGridWidth;
    var y2 := aCell2 div fGridWidth;
    Result := Abs(x2 - x1);
    if Abs(y2 - y1) > Result then
      Result := Abs(y2 - y1);
  end;

begin
  if fStopCondition <> NOT_TRIGGERED then
    Exit;

  for var i := 0 to High(fStateConditions) do
  begin
    var condIndex := fStateConditions[i];
    var cond := fQuery.Conditions[condIndex];

    case cond.Kind of
      ekReachesAge:
        begin
          if fIsAnyAgent then
          begin
            if aSummary.LongestLife.Age >= cond.IntParam then
            begin
              fStopCondition := condIndex;
              Exit;
            end;
          end
          else
          begin
            for var a := 0 to High(fSortedAgents) do
            begin
              var state := fPopulation.GetAgentState(Integer(fSortedAgents[a]));
              if (state <> nil) and (state.Reserves > 0.0) then
                if state.Age >= cond.IntParam then
                begin
                  fStopCondition := condIndex;
                  Exit;
                end;
            end;
          end;
        end;

      ekExceedsReserves:
        begin
          if fIsAnyAgent then
          begin
            if aSummary.MaxReserves.Reserves >= cond.FloatParam then
            begin
              fStopCondition := condIndex;
              Exit;
            end;
          end
          else
          begin
            for var a := 0 to High(fSortedAgents) do
            begin
              var state := fPopulation.GetAgentState(Integer(fSortedAgents[a]));
              if (state <> nil) and (state.Reserves > 0.0) then
                if state.Reserves >= cond.FloatParam then
                begin
                  fStopCondition := condIndex;
                  Exit;
                end;
            end;
          end;
        end;

      ekAwakePastTick:
        begin
          // Only evaluate if current DayTick is past the threshold.
          if fDayTick <= cond.IntParam then
            Continue;

          if fIsAnyAgent then
          begin
            if aSummary.Living - aSummary.Sheltering > 0 then
            begin
              fStopCondition := condIndex;
              Exit;
            end;
          end
          else
          begin
            for var a := 0 to High(fSortedAgents) do
            begin
              var state := fPopulation.GetAgentState(Integer(fSortedAgents[a]));
              if (state <> nil) and (state.Reserves > 0.0) then
                if state.Action <> acShelter then
                begin
                  fStopCondition := condIndex;
                  Exit;
                end;
            end;
          end;
        end;

      ekTravelsDistance:
        begin
          if fIsAnyAgent then
          begin
            if aSummary.MaxDistance.Distance >= cond.IntParam then
            begin
              fStopCondition := condIndex;
              Exit;
            end;
          end
          else
          begin
            if fGridWidth <= 0 then
              Continue;

            for var a := 0 to High(fSortedAgents) do
            begin
              var state := fPopulation.GetAgentState(Integer(fSortedAgents[a]));
              if (state <> nil) and (state.Reserves > 0.0) then
                if ChebyshevDistance(state.Birthplace, state.Location) >= cond.IntParam then
                begin
                  fStopCondition := condIndex;
                  Exit;
                end;
            end;
          end;
        end;
    end;
  end;
end;

procedure TExplorationEvaluator.Prepare(const aQuery: TExplorationQuery);

  procedure SortAgents(var Agents: TArray<TAgentId>);
  begin
    // Simple insertion sort — agent lists are expected to be small.
    for var i := 1 to High(Agents) do
    begin
      var key := Agents[i];
      var j := i - 1;
      while (j >= 0) and (Integer(Agents[j]) > Integer(key)) do
      begin
        Agents[j + 1] := Agents[j];
        Dec(j);
      end;
      Agents[j + 1] := key;
    end;
  end;

begin
  fQuery := aQuery;
  fStopCondition := NOT_TRIGGERED;
  fDayTick := 0;

  // Cache whether this is an "any agent" query.
  fIsAnyAgent := Length(fQuery.Agents) = 0;

  // Sort agent list for binary search during evaluation.
  fSortedAgents := Copy(fQuery.Agents);
  if Length(fSortedAgents) > 1 then
    SortAgents(fSortedAgents);

  // Pre-classify conditions into event-phase and state-phase buckets.
  var eventCount := 0;
  var stateCount := 0;
  SetLength(fEventConditions, Length(fQuery.Conditions));
  SetLength(fStateConditions, Length(fQuery.Conditions));

  for var i := 0 to High(fQuery.Conditions) do
  begin
    case fQuery.Conditions[i].Kind of
      ekBorn, ekDies, ekActionSelected:
        begin
          fEventConditions[eventCount] := i;
          Inc(eventCount);
        end;
      ekAwakePastTick, ekReachesAge, ekTravelsDistance, ekExceedsReserves:
        begin
          fStateConditions[stateCount] := i;
          Inc(stateCount);
        end;
    end;
  end;

  SetLength(fEventConditions, eventCount);
  SetLength(fStateConditions, stateCount);
end;

end.
