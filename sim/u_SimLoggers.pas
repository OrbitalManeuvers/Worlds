unit u_SimLoggers;

interface

uses System.Classes, System.Types,

  u_Simulators, u_SimEnvironments, u_EnvironmentTypes;

type
  TLogger = class;
  TLogEvent = procedure (Sender: TLogger; const aMsg: string) of object;

  TLogger = class
  private
    fOnLog: TLogEvent;
    fOnBeginOutput: TNotifyEvent;
    fOnEndOutput: TNotifyEvent;
  protected
    procedure BeginOutput;
    procedure EndOutput;
  public

    procedure Log(const aMsg: string); overload;
    procedure Log(const aMsg: string; const aParams: array of const); overload;

    property OnLog: TLogEvent read fOnLog write fOnLog;
    property OnBeginOutput: TNotifyEvent read fOnBeginOutput write fOnBeginOutput;
    property OnEndOutput: TNotifyEvent read fOnEndOutput write fOnEndOutput;
  end;

  TSimLogger = class(TLogger)
  private
    fSim: TSimulator;
    fFieldSpacing: Integer;
    fFields: TStrings;
    procedure LogFields;
  protected
    property Sim: TSimulator read fSim;
    property Fields: TStrings read fFields;
  public
    constructor Create(const Simulator: TSimulator);
    destructor Destroy; override;

    procedure LogCell(ACell: TPoint);
    procedure LogSubstances;

    { options }
    property FieldSpacing: Integer read fFieldSpacing write fFieldSpacing;
  end;


implementation

uses System.SysUtils, System.StrUtils;

function SubstanceToStr(const sub: TSubstance): string;
const
  mchars: array[TMolecule] of char = ('A', 'B', 'G', 'X');
begin
  Result := '';
  for var m := Low(TMolecule) to High(TMolecule) do
  begin
    Result := Result + mchars[m];
    var digit := sub[m] div 10;
    var s := '';
    if digit = 0 then s := '.'
    else if digit = 10 then s := '!'
    else s := digit.ToString;
    Result := Result + s[1];
  end;
end;

{ TLogger }

procedure TLogger.BeginOutput;
begin
  if Assigned(fOnBeginOutput) then
    fOnBeginOutput(Self);
end;

procedure TLogger.EndOutput;
begin
  if Assigned(fOnEndOutput) then
    fOnEndOutput(Self);
end;

procedure TLogger.Log(const aMsg: string; const aParams: array of const);
begin
  Log(Format(aMsg, aParams));
end;

procedure TLogger.Log(const aMsg: string);
begin
  if Assigned(fOnLog) then
    fOnLog(Self, aMsg);
end;

{ TSimLogger }

constructor TSimLogger.Create(const Simulator: TSimulator);
begin
  inherited Create;
  fSim := Simulator;
  fFields := TStringList.Create(dupAccept, False, False);
  fFieldSpacing := 2;
end;

destructor TSimLogger.Destroy;
begin
  fFields.Free;
  inherited;
end;

procedure TSimLogger.LogCell(ACell: TPoint);
begin
  BeginOutput;
  try
    Fields.Clear;
    var simSizeX := Sim.Runtime.Environment.Dimensions.cx;
    var cellIndex := (ACell.Y * simSizeX) + ACell.X;

    // sim time
    Fields.Add(Format('[%.02d:%.04d]', [Sim.Clock.DayNumber, Sim.Clock.Tick]));

    // solar flux
    Fields.Add(Format('[%.06f]', [Sim.Runtime.Environment.SolarFlux]));

    // cell number
    Fields.Add(Format('[%.03d:%.03d]', [ACell.X, ACell.Y]));

    // resources
    var resCount := Sim.Runtime.Environment.Cells[cellIndex].ResourceCount;

    if resCount > 0 then
    begin
      var resStart := Sim.Runtime.Environment.Cells[cellIndex].ResourceStart;
      for var j := 0 to resCount - 1 do
      begin
        var resIndex := resStart + j;

        var substanceIndex := Sim.Runtime.Environment.Resources[resIndex].SubstanceIndex;
        var amount := Sim.Runtime.Environment.Resources[resIndex].Amount;
        Fields.Add(Format('%.02d [%.02d %.06f]', [j, substanceIndex, amount]));
      end;
    end;

    LogFields;

  finally
    EndOutput;
  end;

end;

procedure TSimLogger.LogFields;
begin
  var spaces := System.StrUtils.DupeString(' ', fFieldSpacing);
  var s := '';
  for var field in fFields do
    s := s + field + spaces;
  SetLength(s, s.Length - spaces.Length);
  Log(s);
  Fields.Clear;
end;

procedure TSimLogger.LogSubstances;
begin
  for var i := 0 to Length(Sim.Runtime.Environment.Substances) - 1 do
    Log('[%.02d %s]', [i, SubstanceToStr(Sim.Runtime.Environment.Substances[i])]);

end;

end.
