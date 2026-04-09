unit u_Seeds;

interface

uses
  u_EnvironmentTypes;

type
  TSeed = class(TNamedEnvironmentObject)
  private
    fValue: Integer;
    procedure SetValue(const Value: Integer);
  public
    constructor Create;
    property Value: Integer read fValue write SetValue;
  end;

implementation

{ TSeed }

constructor TSeed.Create;
begin
  inherited Create;
  fValue := 0;
end;

procedure TSeed.SetValue(const Value: Integer);
begin
  if fValue <> Value then
  begin
    fValue := Value;
    Changed;
  end;
end;

end.