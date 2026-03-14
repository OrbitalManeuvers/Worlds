unit u_CellVisualizers;

interface

uses System.SysUtils, System.Types, Vcl.ExtCtrls, Vcl.Graphics,

  u_SimEnvironments;

type
  TCellDisplayMode = (dmNone, dmSolarFlux, dmContents, dmResources);
  TCellVisualizer = class
  private
    fDisplay: TPaintbox;
    fBitmap: TBitmap;
    fEnvironment: TSimEnvironment;
    fTarget: TPoint;
    fCellIndex: Cardinal;
    fMode: TCellDisplayMode;
    procedure DisplayPaint(Sender: TObject);
    procedure SetTarget(const Value: TPoint);
    procedure SetMode(const Value: TCellDisplayMode);
    procedure RenderFlux(const contentRect: TRect; canvas: TCanvas);
    procedure RenderResources(const contentRect: TRect; canvas: TCanvas);
  public
    constructor Create(aDisplay: TPaintbox; aEnvironment: TSimEnvironment);
    destructor Destroy; override;

    property Mode: TCellDisplayMode read fMode write SetMode;
    property Target: TPoint read fTarget write SetTarget;
    property Display: TPaintBox read fDisplay;
  end;

implementation

uses Vcl.GraphUtil, Vcl.Themes, System.Math;


function UnitToLumaN(const V: Single): Integer;
begin
  // Absolute luminance in HLS space: 0 = black, 240 = white.
  Result := Round(EnsureRange(V, 0.0, 1.0) * 240.0);
end;

function ColorSetUnitLuma(const Base: TColor; const V: Single): TColor;
var
  H, L, S: Word;
begin
  ColorRGBToHLS(ColorToRGB(Base), H, L, S);
  Result := ColorHLSToRGB(H, UnitToLumaN(V), S);
end;

{ TCellVisualizer }

constructor TCellVisualizer.Create(aDisplay: TPaintbox; aEnvironment: TSimEnvironment);
begin
  inherited Create;
  fDisplay := aDisplay;

  fDisplay.OnPaint := DisplayPaint;
  fEnvironment := aEnvironment;

  // off-screen bitmap
  fBitmap := TBitmap.Create;
  fBitmap.Width := Display.Width;
  fBitmap.Height := Display.Height;
end;

destructor TCellVisualizer.Destroy;
begin
  fBitmap.Free;
  inherited;
end;

procedure TCellVisualizer.DisplayPaint(Sender: TObject);
begin
  // background
  var r := Display.ClientRect;
  fBitmap.Canvas.Font := Display.Canvas.Font;

  case Mode of
    dmSolarFlux: RenderFlux(r, fBitmap.Canvas);
    dmResources: RenderResources(r, fBitmap.Canvas);
  else
    begin
      fBitmap.canvas.Brush.Color := StyleServices.GetSystemColor(clBtnFace);
      fBitmap.canvas.Brush.Style := bsSolid;
      fBitmap.canvas.FillRect(r);
    end;
  end;

  // xfer to display surface
  r := Display.Canvas.ClipRect;
  Display.Canvas.CopyRect(r, fBitmap.Canvas, r);
end;

procedure TCellVisualizer.RenderFlux(const contentRect: TRect; canvas: TCanvas);
begin
  var flux := fEnvironment.SolarFlux;
  var color := ColorSetUnitLuma(clSkyBlue, flux);

  canvas.Brush.Style := bsSolid;
  canvas.Brush.Color := color;
  canvas.Pen.Color := StyleServices.GetSystemColor(clWhite);
  canvas.Pen.Style := psSolid;
  canvas.Pen.Width := 1;
  canvas.Rectangle(contentRect);

end;

procedure TCellVisualizer.RenderResources(const contentRect: TRect; canvas: TCanvas);
begin
  var resCount := fEnvironment.Cells[fCellIndex].ResourceCount;
  if resCount > 0 then
  begin
    var resStart := fEnvironment.Cells[fCellIndex].ResourceStart;
    canvas.Font.Color := StyleServices.GetStyleFontColor(sfButtonTextNormal);
    var lineHeight := canvas.TextHeight('j');

    var r := contentRect;
    r.Bottom := r.Top + lineHeight;

    for var i := 0 to resCount - 1 do
    begin
      var caption := Format('SI: %d A: %f', [i, fEnvironment.Resources[resStart + i].Amount]);
      canvas.TextRect(r, caption, [tfSingleLine]);
      r.Offset(0, lineHeight);


    end;



//    var r := contentRect;
  end;

end;

procedure TCellVisualizer.SetTarget(const Value: TPoint);
begin
  fTarget := Value;
  fCellIndex := (fTarget.Y * fEnvironment.Dimensions.cx) + fTarget.X;
end;

procedure TCellVisualizer.SetMode(const Value: TCellDisplayMode);
begin
  fMode := Value;
  Display.Invalidate;
end;

end.
