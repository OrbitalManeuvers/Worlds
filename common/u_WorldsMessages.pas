unit u_WorldsMessages;

interface

uses WinApi.Windows, WinApi.Messages;

type
  { TSessionId - opaque session index, declared here to avoid layering violations
    between common and sim. u_SessionManager uses this definition. }
  TSessionId = type Integer;

const
  WM_SESSION_SUBMITTED = WM_USER + $0001;
  WM_END_SIMULATION    = WM_USER + $0002;

type
  TWMSessionSubmitted = packed record
    Msg: Cardinal;
    SessionId: TSessionId;  // WParam
    Unused: LPARAM;
    Result: LRESULT;
  end;

implementation

end.
