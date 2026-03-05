unit fr_RegionEditor;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ControlList, Vcl.ComCtrls, Vcl.Buttons,
  PngSpeedButton,

  fr_ContentFrames,
  u_MapEditors, u_Regions;

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
    shDrawing: TShape;
    shErasing: TShape;
    procedure RegionListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure RegionListItemClick(Sender: TObject);
    procedure btnNewRegionClick(Sender: TObject);
    procedure edtDescriptionChange(Sender: TObject);
    procedure edtNameChange(Sender: TObject);
    procedure BiomeListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure BiomeListItemClick(Sender: TObject);
  private
    UntitledCount: Integer;
    Region: TRegion;
    MapEditor: TMapEditor;
    procedure EditRegion(aRegion: TRegion);
    procedure ItemChanged;
  public
    procedure Init; override;
    procedure ActivateContent; override;
  end;

implementation

{$R *.dfm}

uses u_EnvironmentLibraries;

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

procedure TRegionEditor.ActivateContent;
begin
  inherited;
  BiomeList.ItemCount := WorldLibrary.BiomeCount;
  MapEditor.UpdatePalette;

  if (RegionList.ItemCount > 0) and (RegionList.ItemIndex = -1) then
  begin
    RegionList.ItemIndex := 0;
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

  shDrawing.Brush.Color := WorldLibrary.Biomes[biomeIndex].Color;
  MapEditor.DrawMarker := WorldLibrary.Biomes[biomeIndex].Marker;
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

end.
