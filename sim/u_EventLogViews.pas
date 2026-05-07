unit u_EventLogViews;

interface

uses
  u_SimEventTypes;

type
  TEventLogView = class(TInterfacedObject, IEventLogView, ISimEventConsumer)
  private
    { IEventLogView }
    function GetCount: Integer;
    function GetEvent(aIndex: Integer): TSimEvent; // indirection through internal list
    { ISimEventConsumer }
    procedure Consume(const aEvent: TSimEvent);
  private
    fLogView: IEventLog;
    fViewDef: TSimEventViewDef;
    fVisibleEventIndexes: TArray<Integer>;
    fLastScannedLogIndex: Integer;
    function EventMatchesFilter(const aEvent: TSimEvent): Boolean;
  public
    constructor Create(const aLog: IEventLog);
    destructor Destroy; override;
    procedure Define(const aViewDef: TSimEventViewDef);
    procedure Extend;
    procedure AddAgentId(aAgentId: Integer);
  end;

implementation

{ TEventLogView }

constructor TEventLogView.Create(const aLog: IEventLog);
begin
  inherited Create;
  fLogView := aLog;
end;

procedure TEventLogView.Define(const aViewDef: TSimEventViewDef);
begin
  fViewDef := aViewDef;
  fLastScannedLogIndex := 0;

  SetLength(fVisibleEventIndexes, 0);

  var count := fLogView.Count;
  if count = 0 then
    Exit;

  SetLength(fVisibleEventIndexes, count);
  var visibleCount := 0;

  for var i := 0 to count - 1 do
  begin
    if EventMatchesFilter(fLogView.Events[i]) then
    begin
      fVisibleEventIndexes[visibleCount] := i;
      Inc(visibleCount);
    end;
  end;

  SetLength(fVisibleEventIndexes, visibleCount);
  fLastScannedLogIndex := fLogView.Count;
end;

procedure TEventLogView.Extend;
var
  newCount: Integer;
begin
  newCount := fLogView.Count;
  if newCount <= fLastScannedLogIndex then
    Exit;

  for var i := fLastScannedLogIndex to newCount - 1 do
    if EventMatchesFilter(fLogView.Events[i]) then
    begin
      var len := Length(fVisibleEventIndexes);
      SetLength(fVisibleEventIndexes, len + 1);
      fVisibleEventIndexes[len] := i;
    end;

  fLastScannedLogIndex := newCount;
end;

procedure TEventLogView.Consume(const aEvent: TSimEvent);
begin
  if not EventMatchesFilter(aEvent) then
    Exit;

  var insertIndex := fLogView.Count - 1; // event is already appended to the log
  var len := Length(fVisibleEventIndexes);
  SetLength(fVisibleEventIndexes, len + 1);
  fVisibleEventIndexes[len] := insertIndex;
end;

procedure TEventLogView.AddAgentId(aAgentId: Integer);
begin
  fViewDef.AgentIds := fViewDef.AgentIds + [aAgentId];
end;

function TEventLogView.EventMatchesFilter(const aEvent: TSimEvent): Boolean;
  function EventAgentIds(const aEvent: TSimEvent): TArray<Integer>;
  begin
    case aEvent.Header.Kind of
      sekActionResolved:  Result := [aEvent.ActionResolved.AgentId];
      sekDecisionTrace:   Result := [aEvent.DecisionTrace.AgentId];
      sekAgentBorn:       Result := [aEvent.AgentBorn.AgentId, aEvent.AgentBorn.ParentAgentId];
      sekAgentMoved:      Result := [aEvent.AgentMoved.AgentId];
      sekBiomassCreated:
        if aEvent.BiomassCreated.SourceAgentId >= 0 then
          Result := [aEvent.BiomassCreated.SourceAgentId]
        else
          SetLength(Result, 0);
      sekBiomassConsumed: Result := [aEvent.BiomassConsumed.AgentId];
      sekAgentDied:       Result := [aEvent.AgentDied.AgentId];
      sekResourceSampled: SetLength(Result, 0);
    end;
  end;

  function MatchAgent: Boolean;
  begin
    if Length(fViewDef.AgentIds) = 0 then
      Exit(True);

    for var candidate in EventAgentIds(aEvent) do
      for var filter in fViewDef.AgentIds do
        if candidate = filter then
          Exit(True);

    Result := False;
  end;

  function MatchSequence: Boolean;
  begin
    Result := ((fViewDef.StartSequence < 0) or (aEvent.Header.Sequence >= fViewDef.StartSequence)) and
              ((fViewDef.StopSequence  < 0) or (aEvent.Header.Sequence <= fViewDef.StopSequence));
  end;

begin
  Result := (aEvent.Header.Kind in fViewDef.Kinds) and MatchSequence and MatchAgent;
end;

destructor TEventLogView.Destroy;
begin

  inherited;
end;

function TEventLogView.GetCount: Integer;
begin
  Result := Length(fVisibleEventIndexes);
end;

function TEventLogView.GetEvent(aIndex: Integer): TSimEvent;
begin
  Result := fLogView.Events[fVisibleEventIndexes[aIndex]];
end;

end.
