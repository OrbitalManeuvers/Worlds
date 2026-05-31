object PopulationViewFrame: TPopulationViewFrame
  Left = 0
  Top = 0
  Width = 626
  Height = 190
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = False
  TabOrder = 0
  DesignSize = (
    626
    190)
  object Label2: TLabel
    Left = 8
    Top = 8
    Width = 65
    Height = 17
    Caption = 'Population:'
  end
  object lblCount: TLabel
    Left = 520
    Top = 8
    Width = 37
    Height = 17
    Anchors = [akTop, akRight]
    Caption = 'Count:'
  end
  object lblPopulationCount: TLabel
    Left = 575
    Top = 8
    Width = 35
    Height = 17
    Anchors = [akTop, akRight]
    Caption = '00000'
  end
  object PopulationList: TControlList
    Left = 9
    Top = 31
    Width = 609
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
    object lblDetail: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 0
      Width = 112
      Height = 22
      Margins.Left = 4
      Margins.Top = 0
      Margins.Right = 4
      Margins.Bottom = 0
      Align = alLeft
      AutoSize = False
      Caption = '000 000,000 0000'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
      StyleElements = [seClient, seBorder]
      ExplicitTop = -5
    end
    object lblReserves: TLabel
      AlignWithMargins = True
      Left = 128
      Top = 0
      Width = 48
      Height = 22
      Margins.Left = 8
      Margins.Top = 0
      Margins.Right = 4
      Margins.Bottom = 0
      Align = alLeft
      Alignment = taRightJustify
      AutoSize = False
      Caption = '0.0002'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
      StyleElements = [seClient, seBorder]
    end
    object lblMoleculeWeights: TLabel
      AlignWithMargins = True
      Left = 188
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
