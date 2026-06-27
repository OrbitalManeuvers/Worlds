object AgentWatchFrame: TAgentWatchFrame
  Left = 0
  Top = 0
  Width = 697
  Height = 490
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clBlack
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = False
  TabOrder = 0
  DesignSize = (
    697
    490)
  object Label2: TLabel
    Left = 8
    Top = 18
    Width = 43
    Height = 17
    Caption = 'Agents:'
  end
  object btnUpdateAgents: TSpeedButton
    Left = 392
    Top = 14
    Width = 73
    Height = 27
    Caption = 'Update'
    OnClick = btnUpdateAgentsClick
  end
  object btnExport: TSpeedButton
    Left = 632
    Top = 14
    Width = 54
    Height = 27
    Caption = 'Export'
    OnClick = btnExportClick
  end
  object edtAgentList: TEdit
    Left = 72
    Top = 15
    Width = 305
    Height = 25
    TabOrder = 0
    OnKeyPress = edtAgentListKeyPress
  end
  object pnlClientArea: TPanel
    Left = 8
    Top = 64
    Width = 678
    Height = 417
    Anchors = [akLeft, akTop, akRight, akBottom]
    ShowCaption = False
    TabOrder = 1
    object Tree: TVirtualDrawTree
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 670
      Height = 409
      Align = alClient
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
      Header.AutoSizeIndex = 0
      Header.MainColumn = -1
      TabOrder = 0
      TreeOptions.MiscOptions = [toAcceptOLEDrop, toFullRepaintOnResize, toInitOnSave, toToggleOnDblClick, toWheelPanning, toVariableNodeHeight, toEditOnClick]
      TreeOptions.PaintOptions = [toHideFocusRect, toHideSelection, toShowButtons, toShowDropmark, toShowRoot, toShowTreeLines, toThemeAware, toUseBlendedImages]
      TreeOptions.SelectionOptions = [toDisableDrawSelection]
      OnDrawNode = TreeDrawNode
      OnGetNodeDataSize = TreeGetNodeDataSize
      OnInitChildren = TreeInitChildren
      OnInitNode = TreeInitNode
      OnMeasureItem = TreeMeasureItem
      Touch.InteractiveGestures = [igPan, igPressAndTap]
      Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
      ExplicitLeft = 1
      ExplicitTop = 8
      ExplicitWidth = 664
      ExplicitHeight = 393
      Columns = <>
    end
  end
  object spnTickCount: TSpinEdit
    Left = 496
    Top = 15
    Width = 49
    Height = 27
    MaxValue = 4
    MinValue = 0
    TabOrder = 2
    Value = 0
    OnChange = spnTickCountChange
  end
end
