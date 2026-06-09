object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'TMarkDownViewer Demo'
  ClientHeight = 641
  ClientWidth = 964
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  Position = poScreenCenter
  TextHeight = 15
  object Editor: TMemo
    Left = 0
    Top = 34
    Width = 390
    Height = 607
    Align = alLeft
    ScrollBars = ssBoth
    TabOrder = 0
    WordWrap = True
    OnChange = EditorChanged
  end
  object Splitter: TSplitter
    Left = 390
    Top = 34
    Width = 6
    Height = 607
  end
  object Viewer: TMarkDownViewer
    Left = 396
    Top = 34
    Width = 568
    Height = 607
    Align = alClient
    ParentColor = False
    TabOrder = 1
    OnLinkClick = LinkClicked
  end
  object FindPanel: TPanel
    Left = 0
    Top = 0
    Width = 964
    Height = 34
    Align = alTop
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 2
    object FindLabel: TLabel
      Left = 10
      Top = 9
      Width = 24
      Height = 15
      Caption = 'Find'
    end
    object FindEdit: TEdit
      Left = 48
      Top = 5
      Width = 260
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
      OnChange = FindChanged
    end
  end
end
