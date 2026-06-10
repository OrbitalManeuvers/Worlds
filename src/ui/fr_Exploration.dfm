object ExplorationFrame: TExplorationFrame
  Left = 0
  Top = 0
  Width = 483
  Height = 409
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = False
  TabOrder = 0
  DesignSize = (
    483
    409)
  object Label1: TLabel
    Left = 16
    Top = 91
    Width = 43
    Height = 17
    Caption = 'Agents:'
  end
  object btnAddCondition: TSpeedButton
    Left = 320
    Top = 88
    Width = 65
    Height = 25
    Caption = 'Add'
    OnClick = btnAddConditionClick
  end
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 483
    Height = 4
    Align = alTop
    Brush.Color = 11295602
    Pen.Style = psClear
    ExplicitWidth = 516
  end
  object Label2: TLabel
    Left = 16
    Top = 21
    Width = 48
    Height = 17
    Caption = 'Queries:'
  end
  object btnDeleteCondition: TSpeedButton
    Left = 400
    Top = 88
    Width = 65
    Height = 25
    Caption = 'Delete'
    OnClick = btnDeleteConditionClick
  end
  object Bevel1: TBevel
    Left = 16
    Top = 56
    Width = 458
    Height = 9
    Anchors = [akLeft, akTop, akRight]
    Shape = bsBottomLine
    Style = bsRaised
  end
  object btnRun: TSpeedButton
    Left = 400
    Top = 18
    Width = 65
    Height = 25
    Caption = 'Run'
    OnClick = btnRunClick
  end
  object ConditionView: TScrollBox
    Left = 3
    Top = 128
    Width = 471
    Height = 258
    Anchors = [akLeft, akTop, akRight, akBottom]
    Color = clWindow
    ParentColor = False
    TabOrder = 0
  end
  object edtAgents: TEdit
    Left = 80
    Top = 88
    Width = 153
    Height = 25
    TabOrder = 1
    Text = '*'
    TextHint = 'Any'
    OnChange = edtAgentsChange
  end
  object cmbQueryList: TComboBox
    Left = 80
    Top = 18
    Width = 249
    Height = 25
    Style = csDropDownList
    TabOrder = 2
  end
end
