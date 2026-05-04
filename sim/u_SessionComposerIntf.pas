unit u_SessionComposerIntf;

interface

uses u_SimRuntimes;

type
  ISessionComposer = interface
    ['{CBE105C8-4127-4A4E-9836-1EB9DB22EC93}']
    procedure Compose(Runtime: TSimRuntime);
  end;

implementation

end.
