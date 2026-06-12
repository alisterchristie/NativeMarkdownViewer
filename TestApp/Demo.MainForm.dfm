object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'TMarkDownViewer Demo'
  ClientHeight = 636
  ClientWidth = 1092
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = MainMenu
  Position = poScreenCenter
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  TextHeight = 15
  object Splitter: TSplitter
    Left = 390
    Top = 34
    Width = 6
    Height = 580
    ExplicitHeight = 585
  end
  object Editor: TMemo
    Left = 0
    Top = 34
    Width = 390
    Height = 580
    Align = alLeft
    ScrollBars = ssBoth
    TabOrder = 0
    WordWrap = False
    OnChange = EditorChanged
  end
  object FindPanel: TPanel
    Left = 0
    Top = 0
    Width = 1092
    Height = 34
    Align = alTop
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 2
    DesignSize = (
      1092
      34)
    object FindLabel: TLabel
      Left = 214
      Top = 9
      Width = 23
      Height = 15
      Caption = 'Find'
    end
    object OpenButton: TButton
      Left = 6
      Top = 4
      Width = 58
      Height = 25
      Caption = 'Open'
      TabOrder = 0
      OnClick = OpenClick
    end
    object SaveButton: TButton
      Left = 68
      Top = 4
      Width = 58
      Height = 25
      Caption = 'Save'
      TabOrder = 1
      OnClick = SaveClick
    end
    object ReloadButton: TButton
      Left = 130
      Top = 4
      Width = 62
      Height = 25
      Caption = 'Reload'
      TabOrder = 2
      OnClick = ReloadClick
    end
    object FindEdit: TEdit
      Left = 252
      Top = 5
      Width = 388
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 3
      OnChange = FindChanged
    end
    object ClearFindButton: TButton
      Left = 646
      Top = 4
      Width = 58
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Clear'
      TabOrder = 4
      OnClick = ClearFindClick
    end
  end
  object Viewer: TMarkDownViewer
    Left = 396
    Top = 34
    Width = 511
    Height = 580
    Align = alClient
    CodeFontName = 'Consolas'
    HeadingRuleColor = clNone
    ReadOnly = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentColor = False
    ParentFont = False
    TabOrder = 1
    OnChange = ViewerChanged
    OnLinkClick = LinkClicked
    OnScroll = SyncEditorToViewer
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 614
    Width = 1092
    Height = 22
    Panels = <>
    SimplePanel = True
  end
  object pnlOptions: TPanel
    Left = 907
    Top = 34
    Width = 185
    Height = 580
    Align = alRight
    Caption = 'pnlProperties'
    ShowCaption = False
    TabOrder = 4
    ExplicitLeft = 913
    ExplicitTop = 40
    object lblHeadingColor: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 38
      Width = 177
      Height = 15
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Heading Rule Color'
      ExplicitTop = 4
      ExplicitWidth = 103
    end
    object lblCodeBackground: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 87
      Width = 177
      Height = 15
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Code Background Color'
      ExplicitTop = 53
      ExplicitWidth = 127
    end
    object lblQuoteBar: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 136
      Width = 177
      Height = 15
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Quote Bar Color'
      ExplicitTop = 102
      ExplicitWidth = 85
    end
    object lblLinkColor: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 185
      Width = 177
      Height = 15
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Link Color'
      ExplicitTop = 151
      ExplicitWidth = 54
    end
    object lblSearchHighlight: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 234
      Width = 177
      Height = 15
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Search Highlight Color'
      ExplicitTop = 200
      ExplicitWidth = 120
    end
    object lblBackground: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 283
      Width = 177
      Height = 15
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Background Color'
      ExplicitTop = 249
      ExplicitWidth = 96
    end
    object lblCodeFont: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 332
      Width = 177
      Height = 15
      Margins.Bottom = 0
      Align = alTop
      Caption = 'Code Font'
      ExplicitTop = 298
      ExplicitWidth = 55
    end
    object cbbHeadingRuleColor: TColorBox
      AlignWithMargins = True
      Left = 4
      Top = 56
      Width = 177
      Height = 22
      Margins.Bottom = 6
      Align = alTop
      TabOrder = 0
      OnChange = cbbHeadingRuleColorChange
      ExplicitTop = 25
    end
    object cbbCodeBackgroundColor: TColorBox
      AlignWithMargins = True
      Left = 4
      Top = 105
      Width = 177
      Height = 22
      Margins.Bottom = 6
      Align = alTop
      TabOrder = 1
      OnChange = cbbCodeBackgroundColorChange
      ExplicitTop = 74
    end
    object cbbQuoteBarColor: TColorBox
      AlignWithMargins = True
      Left = 4
      Top = 154
      Width = 177
      Height = 22
      Margins.Bottom = 6
      Align = alTop
      TabOrder = 2
      OnChange = cbbQuoteBarColorChange
      ExplicitTop = 123
    end
    object cbbLinkColor: TColorBox
      AlignWithMargins = True
      Left = 4
      Top = 203
      Width = 177
      Height = 22
      Margins.Bottom = 6
      Align = alTop
      TabOrder = 3
      OnChange = cbbLinkColorChange
      ExplicitTop = 172
    end
    object cbbSearchHighlightColor: TColorBox
      AlignWithMargins = True
      Left = 4
      Top = 252
      Width = 177
      Height = 22
      Margins.Bottom = 6
      Align = alTop
      TabOrder = 4
      OnChange = cbbSearchHighlightColorChange
      ExplicitTop = 221
    end
    object cbbBackgroundColor: TColorBox
      AlignWithMargins = True
      Left = 4
      Top = 301
      Width = 177
      Height = 22
      Margins.Bottom = 6
      Align = alTop
      TabOrder = 5
      OnChange = cbbBackgroundColorChange
      ExplicitTop = 270
    end
    object cmbCodeFontName: TComboBox
      AlignWithMargins = True
      Left = 4
      Top = 350
      Width = 177
      Height = 23
      Margins.Bottom = 6
      Align = alTop
      TabOrder = 6
      Text = 'Consolas'
      OnChange = cmbCodeFontNameChange
      Items.Strings = (
        'Consolas'
        'Courier New'
        'Cascadia Code'
        'Cascadia Mono'
        'Lucida Console'
        'Fira Code'
        'JetBrains Mono')
      ExplicitTop = 319
    end
    object btnResetProperties: TButton
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 177
      Height = 25
      Margins.Bottom = 6
      Align = alTop
      Caption = 'Reset Properties'
      TabOrder = 7
      OnClick = btnResetPropertiesClick
      ExplicitLeft = 6
      ExplicitTop = -6
      ExplicitWidth = 183
    end
  end
  object MainMenu: TMainMenu
    Left = 816
    Top = 80
    object FileMenu: TMenuItem
      Caption = '&File'
      object NewMenuItem: TMenuItem
        Caption = '&New'
        ShortCut = 16462
        OnClick = NewClick
      end
      object OpenMenuItem: TMenuItem
        Caption = '&Open...'
        ShortCut = 16463
        OnClick = OpenClick
      end
      object SaveMenuItem: TMenuItem
        Caption = '&Save'
        ShortCut = 16467
        OnClick = SaveClick
      end
      object SaveAsMenuItem: TMenuItem
        Caption = 'Save &As...'
        ShortCut = 24659
        OnClick = SaveAsClick
      end
      object ReloadMenuItem: TMenuItem
        Caption = '&Reload'
        ShortCut = 116
        OnClick = ReloadClick
      end
      object FileSeparator: TMenuItem
        Caption = '-'
      end
      object ExitMenuItem: TMenuItem
        Caption = 'E&xit'
        OnClick = ExitClick
      end
    end
    object EditMenu: TMenuItem
      Caption = '&Edit'
      object UndoMenuItem: TMenuItem
        Caption = '&Undo'
        ShortCut = 16474
        OnClick = UndoClick
      end
      object ReadOnlyMenuItem: TMenuItem
        Caption = '&Read Only'
        OnClick = ReadOnlyClick
      end
      object EditSeparator: TMenuItem
        Caption = '-'
      end
      object CutMenuItem: TMenuItem
        Caption = 'Cu&t'
        ShortCut = 16472
        OnClick = CutClick
      end
      object CopyMenuItem: TMenuItem
        Caption = '&Copy'
        ShortCut = 16451
        OnClick = CopyClick
      end
      object PasteMenuItem: TMenuItem
        Caption = '&Paste'
        ShortCut = 16470
        OnClick = PasteClick
      end
      object SelectAllMenuItem: TMenuItem
        Caption = 'Select &All'
        ShortCut = 16449
        OnClick = SelectAllClick
      end
    end
    object ViewMenu: TMenuItem
      Caption = '&View'
      object ShowEditorMenuItem: TMenuItem
        Caption = 'Show &Editor'
        Checked = True
        OnClick = ShowEditorClick
      end
      object WordWrapMenuItem: TMenuItem
        Caption = '&Word Wrap'
        OnClick = WordWrapClick
      end
      object ViewSeparator: TMenuItem
        Caption = '-'
      end
      object IncreaseFontMenuItem: TMenuItem
        Caption = 'Increase Font'
        ShortCut = 16571
        OnClick = IncreaseFontClick
      end
      object DecreaseFontMenuItem: TMenuItem
        Caption = 'Decrease Font'
        ShortCut = 16493
        OnClick = DecreaseFontClick
      end
      object ResetFontMenuItem: TMenuItem
        Caption = 'Reset Font'
        ShortCut = 16432
        OnClick = ResetFontClick
      end
    end
    object HelpMenu: TMenuItem
      Caption = '&Help'
      object LoadSampleMenuItem: TMenuItem
        Caption = 'Load &Sample Markdown'
        OnClick = LoadSampleClick
      end
    end
  end
  object OpenDialog: TOpenDialog
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Left = 816
    Top = 136
  end
  object SaveDialog: TSaveDialog
    Left = 872
    Top = 136
  end
end
