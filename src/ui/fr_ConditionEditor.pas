unit fr_ConditionEditor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,

  u_ExplorationTypes;

type
  TEditorStatus = (esOK, esError, esDisabled);

  TConditionEditor = class(TFrame)
    cmbAction: TComboBox;
    edtParameter: TEdit;
    cmbCacheType: TComboBox;
    shStatus: TShape;
    cmbKind: TComboBox;
    shBorder: TShape;
    procedure cmbKindCloseUp(Sender: TObject);
    procedure cmbActionCloseUp(Sender: TObject);
    procedure shBorderMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure shStatusMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure cmbCacheTypeCloseUp(Sender: TObject);
    procedure edtParameterChange(Sender: TObject);
  private type
    TParamType = (ptPoint, ptInteger, ptFloat);
  private
    fCondition: TExplorationCondition;
    fSelected: Boolean;
    fStatus: TEditorStatus;
    fOnStatusChange: TNotifyEvent;
    procedure SetCondition(const Value: TExplorationCondition);
    procedure UpdateLayout;
    procedure SetSelected(const Value: Boolean);
    function GetCondition: TExplorationCondition;
    procedure Validate;
    procedure ChangeStatus(aStatus: TEditorStatus);
    function MakeParam(const aValue: string; aParamType: TParamType; out IntValue: Integer): Boolean; overload;
    function MakeParam(const aValue: string; aParamType: TParamType; out FloatValue: Single): Boolean; overload;
    function MakeParam(const aValue: string; aParamType: TParamType; out PointValue: TPoint): Boolean; overload;
  public
    constructor Create(AOwner: TComponent); override;
    property Condition: TExplorationCondition read GetCondition write SetCondition;
    property Selected: Boolean read fSelected write SetSelected;
    property Status: TEditorStatus read fStatus;
    property OnStatusChange: TNotifyEvent read fOnStatusChange write fOnStatusChange;
  end;

implementation

{$R *.dfm}

uses Vcl.Themes, u_AgentTypes;

const
  GRID_WIDTH = 256; // well-established tech debt found several places

const
  condition_kind_labels: array[TExplorationConditionKind] of string = (
    'Birth', 'Death', 'Action', 'Awake Past', 'Reaches Age', 'Travels Distance', 'Exceeds Reserves');
  action_labels: array[TAgentAction] of string = (
    'Move', 'Forage', 'Shelter', 'Reproduce', 'Idle'
  );
  status_colors: array[TEditorStatus] of TColor = (clMoneyGreen, clWebCrimson, clWebGray);

{ TConditionEditor }

constructor TConditionEditor.Create(AOwner: TComponent);
begin
  inherited;
  shBorder.ControlStyle := shBorder.ControlStyle + [csClickEvents];
  fCondition := Default(TExplorationCondition);

  cmbKind.Items.BeginUpdate;
  try
    cmbKind.Items.Clear;
    for var k := Low(TExplorationConditionKind) to High(TExplorationConditionKind) do
      cmbKind.Items.Add(condition_kind_labels[k]);
  finally
    cmbKind.Items.EndUpdate;
  end;

  cmbAction.Items.BeginUpdate;
  try
    cmbAction.Items.Clear;
    for var a := Low(TAgentAction) to High(TAgentAction) do
      cmbAction.Items.Add(action_labels[a]);
  finally
    cmbAction.Items.EndUpdate;
  end;

  SetSelected(False);
  cmbKind.ItemIndex := 0;
  UpdateLayout;
  ChangeStatus(esOK);
end;

procedure TConditionEditor.edtParameterChange(Sender: TObject);
begin
  Validate;
end;

function TConditionEditor.GetCondition: TExplorationCondition;
begin
  // only valid when Status = ok
  Assert(Status = esOK);
  Result := fCondition;
end;

function TConditionEditor.MakeParam(const aValue: string; aParamType: TParamType; out IntValue: Integer): Boolean;
begin
  Result := TryStrToInt(aValue, intValue);
end;

function TConditionEditor.MakeParam(const aValue: string; aParamType: TParamType; out FloatValue: Single): Boolean;
begin
  Result := TryStrToFloat(aValue, FloatValue);
end;

function TConditionEditor.MakeParam(const aValue: string; aParamType: TParamType; out PointValue: TPoint): Boolean;
begin
  Result := False;
  var parts := aValue.Split([',']);
  if Length(parts) = 2 then
    Result := TryStrToInt(parts[0], PointValue.X) and TryStrToInt(parts[1], PointValue.Y);
end;

procedure TConditionEditor.SetCondition(const Value: TExplorationCondition);
begin
  fCondition := Value;
  UpdateLayout;
end;

procedure TConditionEditor.SetSelected(const Value: Boolean);
begin
  fSelected := Value;
  if fSelected then
  begin
    shBorder.Pen.Color := StyleServices.GetSystemColor(clHighlight);
    shBorder.Pen.Width := 2;
  end
  else
  begin
    shBorder.Pen.Color := StyleServices.GetSystemColor(clBtnHighlight);
    shBorder.Pen.Width := 1;
  end;
