unit u_Worlds;

interface

uses System.Generics.Collections, System.JSON,

  u_Worlds.Types, u_Environment.Types, u_EditorObjects,

  u_Foods;


implementation

uses System.SysUtils, System.IOUtils;

type
  TWorld = class
  private
  protected
    Name: string;
  public
    constructor Create; override;
    destructor Destroy; override;
  end;

{ TWorld }

constructor TWorld.Create;
begin
  inherited Create;
  Name := 'New World';
end;

destructor TWorld.Destroy;
begin
  inherited;
end;



end.
