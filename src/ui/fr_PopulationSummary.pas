unit fr_PopulationSummary;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls,

  u_SimEventTypes, u_LogTypes, u_ControlRendering;

type
  TPopulationSummaryFrame = class(TFrame, ISimEventConsumer)
    Shape1: TShape;
    pbSummary1: TPaintBox;
    pbSummary2: TPaintBox;
    procedure pbSummary2Paint(Sender: TObject);
    procedure pbSummary1Paint(Sender: TObject);
  private
    fSummary1: TLogFields;
    fSummary2: TLogFields;
    procedure Consume(const aEvent: TSimEvent);
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{$R *.dfm}

uses u_DiagnosticsHelpers;


{ TSimStatsFrame }

procedure TPopulationSummaryFrame.Consume(const aEvent: TSimEvent);
begin
  if aEvent.Header.Kind = sekPopulationSummary then
  begin
    fSummary1 := aEvent.PopulationSummary.AsSummaryFields;
    fSummary2 := aEvent.PopulationSummary.AsMaxFields;
    pbSummary1.Invalidate;
    pbSummary2.Invalidate;
  end;
end;

constructor TPopulationSummaryFrame.Create(AOwner: TComponent);
begin
  inherited;
  fSummary1 := Default(TLogFields);
  fSummary2 := Default(TLogFields);
end;

procedure TPopulationSummaryFrame.pbSummary1Paint(Sender: TObject);
begin
  pbSummary1.Render(fSummary1, clBtnFace);
end;

procedure TPopulationSummaryFrame.pbSummary2Paint(Sender: TObject);
begin
  pbSummary2.Render(fSummary2, clBtnFace);
end;

end.
