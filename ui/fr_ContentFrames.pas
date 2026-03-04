unit fr_ContentFrames;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,

  u_Worlds, Vcl.StdCtrls;

type
  TContentFrame = class(TFrame)
  private
  protected
  public
    procedure Init; virtual;
    procedure Done; virtual;
    procedure ActivateContent; virtual;
    procedure DeactivateContent; virtual;
  end;
  TContentFrameClass = class of TContentFrame;

implementation

{$R *.dfm}


{ TContentFrame }

procedure TContentFrame.ActivateContent;
begin
  //
end;

procedure TContentFrame.DeactivateContent;
begin
  //
end;

procedure TContentFrame.Done;
begin
  //
end;

procedure TContentFrame.Init;
begin
  //
end;

end.
