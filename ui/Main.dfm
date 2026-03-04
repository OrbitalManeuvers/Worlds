object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Worlds'
  ClientHeight = 942
  ClientWidth = 1315
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 17
  object StatusBar: TStatusBar
    Left = 0
    Top = 923
    Width = 1315
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object AppEvents: TApplicationEvents
    OnHint = AppEventsHint
    Left = 104
    Top = 464
  end
end
