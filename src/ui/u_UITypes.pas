unit u_UITypes;

interface

uses System.Classes, System.SysUtils, System.JSON, Vcl.Graphics,
  u_Environment.Types;

type
  // low-res, easy, relative scoring
  TRating = (Worst, Horrible, Bad, Normal, Good, Great, Best);
  TPercentage = 0 .. 100;

type
  TBiomeColorPalette = array[TBiomeMarker] of TColor;


implementation

end.
