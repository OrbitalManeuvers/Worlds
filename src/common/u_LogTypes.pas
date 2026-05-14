unit u_LogTypes;

interface

type
  TLogField = record
    Name: string;
    Value: string;
    function AsShortText: string;
  end;

  TLogFields = record
    Fields: TArray<TLogField>;    // structured data for details, export, columns
    procedure Add(const aName, aValue: string);
    function ShortFieldText: string;
  end;

implementation

{ TLogFields }

procedure TLogFields.Add(const aName, aValue: string);
begin
  var i := Length(Fields);
  SetLength(Fields, i + 1);
  Fields[i].Name := aName;
  Fields[i].Value := aValue;
end;

function TLogFields.ShortFieldText: string;
begin
  var s := '';
  for var f in Fields do
    s := s + f.AsShortText + ' ';
  Result := s;
end;

{ TLogField }

function TLogField.AsShortText: string;
begin
  Result := Name + ':' + Value;
end;

end.
