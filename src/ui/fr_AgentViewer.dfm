object AgentViewerFrame: TAgentViewerFrame
  Left = 0
  Top = 0
  Width = 640
  Height = 255
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = False
  TabOrder = 0
  object btnApply: TSpeedButton
    Left = 304
    Top = 6
    Width = 65
    Height = 22
    Caption = 'Apply'
    Layout = blGlyphTop
    OnClick = btnApplyClick
  end
  object edtAgentIds: TLabeledEdit
    Left = 80
    Top = 3
    Width = 201
    Height = 25
    EditLabel.Width = 64
    EditLabel.Height = 25
    EditLabel.Caption = 'Agent List: '
    LabelPosition = lpLeft
    TabOrder = 0
    Text = ''
  end
  object AgentList: TControlList
    Left = 3
    Top = 34
    Width = 622
    Height = 200
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    ItemHeight = 24
    ItemMargins.Left = 0
    ItemMargins.Top = 0
    ItemMargins.Right = 0
    ItemMargins.Bottom = 0
    ParentColor = False
    ParentFont = False
    TabOrder = 1
    OnBeforeDrawItem = AgentListBeforeDrawItem
    object lblAgentId: TLabel
      Left = 8
      Top = 8
      Width = 593
      Height = 15
      AutoSize = False
      Caption = '000'
    end
  end
end
