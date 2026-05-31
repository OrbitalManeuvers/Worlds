object AgentWatchFrame: TAgentWatchFrame
  Left = 0
  Top = 0
  Width = 640
  Height = 398
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clBlack
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = False
  TabOrder = 0
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
    Width = 617
    Height = 329
    Font.Charset = ANSI_CHARSET
    Font.Color = clBlack
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    ItemMargins.Left = 0
    ItemMargins.Top = 0
    ItemMargins.Right = 0
    ItemMargins.Bottom = 0
    ParentColor = False
    ParentFont = False
    TabOrder = 0
    OnBeforeDrawItem = WatchListBeforeDrawItem
    object Shape1: TShape
      AlignWithMargins = True
      Left = 8
      Top = 3
      Width = 597
      Height = 64
      Margins.Left = 8
      Margins.Right = 8
      Align = alClient
      Brush.Color = 14475992
      Pen.Style = psClear
      Shape = stRoundRect
      ExplicitTop = 4
      ExplicitWidth = 497
      ExplicitHeight = 61
    end
    object lblAgentId: TLabel
      Left = 16
      Top = 8
      Width = 21
      Height = 15
      Caption = '010'
      StyleElements = [seClient, seBorder]
    end
    object lblReserves: TLabel
      Left = 48
      Top = 8
      Width = 42
      Height = 15
      Caption = '12.332'
      StyleElements = [seClient, seBorder]
    end
    object lblMoleculeWeights: TLabel
      Left = 120
      Top = 8
      Width = 224
      Height = 15
      Caption = 'A:1.000 B:1.000 G:1.0000 D:1.000'
      StyleElements = [seClient, seBorder]
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
end
