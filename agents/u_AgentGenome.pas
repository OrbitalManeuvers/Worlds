unit u_AgentGenome;

interface

uses System.Generics.Collections,

  u_SimQueriesIntf, u_EnvironmentTypes, u_AgentTypes;

// In this simulated universe, a "gene" is just an upgradable bit of agent that makes them tick. Every tick.

type
  TMoleculeFactors = array[TMolecule] of Single;

  TSmellParams = record
    Range: Single;
    Ratings: TMoleculeFactors;
  end;

  // Caller-owned workspace reused across ticks for smell scan queries.
  TSmellScanScratch = record
    Buffer: TSmellCacheInfos;
    Count: Integer;
  end;

  // Caller-owned workspace reused across ticks for sight scan queries.
  TSightScanScratch = record
    Buffer: TSightInfos;
    Count: Integer;
  end;

  TSensorScanScratch = record
    Smell: TSmellScanScratch;
    Sight: TSightScanScratch;
  end;

  // Self-state observed by the Energy module.
  TEnergyInput = record
    Reserves: Single;
  end;

  // Action-specific evaluator inputs keep evaluator contracts narrow.
  TForageEvalInput = record
    IsNight: Boolean;
    EnergyLevel: TEnergyLevel;
    CurrentAction: TAgentAction;
    Smell: TSmellReport;
  end;

  TMoveEvalInput = record
    IsNight: Boolean;
    EnergyLevel: TEnergyLevel;
    CurrentAction: TAgentAction;
    Smell: TSmellReport;
  end;

  TShelterEvalInput = record
    IsNight: Boolean;
    EnergyLevel: TEnergyLevel;
    CurrentAction: TAgentAction;
    ThreatPressure: Single;
  end;

  TReproduceEvalInput = record
    IsNight: Boolean;
    EnergyLevel: TEnergyLevel;
    CurrentAction: TAgentAction;
  end;

  TActionEvalResult = record
    Score: Single;
    Target: TTarget;
  end;
  TActionEvaluations = array[TAgentAction] of TActionEvalResult;

  TCognitionInput = record
    Context: TDecisionContext;
    ActionEvaluations: TActionEvaluations;
    CurrentTarget: TTarget;
  end;

  TCognitionOutput = record
    RequestedAction: TAgentAction;
    RequestedTarget: TTarget;
  end;

  // Evaluators own their own workspace contract, even when empty for now.
  TForageEvalScratch = record
  end;

  TMoveEvalScratch = record
  end;

  TShelterEvalScratch = record
  end;

  TReproduceEvalScratch = record
  end;

  TCognitionScratch = record
  end;

  TEvaluatorScratch = record
    Forage: TForageEvalScratch;
    Shelter: TShelterEvalScratch;
    Movement: TMoveEvalScratch;
    Reproduce: TReproduceEvalScratch;
    Cognition: TCognitionScratch;
  end;

  TGene = class
  public
    class function GetGenerationCode: Char; virtual; // first gen gets 'A' by default
  end;
  TGeneClass = class of TGene;

  // Energy
  TEnergyGene = class(TGene)
    class function EvaluateEnergyLevel(const Input: TEnergyInput): TEnergyLevel; virtual; abstract;
  end;
  TEnergyGeneClass = class of TEnergyGene;

  // Smell
  TSmellGene = class(TGene)
  public
    class function Scan(Location: Cardinal; const Params: TSmellParams; const Query: ISimQuery;
      var Scratch: TSmellScanScratch): TSmellReport; virtual; abstract;
  end;
  TSmellGeneClass = class of TSmellGene;

  // Sight
  TSightGene = class(TGene)
  public
    class function Scan(Location: Cardinal; Range: Single; const Query: ISimQuery;
      var Scratch: TSightScanScratch): TSightReport; virtual; abstract;
  end;
  TSightGeneClass = class of TSightGene;


  // Move evaluation
  TMoveEvalGene = class(TGene)
    class function Evaluate(const Input: TMoveEvalInput; var Scratch: TMoveEvalScratch): TActionEvalResult; virtual; abstract;
  end;
  TMoveEvalGeneClass = class of TMoveEvalGene;

  // Forage evaluation
  TForageEvalGene = class(TGene)
    class function Evaluate(const Input: TForageEvalInput; var Scratch: TForageEvalScratch): TActionEvalResult; virtual; abstract;
  end;
  TForageEvalGeneClass = class of TForageEvalGene;

  // Shelter evaluation
  TShelterEvalGene = class(TGene)
    class function Evaluate(const Input: TShelterEvalInput; var Scratch: TShelterEvalScratch): TActionEvalResult; virtual; abstract;
  end;
  TShelterEvalGeneClass = class of TShelterEvalGene;

  // Reproduction evaluation
  TReproduceEvalGene = class(TGene)
    class function Evaluate(const Input: TReproduceEvalInput; var Scratch: TReproduceEvalScratch): TActionEvalResult; virtual; abstract;
  end;
  TReproduceEvalGeneClass = class of TReproduceEvalGene;

  // Cognition gene
  TCognitionGene = class(TGene)
    class function Decide(const Input: TCognitionInput; var Scratch: TCognitionScratch): TCognitionOutput; virtual; abstract;
  end;
  TCognitionGeneClass = class of TCognitionGene;

  // Converter gene
  TConverterGene = class(TGene)
  end;
  TConverterGeneClass = class of TConverterGene;


  // part of the agent's genome record
  TGeneMap = record
    Energy: TEnergyGeneClass;
    Smell: TSmellGeneClass;
    Sight: TSightGeneClass;
    MoveEval: TMoveEvalGeneClass;
    ForageEval: TForageEvalGeneClass;
    ShelterEval: TShelterEvalGeneClass;
    ReproduceEval: TReproduceEvalGeneClass;
    Cognition: TCognitionGeneClass;
    Converter: TConverterGeneClass;
  end;

  // record of an agent's gene sequence
  TGeneSequence = record
  private
    Energy: Char;
    Smell: Char;
    Sight: Char;
    Movement: Char;
    Forage: Char;
    Shelter: Char;
    Reproduce: Char;
    Cognition: Char;
    Convert: Char;
    function GetAsText: string;
    procedure SetAsText(const aValue: string);
  public
    property AsText: string read GetAsText write SetAsText;
  end;

  TGeneSequencer = class
  public
    class procedure Populate(var aMap: TGeneMap; const aSequence: TGeneSequence);
    class function GetSequence(const aMap: TGeneMap): TGeneSequence;
  end;

  TGeneRegistry = class
  private
    fRegistry: TDictionary<string, TList<TGeneClass>>;
    function GetClassCategory(aClass: TGeneClass): string;
  public
    constructor Create;
    destructor Destroy; override;

    procedure RegisterGene(aClass: TGeneClass);
    function FindGeneration(aClass: TGeneClass; aGen: Char): TGeneClass;
  end;


  TAgentGenome = record
    // agent's genes
    GeneMap: TGeneMap;

    // Data parameters: continuous variation within a generation
    ConverterRatings: TMoleculeFactors;
    SmellRatings: TMoleculeFactors;
    SmellRange: Single;
    SightRange: Single;
    Metabolism: Single;
  end;


