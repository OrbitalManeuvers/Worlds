unit u_AgentTypes;

interface

uses System.Types,

  u_EnvironmentTypes;

type
  TAgentId = type Integer;
  TCellIndex = type Integer;

  TAgentAction = (acMove, acForage, acShelter, acReproduce, acIdle);
  TDecisionAction = acMove..acReproduce;

  TEnergyLevel = (elEmpty, elLow, elMedium, elHigh, elFull);
  TDecisionEnergy = elLow..elFull;

  TDecisionFoodSignal = (dfsNone, dfsWeak, dfsStrong);
  TDecisionDayPhase = (ddDay, ddNight);

  TDecisionBuckets = record
    Energy: TDecisionEnergy;
    FoodSignal: TDecisionFoodSignal;
    DayPhase: TDecisionDayPhase;
  end;

  TCacheKind = (ckResource, ckDelta);
  TCacheRef = record
    Kind: TCacheKind;
    Index: Integer;
  end;

  TTargetType = (ttNone, ttCell, ttCache, ttWander);
  TTarget = record
    case TType: TTargetType of
      ttNone, ttWander: ();
      ttCell: (Cell: TCellIndex);
      ttCache: (Cache: TCacheRef);
  end;

  TMoveDirection = (mdNorth, mdNorthEast, mdEast, mdSouthEast, mdSouth, mdSouthWest, mdWest, mdNorthWest);
  TDirections = record
    Direction: TMoveDirection;
    Distance: Word;
  end;

  TSightDetails = record
    // consider what else can be "seen" about agents
    Directions: TDirections;
  end;

  TSightReport = record
    Count: Integer;
    Details: array of TSightDetails;
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

  TDecisionContext = record
    Location: Integer;
    IsNight: Boolean;
    SolarFlux: Single;
    SolarFluxDelta: Single;

    EnergyLevel: TEnergyLevel;
    Smell: TSmellReport;
    Sight: TSightReport;

    // evaluator scores

    CurrentAction: TAgentAction;
    CurrentActionAge: Integer;
  end;


implementation



end.
