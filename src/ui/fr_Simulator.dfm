inherited SimulatorFrame: TSimulatorFrame
  Width = 1387
  Height = 606
  Font.Height = -13
  ParentFont = False
  ExplicitWidth = 1387
  ExplicitHeight = 606
  object phController: TShape
    Left = 16
    Top = 16
    Width = 513
    Height = 161
    Brush.Color = clGray
    Visible = False
  end
  object phLogViewer: TShape
    Left = 16
    Top = 200
    Width = 604
    Height = 333
    Anchors = [akLeft, akTop, akBottom]
    Brush.Color = clGray
    Visible = False
    ExplicitHeight = 305
  end
  object bvBottom: TBevel
    Left = 16
    Top = 548
    Width = 1361
    Height = 11
    Anchors = [akLeft, akRight, akBottom]
    Shape = bsBottomLine
    ExplicitTop = 520
    ExplicitWidth = 857
  end
  object phResViewer: TShape
    Left = 640
    Top = 200
    Width = 300
    Height = 330
    Brush.Color = clGray
  end
  object phDeltaViewer: TShape
    Left = 946
    Top = 200
    Width = 300
    Height = 330
    Brush.Color = clGray
  end
  object btnClose: TButton
    Left = 1257
    Top = 565
    Width = 125
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'DISCARD + Close'
    TabOrder = 0
    OnClick = btnCloseClick
    ExplicitLeft = 900
  end
  object btnSaveClose: TButton
    Tag = 1
    Left = 1121
    Top = 565
    Width = 117
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'SAVE + Close'
    TabOrder = 1
    OnClick = btnCloseClick
    ExplicitLeft = 764
  end
  object SaveProgress: TProgressBar
    Left = 521
    Top = 565
    Width = 584
    Height = 25
    Anchors = [akRight, akBottom]
    TabOrder = 2
    Visible = False
    ExplicitLeft = 164
  end
  object ViewPopup: TPopupMenu
    Left = 592
    Top = 152
    object mniExport: TMenuItem
      Caption = 'Export Selected Rows'
      OnClick = mniExportClick
    end
  end
end
