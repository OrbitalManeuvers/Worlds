object ConditionEditor: TConditionEditor
  AlignWithMargins = True
  Left = 0
  Top = 0
  Width = 550
  Height = 50
  Margins.Left = 4
  Margins.Top = 4
  Margins.Right = 4
  Margins.Bottom = 2
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = False
  TabOrder = 0
  object shBorder: TShape
    Left = 0
    Top = 0
    Width = 550
    Height = 50
    Align = alClient
    Brush.Style = bsClear
    Pen.Color = clMoneyGreen
    OnMouseDown = shBorderMouseDown
    ExplicitLeft = 328
    ExplicitTop = 16
    ExplicitWidth = 9
    ExplicitHeight = 17
  end
  object shStatus: TShape
    Left = 10
    Top = 15
    Width = 20
    Height = 20
    Brush.Color = clMoneyGreen
    Shape = stCircle
    OnMouseDown = shStatusMouseDown
  end
  object cmbAction: TComboBox
    Left = 196
    Top = 13
    Width = 101
    Height = 25
    Style = csDropDownList
    TabOrder = 0
    OnCloseUp = cmbActionCloseUp
  end
  object edtParameter: TEdit
    Left = 424
    Top = 13
    Width = 65
    Height = 25
    TabOrder = 1
    OnChange = edtParameterChange
  end
  object cmbCacheType: TComboBox
    Left = 312
    Top = 13
    Width = 97
    Height = 25
    Style = csDropDownList
    ItemIndex = 0
    TabOrder = 2
    Text = 'Growable'
    OnCloseUp = cmbCacheTypeCloseUp
    Items.Strings = (
      'Growable'
      'Delta')
  end
  object cmbKind: TComboBox
    Left = 48
    Top = 13
    Width = 137
    Height = 25
    Style = csDropDownList
    TabOrder = 3
    OnCloseUp = cmbKindCloseUp
  end
end
