unit fr_Exploration;

interface

uses System.Generics.Collections,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Buttons,

  u_MulticastEvents,
  u_SimEventTypes, u_ExplorationEvaluators, u_ExplorationTypes,
  u_SimDiagnostics, u_SimPopulations, u_SimControllers,
  fr_ConditionEditor, u_DiagnosticsIntf, u_SimRuntimes;

type
  TExplorationFrame = class(TFrame, IRuntimeObserver, IRuntimeController)
    ConditionView: TScrollBox;
    Label1: TLabel;
    btnAddCondition: TSpeedButton;
    Shape1: TShape;
    edtAgents: TEdit;
    cmbQueryList: TComboBox;
    Label2: TLabel;
    btnDeleteCondition: TSpeedButton;
    Bevel1: TBevel;
    btnRun: TSpeedButton;
    procedure btnAddConditionClick(Sender: TObject);
    procedure btnDeleteConditionClick(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure edtAgentsChange(Sender: TObject);
  private
    fRuntime: TSimRuntime;
    fDiagnostics: TSimDiagnosticsHub;
    fConditions: TObjectList<TConditionEditor>;
    fPopulation: TSimPopulation;
    fEvaluator: TExplorationEvaluator;
    fController: TSimController;
    fCancelled: Boolean;
    fSystemStop: Boolean;
    fAgentsValid: Boolean;
    fAgents: TList<Integer>;
    fNextconditionId: Integer;
    procedure HandleEditorClicked(Sender: TObject);
    procedure HandleStatusChanged(Sender: TObject);
    procedure HandleExplorationSystemCancel(Sender: TObject; TicksExecuted: Integer; var CanContinue: Boolean);
    procedure UpdateControls;

    { IRuntimeObserver }
    procedure ConnectRuntime(aRuntime: TSimRuntime; aDiagnostics: TSimDiagnosticsHub;
      AfterAdvance: TMulticastEvent<TNotifyEvent>);
    procedure DisconnectRuntime(aRuntime: TSimRuntime; aDiagnostics: TSimDiagnosticsHub;
      AfterAdvance: TMulticastEvent<TNotifyEvent>);

    { IRuntimeController }
    procedure ConnectController(aController: TSimController);
    procedure DisconnectController(aController: TSimController);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property Cancelled: Boolean read fCancelled write fCancelled;
    property SystemStop: Boolean read fSystemStop write fSystemStop;
  end;

implementation

{$R *.dfm}

uses u_SimTypes, u_RuntimeTypes, u_EnvironmentTypes, d_ExplorationProgressDlg;

const
  MAX_EXPLORATION_POPULATION = 500;
  MAX_EXPLORATION_TICKS = 1000;

type
  condition_helper = record helper for TExplorationCondition
    procedure firstDelta;
  end;

{ query_helper }
procedure condition_helper.firstDelta;
begin
  Kind := ekActionSelected;
  Action.Action := acForage;
  Action.Target.TType := ttCache;
  Action.Target.Cache.Kind := ckDelta;
  Action.Target.Cache.Index := -1;
end;

{ TExplorationFrame }
constructor TExplorationFrame.Create(AOwner: TComponent);
begin
  inherited;
  fEvaluator := TExplorationEvaluator.Create;
  fConditions := TObjectList<TConditionEditor>.Create(False);
  fAgents := TList<Integer>.Create;
  fAgentsValid := True;
end;

destructor TExplorationFrame.Destroy;
begin
  fAgents.Free;
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

procedure TExplorationFrame.btnRunClick(Sender: TObject);
begin
  var query := Default(TExplorationQuery);

  // if there are agents specified
  if fAgents.Count > 0 then
  begin
    SetLength(query.Agents, fAgents.Count);
    for var i := 0 to fAgents.Count - 1 do
      query.Agents[i] := fAgents[i];
  end;

  // copy the conditions from the UI
  for var i := 0 to fConditions.Count - 1 do
  begin
    if fConditions[i].Status = esOK then
    begin
      var len := Length(query.Conditions);
      SetLength(query.Conditions, len + 1);
      query.Conditions[len] := fConditions[i].Condition;
    end;
  end;

  // execute
  var dlg := TExplorationProgressDlg.Create(Application);
  try
    dlg.OnSystemCancel := HandleExplorationSystemCancel;
    var expResult := dlg.Execute(fRuntime, fController, fEvaluator, query);

    // if the result is >= 0
    if expResult >= 0 then
    begin
//      query.Conditions[expResult]
    end;

  finally
    dlg.Free;
  end;
end;

procedure TExplorationFrame.ConnectRuntime(aRuntime: TSimRuntime; aDiagnostics: TSimDiagnosticsHub;
  AfterAdvance: TMulticastEvent<TNotifyEvent>);
begin
  fRuntime := aRuntime;
  fDiagnostics := aDiagnostics;

  fEvaluator.Population := fRuntime.Population;
  fEvaluator.SubscriptionId := fDiagnostics.Subscribe(fEvaluator);

  UpdateControls;
end;

procedure TExplorationFrame.DisconnectRuntime(aRuntime: TSimRuntime; aDiagnostics: TSimDiagnosticsHub;
  AfterAdvance: TMulticastEvent<TNotifyEvent>);
begin
  fEvaluator.Population := nil;
  aDiagnostics.Unsubscribe(fEvaluator.SubscriptionId);
  fEvaluator.SubscriptionId := 0;
end;

procedure TExplorationFrame.ConnectController(aController: TSimController);
begin
  fController := aController;
end;

procedure TExplorationFrame.DisconnectController(aController: TSimController);
begin
  fController := nil;
end;

procedure TExplorationFrame.edtAgentsChange(Sender: TObject);
begin
  fAgents.Clear;

  var input := Trim(edtAgents.Text);
  fAgentsValid := input = '*';

  if not fAgentsValid then
  begin
    var parts := input.Split([',', ' ']);
    if Length(parts) > 0 then
    begin
      for var item in parts do
      begin
        var id: Integer;
        if TryStrToInt(item, id) then
        begin
          fAgentsValid := True;
          fAgents.Add(id);
        end
        else
        begin
          fAgentsValid := False;
          Break;
        end;
      end;
    end;
  end;

  UpdateControls;
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

procedure TExplorationFrame.HandleExplorationSystemCancel(Sender: TObject;
  TicksExecuted: Integer; var CanContinue: Boolean);
begin
  if (TicksExecuted > MAX_EXPLORATION_TICKS) or
    (Assigned(fPopulation) and (fPopulation.AgentCount > MAX_EXPLORATION_POPULATION)) then
    CanContinue := False;
end;

procedure TExplorationFrame.HandleStatusChanged(Sender: TObject);
begin
  UpdateControls;
end;

procedure TExplorationFrame.btnAddConditionClick(Sender: TObject);
begin
  var editor := TConditionEditor.Create(Self);
  fConditions.Add(editor);

  editor.OnClick := HandleEditorClicked;
  editor.OnStatusChange := HandleStatusChanged;
  editor.name := 'ced' + IntToStr(fNextConditionId);
  Inc(fNextConditionId);
  editor.Align := alTop;
  editor.Top := ConditionView.ClientHeight + 1; // make sure it's last
  editor.Parent := ConditionView;

  var firstDelta: TExplorationCondition;
  firstDelta.firstDelta;
  editor.Condition := firstDelta;

  ConditionView.ScrollInView(editor);
  UpdateControls;
end;

procedure TExplorationFrame.UpdateControls;
begin
  btnDeleteCondition.Enabled := False;
  btnRun.Enabled := fConditions.Count > 0;

  var validConditions := 0;
  for var c in fConditions do
  begin
    if c.Status = esOK then
      Inc(validConditions);
    if c.Selected then
      btnDeleteCondition.Enabled := True;
    if c.Status = esError then
      btnRun.Enabled := False;
  end;

  if (validConditions = 0) or (not fAgentsValid) then
    btnRun.Enabled := False;
end;

end.
