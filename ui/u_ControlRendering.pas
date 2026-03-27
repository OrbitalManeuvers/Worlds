unit u_ControlRendering;

interface

uses
  Winapi.Windows, System.SysUtils, Vcl.Graphics,
  Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls,

  u_EnvironmentTypes,
  u_Foods;

type
  TPaintboxHelper = class helper for TPaintBox
  private type
    TLayout = record
      content: TRect;
      cellSize: TPoint;
      margins: TPoint;
    end;
    function GetColorGridLayout(): TLayout;
  public
    procedure Render(Rating: TRating; const aCaption: string); overload;

    procedure Render(Recipe: TRecipe); overload;
    procedure Render(Recipe: TRecipe; Molecule: TGrowableMolecule); overload;
    function PercentAtPos(X, Y: Integer; out Percent: TPercentage): Boolean;

    procedure RenderToolButton(const aCaption: string; aColor: TColor; isActive: Boolean);

    procedure RenderColorPresets;
    function ColorAtPos(X, Y: Integer; out aColor: TColor): Boolean;
  end;

implementation

uses System.Types, Vcl.Themes, Vcl.GraphUtil, System.Math,
  u_EditorTypes;

const
  PresetBiomeColors: array[0..9] of string = (
    '#D8BFA6','#B3D8A6','#D47349','#BE9974','#4F7CAC',
    '#87BE74','#99734D','#60994D','#6FA3A8','#C75538'
  );


{ TPaintboxHelper }

procedure TPaintboxHelper.Render(Recipe: TRecipe);
begin
  var r := Self.ClientRect;
  var bitmap := TBitmap.Create;
  try
    bitmap.Width := Self.ClientWidth;
    bitmap.Height := self.ClientHeight;

    // background
    bitmap.canvas.Brush.Color := StyleServices.GetSystemColor(clWindow);
    bitmap.canvas.Brush.Style := bsSolid;
    bitmap.canvas.FillRect(r);

    // sizes
    var colCount := Ord(High(TGrowableMolecule)) + 1;
    var colWidth := Floor(r.Width / colCount);

    for var gm := Low(TGrowableMolecule) to High(TGrowableMolecule) do
    begin
      var percent := Recipe.Percents[gm];
      var h := Floor(r.Height * (percent * 0.01));
      var colRect := r;
      colRect.Top := colrect.Bottom - h;
      colRect.Left := Ord(gm) * colWidth;
      colRect.Right := colRect.Left + colWidth;

      bitmap.Canvas.Brush.Style := bsSolid;
      bitmap.Canvas.Brush.Color := WebColorStrToColor(MOLECULE_COLORS[gm]);
      bitmap.Canvas.FillRect(colRect);

      colRect.Top := r.Top;
      bitmap.Canvas.Brush.Color := clGray;
      bitmap.Canvas.FrameRect(colRect);
    end;

    // xfer to display surface
    r := Self.Canvas.ClipRect;
    Self.Canvas.CopyRect(r, bitmap.Canvas, r);

  finally
    bitmap.Free;
  end;
end;

procedure TPaintboxHelper.Render(Rating: TRating; const aCaption: string);
begin
  var r := Self.ClientRect;

  var bitmap := TBitmap.Create;
  try
    bitmap.Width := Self.ClientWidth;
    bitmap.Height := self.ClientHeight;

    // background
    bitmap.canvas.Brush.Color := StyleServices.GetSystemColor(clBtnFace);
    bitmap.canvas.Brush.Style := bsSolid;
    bitmap.canvas.FillRect(r);

    // spacing sizes
    const horz_margin = 2;
    const vert_margin = 2;

    // draw caption
    var caption := aCaption;
    bitmap.canvas.Font := Self.Font;
    bitmap.canvas.Font.Color := StyleServices.GetStyleFontColor(sfButtonTextNormal);
    var captionSize := bitmap.canvas.TextExtent(caption);

    Inc(r.Left, horz_margin);
    Inc(r.Top, vert_margin);
    Dec(r.Right, horz_margin);
    r.Bottom := r.Top + captionSize.cy;
    bitmap.Canvas.Brush.Style := bsClear;
    bitmap.canvas.TextRect(r, caption, [tfSingleLine, tfCenter]);

    // draw segments
    r.Top := r.Bottom;
    r.Left := horz_margin;
    r.Right := Self.ClientWidth - 2;

