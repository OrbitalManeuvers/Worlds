unit fr_ContentFrames;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,

  u_Worlds, Vcl.StdCtrls;

type
  TContentFrame = class(TFrame)
  private
    fWorld: TWorld;
    procedure SetWorld(const Value: TWorld);
  protected
    procedure InitContent; virtual; abstract;
  public
    property World: TWorld read fWorld write SetWorld;
  end;
  TContentFrameClass = class of TContentFrame;

implementation

{$R *.dfm}

{ TContentFrame }

procedure TContentFrame.SetWorld(const Value: TWorld);
begin
  fWorld := Value;
  InitContent;
end;

end.
