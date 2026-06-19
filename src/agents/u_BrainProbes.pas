unit u_BrainProbes;

interface

uses System.Generics.Collections,
  u_AgentTypes, u_AgentGenome;

type
  TBrainSnapshot = record
    AgentId: TAgentId;

    // Observation phase
    DecisionContext: TDecisionContext;

    // Evaluation phase
    ForageReport: TForageReport;
    MoveReport: TMoveReport;
    RawScores: TActionScores;
    WeightedScores: TActionScores;

    // Cognition phase
    CognitionInput: TCognitionInput;
    FinalAction: TAgentAction;
    FinalTarget: TTarget;
  end;

  TBrainProbe = class
  private
    fActive: Boolean;
    fSnapshots: TDictionary<TAgentId, TBrainSnapshot>;
  public
    S: TBrainSnapshot;  // live workspace — brain writes here during tick

    constructor Create;
    destructor Destroy; override;

    procedure Watch(aAgentId: TAgentId);
    procedure Unwatch(aAgentId: TAgentId);
    function IsWatching(aAgentId: TAgentId): Boolean;

    procedure BeforeTick(aAgentId: TAgentId);
    procedure AfterTick(aAgentId: TAgentId);

    function GetSnapshot(aAgentId: TAgentId): TBrainSnapshot;

    property Active: Boolean read fActive;
  end;


implementation

{ TBrainProbe }

constructor TBrainProbe.Create;
begin
  inherited Create;
  fSnapshots := TDictionary<TAgentId, TBrainSnapshot>.Create;
  fActive := False;
end;

destructor TBrainProbe.Destroy;
begin
  fSnapshots.Free;
  inherited;
end;

procedure TBrainProbe.Watch(aAgentId: TAgentId);
begin
  if not fSnapshots.ContainsKey(aAgentId) then
    fSnapshots.Add(aAgentId, Default(TBrainSnapshot));
end;

procedure TBrainProbe.Unwatch(aAgentId: TAgentId);
begin
  fSnapshots.Remove(aAgentId);
end;

function TBrainProbe.IsWatching(aAgentId: TAgentId): Boolean;
begin
  Result := fSnapshots.ContainsKey(aAgentId);
end;

procedure TBrainProbe.BeforeTick(aAgentId: TAgentId);
begin
  fActive := fSnapshots.ContainsKey(aAgentId);
  if fActive then
  begin
    S := Default(TBrainSnapshot);
    S.AgentId := aAgentId;
  end;
end;

procedure TBrainProbe.AfterTick(aAgentId: TAgentId);
begin
  if fActive then
    fSnapshots.AddOrSetValue(aAgentId, S);
  fActive := False;
end;

function TBrainProbe.GetSnapshot(aAgentId: TAgentId): TBrainSnapshot;
begin
  if not fSnapshots.TryGetValue(aAgentId, Result) then
    Result := Default(TBrainSnapshot);
end;

end.
