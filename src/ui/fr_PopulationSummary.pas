unit fr_PopulationSummary;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls,

  u_LogTypes, u_ControlRendering, u_DiagnosticsIntf,
  u_SimRuntimes, u_MulticastEvents;

type
  TPopulationSummaryFrame = class(TFrame, IRuntimeObserver)
    shBorder: TShape;
    pbSummary1: TPaintBox;
    pbSummary2: TPaintBox;
    procedure pbSummary2Paint(Sender: TObject);
    procedure pbSummary1Paint(Sender: TObject);
  private
    { IRuntimeObserver }
    procedure ConnectRuntime(aRuntime: TSimRuntime; aEvents: TNotificationEvents);
    procedure DisconnectRuntime(aRuntime: TSimRuntime; aEvents: TNotificationEvents);
    procedure HandleBeforeRun(Sender: TObject);
    procedure HandleAfterRun(Sender: TObject);
  private
    Runtime: TSimRuntime;
    fRunning: Boolean;
    Summary1: TLogFields;
    Summary2: TLogFields;
    procedure Reset;
  end;

implementation

{$R *.dfm}

uses u_DiagnosticsHelpers;


{ TSimStatsFrame }

procedure TPopulationSummaryFrame.Reset;
begin
  Summary1 := Default(TLogFields);
  Summary2 := Default(TLogFields);
end;

procedure TPopulationSummaryFrame.ConnectRuntime(aRuntime: TSimRuntime; aEvents: TNotificationEvents);
begin
  Runtime := aRuntime;
  aEvents.OnRun.Before.Subscribe(HandleBeforeRun);
  aEvents.OnRun.After.Subscribe(HandleAfterRun);
  Reset;
end;

procedure TPopulationSummaryFrame.DisconnectRuntime(aRuntime: TSimRuntime; aEvents: TNotificationEvents);
begin
  aEvents.OnRun.Before.Unsubscribe(HandleBeforeRun);
  aEvents.OnRun.After.Unsubscribe(HandleAfterRun);
  Runtime := nil;
  Reset;
  Invalidate;
end;

procedure TPopulationSummaryFrame.HandleAfterRun(Sender: TObject);
begin
  fRunning := False;
  if Assigned(Runtime) then
  begin
    Summary1 := Runtime.PopulationSummary.AsSummaryFields;
    Summary2 := Runtime.PopulationSummary.AsMaxFields;
    Invalidate;
  end;
end;

procedure TPopulationSummaryFrame.HandleBeforeRun(Sender: TObject);
begin
  fRunning := True;
end;

procedure TPopulationSummaryFrame.pbSummary1Paint(Sender: TObject);
begin
  if not fRunning then
    pbSummary1.Render(Summary1, clBtnFace);
end;

procedure TPopulationSummaryFrame.pbSummary2Paint(Sender: TObject);
begin
  if not fRunning then
    pbSummary2.Render(Summary2, clBtnFace);
end;

end.
