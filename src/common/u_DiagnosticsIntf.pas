unit u_DiagnosticsIntf;

interface

uses System.Classes,
  u_MulticastEvents, u_SimRuntimes, u_SimControllers;

type
  TBeforeAfterPair = record
    Before: TMulticastEvent<TNotifyEvent>;
    After: TMulticastEvent<TNotifyEvent>;
  end;

  TNotificationEvents = record
    OnStep: TBeforeAfterPair;
    OnRun: TBeforeAfterPair;
  end;

  IRuntimeObserver = interface
    ['{3C7F0298-2DA7-4CF3-A39A-68F9A0E46713}']
    procedure ConnectRuntime(aRuntime: TSimRuntime; aEvents: TNotificationEvents);
    procedure DisconnectRuntime(aRuntime: TSimRuntime; aEvents: TNotificationEvents);
  end;

  IRuntimeController = interface
    ['{5FEEE5B2-D834-48FF-B4B0-16158160044B}']
    procedure ConnectController(aController: TSimController);
    procedure DisconnectController(aController: TSimController);
  end;

implementation

end.
