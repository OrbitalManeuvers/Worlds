unit u_FieldRendering;

interface

uses System.SysUtils, System.Types, System.Generics.Collections, Vcl.Graphics,
  u_LogTypes;

type
  TFieldColor = record
    NameIndex: Integer;
    ValueIndex: Integer;
  end;

  TDefaultColors = record
    Bk: TColor;
    NameColor: TColor;
    ValueColor: TColor;
  end;

  TDisplayFields = record
    Palette: TArray<TColor>;
    Defaults: TDefaultColors;
    FieldColors: TArray<TFieldColor>;
    LogFields: TLogFields;
    procedure AddField(const nameStr, valueStr: string; nameIdx, valueIdx: Integer); overload;
    procedure AddField(const nameStr, valueStr: string); overload;
  end;

  TFieldDisplayEngine = class
    class procedure RenderFields(const Fields: TDisplayFields; Canvas: TCanvas; Dest: TRect);
  end;


implementation

uses System.Math;

const
  FIELD_FONT_NAME = 'Consolas';
  FIELD_FONT_SIZE = 10;
  FIELD_SPACING_PX = 8;

{ TFieldDisplayEngine }

class procedure TFieldDisplayEngine.RenderFields(const Fields: TDisplayFields;
  Canvas: TCanvas; Dest: TRect);
begin
 //
  var bitmap := TBitmap.Create;
  try
    bitmap.Width := Max(10, Dest.Width);
    bitmap.Height := Max(10, Dest.Height);

    // background
    bitmap.canvas.Brush.Style := bsSolid;
    bitmap.canvas.Brush.Color := Fields.Defaults.Bk;
    bitmap.canvas.FillRect(Dest);

    if Fields.LogFields.Count > 0 then
    begin
      bitmap.Canvas.Font.Name := FIELD_FONT_NAME;
      bitmap.Canvas.Font.Size := FIELD_FONT_SIZE;

      var cellRect := Dest;
      cellRect.Inflate(-1, -1);

      for var fieldIndex := 0 to Fields.LogFields.Count - 1 do
      begin
        var nameStr := Fields.LogFields.Fields[fieldIndex].Name;
        if nameStr.Length > 0 then
          nameStr := nameStr + ':';
        var valueStr := Fields.LogFields.Fields[fieldIndex].Value;

        // take the hit of measuring each individually since we'll need it anyway
        var nameExt := bitmap.Canvas.TextExtent(nameStr);
        var valueExt := bitmap.Canvas.TextExtent(valueStr);

        // if there's room
        if cellRect.Left + nameExt.cx + valueExt.cx < bitmap.Width - 1 then
        begin
          var contentRect := cellRect;
          var fontColor: TColor;

          // draw field name. start with default color
          fontColor := Fields.Defaults.NameColor;
          if fieldIndex < Length(Fields.FieldColors) then
          begin
            var paletteIndex := Fields.FieldColors[fieldIndex].NameIndex;
            if paletteIndex >= 0 then
              fontColor := Fields.Palette[paletteIndex];
          end;
          bitmap.Canvas.Font.Color := fontColor;

          contentRect.Right := contentRect.Left + nameExt.cx;
          bitmap.Canvas.TextRect(contentRect, nameStr, [tfSingleLine,tfVerticalCenter]);

          // draw field value
          contentRect.Left := contentRect.Right + 1;
          contentRect.Right := contentRect.Left + valueExt.cx;
          fontColor := Fields.Defaults.ValueColor;
          if fieldIndex < Length(Fields.FieldColors) then
          begin
            var paletteIndex := Fields.FieldColors[fieldIndex].ValueIndex;
            if paletteIndex >= 0 then
              fontColor := Fields.Palette[paletteIndex];
          end;
          bitmap.Canvas.Font.Color := fontColor;
          bitmap.Canvas.TextRect(contentRect, valueStr, [tfSingleLine,tfVerticalCenter]);

          cellRect.Left := contentRect.Right + FIELD_SPACING_PX;
        end
        else
          Break;

      end;

    end;

    // xfer to display surface
    Canvas.CopyRect(Dest, bitmap.Canvas, Dest);

  finally
    bitmap.Free;
  end;
end;

{ TDisplayFields }

procedure TDisplayFields.AddField(const nameStr, valueStr: string; nameIdx, valueIdx: Integer);
begin
  Self.LogFields.Add(nameStr, valueStr);
  var i := Length(FieldColors);
  SetLength(FieldColors, i + 1);
  FieldColors[i].NameIndex := nameIdx;
  FieldColors[i].ValueIndex := valueIdx;
end;

procedure TDisplayFields.AddField(const nameStr, valueStr: string);
begin
  AddField(nameStr, valueStr, -1, -1);
end;

end.
