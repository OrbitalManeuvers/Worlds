unit fr_RatingControl;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Buttons,
  PngSpeedButton, System.ImageList, Vcl.ImgList, PngImageList, Vcl.StdCtrls,

  u_Worlds.Types;

type
  TRatingEditorFrame = class(TFrame)
    RatingImages: TPngImageList;
    btnWorse: TPngSpeedButton;
    btnBetter: TPngSpeedButton;
    shSegment0: TShape;
    shSegment1: TShape;
    shSegment2: TShape;
    shSegment3: TShape;
    shSegment4: TShape;
    shSegment5: TShape;
    shSegment6: TShape;
    lblRating: TLabel;
    shBkGrnd: TShape;
    procedure AdjustClick(Sender: TObject);
  private
    fShapes: array[TRating] of TShape;
    fRating: TRating;
    fActiveColor: TColor;
    fInactiveColor: TColor;
    procedure SetRating(const Value: TRating);
    procedure Segment(Value: TRating; IsActive: Boolean);

  public
    constructor Create(AOwner: TComponent); override;
    procedure Init;

    property Rating: TRating read fRating write SetRating;
    property ActiveColor: TColor read fActiveColor write fActiveColor;
    property InactiveColor: TColor read fInactiveColor write fInactiveColor;
  end;

implementation

uses Vcl.GraphUtil;

{$R *.dfm}

const
  RatingsStrs: array[TRating] of string = (
    'Worst',
    'Horrible',
    'Bad',
    'Normal',
    'Good',
    'Great',
    'Best'
  );

{ TRatingEditorFrame }

constructor TRatingEditorFrame.Create(AOwner: TComponent);
begin
  inherited;
  fShapes[Worst] := shSegment0;
  fShapes[Horrible] := shSegment1;
  fShapes[Bad] := shSegment2;
  fShapes[Normal] := shSegment3;
  fShapes[Good] := shSegment4;
  fShapes[Great] := shSegment5;
  fShapes[Best] := shSegment6;
end;

procedure TRatingEditorFrame.Init;
begin
  for var r := Low(TRating) to High(TRating) do
    Segment(r, False);
  Self.Rating := Normal;
end;

procedure TRatingEditorFrame.AdjustClick(Sender: TObject);
begin
  if Sender = btnWorse then
    Rating := Pred(fRating)
  else
    Rating := Succ(fRating);
end;

procedure TRatingEditorFrame.Segment(Value: TRating; IsActive: Boolean);
begin
  if IsActive then
  begin
//    fShapes[Value].Pen.Style := psClear;
//    fShapes[Value].Brush.Style := bsSolid;

    var c := GetHighlightColor(fActiveColor, Ord(fRating) * 8);
    fShapes[Value].Brush.Color := c;
  end
  else
  begin
    fShapes[Value].Brush.Color := fInactiveColor;
//    fShapes[Value].Pen.Style := psSolid;
//    fShapes[Value].Pen.Color := fInactiveColor;
  end;
end;

procedure TRatingEditorFrame.SetRating(const Value: TRating);
begin
  if Value <> fRating then
  begin
    Segment(fRating, False);
    fRating := Value;
    Segment(fRating, True);
  end;

  btnWorse.Enabled := fRating > Low(TRating);
  btnBetter.Enabled := fRating < High(TRating);
  lblRating.Caption := RatingsStrs[fRating];
end;

end.
