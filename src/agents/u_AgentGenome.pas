unit u_AgentGenome;

interface

uses System.Generics.Collections,

  u_SimTypes, u_RunTimeTypes, u_EnvironmentTypes, u_SimEnvironments,
  u_GeneTypes;

const
  // Shared fit-parent start floor for reproduction. Runtime still owns actual spawning,
  // but evaluators should not ask for reproduction below this legal minimum.
  REPRODUCTION_MIN_ATTEMPT_RESERVES = 6.0;

  GENE_SEQUENCE_LENGTH = 8; // at least for today!

// In this simulated universe, a "gene" is just an upgradable bit of agent that makes them tick. Every tick.

type

// ------ should begin here




  // record of an agent's gene sequence
  TGeneSequence = record
  private
    Energy: Char;
    Smell: Char;
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
    // agent's genes — stored as a compact sequence, resolved to class pointers at tick time
    Sequence: TGeneSequence;

    // Data parameters: continuous variation within a generation
    ForageMoleculeWeights: TMoleculeFactors;  // learned preference per molecule
    ConverterRatings: TMoleculeFactors;
    SmellRatings: TMoleculeFactors;
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
  Result := Energy + Smell + Movement + Forage + Shelter + Reproduce +
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
  Movement := aValue[3];
  Forage := aValue[4];
  Shelter := aValue[5];
  Reproduce := aValue[6];
  Cognition := aValue[7];
  Convert := aValue[8];
end;

{ TGeneSequencer }

class function TGeneSequencer.GetSequence(const aMap: TGeneMap): TGeneSequence;
begin
  Result.Energy := aMap.Energy.GetGenerationCode;
  Result.Smell := aMap.Smell.GetGenerationCode;
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

  // move evaluation
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
