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
        Width = 82
        Height = 17
        Caption = 'Select Region:'
      end
      object RegionList: TControlList
        Left = 16
        Top = 37
        Width = 200
        Height = 404
        ItemHeight = 45
        ItemMargins.Left = 0
        ItemMargins.Top = 0
        ItemMargins.Right = 0
        ItemMargins.Bottom = 0
        ParentColor = False
        TabOrder = 0
        OnBeforeDrawItem = RegionListBeforeDrawItem
        OnItemClick = RegionListItemClick
        object lblRegionName: TLabel
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
          Caption = 'lblRegionName'
          Layout = tlCenter
          ExplicitHeight = 41
        end
      end
      object btnCreateSim: TButton
        Left = 236
        Top = 37
        Width = 75
        Height = 25
        Caption = 'Create Sim'
        TabOrder = 1
        OnClick = btnCreateSimClick
      end
    end
    object tsSelection: TTabSheet
      Caption = 'tsSelection'
      DoubleBufferedMode = dbmRequested
      ImageIndex = 1
      TabVisible = False
      object pbVisualizer: TPaintBox
        Left = 296
        Top = 13
        Width = 256
        Height = 256
        OnPaint = pbVisualizerPaint
      end
      object LogMemo: TMemo
        Left = 0
        Top = 320
        Width = 982
        Height = 378
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
        Width = 241
        Height = 261
        TabOrder = 1
        object lblClock: TLabel
          Left = 16
          Top = 16
          Width = 59
          Height = 17
          Caption = 'Sim Clock:'
        end
        object lblTime: TLabel
          Left = 96
          Top = 18
          Width = 42
          Height = 15
          Caption = '00:000'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Consolas'
          Font.Style = []
          ParentFont = False
        end
        object btnStep1: TSpeedButton
          Tag = 1
          Left = 16
          Top = 48
          Width = 41
          Height = 33
          Caption = '[ 1 ]'
          Transparent = False
          OnClick = btnStepClick
        end
        object btnStep5: TSpeedButton
          Tag = 5
          Left = 64
          Top = 48
          Width = 41
          Height = 33
          Caption = '[ 5 ]'
          Transparent = False
          OnClick = btnStepClick
        end
        object btnStep10: TSpeedButton
          Tag = 10
          Left = 112
          Top = 48
          Width = 41
          Height = 33
          Caption = '[ 10 ]'
          Transparent = False
          OnClick = btnStepClick
        end
        object Label1: TLabel
          Left = 28
          Top = 128
          Width = 62
          Height = 17
          Caption = 'Substance:'
        end
        object btnScrollUp: TSpeedButton
          Tag = 1
          Left = 88
          Top = 183
          Width = 23
          Height = 22
          Caption = '^'
          OnClick = ScrollClick
        end
        object btnScrollRight: TSpeedButton
          Tag = 2
          Left = 112
          Top = 200
          Width = 23
          Height = 22
          Caption = '>'
          OnClick = ScrollClick
        end
        object btnScrollLeft: TSpeedButton
          Tag = 4
          Left = 67
          Top = 200
          Width = 23
          Height = 22
          Caption = '<'
          OnClick = ScrollClick
        end
        object btnScrollDown: TSpeedButton
          Tag = 3
          Left = 88
          Top = 213
          Width = 23
          Height = 22
          Caption = 'v'
          OnClick = ScrollClick
        end
        object spZoomLevel: TSpinButton
          Left = 175
          Top = 125
          Width = 26
          Height = 30
          DownGlyph.Data = {
            0E010000424D0E01000000000000360000002800000009000000060000000100
            200000000000D800000000000000000000000000000000000000008080000080
            8000008080000080800000808000008080000080800000808000008080000080
            8000008080000080800000808000000000000080800000808000008080000080
            8000008080000080800000808000000000000000000000000000008080000080
            8000008080000080800000808000000000000000000000000000000000000000
            0000008080000080800000808000000000000000000000000000000000000000
            0000000000000000000000808000008080000080800000808000008080000080
            800000808000008080000080800000808000}
          TabOrder = 0
          UpGlyph.Data = {
            0E010000424D0E01000000000000360000002800000009000000060000000100
            200000000000D800000000000000000000000000000000000000008080000080
            8000008080000080800000808000008080000080800000808000008080000080
            8000000000000000000000000000000000000000000000000000000000000080
            8000008080000080800000000000000000000000000000000000000000000080
            8000008080000080800000808000008080000000000000000000000000000080
            8000008080000080800000808000008080000080800000808000000000000080
            8000008080000080800000808000008080000080800000808000008080000080
            800000808000008080000080800000808000}
          OnDownClick = spZoomLevelDownClick
          OnUpClick = spZoomLevelUpClick
        end
        object spnSubstanceIndex: TSpinEdit
          Left = 104
          Top = 125
          Width = 49
          Height = 27
          MaxValue = 0
          MinValue = 0
          TabOrder = 1
          Value = 0
          OnChange = spnSubstanceIndexChange
        end
      end
    end
  end
end
