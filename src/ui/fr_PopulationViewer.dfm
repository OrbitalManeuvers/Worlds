object PopulationViewFrame: TPopulationViewFrame
  Left = 0
  Top = 0
  Width = 701
  Height = 190
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = False
  TabOrder = 0
  DesignSize = (
    701
    190)
  object Label2: TLabel
    Left = 8
    Top = 8
    Width = 65
    Height = 17
    Caption = 'Population:'
  end
  object lblCount: TLabel
    Left = 595
    Top = 8
    Width = 37
    Height = 17
    Anchors = [akTop, akRight]
    Caption = 'Count:'
    ExplicitLeft = 520
  end
  object lblPopulationCount: TLabel
    Left = 650
    Top = 8
    Width = 35
    Height = 17
    Anchors = [akTop, akRight]
    Caption = '00000'
    ExplicitLeft = 575
  end
  object PopulationList: TControlList
    Left = 9
    Top = 31
    Width = 684
    Height = 144
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    ItemHeight = 22
    ItemMargins.Left = 0
    ItemMargins.Top = 0
    ItemMargins.Right = 0
    ItemMargins.Bottom = 0
    ParentColor = False
    ParentFont = False
    TabOrder = 0
    OnBeforeDrawItem = PopulationListBeforeDrawItem
    ExplicitWidth = 609
    object lblDetail: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 0
      Width = 129
      Height = 22
      Margins.Left = 4
      Margins.Top = 0
      Margins.Right = 4
      Margins.Bottom = 0
      Align = alLeft
      AutoSize = False
      Caption = '000 (000,000) 0000'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
      StyleElements = [seClient, seBorder]
    end
    object lblReserves: TLabel
      AlignWithMargins = True
      Left = 189
      Top = 0
      Width = 113
      Height = 22
      Margins.Left = 8
      Margins.Top = 0
      Margins.Right = 4
      Margins.Bottom = 0
      Align = alLeft
      Alignment = taRightJustify
      AutoSize = False
      Caption = '12.789 (-0.023)'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
      StyleElements = [seClient, seBorder]
      ExplicitLeft = 128
    end
    object lblMoleculeWeights: TLabel
      AlignWithMargins = True
      Left = 314
      Top = 0
      Width = 221
      Height = 22
      Margins.Left = 8
      Margins.Top = 0
      Margins.Right = 4
      Margins.Bottom = 0
      Align = alLeft
      AutoSize = False
      Caption = 'A:1.000 A:1.000 A:1.000 A:1.000 '
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
      StyleElements = [seClient, seBorder]
      ExplicitLeft = 270
      ExplicitTop = -5
    end
    object lblPressures: TLabel
      AlignWithMargins = True
      Left = 547
      Top = 0
      Width = 131
      Height = 22
      Margins.Left = 8
      Margins.Top = 0
      Margins.Right = 4
      Margins.Bottom = 0
      Align = alLeft
      AutoSize = False
      Caption = 'tsr:0000'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
      StyleElements = [seClient, seBorder]
      ExplicitLeft = 503
    end
    object lblAction: TLabel
      AlignWithMargins = True
      Left = 145
      Top = 0
      Width = 32
      Height = 22
      Margins.Left = 8
      Margins.Top = 0
      Margins.Right = 4
      Margins.Bottom = 0
      Align = alLeft
      AutoSize = False
      Caption = 'idl'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
      StyleElements = [seClient, seBorder]
    end
  end
  object cbLivingOnly: TCheckBox
    Left = 168
    Top = 8
    Width = 121
    Height = 17
    Caption = 'Living only'
    TabOrder = 1
    OnClick = cbLivingOnlyClick
  end
end
