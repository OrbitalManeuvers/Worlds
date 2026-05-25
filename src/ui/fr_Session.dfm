inherited SessionFrame: TSessionFrame
  Width = 990
  Height = 673
  DoubleBuffered = True
  Font.Height = -13
  ParentDoubleBuffered = False
  ParentFont = False
  ExplicitWidth = 990
  ExplicitHeight = 673
  object Label2: TLabel
    Left = 16
    Top = 105
    Width = 216
    Height = 17
    Caption = 'Select what type of session to create:'
  end
  object btnCreateSim: TButton
    Left = 596
    Top = 557
    Width = 93
    Height = 36
    Caption = 'Create Sim'
    TabOrder = 0
    OnClick = btnCreateSimClick
  end
  object pcPages: TPageControl
    Left = 16
    Top = 136
    Width = 673
    Height = 415
    ActivePage = tsStandard
    TabOrder = 1
    OnChange = pcPagesChange
    object tsStandard: TTabSheet
      Caption = 'Standard'
      object Label3: TLabel
        Left = 12
        Top = 17
        Width = 168
        Height = 17
        Caption = 'Select which World to create:'
      end
      object Label1: TLabel
        Left = 264
        Top = 48
        Width = 110
        Height = 17
        Caption = 'Number of agents:'
      end
      object Label4: TLabel
        Left = 264
        Top = 110
        Width = 79
        Height = 17
        Caption = 'Session seed:'
      end
      object Label5: TLabel
        Left = 264
        Top = 80
        Width = 71
        Height = 17
        Caption = 'Scale factor:'
      end
      object WorldList: TControlList
        Left = 12
        Top = 40
        Width = 213
        Height = 313
        ItemHeight = 32
        ItemMargins.Left = 0
        ItemMargins.Top = 0
        ItemMargins.Right = 0
        ItemMargins.Bottom = 0
        ParentColor = False
        TabOrder = 0
        OnBeforeDrawItem = WorldListBeforeDrawItem
        object lblWorldName: TLabel
          Left = 8
          Top = 6
          Width = 84
          Height = 17
          Caption = 'lblWorldName'
        end
      end
      object seAgentCount: TSpinEdit
        Left = 400
        Top = 45
        Width = 73
        Height = 27
        MaxValue = 0
        MinValue = 0
        TabOrder = 1
        Value = 4
      end
      object SeedList: TControlList
        Left = 400
        Top = 110
        Width = 200
        Height = 105
        ItemHeight = 32
        ItemMargins.Left = 0
        ItemMargins.Top = 0
        ItemMargins.Right = 0
        ItemMargins.Bottom = 0
        ParentColor = False
        TabOrder = 2
        OnBeforeDrawItem = SeedListBeforeDrawItem
        object lblSeedName: TLabel
          Left = 8
          Top = 8
          Width = 78
          Height = 17
          Caption = 'lblSeedName'
        end
      end
      object seScaleFactor: TSpinEdit
        Left = 400
        Top = 77
        Width = 73
        Height = 27
        MaxValue = 8
        MinValue = 8
        TabOrder = 3
        Value = 8
      end
    end
    object tsDebug: TTabSheet
      Caption = 'Debug'
      ImageIndex = 1
      object Label6: TLabel
        Left = 12
        Top = 16
        Width = 134
        Height = 17
        Caption = 'Select Debug Scenario:'
      end
      object ScenarioList: TControlList
        Left = 12
        Top = 39
        Width = 213
        Height = 313
        ItemHeight = 32
        ItemMargins.Left = 0
        ItemMargins.Top = 0
        ItemMargins.Right = 0
        ItemMargins.Bottom = 0
        ParentColor = False
        TabOrder = 0
        OnBeforeDrawItem = ScenarioListBeforeDrawItem
        object lblScenarioName: TLabel
          Left = 8
          Top = 8
          Width = 99
          Height = 17
          Caption = 'lblScenarioName'
        end
      end
    end
  end
  object GroupBox1: TGroupBox
    Left = 16
    Top = 16
    Width = 673
    Height = 73
    Caption = ' Session Parameters '
    TabOrder = 2
    object Label8: TLabel
      Left = 19
      Top = 28
      Width = 72
      Height = 17
      Caption = 'Session title:'
    end
    object edtSessionTitle: TEdit
      Left = 131
      Top = 25
      Width = 194
      Height = 25
      TabOrder = 0
      Text = 'session-01'
    end
  end
end
