unit fr_BiomeEditor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.StdCtrls,
  Vcl.ComCtrls, Vcl.ControlList, Vcl.ExtCtrls, Vcl.Buttons,

  u_Worlds.Types,
  u_Environment.Types,
  u_Foods,
  u_Biomes, fr_RatingEditor;

type
  TBiomeEditor = class(TContentFrame)
    BiomeList: TControlList;
    BiomePages: TPageControl;
    tsNoSelection: TTabSheet;
    tsSelection: TTabSheet;
    Label1: TLabel;
    edtName: TEdit;
    lblBiomeName: TLabel;
    edtDescription: TEdit;
    Label2: TLabel;
    Label3: TLabel;
    pbPresets: TPaintBox;
    shMapColor: TShape;
    PropertyPages: TPageControl;
    tsEnvironment: TTabSheet;
    tsFoods: TTabSheet;
    bvSunlight: TBevel;
    bvMobility: TBevel;
    lblSunlight: TLabel;
    lblMobility: TLabel;
    lblGrowthRate: TLabel;
    bvGrowthRate: TBevel;
    bvCapacity: TBevel;
    lblCapacity: TLabel;
    lblGrowthRateInfo: TLabel;
    lblSunlightInfo: TLabel;
    lblMobilityInfo: TLabel;
    Label6: TLabel;
    shBiomeMapColor: TShape;
    FoodList: TControlList;
    cbFoodActive: TControlListCheckBox;
    lblFoodName: TLabel;
    pbIngredients: TPaintBox;
    btnNewBiome: TButton;
    SunlightEditor: TRatingEditorFrame;
    MobilityEditor: TRatingEditorFrame;
    GrowthEditor: TRatingEditorFrame;
    CapacityEditor: TRatingEditorFrame;
    procedure BiomeListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure pbPresetsPaint(Sender: TObject);
    procedure BiomeListItemClick(Sender: TObject);
    procedure FoodListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure cbFoodActiveClick(Sender: TObject);
    procedure btnNewBiomeClick(Sender: TObject);
    procedure SunlightClick(Sender: TObject);
    procedure MobilityClick(Sender: TObject);
    procedure GrowthRateClick(Sender: TObject);
    procedure CapacityClick(Sender: TObject);
    procedure pbPresetsMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure NameChanged(Sender: TObject);
    procedure DescriptionChanged(Sender: TObject);
  private
    Biome: TBiome; // the one being edited
    procedure EditBiome(aBiome: TBiome);
    procedure UpdateControls;
    procedure ItemChanged;
  protected
    procedure InitContent; override;
  public
    { Public declarations }
  end;


implementation

uses Vcl.Themes,
  u_ControlRendering, u_EnvironmentLibraries;

{$R *.dfm}

{ TBiomeEditor }

procedure TBiomeEditor.BiomeListBeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  if (AIndex >= 0) and (AIndex <= GlobalLibrary.BiomeCount) then
  begin
    var b := GlobalLibrary.Biomes[AIndex];
    lblBiomeName.Caption := b.Name;
    shBiomeMapColor.Brush.Color := b.Color;
    shBiomeMapColor.Brush.Style := bsSolid;
  end
  else
  begin
    lblBiomeName.Caption := '';
    shBiomeMapColor.Brush.Style := bsClear;
  end;
end;

procedure TBiomeEditor.BiomeListItemClick(Sender: TObject);
begin
  if BiomeList.ItemIndex = -1 then
    EditBiome(nil)
  else
    EditBiome(GlobalLibrary.Biomes[BiomeList.ItemIndex]);
end;

procedure TBiomeEditor.btnNewBiomeClick(Sender: TObject);
begin
  var b := TBiome.Create;
  b.Name := 'Untitled01';
  GlobalLibrary.AddBiome(b);
  BiomeList.ItemCount := GlobalLibrary.BiomeCount;

end;

