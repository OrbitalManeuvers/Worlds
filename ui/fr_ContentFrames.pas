unit fr_ContentFrames;

interface

uses
  System.Classes, Vcl.Forms;

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