//    const segment_spacing = 2;
// it's visually OK but segment_spacing isn't used yet - figure what to do here

    const segment_height = 10;
    var pxPerSegment := Floor(r.Width / (Ord(High(TRating)) + 1));

    r.Right := r.Left + (pxPerSegment - horz_margin);
    r.Bottom := r.Top + segment_height;
    bitmap.canvas.Brush.Style := bsSolid;

    var normalColor := StyleServices.GetSystemColor(clBtnShadow);
    var selectedColor := StyleServices.GetSystemColor(clHighlight);

    for var rValue := Low(TRating) to High(TRating) do
    begin
      if rValue = Rating then
      begin
        bitmap.canvas.Brush.Color := selectedColor;
        bitmap.canvas.FillRect(r);
      end
      else
      begin
        bitmap.canvas.Brush.Color := normalColor;
        bitmap.canvas.FillRect(r);
      end;
      r.SetLocation(r.Left + pxPerSegment, r.top);
    end;

    // xfer to display surface
    r := Self.Canvas.ClipRect;
    Self.Canvas.CopyRect(r, bitmap.Canvas, r);

  finally
    bitmap.Free;
  end;
end;

procedure TPaintboxHelper.Render(Recipe: TRecipe; Molecule: TGrowableMolecule);
begin
  var bitmap := TBitmap.Create;
  try
    bitmap.Width := Self.ClientWidth;
    bitmap.Height := self.ClientHeight;

    // background
    var contentRect := Self.ClientRect;
    bitmap.canvas.Brush.Style := bsSolid;
    bitmap.canvas.Brush.Color := StyleServices.GetSystemColor(clWindow);
    bitmap.canvas.FillRect(contentRect);
    bitmap.canvas.Brush.Color := StyleServices.GetSystemColor(clBtnHighlight);
    bitmap.Canvas.FrameRect(contentRect);

    const hv_margin = 2;
    contentRect.Inflate(-hv_margin, -hv_margin);

    // calculate how tall each segment can be if we need 11 + 1 blank space
    var segmentHeight := Floor(contentRect.Height / (10 + 2));
    var currentValue := Recipe.Percents[Molecule] div 10;
    var balanced := Recipe.IsBalanced;

    var unbalancedColor := Vcl.GraphUtil.ColorBlendRGB(clWhite, clRed, 0.5);

    bitmap.Canvas.Font := Self.Font;
    bitmap.Canvas.Font.Color := StyleServices.GetSystemColor(clWindow);
    bitmap.Canvas.Font.Style := [fsBold];

    for var segmentValue := 0 to 10 do
    begin
      var slotIndex := 10 - segmentValue;           // 100% is at the top (smallest Y)
      if segmentValue = 0 then
        Inc(slotIndex);
      var slotYPos := (segmentHeight * slotIndex) + hv_margin;

      var r := contentRect;
      r.Bottom := r.Top + (segmentHeight - 1);
      r.SetLocation(r.Left, slotYPos);

      if segmentValue = 0 then
      begin
        bitmap.Canvas.Brush.Style := bsSolid;
        bitmap.Canvas.Brush.Color := clGray;
        if currentValue = 0 then
          bitmap.Canvas.FillRect(r)
        else
          bitmap.Canvas.FrameRect(r);
      end
      else
      begin
        if not balanced then
          bitmap.Canvas.Brush.Color := unbalancedColor
        else if segmentValue > currentValue then
          bitmap.Canvas.Brush.Color := clGray
        else
          bitmap.Canvas.Brush.Color := WebColorStrToColor(MOLECULE_COLORS[Molecule]);
        if segmentValue > currentValue then
          bitmap.Canvas.FrameRect(r)
        else
          bitmap.Canvas.FillRect(r);
      end;

      if segmentValue = currentValue then
      begin
        var s := IntToStr(currentValue * 10) + '%';
        bitmap.Canvas.TextRect(r, s, [tfSingleLine, tfCenter, tfVerticalCenter]);
      end;
    end;

    // xfer to display surface
    contentRect := Self.Canvas.ClipRect;
    Self.Canvas.CopyRect(contentRect, bitmap.Canvas, contentRect);

  finally
    bitmap.Free;
  end;

end;

function TPaintboxHelper.PercentAtPos(X, Y: Integer; out Percent: TPercentage): Boolean;
begin
  var p := Point(X, Y);
  if not Self.ClientRect.Contains(p) then
  begin
    Exit(False);
  end;

  // someone clean up this mess

  const hv_margin = 2;
  var contentRect := Self.ClientRect;
  contentRect.Inflate(-hv_margin, -hv_margin);

  // calculate how tall each segment can be if we need 11 + 1 blank space
  var segmentHeight := Floor(contentRect.Height / (11 + 1));
  var segmentIndex := Min(y div segmentHeight, 11);

  case segmentIndex of
    11: Percent := 0;
    10: Exit(False);
    else
      Percent := (10 - segmentIndex) * 10;
  end;

  Result := True;
end;