function GlobalGeneRegistry: TGeneRegistry;

implementation

uses System.SysUtils;

var
  _globalRegistry: TGeneRegistry = nil;

function GlobalGeneRegistry: TGeneRegistry;
begin
  if not Assigned(_globalRegistry) then
    _globalRegistry := TGeneRegistry.Create;
  Result := _globalRegistry;
end;

{ TGene }

class function TGene.GetGenerationCode: Char;
begin
  Result := 'A';
end;


{ TGeneRegistry }

constructor TGeneRegistry.Create;
begin
  inherited Create;
  fRegistry := TDictionary<string, TList<TGeneClass>>.Create;
end;

destructor TGeneRegistry.Destroy;
begin
  fRegistry.Free;
  inherited;
end;

function TGeneRegistry.GetClassCategory(aClass: TGeneClass): string;
begin
  var baseClass := TGeneClass.ClassName;

  // find the parent class
  var firstClass: TClass := aClass;
  while Assigned(firstClass) and (firstClass.ClassParent.ClassName <> baseClass) do
    firstClass := firstClass.ClassParent;

  Result := firstClass.ClassName;
end;

function TGeneRegistry.FindGeneration(aClass: TGeneClass; aGen: Char): TGeneClass;
begin
  var category := GetClassCategory(aClass);
  var geneList: TList<TGeneClass>;

  if fRegistry.TryGetValue(category, geneList) then
  begin
    for var geneClass in geneList do
    begin
      // ideally: here we support multiple 'B' for example, and then select one at random. this would allow
      // for multiple implementations of "next tier" genes

      if geneClass.GetGenerationCode = aGen then
      begin
        Result := geneClass;
        Exit;
      end;
    end;
  end;

  Result := aClass; // default to the base class if not found
