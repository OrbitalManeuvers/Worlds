program WorldsServer;
{$APPTYPE GUI}

uses
  Vcl.Forms,
  Web.WebReq,
  IdHTTPWebBrokerBridge,
  f_ServerMainForm in 'server\f_ServerMainForm.pas' {Form1},
  dm_ServerWebModule in 'server\dm_ServerWebModule.pas' {WebMain: TWebModule};

{$R *.res}

begin
  if WebRequestHandler <> nil then
    WebRequestHandler.WebModuleClass := WebModuleClass;
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
