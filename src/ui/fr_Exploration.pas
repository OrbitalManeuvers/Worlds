unit fr_Exploration;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,

  u_SimEventTypes, u_ExplorationEvaluators, u_ExplorationTypes,
  u_SimDiagnostics, u_SimPopulations;

type
  TExplorationFrame = class(TFrame)
  private
    fSubscriptionId: Integer;
    fEvaluator: TExplorationEvaluator;
  public
    procedure Connect(aDiagnostics: TSimDiagnosticsHub; aPopulation: TSimPopulation);
  end;

implementation

{$R *.dfm}



procedure TExplorationFrame.Connect(aDiagnostics: TSimDiagnosticsHub; aPopulation: TSimPopulation);
begin
//  fEvaluator.Population := aPopulation;
//  fSubscriptionId := aDiagnostics.Subscribe(fEvaluator);
end;

end.