end;

procedure TGeneRegistry.RegisterGene(aClass: TGeneClass);
begin
  // put aClass into correct bucket
  var category := GetClassCategory(aClass);  // this could be done other ways

  var geneList: TList<TGeneClass>;
  if not fRegistry.TryGetValue(category, geneList) then
  begin
    geneList := TList<TGeneClass>.Create;
    fRegistry.Add(category, geneList);
  end;

  geneList.Add(aClass);
end;


{ TGeneSequence }

function TGeneSequence.getAsText: string;
begin
  Result := Energy + Smell + Sight + Movement + Forage + Shelter + Reproduce +
    Cognition + Convert;
end;

procedure TGeneSequence.setAsText(const aValue: string);
begin
  if aValue.Length = 9 then
  begin
    Energy := aValue[1];
    Smell := aValue[2];
    Sight := aValue[3];
    Movement := aValue[4];
    Forage := aValue[5];
    Shelter := aValue[6];
    Reproduce := aValue[7];
    Cognition := aValue[8];
    Convert := aValue[9];
  end;
end;

{ TGeneSequencer }

class function TGeneSequencer.GetSequence(const aMap: TGeneMap): TGeneSequence;
begin
  Result.Energy := aMap.Energy.GetGenerationCode;
  Result.Smell := aMap.Smell.GetGenerationCode;
  Result.Sight := aMap.Sight.GetGenerationCode;
  Result.Movement := aMap.MoveEval.GetGenerationCode;
  Result.Forage := aMap.ForageEval.GetGenerationCode;
  Result.Shelter := aMap.ShelterEval.GetGenerationCode;
  Result.Reproduce := aMap.ReproduceEval.GetGenerationCode;
  Result.Cognition := aMap.Cognition.GetGenerationCode;
  Result.Convert := aMap.Converter.GetGenerationCode;
end;

class procedure TGeneSequencer.Populate(var aMap: TGeneMap; const aSequence: TGeneSequence);
begin
  var geneClass: TGeneClass;

  // observation
  geneClass := GlobalGeneRegistry.FindGeneration(TEnergyGene, aSequence.Energy);
  aMap.Energy := TEnergyGeneClass(geneClass);

  geneClass := GlobalGeneRegistry.FindGeneration(TSmellGene, aSequence.Smell);
  aMap.Smell := TSmellGeneClass(geneClass);

  geneClass := GlobalGeneRegistry.FindGeneration(TSightGene, aSequence.Sight);
  aMap.Sight := TSightGeneClass(geneClass);

  // evaluation

  geneClass := GlobalGeneRegistry.FindGeneration(TMoveEvalGene, aSequence.Movement);
  aMap.MoveEval := TMoveEvalGeneClass(geneClass);

  // forage
  geneClass := GlobalGeneRegistry.FindGeneration(TForageEvalGene, aSequence.Forage);
  aMap.ForageEval := TForageEvalGeneClass(geneClass);

  // shelter
  geneClass := GlobalGeneRegistry.FindGeneration(TShelterEvalGene, aSequence.Shelter);
  aMap.ShelterEval := TShelterEvalGeneClass(geneClass);

  // decision
  geneClass := GlobalGeneRegistry.FindGeneration(TCognitionGene, aSequence.Cognition);
  aMap.Cognition := TCognitionGeneClass(geneClass);



  // digestion



end;

initialization

finalization

if Assigned(_globalRegistry) then
begin
  _globalRegistry.Free;
end;


end.
