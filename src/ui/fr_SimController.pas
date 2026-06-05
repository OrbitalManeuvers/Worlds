unit fr_SimController;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.ImageList,
  Vcl.ImgList, PngImageList, PngSpeedButton, Vcl.Buttons, Vcl.ExtCtrls,
  Vcl.StdCtrls,

  u_SimControllers, u_SimTypes;

type
  TControllerFrame = class(TFrame)
    btnRecord: TPngSpeedButton;
    ilController: TPngImageList;
    btnStep: TPngSpeedButton;
    btnRun5: TPngSpeedButton;
    btnRun10: TPngSpeedButton;
    btnSunset: TPngSpeedButton;
    btnSunrise: TPngSpeedButton;
    lblClock: TLabel;
    Shape1: TShape;
    Shape3: TShape;
    btnScratch: TSpeedButton;
    procedure btnStepClick(Sender: TObject);
    procedure btnRun5Click(Sender: TObject);
    procedure btnRun10Click(Sender: TObject);
    procedure btnSunsetClick(Sender: TObject);
    procedure btnSunriseClick(Sender: TObject);
    procedure btnRecordClick(Sender: TObject);
    procedure btnPlayClick(Sender: TObject);
    procedure btnScratchClick(Sender: TObject);
  private
    fOnBeforeRun: TNotifyEvent;
    fOnAfterRun: TNotifyEvent;
    fOnRecordingChange: TNotifyEvent;
  private
    fController: TSimController;
    fOnScratchChange: TNotifyEvent;
    procedure SetController(const Value: TSimController);
    procedure UpdateClockDisplay;
    procedure RunToDate(aDate: TSimDate);
    function GetRecording: Boolean;
    function GetScratchEnabled: Boolean;
    procedure SetScratchEnabled(const Value: Boolean);
    procedure BeforeRun;
    procedure AfterRun;
  public
    property Controller: TSimController read fController write SetController;
    property Recording: Boolean read GetRecording;
    property ScratchEnabled: Boolean read GetScratchEnabled write SetScratchEnabled;

    property OnBeforeRun: TNotifyEvent read fOnBeforeRun write fOnBeforeRun;
    property OnAfterRun: TNotifyEvent read fOnAfterRun write fOnAfterRun;
    property OnScratchChange: TNotifyEvent read fOnScratchChange write fOnScratchChange;
  end;

implementation

{$R *.dfm}

uses u_SimClocks, u_Playlists;

{ TControllerFrame }

procedure TControllerFrame.btnPlayClick(Sender: TObject);
begin
  //
end;

procedure TControllerFrame.btnRecordClick(Sender: TObject);
begin
  if Assigned(fOnRecordingChange) then
    fOnRecordingChange(Self);
end;

procedure TControllerFrame.btnRun10Click(Sender: TObject);
begin
  RunToDate(fController.CurrentDate.AddTicks(10));
end;

procedure TControllerFrame.btnRun5Click(Sender: TObject);
begin
  RunToDate(fController.CurrentDate.AddTicks(5));
end;

procedure TControllerFrame.btnScratchClick(Sender: TObject);
begin
  if Assigned(fOnScratchChange) then
    fOnScratchChange(Self);
end;

procedure TControllerFrame.btnStepClick(Sender: TObject);
begin
  RunToDate(fController.CurrentDate.AddTicks(1));
end;

procedure TControllerFrame.btnSunriseClick(Sender: TObject);
begin
  RunToDate(fController.CurrentDate.NextSunrise);
end;

procedure TControllerFrame.btnSunsetClick(Sender: TObject);
begin
  RunToDate(fController.CurrentDate.NextSunset);
end;

function TControllerFrame.GetRecording: Boolean;
begin
  Result := btnRecord.Down;
end;

function TControllerFrame.GetScratchEnabled: Boolean;
begin
  Result := btnScratch.Down;
end;

procedure TControllerFrame.BeforeRun;
begin
  if Assigned(fOnBeforeRun) then
    fOnBeforeRun(Self);
end;

procedure TControllerFrame.AfterRun;
begin
  UpdateClockDisplay;
  if Assigned(fOnAfterRun) then
    fOnAfterRun(Self);
end;

procedure TControllerFrame.RunToDate(aDate: TSimDate);
begin
  var playlist := TPlaylist.Create;
  try
    var seg := Default(TSegment);
    seg.StartTime  := fController.CurrentDate;
    seg.EndTime    := aDate;
//    seg.EndEvents  := [];
    seg.Recording  := btnRecord.Down;
    playlist.Add(seg);

    // allow clients to freeze UI updates
    BeforeRun;
    try
      fController.RunPlaylist(playlist);
    finally
      AfterRun;
    end;

  finally
    playlist.Free;
  end;
end;

procedure TControllerFrame.SetController(const Value: TSimController);
begin
  fController := Value;
  UpdateClockDisplay;
end;

procedure TControllerFrame.SetScratchEnabled(const Value: Boolean);
begin
  btnScratch.Down := Value;
end;

procedure TControllerFrame.UpdateClockDisplay;
begin
  if not Assigned(fController) then
    Exit;
  lblClock.Caption := Format('%.03d:%.03d', [fController.CurrentDate.DayNumber,
    fController.CurrentDate.DayTick]);
end;

end.
