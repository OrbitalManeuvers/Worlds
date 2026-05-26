unit u_Playlists;

interface

uses System.Generics.Collections,
  u_SimTypes, u_SimEventTypes;

type
  TSegment = record
    StartTime: TSimDate;
    EndTime: TSimDate;
    EndEvents: TSimEventKinds;  // empty = time-only end condition
    Recording: Boolean;
  end;

  TPlaylist = TList<TSegment>;


implementation

end.
