object LogViewer: TLogViewer
  Left = 0
  Top = 0
  Width = 699
  Height = 401
  TabOrder = 0
  DesignSize = (
    699
    401)
  object pnlViewTools: TPanel
    Left = 24
    Top = 16
    Width = 657
    Height = 41
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    object btnIncDT: TSpeedButton
      Left = 8
      Top = 8
      Width = 25
      Height = 25
      AllowAllUp = True
      GroupIndex = 1
      Caption = 'DT'
      OnClick = FilterChanged
    end
    object btnExport: TSpeedButton
      Left = 416
      Top = 8
      Width = 65
      Height = 25
      Caption = 'Export'
      OnClick = btnExportClick
    end
    object btnIncAR: TSpeedButton
      Left = 40
      Top = 8
      Width = 25
      Height = 25
      AllowAllUp = True
      GroupIndex = 2
      Caption = 'AR'
      OnClick = FilterChanged
    end
  end
  object DetailsView: TControlList
    Left = 16
    Top = 288
    Width = 665
    Height = 97
    Anchors = [akLeft, akRight, akBottom]
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
      Width = 654
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
    Left = 16
    Top = 72
    Width = 665
    Height = 201
    Anchors = [akLeft, akTop, akRight, akBottom]
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
      ExplicitLeft = 14
      ExplicitTop = 8
    end
    object lblEventContent: TLabel
      AlignWithMargins = True
      Left = 96
      Top = 3
      Width = 562
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
