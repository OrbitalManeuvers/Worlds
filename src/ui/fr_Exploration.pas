unit fr_Exploration;

interface

uses System.Generics.Collections,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Buttons,

  u_SimEventTypes, u_ExplorationEvaluators, u_ExplorationTypes,
  u_SimDiagnostics, u_SimPopulations, u_SimControllers,
  fr_ConditionEditor;

type
  TExplorationFrame = class(TFrame)
    ConditionView: TScrollBox;
    Label1: TLabel;
    btnAddCondition: TSpeedButton;
    Shape1: TShape;
    edtAgents: TEdit;
    cmbQueryList: TComboBox;
    Label2: TLabel;
    btnDeleteCondition: TSpeedButton;
    Bevel1: TBevel;
    procedure btnAddConditionClick(Sender: TObject);
    procedure btnDeleteConditionClick(Sender: TObject);
  private
    fConditions: TObjectList<TConditionEditor>;
    fSubscriptionId: Integer;
    fPopulation: TSimPopulation;
    fEvaluator: TExplorationEvaluator;
    fController: TSimController;
    fCancelled: Boolean;
    fSystemStop: Boolean;
    procedure Temp;
    procedure HandleEditorClicked(Sender: TObject);
    procedure HandleAfterAdvance(Sender: TObject);
    procedure UpdateControls;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Connect(aController: TSimController; aDiagnostics: TSimDiagnosticsHub; aPopulation: TSimPopulation);
    procedure Disconnect(aDiagnostics: TSimDiagnosticsHub);

    property Cancelled: Boolean read fCancelled write fCancelled;
    property SystemStop: Boolean read fSystemStop write fSystemStop;
  end;

implementation

{$R *.dfm}

uses u_SimTypes, u_AgentTypes;

const
  MAX_POPULATION = 1000;

constructor TExplorationFrame.Create(AOwner: TComponent);
begin
  inherited;
  fEvaluator := TExplorationEvaluator.Create;
  fConditions := TObjectList<TConditionEditor>.Create(False);
end;

destructor TExplorationFrame.Destroy;
begin
  Assert(fSubscriptionId = 0);

  fConditions.Free;
  fEvaluator.Free;
  inherited;
end;

procedure TExplorationFrame.btnDeleteConditionClick(Sender: TObject);
begin
  for var c in fConditions do
    if c.Selected then
    begin
      fConditions.Remove(c);
      c.Free;
      Break;
    end;
  UpdateControls;
end;

procedure TExplorationFrame.Connect(aController: TSimController; aDiagnostics: TSimDiagnosticsHub; aPopulation: TSimPopulation);
begin
  Assert(Assigned(aDiagnostics));
  Assert(Assigned(aPopulation));
  Assert(fSubscriptionId = 0);

  fPopulation := aPopulation;
  fEvaluator.Population := aPopulation;
  fSubscriptionId := aDiagnostics.Subscribe(fEvaluator);

  fController := aController;
  fController.AfterAdvance.Subscribe(HandleAfterAdvance);
end;

procedure TExplorationFrame.Disconnect(aDiagnostics: TSimDiagnosticsHub);
begin
  Assert(Assigned(aDiagnostics));
  fController.AfterAdvance.Unsubscribe(HandleAfterAdvance);

  if fSubscriptionId <> 0 then
  begin
    aDiagnostics.Unsubscribe(fSubscriptionId);
    fSubscriptionId := 0;
  end;

  fEvaluator.Population := nil;
end;

procedure TExplorationFrame.HandleAfterAdvance(Sender: TObject);
begin
  // called from the controller when the tick is done
  SystemStop := Assigned(fPopulation) and (fPopulation.AgentCount > MAX_POPULATION);
  if not SystemStop then
    fEvaluator.TickComplete;
end;

procedure TExplorationFrame.HandleEditorClicked(Sender: TObject);
begin
  var index := fConditions.IndexOf(Sender as TConditionEditor);
  if index <> -1 then
  begin
    var wasSelected := fConditions[index].Selected;
    for var c in fConditions do
      c.Selected := False;
    fConditions[index].Selected := not wasSelected;
    UpdateControls;
  end;
end;

procedure TExplorationFrame.btnAddConditionClick(Sender: TObject);
begin
  var editor := TConditionEditor.Create(Self);
  fConditions.Add(editor);

  editor.OnClick := HandleEditorClicked;
  editor.name := 'c' + IntToStr(ConditionView.ControlCount + 1);
  editor.Align := alTop;
  editor.Top := ConditionView.ClientHeight + 1; // make sure it's last
  editor.Parent := ConditionView;
  ConditionView.ScrollInView(editor);
  UpdateControls;
end;


// this will eventually be Run
procedure TExplorationFrame.Temp;
begin
  fController.Run(
    procedure(const Date: TSimDate; var CanContinue: Boolean)
    begin
      CanContinue := (not Self.Cancelled) and (not Self.SystemStop);
      if CanContinue then
      begin
        fEvaluator.TickComplete;
        CanContinue := fEvaluator.StopCondition < 0;
      end;

    end
  );
end;

procedure TExplorationFrame.UpdateControls;
begin
  btnDeleteCondition.Enabled := False;
  for var c in fConditions do
    if c.Selected then
    begin
      btnDeleteCondition.Enabled := True;
      Break;
    end;

end;

end.
