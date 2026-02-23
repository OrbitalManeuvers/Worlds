unit u_ButtonBars;

interface

uses WinApi.Windows, WinApi.Messages, System.Classes, Vcl.Controls, Vcl.Graphics;

type
  TButtonBar = class(TGraphicControl)
  private
    fMouseInControl: Boolean;
    fItemIndex: Integer;
    fMouseIsDown: Boolean;
    fButtonWidth: Integer;
    fCaptions: TStrings;
    procedure Layout;
    procedure SetCaptions(const Value: TStrings);
    function GetCaptionStr: string;
    procedure SetCaptionStr(const Value: string);
  protected
    procedure Paint; override;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure WMWindowPosChanged(var Msg: TWMWindowPosChanged); message WM_WINDOWPOSCHANGED;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Captions: TStrings read fCaptions write SetCaptions;
    property CaptionStr: string read GetCaptionStr write SetCaptionStr;
  end;

implementation

uses Vcl.Themes;


{ TButtonBar }
constructor TButtonBar.Create(AOwner: TComponent);
begin
  inherited;
  fCaptions := TStringList.Create(dupIgnore, False, False);
//  Self.ControlStyle := [cs

end;

destructor TButtonBar.Destroy;
begin
  fCaptions.Free;
  inherited;
end;

function TButtonBar.GetCaptionStr: string;
begin
  Result := fCaptions.CommaText;
end;

procedure TButtonBar.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
end;

procedure TButtonBar.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
end;

procedure TButtonBar.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;

end;

procedure TButtonBar.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;

end;

procedure TButtonBar.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;

end;

procedure TButtonBar.Paint;
var
  details: TThemedElementDetails;
begin
  var r := Self.ClientRect;
//  details := StyleServices.GetElementDetails(trBand);
//  StyleServices.DrawElement(Canvas.Handle, details, r);

  for var i := 0 to fCaptions.Count - 1 do
  begin
    r.Right := r.Left + fButtonWidth;
    if i = fItemIndex then
      details := StyleServices.GetElementDetails(ttbButtonPressed)
    else
      details := StyleServices.GetElementDetails(ttbButtonNormal);

//    details := StyleServices.GetElementDetails(ttbButtonNormal);
    StyleServices.DrawElement(Canvas.Handle, details, r);

    var itemCaption := fCaptions[i];
    StyleServices.DrawText(Canvas.Handle, details, itemCaption, r, [tfSingleLine, tfCenter, tfVerticalCenter]);


    r.Left := r.Right - 1;
  end;



//  Canvas.Brush.Color := StyleServices.GetSystemColor(clWindow);
//  Canvas.Brush.Style := bsSolid;
//  Canvas.Pen.Style := psClear;
//  Canvas.FrameRect(R);


//    //  drawing a text
//    LTextOptions.GlowSize := cDefaultGlowSize;
//    LTextOptions.Flags := [stfTextColor, stfGlowSize];
//
//    if Active then
//      LTextOptions.TextColor := clWebDarkRed
//    else
//      LTextOptions.TextColor := clBlue;
//
//    LTextFormat := [tfSingleLine, tfVerticalCenter, tfEndEllipsis, tfComposited];
//    Include(LTextFormat, AlignStyles[taCenter]);
//
//    Inc(LRect.Top, ScaleValue(20));
//    s := 'Sample Text OnPaint event';
//    TStyleManager.SystemStyle.DrawText(Canvas.Handle,
//      TStyleManager.SystemStyle.GetElementDetails(twCaptionActive), s, LRect,
//      LTextFormat, LTextOptions);



end;

procedure TButtonBar.SetCaptions(const Value: TStrings);
begin
  fCaptions.Assign(Value);
  Layout;
end;

procedure TButtonBar.SetCaptionStr(const Value: string);
begin
  fCaptions.CommaText := Value;
  Layout;
end;

procedure TButtonBar.WMWindowPosChanged(var Msg: TWMWindowPosChanged);
begin
  inherited;
  Layout;
end;

procedure TButtonBar.Layout;
begin
  if fCaptions.Count = 0 then
    Exit;
  // how many pixels do we have for each value?
  fButtonWidth := Self.ClientWidth div fCaptions.Count;


  Invalidate;
end;

end.
