inherited SimFrame: TSimFrame
  Width = 990
  Height = 708
  DoubleBuffered = True
  Font.Height = -13
  ParentDoubleBuffered = False
  ParentFont = False
  ExplicitWidth = 990
  ExplicitHeight = 708
  object Pages: TPageControl
    Left = 0
    Top = 0
    Width = 990
    Height = 708
    ActivePage = tsSelection
    Align = alClient
    TabOrder = 0
    object tsNoSelection: TTabSheet
      Caption = 'tsNoSelection'
      TabVisible = False
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
          Height = -4
          Margins.Left = 4
          Margins.Top = 2
          Margins.Bottom = 2
          Align = alLeft
          AutoSize = False
          Caption = '[world]'
          Layout = tlCenter
          ExplicitHeight = 41
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
    object tsSelection: TTabSheet
      Caption = 'tsSelection'
      DoubleBufferedMode = dbmRequested
      ImageIndex = 1
      TabVisible = False
      object phV1: TShape
        Left = 200
        Top = 26
        Width = 300
        Height = 330
        Brush.Color = clDimgray
        Pen.Style = psClear
      end
      object phV2: TShape
        Left = 592
        Top = 26
        Width = 300
        Height = 330
        Brush.Color = clDimgray
        Pen.Style = psClear
      end
      object LogMemo: TMemo
        Left = 0
        Top = 384
        Width = 982
        Height = 314
        Align = alBottom
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Lucida Console'
        Font.Style = []
        ParentFont = False
        ScrollBars = ssBoth
        TabOrder = 0
        WordWrap = False
      end
      object gbControls: TGroupBox
        Left = 8
        Top = 8
        Width = 169
        Height = 105
        TabOrder = 1
        object lblClock: TLabel
          Left = 8
          Top = 16
          Width = 59
          Height = 17
          Caption = 'Sim Clock:'
        end
        object lblTime: TLabel
          Left = 88
          Top = 16
          Width = 48
          Height = 18
          Caption = '00:000'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -15
          Font.Name = 'Consolas'
          Font.Style = []
          ParentFont = False
        end
        object btnStep1: TSpeedButton
          Tag = 1
          Left = 8
          Top = 61
          Width = 41
          Height = 33
          Caption = '[ 1 ]'
          Transparent = False
          OnClick = btnStepClick
        end
        object btnStep5: TSpeedButton
          Tag = 5
          Left = 56
          Top = 61
          Width = 41
          Height = 33
          Caption = '[ 5 ]'
          Transparent = False
          OnClick = btnStepClick
        end
        object btnStep10: TSpeedButton
          Tag = 10
          Left = 104
          Top = 61
          Width = 41
          Height = 33
          Caption = '[ 10 ]'
          Transparent = False
          OnClick = btnStepClick
        end
        object lblStep: TLabel
          Left = 8
          Top = 40
          Width = 35
          Height = 17
          Caption = 'Steps:'
        end
      end
      object btnClose: TButton
        Left = 8
        Top = 327
        Width = 75
        Height = 25
        Caption = 'Close'
        TabOrder = 2
        OnClick = btnCloseClick
      end
      object grpSeeds: TGroupBox
        Left = 8
        Top = 128
        Width = 169
        Height = 113
        TabOrder = 3
        object Label1: TLabel
          Left = 8
          Top = 8
          Width = 70
          Height = 17
          Caption = 'Seed in use:'
        end
        object btnSaveSeed: TSpeedButton
          Left = 8
          Top = 64
          Width = 77
          Height = 25
          Caption = 'Save As ...'
        end
        object edtSeedName: TEdit
          Left = 8
          Top = 32
          Width = 140
          Height = 25
          TabOrder = 0
          Text = '(unnamed)'
        end
      end
      object ViewerGridPanel: TGridPanel
        Left = 194
        Top = 20
        Width = 655
        Height = 340
        Caption = 'ViewerGridPanel'
        ColumnCollection = <
          item
            Value = 50.000000000000000000
          end
          item
            Value = 50.000000000000000000
          end>
        ControlCollection = <>
        ExpandStyle = emAddColumns
        FullRepaint = False
        RowCollection = <
          item
            Value = 100.000000000000000000
          end>
        TabOrder = 4
      end
    end
  end
end
