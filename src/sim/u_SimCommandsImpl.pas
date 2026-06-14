unit u_SimCommandsImpl;

interface

uses u_SimCommandsIntf, u_SimEnvironments, u_SimPopulations;

type
  TSimCommand = class(TInterfacedObject, ISimCommand, 
    IEnvironmentCommand, IEnvironmentForageCommand,
    IPopulationCommand, IMoveAgentCommand)
  private
    fEnvironment: TSimEnvironment;
    fPopulation: TSimPopulation;

    { IEnvironmentForageCommand }
    function TryConsumeCache(const Request: TConsumeCacheRequest; out Reply: TConsumeCacheReply): Boolean;

    { IMoveAgentCommand }
    function TryMoveAgent(const Request: TMoveAgentRequest; out Reply: TMoveAgentReply): Boolean;

  public
    constructor Create(aEnvironment: TSimEnvironment; aPopulation: TSimPopulation);
  end;


implementation

uses System.Math, u_AgentState, u_AgentTypes;


{ TSimCommand }

constructor TSimCommand.Create(aEnvironment: TSimEnvironment; aPopulation: TSimPopulation);
begin
  inherited Create;
  fEnvironment := aEnvironment;
  fPopulation := aPopulation;
end;

function TSimCommand.TryConsumeCache(const Request: TConsumeCacheRequest; out Reply: TConsumeCacheReply): Boolean;
begin
  Reply := Default(TConsumeCacheReply);
  Result := False;

  case Request.Cache.Kind of
    ckResource:
      begin
        var cacheIndex := Request.Cache.Index;
        var available := fEnvironment.Resources[cacheIndex].Amount;
        if available <= 0.0 then
          Exit;

        var consumed := Request.RequestedAmount;
        if consumed > available then
          consumed := available;

        var substanceIndex := fEnvironment.Resources[cacheIndex].SubstanceIndex;
        Reply.Substance := fEnvironment.SubstanceEntries[substanceIndex].Substance;

        var remaining := available - consumed;
        fEnvironment.Resources[cacheIndex].Amount := remaining;

        Reply.ConsumedAmount := consumed;
        Reply.RemainingAmount := fEnvironment.Resources[cacheIndex].Amount;
        Result := consumed > 0.0;
      end;
    ckDelta:
      begin
        var cacheIndex := Request.Cache.Index;
        var available := fEnvironment.DeltaCaches[cacheIndex].Amount;
        if available <= 0.0 then
          Exit;

        var consumed := Request.RequestedAmount;
        if consumed > available then
          consumed := available;

        Reply.Substance := DELTA_SUBSTANCE;

        var remaining := available - consumed;
        fEnvironment.DeltaCaches[cacheIndex].Amount := remaining;

        Reply.ConsumedAmount := consumed;
        Reply.RemainingAmount := fEnvironment.DeltaCaches[cacheIndex].Amount;
        Result := consumed > 0.0;
      end;
  end;
end;

function TSimCommand.TryMoveAgent(const Request: TMoveAgentRequest; out Reply: TMoveAgentReply): Boolean;
begin
  Reply := Default(TMoveAgentReply);
  Result := False;

  var state := fPopulation.GetAgentState(Request.AgentIndex);

  Reply.PreviousCell := state.Location;
  Reply.NewCell := state.Location;

  if (Request.DestinationCell < 0) or (Request.DestinationCell > High(fEnvironment.Cells)) then
  begin
    Reply.RejectReason := mrrOutOfBounds;
    Exit;
  end;

  if Request.DestinationCell = state.Location then
  begin
    Reply.RejectReason := mrrNoChange;
    Exit;
  end;

  var width := fEnvironment.Dimensions.cx;
  var height := fEnvironment.Dimensions.cy;
  if (width <= 0) or (height <= 0) then
  begin
    Reply.RejectReason := mrrOutOfBounds;
    Exit;
  end;

  var fromX := state.Location mod width;
  var fromY := state.Location div width;
  var toX := Request.DestinationCell mod width;
  var toY := Request.DestinationCell div width;

  var dx := Abs(toX - fromX);
  var dy := Abs(toY - fromY);
  if Max(dx, dy) <> 1 then
  begin
    Reply.RejectReason := mrrNotAdjacent;
    Exit;
  end;

  // Location mutation and index update are handled by the runtime caller.
  Reply.Moved := True;
  Reply.NewCell := Request.DestinationCell;
  Reply.RejectReason := mrrNone;
  Result := True;
end;

end.
