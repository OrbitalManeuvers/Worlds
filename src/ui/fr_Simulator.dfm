inherited SimulatorFrame: TSimulatorFrame
  Width = 1259
  Height = 819
  Font.Height = -13
  ParentFont = False
  ExplicitWidth = 1259
  ExplicitHeight = 819
  object phController: TShape
    Left = 16
    Top = 16
    Width = 513
    Height = 148
    Brush.Color = clGray
    Visible = False
  end
  object phLogViewer: TShape
    Left = 16
    Top = 170
    Width = 604
    Height = 576
    Anchors = [akLeft, akTop, akRight, akBottom]
    Brush.Color = clGray
    Visible = False
  end
  object bvBottom: TBevel
    Left = 16
    Top = 761
    Width = 1233
    Height = 11
    Anchors = [akLeft, akRight, akBottom]
    Shape = bsBottomLine
    ExplicitTop = 520
    ExplicitWidth = 857
  end
  object phResViewer: TShape
    Left = 640
    Top = 170
    Width = 300
    Height = 330
    Anchors = [akTop, akRight]
    Brush.Color = clGray
  end
  object phDeltaViewer: TShape
    Left = 946
    Top = 170
    Width = 300
    Height = 330
    Anchors = [akTop, akRight]
    Brush.Color = clGray
  end
  object btnCopySummary: TSpeedButton
    Left = 952
    Top = 560
    Width = 49
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Copy'
    OnClick = btnCopySummaryClick
  end
  object btnClose: TButton
    Left = 1129
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
    Left = 993
    Top = 778
    Width = 117
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'SAVE + Close'
    TabOrder = 1
    OnClick = btnCloseClick
  end
  object SaveProgress: TProgressBar
    Left = 393
    Top = 778
    Width = 584
    Height = 25
    Anchors = [akRight, akBottom]
    TabOrder = 2
    Visible = False
  end
  object vlPopulationStats: TValueListEditor
    Left = 640
    Top = 560
    Width = 297
    Height = 185
    Anchors = [akTop, akRight]
    DisplayOptions = [doKeyColFixed]
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goEditing, goThumbTracking]
    ScrollBars = ssVertical
    Strings.Strings = (
      '')
    TabOrder = 3
    ColWidths = (
      150
      141)
  end
  object ViewPopup: TPopupMenu
    Left = 592
    Top = 152
    object mniExport: TMenuItem
      Caption = 'Export Selected Rows'
    end
  end
end
