unit fr_SimStats;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,

  u_SimEventTypes;

type
  TSimStatsFrame = class(TFrame, ISimEventConsumer)
  private
    procedure Consume(const aEvent: TSimEvent);
  public
  end;

implementation

{$R *.dfm}

(*
  TPopulationState = record
    Alive: Integer;
    Dead: Integer;
    Births: Integer;
    LongestLife: TLifespan;
    ShortestLife: TLifespan;
    MaxReserves: TReservespan;
    MaxTravel: TTravelspan; // from state.Birthplace
    MaxLiving: Integer;
  end;


*)

{ TSimStatsFrame }

procedure TSimStatsFrame.Consume(const aEvent: TSimEvent);
begin
  //
end;

end.
