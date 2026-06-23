unit fr_AgentWatches;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.ControlList, Vcl.Buttons, Vcl.StdCtrls, Vcl.Samples.Spin,
  System.Generics.Collections,

  u_ControlRendering, u_LogTypes, u_SimPopulations, u_SimTypes,
  u_SimRuntimes, u_MulticastEvents, u_DiagnosticsIntf, u_BrainProbes;

const
  TICK_HISTORY_LENGTH = 5;
  LINES_PER_TICK = 2;

type
  THistoryEvent = record
    Date: TSimDate;
    Snapshot: TBrainSnapshot;
  end;

  TAgentWatch = record
    AgentId: TAgentId;
    // Ring buffer
    History: array[0..TICK_HISTORY_LENGTH - 1] of THistoryEvent;
    HistoryCount: Integer;
    WriteIndex: Integer;
  end;

  TAgentWatchFrame = class(TFrame, IRuntimeObserver)
    edtAgentList: TEdit;
    Label2: TLabel;
    btnUpdateAgents: TSpeedButton;
    pnlClientArea: TPanel;
    HSplit: TSplitter;
    btnExportSelected: TSpeedButton;
    pbTest: TPaintBox;
    procedure edtAgentListKeyPress(Sender: TObject; var Key: Char);
    procedure btnUpdateAgentsClick(Sender: TObject);
    procedure btnExportSelectedClick(Sender: TObject);
    procedure pbTestPaint(Sender: TObject);
  private
    Runtime: TSimRuntime;
  private
    procedure UpdateAgentList;
    function IndexOf(AgentId: TAgentId): Integer;
  private
    { IRuntimeObserver }
    procedure ConnectRuntime(aRuntime: TSimRuntime; aEvents: TNotificationEvents);
    procedure DisconnectRuntime(aRuntime: TSimRuntime; aEvents: TNotificationEvents);
    procedure HandleAfterRun(Sender: TObject);
  public
  end;

implementation

{$R *.dfm}

uses System.Types, System.IOUtils, Vcl.Themes, Vcl.GraphUtil,
  u_DiagnosticsHelpers, u_FieldRendering;

const
  bk_colors: array[0..9] of string = (
    'fec5bb','fcd5ce','fae1dd','f8edeb','e8e8e4','d8e2dc','ece4db','ffe5d9','ffd7ba','fec89a'
  );


{ TAgentWatchFrame }

procedure TAgentWatchFrame.btnUpdateAgentsClick(Sender: TObject);
begin
  UpdateAgentList;


end;

function TAgentWatchFrame.IndexOf(AgentId: TAgentId): Integer;
begin
  Result := -1;
end;

procedure TAgentWatchFrame.pbTestPaint(Sender: TObject);
const
  _name = 0;
  _value = 1;
  _positive = 2;
  _negative = 3;

  function stdPalette: TArray<TColor>;
  begin
    SetLength(Result, 4);
    Result[_name] := clWebCornFlowerBlue;
    Result[_value] := StyleServices.GetSystemColor(clWindowText);
    Result[_positive] := clWebGreenYellow;
    Result[_negative] := clWebTomato;
  end;

begin
  var df := Default(TDisplayFields);
  df.Palette := stdPalette;
  df.Defaults.Bk := StyleServices.GetSystemColor(clWindow);
  df.Defaults.NameColor := df.Palette[_name];
  df.Defaults.ValueColor := df.Palette[_value];

  df.AddField('rsrv', '6.30', _name, _value);
  df.AddField('', '2.4', _name, _negative);
  df.addField('loc', '(3,23)', _name, _value);

  TFieldDisplayEngine.RenderFields(df, pbTest.Canvas, pbTest.ClientRect);

end;

procedure TAgentWatchFrame.ConnectRuntime(aRuntime: TSimRuntime; aEvents: TNotificationEvents);
begin
  Runtime := aRuntime;
  aEvents.OnRun.After.Subscribe(HandleAfterRun);
end;

procedure TAgentWatchFrame.DisconnectRuntime(aRuntime: TSimRuntime; aEvents: TNotificationEvents);
begin
  aEvents.OnRun.After.Unsubscribe(HandleAfterRun);
  Runtime := nil;
end;

procedure TAgentWatchFrame.edtAgentListKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    UpdateAgentList;
  end;
end;

procedure TAgentWatchFrame.UpdateAgentList;

  procedure AddWatch(aId: TAgentId);
  begin
  end;

begin
  //
end;

procedure TAgentWatchFrame.HandleAfterRun(Sender: TObject);
begin
  if Assigned(Runtime) then
  begin

  end;
end;

procedure TAgentWatchFrame.btnExportSelectedClick(Sender: TObject);
const
  CRLF = #13#10;
begin
  //
end;

end.
