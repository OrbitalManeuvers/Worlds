unit fr_RegionEditor;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ControlList, Vcl.ComCtrls, Vcl.Buttons,
  PngSpeedButton,

  fr_ContentFrames,
  u_MapEditors, u_Regions, u_EnvironmentTypes;

type
  TRegionEditor = class(TContentFrame)
    shPlaceholder: TShape;
    Label1: TLabel;
    RegionList: TControlList;
    btnNewRegion: TButton;
    lblRegionName: TLabel;
    PageControl: TPageControl;
    tsNoSelection: TTabSheet;
    tsSelection: TTabSheet;
    lblName: TLabel;
    edtName: TEdit;
    Label2: TLabel;
    edtDescription: TEdit;
    BiomeList: TControlList;
    lblBiomeName: TLabel;
    shBiomeMapColor: TShape;
    pbDrawButton: TPaintBox;
    pbEraseButton: TPaintBox;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    procedure RegionListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure RegionListItemClick(Sender: TObject);
    procedure btnNewRegionClick(Sender: TObject);
    procedure edtDescriptionChange(Sender: TObject);
    procedure edtNameChange(Sender: TObject);
    procedure BiomeListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure BiomeListItemClick(Sender: TObject);
    procedure pbDrawButtonPaint(Sender: TObject);
    procedure pbEraseButtonPaint(Sender: TObject);
    procedure pbDrawButtonClick(Sender: TObject);
    procedure pbEraseButtonClick(Sender: TObject);
  private type
    TToolMode = (tmDrawing, tmErasing);
  private
    UntitledCount: Integer;
    Region: TRegion;
    MapEditor: TMapEditor;
    ToolMode: TToolMode;
    DrawingMarker: TBiomeMarker;
    procedure EditRegion(aRegion: TRegion);
    procedure ItemChanged;
    procedure SetToolMode(aMode: TToolMode);
  public
    procedure Init; override;
    procedure ActivateContent; override;
  end;

implementation

{$R *.dfm}

uses u_EnvironmentLibraries, u_ControlRendering;

{ TRegionEditor }

procedure TRegionEditor.Init;
begin
  inherited;
  PageControl.ActivePage := tsNoSelection;
  var r := shPlaceholder.BoundsRect;
  shPlaceholder.Hide;
  MapEditor := TMapEditor.Create(Self);
  MapEditor.BoundsRect := r;
  MapEditor.Parent := shPlaceholder.Parent;

  RegionList.ItemCount := WorldLibrary.RegionCount;
  BiomeList.ItemCount := WorldLibrary.BiomeCount;
end;

procedure TRegionEditor.RegionListBeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  lblRegionName.Caption := WorldLibrary.Regions[AIndex].Name;
end;

procedure TRegionEditor.RegionListItemClick(Sender: TObject);
begin
  var r := WorldLibrary.Regions[RegionList.ItemIndex];
  EditRegion(r);
end;

procedure TRegionEditor.SetToolMode(aMode: TToolMode);
begin
  ToolMode := aMode;
  pbDrawButton.Invalidate;
  pbEraseButton.Invalidate;

  if ToolMode = tmDrawing then
    MapEditor.DrawMarker := DrawingMarker
  else
    MapEditor.DrawMarker := 0;
end;

procedure TRegionEditor.ActivateContent;
begin
  inherited;
  var saveIndex := BiomeList.ItemIndex;
  BiomeList.ItemCount := WorldLibrary.BiomeCount;
  if BiomeList.ItemCount > 0 then
  begin
    if (saveIndex < 0) or (saveIndex > BiomeList.ItemCount) then
     saveIndex := 0;
    BiomeList.ItemIndex := saveIndex;
    BiomeListItemClick(nil);
  end;

  MapEditor.UpdatePalette;

  if (RegionList.ItemCount > 0) and (RegionList.ItemIndex = -1) then
  begin
    RegionList.ItemIndex := 0;
    RegionListItemClick(nil);
    EditRegion(WorldLibrary.Regions[0]);
  end;
end;

procedure TRegionEditor.BiomeListBeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  lblBiomeName.Caption := WorldLibrary.Biomes[AIndex].Name;
  shBiomeMapColor.Brush.Color := WorldLibrary.Biomes[AIndex].Color;
end;

procedure TRegionEditor.BiomeListItemClick(Sender: TObject);
begin
  var biomeIndex := BiomeList.ItemIndex;
  if biomeIndex < 0 then
    Exit;

  DrawingMarker := WorldLibrary.Biomes[biomeIndex].Marker;
  pbDrawButton.Invalidate;
  if ToolMode = tmDrawing then
    MapEditor.DrawMarker := DrawingMarker;
end;

procedure TRegionEditor.btnNewRegionClick(Sender: TObject);
begin
  //
  Inc(UntitledCount);
  var r := TRegion.Create;
  r.Name := Format('Untitled-%d', [UntitledCount]);

  WorldLibrary.AddRegion(r);
  RegionList.ItemCount := WorldLibrary.RegionCount;
end;

procedure TRegionEditor.EditRegion(aRegion: TRegion);
begin
  Region := aRegion;
  edtName.Text := Region.Name;
  edtDescription.Text := Region.Description;
  PageControl.ActivePage := tsSelection;

  MapEditor.map := Region.BiomeMap;
end;

procedure TRegionEditor.edtDescriptionChange(Sender: TObject);
begin
  Region.Description := edtDescription.Text;
  ItemChanged;
end;

procedure TRegionEditor.edtNameChange(Sender: TObject);
begin
  Region.Name := edtName.Text;
  ItemChanged;
end;

procedure TRegionEditor.ItemChanged;
begin
  RegionList.UpdateItem(RegionList.ItemIndex);
end;

procedure TRegionEditor.pbDrawButtonClick(Sender: TObject);
begin
  SetToolMode(tmDrawing);
end;

procedure TRegionEditor.pbDrawButtonPaint(Sender: TObject);
begin
  var drawingColor := clBlack;
  if BiomeList.ItemIndex <> -1 then
    drawingColor := WorldLibrary.Biomes[BiomeList.ItemIndex].Color;
  pbDrawButton.RenderToolButton('Drawing', drawingColor, ToolMode = tmDrawing);
end;

procedure TRegionEditor.pbEraseButtonClick(Sender: TObject);
begin
  SetToolMode(tmErasing);
end;

procedure TRegionEditor.pbEraseButtonPaint(Sender: TObject);
begin
  pbEraseButton.RenderToolButton('Erasing', clBlack, ToolMode = tmErasing);
end;

end.
