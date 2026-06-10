unit Demo.MainForm;

interface

uses
  System.Classes,
  Winapi.Messages,
  Vcl.Controls,
  Vcl.ComCtrls,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Menus,
  Vcl.StdCtrls,
  MarkdownViewerVCL;

type
  TMainForm = class(TForm)
    Editor: TMemo;
    FindEdit: TEdit;
    FindLabel: TLabel;
    FindPanel: TPanel;
    MainMenu: TMainMenu;
    FileMenu: TMenuItem;
    NewMenuItem: TMenuItem;
    OpenMenuItem: TMenuItem;
    SaveMenuItem: TMenuItem;
    SaveAsMenuItem: TMenuItem;
    ReloadMenuItem: TMenuItem;
    FileSeparator: TMenuItem;
    ExitMenuItem: TMenuItem;
    EditMenu: TMenuItem;
    UndoMenuItem: TMenuItem;
    EditSeparator: TMenuItem;
    CutMenuItem: TMenuItem;
    CopyMenuItem: TMenuItem;
    PasteMenuItem: TMenuItem;
    SelectAllMenuItem: TMenuItem;
    ViewMenu: TMenuItem;
    ShowEditorMenuItem: TMenuItem;
    WordWrapMenuItem: TMenuItem;
    ViewSeparator: TMenuItem;
    IncreaseFontMenuItem: TMenuItem;
    DecreaseFontMenuItem: TMenuItem;
    ResetFontMenuItem: TMenuItem;
    HelpMenu: TMenuItem;
    LoadSampleMenuItem: TMenuItem;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    StatusBar: TStatusBar;
    OpenButton: TButton;
    SaveButton: TButton;
    ReloadButton: TButton;
    ClearFindButton: TButton;
    Splitter: TSplitter;
    Viewer: TMarkDownViewer;
    procedure ClearFindClick(Sender: TObject);
    procedure CopyClick(Sender: TObject);
    procedure CutClick(Sender: TObject);
    procedure DecreaseFontClick(Sender: TObject);
    procedure EditorChanged(Sender: TObject);
    procedure ExitClick(Sender: TObject);
    procedure FindChanged(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure IncreaseFontClick(Sender: TObject);
    procedure LinkClicked(Sender: TObject; const Url: string);
    procedure LoadSampleClick(Sender: TObject);
    procedure NewClick(Sender: TObject);
    procedure OpenClick(Sender: TObject);
    procedure PasteClick(Sender: TObject);
    procedure ReloadClick(Sender: TObject);
    procedure ResetFontClick(Sender: TObject);
    procedure SaveAsClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure SelectAllClick(Sender: TObject);
    procedure ShowEditorClick(Sender: TObject);
    procedure UndoClick(Sender: TObject);
    procedure WordWrapClick(Sender: TObject);
  private
    FCurrentFileName: string;
    FEditorWindowProc: TWndMethod;
    FLoading: Boolean;
    FModified: Boolean;
    FSyncingScroll: Boolean;
    function ConfirmSaveChanges: Boolean;
    procedure EditorWindowProc(var Message: TMessage);
    function GetEditorScrollRange(out Position, MaxPosition: Integer): Boolean;
    procedure LoadDocument(const FileName: string);
    procedure SetDocumentText(const Text, FileName: string);
    procedure SetModified(Value: Boolean);
    function SaveDocument(const FileName: string): Boolean;
    procedure SyncEditorToViewer(Sender: TObject);
    procedure SyncViewerToEditor;
    procedure UpdateInterface;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    destructor Destroy; override;
  end;

implementation

uses
  System.Math,
  System.StrUtils,
  System.SysUtils,
  System.UITypes,
  Winapi.Windows;

{$R *.dfm}

const
  SampleMarkdown = '''
# TMarkDownViewer

This is a native **VCL** markdown viewer component. It paints markdown text directly, supports `inline code`, and can be created at runtime.

## Supported examples

- Headings
- **Bold**, *italic*, and ~~strikethrough~~ spans
- Escaped markdown characters
- Automatic links
- Ordered and unordered lists
- Nested lists
- Block quotes
- Code blocks
- Tables
- Task lists
- Local images with fallback alt text
- [Clickable links](https://www.embarcadero.com/)
- Reference-style links

Automatic link examples: https://www.embarcadero.com/ and <https://docwiki.embarcadero.com/>.

[Reference-style links][docwiki] are resolved from definitions elsewhere in the markdown. The same reference can be reused, including this [DocWiki shortcut][docwiki].

The demo find box highlights every visible match for markdown.

Escaped characters remain literal: \*not italic\*, \[not a link\], and \`not code\`.

> The component is in the package, but this demo creates it in code so it does not need to be installed in the IDE.

---

## Tables

| Header Column 1 | Header Column 2 | Align Center | Align Right |
| :--- | :--- | :---: | ---: |
| **Bold row data** | Sample value A | `inline code` | $100.00 |
| Left row data 2 | *Italic value* | [DocWiki][docwiki] | $1,500.00 |
| Left row data 3 | ~~Old value~~ | Center text | $45.50 |

---

## Task Lists
- [x] Verified basic structural formatting
- [x] Verified lists and syntax blocks
  - [x] Nested completed task
  - [ ] Nested pending task
- [ ] Remaining item to be completed

---

## Nested Lists
- Top-level item
  - Nested item
    - Deeper nested item
- Another top-level item

---

## Images
![Sample local image alt text](sample-image.jpg)

If the image path is missing or remote, the viewer displays the alt text.

---

```
var
  Viewer: TMarkDownViewer;
begin
  Viewer := TMarkDownViewer.Create(Self);
  Viewer.Parent := Self;
  Viewer.Align := alClient;
end;
```

[docwiki]: https://docwiki.embarcadero.com/
''';

procedure TMainForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.ExStyle := (Params.ExStyle or WS_EX_APPWINDOW) and not WS_EX_TOOLWINDOW;
end;

destructor TMainForm.Destroy;
begin
  if Assigned(FEditorWindowProc) and (Editor <> nil) then
    Editor.WindowProc := FEditorWindowProc;
  inherited Destroy;
end;

procedure TMainForm.EditorChanged(Sender: TObject);
begin
  Viewer.Markdown.Assign(Editor.Lines);
  if not FLoading then
    SetModified(True);
end;

procedure TMainForm.EditorWindowProc(var Message: TMessage);
begin
  FEditorWindowProc(Message);
  if (Message.Msg = WM_VSCROLL) or (Message.Msg = WM_MOUSEWHEEL) or
    (Message.Msg = WM_KEYDOWN) then
    SyncViewerToEditor;
end;

procedure TMainForm.FindChanged(Sender: TObject);
begin
  Viewer.SearchText := FindEdit.Text;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Viewer := TMarkDownViewer.Create(Self);
  Viewer.Parent := Self;
  Viewer.Align := alClient;
  Viewer.OnLinkClick := LinkClicked;
  Viewer.OnScroll := SyncEditorToViewer;
  Viewer.TabOrder := 1;

  FEditorWindowProc := Editor.WindowProc;
  Editor.WindowProc := EditorWindowProc;
  OpenDialog.Filter := 'Markdown files|*.md;*.markdown;*.mdown|Text files|*.txt|All files|*.*';
  SaveDialog.Filter := OpenDialog.Filter;
  SaveDialog.DefaultExt := 'md';
  SaveDialog.Options := SaveDialog.Options + [ofOverwritePrompt, ofPathMustExist];
  SetDocumentText(SampleMarkdown, '');
  FindEdit.Text := 'markdown';
  UpdateInterface;
end;

function TMainForm.GetEditorScrollRange(out Position,
  MaxPosition: Integer): Boolean;
var
  ScrollInfo: TScrollInfo;
begin
  ZeroMemory(@ScrollInfo, SizeOf(ScrollInfo));
  ScrollInfo.cbSize := SizeOf(ScrollInfo);
  ScrollInfo.fMask := SIF_RANGE or SIF_PAGE or SIF_POS;
  Result := GetScrollInfo(Editor.Handle, SB_VERT, ScrollInfo);
  if Result then
  begin
    Position := ScrollInfo.nPos;
    MaxPosition := Max(0, ScrollInfo.nMax - Integer(ScrollInfo.nPage) + 1);
    Result := MaxPosition > 0;
  end
  else
  begin
    Position := 0;
    MaxPosition := 0;
  end;
end;

procedure TMainForm.LinkClicked(Sender: TObject; const Url: string);
begin
  ShowMessage(Url);
end;

procedure TMainForm.ClearFindClick(Sender: TObject);
begin
  FindEdit.Clear;
  FindEdit.SetFocus;
end;

function TMainForm.ConfirmSaveChanges: Boolean;
begin
  Result := True;
  if not FModified then
    Exit;

  case MessageDlg('Save changes to the current document?', mtConfirmation,
    [mbYes, mbNo, mbCancel], 0) of
    mrYes:
      Result := SaveDocument(FCurrentFileName);
    mrCancel:
      Result := False;
  end;
end;

procedure TMainForm.CopyClick(Sender: TObject);
begin
  if Editor.Focused then
    Editor.CopyToClipboard
  else
    Viewer.CopySelection;
end;

procedure TMainForm.CutClick(Sender: TObject);
begin
  if Editor.CanFocus then
  begin
    Editor.SetFocus;
    Editor.CutToClipboard;
  end;
end;

procedure TMainForm.DecreaseFontClick(Sender: TObject);
begin
  Viewer.Font.Size := Max(7, Viewer.Font.Size - 1);
  Editor.Font.Size := Max(7, Editor.Font.Size - 1);
end;

procedure TMainForm.ExitClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := ConfirmSaveChanges;
end;

procedure TMainForm.IncreaseFontClick(Sender: TObject);
begin
  Viewer.Font.Size := Min(24, Viewer.Font.Size + 1);
  Editor.Font.Size := Min(24, Editor.Font.Size + 1);
end;

procedure TMainForm.LoadDocument(const FileName: string);
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    try
      Lines.LoadFromFile(FileName);
      SetDocumentText(Lines.Text, ExpandFileName(FileName));
    except
      on E: Exception do
        MessageDlg('Unable to open the document:' + sLineBreak + E.Message,
          mtError, [mbOK], 0);
    end;
  finally
    Lines.Free;
  end;
end;

procedure TMainForm.LoadSampleClick(Sender: TObject);
begin
  if ConfirmSaveChanges then
    SetDocumentText(SampleMarkdown, '');
end;

procedure TMainForm.NewClick(Sender: TObject);
begin
  if ConfirmSaveChanges then
    SetDocumentText('', '');
end;

procedure TMainForm.OpenClick(Sender: TObject);
begin
  if ConfirmSaveChanges and OpenDialog.Execute then
    LoadDocument(OpenDialog.FileName);
end;

procedure TMainForm.PasteClick(Sender: TObject);
begin
  if Editor.CanFocus then
  begin
    Editor.SetFocus;
    Editor.PasteFromClipboard;
  end;
end;

procedure TMainForm.ReloadClick(Sender: TObject);
begin
  if (FCurrentFileName <> '') and ConfirmSaveChanges then
    LoadDocument(FCurrentFileName);
end;

procedure TMainForm.ResetFontClick(Sender: TObject);
begin
  Viewer.Font.Size := 10;
  Editor.Font.Size := 10;
end;

procedure TMainForm.SaveAsClick(Sender: TObject);
begin
  SaveDialog.FileName := FCurrentFileName;
  if SaveDialog.Execute then
    SaveDocument(SaveDialog.FileName);
end;

procedure TMainForm.SaveClick(Sender: TObject);
begin
  SaveDocument(FCurrentFileName);
end;

function TMainForm.SaveDocument(const FileName: string): Boolean;
var
  TargetFileName: string;
begin
  Result := False;
  TargetFileName := FileName;
  if TargetFileName = '' then
  begin
    SaveDialog.FileName := 'Untitled.md';
    if not SaveDialog.Execute then
      Exit;
    TargetFileName := SaveDialog.FileName;
  end;

  try
    Editor.Lines.SaveToFile(TargetFileName, TEncoding.UTF8);
    FCurrentFileName := ExpandFileName(TargetFileName);
    Viewer.BasePath := ExtractFilePath(FCurrentFileName);
    SetModified(False);
    Result := True;
  except
    on E: Exception do
      MessageDlg('Unable to save the document:' + sLineBreak + E.Message,
        mtError, [mbOK], 0);
  end;
end;

procedure TMainForm.SelectAllClick(Sender: TObject);
begin
  if Viewer.Focused then
    Viewer.SelectAll
  else if Editor.CanFocus then
  begin
    Editor.SetFocus;
    Editor.SelectAll;
  end;
end;

procedure TMainForm.SetDocumentText(const Text, FileName: string);
var
  FirstVisibleLine: Integer;
begin
  FLoading := True;
  try
    Editor.Lines.Text := Text;
    FCurrentFileName := FileName;
    if FileName <> '' then
      Viewer.BasePath := ExtractFilePath(FileName)
    else
      Viewer.BasePath := ExtractFilePath(Application.ExeName);
    Viewer.Markdown.Assign(Editor.Lines);
    Viewer.ScrollPosition := 0;
    FirstVisibleLine := Editor.Perform(EM_GETFIRSTVISIBLELINE, 0, 0);
    if FirstVisibleLine > 0 then
      Editor.Perform(EM_LINESCROLL, 0, -FirstVisibleLine);
  finally
    FLoading := False;
  end;
  SetModified(False);
end;

procedure TMainForm.SyncEditorToViewer(Sender: TObject);
var
  CurrentLine: Integer;
  MaxEditorPosition: Integer;
  TargetLine: Integer;
begin
  if FSyncingScroll or (Viewer.MaxScrollPosition = 0) or
    not GetEditorScrollRange(CurrentLine, MaxEditorPosition) then
    Exit;

  FSyncingScroll := True;
  try
    TargetLine := MulDiv(Viewer.ScrollPosition, MaxEditorPosition,
      Viewer.MaxScrollPosition);
    if TargetLine <> CurrentLine then
      Editor.Perform(EM_LINESCROLL, 0, TargetLine - CurrentLine);
  finally
    FSyncingScroll := False;
  end;
end;

procedure TMainForm.SyncViewerToEditor;
var
  FirstVisibleLine: Integer;
  MaxEditorPosition: Integer;
begin
  if FSyncingScroll or
    not GetEditorScrollRange(FirstVisibleLine, MaxEditorPosition) then
    Exit;

  FSyncingScroll := True;
  try
    Viewer.ScrollPosition := MulDiv(FirstVisibleLine,
      Viewer.MaxScrollPosition, MaxEditorPosition);
  finally
    FSyncingScroll := False;
  end;
end;

procedure TMainForm.SetModified(Value: Boolean);
begin
  FModified := Value;
  UpdateInterface;
end;

procedure TMainForm.ShowEditorClick(Sender: TObject);
begin
  ShowEditorMenuItem.Checked := not ShowEditorMenuItem.Checked;
  Editor.Visible := ShowEditorMenuItem.Checked;
  Splitter.Visible := ShowEditorMenuItem.Checked;
end;

procedure TMainForm.UndoClick(Sender: TObject);
begin
  if Editor.CanFocus then
  begin
    Editor.SetFocus;
    Editor.Undo;
  end;
end;

procedure TMainForm.UpdateInterface;
var
  DisplayName: string;
begin
  if FCurrentFileName = '' then
    DisplayName := 'Untitled'
  else
    DisplayName := ExtractFileName(FCurrentFileName);
  if FModified then
    DisplayName := DisplayName + ' *';

  Caption := DisplayName + ' - TMarkDownViewer Demo';
  StatusBar.SimpleText := IfThen(FCurrentFileName = '', 'Sample/unsaved document',
    FCurrentFileName);
  SaveMenuItem.Enabled := FModified;
  SaveButton.Enabled := FModified;
  ReloadMenuItem.Enabled := FCurrentFileName <> '';
  ReloadButton.Enabled := ReloadMenuItem.Enabled;
end;

procedure TMainForm.WordWrapClick(Sender: TObject);
begin
  WordWrapMenuItem.Checked := not WordWrapMenuItem.Checked;
  Editor.WordWrap := WordWrapMenuItem.Checked;
  if Editor.WordWrap then
    Editor.ScrollBars := ssVertical
  else
    Editor.ScrollBars := ssBoth;
end;

end.
