unit u_BrainTypes;

interface

uses
  u_SimTypes, u_SimQueriesIntf, u_RuntimeTypes, u_EnvironmentTypes;

type

  TDecisionFoodSignal = (dfsNone, dfsWeak, dfsStrong);
  TDecisionDayPhase = (ddDay, ddNight);


  TDecisionBuckets = record
    Energy: TDecisionEnergy;
    FoodSignal: TDecisionFoodSignal;
    DayPhase: TDecisionDayPhase;
  end;

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
    CurrentActionProgress: Integer;

    // Smell retained for move-target anchor lookup
    Smell: TSmellReport;
    ForageReport: TForageReport;
    MoveReport: TMoveReport;
  end;

  TCognitionOutput = record
    RequestedAction: TAgentAction;
    RequestedTarget: TTarget;
    DampenedScores: TActionScores;
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

  // Result returned by the brain to the population/sim tick routine.
  TBrainTickOutput = record
    RequestedAction: TAgentAction;
    RequestedTarget: TTarget;
    Scores: TActionScores;
    DampenedScores: TActionScores;
    DecisionBuckets: TDecisionBuckets;
    CognitionInput: TCognitionInput;
  end;


implementation



end.
