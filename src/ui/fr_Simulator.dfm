inherited SimulatorFrame: TSimulatorFrame
  Width = 1311
  Height = 875
  Font.Height = -13
  ParentFont = False
  ExplicitWidth = 1311
  ExplicitHeight = 875
  object phController: TShape
    Left = 16
    Top = 16
    Width = 513
    Height = 120
    Brush.Color = clGray
    Visible = False
  end
  object phAgentWatches: TShape
    Left = 600
    Top = 16
    Width = 698
    Height = 273
    Anchors = [akLeft, akTop, akRight, akBottom]
    Brush.Color = clGray
    Visible = False
  end
  object bvBottom: TBevel
    Left = 16
    Top = 817
    Width = 1285
    Height = 11
    Anchors = [akLeft, akRight, akBottom]
    Shape = bsBottomLine
    ExplicitTop = 520
    ExplicitWidth = 857
  end
  object phResViewer1: TShape
    Left = 692
    Top = 300
    Width = 300
    Height = 330
    Anchors = [akRight, akBottom]
    Brush.Color = clGray
    ExplicitLeft = 903
  end
  object phResViewer2: TShape
    Left = 998
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
    Width = 698
    Height = 177
    Anchors = [akLeft, akRight, akBottom]
    Brush.Color = clGray
  end
  object phPopulationSummary: TShape
    Left = 16
    Top = 138
    Width = 513
    Height = 70
    Brush.Color = clGray
    Visible = False
  end
  object btnClose: TButton
    Left = 1181
    Top = 834
    Width = 125
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'DISCARD + Close'
    TabOrder = 0
    OnClick = btnCloseClick
    ExplicitLeft = 1392
    ExplicitTop = 778
  end
  object btnSaveClose: TButton
    Tag = 1
    Left = 1045
    Top = 834
    Width = 117
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'SAVE + Close'
    TabOrder = 1
    OnClick = btnCloseClick
    ExplicitLeft = 1256
    ExplicitTop = 778
  end
  object SaveProgress: TProgressBar
    Left = 16
    Top = 834
    Width = 1013
    Height = 25
    Anchors = [akLeft, akRight, akBottom]
    TabOrder = 2
    Visible = False
    ExplicitTop = 778
    ExplicitWidth = 1224
  end
  object ViewPopup: TPopupMenu
    Left = 592
    Top = 152
    object mniExport: TMenuItem
      Caption = 'Export Selected Rows'
    end
  end
end
