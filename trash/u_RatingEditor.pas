unit u_RatingEditor;

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ControlList, Vcl.ExtCtrls,
  System.Generics.Collections, Vcl.ComCtrls, Vcl.Buttons,

  u_Worlds.Types,
  u_Environment.Types;

type
  TRatingEditor = class
  private
    fDisplay: TPaintBox;
    fRating: TRating;
    procedure SetRating(const Value: TRating);
    procedure Paint(Sender: TObject);
  public
    constructor Create(aDisplaySurface: TPaintBox);
    property Rating: TRating read fRating write SetRating;
  end;


implementation

uses System.Types, Vcl.Themes, Vcl.GraphUtil;


{ TRatingEditor }

constructor TRatingEditor.Create(aDisplaySurface: TPaintBox);
begin
  inherited Create;
  fDisplay := aDisplaySurface;
  fDisplay.OnPaint := Paint;

  // set the default
  Rating := Normal;

end;

procedure TRatingEditor.Paint(Sender: TObject);
var
  bitmap: TBitmap;
  canvas: TCanvas;
  r: TRect;
  details: TThemedElementDetails;
begin
  r := fDisplay.ClientRect;
  bitmap := TBitmap.Create;
  try
    bitmap.Width := r.Width;
    bitmap.Height := r.Height;
    canvas := bitmap.Canvas;

    // fill background
    canvas.Brush.Color := StyleServices.GetSystemColor(clWindow);
    canvas.Brush.Style := bsSolid;
    canvas.FillRect(r);

    // spacing sizes
    const horz_margin = 2;
    const vert_margin = 2;

    // draw caption
    var caption := RATING_NAMES[fRating];
    canvas.Font := fDisplay.Font;
    canvas.Font.Color := StyleServices.GetStyleFontColor(sfButtonTextNormal);
    var captionSize := canvas.TextExtent(caption);

    r := fDisplay.ClientRect;
    Inc(r.Left, horz_margin);
    Inc(r.Top, vert_margin);
    Dec(r.Right, vert_margin);
    r.Bottom := r.Top + captionSize.cy;
    canvas.TextRect(r, caption, [tfSingleLine, tfCenter]);

    // draw segments
    const segment_spacing = 2;
    var pxPerSegment := (r.Width - (horz_margin * 2)) div ((Ord(High(TRating)) + 1 ) );
    r.Left := horz_margin;
    r.top := r.Bottom;
    r.Right := r.Left + (pxPerSegment - horz_margin);
    r.Bottom := r.Top + 9;
    canvas.Brush.Style := bsSolid;

    var normalColor := StyleServices.GetSystemColor(clBtnFace);
    var selectedColor := StyleServices.GetSystemColor(clHighlight);

    for var rValue := Low(TRating) to High(TRating) do
    begin
      if (fRating > Low(TRating)) and (rValue = Pred(fRating)) then
      begin
        var toColor := GetShadowColor(selectedColor, -30);
//        Inc(gradientRect.Left, r.Width div 2);
        Vcl.GraphUtil.GradientFillCanvas(canvas, normalColor, toColor, r, gdHorizontal);

      end
      else if (fRating < High(TRating)) and (rValue = Succ(fRating)) then
      begin
        var toColor := GetShadowColor(selectedColor, -30);
//        Inc(gradientRect.Left, r.Width div 2);
        Vcl.GraphUtil.GradientFillCanvas(canvas, toColor, normalColor, r, gdHorizontal);

      end
      else if rValue = fRating then
      begin
        canvas.Brush.Color := selectedColor;
        canvas.FillRect(r);
      end
      else
      begin
        canvas.Brush.Color := normalColor;
        canvas.FillRect(r);
      end;
//        canvas.FillRect(r);
      r.SetLocation(r.Left + pxPerSegment, r.top);
    end;

    // draw the osb to the display
    r := fDisplay.Canvas.ClipRect;
    fDisplay.Canvas.CopyRect(r, canvas, r);
    //Draw(0, 0, bitmap);
  finally
    bitmap.Free;
  end;
end;

procedure TRatingEditor.SetRating(const Value: TRating);
begin
  if Value <> fRating then
  begin
    fRating := Value;
    fDisplay.Invalidate;
  end;
end;

end.
