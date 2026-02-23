unit fr_WorldFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Buttons,
  PngSpeedButton, Vcl.ExtCtrls,

  fr_ContentFrames,
  u_Worlds;

type
  TContentFrameType = (cfFood, cfBiomes, cfRegions, cfWorlds, cfSimulator);

  TWorldFrame = class(TFrame)
    pnlTaskbar: TPanel;
    btnFood: TPngSpeedButton;
    btnBiomes: TPngSpeedButton;
    btnWorlds: TPngSpeedButton;
    btnSimulator: TPngSpeedButton;
    btnRegions: TPngSpeedButton;
    procedure EditorButtonClick(Sender: TObject);
  private
    fWorld: TWorld;
    fActiveFrameType: TContentFrameType;
    fContentFrames: array[TContentFrameType] of TContentFrame;
    procedure SetWorld(const Value: TWorld);
    procedure ActivateContent(FrameType: TContentFrameType);
  public
    constructor Create(AOwner: TComponent); override;
    property World: TWorld write SetWorld;
  end;

implementation

{$R *.dfm}

uses
  Vcl.GraphUtil, Vcl.Themes,

  fr_FoodEditor;

const
  FrameClass: array[TContentFrameType] of TContentFrameClass = (
    TFoodEditor,
    nil,
    nil,
    nil,
    nil
  );

{ TWorldFrame }

constructor TWorldFrame.Create(AOwner: TComponent);

  procedure C(B: TSpeedButton; F: TContentFrameType);
  begin
    B.Tag := Ord(F);
  end;

begin
  inherited;
  pnlTaskbar.StyleElements := pnlTaskbar.StyleElements - [seClient];
  pnlTaskbar.Color := GetHighlightColor(StyleServices.GetSystemColor(clBtnFace), 8);

  // this could be done in the form designer but I dislike enum->int, so we'll minimize that
  C(btnFood, cfFood);
  C(btnBiomes, cfBiomes);
  C(btnRegions, cfRegions);
  C(btnWorlds, cfWorlds);
  C(btnSimulator, cfSimulator);

  for var cf := Low(TContentFrameType) to High(TContentFrameType) do
    fContentFrames[cf] := nil;

  // make sure we detect a change on startup
  fActiveFrameType := High(TContentFrameType);
end;

procedure TWorldFrame.EditorButtonClick(Sender: TObject);
begin
  if Sender is TComponent then
  begin
    var frameType := TContentFrameType(TComponent(Sender).Tag);
    ActivateContent(frameType);
  end;
end;

procedure TWorldFrame.SetWorld(const Value: TWorld);
begin
  fWorld := Value;
  ActivateContent(Low(TContentFrameType));
end;

procedure TWorldFrame.ActivateContent(FrameType: TContentFrameType);
begin
  if FrameType <> fActiveFrameType then
  begin
    // hide the currently active frame
    if Assigned(fContentFrames[fActiveFrameType]) then
      fContentFrames[fActiveFrameType].Hide;

    fActiveFrameType := FrameType;
    if FrameClass[FrameType] = nil then
      Exit;

    if not Assigned(fContentFrames[fActiveFrameType]) then
    begin
      var frame := FrameClass[fActiveFrameType].Create(Self);
      frame.Align := alClient;
      frame.Parent := Self;
      frame.World := fWorld;
      fContentFrames[fActiveFrameType] := frame;
    end;

    fContentFrames[fActiveFrameType].Show;
  end;

end;


end.
