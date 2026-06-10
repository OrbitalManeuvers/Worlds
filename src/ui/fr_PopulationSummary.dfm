object PopulationSummaryFrame: TPopulationSummaryFrame
  Left = 0
  Top = 0
  Width = 375
  Height = 69
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = False
  TabOrder = 0
  DesignSize = (
    375
    69)
  object shBorder: TShape
    Left = 0
    Top = 0
    Width = 375
    Height = 69
    Align = alClient
    Brush.Style = bsClear
    Pen.Color = clGray
    ExplicitLeft = 368
    ExplicitTop = 40
    ExplicitWidth = 57
    ExplicitHeight = 41
  end
  object pbSummary1: TPaintBox
    AlignWithMargins = True
    Left = 4
    Top = 6
    Width = 367
    Height = 25
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Anchors = [akLeft, akTop, akRight]
    OnPaint = pbSummary1Paint
  end
  object pbSummary2: TPaintBox
    AlignWithMargins = True
    Left = 4
    Top = 37
    Width = 367
    Height = 25
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Anchors = [akLeft, akTop, akRight]
    OnPaint = pbSummary2Paint
  end
end
