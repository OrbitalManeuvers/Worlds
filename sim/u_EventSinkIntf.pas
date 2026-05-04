unit u_EventSinkIntf;

interface

uses System.Classes, u_SimDiagnosticsIntf;

type
  IEventSink = interface
    ['{E42567E7-85F6-4C87-90BE-B00699011824}']
    procedure Write(aEvent: TSimEvent);
  end;

  IEventLog = interface
    ['{3894A514-3F88-4E07-9618-1A1E588CE60C}']
    procedure Subscribe(const aHandler: TNotifyEvent);
    procedure Unsubscribe(const aHandler: TNotifyEvent);
    function GetCount: Integer;
    function GetEvent(aIndex: Integer): TSimEvent;

    property Count: Integer read GetCount;
    property Events[aIndex: Integer]: TSimEvent read GetEvent;

  end;
implementation

end.