function TPaintboxHelper.GetColorGridLayout(): TLayout;
begin
  // 5x5 grid
  Result.margins := Point(2, 2);
  Result.content := Self.ClientRect;
  Result.content.Inflate(-Result.margins.X, -Result.margins.Y);
  Result.cellSize.X := Floor(Result.content.Width / 5) - 1;
  Result.cellSize.Y := Floor(Result.content.Height / 2) - 1;
end;

function TPaintboxHelper.ColorAtPos(X, Y: Integer; out aColor: TColor): Boolean;
begin
  var layout := GetColorGridLayout();
  var mouse := Point(X, Y);
  if layout.content.Contains(mouse) then
  begin
    // normalize mouse pos within content rect
    Dec(mouse.X, layout.content.Left);
    Dec(mouse.y, layout.content.Top);

    // figure out which cell was clicked
    var hitCell := Point(mouse.X div (layout.cellSize.X + layout.margins.X),
      mouse.Y div (layout.cellSize.Y + layout.margins.Y));
    if (hitCell.X < 5) and (hitCell.Y < 2) then
    begin 
      var colorIndex := hitCell.X + (hitCell.Y * 5);
      if colorIndex < Length(PresetBiomeColors) then
      begin
        aColor := WebColorStrToColor(PresetBiomeColors[colorIndex]);
        Exit(True);
      end;
    end;
  end;

  Result := False;
end;

procedure TPaintboxHelper.RenderColorPresets;
begin
  var bitmap := TBitmap.Create;
  try
    bitmap.Width := Self.ClientWidth;
    bitmap.Height := self.ClientHeight;

    // background
    bitmap.canvas.Brush.Style := bsSolid;
    bitmap.canvas.Brush.Color := StyleServices.GetSystemColor(clWindow);
    bitmap.canvas.FillRect(Self.ClientRect);
    bitmap.canvas.Brush.Color := StyleServices.GetSystemColor(clBtnHighlight);
    bitmap.Canvas.FrameRect(Self.ClientRect);

    var layout := GetColorGridLayout();

    var r := layout.content;
    r.Width := layout.cellSize.x;
    r.Height := layout.cellSize.y;
    for var i := 0 to 9 do
    begin
      bitmap.Canvas.Brush.Color := WebColorStrToColor(PresetBiomeColors[i]);
      bitmap.canvas.FillRect(r);
      r.Offset(layout.cellSize.x + layout.margins.X, 0);
      if i = 4 then
        r.SetLocation(layout.content.Left, layout.content.Top + (layout.cellSize.y + layout.margins.Y));
    end;

    // xfer to display surface
    r := Self.Canvas.ClipRect;
    Self.Canvas.CopyRect(r, bitmap.Canvas, r);

  finally
    bitmap.Free;
  end;

end;

procedure TPaintboxHelper.RenderToolButton(const aCaption: string; aColor: TColor; isActive: Boolean);
const
  color_size = 20;
begin
  var bitmap := TBitmap.Create;
  try
    bitmap.Width := Self.ClientWidth;
    bitmap.Height := self.ClientHeight;

    // background
    bitmap.canvas.Brush.Style := bsSolid;
    var c := StyleServices.GetSystemColor(clBtnFace);
    if isActive then
      c := Vcl.GraphUtil.GetHighLightColor(c, 25);
    bitmap.canvas.Brush.Color := c;
    bitmap.canvas.FillRect(Self.ClientRect);

    c := StyleServices.GetSystemColor(clWindowFrame);
    if isActive then
      c := StyleServices.GetSystemColor(clHighlight);

    bitmap.canvas.Brush.Color := c;
    bitmap.Canvas.FrameRect(Self.ClientRect);

    var r := Self.ClientRect;
    Dec(r.Right, 4);
    r.left := r.Right - color_size;

    var p := r.CenterPoint;
    r.top := p.y - (color_size div 2);
    r.Bottom := r.Top + color_size;
    bitmap.Canvas.Brush.Color := aColor;
    bitmap.Canvas.FillRect(r);

    r.right := r.left - 4;
    r.left := 4;
    r.Top := 0;
    r.Bottom := self.ClientHeight;
    bitmap.Canvas.Font := Self.Font;
    if isActive then
      c := StyleServices.GetStyleFontColor(sfButtonTextPressed)
    else
      c := StyleServices.GetStyleFontColor(sfButtonTextDisabled);

    bitmap.Canvas.Font.Color := c;
    var s := aCaption;
    bitmap.Canvas.Brush.Style := bsClear;
    bitmap.Canvas.TextRect(r, s, [tfVerticalCenter, tfSingleLine]);

    // xfer to display surface
    r := Self.Canvas.ClipRect;
    Self.Canvas.CopyRect(r, bitmap.Canvas, r);

  finally
    bitmap.Free;
  end;
end;


end.
