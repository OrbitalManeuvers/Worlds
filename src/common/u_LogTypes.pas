unit u_LogTypes;

interface

uses System.Classes;

type
  TLogField = record
    Name: string;
    Value: string;
    function AsFieldText: string;
  end;

  TLogFields = record
    Fields: TArray<TLogField>;    // structured data for details, export, columns
    procedure Add(const aName, aValue: string);
    procedure AddFields(aNewFields: TLogFields);
    function Count: Integer;
    procedure Clear;
    function AsFieldText(FromField, ToField: Integer): string; overload;
    function AsFieldText(): string; overload;
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

procedure TLogFields.AddFields(aNewFields: TLogFields);
begin
  var newLen := Self.Count + aNewFields.Count;
  if newLen <> Self.Count then
  begin
    var baseIndex := Length(Fields);
    SetLength(Fields, newLen);
    for var i := 0 to aNewFields.Count - 1 do
      Fields[baseIndex + i] := aNewFields.Fields[i];
  end;
end;

function TLogFields.AsFieldText: string;
begin
  Result := AsFieldText(Low(Fields), High(Fields));
end;

function TLogFields.AsFieldText(FromField, ToField: Integer): string;
begin
  Result := '';
  for var i := FromField to ToField do
    Result := Result + Fields[i].AsFieldText() + ' ';
  SetLength(Result, Length(Result) - 1);
end;

procedure TLogFields.Clear;
begin
  SetLength(Fields, 0);
end;

function TLogFields.Count: Integer;
begin
  Result := Length(Fields);
end;

//procedure TLogFields.GetPairs(Strings: TStrings);
//begin
//  Strings.BeginUpdate;
//  try
//    for var f in Fields do
//      Strings.AddPair(f.Name, f.Value);
//  finally
//    Strings.EndUpdate;
//  end;
//end;

{ TLogField }
function TLogField.AsFieldText: string;
begin
  if Name <> '' then
    Result := Name + ':' + Value
  else
    Result := Value;
end;

end.
