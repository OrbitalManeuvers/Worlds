object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Worlds'
  ClientHeight = 665
  ClientWidth = 1103
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = MainMenu
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 17
  object StatusBar: TStatusBar
    Left = 0
    Top = 646
    Width = 1103
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object MainMenu: TMainMenu
    Left = 64
    Top = 120
    object mnuFile: TMenuItem
      Caption = '&File'
      object mniFileNew: TMenuItem
        Caption = '&New'
        Hint = 'Create New World'
      end
      object mniFileOpen: TMenuItem
        Caption = '&Open...'
        Hint = 'Open Existing World from disk'
        ShortCut = 16463
      end
      object mniFileSave: TMenuItem
        Caption = '&Save'
        Hint = 'Save World'
        ShortCut = 16467
      end
      object mniFileSaveAs: TMenuItem
        Caption = 'Save &As...'
        Hint = 'Save World with New Name'
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object mniFileExit: TMenuItem
        Caption = 'E&xit'
        Hint = 'Exit the application'
        ShortCut = 32856
        OnClick = mniFileExitClick
      end
    end
    object Help1: TMenuItem
      Caption = '&Help'
      object About1: TMenuItem
        Caption = '&About...'
      end
    end
  end
  object AppEvents: TApplicationEvents
    OnHint = AppEventsHint
    Left = 104
    Top = 464
  end
end
