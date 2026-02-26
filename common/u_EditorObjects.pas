unit u_EditorObjects;

interface

uses System.Classes, System.Generics.Collections, System.JSON,
  u_Worlds.Types;

type
  TEditorObject = class
  private
    fModified: Boolean;
    fUpdateCount: Integer;
    fOnChange: TNotifyEvent;
    procedure SetModified(const Value: Boolean);
  protected
    procedure Changed;
    procedure ChildChanged(Sender: TObject); virtual;
  public
    procedure BeginUpdate;
    procedure EndUpdate;

    property Modified: Boolean read fModified write SetModified;
    property OnChange: TNotifyEvent read fOnChange write fOnChange;
  end;


implementation

{ TEditorObject }

procedure TEditorObject.BeginUpdate;
begin
  Inc(fUpdateCount);
end;

procedure TEditorObject.Changed;
begin
  Modified := True;
end;

procedure TEditorObject.ChildChanged(Sender: TObject);
begin
  Changed;
end;

procedure TEditorObject.EndUpdate;
begin
  if fUpdateCount > 0 then
  begin
    Dec(fUpdateCount);
    if fUpdateCount = 0 then
    begin
      if fModified then
      begin
        if Assigned(fOnChange) then
          fOnChange(Self);
      end;
    end;
  end;
end;

procedure TEditorObject.SetModified(const Value: Boolean);
begin
  fModified := Value;
  if (fUpdateCount = 0) and Assigned(fOnChange) then
    fOnChange(Self);
end;

end.
