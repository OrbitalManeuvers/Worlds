unit u_GridEditor;

interface

uses WinApi.Windows, WinApi.Messages, System.Classes, Vcl.Controls, System.SysUtils,
  System.Types, Vcl.Graphics,
  u_Worlds.Types, u_Environment.Types;

type
  TCellRect = type TRect;
  TCellPoint = type TPoint;

  TGridEditor = class(TCustomControl)
  private
    fCellSize: TSize;
    fDrawBuffer: TBitmap;
    fGrid: PBiomeGrid;
    fPalette: TBiomeColorPalette;
    fDrawMarker: TBiomeMarker;
    fIsDrawing: Boolean;
    fHasLastCell: Boolean;
    fLastCell: TCellPoint;
    fLastMousePoint: TPoint;
    procedure SetCellSize(const Value: TSize);
    procedure SetGrid(const Value: PBiomeGrid);
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
    property Grid: PBiomeGrid read fGrid write SetGrid;
    property DrawMarker: TBiomeMarker read fDrawMarker write fDrawMarker;
  end;


implementation

uses Vcl.Forms, Vcl.Themes,
  u_EnvironmentLibraries;


{ TGridEditor }

constructor TGridEditor.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csClickEvents];
  Color := clWindow;
  fDrawBuffer := TBitmap.Create;
  CellSize := TSize.Create(20, 20);

  fDrawMarker := 1;
end;

destructor TGridEditor.Destroy;
begin
  fDrawBuffer.Free;
  inherited;
end;

function TGridEditor.CellRectToPixelRect(const ACellRect: TCellRect): TRect;
begin
  Result.Left := ACellRect.Left * fCellSize.cx;
  Result.Top := ACellRect.Top * fCellSize.cy;
  Result.Right := ACellRect.Right * fCellSize.cx;
  Result.Bottom := ACellRect.Bottom * fCellSize.cy;
end;

function TGridEditor.PixelPointToCellPoint(const APixelPoint: TPoint): TCellPoint;
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

function TGridEditor.BiasCellForDrag(const AProposedCell: TCellPoint;
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

function TGridEditor.ClipRectToCellRect(const APixelRect: TRect): TCellRect;
begin
  Result.Left := APixelRect.Left div fCellSize.cx;
  Result.Top := APixelRect.Top div fCellSize.cy;
  Result.Right := (APixelRect.Right + fCellSize.cx - 1) div fCellSize.cx;
  Result.Bottom := (APixelRect.Bottom + fCellSize.cy - 1) div fCellSize.cy;
end;

procedure TGridEditor.InvalidateCell(const aCell: TCellPoint);
begin
  var cellRect: TCellRect;
  cellRect.SetLocation(aCell.X, aCell.Y);
  cellRect.Right := cellRect.Left + 1;
  cellRect.Bottom := cellRect.Top + 1;

  var pxRect := CellRectToPixelRect(cellRect);
  InvalidateRect(Self.Handle, @pxRect, False);
end;

procedure TGridEditor.PaintCell(const Cell: TCellPoint; Value: TBiomeMarker);
begin
  if not fHasLastCell or (Cell.X <> fLastCell.X) or (Cell.Y <> fLastCell.Y) then
  begin
    fLastCell := Cell;
    fHasLastCell := True;
  end;

  if fGrid[cell.X, cell.Y] = Value then
    Exit;

  fGrid[cell.X, cell.Y] := Value;
  InvalidateCell(cell);
end;

procedure TGridEditor.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button <> mbLeft) or (fGrid = nil) then
    Exit;

  fLastMousePoint := Point(X, Y);

  var cellPoint := PixelPointToCellPoint(Point(X, Y));
  PaintCell(cellPoint, fDrawMarker);
  fIsDrawing := True;
end;

procedure TGridEditor.MouseMove(Shift: TShiftState; X, Y: Integer);
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

procedure TGridEditor.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  fIsDrawing := False;
  fHasLastCell := False;
end;

procedure TGridEditor.CreateParams(var Params: TCreateParams);
const
  BorderStyles: array[TBorderStyle] of DWORD = (0, WS_BORDER);
begin
  inherited CreateParams(Params);
  with Params do
  begin
    WindowClass.style := WindowClass.style and not (CS_HREDRAW or CS_VREDRAW);
  end;
end;

procedure TGridEditor.Paint;
begin
  if fGrid = nil then
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
      var currentMarker: TBiomeMarker := fGrid[rleStart, row];
      var rleEnd := rleStart + 1;

      // move the right end of the run until it's another value
      while rleEnd < cellClipRect.Right do
      begin
        if fGrid[rleEnd, row] = currentMarker then
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

procedure TGridEditor.SetGrid(const Value: PBiomeGrid);
begin
  fGrid := Value;
  UpdatePalette;
end;

procedure TGridEditor.UpdatePalette;
begin
  WorldLibrary.UpdateBiomeColorPalette(fPalette);
  Invalidate;
end;

procedure TGridEditor.SetCellSize(const Value: TSize);
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

procedure TGridEditor.WMCaptureChanged(var Msg: TWMNoParams);
begin
  fIsDrawing := False;
  fHasLastCell := False;
end;

procedure TGridEditor.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  Msg.Result := 1;
end;

end.
