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

  fEnvironment.Resources[cacheIndex].Amount := available - consumed;

  Reply.ConsumedAmount := consumed;
  Reply.RemainingAmount := fEnvironment.Resources[cacheIndex].Amount;
  Result := consumed > 0.0;
end;

end.
