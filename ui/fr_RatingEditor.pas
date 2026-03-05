unit fr_RatingEditor;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  PngImageList, PngSpeedButton, Vcl.ExtCtrls,
  System.ImageList, Vcl.ImgList, Vcl.Buttons,

  u_EnvironmentTypes;

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
    fOnChange: TNotifyEvent;
    procedure SetRating(const Value: TRating);
    procedure UpdateControls;
  public
    property Rating: TRating read fRating write SetRating;
    property OnChange: TNotifyEvent read fOnChange write fOnChange;
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

procedure TRatingEditorFrame.pbRatingPaint(Sender: TObject);
begin
  pbRating.Render(fRating);
end;

procedure TRatingEditorFrame.SetRating(const Value: TRating);
begin
  fRating := Value;
  pbRating.Invalidate;
  UpdateControls;
end;

procedure TRatingEditorFrame.UpdateControls;
begin
  btnLess.Enabled := fRating > Low(TRating);
  btnMore.Enabled := fRating < High(TRating);
end;

end.
