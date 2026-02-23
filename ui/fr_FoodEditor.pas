unit fr_FoodEditor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.StdCtrls,
  Vcl.ControlList, Vcl.ExtCtrls,
  System.Generics.Collections, Vcl.ComCtrls, Vcl.Buttons,

  u_Worlds.Types, u_Environment.Types;

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
    pbGrowthRate: TPaintBox;
    pbIngredients: TPaintBox;
    btnGrowthLess: TSpeedButton;
    btnGrowthMore: TSpeedButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    pbAlphaPercent: TPaintBox;
    pbBetaPercent: TPaintBox;
    pbGammaPercent: TPaintBox;
    Button1: TButton;
    procedure FoodListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure FoodListItemClick(Sender: TObject);
    procedure pbGrowthRatePaint(Sender: TObject);
    procedure pbIngredientsPaint(Sender: TObject);
    procedure edtNameChange(Sender: TObject);
    procedure GrowthRateClick(Sender: TObject);
    procedure pbPercentMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pbPercentMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pbPercentMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure pbPercentPaint(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
//    fItemIndex: Integer;
    Food: TFood;
    procedure UpdateControls;
    procedure EditFood(aFood: TFood);
    procedure ItemChanged;
  protected
    procedure InitContent; override;
  public
    destructor Destroy; override;
  end;

implementation

{$R *.dfm}

uses System.UITypes, Vcl.Themes, Vcl.GraphUtil, System.Math, u_ControlRendering;

{ TFoodEditor }

procedure TFoodEditor.InitContent;
begin
  inherited;
//  fItemIndex := -1;
  Food := nil;
  FoodList.ItemCount := World.Foods.Count;
  FoodPages.ActivePage := tsNoSelection;
  pbAlphaPercent.Tag := Ord(Alpha);
  pbBetaPercent.Tag := Ord(Beta);
  pbGammaPercent.Tag := Ord(Gamma);
  UpdateControls;
end;

procedure TFoodEditor.pbIngredientsPaint(Sender: TObject);
begin
  var index := pbIngredients.Tag;
  if (not Assigned(World)) or (index < 0) or (index >= World.Foods.Count) then
    Exit;
   pbIngredients.Render(World.Foods[index].Recipe);
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

procedure TFoodEditor.pbGrowthRatePaint(Sender: TObject);
begin
  if Assigned(Food) then
  begin
    var rating := Food.GrowthRate;
    TPaintBox(Sender).Render(rating);
  end;
end;

procedure TFoodEditor.Button1Click(Sender: TObject);
begin
  var Food := TFood.Create;
  Food.Name := 'Unnamed01';
  World.Foods.Add(Food);
  FoodList.ItemCount := World.Foods.Count;
//

end;

destructor TFoodEditor.Destroy;
begin
  inherited;
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
  lblFoodName.Caption := World.Foods[AIndex].Name;
  pbIngredients.Tag := AIndex;
  pbIngredients.Invalidate;
end;

procedure TFoodEditor.FoodListItemClick(Sender: TObject);
begin
  if FoodList.ItemIndex = -1 then
    EditFood(nil)
  else
    EditFood(World.Foods[FoodList.ItemIndex]);
end;

procedure TFoodEditor.EditFood(aFood: TFood);
begin
  Food := aFood;
  if Assigned(Food) then
    FoodPages.ActivePage := tsSelection
  else
    FoodPages.ActivePage := tsNoSelection;

  edtName.Text := Food.Name;
  pbGrowthRate.Invalidate;
  pbAlphaPercent.Invalidate;
  pbBetaPercent.Invalidate;
  pbGammaPercent.Invalidate;
  ItemChanged;
end;

procedure TFoodEditor.GrowthRateClick(Sender: TObject);
begin
  var rate := Food.GrowthRate;
  if Sender = btnGrowthLess then
    rate := Pred(rate)
  else
    rate := Succ(rate);
  Food.GrowthRate := Rate;
  pbGrowthRate.Invalidate;
  ItemChanged;
end;

procedure TFoodEditor.ItemChanged;
begin
  FoodList.UpdateItem(FoodList.ItemIndex);
  pbAlphaPercent.Invalidate;
  pbBetaPercent.Invalidate;
  pbGammaPercent.Invalidate;
  UpdateControls;
end;

procedure TFoodEditor.UpdateControls;
begin
  btnGrowthLess.Enabled := Assigned(Food) and (Food.GrowthRate > Low(TRating));
  btnGrowthMore.Enabled := Assigned(Food) and (Food.GrowthRate < High(TRating));
end;


end.
