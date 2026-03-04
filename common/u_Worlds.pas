unit u_Worlds;

interface

uses System.Generics.Collections, System.JSON,

  u_Worlds.Types, u_Environment.Types, u_EditorObjects,

  u_Foods;

type
  TWorld = class(TEditorObject)
  private
  protected
    Name: string;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses System.SysUtils, System.IOUtils;

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
