unit u_Playlists;

interface

uses System.Generics.Collections,
  u_SimTypes, u_SimEventTypes, u_AgentTypes;

type
  TEndAction = (eaContinue, eaStop);

  TSegment = record
    Id: Integer;             // assigned at load
    Enabled: Boolean;
    Recording: Boolean;
    StartTime: TSimDate;
    EndTime: TSimDate;
  end;

  TPlaylist = TList<TSegment>;


implementation

const
  IMMEDIATE: TSimDate = (DayNumber: 0; DayTick: 0);

procedure test;
begin
//  var s: TSegment;
//
//  s.Id := 1;
//  s.Recording := False;
//  s.StartTime := IMMEDIATE;
//

end;

end.
