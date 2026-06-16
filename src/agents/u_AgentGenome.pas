unit u_AgentGenome;

interface

uses System.Generics.Collections,

  u_SimQueriesIntf, u_EnvironmentTypes, u_SimEnvironments, u_AgentTypes;

const
  // Shared fit-parent start floor for reproduction. Runtime still owns actual spawning,
  // but evaluators should not ask for reproduction below this legal minimum.
  REPRODUCTION_MIN_ATTEMPT_RESERVES = 6.0;

  GENE_SEQUENCE_LENGTH = 9; // at least for today!

// In this simulated universe, a "gene" is just an upgradable bit of agent that makes them tick. Every tick.

type
  TMoleculeFactors = array[TMolecule] of Single;

  TSmellParams = record
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
    Reserves: Single;
    ReserveDelta: Single;  // per-tick change in reserves; negative = losing energy, positive = gaining
    Smell: TSmellReport;
    MoleculeWeights: TMoleculeFactors;  // learned preference per molecule (initialized to 1.0)
  end;

  TMoveEvalInput = record
    Reserves: Single;
    ReserveDelta: Single;
    Smell: TSmellReport;
    MoleculeWeights: TMoleculeFactors;  // learned preference per molecule — used to judge local food value
  end;

  TShelterEvalInput = record
    CircadianPressure: Single;
    Reserves: Single;
    ReserveDelta: Single;  // per-tick change in reserves; negative = losing energy, positive = gaining
    IsNight: Boolean;
    SolarFlux: Single;     // 0.0 at night, rising through the day
    HasLocalFoodSignal: Boolean;  // food cache at distance 0
  end;

  TReproduceEvalInput = record
    Reserves: Single;
    ReserveDelta: Single;
    TicksSinceReproduction: Integer;
    Age: Integer;
    LocalAgentCount: Integer;
    DeltaWeight: Single;               // learned delta molecule preference; high values suppress reproduction
  end;

  TConverterInput = record
    ConsumedAmount: Single;
    Substance: TSubstance;
    Ratings: TMoleculeFactors;
  end;

  TForageOutcome = record
    Consumed: Single;
    Gain: Single;
    Substance: TSubstance;
  end;

// eval-cleanup
  TForageOption = record
    Cache: TCacheRef;
    CellIndex: TCellIndex;
    Opportunity: Single;   // evaluator-owned quality signal
    Distance: Word;
  end;

  TForageOptionArray = array[0..2] of TForageOption;
  TForageReport = record
    Count: Integer;
    Options: TForageOptionArray;
  end;

  TMoveOption = record
    Cell: TCellIndex;
    Opportunity: Single;   // evaluator-owned quality signal
    Distance: Word;
  end;

  TMoveOptionArray = array[0..2] of TMoveOption;
  TMoveReport = record
    Count: Integer;
    Options: TMoveOptionArray;
  end;
