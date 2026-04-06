unit u_AgentTypes;

interface

uses System.Types,

  u_EnvironmentTypes;

type
  TAgentAction = (acMove, acForage, acShelter, acReproduce, acIdle);

  TEnergyLevel = (elEmpty, elLow, elMedium, elHigh, elFull);

  TTargetType = (ttCell, ttCache);
  TTarget = record
    case TType: TTargetType of
      ttCell: (Cell: Integer);
      ttCache: (CacheId: Integer);
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
    CacheId: Integer;
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

    EnergyLevel: TEnergyLevel;
    Smell: TSmellReport;
    Sight: TSightReport;

    // evaluator scores

    CurrentAction: TAgentAction;
  end;


implementation



end.
