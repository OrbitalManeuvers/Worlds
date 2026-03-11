unit fr_SimFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.StdCtrls,

  u_EnvironmentLibraries;

type
  TSimFrame = class(TContentFrame)
    cmbRegions: TComboBox;
    btnTest: TButton;
    mmoUpscaleReport: TMemo;
    procedure btnTestClick(Sender: TObject);
  private
  public
    procedure Init; override;
    procedure ActivateContent; override;
  end;


implementation

{$R *.dfm}

uses u_SimUpscalers, u_SimRuntimes, u_SimParams,
  u_Regions;

{ TSimFrame }

procedure TSimFrame.ActivateContent;
begin
  inherited;
  cmbRegions.Items.BeginUpdate;
  try
    cmbRegions.Items.Clear;

    for var i := 0 to WorldLibrary.RegionCount - 1 do
    begin
      var region := WorldLibrary.Regions[i];
      cmbRegions.Items.AddObject(region.Name, region);
    end;

    if cmbRegions.Items.Count > 0 then
      cmbRegions.ItemIndex := 0;

  finally
    cmbRegions.Items.EndUpdate;
  end;
end;

procedure TSimFrame.btnTestClick(Sender: TObject);
begin

  var runtime := TSimRuntime.Create;
  try

    var params: TSimParams;
    var upscaler := TSimUpscaler.Create(runtime, params);
    try

      var index := cmbRegions.ItemIndex;
      if index = -1 then
        Exit;

      var region := cmbRegions.Items.Objects[index] as TRegion;
      upscaler.UpscaleRegion(region, 8, WorldLibrary);

      mmoUpscaleReport.Lines.Assign(upscaler.Report);


    finally
      upscaler.Free;
    end;

  finally
    runtime.Free;
  end;

end;

procedure TSimFrame.Init;
begin
  inherited;
  //
end;

end.
