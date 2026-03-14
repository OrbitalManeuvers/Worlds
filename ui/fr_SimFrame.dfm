inherited SimFrame: TSimFrame
  Width = 778
  Height = 708
  DoubleBuffered = True
  ParentDoubleBuffered = False
  ExplicitWidth = 778
  ExplicitHeight = 708
  object pbVisualizer: TPaintBox
    Left = 16
    Top = 72
    Width = 256
    Height = 256
  end
  object Label1: TLabel
    Left = 278
    Top = 88
    Width = 57
    Height = 15
    Caption = 'Substance:'
  end
  object cmbRegions: TComboBox
    Left = 16
    Top = 17
    Width = 185
    Height = 23
    Style = csDropDownList
    TabOrder = 0
  end
  object btnStep: TButton
    Left = 296
    Top = 16
    Width = 75
    Height = 25
    Caption = 'Step'
    TabOrder = 1
    OnClick = btnStepClick
  end
  object LogMemo: TMemo
    Left = 16
    Top = 344
    Width = 745
    Height = 348
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Lucida Console'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 2
    WordWrap = False
  end
  object btnStart: TButton
    Left = 207
    Top = 16
    Width = 75
    Height = 25
    Caption = 'Create Sim'
    TabOrder = 3
    OnClick = btnStartClick
  end
  object spStepCount: TSpinEdit
    Left = 389
    Top = 17
    Width = 49
    Height = 24
    MaxValue = 10
    MinValue = 1
    TabOrder = 4
    Value = 1
  end
  object spnSubstanceIndex: TSpinEdit
    Left = 352
    Top = 85
    Width = 49
    Height = 24
    MaxValue = 0
    MinValue = 0
    TabOrder = 5
    Value = 0
    OnChange = spnSubstanceIndexChange
  end
  object Button1: TButton
    Left = 464
    Top = 24
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 6
  end
end
