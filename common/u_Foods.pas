unit u_Foods;

interface

uses System.Generics.Collections,
  u_EditorObjects, u_Environment.Types, u_Worlds.Types;

type
  // usage of TMolecules
  TRecipe = class(TEditorObject)
  private
    fPercents: array[TGrowableMolecule] of TPercentage;
    function GetPercent(I: TGrowableMolecule): TPercentage;
    procedure SetPrecent(I: TGrowableMolecule; const Value: TPercentage);
  public
    constructor Create;
    function IsBalanced: Boolean;
    procedure SetPercents(alphaPercent, betaPercent, gammaPercent: TPercentage);
    property Percents[I: TGrowableMolecule]: TPercentage read GetPercent write SetPrecent;
  end;

  // a food item
  TFood = class(TEditorObject)
  private
    fName: string;
    fGrowthRate: TRating;
    fRecipe: TRecipe;
    procedure SetGrowthRate(const Value: TRating);
    procedure SetName(const Value: string);
  protected
  public
    constructor Create;
    destructor Destroy; override;

    property Name: string read fName write SetName;
    property GrowthRate: TRating read fGrowthRate write SetGrowthRate;
    property Recipe: TRecipe read fRecipe;
  end;


implementation

uses System.SysUtils;

{ TRecipe }

constructor TRecipe.Create;
begin
  inherited Create;
  fPercents[Alpha] := 30;
  fPercents[Beta] := 40;
  fPercents[Gamma] := 30;
end;

function TRecipe.GetPercent(I: TGrowableMolecule): TPercentage;
begin
  Result := fPercents[I];
end;

function TRecipe.IsBalanced: Boolean;
begin
  var total := 0;
  for var gm in fPercents do
    total := total + gm;
  Result := total = 100;
end;



procedure TRecipe.SetPercents(alphaPercent, betaPercent, gammaPercent: TPercentage);
begin
  fPercents[Alpha] := alphaPercent;
  fPercents[Beta] := betaPercent;
  fPercents[Gamma] := gammaPercent;
  Changed;
end;

procedure TRecipe.SetPrecent(I: TGrowableMolecule; const Value: TPercentage);
begin
  fPercents[I] := Value;
  Changed;
end;


{ TFood }

constructor TFood.Create;
begin
  inherited Create;
  fGrowthRate := Normal;
  fRecipe := TRecipe.Create;
end;

destructor TFood.Destroy;
begin
  Recipe.Free;
  inherited;
end;

procedure TFood.SetGrowthRate(const Value: TRating);
begin
  if Value <> fGrowthRate then
  begin
    fGrowthRate := Value;
    Changed;
  end;
end;

procedure TFood.SetName(const Value: string);
begin
  if not SameText(Value, fName) then
  begin
    fName := Value;
    Changed;
  end;
end;

end.
