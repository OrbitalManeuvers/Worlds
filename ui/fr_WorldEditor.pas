unit fr_WorldEditor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.ControlList,
  Vcl.StdCtrls, Vcl.ComCtrls,

  u_Worlds, Vcl.ExtCtrls, u_GraphicButtonBars, Vcl.Grids, Vcl.ValEdit;

type
  TWorldEditor = class(TContentFrame)
    WorldList: TControlList;
    btnNewWorld: TButton;
    Pages: TPageControl;
    tsNoSelection: TTabSheet;
    tsSelection: TTabSheet;
    lblWorldName: TLabel;
    lblName: TLabel;
    edtName: TEdit;
    lblDescription: TLabel;
    edtDescription: TEdit;
    lblLayout: TLabel;
    pbRegionLayout: TPaintBox;
    RegionList1: TControlList;
    RegionList2: TControlList;
    RegionList3: TControlList;
    Regionlist4: TControlList;
    lblRegion1: TLabel;
    lblRegion2: TLabel;
    lblRegion3: TLabel;
    lblRegion4: TLabel;
    procedure btnNewWorldClick(Sender: TObject);
    procedure WorldListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure WorldListItemClick(Sender: TObject);
    procedure edtDescriptionChange(Sender: TObject);
    procedure edtNameChange(Sender: TObject);
    procedure Regionlist4BeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure RegionList2BeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure RegionList1BeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure RegionList3BeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure RegionClick(Sender: TObject);
  private
    World: TWorld;
    bbRegionLayout: TButtonBar;
    procedure EditWorld(aWorld: TWorld);
    procedure UpdateControls;
    procedure ItemChanged;
    procedure RegionLayoutClick(Sender: TObject);
    procedure RegionLayoutChanged;
  public
    procedure Init; override;
    procedure ActivateContent; override;
  end;


implementation

{$R *.dfm}

uses System.Generics.Collections, System.Math,
  u_EnvironmentLibraries;

procedure Replace(pb: TPaintBox; bbar: TButtonBar);
begin
  pb.Hide;
  bbar.Parent := pb.Parent;
  bbar.BoundsRect := pb.BoundsRect;
  bbar.Visible := True;
end;


{ TWorldEditor }

procedure TWorldEditor.Init;
begin
  inherited;
  Pages.ActivePage := tsNoSelection;

  bbRegionLayout := TButtonBar.Create(Self);
  bbRegionLayout.Captions := ['Single', 'North to South', 'West to East', 'Square'];
  bbRegionLayout.OnClick := RegionLayoutClick;
  Replace(pbRegionLayout, bbRegionLayout);
end;

procedure TWorldEditor.ItemChanged;
begin
  // the selected item has changed
  WorldList.UpdateItem(WorldList.ItemIndex);
end;

procedure TWorldEditor.RegionLayoutClick(Sender: TObject);
begin
  World.Layout := TRegionLayout(bbRegionLayout.ItemIndex);
  RegionLayoutChanged;
end;

procedure TWorldEditor.RegionList1BeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  lblRegion1.Caption := WorldLibrary.Regions[AIndex].Name;
end;

procedure TWorldEditor.RegionList2BeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  lblRegion2.Caption := WorldLibrary.Regions[AIndex].Name;
end;

procedure TWorldEditor.RegionList3BeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  lblRegion3.Caption := WorldLibrary.Regions[AIndex].Name;
end;

procedure TWorldEditor.Regionlist4BeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  lblRegion4.Caption := WorldLibrary.Regions[AIndex].Name;
end;

procedure TWorldEditor.RegionClick(Sender: TObject);
begin
  if Sender = RegionList1 then
    World.Regions[1] := WorldLibrary.Regions[RegionList1.ItemIndex]
  else if Sender = RegionList2 then
    World.Regions[2] := WorldLibrary.Regions[RegionList2.ItemIndex]
  else if Sender = RegionList3 then
    World.Regions[3] := WorldLibrary.Regions[RegionList3.ItemIndex]
  else if Sender = RegionList4 then
    World.Regions[4] := WorldLibrary.Regions[RegionList4.ItemIndex];
end;

procedure TWorldEditor.RegionLayoutChanged;
begin
  if not Assigned(World) then
    Exit;

  RegionList2.Visible := World.Layout in [rlWestEast, rlSquare];
  RegionList3.Visible := World.Layout in [rlNorthSouth, rlSquare];
  RegionList4.Visible := World.Layout = rlSquare;
end;

procedure TWorldEditor.ActivateContent;
begin
  RegionList1.ItemCount := WorldLibrary.RegionCount;
  RegionList2.ItemCount := RegionList1.ItemCount;
  RegionList3.ItemCount := RegionList1.ItemCount;
  RegionList4.ItemCount := RegionList1.ItemCount;

  if WorldLibrary.WorldCount <> WorldList.ItemCount then
  begin
    WorldList.ItemCount := WorldLibrary.WorldCount;

    if WorldList.ItemCount = 0 then
    begin
      World := nil;
      WorldList.ItemIndex := -1;
    end
    else
    begin
      WorldList.ItemIndex := 0;
      EditWorld(WorldLibrary.Worlds[WorldList.ItemIndex]);
    end;
  end;
end;

procedure TWorldEditor.btnNewWorldClick(Sender: TObject);
begin
  var W := TWorld.Create;
  W.Name := 'Untitled01';
  W.Description := 'Test World';
  WorldLibrary.AddWorld(W);
  WorldList.ItemCount := WorldLibrary.WorldCount;
end;

procedure TWorldEditor.EditWorld(aWorld: TWorld);
begin
  Pages.ActivePage := tsSelection;
  World := aWorld;

  edtName.Text := World.Name;
  edtDescription.Text := World.Description;
  bbRegionLayout.ItemIndex := Ord(World.Layout);

  if Assigned(World.Regions[1]) then
    RegionList1.ItemIndex := WorldLibrary.IndexOfRegion(World.Regions[1].Name);
  if Assigned(World.Regions[2]) then
    RegionList2.ItemIndex := WorldLibrary.IndexOfRegion(World.Regions[2].Name);
  if Assigned(World.Regions[3]) then
    RegionList3.ItemIndex := WorldLibrary.IndexOfRegion(World.Regions[3].Name);
  if Assigned(World.Regions[4]) then
    RegionList4.ItemIndex := WorldLibrary.IndexOfRegion(World.Regions[4].Name);



  RegionLayoutChanged;

  UpdateControls;
end;

procedure TWorldEditor.edtDescriptionChange(Sender: TObject);
begin
  World.Description := edtDescription.Text;
  ItemChanged;
end;

procedure TWorldEditor.edtNameChange(Sender: TObject);
begin
  World.Name := edtName.Text;
  ItemChanged;
end;

procedure TWorldEditor.UpdateControls;
begin
  //
end;

procedure TWorldEditor.WorldListBeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  if (AIndex >= 0) and (AIndex < WorldLibrary.WorldCount) then
  begin
    lblWorldName.Caption := WorldLibrary.Worlds[AIndex].Name;
  end;
end;

procedure TWorldEditor.WorldListItemClick(Sender: TObject);
begin
  if WorldList.ItemIndex >= 0 then
    EditWorld(WorldLibrary.Worlds[WorldList.ItemIndex]);
end;

end.
