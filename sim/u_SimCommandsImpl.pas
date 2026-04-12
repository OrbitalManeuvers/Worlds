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

uses System.Math;

const
  // Recoil debt added per successful consume event.
  // Debt is interpreted as cooldown ticks and is paid down by environment ticks.
  CONSUMPTION_REGEN_DEBT_PER_CONSUME = 2.0;
  CONSUMPTION_REGEN_DEBT_MAX = 6.0;


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

  // Every successful bite adds recoil cooldown debt.
  // Repeated/parallel foraging compounds this debt up to a cap.
  var debt := fEnvironment.Resources[cacheIndex].RegenDebt + CONSUMPTION_REGEN_DEBT_PER_CONSUME;
  fEnvironment.Resources[cacheIndex].RegenDebt := Min(CONSUMPTION_REGEN_DEBT_MAX, debt);

  Reply.ConsumedAmount := consumed;
  Reply.RemainingAmount := fEnvironment.Resources[cacheIndex].Amount;
  Result := consumed > 0.0;
end;

end.
