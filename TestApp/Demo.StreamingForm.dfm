object frmStreaming: TfrmStreaming
  Left = 0
  Top = 0
  Caption = 'Streaming Demo'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnClose = FormClose
  TextHeight = 15
  object MarkDownViewer1: TMarkDownViewer
    Left = 0
    Top = 41
    Width = 624
    Height = 400
    Align = alClient
    ParentColor = False
    TabOrder = 0
    ExplicitLeft = 216
    ExplicitTop = 88
    ExplicitWidth = 360
    ExplicitHeight = 260
  end
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 624
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 1
    ExplicitLeft = 232
    ExplicitTop = 224
    ExplicitWidth = 185
    object btnLoad: TButton
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 75
      Height = 35
      Align = alLeft
      Caption = 'Load'
      TabOrder = 0
      OnClick = btnLoadClick
      ExplicitLeft = 280
      ExplicitTop = 16
      ExplicitHeight = 25
    end
    object TrackBar1: TTrackBar
      AlignWithMargins = True
      Left = 84
      Top = 3
      Width = 150
      Height = 35
      Align = alLeft
      Max = 100
      Min = 1
      Frequency = 10
      Position = 1
      ShowSelRange = False
      TabOrder = 1
    end
  end
  object OpenTextFileDialog1: TOpenTextFileDialog
    DefaultExt = '.md'
    Filter = 'Markdown|*.md|All Files|*.*'
    Left = 304
    Top = 224
  end
  object Timer1: TTimer
    Left = 152
    Top = 136
  end
end
