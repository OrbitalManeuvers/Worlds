unit u_SimVisualizer;

interface

uses Winapi.Windows, System.Classes, System.SysUtils, System.Types, Vcl.ExtCtrls, Vcl.Graphics,

  u_Simulators, u_SimEnvironments;


type
  TVisualizerGrid = array[0..255, 0..255] of Byte;
  TSubstanceDisplayMode = (sdmFill, sdmAmount, sdmCapacity);

  TSimVisualizer = class
  private type
    TInvalidation = (ivDisplay, ivData);
    TInvalidations = set of TInvalidation;
  private
    fPaintBox: TPaintBox;
    fSimulator: TSimulator;
    fColor: TColor;
    fBitmap: TBitmap;
    procedure SetPaintBox(const Value: TPaintBox);
    procedure SetSimulator(const Value: TSimulator);
    procedure SetColor(const Value: TColor);
  protected
    fCells: TVisualizerGrid;
    procedure HandlePaint(Sender: TObject);
    procedure Invalidate(Invalidations: TInvalidations = []);
    procedure DataRequired(DataRect: TRect); virtual;

  public
    constructor Create;
    destructor Destroy; override;

    property PaintBox: TPaintBox read fPaintBox write SetPaintBox;
    property Simulator: TSimulator read fSimulator write SetSimulator;
    property Cells: TVisualizerGrid read fCells;
    property Color: TColor read fColor write SetColor;
  end;

  TSubstanceVisualizer = class(TSimVisualizer)
  private
    fSubstanceIndex: Integer;
    fDisplayMode: TSubstanceDisplayMode;
    procedure SetSubstanceIndex(const Value: Integer);
    procedure SetDisplayMode(const Value: TSubstanceDisplayMode);
  protected
    procedure DataRequired(DataRect: TRect); override;
  public
    constructor Create;
    property SubstanceIndex: Integer read fSubstanceIndex write SetSubstanceIndex;
    property DisplayMode: TSubstanceDisplayMode read fDisplayMode write SetDisplayMode;
  end;


implementation

uses Vcl.Themes, System.Math;


function ModulateColor(const BaseColor: TColor; const Luma: Byte): TColor;
begin
  var temp := ColorToRGB(BaseColor);
  Result := RGB(
    (GetRValue(temp) * Luma) div 255,
    (GetGValue(temp) * Luma) div 255,
    (GetBValue(temp) * Luma) div 255
  );
end;


{ TSimVisualizer }

constructor TSimVisualizer.Create;
begin
  inherited Create;
  fBitmap := TBitmap.Create;
  fBitmap.PixelFormat := pf24bit;
  fBitmap.SetSize(Length(fCells), Length(fCells[0]));
  fColor := clLime;
end;

procedure TSimVisualizer.DataRequired(DataRect: TRect);
begin
  var paintRect := Rect(
    EnsureRange(DataRect.Left, 0, High(fCells)),
    EnsureRange(DataRect.Top, 0, High(fCells[0])),
    EnsureRange(DataRect.Right, 0, High(fCells) + 1),
    EnsureRange(DataRect.Bottom, 0, High(fCells[0]) + 1)
  );

  if IsRectEmpty(paintRect) then
    Exit;

  const CenterX = (High(fCells) + 1) div 2;
  const CenterY = (High(fCells[0]) + 1) div 2;
  const MaxDist = 181.0;

  for var y := paintRect.Top to paintRect.Bottom - 1 do
  begin
    for var x := paintRect.Left to paintRect.Right - 1 do
    begin
      var dx := x - CenterX;
      var dy := y - CenterY;
      var dist := Sqrt(dx * dx + dy * dy);

      var radial := Round(180.0 * (1.0 - EnsureRange(dist / MaxDist, 0.0, 1.0)));
      var rings := (Round(dist) div 12) mod 2;
      var checker := ((x div 16) xor (y div 16)) and 1;
      var stripes := (x + y) mod 32;

      var value := 24 + radial + stripes;
      if rings = 1 then
        Inc(value, 28);
      if checker = 1 then
        Dec(value, 18);

      fCells[x, y] := EnsureRange(value, 0, 255);

    end;
  end;

end;

destructor TSimVisualizer.Destroy;
begin
  fBitmap.Free;
  inherited;
end;

procedure TSimVisualizer.HandlePaint(Sender: TObject);
begin
  if not Assigned(fPaintBox) then
    Exit;

  if (fBitmap.Width <> Length(fCells)) or (fBitmap.Height <> Length(fCells[0])) then
    fBitmap.SetSize(Length(fCells), Length(fCells[0]));

  var clipRect := fPaintBox.Canvas.ClipRect;
  var dataRect: TRect;
  if not IntersectRect(dataRect, clipRect, Rect(0, 0, fBitmap.Width, fBitmap.Height)) then
    Exit;

  fBitmap.Canvas.Font := fPaintBox.Canvas.Font;

  if (fBitmap.Width > 0) and (fBitmap.Height > 0) then
  begin
    DataRequired(dataRect);

    for var y := dataRect.Top to dataRect.Bottom - 1 do
    begin
      for var x := dataRect.Left to dataRect.Right - 1 do
        fBitmap.Canvas.Pixels[x, y] := ModulateColor(fColor, fCells[x, y]);
    end;
  end;

  // transfer to display
  fPaintBox.Canvas.CopyRect(dataRect, fBitmap.Canvas, dataRect);
end;

procedure TSimVisualizer.Invalidate(Invalidations: TInvalidations);
begin
  if ivData in Invalidations then
  begin
    //
  end;

  if ivDisplay in Invalidations then
  begin
    if Assigned(fPaintBox) then
      fPaintBox.Invalidate;
  end;
