object LogViewer: TLogViewer
  Left = 0
  Top = 0
  Width = 699
  Height = 401
  TabOrder = 0
  object pnlViewTools: TPanel
    Left = 0
    Top = 0
    Width = 699
    Height = 81
    Align = alTop
    TabOrder = 0
    object btnExport: TSpeedButton
      Left = 376
      Top = 48
      Width = 121
      Height = 25
      Caption = 'Export Selected'
      OnClick = btnExportClick
    end
    object lbEventTypes: TCheckListBox
      Left = 6
      Top = 8
      Width = 355
      Height = 65
      Columns = 2
      ItemHeight = 17
      TabOrder = 0
      OnClickCheck = lbEventTypesClickCheck
    end
  end
  object DetailsView: TControlList
    Left = 0
    Top = 304
    Width = 699
    Height = 97
    Align = alBottom
    ItemHeight = 20
    ItemMargins.Left = 0
    ItemMargins.Top = 0
    ItemMargins.Right = 0
    ItemMargins.Bottom = 0
    ParentColor = False
    TabOrder = 1
    OnBeforeDrawItem = DetailsViewBeforeDrawItem
    object lblDetails: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 3
      Width = 688
      Height = 14
      Margins.Left = 4
      Align = alClient
      Caption = 'lblDetails'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindow
      Font.Height = -12
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      StyleElements = [seClient, seBorder]
      ExplicitWidth = 70
    end
  end
  object EventList: TControlList
    AlignWithMargins = True
    Left = 0
    Top = 81
    Width = 699
    Height = 219
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 4
    Align = alClient
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = []
    ItemHeight = 20
    ItemMargins.Left = 0
    ItemMargins.Top = 0
    ItemMargins.Right = 0
    ItemMargins.Bottom = 0
    ParentColor = False
    ParentFont = False
    MultiSelect = True
    TabOrder = 2
    OnBeforeDrawItem = EventListBeforeDrawItem
    OnItemClick = EventListItemClick
    object lblEventTime: TLabel
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 84
      Height = 14
      Align = alLeft
      Caption = 'lblEventTime'
      Font.Charset = ANSI_CHARSET
      Font.Color = clSilver
      Font.Height = -12
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
      StyleElements = [seClient, seBorder]
    end
    object lblEventContent: TLabel
      AlignWithMargins = True
      Left = 96
      Top = 3
      Width = 596
      Height = 14
      Margins.Left = 6
      Align = alClient
      Caption = 'lblEventContent'
      Color = clWindow
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindow
      Font.Height = -12
      Font.Name = 'Consolas'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Layout = tlCenter
      StyleElements = [seClient, seBorder]
      ExplicitWidth = 105
    end
  end
end
