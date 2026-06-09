inherited SimulatorFrame: TSimulatorFrame
  Width = 1277
  Height = 875
  Font.Height = -13
  ParentFont = False
  ExplicitWidth = 1277
  ExplicitHeight = 875
  object phStepper: TShape
    Left = 16
    Top = 16
    Width = 492
    Height = 120
    Brush.Color = clGray
    Visible = False
  end
  object phAgentWatches: TShape
    Left = 565
    Top = 16
    Width = 699
    Height = 273
    Anchors = [akTop, akRight, akBottom]
    Brush.Color = clGray
    Visible = False
    ExplicitLeft = 600
  end
  object bvBottom: TBevel
    Left = 16
    Top = 817
    Width = 1251
    Height = 11
    Anchors = [akLeft, akRight, akBottom]
    Shape = bsBottomLine
    ExplicitTop = 520
    ExplicitWidth = 857
  end
  object phResViewer1: TShape
    Left = 658
    Top = 300
    Width = 300
    Height = 330
    Anchors = [akRight, akBottom]
    Brush.Color = clGray
    ExplicitLeft = 903
  end
  object phResViewer2: TShape
    Left = 964
    Top = 300
    Width = 300
    Height = 330
    Anchors = [akRight, akBottom]
    Brush.Color = clGray
    ExplicitLeft = 1209
  end
  object btnCopySummary: TSpeedButton
    Left = 16
    Top = 214
    Width = 49
    Height = 25
    Caption = 'Copy'
    OnClick = btnCopySummaryClick
  end
  object phPopulationViewer: TShape
    Left = 600
    Top = 636
    Width = 664
    Height = 177
    Anchors = [akLeft, akRight, akBottom]
    Brush.Color = clGray
    ExplicitWidth = 698
  end
  object phPopulationSummary: TShape
    Left = 16
    Top = 138
    Width = 492
    Height = 70
    Brush.Color = clGray
    Visible = False
  end
  object phExplorer: TShape
    Left = 16
    Top = 256
    Width = 492
    Height = 374
    Anchors = [akLeft, akTop, akBottom]
    Brush.Color = clGray
    Visible = False
  end
  object btnClose: TButton
    Left = 1147
    Top = 834
    Width = 125
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'DISCARD + Close'
    TabOrder = 0
    OnClick = btnCloseClick
    ExplicitLeft = 1181
  end
  object btnSaveClose: TButton
    Tag = 1
    Left = 1011
    Top = 834
    Width = 117
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'SAVE + Close'
    TabOrder = 1
    OnClick = btnCloseClick
    ExplicitLeft = 1045
  end
  object SaveProgress: TProgressBar
    Left = 16
    Top = 834
    Width = 979
    Height = 25
    Anchors = [akLeft, akRight, akBottom]
    TabOrder = 2
    Visible = False
    ExplicitWidth = 1013
  end
  object ViewPopup: TPopupMenu
    Left = 592
    Top = 152
    object mniExport: TMenuItem
      Caption = 'Export Selected Rows'
    end
  end
end
