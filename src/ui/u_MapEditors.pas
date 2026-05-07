unit u_MapEditors;

interface

uses WinApi.Windows, WinApi.Messages, System.Classes, Vcl.Controls, System.SysUtils,
  System.Types, Vcl.Graphics,
  u_EnvironmentTypes, u_EditorTypes, u_BiomeMaps;

type
  TCellRect = type TRect;
  TCellPoint = type TPoint;

  TMapEditor = class(TCustomControl)
  private
    fCellSize: TSize;
    fDrawBuffer: TBitmap;
    fMap: TBiomeMap;
    fPalette: TBiomeColorPalette;
    fDrawMarker: TBiomeMarker;
    fIsDrawing: Boolean;
    fHasLastCell: Boolean;
    fLastCell: TCellPoint;
    fLastMousePoint: TPoint;
    procedure SetCellSize(const Value: TSize);
    procedure SetMap(const Value: TBiomeMap);
    function PixelPointToCellPoint(const APixelPoint: TPoint): TCellPoint;
    function BiasCellForDrag(const AProposedCell: TCellPoint; const APixelPoint: TPoint): TCellPoint;
    function ClipRectToCellRect(const APixelRect: TRect): TCellRect;
    function CellRectToPixelRect(const ACellRect: TCellRect): TRect;
    procedure InvalidateCell(const aCell: TCellPoint);
    procedure PaintCell(const Cell: TCellPoint; Value: TBiomeMarker);
  protected
    procedure Paint; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMCaptureChanged(var Msg: TWMNoParams); message WM_CAPTURECHANGED;

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure UpdatePalette;
    property CellSize: TSize read fCellSize write SetCellSize;
    property Map: TBiomeMap read fMap write SetMap;
    property DrawMarker: TBiomeMarker read fDrawMarker write fDrawMarker;
  end;


implementation

uses Vcl.Forms, Vcl.Themes,
  u_EnvironmentLibraries;


{ TMapEditor }

constructor TMapEditor.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csClickEvents];
  Color := clWindow;
  fDrawBuffer := TBitmap.Create;
  CellSize := TSize.Create(20, 20);

  fDrawMarker := 1;
end;

destructor TMapEditor.Destroy;
begin
  fDrawBuffer.Free;
  inherited;
end;

function TMapEditor.CellRectToPixelRect(const ACellRect: TCellRect): TRect;
begin
  Result.Left := ACellRect.Left * fCellSize.cx;
  Result.Top := ACellRect.Top * fCellSize.cy;
  Result.Right := ACellRect.Right * fCellSize.cx;
  Result.Bottom := ACellRect.Bottom * fCellSize.cy;
end;

function TMapEditor.PixelPointToCellPoint(const APixelPoint: TPoint): TCellPoint;
begin
  Result.X := APixelPoint.X div fCellSize.cx;
  Result.Y := APixelPoint.Y div fCellSize.cy;

  // !!! eval
  if Result.X < Low(TGridExtent) then
    Result.X := Low(TGridExtent)
  else if Result.X > High(TGridExtent) then
    Result.X := High(TGridExtent);

  if Result.Y < Low(TGridExtent) then
    Result.Y := Low(TGridExtent)
  else if Result.Y > High(TGridExtent) then
    Result.Y := High(TGridExtent);
end;

function TMapEditor.BiasCellForDrag(const AProposedCell: TCellPoint;
  const APixelPoint: TPoint): TCellPoint;
begin
  Result := AProposedCell;

  if not fHasLastCell then
    Exit;

  if (Result.X <> fLastCell.X) and (Result.Y <> fLastCell.Y) then
  begin
    var deltaX := Abs(APixelPoint.X - fLastMousePoint.X);
    var deltaY := Abs(APixelPoint.Y - fLastMousePoint.Y);

    if deltaX >= deltaY then
      Result.Y := fLastCell.Y
    else
      Result.X := fLastCell.X;
  end;
end;

function TMapEditor.ClipRectToCellRect(const APixelRect: TRect): TCellRect;
begin
  Result.Left := APixelRect.Left div fCellSize.cx;
  Result.Top := APixelRect.Top div fCellSize.cy;
  Result.Right := (APixelRect.Right + fCellSize.cx - 1) div fCellSize.cx;
  Result.Bottom := (APixelRect.Bottom + fCellSize.cy - 1) div fCellSize.cy;
end;

procedure TMapEditor.InvalidateCell(const aCell: TCellPoint);
begin
  var cellRect: TCellRect;
  cellRect.SetLocation(aCell.X, aCell.Y);
  cellRect.Right := cellRect.Left + 1;
  cellRect.Bottom := cellRect.Top + 1;

  var pxRect := CellRectToPixelRect(cellRect);
  InvalidateRect(Self.Handle, @pxRect, False);
