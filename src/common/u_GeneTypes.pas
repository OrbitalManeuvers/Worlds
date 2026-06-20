unit u_GeneTypes;

interface

uses u_BrainTypes, u_SimTypes, u_RuntimeTypes, u_EnvironmentTypes, u_SimQueriesIntf;

type
  TGeneSlotFlag = (gsfAlwaysOn);
  TGeneSlotFlags = set of TGeneSlotFlag;

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
    class function EvaluateEnergyLevel(const Input: TEnergyReserves): TEnergyLevel; virtual; abstract;
  end;
  TEnergyGeneClass = class of TEnergyGene;

  // Smell
  TSmellGene = class(TGene)
  public
    class function Scan(Location: Integer; const Params: TSmellParams; const Query: ISimQuery;
      var Scratch: TSmellScanScratch): TSmellReport; virtual; abstract;
  end;
  TSmellGeneClass = class of TSmellGene;

  // ===================
  // Evaluation Genes
  // ===================
  TMoveEvalInput = record
    Reserves: Single;
    ReserveDelta: Single;
    Smell: TSmellReport;
    MoleculeWeights: TMoleculeFactors;  // learned preference per molecule — used to judge local food value
  end;

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
  TShelterEvalInput = record
    CircadianPressure: Single;
    Reserves: Single;
    ReserveDelta: Single;  // per-tick change in reserves; negative = losing energy, positive = gaining
    SolarFlux: Single;     // 0.0 at night, rising through the day
    HasLocalFoodSignal: Boolean;  // food cache at distance 0
  end;

  TShelterEvalGene = class(TGene)
    class function Evaluate(const Input: TShelterEvalInput; var Scratch: TShelterEvalScratch): TActionScore; virtual; abstract;
  end;
  TShelterEvalGeneClass = class of TShelterEvalGene;

  // Reproduction evaluation
  TReproduceEvalInput = record
    Reserves: Single;
    ReserveDelta: Single;
    TicksSinceReproduction: Integer;
    Age: Integer;
    LocalAgentCount: Integer;
    DeltaWeight: Single;               // learned delta molecule preference; high values suppress reproduction
  end;

  TReproduceEvalGene = class(TGene)
    class function Evaluate(const Input: TReproduceEvalInput; var Scratch: TReproduceEvalScratch): TActionScore; virtual; abstract;
    class function MinimumAge: Integer; virtual; abstract;
  end;
  TReproduceEvalGeneClass = class of TReproduceEvalGene;

  // ===================
  // Cognition Gene
  // ===================
  TCognitionInput = record
    ActionScores: TActionScores;
    Reserves: Single;
    ReserveDelta: Single;
    CircadianPressure: Single;
    LastForageCell: TCellIndex;

    // Agent state context for cognition decisions
    Location: TCellIndex;
    CurrentAction: TAgentAction;
    CurrentTarget: TTarget;
    CurrentActionAge: Integer;
    ActionProgress: Integer;

    // Smell retained for move-target anchor lookup
    Smell: TSmellReport;
    ForageReport: TForageReport;
    MoveReport: TMoveReport;
  end;


  TCognitionGene = class(TGene)
    class function Decide(const Input: TCognitionInput; var Scratch: TCognitionScratch): TCognitionOutput; virtual; abstract;
    class function Reflect(const Input: TCognitionReflectionInput; var Scratch: TReflectionScratch): TCognitionReflectionOutput; virtual; abstract;
  end;
  TCognitionGeneClass = class of TCognitionGene;

  // ===================
  // Converter Gene
  // ===================
  TConverterInput = record
    ConsumedAmount: Single;
    Substance: TSubstance;
    Ratings: TMoleculeFactors;
  end;

  TConverterGene = class(TGene)
    class function Convert(const Input: TConverterInput; var Scratch: TConverterScratch): Single; virtual; abstract;
  end;
  TConverterGeneClass = class of TConverterGene;

  // part of the agent's genome record
  TGeneMap = record
    Energy: TEnergyGeneClass;
    Smell: TSmellGeneClass;
    MoveEval: TMoveEvalGeneClass;
    ForageEval: TForageEvalGeneClass;
    ShelterEval: TShelterEvalGeneClass;
    ReproduceEval: TReproduceEvalGeneClass;
    Cognition: TCognitionGeneClass;
    Converter: TConverterGeneClass;
  end;

implementation

{ TGene }

class function TGene.GetGenerationCode: Char;
begin
  Result := 'A';
end;

end.
