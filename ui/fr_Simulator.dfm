inherited SimulatorFrame: TSimulatorFrame
  Width = 789
  Font.Height = -13
  ParentFont = False
  ExplicitWidth = 789
  object btnClose: TButton
    Left = 710
    Top = 447
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Close'
    TabOrder = 0
    OnClick = btnCloseClick
    ExplicitLeft = 561
  end
  object AgentTree: TVirtualDrawTree
    Left = 24
    Top = 168
    Width = 345
    Height = 281
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
    DefaultNodeHeight = 19
    Header.AutoSizeIndex = 0
    Header.MainColumn = -1
    PopupMenu = StepViewPopup
    TabOrder = 1
    TreeOptions.PaintOptions = [toShowButtons, toShowDropmark, toShowHorzGridLines, toShowRoot, toShowTreeLines, toThemeAware, toUseBlendedImages]
    TreeOptions.SelectionOptions = [toFullRowSelect, toMultiSelect]
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <>
  end
  object LifetimeTree: TVirtualDrawTree
    Left = 512
    Top = 24
    Width = 257
    Height = 281
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
    DefaultNodeHeight = 19
    Header.AutoSizeIndex = 0
    Header.MainColumn = -1
    PopupMenu = StepViewPopup
    TabOrder = 2
    TreeOptions.PaintOptions = [toShowButtons, toShowDropmark, toShowHorzGridLines, toShowRoot, toShowTreeLines, toThemeAware, toUseBlendedImages]
    TreeOptions.SelectionOptions = [toFullRowSelect, toMultiSelect]
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <>
  end
  object StepViewPopup: TPopupMenu
    Left = 416
    Top = 248
    object mniExport: TMenuItem
      Caption = 'Export Selected Rows'
      OnClick = mniExportClick
    end
  end
end
