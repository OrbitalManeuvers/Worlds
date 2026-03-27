inherited BiologyEditor: TBiologyEditor
  Width = 773
  Height = 550
  Font.Height = -13
  ParentFont = False
  ExplicitWidth = 773
  ExplicitHeight = 550
  object Label1: TLabel
    Left = 16
    Top = 7
    Width = 100
    Height = 17
    Caption = 'Molecule Ratings'
  end
  object btnNewRatings: TSpeedButton
    Left = 24
    Top = 248
    Width = 81
    Height = 25
    Caption = 'New Ratings'
    OnClick = btnNewRatingsClick
  end
  object RatingsList: TControlList
    Left = 16
    Top = 32
    Width = 217
    Height = 200
    ItemHeight = 45
    ItemMargins.Left = 0
    ItemMargins.Top = 0
    ItemMargins.Right = 0
    ItemMargins.Bottom = 0
    ParentColor = False
    TabOrder = 0
    OnBeforeDrawItem = RatingsListBeforeDrawItem
    OnItemClick = RatingsListItemClick
    object lblRatingsName: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 2
      Width = 142
      Height = 41
      Margins.Left = 4
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Align = alLeft
      AutoSize = False
      Caption = 'lblRatingsName'
      Layout = tlCenter
      ExplicitLeft = 3
      ExplicitTop = 3
      ExplicitHeight = 39
    end
  end
  object Pages: TPageControl
    Left = 248
    Top = 32
    Width = 505
    Height = 361
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
      object bvAlpha: TBevel
        Left = 120
        Top = 79
        Width = 313
        Height = 50
      end
      object lblName: TLabel
        Left = 16
        Top = 19
        Width = 38
        Height = 17
        Caption = 'Name:'
      end
      object lblDescription: TLabel
        Left = 16
        Top = 47
        Width = 69
        Height = 17
        Caption = 'Description:'
      end
      object lblAlphaRating: TLabel
        Left = 136
        Top = 93
        Width = 42
        Height = 21
        Caption = 'Alpha'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object bvBeta: TBevel
        Left = 120
        Top = 136
        Width = 313
        Height = 50
      end
      object lblBetaRating: TLabel
        Left = 136
        Top = 150
        Width = 33
        Height = 21
        Caption = 'Beta'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object bvGamma: TBevel
        Left = 120
        Top = 193
        Width = 313
        Height = 50
      end
      object lblGammaRating: TLabel
        Left = 136
        Top = 207
        Width = 55
        Height = 21
        Caption = 'Gamma'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object bvBiomass: TBevel
        Left = 120
        Top = 250
        Width = 313
        Height = 50
      end
      object lblBiomassRating: TLabel
        Left = 136
        Top = 264
        Width = 60
        Height = 21
        Caption = 'Biomass'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
      end
      object Label2: TLabel
        Left = 16
        Top = 80
        Width = 62
        Height = 17
        Caption = 'Molecules:'
      end
      object edtName: TEdit
        Left = 120
        Top = 16
        Width = 169
        Height = 25
        TabOrder = 0
        Text = 'edtName'
        OnChange = edtNameChange
      end
      object edtDescription: TEdit
        Left = 120
        Top = 44
        Width = 313
        Height = 25
        TabOrder = 1
        OnChange = edtDescriptionChange
      end
      inline AlphaRatingFrame: TRatingEditorFrame
        Left = 208
        Top = 82
        Width = 205
        Height = 46
        TabOrder = 2
        ExplicitLeft = 208
        ExplicitTop = 82
      end
      inline BetaRatingFrame: TRatingEditorFrame
        Left = 208
        Top = 139
        Width = 205
        Height = 46
        TabOrder = 3
        ExplicitLeft = 208
        ExplicitTop = 139
      end
      inline GammaRatingFrame: TRatingEditorFrame
        Left = 208
        Top = 196
        Width = 205
        Height = 46
        TabOrder = 4
        ExplicitLeft = 208
        ExplicitTop = 196
      end
      inline BiomassRatingFrame: TRatingEditorFrame
        Left = 208
        Top = 253
        Width = 205
        Height = 46
        TabOrder = 5
        ExplicitLeft = 208
        ExplicitTop = 253
      end
    end
  end
end
