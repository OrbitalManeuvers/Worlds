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
    Top = 10
    Width = 43
    Height = 17
    Caption = 'Agents:'
  end
  object btnUpdateAgents: TSpeedButton
    Left = 392
    Top = 3
    Width = 73
    Height = 27
    Caption = 'Update'
    OnClick = btnUpdateAgentsClick
  end
  object btnExportSelected: TSpeedButton
    Left = 632
    Top = 3
    Width = 54
    Height = 27
    Caption = 'Export'
    Enabled = False
    OnClick = btnExportSelectedClick
  end
  object edtAgentList: TEdit
    Left = 72
    Top = 7
    Width = 305
    Height = 25
    TabOrder = 0
    OnKeyPress = edtAgentListKeyPress
  end
  object spnRowCount: TSpinEdit
    Left = 481
    Top = 3
    Width = 57
    Height = 27
    MaxValue = 0
    MinValue = 0
    TabOrder = 1
    Value = 0
    OnChange = spnRowCountChange
  end
  object pnlClientArea: TPanel
    Left = 8
    Top = 48
    Width = 678
    Height = 433
    Anchors = [akLeft, akTop, akRight, akBottom]
    ShowCaption = False
    TabOrder = 2
    object HSplit: TSplitter
      Left = 1
      Top = 316
      Width = 676
      Height = 3
      Cursor = crVSplit
      Align = alBottom
      ResizeStyle = rsUpdate
      Visible = False
      ExplicitTop = 193
      ExplicitWidth = 126
    end
    object WatchList: TControlList
      Left = 1
      Top = 1
      Width = 676
      Height = 315
      Align = alClient
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Consolas'
      Font.Style = []
      ItemHeight = 29
      ItemMargins.Left = 0
      ItemMargins.Top = 0
      ItemMargins.Right = 0
      ItemMargins.Bottom = 0
      ItemSelectionOptions.HotColor = clWindow
      ItemSelectionOptions.SelectedColor = clWindow
      ItemSelectionOptions.FocusedColor = clWindow
      ParentColor = False
      ParentFont = False
      TabOrder = 0
      OnBeforeDrawItem = WatchListBeforeDrawItem
      OnItemClick = WatchListItemClick
      object pbContent: TPaintBox
        Left = 47
        Top = 2
        Width = 620
        Height = 25
        Anchors = [akLeft, akTop, akRight]
        OnPaint = FieldPaint
        ExplicitWidth = 562
      end
      object shAgentId: TShape
        Left = 2
        Top = 2
        Width = 39
        Height = 25
        Brush.Color = clGray
        Pen.Style = psClear
      end
      object lblAgentId: TLabel
        Left = 7
        Top = 6
        Width = 28
        Height = 15
        Caption = 'A000'
        OnClick = lblAgentIdClick
      end
    end
    object DetailList: TControlList
      Left = 1
      Top = 319
      Width = 676
      Height = 113
      Align = alBottom
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Consolas'
      Font.Style = []
      ItemHeight = 25
      ItemMargins.Left = 0
      ItemMargins.Top = 0
      ItemMargins.Right = 0
      ItemMargins.Bottom = 0
      ItemSelectionOptions.HotColor = clWindow
      ItemSelectionOptions.SelectedColor = clWindow
      ItemSelectionOptions.FocusedColor = clWindow
      ParentColor = False
      ParentFont = False
      TabOrder = 1
      Visible = False
      OnBeforeDrawItem = DetailListBeforeDrawItem
      object pbDetailLine: TPaintBox
        AlignWithMargins = True
        Left = 42
        Top = 2
        Width = 626
        Height = 21
        Margins.Left = 4
        Margins.Top = 2
        Margins.Right = 4
        Margins.Bottom = 2
        Align = alClient
        OnPaint = DetailPaint
        ExplicitLeft = 61
        ExplicitTop = 3
        ExplicitWidth = 578
        ExplicitHeight = 23
      end
      object lblDetailLineNumber: TLabel
        AlignWithMargins = True
        Left = 4
        Top = 2
        Width = 31
        Height = 21
        Margins.Left = 4
        Margins.Top = 2
        Margins.Bottom = 2
        Align = alLeft
        Alignment = taCenter
        AutoSize = False
        Caption = '00'
        Layout = tlCenter
        ExplicitHeight = 25
      end
    end
  end
  object cbDetails: TCheckBox
    Left = 552
    Top = 8
    Width = 65
    Height = 17
    Caption = 'Details'
    TabOrder = 3
    OnClick = cbDetailsClick
  end
end
