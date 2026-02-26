inherited FoodEditor: TFoodEditor
  Width = 960
  Height = 556
  Font.Height = -13
  ParentFont = False
  StyleElements = [seClient, seBorder]
  ExplicitWidth = 960
  ExplicitHeight = 556
  object lblFoodList: TLabel
    Left = 16
    Top = 4
    Width = 87
    Height = 17
    Caption = 'Existing Foods:'
  end
  object lblProperties: TLabel
    Left = 296
    Top = 4
    Width = 150
    Height = 17
    Caption = 'Selected Food Properties:'
  end
  object FoodList: TControlList
    Left = 16
    Top = 32
    Width = 249
    Height = 457
    ItemHeight = 45
    ItemMargins.Left = 0
    ItemMargins.Top = 0
    ItemMargins.Right = 0
    ItemMargins.Bottom = 0
    ParentColor = False
    TabOrder = 0
    OnBeforeDrawItem = FoodListBeforeDrawItem
    OnItemClick = FoodListItemClick
    object lblFoodName: TLabel
      Left = 10
      Top = 5
      Width = 149
      Height = 34
      AutoSize = False
      Caption = '(none)'
      Layout = tlCenter
    end
    object pbIngredients: TPaintBox
      Left = 181
      Top = 4
      Width = 40
      Height = 35
      OnPaint = pbIngredientsPaint
    end
  end
  object FoodPages: TPageControl
    Left = 296
    Top = 32
    Width = 521
    Height = 457
    ActivePage = tsSelection
    TabOrder = 1
    object tsNoSelection: TTabSheet
      TabVisible = False
    end
    object tsSelection: TTabSheet
      ImageIndex = 1
      TabVisible = False
      object lblNameProp: TLabel
        Left = 8
        Top = 8
        Width = 38
        Height = 17
        Caption = 'Name:'
      end
      object lblGrowthRate: TLabel
        Left = 8
        Top = 41
        Width = 75
        Height = 17
        Caption = 'Growth Rate:'
      end
      object pbGrowthRate: TPaintBox
        Left = 150
        Top = 35
        Width = 148
        Height = 35
        OnPaint = pbGrowthRatePaint
      end
      object btnGrowthLess: TSpeedButton
        Left = 121
        Top = 36
        Width = 23
        Height = 35
        Caption = '<'
        OnClick = GrowthRateClick
      end
      object btnGrowthMore: TSpeedButton
        Left = 306
        Top = 35
        Width = 23
        Height = 35
        Caption = '>'
        OnClick = GrowthRateClick
      end
      object Label1: TLabel
        Left = 8
        Top = 89
        Width = 42
        Height = 17
        Caption = 'Recipe:'
      end
      object Label2: TLabel
        Left = 128
        Top = 89
        Width = 38
        Height = 17
        Caption = 'ALPHA'
      end
      object Label3: TLabel
        Left = 209
        Top = 89
        Width = 28
        Height = 17
        Caption = 'BETA'
      end
      object Label4: TLabel
        Left = 274
        Top = 89
        Width = 49
        Height = 17
        Caption = 'GAMMA'
      end
      object pbAlphaPercent: TPaintBox
        Left = 120
        Top = 112
        Width = 58
        Height = 270
        OnMouseDown = pbPercentMouseDown
        OnMouseMove = pbPercentMouseMove
        OnMouseUp = pbPercentMouseUp
        OnPaint = pbPercentPaint
      end
      object pbBetaPercent: TPaintBox
        Left = 195
        Top = 112
        Width = 58
        Height = 270
        OnMouseDown = pbPercentMouseDown
        OnMouseMove = pbPercentMouseMove
        OnMouseUp = pbPercentMouseUp
        OnPaint = pbPercentPaint
      end
      object pbGammaPercent: TPaintBox
        Left = 271
        Top = 112
        Width = 58
        Height = 270
        OnMouseDown = pbPercentMouseDown
        OnMouseMove = pbPercentMouseMove
        OnMouseUp = pbPercentMouseUp
        OnPaint = pbPercentPaint
      end
      object edtName: TEdit
        Left = 120
        Top = 5
        Width = 209
        Height = 25
        TabOrder = 0
        Text = 'edtName'
        OnChange = edtNameChange
      end
    end
  end
  object Button1: TButton
    Left = 24
    Top = 504
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 2
    OnClick = Button1Click
  end
end
