unit u_SimCommandsImpl;

interface

uses u_SimCommandsIntf, u_SimEnvironments;

type
  TSimCommand = class(TInterfacedObject, ISimCommand, IEnvironmentCommand, IEnvironmentForageCommand)
  private
    fEnvironment: TSimEnvironment;

    { IEnvironmentForageCommand }
    function TryConsumeCache(const Request: TConsumeCacheRequest; out Reply: TConsumeCacheReply): Boolean;

  public
    constructor Create(aEnvironment: TSimEnvironment);
  end;


implementation

const
  // Baseline cooldown debt applied when a consumption event empties a cache.
  // Debt is paid down by growth potential in environment update ticks.
  CONSUMPTION_EMPTY_REGEN_DEBT = 0.40;

{ TSimCommand }

constructor TSimCommand.Create(aEnvironment: TSimEnvironment);
begin
  inherited Create;
  fEnvironment := aEnvironment;
end;

function TSimCommand.TryConsumeCache(const Request: TConsumeCacheRequest;
  out Reply: TConsumeCacheReply): Boolean;
begin
  Reply := Default(TConsumeCacheReply);
  Result := False;

  var cacheIndex := Request.CacheId;
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

  // Apply cooldown only when this consume event transitions the cache to empty.
  if (remaining <= 0.0) and (available > 0.0) then
    fEnvironment.Resources[cacheIndex].RegenDebt := CONSUMPTION_EMPTY_REGEN_DEBT;

  Reply.ConsumedAmount := consumed;
  Reply.RemainingAmount := fEnvironment.Resources[cacheIndex].Amount;
  Result := consumed > 0.0;
end;

end.
