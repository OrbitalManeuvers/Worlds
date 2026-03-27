unit u_SimVisualizer;

interface

uses Winapi.Windows, System.Classes, System.SysUtils, System.Types, Vcl.Graphics,

  u_Simulators, u_SimEnvironments;

type
  TVisualizerZoom = (vz1, vz2, vz4, vz8, vz16, vz32);

const
  VisualizerSize = 256;

type
  TVisualizerGrid = array[0..VisualizerSize - 1, 0..VisualizerSize - 1] of Byte;
  TSubstanceDisplayMode = (sdmFill, sdmAmount, sdmCapacity);

  TSimVisualizer = class
  private
    fSimulator: TSimulator;
    fBitmap: TBitmap;
    fZoomLevel: TVisualizerZoom;
    fAnchorCell: TPoint;
    fOnZoomChanged: TNotifyEvent;
    fOnAnchorChanged: TNotifyEvent;
    procedure SetSimulator(const Value: TSimulator);
    procedure SetZoomLevel(const Value: TVisualizerZoom);
    procedure SetAnchorCell(const Value: TPoint);
    function GetZoomPixelsPerCell: Integer;
    function GetVisibleCellSize: TSize;
    procedure DoZoomChanged;
    procedure DoAnchorChanged;
  protected
    fCells: TVisualizerGrid;
    procedure DataRequired(DataRect: TRect); virtual;
    procedure BeforeDataRequired(DataRect: TRect); virtual;
    procedure ClampAnchorCell; virtual;
    function GetEnvironmentDimensions: TSize; virtual;
    function SampleCellLuma(const CellX, CellY: Integer): Byte; virtual;

  public
    constructor Create;
    destructor Destroy; override;

    procedure Paint(ACanvas: TCanvas; ABaseColor: TColor); overload;
    procedure Paint(ACanvas: TCanvas; ABaseColor: TColor; const ATargetRect: TRect); overload;

    procedure ResetView;
    procedure PanByCells(const Delta: TPoint);
    procedure ZoomIn;
    procedure ZoomOut;

    property Simulator: TSimulator read fSimulator write SetSimulator;
    property Cells: TVisualizerGrid read fCells;
    property ZoomLevel: TVisualizerZoom read fZoomLevel write SetZoomLevel;
    property AnchorCell: TPoint read fAnchorCell write SetAnchorCell;
    property ZoomPixelsPerCell: Integer read GetZoomPixelsPerCell;
    property VisibleCellSize: TSize read GetVisibleCellSize;
    property OnZoomChanged: TNotifyEvent read fOnZoomChanged write fOnZoomChanged;
    property OnAnchorChanged: TNotifyEvent read fOnAnchorChanged write fOnAnchorChanged;
  end;

  TSubstanceVisualizer = class(TSimVisualizer)
  private
    fSubstanceIndex: Integer;
    fDisplayMode: TSubstanceDisplayMode;
    fFrameMaxMetric: Single;
    procedure SetSubstanceIndex(const Value: Integer);
    procedure SetDisplayMode(const Value: TSubstanceDisplayMode);
  protected
    procedure BeforeDataRequired(DataRect: TRect); override;
    function SampleCellLuma(const CellX, CellY: Integer): Byte; override;
  public
    constructor Create;
    property SubstanceIndex: Integer read fSubstanceIndex write SetSubstanceIndex;
    property DisplayMode: TSubstanceDisplayMode read fDisplayMode write SetDisplayMode;
  end;


implementation

uses Vcl.Themes, System.Math;

const
  SubcellsPerCell = 32;


function ModulateColor(const BaseColor: TColor; const Luma: Byte): TColor;
begin
  var temp := ColorToRGB(BaseColor);
  Result := RGB(
    (GetRValue(temp) * Luma) div 255,
    (GetGValue(temp) * Luma) div 255,
    (GetBValue(temp) * Luma) div 255
  );
end;

function ZoomPixelsPerCellFromLevel(const Zoom: TVisualizerZoom): Integer;
const
  ZoomValues: array[TVisualizerZoom] of Integer = (1, 2, 4, 8, 16, 32);
begin
  Result := ZoomValues[Zoom];
end;


{ TSimVisualizer }

constructor TSimVisualizer.Create;
begin
  inherited Create;
  fBitmap := TBitmap.Create;
  fBitmap.PixelFormat := pf24bit;
  fBitmap.SetSize(Length(fCells), Length(fCells[0]));
  fZoomLevel := vz1;
  fAnchorCell := Point(0, 0);
end;

procedure TSimVisualizer.BeforeDataRequired(DataRect: TRect);
begin
  // default: no prepass needed
end;

