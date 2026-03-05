unit fr_FoodEditor;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  Vcl.ControlList, Vcl.ExtCtrls,
  Vcl.ComCtrls,

  fr_ContentFrames,
  u_EnvironmentTypes, u_Foods, fr_RatingEditor;

type
  TFoodEditor = class(TContentFrame)
    FoodList: TControlList;
    lblFoodName: TLabel;
    FoodPages: TPageControl;
    lblFoodList: TLabel;
    lblProperties: TLabel;
    tsNoSelection: TTabSheet;
    tsSelection: TTabSheet;
    lblNameProp: TLabel;
    edtName: TEdit;
    lblGrowthRate: TLabel;
    pbIngredients: TPaintBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    pbAlphaPercent: TPaintBox;
    pbBetaPercent: TPaintBox;
    pbGammaPercent: TPaintBox;
    btnNewFood: TButton;
    GrowthEditor: TRatingEditorFrame;
    procedure FoodListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure FoodListItemClick(Sender: TObject);
    procedure pbIngredientsPaint(Sender: TObject);
    procedure edtNameChange(Sender: TObject);
    procedure pbPercentMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pbPercentMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pbPercentMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure pbPercentPaint(Sender: TObject);
    procedure btnNewFoodClick(Sender: TObject);
  private
    Food: TFood; // the one being edited
    procedure UpdateControls;
    procedure EditFood(aFood: TFood);
    procedure ItemChanged;
    procedure GrowthChanged(Sender: TObject);
  protected
  public
    procedure Init; override;
    procedure ActivateContent; override;
    destructor Destroy; override;
  end;

implementation

{$R *.dfm}

uses u_ControlRendering, u_EnvironmentLibraries;


{ TFoodEditor }

destructor TFoodEditor.Destroy;
begin
  inherited;
end;

procedure TFoodEditor.Init;
begin
  inherited;
  Food := nil;
  FoodList.ItemCount := WorldLibrary.FoodCount;
  FoodPages.ActivePage := tsNoSelection;
  pbAlphaPercent.Tag := Ord(Alpha);
  pbBetaPercent.Tag := Ord(Beta);
  pbGammaPercent.Tag := Ord(Gamma);

  GrowthEditor.OnChange := GrowthChanged;
  UpdateControls;
end;

procedure TFoodEditor.pbIngredientsPaint(Sender: TObject);
begin
  var index := pbIngredients.Tag;
  if (index < 0) or (index >= WorldLibrary.FoodCount) then
    Exit;
   pbIngredients.Render(WorldLibrary.Foods[index].Recipe);
end;

procedure TFoodEditor.pbPercentMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if not (Sender is TPaintBox) then
    Exit;
  var pb := TPaintBox(Sender);
  var percent: TPercentage;
  if pb.PercentAtPos(X, Y, percent) then
  begin
    Food.Recipe.Percents[TMolecule(pb.Tag)] := percent;
    ItemChanged;
  end;
end;

procedure TFoodEditor.pbPercentMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  //
end;

procedure TFoodEditor.pbPercentMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  //
end;

procedure TFoodEditor.pbPercentPaint(Sender: TObject);
begin
  if (Sender is TPaintBox) and Assigned(Food) then
  begin
    var pb := TPaintbox(Sender);
    pb.Render(Food.Recipe, TMolecule(pb.Tag));
  end;
end;

procedure TFoodEditor.ActivateContent;
begin
  inherited;
  if (FoodList.ItemCount > 0) and (FoodList.ItemIndex = -1) then
  begin
    FoodList.ItemIndex := 0;
    EditFood(WorldLibrary.Foods[0]);
  end;
end;

procedure TFoodEditor.btnNewFoodClick(Sender: TObject);
begin
  var Food := TFood.Create;
  Food.Name := 'Unnamed01';
  WorldLibrary.AddFood(Food);
  FoodList.ItemCount := WorldLibrary.FoodCount;
  FoodList.Invalidate;
end;

procedure TFoodEditor.edtNameChange(Sender: TObject);
begin
  if Assigned(Food) then
  begin
    Food.Name := edtName.Text;
    ItemChanged;
  end;
end;

procedure TFoodEditor.FoodListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
  ARect: TRect; AState: TOwnerDrawState);
begin
  lblFoodName.Caption := WorldLibrary.Foods[AIndex].Name;
  pbIngredients.Tag := AIndex;
  pbIngredients.Invalidate;
end;

procedure TFoodEditor.FoodListItemClick(Sender: TObject);
begin
  if FoodList.ItemIndex = -1 then
    EditFood(nil)
  else
    EditFood(WorldLibrary.Foods[FoodList.ItemIndex]);
end;

procedure TFoodEditor.GrowthChanged(Sender: TObject);
begin
  if Assigned(Food) then
    Food.GrowthRate := GrowthEditor.Rating;
end;

procedure TFoodEditor.EditFood(aFood: TFood);
begin
  Food := aFood;
  if Assigned(Food) then
  begin
    FoodPages.ActivePage := tsSelection;
    edtName.Text := Food.Name;
    GrowthEditor.Rating := food.GrowthRate;
    ItemChanged;
  end
  else
    FoodPages.ActivePage := tsNoSelection;
end;

procedure TFoodEditor.ItemChanged;
begin
  FoodList.UpdateItem(FoodList.ItemIndex);
//  pbGrowthRate.Invalidate;
  pbAlphaPercent.Invalidate;
  pbBetaPercent.Invalidate;
  pbGammaPercent.Invalidate;
  UpdateControls;
end;

procedure TFoodEditor.UpdateControls;
begin
//  btnGrowthLess.Enabled := Assigned(Food) and (Food.GrowthRate > Low(TRating));
//  btnGrowthMore.Enabled := Assigned(Food) and (Food.GrowthRate < High(TRating));
end;


end.
