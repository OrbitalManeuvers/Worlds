inherited WorldEditor: TWorldEditor
  Width = 954
  Height = 543
  ExplicitWidth = 954
  ExplicitHeight = 543
  object WorldList: TControlList
    Left = 8
    Top = 32
    Width = 200
    Height = 393
    ItemHeight = 45
    ItemMargins.Left = 0
    ItemMargins.Top = 0
    ItemMargins.Right = 0
    ItemMargins.Bottom = 0
    ParentColor = False
    TabOrder = 0
    OnBeforeDrawItem = WorldListBeforeDrawItem
    OnItemClick = WorldListItemClick
    object lblWorldName: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 2
      Width = 165
      Height = -4
      Margins.Left = 4
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Align = alLeft
      AutoSize = False
      Caption = 'lblWorldName'
      Layout = tlCenter
      ExplicitHeight = 41
    end
  end
  object btnNewWorld: TButton
    Left = 16
    Top = 448
    Width = 75
    Height = 25
    Caption = 'New World'
    TabOrder = 1
    OnClick = btnNewWorldClick
  end
  object Pages: TPageControl
    Left = 232
    Top = 32
    Width = 649
    Height = 481
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
        Top = 16
        Width = 35
        Height = 15
        Caption = 'Name:'
      end
      object lblDescription: TLabel
        Left = 8
        Top = 44
        Width = 63
        Height = 15
        Caption = 'Description:'
      end
      object lblLayout: TLabel
        Left = 8
        Top = 79
        Width = 39
        Height = 15
        Caption = 'Layout:'
      end
      object pbRegionLayout: TPaintBox
        Left = 104
        Top = 71
        Width = 417
        Height = 33
      end
      object edtName: TEdit
        Left = 104
        Top = 13
        Width = 169
        Height = 23
        TabOrder = 0
        TextHint = 'World name'
        OnChange = edtNameChange
      end
      object edtDescription: TEdit
        Left = 104
        Top = 41
        Width = 297
        Height = 23
        TabOrder = 1
        TextHint = 'World description'
        OnChange = edtDescriptionChange
      end
      object RegionList1: TControlList
        Left = 104
        Top = 120
        Width = 200
        Height = 121
        ItemHeight = 30
        ItemMargins.Left = 0
        ItemMargins.Top = 0
        ItemMargins.Right = 0
        ItemMargins.Bottom = 0
        ParentColor = False
        TabOrder = 2
        OnBeforeDrawItem = RegionList1BeforeDrawItem
        OnItemClick = RegionClick
        object lblRegion1: TLabel
          AlignWithMargins = True
          Left = 6
          Top = 2
          Width = -9
          Height = -4
          Margins.Left = 6
          Margins.Top = 2
          Margins.Bottom = 2
          Align = alClient
          AutoSize = False
          Caption = 'lblRegion1'
          Layout = tlCenter
          ExplicitLeft = 16
          ExplicitTop = 8
          ExplicitWidth = 56
          ExplicitHeight = 15
        end
      end
      object RegionList2: TControlList
        Left = 320
        Top = 120
        Width = 200
        Height = 121
        ItemHeight = 30
        ItemMargins.Left = 0
        ItemMargins.Top = 0
        ItemMargins.Right = 0
        ItemMargins.Bottom = 0
        ParentColor = False
        TabOrder = 3
        OnBeforeDrawItem = RegionList2BeforeDrawItem
        OnItemClick = RegionClick
        object lblRegion2: TLabel
          AlignWithMargins = True
          Left = 6
          Top = 2
          Width = -9
          Height = -4
          Margins.Left = 6
          Margins.Top = 2
          Margins.Bottom = 2
          Align = alClient
          AutoSize = False
          Caption = 'lblRegion1'
          Layout = tlCenter
          ExplicitLeft = 9
          ExplicitTop = 4
          ExplicitWidth = 187
          ExplicitHeight = 26
        end
      end
      object RegionList3: TControlList
        Left = 104
        Top = 256
        Width = 200
        Height = 121
        ItemHeight = 30
        ItemMargins.Left = 0
        ItemMargins.Top = 0
        ItemMargins.Right = 0
        ItemMargins.Bottom = 0
        ParentColor = False
        TabOrder = 4
        OnBeforeDrawItem = RegionList3BeforeDrawItem
        OnItemClick = RegionClick
        object lblRegion3: TLabel
          AlignWithMargins = True
          Left = 6
          Top = 2
          Width = -9
          Height = -4
          Margins.Left = 6
          Margins.Top = 2
          Margins.Bottom = 2
          Align = alClient
          AutoSize = False
          Caption = 'lblRegion1'
          Layout = tlCenter
          ExplicitLeft = 9
          ExplicitTop = 4
          ExplicitWidth = 187
          ExplicitHeight = 26
        end
      end
      object Regionlist4: TControlList
        Left = 320
        Top = 256
        Width = 200
        Height = 121
        ItemHeight = 30
        ItemMargins.Left = 0
        ItemMargins.Top = 0
        ItemMargins.Right = 0
        ItemMargins.Bottom = 0
        ParentColor = False
        TabOrder = 5
        OnBeforeDrawItem = Regionlist4BeforeDrawItem
        OnItemClick = RegionClick
        object lblRegion4: TLabel
          AlignWithMargins = True
          Left = 6
          Top = 2
          Width = -9
          Height = -4
          Margins.Left = 6
          Margins.Top = 2
          Margins.Bottom = 2
          Align = alClient
          AutoSize = False
          Caption = 'lblRegion1'
          Layout = tlCenter
          ExplicitLeft = 9
          ExplicitTop = 4
          ExplicitWidth = 187
          ExplicitHeight = 26
        end
      end
    end
  end
end
