unit fr_BiologyEditor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.StdCtrls,
  Vcl.ControlList, Vcl.Buttons, Vcl.ComCtrls,

  u_BiologyTypes, fr_RatingEditor, Vcl.ExtCtrls;

type
  TBiologyEditor = class(TContentFrame)
    RatingsList: TControlList;
    Label1: TLabel;
    btnNewRatings: TSpeedButton;
    Pages: TPageControl;
    tsNoSelection: TTabSheet;
    tsSelection: TTabSheet;
    lblRatingsName: TLabel;
    edtName: TEdit;
    edtDescription: TEdit;
    lblName: TLabel;
    lblDescription: TLabel;
    lblAlphaRating: TLabel;
    bvAlpha: TBevel;
    AlphaRatingFrame: TRatingEditorFrame;
    BetaRatingFrame: TRatingEditorFrame;
    bvBeta: TBevel;
    lblBetaRating: TLabel;
    GammaRatingFrame: TRatingEditorFrame;
    bvGamma: TBevel;
    lblGammaRating: TLabel;
    BiomassRatingFrame: TRatingEditorFrame;
    bvBiomass: TBevel;
    lblBiomassRating: TLabel;
    Label2: TLabel;
    procedure RatingsListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure RatingsListItemClick(Sender: TObject);
    procedure edtNameChange(Sender: TObject);
    procedure edtDescriptionChange(Sender: TObject);
    procedure btnNewRatingsClick(Sender: TObject);
  private
    fRatings: TMoleculeRatings;
    procedure EditRatings(aRatings: TMoleculeRatings);
    procedure ItemChanged;
    procedure RatingChanged(Sender: TObject);
  public
    procedure Init; override;
    procedure ActivateContent; override;
  end;


implementation

uses Vcl.Themes, Vcl.GraphUtil,
  u_EnvironmentTypes,
  u_ControlRendering, u_EnvironmentLibraries, u_EditorTypes;

{$R *.dfm}

const
  RatingCaptions: TRatingNames = (
   'Invisible',
   'Minimal',
   'Low',
   'Normal',
   'Above Average',
   'Highly Valuable',
   'SuperPowers'
  );


{ TBiologyEditor }

procedure TBiologyEditor.Init;

  procedure UpdateLabel(const aLabel: TLabel; aMolecule: TMolecule);
  begin
    aLabel.StyleElements := lblAlphaRating.StyleElements - [seFont];
    aLabel.Font.Color := WebColorStrToColor(MOLECULE_COLORS[aMolecule]);
  end;

  procedure UpdateEditor(aFrame: TRatingEditorFrame; aMolecule: TMolecule);
  begin
    aFrame.Tag := Ord(aMolecule);
    aFrame.OnChange := RatingChanged;
  end;

begin
  inherited;
  fRatings := nil;
  Pages.ActivePage := tsNoSelection;
  UpdateLabel(lblAlphaRating, Alpha);
  UpdateLabel(lblBetaRating, Beta);
  UpdateLabel(lblGammaRating, Gamma);
  UpdateLabel(lblBiomassRating, Biomass);

  UpdateEditor(AlphaRatingFrame, Alpha);
  UpdateEditor(BetaRatingFrame, Beta);
  UpdateEditor(GammaRatingFrame, Gamma);
  UpdateEditor(BiomassRatingFrame, Biomass);
end;

procedure TBiologyEditor.ItemChanged;
begin
  RatingsList.Invalidate;
end;

procedure TBiologyEditor.ActivateContent;
begin
  inherited;
  // make sure we have the most current list
  if WorldLibrary.RatingsCount <> RatingsList.ItemCount then
  begin
    RatingsList.ItemCount := WorldLibrary.RatingsCount;
    if RatingsList.ItemCount > 0 then
    begin
      RatingsList.ItemIndex := 0;
      EditRatings(WorldLibrary.Ratings[0]);
    end;
  end;
end;

procedure TBiologyEditor.RatingsListBeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  if (AIndex > -1) and (AIndex < WorldLibrary.RatingsCount) then
  begin
    lblRatingsName.Caption := WorldLibrary.Ratings[AIndex].Name;

  end;
end;

procedure TBiologyEditor.RatingsListItemClick(Sender: TObject);
begin
  if RatingsList.ItemIndex <> -1 then
    EditRatings(WorldLibrary.Ratings[RatingsList.ItemIndex]);
end;

procedure TBiologyEditor.btnNewRatingsClick(Sender: TObject);
begin
  var Ratings := TMoleculeRatings.Create;
  Ratings.Name := 'Unnamed01';
  WorldLibrary.AddRatings(Ratings);
  RatingsList.ItemCount := WorldLibrary.RatingsCount;
  RatingsList.Invalidate;
end;

procedure TBiologyEditor.EditRatings(aRatings: TMoleculeRatings);
begin
  if Assigned(aRatings) then
  begin
    Pages.ActivePage := tsSelection;
    fRatings := aRatings;
    edtName.Text := fRatings.Name;
    edtDescription.Text := fRatings.Description;
    AlphaRatingFrame.Rating := fRatings[Alpha];
    BetaRatingFrame.Rating := fRatings[Beta];
    GammaRatingFrame.Rating := fRatings[Gamma];
    BiomassRatingFrame.Rating := fRatings[Biomass];
  end
  else
  begin
    Pages.ActivePage := tsNoSelection;
  end;
end;

procedure TBiologyEditor.edtDescriptionChange(Sender: TObject);
begin
  fRatings.Description := edtDescription.Text;
  ItemChanged;
end;

procedure TBiologyEditor.edtNameChange(Sender: TObject);
begin
  fRatings.Name := edtName.Text;
  ItemChanged;
end;

procedure TBiologyEditor.RatingChanged(Sender: TObject);
begin
  if Sender is TRatingEditorFrame then
  begin
    var frame := TRatingEditorFrame(Sender);
    var molecule := TMolecule(frame.Tag);
    fRatings[molecule] := frame.Rating;
    ItemChanged;
  end;
end;


end.