end;

procedure TSimVisualizer.SetColor(const Value: TColor);
begin
  fColor := Value;
  Invalidate([ivDisplay]);
end;

procedure TSimVisualizer.SetPaintBox(const Value: TPaintBox);
begin
  if fPaintBox = Value then
    Exit;

  if Assigned(fPaintBox) then
    fPaintBox.OnPaint := nil;

  fPaintBox := Value;

  if Assigned(fPaintBox) then
  begin
    fPaintBox.OnPaint := HandlePaint;
  end;

  Invalidate([ivDisplay]);
end;

procedure TSimVisualizer.SetSimulator(const Value: TSimulator);
begin
  fSimulator := Value;

  Invalidate([ivDisplay]);
end;


{ TSubstanceVisualizer }

constructor TSubstanceVisualizer.Create;
begin
  inherited;
  fDisplayMode := sdmFill;
end;

procedure TSubstanceVisualizer.DataRequired(DataRect: TRect);
begin
  var paintRect := Rect(
    EnsureRange(DataRect.Left, 0, High(fCells)),
    EnsureRange(DataRect.Top, 0, High(fCells[0])),
    EnsureRange(DataRect.Right, 0, High(fCells) + 1),
    EnsureRange(DataRect.Bottom, 0, High(fCells[0]) + 1)
  );

  if IsRectEmpty(paintRect) then
    Exit;

  if not Assigned(Simulator) then
  begin
    for var y := paintRect.Top to paintRect.Bottom - 1 do
      for var x := paintRect.Left to paintRect.Right - 1 do
        fCells[x, y] := 0;
    Exit;
  end;

  var env := Simulator.Runtime.Environment;
  if (fSubstanceIndex < 0) or (fSubstanceIndex >= Length(env.Substances)) then
  begin
    for var y := paintRect.Top to paintRect.Bottom - 1 do
      for var x := paintRect.Left to paintRect.Right - 1 do
        fCells[x, y] := 0;
    Exit;
  end;

  var envWidth := env.Dimensions.cx;
  var envHeight := env.Dimensions.cy;
  var cellCount := Length(env.Cells);
  var maxMetric := 0.0;

  if fDisplayMode <> sdmFill then
  begin
    for var y := paintRect.Top to paintRect.Bottom - 1 do
    begin
      for var x := paintRect.Left to paintRect.Right - 1 do
      begin
        if not ((x < envWidth) and (y < envHeight) and (cellCount > 0)) then
          Continue;

        var cellIndex := (y * envWidth) + x;
        if (cellIndex < 0) or (cellIndex >= cellCount) then
          Continue;

        var start := env.Cells[cellIndex].ResourceStart;
        var count := env.Cells[cellIndex].ResourceCount;

        for var i := 0 to count - 1 do
        begin
          var resIndex := start + i;
          if (resIndex >= 0) and (resIndex < Length(env.Resources)) and
             (env.Resources[resIndex].SubstanceIndex = fSubstanceIndex) then
          begin
            var metric := 0.0;
            case fDisplayMode of
              sdmAmount:
                metric := env.Resources[resIndex].Amount;
              sdmCapacity:
                metric := env.Resources[resIndex].Capacity;
            end;

            if metric > maxMetric then
              maxMetric := metric;
            Break;
          end;
        end;
      end;
    end;
  end;

  for var y := paintRect.Top to paintRect.Bottom - 1 do
  begin
    for var x := paintRect.Left to paintRect.Right - 1 do
    begin
      var value: Byte := 0;

      if (x < envWidth) and (y < envHeight) and (cellCount > 0) then
      begin
        var cellIndex := (y * envWidth) + x;
        if (cellIndex >= 0) and (cellIndex < cellCount) then
        begin
          var start := env.Cells[cellIndex].ResourceStart;
          var count := env.Cells[cellIndex].ResourceCount;

          for var i := 0 to count - 1 do
          begin
            var resIndex := start + i;
            if (resIndex >= 0) and (resIndex < Length(env.Resources)) and
               (env.Resources[resIndex].SubstanceIndex = fSubstanceIndex) then
            begin
              var capacity := env.Resources[resIndex].Capacity;
              var amount := env.Resources[resIndex].Amount;
              var lumaUnit := 0.0;
              case fDisplayMode of
                sdmFill:
                begin
                  if capacity > 0 then
                    lumaUnit := EnsureRange(amount / capacity, 0.0, 1.0)
                  else
                    lumaUnit := 0.0;
                end;
                sdmAmount:
                begin
                  if maxMetric > 0 then
                    lumaUnit := EnsureRange(amount / maxMetric, 0.0, 1.0)
                  else
                    lumaUnit := 0.0;
                end;
                sdmCapacity:
                begin
                  if maxMetric > 0 then
                    lumaUnit := EnsureRange(capacity / maxMetric, 0.0, 1.0)
                  else
                    lumaUnit := 0.0;
                end;
              end;

              value := Round(lumaUnit * 255.0);
              Break;
            end;
          end;
        end;
      end;

      fCells[x, y] := value;
    end;
  end;



end;

procedure TSubstanceVisualizer.SetSubstanceIndex(const Value: Integer);
begin
  if fSubstanceIndex = Value then
    Exit;

  fSubstanceIndex := Value;
  Invalidate([ivDisplay]);
end;

procedure TSubstanceVisualizer.SetDisplayMode(const Value: TSubstanceDisplayMode);
begin
  if fDisplayMode = Value then
    Exit;

  fDisplayMode := Value;
  Invalidate([ivDisplay]);
end;

end.
