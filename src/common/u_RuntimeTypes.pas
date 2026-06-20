unit u_RuntimeTypes;

interface

uses u_SimTypes, u_EnvironmentTypes, u_SimQueriesIntf;

type
  TCellIndex = type Integer;

  TDecisionAction = acMove..acReproduce;

  TMoveDirection = (mdNorth, mdNorthEast, mdEast, mdSouthEast, mdSouth, mdSouthWest, mdWest, mdNorthWest);
  TDirections = record
    Direction: TMoveDirection;
    Distance: Word;
  end;


  TTargetType = (ttNone, ttCell, ttCache);
  TTarget = record
    case TType: TTargetType of
      ttNone: ();
      ttCell: (Cell: TCellIndex);
      ttCache: (Cache: TCacheRef);
  end;


  // what the agent detects about a resource cache.
  TSmellDetails = record
    Cache: TCacheRef;
    CellIndex: TCellIndex;
    Directions: TDirections;
    MoleculesPresent: TMolecules;
    MoleculeStrength: array[TMolecule] of Single;
  end;

  TSmellReport = record
    Count: Integer;
    Details: array of TSmellDetails;
  end;

  // Caller-owned workspace reused across ticks for smell scan queries.
  TSmellScanScratch = record
    Buffer: TSmellCacheInfos;
    Count: Integer;
  end;


  TMoleculeFactors = array[TMolecule] of Single;

  TSmellParams = record
    Ratings: TMoleculeFactors;
  end;


  // Self-state observed by the Energy module.
//  TDecisionEnergy = TEnergyLevel; //elLow..elFull;


  TForageOutcome = record
    Consumed: Single;
    Gain: Single;
    Substance: TSubstance;
  end;

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


  // Action-specific evaluator inputs keep evaluator contracts narrow.
  TForageEvalInput = record
    Reserves: Single;
    ReserveDelta: Single;  // per-tick change in reserves; negative = losing energy, positive = gaining
    Smell: TSmellReport;
    MoleculeWeights: TMoleculeFactors;  // learned preference per molecule (initialized to 1.0)
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

  // Caller-owned per-agent scratch state reused across ticks.
  // This keeps the brain stateless while avoiding per-tick temp allocations.
  TAgentScratch = record
    SmellScratch: TSmellScanScratch;
    EvaluatorScratch: TEvaluatorScratch;
    ActionScores: TActionScores;
  end;



implementation

end.
