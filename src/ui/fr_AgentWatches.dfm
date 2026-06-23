object AgentWatchFrame: TAgentWatchFrame
  Left = 0
  Top = 0
  Width = 697
  Height = 490
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clBlack
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = False
  TabOrder = 0
  DesignSize = (
    697
    490)
  object Label2: TLabel
    Left = 8
    Top = 10
    Width = 43
    Height = 17
    Caption = 'Agents:'
  end
  object btnUpdateAgents: TSpeedButton
    Left = 392
    Top = 3
    Width = 73
    Height = 27
    Caption = 'Update'
    OnClick = btnUpdateAgentsClick
  end
  object btnExportSelected: TSpeedButton
    Left = 632
    Top = 3
    Width = 54
    Height = 27
    Caption = 'Export'
    Enabled = False
    OnClick = btnExportSelectedClick
  end
  object edtAgentList: TEdit
    Left = 72
    Top = 7
    Width = 305
    Height = 25
    TabOrder = 0
    OnKeyPress = edtAgentListKeyPress
  end
  object pnlClientArea: TPanel
    Left = 8
    Top = 48
    Width = 678
    Height = 433
    Anchors = [akLeft, akTop, akRight, akBottom]
    ShowCaption = False
    TabOrder = 1
    object HSplit: TSplitter
      Left = 1
      Top = 429
      Width = 676
      Height = 3
      Cursor = crVSplit
      Align = alBottom
      ResizeStyle = rsUpdate
      Visible = False
      ExplicitTop = 193
      ExplicitWidth = 126
    end
    object pbTest: TPaintBox
      Left = 24
      Top = 8
      Width = 297
      Height = 33
      OnPaint = pbTestPaint
    end
  end
end