procedure TBiomeEditor.cbFoodActiveClick(Sender: TObject);
begin
  // toggling the active food
  var i := FoodList.ItemIndex;
  if i = -1 then
    Exit;

  var food := GlobalLibrary.Foods[i];
  if cbFoodActive.Checked then
  begin
    Biome.AddFood(food);
  end
  else
  begin
    Biome.RemoveFood(food);
  end;

end;

procedure TBiomeEditor.DescriptionChanged(Sender: TObject);
begin
  Biome.Description := edtDescription.Text;
  ItemChanged;
end;

procedure TBiomeEditor.EditBiome(aBiome: TBiome);
begin
  Biome := aBiome;
  if Assigned(Biome) then
  begin
    BiomePages.ActivePage := tsSelection;
    edtName.Text := Biome.Name;
    edtDescription.Text := Biome.Description;
    shMapColor.Brush.Color := Biome.Color;

    // environment params
    GrowthEditor.Rating := Biome.GrowthRate;
    SunlightEditor.Rating := Biome.Sunlight;
    MobilityEditor.Rating := Biome.Mobility;
    CapacityEditor.Rating := Biome.Capacity;
    FoodList.Invalidate;
  end
  else
    BiomePages.ActivePage := tsNoSelection;

  UpdateControls;
end;

procedure TBiomeEditor.FoodListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
  ARect: TRect; AState: TOwnerDrawState);
begin
  if Assigned(Biome) then
  begin
    lblFoodName.Caption := GlobalLibrary.Foods[AIndex].Name;
    cbFoodActive.Checked := Biome.FoodActive(GlobalLibrary.Foods[AIndex]);

    if cbFoodActive.Checked then
      lblFoodName.Font.Color := StyleServices.GetStyleFontColor(sfWindowTextNormal)
    else
      lblFoodName.Font.Color := StyleServices.GetStyleFontColor(sfWindowTextDisabled);

    pbIngredients.Tag := AIndex;
    pbIngredients.Invalidate;
  end;

end;

procedure TBiomeEditor.InitContent;
begin
  inherited;

  Biome := nil;
  BiomePages.ActivePage := tsNoSelection;
  BiomeList.ItemCount := GlobalLibrary.BiomeCount;

  FoodList.ItemCount := GlobalLibrary.FoodCount;
  lblFoodName.StyleElements := lblFoodName.StyleElements - [seFont];

  SunlightEditor.OnChange := SunlightClick;
  MobilityEditor.OnChange := MobilityClick;
  GrowthEditor.OnChange := GrowthRateClick;
  CapacityEditor.OnChange := CapacityClick;

  UpdateControls;
end;

procedure TBiomeEditor.pbPresetsMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  var newColor: TColor;
  if pbPresets.ColorAtPos(X, Y, newColor) then
  begin
    Biome.Color := newColor;
    ItemChanged;
  end;
end;

procedure TBiomeEditor.pbPresetsPaint(Sender: TObject);
begin
  pbPresets.RenderColorPresets;
end;

procedure TBiomeEditor.NameChanged(Sender: TObject);
begin
  Biome.Name := edtName.Text;
  ItemChanged;
end;

procedure TBiomeEditor.UpdateControls;
begin
end;

procedure TBiomeEditor.ItemChanged;
begin
  // update any views looking at the editing item
  BiomeList.Invalidate;
  FoodList.Invalidate;
  shMapColor.Brush.Color := Biome.Color;

  UpdateControls;
end;


{$region 'Rating Clicks'}
procedure TBiomeEditor.CapacityClick(Sender: TObject);
begin
  if Assigned(Biome) then
    Biome.Capacity := CapacityEditor.Rating;
end;
procedure TBiomeEditor.SunlightClick(Sender: TObject);
begin
  if Assigned(Biome) then
    Biome.Sunlight := SunlightEditor.Rating;
end;
procedure TBiomeEditor.MobilityClick(Sender: TObject);
begin
  if Assigned(Biome) then
    Biome.Mobility := MobilityEditor.Rating;
end;

procedure TBiomeEditor.GrowthRateClick(Sender: TObject);
begin
  if Assigned(Biome) then
    Biome.GrowthRate := GrowthEditor.Rating;
end;
{$endregion}



end.