end;

procedure TMapEditor.PaintCell(const Cell: TCellPoint; Value: TBiomeMarker);
begin
  if not fHasLastCell or (Cell.X <> fLastCell.X) or (Cell.Y <> fLastCell.Y) then
  begin
    fLastCell := Cell;
    fHasLastCell := True;
  end;

  if fMap[cell.X, cell.Y] = Value then
    Exit;

  fMap[cell.X, cell.Y] := Value;
  InvalidateCell(cell);
end;

procedure TMapEditor.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button <> mbLeft) or (fMap = nil) then
    Exit;

  fLastMousePoint := Point(X, Y);

  var cellPoint := PixelPointToCellPoint(Point(X, Y));
  PaintCell(cellPoint, fDrawMarker);
  fIsDrawing := True;
end;

procedure TMapEditor.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  if fIsDrawing then
  begin
    var mousePoint := Point(X, Y);
    var cellPoint := PixelPointToCellPoint(mousePoint);
    cellPoint := BiasCellForDrag(cellPoint, mousePoint);
    PaintCell(cellPoint, fDrawMarker);
    fLastMousePoint := mousePoint;
  end;
end;

procedure TMapEditor.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  fIsDrawing := False;
  fHasLastCell := False;
end;

procedure TMapEditor.CreateParams(var Params: TCreateParams);
const
  BorderStyles: array[TBorderStyle] of DWORD = (0, WS_BORDER);
begin
  inherited CreateParams(Params);
  with Params do
  begin
    WindowClass.style := WindowClass.style and not (CS_HREDRAW or CS_VREDRAW);
  end;
end;

procedure TMapEditor.Paint;
begin
  if fMap = nil then
  begin
    Canvas.Brush.Color := StyleServices.GetSystemColor(clWindow);
    Canvas.Brush.Style := bsSolid;
    Canvas.FillRect(Canvas.ClipRect);
    Exit;
  end;

  var cellClipRect := ClipRectToCellRect(Canvas.ClipRect);
  if (cellClipRect.Right <= cellClipRect.Left) or
    (cellClipRect.Bottom <= cellClipRect.Top) then
    Exit;

  fDrawBuffer.Canvas.Brush.Style := bsSolid;
  fDrawBuffer.Canvas.Pen.Style := psClear;

  for var row := cellClipRect.Top to cellClipRect.Bottom - 1 do
  begin
    var rleStart := cellClipRect.Left;
    while rleStart < cellClipRect.Right do
    begin
      var currentMarker: TBiomeMarker := fMap[rleStart, row];
      var rleEnd := rleStart + 1;

      // move the right end of the run until it's another value
      while rleEnd < cellClipRect.Right do
      begin
        if fMap[rleEnd, row] = currentMarker then
          Inc(rleEnd)
        else
          Break;
      end;

      // now we have the number of cells that get painted in current color
      var cellRunRect: TCellRect;
      cellRunRect.Left := rleStart;
      cellRunRect.Top := row;
      cellRunRect.Right := rleEnd;
      cellRunRect.Bottom := row + 1;

      var drawRect := CellRectToPixelRect(cellRunRect);

      fDrawBuffer.Canvas.Brush.Color := fPalette[currentMarker];
      fDrawBuffer.Canvas.FillRect(drawRect);

      rleStart := rleEnd;
    end;
  end;

  var r := Canvas.ClipRect;
  Canvas.CopyRect(r, fDrawBuffer.Canvas, r);
end;

procedure TMapEditor.SetMap(const Value: TBiomeMap);
begin
  fMap := Value;
  UpdatePalette;
end;

procedure TMapEditor.UpdatePalette;
begin
  WorldLibrary.UpdateBiomeColorPalette(fPalette);
  Invalidate;
end;

procedure TMapEditor.SetCellSize(const Value: TSize);
begin
  fCellSize := Value;
  var imageSize: TSize := TSize.Create(fCellSize.cx * BIOME_GRID_SIZE,
    fCellSize.cy * BIOME_GRID_SIZE);
  if (fDrawBuffer.Width <> imageSize.cx) or (fDrawBuffer.Height <> imageSize.cy) then
  begin
    fDrawBuffer.Width := imageSize.cx;
    fDrawBuffer.Height := imageSize.cy;
  end;

  Invalidate;
end;

procedure TMapEditor.WMCaptureChanged(var Msg: TWMNoParams);
begin
  fIsDrawing := False;
  fHasLastCell := False;
end;

procedure TMapEditor.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  Msg.Result := 1;
end;

end.
