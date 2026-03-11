inherited SimFrame: TSimFrame
  object cmbRegions: TComboBox
    Left = 56
    Top = 96
    Width = 185
    Height = 23
    Style = csDropDownList
    TabOrder = 0
  end
  object btnTest: TButton
    Left = 247
    Top = 95
    Width = 75
    Height = 25
    Caption = 'Test'
    TabOrder = 1
    OnClick = btnTestClick
  end
  object mmoUpscaleReport: TMemo
    Left = 16
    Top = 144
    Width = 609
    Height = 313
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Lucida Console'
    Font.Style = []
    Lines.Strings = (
      'mmoUpscaleReport')
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 2
    WordWrap = False
  end
end
