inherited SessionFrame: TSessionFrame
  Width = 990
  Height = 708
  DoubleBuffered = True
  Font.Height = -13
  ParentDoubleBuffered = False
  ParentFont = False
  ExplicitWidth = 990
  ExplicitHeight = 708
  object Label2: TLabel
    Left = 16
    Top = 16
    Width = 76
    Height = 17
    Caption = 'Select World:'
  end
  object WorldList: TControlList
    Left = 16
    Top = 39
    Width = 217
    Height = 370
    ItemHeight = 45
    ItemMargins.Left = 0
    ItemMargins.Top = 0
    ItemMargins.Right = 0
    ItemMargins.Bottom = 0
    ParentColor = False
    TabOrder = 0
    OnBeforeDrawItem = WorldListBeforeDrawItem
    OnItemClick = WorldListItemClick
    object lblWorldName: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 2
      Width = 165
      Height = 41
      Margins.Left = 4
      Margins.Top = 2
      Margins.Bottom = 2
      Align = alLeft
      AutoSize = False
      Caption = '[world]'
      Layout = tlCenter
    end
  end
  object btnCreateSim: TButton
    Left = 256
    Top = 421
    Width = 93
    Height = 36
    Caption = 'Create Sim'
    TabOrder = 1
    OnClick = btnCreateSimClick
  end
  object gbPopulation: TGroupBox
    Left = 256
    Top = 24
    Width = 465
    Height = 385
    Caption = ' Population Controls '
    TabOrder = 2
    object edtAgentCount: TLabeledEdit
      Left = 128
      Top = 56
      Width = 121
      Height = 25
      EditLabel.Width = 77
      EditLabel.Height = 25
      EditLabel.Caption = 'Agent count: '
      LabelPosition = lpLeft
      TabOrder = 0
      Text = '1'
    end
  end
end
