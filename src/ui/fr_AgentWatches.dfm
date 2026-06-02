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
    ItemHeight = 104
    ItemMargins.Left = 0
    ItemMargins.Top = 0
    ItemMargins.Right = 0
    ItemMargins.Bottom = 0
    ParentColor = False
    ParentFont = False
    TabOrder = 0
    OnBeforeDrawItem = WatchListBeforeDrawItem
    ExplicitWidth = 617
    object shpCard: TShape
      AlignWithMargins = True
      Left = 8
      Top = 4
      Width = 600
      Height = 93
      Margins.Left = 8
      Margins.Right = 8
      Anchors = [akLeft, akTop, akRight]
      Brush.Color = 2236962
      Pen.Color = 9676167
      Shape = stRoundRect
    end
    object pbEvals: TPaintBox
      Left = 16
      Top = 66
      Width = 580
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      OnPaint = FieldPaint
    end
    object pbAction: TPaintBox
      Left = 16
      Top = 39
      Width = 580
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      OnPaint = FieldPaint
      ExplicitWidth = 579
    end
    object pbHeader: TPaintBox
      Left = 16
      Top = 12
      Width = 265
      Height = 23
      OnPaint = FieldPaint
    end
    object pbWeights: TPaintBox
      Left = 296
      Top = 12
      Width = 300
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      OnPaint = FieldPaint
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
