object ResViewFrame: TResViewFrame
  Left = 0
  Top = 0
  Width = 299
  Height = 329
  DoubleBuffered = True
  DoubleBufferedMode = dbmRequested
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentDoubleBuffered = False
  ParentFont = False
  TabOrder = 0
  object Bevel1: TBevel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 293
    Height = 323
    Align = alClient
    ExplicitLeft = 280
    ExplicitTop = 320
    ExplicitWidth = 50
    ExplicitHeight = 50
  end
  object pbVis: TPaintBox
    Left = 8
    Top = 40
    Width = 256
    Height = 256
    OnPaint = pbVisPaint
  end
  object lblZoom: TLabel
    Left = 210
    Top = 7
    Width = 37
    Height = 17
    Caption = 'Zoom:'
  end
  object pbSubstance: TPaintBox
    Left = 34
    Top = 3
    Width = 136
    Height = 29
    OnPaint = pbSubstancePaint
  end
  object sbHPan: TScrollBar
    Left = 8
    Top = 305
    Width = 256
    Height = 17
    PageSize = 0
    TabOrder = 0
  end
  object sbVPan: TScrollBar
    Left = 273
    Top = 40
    Width = 17
    Height = 256
    Kind = sbVertical
    PageSize = 0
    TabOrder = 1
  end
  object spZoomFactor: TSpinEdit
    Left = 253
    Top = 4
    Width = 37
    Height = 27
    MaxValue = 0
    MinValue = 0
    TabOrder = 2
    Value = 0
    OnChange = spZoomFactorChange
  end
  object sbSubstance: TSpinButton
    Left = 176
    Top = 4
    Width = 20
    Height = 27
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
    TabOrder = 3
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
    OnDownClick = sbSubstanceDownClick
    OnUpClick = sbSubstanceUpClick
  end
  object cbActive: TCheckBox
    Left = 8
    Top = 8
    Width = 23
    Height = 17
    TabOrder = 4
    OnClick = cbActiveClick
  end
end
