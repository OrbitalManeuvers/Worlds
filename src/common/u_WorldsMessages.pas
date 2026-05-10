unit u_WorldsMessages;

interface

uses WinApi.Windows, WinApi.Messages;

const
  WM_SESSION_SUBMITTED = WM_USER + $0001;
  WM_END_SIMULATION    = WM_USER + $0002;

type
  TWMSessionSubmitted = packed record
    Msg: Cardinal;
    WParam: WPARAM;
    Unused: LPARAM;
    Result: LRESULT;
  end;

implementation

end.
