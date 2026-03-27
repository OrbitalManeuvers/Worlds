unit u_AgentTypes;

interface

uses System.Types,

  u_EnvironmentTypes;

type
  TAgentAction = (acMove, acForage, acShelter, acReproduce, acIdle);

  TEnergyLevel = (elEmpty, elLow, elMedium, elHigh, elFull);

  TTargetType = (ttCell, ttCache);
  TAgentTarget = record
    case TType: TTargetType of
      ttCell: (Cell: Cardinal);
      ttCache: (CacheId: Cardinal)
  end;

  TMoveDirection = (mdNorth, mdNorthEast, mdEast, mdSouthEast, mdSouth, mdSouthWest, mdWest, mdNorthWest);
  TDirections = record
    Direction: TMoveDirection;
    Distance: Word;
  end;

  TSightDetails = record
    Directions: TDirections;
  end;

  TSightReport = record
    Count: Integer;
    Details: array of TSightDetails;
  end;

  // what the agent detects about a resource cache.
  // not all gene levels can fill in all fields
  TSmellDetails = record
    Directions: TDirections;
    MoleculesPresent: TMolecules;
    MoleculeStrength: array[TMolecule] of Single;
  end;

  TSmellReport = record
    Count: Integer;
    Details: array of TSmellDetails;
  end;

  TDecisionContext = record
    Location: Cardinal;
    IsNight: Boolean;

    Reserves: TEnergyLevel;
    Smell: TSmellReport;
    Sight: TSightReport;

    // evaluator scores

    CurrentAction: TAgentAction;
  end;


implementation



end.
