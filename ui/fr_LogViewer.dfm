object LogViewer: TLogViewer
  Left = 0
  Top = 0
  Width = 699
  Height = 351
  TabOrder = 0
  DesignSize = (
    699
    351)
  object Panel1: TPanel
    Left = 24
    Top = 16
    Width = 297
    Height = 41
    Caption = 'Panel1'
    TabOrder = 0
  end
  object Tree: TVirtualStringTree
    Left = 16
    Top = 72
    Width = 660
    Height = 265
    AccessibleName = 'Loc'
    Anchors = [akLeft, akTop, akRight, akBottom]
    Colors.BorderColor = 2697513
    Colors.DisabledColor = clGray
    Colors.DropMarkColor = 14581296
    Colors.DropTargetColor = 14581296
    Colors.DropTargetBorderColor = 14581296
    Colors.FocusedSelectionColor = 14581296
    Colors.FocusedSelectionBorderColor = 14581296
    Colors.GridLineColor = 2697513
    Colors.HeaderHotColor = clWhite
    Colors.HotColor = clWhite
    Colors.SelectionRectangleBlendColor = 14581296
    Colors.SelectionRectangleBorderColor = 14581296
    Colors.SelectionTextColor = clWhite
    Colors.TreeLineColor = 9471874
    Colors.UnfocusedColor = clGray
    Colors.UnfocusedSelectionColor = 2368548
    Colors.UnfocusedSelectionBorderColor = 2368548
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = []
    Header.AutoSizeIndex = -1
    Header.DefaultHeight = 24
    Header.Height = 24
    Header.MainColumn = -1
    Header.MinHeight = 24
    Indent = 4
    ParentFont = False
    TabOrder = 1
    TreeOptions.MiscOptions = [toAcceptOLEDrop, toFullRepaintOnResize, toInitOnSave, toToggleOnDblClick, toWheelPanning]
    TreeOptions.PaintOptions = [toShowDropmark, toShowRoot, toThemeAware, toUseBlendedImages]
    TreeOptions.SelectionOptions = [toFullRowSelect, toMultiSelect]
    OnGetText = TreeGetText
    OnInitNode = TreeInitNode
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    ExplicitWidth = 601
    Columns = <>
  end
end
