inherited RegionEditor: TRegionEditor
  Width = 1189
  Height = 841
  Font.Height = -13
  ParentFont = False
  ExplicitWidth = 1189
  ExplicitHeight = 841
  object shPlaceholder: TShape
    Left = 288
    Top = 178
    Width = 640
    Height = 640
    Brush.Color = 5325864
    Pen.Style = psClear
  end
  object Label1: TLabel
    Left = 16
    Top = 10
    Width = 47
    Height = 17
    Caption = 'Regions'
  end
  object shDrawing: TShape
    Left = 296
    Top = 136
    Width = 33
    Height = 33
  end
  object shErasing: TShape
    Left = 344
    Top = 136
    Width = 33
    Height = 33
    Brush.Color = clBlack
    Pen.Color = clGray
  end
  object RegionList: TControlList
    Left = 16
    Top = 32
    Width = 249
    Height = 585
    ItemHeight = 40
    ItemMargins.Left = 0
    ItemMargins.Top = 0
    ItemMargins.Right = 0
    ItemMargins.Bottom = 0
    ParentColor = False
    TabOrder = 0
    OnBeforeDrawItem = RegionListBeforeDrawItem
    OnItemClick = RegionListItemClick
    object lblRegionName: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 0
      Width = 205
      Height = 40
      Margins.Left = 4
      Margins.Top = 0
      Margins.Bottom = 0
      Align = alLeft
      AutoSize = False
      Caption = 'lblRegionName'
      Layout = tlCenter
    end
  end
  object btnNewRegion: TButton
    Left = 24
    Top = 648
    Width = 105
    Height = 25
    Caption = 'New Region'
    TabOrder = 1
    OnClick = btnNewRegionClick
  end
  object PageControl: TPageControl
    Left = 288
    Top = 32
    Width = 640
    Height = 89
    ActivePage = tsSelection
    TabOrder = 2
    object tsNoSelection: TTabSheet
      Caption = 'tsNoSelection'
      TabVisible = False
    end
    object tsSelection: TTabSheet
      Caption = 'tsSelection'
      ImageIndex = 1
      TabVisible = False
      object lblName: TLabel
        Left = 8
        Top = 8
        Width = 38
        Height = 17
        Caption = 'Name:'
      end
      object Label2: TLabel
        Left = 8
        Top = 40
        Width = 69
        Height = 17
        Caption = 'Description:'
      end
      object edtName: TEdit
        Left = 104
        Top = 5
        Width = 265
        Height = 25
        TabOrder = 0
        Text = 'edtName'
        OnChange = edtNameChange
      end
      object edtDescription: TEdit
        Left = 104
        Top = 37
        Width = 417
        Height = 25
        TabOrder = 1
        Text = 'Edit1'
        OnChange = edtDescriptionChange
      end
    end
  end
  object BiomeList: TControlList
    Left = 944
    Top = 178
    Width = 201
    Height = 640
    ItemHeight = 45
    ItemMargins.Left = 0
    ItemMargins.Top = 0
    ItemMargins.Right = 0
    ItemMargins.Bottom = 0
    ParentColor = False
    TabOrder = 3
    OnBeforeDrawItem = BiomeListBeforeDrawItem
    OnItemClick = BiomeListItemClick
    object lblBiomeName: TLabel
      Left = 0
      Top = 0
      Width = 149
      Height = 45
      Align = alLeft
      AutoSize = False
      Caption = '(none)'
      Layout = tlCenter
      ExplicitLeft = 10
      ExplicitTop = 5
      ExplicitHeight = 34
    end
    object shBiomeMapColor: TShape
      Left = 165
      Top = 6
      Width = 32
      Height = 32
      Brush.Color = clMoneyGreen
      Pen.Style = psClear
    end
  end
end
