inherited BiomeEditor: TBiomeEditor
  Width = 1090
  Height = 587
  Font.Height = -13
  ParentFont = False
  ExplicitWidth = 1090
  ExplicitHeight = 587
  object BiomeList: TControlList
    Left = 16
    Top = 32
    Width = 249
    Height = 497
    ItemHeight = 45
    ItemMargins.Left = 0
    ItemMargins.Top = 0
    ItemMargins.Right = 0
    ItemMargins.Bottom = 0
    ParentColor = False
    TabOrder = 0
    OnBeforeDrawItem = BiomeListBeforeDrawItem
    OnItemClick = BiomeListItemClick
    object lblBiomeName: TLabel
      Left = 10
      Top = 5
      Width = 149
      Height = 34
      AutoSize = False
      Caption = '(none)'
      Layout = tlCenter
    end
    object shBiomeMapColor: TShape
      Left = 200
      Top = 6
      Width = 32
      Height = 32
      Brush.Color = clMoneyGreen
      Pen.Style = psClear
    end
  end
  object BiomePages: TPageControl
    Left = 276
    Top = 32
    Width = 797
    Height = 497
    ActivePage = tsSelection
    TabOrder = 1
    object tsNoSelection: TTabSheet
      Caption = 'tsNoSelection'
      TabVisible = False
    end
    object tsSelection: TTabSheet
      Caption = 'tsSelection'
      ImageIndex = 1
      TabVisible = False
      object Label1: TLabel
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
      object Label3: TLabel
        Left = 8
        Top = 83
        Width = 66
        Height = 17
        Caption = 'Map Color:'
      end
      object pbPresets: TPaintBox
        Left = 168
        Top = 72
        Width = 153
        Height = 41
        OnMouseDown = pbPresetsMouseDown
        OnPaint = pbPresetsPaint
      end
      object shMapColor: TShape
        Left = 112
        Top = 75
        Width = 32
        Height = 32
        Brush.Color = clActiveCaption
        Pen.Style = psClear
      end
      object edtName: TEdit
        Left = 120
        Top = 5
        Width = 209
        Height = 25
        TabOrder = 0
        TextHint = 'Name'
        OnChange = NameChanged
      end
      object edtDescription: TEdit
        Left = 120
        Top = 37
        Width = 433
        Height = 25
        TabOrder = 1
        TextHint = 'Description'
        OnChange = DescriptionChanged
      end
      object PropertyPages: TPageControl
        Left = 8
        Top = 128
        Width = 769
        Height = 345
        ActivePage = tsEnvironment
        TabOrder = 2
        object tsEnvironment: TTabSheet
          Caption = 'Environment'
          object bvSunlight: TBevel
            Left = 16
            Top = 16
            Width = 240
            Height = 137
          end
          object bvMobility: TBevel
            Left = 142
            Top = 162
            Width = 240
            Height = 137
          end
          object lblSunlight: TLabel
            Left = 104
            Top = 18
            Width = 60
            Height = 21
            Caption = 'Sunlight'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -16
            Font.Name = 'Segoe UI Semibold'
            Font.Style = []
            ParentFont = False
          end
          object lblMobility: TLabel
            Left = 231
            Top = 164
            Width = 61
            Height = 21
            Caption = 'Mobility'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -16
            Font.Name = 'Segoe UI Semibold'
            Font.Style = []
            ParentFont = False
          end
          object lblGrowthRate: TLabel
            Left = 334
            Top = 25
            Width = 91
            Height = 21
            Caption = 'Growth Rate'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -16
            Font.Name = 'Segoe UI Semibold'
            Font.Style = []
            ParentFont = False
          end
          object bvGrowthRate: TBevel
            Left = 263
            Top = 16
            Width = 240
            Height = 137
          end
          object bvDensity: TBevel
            Left = 511
            Top = 16
            Width = 240
            Height = 137
          end
          object lblDensity: TLabel
            Left = 598
            Top = 28
            Width = 54
            Height = 21
            Caption = 'Density'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -16
            Font.Name = 'Segoe UI Semibold'
            Font.Style = []
            ParentFont = False
          end
          object lblGrowthRateInfo: TLabel
            Left = 272
            Top = 102
            Width = 220
            Height = 42
            Alignment = taCenter
            AutoSize = False
            Caption = 'Can anything grow here?'
            Enabled = False
            WordWrap = True
          end
          object lblSunlightInfo: TLabel
            Left = 25
            Top = 96
            Width = 220
            Height = 42
            Alignment = taCenter
            AutoSize = False
            Caption = 'How far are you from California?'
            Color = clGrayText
            Enabled = False
            ParentColor = False
            WordWrap = True
          end
          object lblMobilityInfo: TLabel
            Left = 151
            Top = 242
            Width = 220
            Height = 42
            Alignment = taCenter
            AutoSize = False
            Caption = 'What'#39's it like moving through here?'
            Enabled = False
            WordWrap = True
          end
          object lblDensityInfo: TLabel
            Left = 520
            Top = 102
            Width = 220
            Height = 42
            Alignment = taCenter
            AutoSize = False
            Caption = 'How easy is it to find food?'
            Enabled = False
            WordWrap = True
          end
          object bvDelta: TBevel
            Left = 400
            Top = 162
            Width = 240
            Height = 137
          end
          object lblDelta: TLabel
            Left = 474
            Top = 164
            Width = 96
            Height = 21
            Caption = 'Delta Density'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -16
            Font.Name = 'Segoe UI Semibold'
            Font.Style = []
            ParentFont = False
          end
          object lblDeltaInfo: TLabel
            Left = 409
            Top = 242
            Width = 220
            Height = 42
            Alignment = taCenter
            AutoSize = False
            Caption = 'How much grows here? (at night)'
            Enabled = False
            WordWrap = True
          end
          inline SunlightEditor: TRatingEditorFrame
            Left = 35
            Top = 48
            Width = 205
            Height = 46
            TabOrder = 0
            ExplicitLeft = 35
            ExplicitTop = 48
          end
          inline MobilityEditor: TRatingEditorFrame
            Left = 166
            Top = 186
            Width = 205
            Height = 46
            TabOrder = 1
            ExplicitLeft = 166
            ExplicitTop = 186
          end
          inline GrowthEditor: TRatingEditorFrame
            Left = 279
            Top = 47
            Width = 205
            Height = 46
            TabOrder = 2
            ExplicitLeft = 279
            ExplicitTop = 47
          end
          inline DensityEditor: TRatingEditorFrame
            Left = 530
            Top = 48
            Width = 205
            Height = 46
            TabOrder = 3
            ExplicitLeft = 530
            ExplicitTop = 48
          end
          inline DeltaEditor: TRatingEditorFrame
            Left = 424
            Top = 186
            Width = 205
            Height = 46
            TabOrder = 4
            OnClick = DeltaClick
            ExplicitLeft = 424
            ExplicitTop = 186
          end
        end
        object tsFoods: TTabSheet
          Caption = 'Foods'
          ImageIndex = 1
          object FoodList: TControlList
            Left = 16
            Top = 24
            Width = 505
            Height = 273
            ItemHeight = 45
            ItemMargins.Left = 0
            ItemMargins.Top = 0
            ItemMargins.Right = 0
            ItemMargins.Bottom = 0
            ParentColor = False
            TabOrder = 0
            OnBeforeDrawItem = FoodListBeforeDrawItem
            object cbFoodActive: TControlListCheckBox
              Left = 0
              Top = 0
              Width = 44
              Height = 0
              Align = alLeft
              OnClick = cbFoodActiveClick
              ExplicitHeight = 45
            end
            object lblFoodName: TLabel
              Left = 44
              Top = 0
              Width = 169
              Height = 0
              Align = alLeft
              AutoSize = False
              Caption = 'Food name'
              Layout = tlCenter
              ExplicitLeft = 56
              ExplicitTop = 8
              ExplicitHeight = 33
            end
            object pbIngredients: TPaintBox
              Left = 240
              Top = 4
              Width = 40
              Height = 35
            end
          end
        end
      end
    end
  end
  object btnNewBiome: TButton
    Left = 16
    Top = 544
    Width = 89
    Height = 25
    Caption = 'New Biome'
    TabOrder = 2
    OnClick = btnNewBiomeClick
  end
end
