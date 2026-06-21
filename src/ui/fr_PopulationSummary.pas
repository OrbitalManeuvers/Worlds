unit fr_PopulationSummary;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls,

  u_SimEventTypes, u_LogTypes, u_ControlRendering, u_DiagnosticsIntf,
  u_SimRuntimes, u_MulticastEvents;

type
  TPopulationSummaryFrame = class(TFrame, IRuntimeObserver, IDiagnosticsView)
    shBorder: TShape;
    pbSummary1: TPaintBox;
    pbSummary2: TPaintBox;
    procedure pbSummary2Paint(Sender: TObject);
    procedure pbSummary1Paint(Sender: TObject);
  private
    { IRuntimeObserver }
    procedure ConnectRuntime(aRuntime: TSimRuntime; const aDiagnostics: ISimEventHub;
      AfterAdvance: TMulticastEvent<TNotifyEvent>);
    procedure DisconnectRuntime(aRuntime: TSimRuntime; const aDiagnostics: ISimEventHub;
      AfterAdvance: TMulticastEvent<TNotifyEvent>);

    { IDiagnosticsView }
    procedure BeginRun;
    procedure EndRun;
  private
    Runtime: TSimRuntime;
    fRunning: Boolean;
    Summary1: TLogFields;
    Summary2: TLogFields;
    procedure HandleAfterAdvance(Sender: TObject);
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

procedure TPopulationSummaryFrame.ConnectRuntime(aRuntime: TSimRuntime;
  const aDiagnostics: ISimEventHub; AfterAdvance: TMulticastEvent<TNotifyEvent>);
begin
  Runtime := aRuntime;
  AfterAdvance.Subscribe(HandleAfterAdvance);
  Reset;
end;

procedure TPopulationSummaryFrame.DisconnectRuntime(aRuntime: TSimRuntime;
  const aDiagnostics: ISimEventHub; AfterAdvance: TMulticastEvent<TNotifyEvent>);
begin
  AfterAdvance.Unsubscribe(HandleAfterAdvance);
  Runtime := nil;
  Reset;
  Invalidate;
end;

procedure TPopulationSummaryFrame.HandleAfterAdvance(Sender: TObject);
begin
  if fRunning then
    Exit;

  if Assigned(Runtime) then
  begin
    Summary1 := Runtime.PopulationSummary.AsSummaryFields;
    Summary2 := Runtime.PopulationSummary.AsMaxFields;
    Invalidate;
  end;
end;

procedure TPopulationSummaryFrame.BeginRun;
begin
  fRunning := True;
end;

procedure TPopulationSummaryFrame.EndRun;
begin
  fRunning := False;
  HandleAfterAdvance(nil);
end;

procedure TPopulationSummaryFrame.pbSummary1Paint(Sender: TObject);
begin
  pbSummary1.Render(Summary1, clBtnFace);
end;

procedure TPopulationSummaryFrame.pbSummary2Paint(Sender: TObject);
begin
  pbSummary2.Render(Summary2, clBtnFace);
end;

end.