procedure TSimVisualizer.ClampAnchorCell;
begin
  var envSize := GetEnvironmentDimensions;
  var visible := VisibleCellSize;

  var maxX := Max(0, envSize.cx - visible.cx);
  var maxY := Max(0, envSize.cy - visible.cy);

  fAnchorCell.X := EnsureRange(fAnchorCell.X, 0, maxX);
  fAnchorCell.Y := EnsureRange(fAnchorCell.Y, 0, maxY);
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

  if not Assigned(Simulator) then
  begin
    for var y := paintRect.Top to paintRect.Bottom - 1 do
      for var x := paintRect.Left to paintRect.Right - 1 do
        fCells[x, y] := 0;
    Exit;
  end;

  BeforeDataRequired(paintRect);

  var zoomPixelsPerCell := ZoomPixelsPerCell;
  var originSubX := fAnchorCell.X * SubcellsPerCell;
  var originSubY := fAnchorCell.Y * SubcellsPerCell;

  for var y := paintRect.Top to paintRect.Bottom - 1 do
  begin
    for var x := paintRect.Left to paintRect.Right - 1 do
    begin
      var worldSubX := originSubX + ((x * SubcellsPerCell) div zoomPixelsPerCell);
      var worldSubY := originSubY + ((y * SubcellsPerCell) div zoomPixelsPerCell);
      var worldX := worldSubX div SubcellsPerCell;
      var worldY := worldSubY div SubcellsPerCell;
      fCells[x, y] := SampleCellLuma(worldX, worldY);
    end;
  end;
end;

destructor TSimVisualizer.Destroy;
begin
  fBitmap.Free;
  inherited;
end;

procedure TSimVisualizer.Paint(ACanvas: TCanvas; ABaseColor: TColor);
begin
  Paint(ACanvas, ABaseColor, Rect(0, 0, VisualizerSize, VisualizerSize));
end;

procedure TSimVisualizer.Paint(ACanvas: TCanvas; ABaseColor: TColor; const ATargetRect: TRect);
var
  fullRect: TRect;
begin
  if not Assigned(ACanvas) then
    Exit;

  if (fBitmap.Width <> Length(fCells)) or (fBitmap.Height <> Length(fCells[0])) then
    fBitmap.SetSize(Length(fCells), Length(fCells[0]));

  fullRect := Rect(0, 0, fBitmap.Width, fBitmap.Height);
  DataRequired(fullRect);

  for var y := fullRect.Top to fullRect.Bottom - 1 do
  begin
    for var x := fullRect.Left to fullRect.Right - 1 do
      fBitmap.Canvas.Pixels[x, y] := ModulateColor(ABaseColor, fCells[x, y]);
  end;

  // Stretch to destination so caller can render anywhere/any size.
  ACanvas.StretchDraw(ATargetRect, fBitmap);
end;

procedure TSimVisualizer.DoZoomChanged;
begin
  if Assigned(fOnZoomChanged) then
    fOnZoomChanged(Self);
end;

procedure TSimVisualizer.DoAnchorChanged;
begin
  if Assigned(fOnAnchorChanged) then
    fOnAnchorChanged(Self);
end;

function TSimVisualizer.GetEnvironmentDimensions: TSize;
begin
  Result := TSize.Create(0, 0);

  if not Assigned(Simulator) then
    Exit;

  Result := Simulator.Runtime.Environment.Dimensions;
end;

function TSimVisualizer.GetVisibleCellSize: TSize;
begin
  var visibleSubX := (VisualizerSize * SubcellsPerCell) div ZoomPixelsPerCell;
  var visibleSubY := (VisualizerSize * SubcellsPerCell) div ZoomPixelsPerCell;
  Result.cx := Max(1, (visibleSubX + SubcellsPerCell - 1) div SubcellsPerCell);
  Result.cy := Max(1, (visibleSubY + SubcellsPerCell - 1) div SubcellsPerCell);
end;

function TSimVisualizer.GetZoomPixelsPerCell: Integer;
begin
  Result := ZoomPixelsPerCellFromLevel(fZoomLevel);
end;

procedure TSimVisualizer.PanByCells(const Delta: TPoint);
begin
  SetAnchorCell(Point(fAnchorCell.X + Delta.X, fAnchorCell.Y + Delta.Y));
end;

procedure TSimVisualizer.ResetView;
var
  oldZoom: TVisualizerZoom;
  oldAnchor: TPoint;
begin
  oldZoom := fZoomLevel;
  oldAnchor := fAnchorCell;
  fZoomLevel := vz1;
  fAnchorCell := Point(0, 0);
  ClampAnchorCell;

  if (oldAnchor.X <> fAnchorCell.X) or (oldAnchor.Y <> fAnchorCell.Y) then
    DoAnchorChanged;

  if oldZoom <> fZoomLevel then
    DoZoomChanged;
end;

function TSimVisualizer.SampleCellLuma(const CellX, CellY: Integer): Byte;
begin
  // Fallback checker pattern so base visualizer still paints without a descendant source.
  var checker := ((CellX div 8) xor (CellY div 8)) and 1;
  if checker = 1 then
    Result := 200
  else
    Result := 80;
