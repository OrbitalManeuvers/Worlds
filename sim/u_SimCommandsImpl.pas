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

const
  // Recoil debt added per successful consume event.
  // Debt is interpreted as cooldown ticks and is paid down by environment ticks.
  CONSUMPTION_REGEN_DEBT_PER_CONSUME = 2.0;
  CONSUMPTION_REGEN_DEBT_MAX = 6.0;


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
        Reply.Substance := fEnvironment.Substances[substanceIndex];

        var remaining := available - consumed;
        fEnvironment.Resources[cacheIndex].Amount := remaining;

        // Every successful bite adds recoil cooldown debt.
        // Repeated/parallel foraging compounds this debt up to a cap.
        var debt := fEnvironment.Resources[cacheIndex].RegenDebt + CONSUMPTION_REGEN_DEBT_PER_CONSUME;
        fEnvironment.Resources[cacheIndex].RegenDebt := Min(CONSUMPTION_REGEN_DEBT_MAX, debt);

        Reply.ConsumedAmount := consumed;
        Reply.RemainingAmount := fEnvironment.Resources[cacheIndex].Amount;
        Result := consumed > 0.0;
      end;
    ckBiomass:
      begin
        var cacheIndex := Request.Cache.Index;
        var available := fEnvironment.BiomassCaches[cacheIndex].Amount;
        if available <= 0.0 then
          Exit;

        var consumed := Request.RequestedAmount;
        if consumed > available then
          consumed := available;

        Reply.Substance := BIOMASS_SUBSTANCE;

        var remaining := available - consumed;
        fEnvironment.BiomassCaches[cacheIndex].Amount := remaining;

        Reply.ConsumedAmount := consumed;
        Reply.RemainingAmount := fEnvironment.BiomassCaches[cacheIndex].Amount;
        Result := consumed > 0.0;
      end;
  end;
end;

function TSimCommand.TryMoveAgent(const Request: TMoveAgentRequest; out Reply: TMoveAgentReply): Boolean;
begin
  Reply := Default(TMoveAgentReply);
  Result := False;

  var state: TAgentState;
  if not Assigned(fPopulation) or not fPopulation.TryGetAgentState(Request.AgentIndex, state) then
  begin
    Reply.RejectReason := mrrAgentNotFound;
    Exit;
  end;

  Reply.PreviousCell := state.Location;
  Reply.NewCell := state.Location;

  if not Assigned(fEnvironment) then
  begin
    Reply.RejectReason := mrrOutOfBounds;
    Exit;
  end;

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

  state.Location := Request.DestinationCell;
  fPopulation.UpdateAgentState(Request.AgentIndex, state);

  Reply.Moved := True;
  Reply.NewCell := Request.DestinationCell;
  Reply.RejectReason := mrrNone;
  Result := True;
end;

end.
