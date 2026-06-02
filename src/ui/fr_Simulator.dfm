inherited SimulatorFrame: TSimulatorFrame
  Width = 1522
  Height = 819
  Font.Height = -13
  ParentFont = False
  ExplicitWidth = 1522
  ExplicitHeight = 819
  object phController: TShape
    Left = 16
    Top = 16
    Width = 513
    Height = 148
    Brush.Color = clGray
    Visible = False
  end
  object phAgentWatches: TShape
    Left = 16
    Top = 271
    Width = 729
    Height = 475
    Anchors = [akLeft, akTop, akRight, akBottom]
    Brush.Color = clGray
    Visible = False
  end
  object bvBottom: TBevel
    Left = 16
    Top = 761
    Width = 1496
    Height = 11
    Anchors = [akLeft, akRight, akBottom]
    Shape = bsBottomLine
    ExplicitTop = 520
    ExplicitWidth = 857
  end
  object phResViewer1: TShape
    Left = 903
    Top = 170
    Width = 300
    Height = 330
    Anchors = [akTop, akRight]
    Brush.Color = clGray
    ExplicitLeft = 640
  end
  object phResViewer2: TShape
    Left = 1209
    Top = 170
    Width = 300
    Height = 330
    Anchors = [akTop, akRight]
    Brush.Color = clGray
    ExplicitLeft = 946
  end
  object btnCopySummary: TSpeedButton
    Left = 545
    Top = 224
    Width = 49
    Height = 25
    Caption = 'Copy'
    OnClick = btnCopySummaryClick
  end
  object phPopulationViewer: TShape
    Left = 751
    Top = 506
    Width = 758
    Height = 240
    Anchors = [akTop, akRight, akBottom]
    Brush.Color = clGray
  end
  object phPopulationSummary: TShape
    Left = 16
    Top = 170
    Width = 513
    Height = 95
    Brush.Color = clGray
    Visible = False
  end
  object btnClose: TButton
    Left = 1392
    Top = 778
    Width = 125
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'DISCARD + Close'
    TabOrder = 0
    OnClick = btnCloseClick
  end
  object btnSaveClose: TButton
    Tag = 1
    Left = 1256
    Top = 778
    Width = 117
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'SAVE + Close'
    TabOrder = 1
    OnClick = btnCloseClick
  end
  object SaveProgress: TProgressBar
    Left = 16
    Top = 778
    Width = 1224
    Height = 25
    Anchors = [akLeft, akRight, akBottom]
    TabOrder = 2
    Visible = False
  end
  object ViewPopup: TPopupMenu
    Left = 592
    Top = 152
    object mniExport: TMenuItem
      Caption = 'Export Selected Rows'
    end
  end
end
