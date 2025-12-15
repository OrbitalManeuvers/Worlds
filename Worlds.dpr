program Worlds;

uses
  Vcl.Forms,
  Main in 'Main.pas' {MainForm},
  WorldTypes in 'engine\WorldTypes.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