end;

procedure TSimVisualizer.SetSimulator(const Value: TSimulator);
begin
  fSimulator := Value;
  SetAnchorCell(fAnchorCell);
end;

procedure TSimVisualizer.SetZoomLevel(const Value: TVisualizerZoom);
begin
  if fZoomLevel = Value then
    Exit;

  var oldAnchor := fAnchorCell;
  fZoomLevel := Value;
  ClampAnchorCell;

  if (oldAnchor.X <> fAnchorCell.X) or (oldAnchor.Y <> fAnchorCell.Y) then
    DoAnchorChanged;

  DoZoomChanged;
end;

procedure TSimVisualizer.SetAnchorCell(const Value: TPoint);
begin
  var oldAnchor := fAnchorCell;
  fAnchorCell := Value;
  ClampAnchorCell;

  if (oldAnchor.X = fAnchorCell.X) and (oldAnchor.Y = fAnchorCell.Y) then
    Exit;

  DoAnchorChanged;
end;

procedure TSimVisualizer.ZoomIn;
begin
  if fZoomLevel < High(TVisualizerZoom) then
    ZoomLevel := Succ(fZoomLevel);
end;

procedure TSimVisualizer.ZoomOut;
begin
  if fZoomLevel > Low(TVisualizerZoom) then
    ZoomLevel := Pred(fZoomLevel);
end;


{ TSubstanceVisualizer }

constructor TSubstanceVisualizer.Create;
begin
  inherited;
  fDisplayMode := sdmFill;
  fFrameMaxMetric := 0;
end;

procedure TSubstanceVisualizer.BeforeDataRequired(DataRect: TRect);
begin
  inherited;
  fFrameMaxMetric := 0;

  if fDisplayMode = sdmFill then
    Exit;

  if not Assigned(Simulator) then
    Exit;

  var env := Simulator.Runtime.Environment;
  var envWidth := env.Dimensions.cx;
  var envHeight := env.Dimensions.cy;
  var cellCount := Length(env.Cells);
  if (fSubstanceIndex < 0) or (fSubstanceIndex >= Length(env.Substances)) or (cellCount = 0) then
    Exit;

  for var y := 0 to envHeight - 1 do
  begin
    for var x := 0 to envWidth - 1 do
    begin
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
              metric := env.ResourceCacheMaxAmount;
          end;

          if metric > fFrameMaxMetric then
            fFrameMaxMetric := metric;
          Break;
        end;
      end;
    end;
  end;
end;

function TSubstanceVisualizer.SampleCellLuma(const CellX, CellY: Integer): Byte;
begin
  Result := 0;

  if not Assigned(Simulator) then
    Exit;

  var env := Simulator.Runtime.Environment;
  if (fSubstanceIndex < 0) or (fSubstanceIndex >= Length(env.Substances)) then
    Exit;

  var envWidth := env.Dimensions.cx;
  var envHeight := env.Dimensions.cy;
  var cellCount := Length(env.Cells);

  if not ((CellX >= 0) and (CellY >= 0) and (CellX < envWidth) and (CellY < envHeight) and (cellCount > 0)) then
    Exit;

  var cellIndex := (CellY * envWidth) + CellX;
  if (cellIndex < 0) or (cellIndex >= cellCount) then
    Exit;

  var start := env.Cells[cellIndex].ResourceStart;
  var count := env.Cells[cellIndex].ResourceCount;

  for var i := 0 to count - 1 do
  begin
    var resIndex := start + i;
    if (resIndex >= 0) and (resIndex < Length(env.Resources)) and
       (env.Resources[resIndex].SubstanceIndex = fSubstanceIndex) then
    begin
      var capacity := env.ResourceCacheMaxAmount;
      var amount := env.Resources[resIndex].Amount;
      var lumaUnit := 0.0;

      case fDisplayMode of
        sdmFill:
        begin
          if capacity > 0 then
            lumaUnit := EnsureRange(amount / capacity, 0.0, 1.0);
        end;
        sdmAmount:
        begin
          if fFrameMaxMetric > 0 then
            lumaUnit := EnsureRange(amount / fFrameMaxMetric, 0.0, 1.0);
        end;
        sdmCapacity:
        begin
          if fFrameMaxMetric > 0 then
            lumaUnit := EnsureRange(capacity / fFrameMaxMetric, 0.0, 1.0);
        end;
      end;

      Result := Round(lumaUnit * 255.0);
      Break;
    end;
  end;
end;

procedure TSubstanceVisualizer.SetSubstanceIndex(const Value: Integer);
begin
  fSubstanceIndex := Value;
end;

procedure TSubstanceVisualizer.SetDisplayMode(const Value: TSubstanceDisplayMode);
begin
  fDisplayMode := Value;
end;

end.
