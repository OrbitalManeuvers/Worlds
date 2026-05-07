unit u_EnvironmentTypes;

interface

uses System.Classes;

type
  // low-res, easy, relative scoring
  TRating = (Worst, Horrible, Bad, Normal, Good, Great, Best);
  TPercentage = 0 .. 100;

type
  TMolecule = (Alpha, Beta, Gamma, Biomass);
  TMolecules = set of TMolecule;
  TGrowableMolecule = TMolecule.Alpha .. TMolecule.Gamma;

type
  TEnvironmentObject = class
  private
    fModified: Boolean;
    fUpdateCount: Integer;
    fOnChange: TNotifyEvent;
    procedure SetModified(const Value: Boolean);
  protected
    procedure Changed;
    procedure ChildChanged(Sender: TObject);
  public
    procedure BeginUpdate;
    procedure EndUpdate;
    property Modified: Boolean read fModified write SetModified;
    property OnChange: TNotifyEvent read fOnChange write fOnChange;
  end;

  TNamedEnvironmentObject = class(TEnvironmentObject)
  private
    fName: string;
    procedure SetName(const Value: string);
  public
    property Name: string read fName write SetName;
  end;

implementation

uses System.SysUtils;


{ TEnvironmentObject }

procedure TEnvironmentObject.BeginUpdate;
begin
  Inc(fUpdateCount);
end;

procedure TEnvironmentObject.Changed;
begin
  fModified := True;
  if (fUpdateCount = 0) and Assigned(fOnChange) then
    fOnChange(Self);
end;

procedure TEnvironmentObject.ChildChanged(Sender: TObject);
begin
  Changed;
end;

procedure TEnvironmentObject.EndUpdate;
begin
  Dec(fUpdateCount);
  if fUpdateCount <= 0 then
  begin
    fUpdateCount := 0;
    if Modified then
      Changed;
  end;
end;

procedure TEnvironmentObject.SetModified(const Value: Boolean);
begin
  fModified := Value;
end;

{ TNamedEnvironmentObject }

procedure TNamedEnvironmentObject.SetName(const Value: string);
begin
  if Value <> fName then
  begin
    fName := Value;
    Changed;
  end;
end;

end.