end;

procedure TConditionEditor.shBorderMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(Self.OnClick) then
    Self.OnClick(Self);
end;

procedure TConditionEditor.shStatusMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if fStatus = esDisabled then
  begin
    ChangeStatus(esOK);
    Validate;
  end
  else
    ChangeStatus(esDisabled);
end;

procedure TConditionEditor.cmbActionCloseUp(Sender: TObject);
begin
  fCondition.Action.Action := TAgentAction(cmbAction.ItemIndex);
  UpdateLayout;
  Validate;
end;

procedure TConditionEditor.cmbCacheTypeCloseUp(Sender: TObject);
begin
  Validate;
end;

procedure TConditionEditor.cmbKindCloseUp(Sender: TObject);
begin
  fCondition.Kind := TExplorationConditionKind(cmbKind.ItemIndex);
  if fCondition.Kind = ekActionSelected then
    cmbAction.ItemIndex := 0;
  UpdateLayout;
  Validate;
end;

procedure TConditionEditor.Validate;

  function PointToCellIndex(aPoint: TPoint): TCellIndex;
  begin
    Result := (aPoint.Y * GRID_WIDTH) + aPoint.X;
  end;

begin
  if Status = esDisabled then
    Exit;

  var valid := True;

  // the only place you can do something invalid is in the editor
  if edtParameter.Visible then
  begin
    var param := Trim(edtParameter.Text);

    fCondition.Kind := TExplorationConditionKind(cmbKind.ItemIndex);

    case fCondition.Kind of
      ekBorn: ;
      ekDies: ;
      ekActionSelected:
        begin
          var action := TAgentAction(cmbAction.ItemIndex);
          fCondition.Action.Action := action;
          case action of
            acMove:
              begin
                var p: TPoint;
                valid := MakeParam(param, ptPoint, p);
                if valid then
                begin
                  fCondition.Action.Target.TType := ttCell;
                  fCondition.Action.Target.Cell := PointToCellIndex(p);
                end;
              end;
            acForage:
              begin
                var cacheKind := TCacheKind(cmbCacheType.ItemIndex);
                var intVal: Integer;
                valid := MakeParam(param, ptInteger, intVal);
                if valid then
                begin
                  fCondition.Action.Target.TType := ttCache;
                  fCondition.Action.Target.Cache.Kind := cacheKind;
                  fCondition.Action.Target.Cache.Index := intVal;
                end;
              end;
            acShelter: ;
            acReproduce: ;
            acIdle: ;
          end;
        end;
      ekAwakePastTick,
      ekReachesAge,
      ekTravelsDistance:
        begin
          var intVal: Integer;
          valid := MakeParam(param, ptInteger, intVal);
          if valid then
            fCondition.IntParam := intVal;
        end;
      ekExceedsReserves:
        begin
          var floatVal: Single;
          valid := MakeParam(param, ptFloat, floatVal);
          if valid then
            fCondition.FloatParam := floatVal;
        end;
    end;
  end;

  if not Valid then
    ChangeStatus(esError)
  else
    ChangeStatus(esOK);
end;

procedure TConditionEditor.UpdateLayout;
begin
  // control visibility
  cmbKind.ItemIndex := Ord(fCondition.Kind);

  cmbCacheType.Visible := False;
  edtParameter.Visible := False;
  cmbAction.Visible := fCondition.Kind = ekActionSelected;
  cmbCacheType.Visible := cmbAction.Visible and (cmbAction.ItemIndex = Ord(acForage));
  edtParameter.Visible := cmbCacheType.Visible or
    (cmbAction.Visible and (cmbAction.ItemIndex = Ord(acMove))) or
    (fCondition.Kind in [ekAwakePastTick, ekReachesAge, ekTravelsDistance, ekExceedsReserves]);

  // positioning
  var x := cmbKind.Left + cmbKind.Width + 4;

  if cmbAction.Visible then
  begin
    cmbAction.Left := x;
    Inc(x, cmbAction.Width + 4);
  end;

  if cmbCacheType.Visible then
  begin
    cmbCacheType.Left := x;
    Inc(x, cmbCacheType.Width + 4);
  end;

  if edtParameter.Visible then
    edtParameter.Left := x;
end;

procedure TConditionEditor.ChangeStatus(aStatus: TEditorStatus);
begin
  fStatus := aStatus;
  shStatus.Brush.Color := status_colors[fStatus];
  shStatus.Pen.Color := status_colors[fStatus];

  if fStatus in [esOK, esError] then
    shStatus.Brush.Style := bsSolid
  else
    shStatus.Brush.Style := bsClear;

  if Assigned(fOnStatusChange) then
    fOnStatusChange(Self);
end;


end.
