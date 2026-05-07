unit fr_ResourceVisualizer;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Samples.Spin;

type
  TResViewFrame = class(TFrame)
    pbVis: TPaintBox;
    sbHPan: TScrollBar;
    sbVPan: TScrollBar;
    spZoomFactor: TSpinEdit;
    lblZoom: TLabel;
    sbSubstance: TSpinButton;
    cbActive: TCheckBox;
    pbSubstance: TPaintBox;
    Bevel1: TBevel;
    procedure pbSubstancePaint(Sender: TObject);
    procedure cbActiveClick(Sender: TObject);
    procedure pbVisPaint(Sender: TObject);
    procedure sbSubstanceUpClick(Sender: TObject);
    procedure sbSubstanceDownClick(Sender: TObject);
    procedure spZoomFactorChange(Sender: TObject);
  private
    fIsActive: Boolean;
    fOnPaint: TNotifyEvent;
    fSubstanceNames: TStrings;
    fSubstanceIndex: Integer;
    procedure SetIsActive(const Value: Boolean);
    function GetCanvas: TCanvas;
    procedure SetSubstanceNames(const Value: TStrings);
    procedure SetSubstanceIndex(const Value: Integer);
    function GetZoomFactor: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure InvalidateView;
    procedure ApplySubstanceNames(const Value: TArray<string>); overload;

    property IsActive: Boolean read fIsActive write SetIsActive;
    property OnPaint: TNotifyEvent read fOnPaint write fOnPaint;
    property Canvas: TCanvas read GetCanvas;
    property SubstanceNames: TStrings read fSubstanceNames write SetSubstanceNames;
    property SubstanceIndex: Integer read fSubstanceIndex write SetSubstanceIndex;
    property ZoomFactor: Integer read GetZoomFactor;
  end;

implementation

{$R *.dfm}

uses Vcl.Themes,
  u_SimVisualizer;

procedure TResViewFrame.cbActiveClick(Sender: TObject);
begin
  SetIsActive(cbActive.Checked);
end;

constructor TResViewFrame.Create(AOwner: TComponent);
begin
  inherited;
  fSubstanceNames := TStringList.Create(dupAccept, False, False);
  DoubleBuffered := True;
  pbVis.ControlStyle := pbVis.ControlStyle + [csOpaque];
  pbSubstance.ControlStyle := pbSubstance.ControlStyle + [csOpaque];
  spZoomFactor.MinValue := 0;
  spZoomFactor.MaxValue := Ord(High(TVisualizerZoom));
end;

destructor TResViewFrame.Destroy;
begin
  fSubstanceNames.Free;
  inherited;
end;

function TResViewFrame.GetCanvas: TCanvas;
begin
  Result := pbVis.Canvas;
end;

function TResViewFrame.GetZoomFactor: Integer;
begin
  Result := spZoomFactor.Value;
end;

procedure TResViewFrame.pbSubstancePaint(Sender: TObject);
begin
  pbSubstance.Canvas.Font := Self.Font;
  pbSubstance.Canvas.Font.Color := StyleServices.GetStyleFontColor(sfWindowTextNormal);

  var substanceName := '';
  if (fSubstanceIndex >= 0) and (SubstanceIndex < fSubstanceNames.Count) then
    substanceName := fSubstanceNames[fSubstanceIndex];

  var r := pbSubstance.ClientRect;
  var c := pbSubstance.Canvas;

  c.Brush.Color := StyleServices.GetStyleColor(scButtonNormal);
  c.Brush.Style := bsSolid;
  c.Pen.Style := psClear;
  c.Rectangle(r);
  c.Brush.Style := bsClear;
  c.TextRect(r, substanceName, [tfSingleLine, tfCenter, tfVerticalCenter]);
end;

procedure TResViewFrame.pbVisPaint(Sender: TObject);
begin
  if cbActive.Checked and Assigned(fOnPaint) then
    fOnPaint(Self);
end;

procedure TResViewFrame.sbSubstanceDownClick(Sender: TObject);
begin
  SubstanceIndex := SubstanceIndex - 1;
end;

procedure TResViewFrame.sbSubstanceUpClick(Sender: TObject);
begin
  SubstanceIndex := SubstanceIndex + 1;
end;

procedure TResViewFrame.SetIsActive(const Value: Boolean);
begin
  if Value <> fIsActive then
  begin
    fIsActive := Value;
    if Value <> cbActive.Checked then
      cbActive.Checked := Value;
    if fIsActive then
      pbVis.Invalidate;
  end;
end;

procedure TResViewFrame.SetSubstanceIndex(const Value: Integer);
begin
  if (Value >= 0) and (Value < fSubstanceNames.Count) then
  begin
    fSubstanceIndex := Value;
    pbSubstance.Invalidate;
    if fIsActive then
      pbVis.Invalidate;
  end;
end;

procedure TResViewFrame.SetSubstanceNames(const Value: TStrings);
begin
  fSubstanceNames.Assign(Value);
  fSubstanceIndex := 0;
  pbSubstance.Invalidate;
end;

procedure TResViewFrame.ApplySubstanceNames(const Value: TArray<string>);
begin
  fSubstanceNames.BeginUpdate;
  try
    fSubstanceNames.Clear;
    for var name in Value do
      fSubstanceNames.Add(name);
  finally
    fSubstanceNames.EndUpdate;
  end;

  fSubstanceIndex := 0;
  pbSubstance.Invalidate;
end;

procedure TResViewFrame.spZoomFactorChange(Sender: TObject);
begin
  pbVis.Invalidate;
end;

procedure TResViewFrame.InvalidateView;
begin
  if fIsActive then
    pbVis.Invalidate;
end;

end.
