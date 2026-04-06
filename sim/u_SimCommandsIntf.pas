unit u_SimCommandsIntf;

interface

uses u_SimEnvironments;

type
  ISimCommand = interface
    ['{AA4AC2FC-B900-4979-B637-1CA28670DCEB}']
  end;

  IEnvironmentCommand = interface(ISimCommand)
    ['{B20DA051-3F33-4FB6-A7FD-64779E0A74F8}']
  end;

  TConsumeCacheRequest = record
    CacheId: Integer;
    RequestedAmount: Single;
  end;

  TConsumeCacheReply = record
    ConsumedAmount: Single;
    RemainingAmount: Single;
    Substance: TSubstance;
  end;

  IEnvironmentForageCommand = interface(IEnvironmentCommand)
    ['{C7A2E2ED-46E4-4EF9-B0FD-D9C9A2C9A4B8}']
    function TryConsumeCache(const Request: TConsumeCacheRequest; out Reply: TConsumeCacheReply): Boolean;
  end;


implementation

end.
