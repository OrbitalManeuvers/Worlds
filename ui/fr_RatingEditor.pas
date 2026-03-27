unit fr_RatingEditor;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  PngImageList, PngSpeedButton, Vcl.ExtCtrls,
  System.ImageList, Vcl.ImgList, Vcl.Buttons,

  u_EnvironmentTypes, u_EditorTypes;

type
  TRatingEditorFrame = class(TFrame)
    pbRating: TPaintBox;
    btnLess: TPngSpeedButton;
    ilButtons: TPngImageList;
    btnMore: TPngSpeedButton;
    procedure pbRatingPaint(Sender: TObject);
    procedure ButtonClick(Sender: TObject);
  private
    fRating: TRating;
    fIsReadOnly: Boolean;
    fOnChange: TNotifyEvent;
    fCaptions: TRatingNames;
    procedure SetRating(const Value: TRating);
    procedure UpdateControls;
    procedure SetIsReadOnly(const Value: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    property Rating: TRating read fRating write SetRating;
    property OnChange: TNotifyEvent read fOnChange write fOnChange;
    property IsReadOnly: Boolean write SetIsReadOnly;
    property RatingNames: TRatingNames read fCaptions write fCaptions;
  end;

implementation

{$R *.dfm}

uses u_ControlRendering;

{ TRatingEditorFrame }

procedure TRatingEditorFrame.ButtonClick(Sender: TObject);
begin
  if Sender = btnLess then
    Rating := Pred(fRating)
  else
    Rating := Succ(fRating);
  if Assigned(fOnChange) then
    fOnChange(Self);
end;

constructor TRatingEditorFrame.Create(AOwner: TComponent);
begin
  inherited;
  fCaptions := RATING_NAMES;
end;

procedure TRatingEditorFrame.pbRatingPaint(Sender: TObject);
begin
  pbRating.Render(fRating, fCaptions[fRating]);
end;

procedure TRatingEditorFrame.SetIsReadOnly(const Value: Boolean);
begin
  fIsReadOnly := Value;
  UpdateControls;
end;

procedure TRatingEditorFrame.SetRating(const Value: TRating);
begin
  fRating := Value;
  pbRating.Invalidate;
  UpdateControls;
end;

procedure TRatingEditorFrame.UpdateControls;
begin
  btnLess.Enabled := (fRating > Low(TRating)) and (not fIsReadOnly);
  btnMore.Enabled := (fRating < High(TRating)) and (not fIsReadOnly);
end;

end.
