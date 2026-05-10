unit fr_SimController;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.ImageList,
  Vcl.ImgList, PngImageList, PngSpeedButton, Vcl.Buttons, Vcl.ExtCtrls,
  Vcl.StdCtrls,

  u_SimControllers;

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
    Shape2: TShape;
    Shape3: TShape;
    procedure btnStepClick(Sender: TObject);
    procedure btnRun5Click(Sender: TObject);
    procedure btnRun10Click(Sender: TObject);
    procedure btnSunsetClick(Sender: TObject);
    procedure btnSunriseClick(Sender: TObject);
    procedure btnRecordClick(Sender: TObject);
  private
    fOnBeforeRun: TNotifyEvent;
    fOnAfterRun: TNotifyEvent;
    fOnRecordingChange: TNotifyEvent;
  private
    fController: TSimController;
    procedure SetController(const Value: TSimController);
    procedure UpdateClockDisplay;
    procedure RunToDate(aDate: TSimDate);
    procedure OnAfterAdvance(Sender: TObject);
    function GetRecording: Boolean;
  public
    property Controller: TSimController read fController write SetController;
    property Recording: Boolean read GetRecording;

    property OnBeforeRun: TNotifyEvent read fOnBeforeRun write fOnBeforeRun;
    property OnAfterRun: TNotifyEvent read fOnAfterRun write fOnAfterRun;
    property OnRecordingChange: TNotifyEvent read fOnRecordingChange write fOnRecordingChange;
  end;

implementation

{$R *.dfm}

uses u_SimClocks;

{ TControllerFrame }

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

procedure TControllerFrame.RunToDate(aDate: TSimDate);
begin
  var playlist := TPlaylist.Create;
  try
    var seg := Default(TSegment);
    seg.StartTime  := fController.CurrentDate;
    seg.EndTime    := aDate;
    seg.EndEvents  := [];
    seg.Recording  := btnRecord.Down;
    playlist.Add(seg);

    // allow clients to freeze UI update
    if Assigned(fOnBeforeRun) then
      fOnBeforeRun(Self);
    try
      fController.RunPlaylist(playlist);
    finally
      if Assigned(fOnAfterRun) then
        fOnAfterRun(Self);
    end;

  finally
    playlist.Free;
  end;
end;

procedure TControllerFrame.SetController(const Value: TSimController);
begin
  if Assigned(fController) then
    fController.AfterAdvance.Unsubscribe(OnAfterAdvance);

  fController := Value;

  if Assigned(fController) then
  begin
    fController.AfterAdvance.Subscribe(OnAfterAdvance);
    UpdateClockDisplay;
  end;
end;

procedure TControllerFrame.OnAfterAdvance(Sender: TObject);
begin
  UpdateClockDisplay;
end;

procedure TControllerFrame.UpdateClockDisplay;
begin
  if not Assigned(fController) then
    Exit;
  lblClock.Caption := Format('%.03d:%.03d', [fController.CurrentDate.DayNumber,
    fController.CurrentDate.DayTick]);
end;

end.