// eval-cleanup ^



  TActionScore = record
    Score: Single;
  end;
  TActionScores = array[TAgentAction] of TActionScore;

  TCognitionInput = record
    Context: TDecisionContext;
    ActionScores: TActionScores;
    CurrentTarget: TTarget;
    Reserves: Single;
    ReserveDelta: Single;
    LastForageCell: TCellIndex;

    ForageReport: TForageReport;
    MoveReport: TMoveReport;
  end;

  TCognitionOutput = record
    RequestedAction: TAgentAction;
    RequestedTarget: TTarget;
  end;

  TCognitionReflectionInput = record
    DecisionBuckets: TDecisionBuckets;
    RequestedAction: TAgentAction;
    RequestedTarget: TTarget;
    ResolvedAction: TAgentAction;
    ResolvedTarget: TTarget;
    Scores: TActionScores;
    ReserveDelta: Single;
    ForageOutcome: TForageOutcome;
    GridWidth: Integer;
    PreviousLocation: Integer;
    CurrentLocation: Integer;
    CurrentReserves: Single;
    ActionProgress: Integer;
  end;

  TCognitionReflectionOutput = record
    LearnedAction: TDecisionAction;
    Outcome: Single;
    ExpectedOutcome: Single;
    PredictionError: Single;
    HasWeightUpdate: Boolean;
    HasMoleculeUpdate: Boolean;
    MoleculeOutcomes: array[TMolecule] of Single;
    MoleculesPresent: TMolecules;
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

  TConverterScratch = record
  end;

  TCognitionScratch = record
  end;

  TReflectionScratch = record
  end;

  TEvaluatorScratch = record
    Forage: TForageEvalScratch;
    Shelter: TShelterEvalScratch;
    Movement: TMoveEvalScratch;
    Reproduce: TReproduceEvalScratch;
    Cognition: TCognitionScratch;
    Reflection: TReflectionScratch;
  end;

  TGene = class
  public
    class function GetGenerationCode: Char; virtual; // first gen gets 'A' by default
  end;
  TGeneClass = class of TGene;

  // ===================
  // Observation Genes
  // ===================

  // Energy
  TEnergyGene = class(TGene)
    class function EvaluateEnergyLevel(const Input: TEnergyInput): TEnergyLevel; virtual; abstract;
  end;
  TEnergyGeneClass = class of TEnergyGene;

  // Smell
  TSmellGene = class(TGene)
  public
    class function Scan(Location: Integer; const Params: TSmellParams; const Query: ISimQuery;
      var Scratch: TSmellScanScratch): TSmellReport; virtual; abstract;
  end;
  TSmellGeneClass = class of TSmellGene;

  // Sight
  TSightGene = class(TGene)
  public
    class function Scan(Location: Integer; Range: Single; const Query: ISimQuery;
      var Scratch: TSightScanScratch): TSightReport; virtual; abstract;
  end;
  TSightGeneClass = class of TSightGene;


  // ===================
  // Evaluation Genes
  // ===================

  // Move evaluation
  TMoveEvalGene = class(TGene)
    class function BuildReport(const Input: TMoveEvalInput; var Scratch: TMoveEvalScratch): TMoveReport; virtual; abstract;
  end;
  TMoveEvalGeneClass = class of TMoveEvalGene;

  // Forage evaluation
  TForageEvalGene = class(TGene)
    class function BuildReport(const Input: TForageEvalInput; var Scratch: TForageEvalScratch): TForageReport; virtual; abstract;
  end;
  TForageEvalGeneClass = class of TForageEvalGene;

  // Shelter evaluation
  TShelterEvalGene = class(TGene)
    class function Evaluate(const Input: TShelterEvalInput; var Scratch: TShelterEvalScratch): TActionScore; virtual; abstract;
  end;
  TShelterEvalGeneClass = class of TShelterEvalGene;

  // Reproduction evaluation
  TReproduceEvalGene = class(TGene)
    class function Evaluate(const Input: TReproduceEvalInput; var Scratch: TReproduceEvalScratch): TActionScore; virtual; abstract;
    class function MinimumAge: Integer; virtual; abstract;
  end;
  TReproduceEvalGeneClass = class of TReproduceEvalGene;

  // ===================
  // Cognition Gene
  // ===================

  TCognitionGene = class(TGene)
    class function Decide(const Input: TCognitionInput; var Scratch: TCognitionScratch): TCognitionOutput; virtual; abstract;
    class function Reflect(const Input: TCognitionReflectionInput; var Scratch: TReflectionScratch): TCognitionReflectionOutput; virtual; abstract;
  end;
  TCognitionGeneClass = class of TCognitionGene;

  // ===================
  // Converter Gene
  // ===================
  TConverterGene = class(TGene)
    class function Convert(const Input: TConverterInput; var Scratch: TConverterScratch): Single; virtual; abstract;
  end;
  TConverterGeneClass = class of TConverterGene;


  TGeneSlotFlag = (gsfAlwaysOn);
  TGeneSlotFlags = set of TGeneSlotFlag;

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
    function SumGenerationCost(const aCostPerGeneration: Single;
      const aRequiredFlags: TGeneSlotFlags = [];
      const aExcludedFlags: TGeneSlotFlags = []): Single;
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
    procedure Init;
    property AsText: string read GetAsText write SetAsText;
    property CognitionGen: Char read Cognition write Cognition;
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
    ForageMoleculeWeights: TMoleculeFactors;  // learned preference per molecule
    ConverterRatings: TMoleculeFactors;
    SmellRatings: TMoleculeFactors;
//    SightRange: Single;
  end;


function GlobalGeneRegistry: TGeneRegistry;

implementation

uses System.SysUtils, System.StrUtils;

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

{ TGeneMap }

function TGeneMap.SumGenerationCost(const aCostPerGeneration: Single;
  const aRequiredFlags: TGeneSlotFlags; const aExcludedFlags: TGeneSlotFlags): Single;

  function GeneGenerationCost(aGeneClass: TGeneClass): Single;
  begin
    if not Assigned(aGeneClass) then
      Exit(0.0);

    Result := (Ord(aGeneClass.GetGenerationCode) - Ord('A')) * aCostPerGeneration;
    if Result < 0.0 then
      Result := 0.0;
  end;

  procedure AddSlot(aGeneClass: TGeneClass; const aFlags: TGeneSlotFlags);
  begin
    if (aRequiredFlags - aFlags) <> [] then
      Exit;

    if (aFlags * aExcludedFlags) <> [] then
      Exit;

    Result := Result + GeneGenerationCost(aGeneClass);
  end;
begin
  Result := 0.0;

  AddSlot(Energy, [gsfAlwaysOn]);
  AddSlot(Smell, []);
  AddSlot(Sight, []);
  AddSlot(MoveEval, []);
  AddSlot(ForageEval, []);
  AddSlot(ShelterEval, [gsfAlwaysOn]);
  AddSlot(ReproduceEval, []);
  AddSlot(Cognition, [gsfAlwaysOn]);
  AddSlot(Converter, []);
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
  Assert(Result.Length = GENE_SEQUENCE_LENGTH);
end;

procedure TGeneSequence.Init;
begin
  setAsText(System.StrUtils.DupeString('A', GENE_SEQUENCE_LENGTH));
end;

procedure TGeneSequence.setAsText(const aValue: string);
begin
  Assert(aValue.Length = GENE_SEQUENCE_LENGTH);

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

  // reproduction
  geneClass := GlobalGeneRegistry.FindGeneration(TReproduceEvalGene, aSequence.Reproduce);
  aMap.ReproduceEval := TReproduceEvalGeneClass(geneClass);

  // decision
  geneClass := GlobalGeneRegistry.FindGeneration(TCognitionGene, aSequence.Cognition);
  aMap.Cognition := TCognitionGeneClass(geneClass);

  // converter
  geneClass := GlobalGeneRegistry.FindGeneration(TConverterGene, aSequence.Convert);
  aMap.Converter := TConverterGeneClass(geneClass);
end;

initialization

finalization

if Assigned(_globalRegistry) then
begin
  _globalRegistry.Free;
end;


end.
