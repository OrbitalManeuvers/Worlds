unit u_LogTypes;

interface

type
  TLogFieldKind = (
    lfkText,
    lfkNumber,
    lfkEnum,
    lfkReference
  );

  TLogField = record
    Key: string;         // stable programmatic name: ReserveDelta
    Caption: string;     // short UI label: rd
    FullCaption: string; // optional longer label: Reserve delta
    ValueText: string;   // already formatted for display: 0.002
    Kind: TLogFieldKind; // optional UI hint
  end;

  TLogRow = record
    Summary: string;              // optional compact line for the tree
    Fields: TArray<TLogField>;    // structured data for details, export, columns
    procedure Add(const Key, Caption, FullCaption, ValueText: string; Kind: TLogFieldKind = lfkText);
    function GetFieldText: string;
  end;

implementation

{ TLogRow }

procedure TLogRow.Add(const Key, Caption, FullCaption, ValueText: string; Kind: TLogFieldKind);
begin
  var i := Length(Fields);
  SetLength(Fields, i + 1);
  Fields[i].Key := Key;
  Fields[i].Caption := Caption;
  Fields[i].FullCaption := FullCaption;
  Fields[i].ValueText := ValueText;
  Fields[i].Kind := Kind;
end;

function TLogRow.GetFieldText: string;
begin
  var s := '';
  for var f in Fields do
    s := s + f.Caption + ':' + f.ValueText + ' ';
  Result := s;
end;

end.
