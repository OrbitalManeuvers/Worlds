inherited SimulatorFrame: TSimulatorFrame
  Width = 881
  Height = 560
  Font.Height = -13
  ParentFont = False
  ExplicitWidth = 881
  ExplicitHeight = 560
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
    Width = 841
    Height = 305
    Anchors = [akLeft, akTop, akRight, akBottom]
    Brush.Color = clGray
    Visible = False
  end
  object btnClose: TButton
    Left = 592
    Top = 519
    Width = 125
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'DISCARD + Close'
    TabOrder = 0
    OnClick = btnCloseClick
  end
  object btnSaveClose: TButton
    Tag = 1
    Left = 736
    Top = 519
    Width = 117
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'SAVE + Close'
    TabOrder = 1
    OnClick = btnCloseClick
  end
  object SaveProgress: TProgressBar
    Left = 15
    Top = 519
    Width = 562
    Height = 25
    TabOrder = 2
    Visible = False
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
