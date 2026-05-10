object LogViewer: TLogViewer
  Left = 0
  Top = 0
  Width = 699
  Height = 351
  TabOrder = 0
  DesignSize = (
    699
    351)
  object pnlViewTools: TPanel
    Left = 24
    Top = 16
    Width = 657
    Height = 41
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    object btnIncDT: TSpeedButton
      Left = 8
      Top = 8
      Width = 25
      Height = 25
      AllowAllUp = True
      GroupIndex = 1
      Caption = 'DT'
      OnClick = FilterChanged
    end
    object btnExport: TSpeedButton
      Left = 416
      Top = 8
      Width = 65
      Height = 25
      Caption = 'Export'
      OnClick = btnExportClick
    end
    object btnIncAR: TSpeedButton
      Left = 40
      Top = 8
      Width = 25
      Height = 25
      AllowAllUp = True
      GroupIndex = 2
      Caption = 'AR'
      OnClick = FilterChanged
    end
  end
  object Tree: TVirtualStringTree
    Left = 16
    Top = 72
    Width = 457
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
    OnAddToSelection = TreeSelectionChanged
    OnGetText = TreeGetText
    OnInitNode = TreeInitNode
    OnRemoveFromSelection = TreeSelectionChanged
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <>
  end
  object vlDetails: TValueListEditor
    Left = 488
    Top = 72
    Width = 193
    Height = 265
    Anchors = [akTop, akRight, akBottom]
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goTabs, goRowSelect, goThumbTracking]
    Strings.Strings = (
      '=')
    TabOrder = 2
    ColWidths = (
      83
      104)
  end
end
