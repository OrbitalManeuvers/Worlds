unit fr_BiomeEditor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.StdCtrls,
  Vcl.ComCtrls, Vcl.ControlList, Vcl.ExtCtrls, Vcl.Buttons,

  u_Worlds.Types,
  u_Environment.Types,
  u_Foods,
  u_Biomes;

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
    btnGrowthLess: TSpeedButton;
    pbGrowthRate: TPaintBox;
    btnGrowthMore: TSpeedButton;
    lblGrowthRateInfo: TLabel;
    btnSunlightLess: TSpeedButton;
    pbSunlight: TPaintBox;
    btnSunlightMore: TSpeedButton;
    lblSunlightInfo: TLabel;
    btnMobilityLess: TSpeedButton;
    pbMobility: TPaintBox;
    btnMobilityMore: TSpeedButton;
    lblMobilityInfo: TLabel;
    btnCapacityLess: TSpeedButton;
    pbCapacity: TPaintBox;
    btnCapacityMore: TSpeedButton;
    Label6: TLabel;
    shBiomeMapColor: TShape;
    FoodList: TControlList;
    cbFoodActive: TControlListCheckBox;
    lblFoodName: TLabel;
    pbIngredients: TPaintBox;
    procedure BiomeListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure pbPresetsPaint(Sender: TObject);
    procedure BiomeListItemClick(Sender: TObject);
    procedure pbSunlightPaint(Sender: TObject);
    procedure pbMobilityPaint(Sender: TObject);
    procedure pbGrowthRatePaint(Sender: TObject);
    procedure pbCapacityPaint(Sender: TObject);
    procedure FoodListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure cbFoodActiveClick(Sender: TObject);
    procedure pbIngredientsPaint(Sender: TObject);
  private
    Biome: TBiome; // the one being edited
    procedure EditBiome(aBiome: TBiome);
    procedure UpdateControls;
  protected
    procedure InitContent; override;
  public
    { Public declarations }
  end;


implementation

uses u_ControlRendering, u_EnvironmentLibraries;

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
    pbGrowthRate.Invalidate;
    pbSunlight.Invalidate;
    pbMobility.Invalidate;
    pbCapacity.Invalidate;
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

  UpdateControls;
end;

procedure TBiomeEditor.pbCapacityPaint(Sender: TObject);
begin
  if Assigned(Biome) then
  begin
    var rating := Biome.Capacity;
    TPaintBox(Sender).Render(rating);
  end;
end;

procedure TBiomeEditor.pbGrowthRatePaint(Sender: TObject);
begin
  if Assigned(Biome) then
  begin
    var rating := Biome.GrowthRate;
    TPaintBox(Sender).Render(rating);
  end;
end;

procedure TBiomeEditor.pbIngredientsPaint(Sender: TObject);
begin
  var i := (Sender as TPaintBox).Tag;
  if Assigned(Biome) and (i <> -1) then
  begin
    pbIngredients.Render(GlobalLibrary.Foods[i].Recipe);
  end;
end;

procedure TBiomeEditor.pbMobilityPaint(Sender: TObject);
begin
  if Assigned(Biome) then
  begin
    var rating := Biome.Mobility;
    TPaintBox(Sender).Render(rating);
  end;
end;

procedure TBiomeEditor.pbPresetsPaint(Sender: TObject);
begin
  pbPresets.RenderColorPresets;

end;

procedure TBiomeEditor.pbSunlightPaint(Sender: TObject);
begin
  if Assigned(Biome) then
  begin
    var rating := Biome.Sunlight;
    TPaintBox(Sender).Render(rating);
  end;
end;

procedure TBiomeEditor.UpdateControls;
begin
  btnGrowthLess.Enabled := Assigned(Biome) and (Biome.GrowthRate > Low(TRating));
  btnGrowthMore.Enabled := Assigned(Biome) and (Biome.GrowthRate < High(TRating));

  btnSunlightLess.Enabled := Assigned(Biome) and (Biome.Sunlight > Low(TRating));
  btnSunlightMore.Enabled := Assigned(Biome) and (Biome.Sunlight < High(TRating));

  btnCapacityLess.Enabled := Assigned(Biome) and (Biome.Capacity > Low(TRating));
  btnCapacityMore.Enabled := Assigned(Biome) and (Biome.Capacity < High(TRating));

  btnMobilityLess.Enabled := Assigned(Biome) and (Biome.Mobility > Low(TRating));
  btnMobilityMore.Enabled := Assigned(Biome) and (Biome.Mobility < High(TRating));

end;

end.
