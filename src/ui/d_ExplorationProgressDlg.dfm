object ExplorationProgressDlg: TExplorationProgressDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Exploration Progress'
  ClientHeight = 120
  ClientWidth = 264
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnShow = FormShow
  TextHeight = 17
  object Label1: TLabel
    Left = 56
    Top = 17
    Width = 55
    Height = 17
    Caption = 'Sim Date:'
  end
  object Label2: TLabel
    Left = 24
    Top = 40
    Width = 87
    Height = 17
    Caption = 'Ticks Executed:'
  end
  object lblSimDate: TLabel
    Left = 136
    Top = 17
    Width = 45
    Height = 17
    Caption = '000:000'
  end
  object lblTicksExecuted: TLabel
    Left = 136
    Top = 40
    Width = 35
    Height = 17
    Caption = '00000'
  end
  object btnCancel: TButton
    Left = 88
    Top = 72
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    TabOrder = 0
    OnClick = btnCancelClick
  end
end
