object AgentWatchFrame: TAgentWatchFrame
  Left = 0
  Top = 0
  Width = 641
  Height = 398
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clBlack
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = False
  TabOrder = 0
  DesignSize = (
    641
    398)
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
  object WatchList: TControlList
    Left = 8
    Top = 48
    Width = 618
    Height = 329
    Anchors = [akLeft, akTop, akRight, akBottom]
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
    object pbContent: TPaintBox
      Left = 47
      Top = 2
      Width = 562
      Height = 25
      Anchors = [akLeft, akTop, akRight]
      OnPaint = FieldPaint
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
    end
  end
  object edtAgentList: TEdit
    Left = 72
    Top = 7
    Width = 305
    Height = 25
    TabOrder = 1
    OnKeyPress = edtAgentListKeyPress
  end
  object spnRowCount: TSpinEdit
    Left = 481
    Top = 3
    Width = 57
    Height = 27
    MaxValue = 0
    MinValue = 0
    TabOrder = 2
    Value = 0
    OnChange = spnRowCountChange
  end
end
