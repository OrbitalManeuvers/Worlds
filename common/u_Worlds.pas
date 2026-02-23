unit u_Worlds;

interface

uses System.Generics.Collections, System.JSON,

  u_Worlds.Types, u_Environment.Types;

type
  TWorld = class
  private
    fModified: Boolean;
    fFoods: TObjectList<TFood>;
  public
    Name: string;
    constructor Create;
    destructor Destroy; override;

    { foods }
    property Foods: TObjectList<TFood> read fFoods;
    property Modified: Boolean read fModified write fModified;
  end;

implementation

{ TWorld }

constructor TWorld.Create;
begin
  inherited Create;
  Name := 'Untitled';
  fFoods := TObjectList<TFood>.Create(True);

  var f := TFood.Create;
  f.Name := 'Poison Onions';
  f.GrowthRate := Worst;
  f.Recipe.SetPercents(0, 60, 40);
  fFoods.Add(f);

  f := TFood.Create;
  f.Name := 'Grapes Du Wrath';
  f.GrowthRate := Normal;
  f.Recipe.SetPercents(30, 10, 60);
  fFoods.Add(f);

  f := TFood.Create;
  f.Name := 'Big Mac';
  f.GrowthRate := Best;
  f.Recipe.SetPercents(0, 0, 100);
  fFoods.Add(f);
end;

destructor TWorld.Destroy;
begin
  fFoods.Free;
  inherited;
end;



end.
