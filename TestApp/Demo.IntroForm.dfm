object frmIntro: TfrmIntro
  Left = 0
  Top = 0
  Caption = 'Introducing Markdown Viewer'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object btnBasicDemo: TButton
    Left = 8
    Top = 8
    Width = 153
    Height = 25
    Caption = 'Basic Demo'
    TabOrder = 0
    OnClick = btnBasicDemoClick
  end
  object btnStreamingDemo: TButton
    Left = 8
    Top = 39
    Width = 153
    Height = 25
    Caption = 'Streaming Demo'
    TabOrder = 1
    OnClick = btnStreamingDemoClick
  end
end
