unit d_ExplorationProgressDlg;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,

  u_SimControllers, u_ExplorationEvaluators, u_SimRuntimes, u_ExplorationTypes;

type
  TExplorationCancelEvent = procedure (Sender: TObject; TicksExecuted: Integer; var CanContinue: Boolean) of object;

  TExplorationProgressDlg = class(TForm)
    btnCancel: TButton;
    Label1: TLabel;
    Label2: TLabel;
    lblSimDate: TLabel;
    lblTicksExecuted: TLabel;
    procedure FormShow(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private const
    WM_START_EXPLORATION = WM_USER + $0001;
  private
    fTicksExecuted: Integer;
    fController: TSimController;
    fEvaluator: TExplorationEvaluator;
    fCancelled: Boolean;
    fOnSystemCancel: TExplorationCancelEvent;
    fRuntime: TSimRuntime;
    procedure WMStartExploration(var Msg: TMessage); message WM_START_EXPLORATION;
    procedure HandleAfterAdvance(Sender: TObject);
  public
    function Execute(aRuntime: TSimRuntime; aController: TSimController;
      aEvaluator: TExplorationEvaluator; const aQuery: TExplorationQuery): Integer;
    property OnSystemCancel: TExplorationCancelEvent read fOnSystemCancel write fOnSystemCancel;
  end;

implementation

{$R *.dfm}

uses u_SimTypes;

{ TExplorationProgressDlg }

procedure TExplorationProgressDlg.btnCancelClick(Sender: TObject);
begin
  fCancelled := True;
end;

function TExplorationProgressDlg.Execute(aRuntime: TSimRuntime; aController: TSimController;
  aEvaluator: TExplorationEvaluator; const aQuery: TExplorationQuery): Integer;
begin
  fController := aController;
  fRuntime := aRuntime;
  fEvaluator := aEvaluator;
  fEvaluator.Prepare(aQuery);

  Result := -1; // nothing and/or cancelled
  fTicksExecuted := 0;

  if ShowModal <> mrCancel then
  begin
    // if the run finished return the evaluator's result
    Result := fEvaluator.StopCondition;
  end;
end;

procedure TExplorationProgressDlg.FormShow(Sender: TObject);
begin
  PostMessage(Self.Handle, WM_START_EXPLORATION, 0, 0);
end;

procedure TExplorationProgressDlg.HandleAfterAdvance(Sender: TObject);
begin
  if Assigned(fOnSystemCancel) then
  begin
    var canContinue := True;
    fOnSystemCancel(Self, fTicksExecuted, canContinue);
    if not canContinue then
      fCancelled := True;
  end;
  if not fCancelled then
    fEvaluator.TickComplete(fRuntime.PopulationSummary);
end;

procedure TExplorationProgressDlg.WMStartExploration(var Msg: TMessage);
begin
  fController.AfterAdvance.Subscribe(HandleAfterAdvance);
  try
    fController.Run(
      procedure(const Date: TSimDate; var CanContinue: Boolean)
      begin
        CanContinue := (not fCancelled) and (fEvaluator.StopCondition < 0);
        if fTicksExecuted mod 50 = 0 then
        begin
          lblSimDate.Caption := Format('%.03d:%.03d', [Date.DayNumber, Date.DayTick]);
          Application.ProcessMessages;  // let the modal form repaint
        end;
        Inc(fTicksExecuted);
      end
    );

    // close when done
    if fCancelled then
      ModalResult := mrCancel
    else
      ModalResult := mrOk;

  finally
    fController.AfterAdvance.Unsubscribe(HandleAfterAdvance);
  end;
end;

end.
