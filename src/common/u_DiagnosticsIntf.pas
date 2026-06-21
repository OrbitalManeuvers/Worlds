unit u_DiagnosticsIntf;

interface

uses System.Classes,
  u_MulticastEvents, u_SimRuntimes, u_SimControllers;

type
  TBeforeAfterPair = record
    Before: TMulticastEvent<TNotifyEvent>;
    After: TMulticastEvent<TNotifyEvent>;
  end;

  TNotifications = record
    OnStep: TBeforeAfterPair;
    OnRun: TBeforeAfterPair;
  end;

  IRuntimeObserver = interface
    ['{3C7F0298-2DA7-4CF3-A39A-68F9A0E46713}']
    procedure ConnectRuntime(aRuntime: TSimRuntime; AfterAdvance: TMulticastEvent<TNotifyEvent>);
    procedure DisconnectRuntime(aRuntime: TSimRuntime; AfterAdvance: TMulticastEvent<TNotifyEvent>);
  end;

  IRuntimeController = interface
    ['{5FEEE5B2-D834-48FF-B4B0-16158160044B}']
    procedure ConnectController(aController: TSimController);
    procedure DisconnectController(aController: TSimController);
  end;

//  IRuntimeSubscriber = interface
//    ['{85ED171D-E633-4638-8109-C31B9251B3D2}']
//    procedure SetSubscriptionId(aValue: Integer);
//    function GetSubscriptionId: Integer;
//  end;

  IDiagnosticsView = interface
    ['{A1D7F4E3-92C8-4B1A-B5F7-3E6D8C0A9B24}']
    procedure BeginRun;
    procedure EndRun;
  end;

implementation

end.
