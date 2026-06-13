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
    ReadOnlyMenuItem: TMenuItem;
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
    pnlOptions: TPanel;
    lblHeadingColor: TLabel;
    cbbHeadingRuleColor: TColorBox;
    lblCodeBackground: TLabel;
    cbbCodeBackgroundColor: TColorBox;
    lblQuoteBar: TLabel;
    cbbQuoteBarColor: TColorBox;
    lblLinkColor: TLabel;
    cbbLinkColor: TColorBox;
    lblSearchHighlight: TLabel;
    cbbSearchHighlightColor: TColorBox;
    lblBackground: TLabel;
    cbbBackgroundColor: TColorBox;
    lblCodeFont: TLabel;
    cmbCodeFontName: TComboBox;
    btnResetProperties: TButton;
    procedure btnResetPropertiesClick(Sender: TObject);
    procedure cbbHeadingRuleColorChange(Sender: TObject);
    procedure cbbCodeBackgroundColorChange(Sender: TObject);
    procedure cbbQuoteBarColorChange(Sender: TObject);
    procedure cbbLinkColorChange(Sender: TObject);
    procedure cbbSearchHighlightColorChange(Sender: TObject);
    procedure cbbBackgroundColorChange(Sender: TObject);
    procedure cmbCodeFontNameChange(Sender: TObject);
    procedure ClearFindClick(Sender: TObject);
    procedure CopyClick(Sender: TObject);
    procedure CutClick(Sender: TObject);
    procedure DecreaseFontClick(Sender: TObject);
    procedure EditorChanged(Sender: TObject);
    procedure ExitClick(Sender: TObject);
    procedure FindChanged(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
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
    procedure ReadOnlyClick(Sender: TObject);
    procedure SaveAsClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure SelectAllClick(Sender: TObject);
    procedure ShowEditorClick(Sender: TObject);
    procedure SyncEditorToViewer(Sender: TObject);
    procedure UndoClick(Sender: TObject);
    procedure ViewerChanged(Sender: TObject);
    procedure WordWrapClick(Sender: TObject);
  private
    FCurrentFileName: string;
    FEditorWindowProc: TWndMethod;
    FLoading: Boolean;
    FModified: Boolean;
    FSyncingScroll: Boolean;
    function ConfirmSaveChanges: Boolean;
    procedure EditorWindowProc(var Message: TMessage);
    procedure FindEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FindEditKeyPress(Sender: TObject; var Key: Char);
    function GetEditorScrollRange(out Position, MaxPosition: Integer): Boolean;
    procedure LoadDocument(const FileName: string);
    procedure SetDocumentText(const Text, FileName: string);
    procedure SetModified(Value: Boolean);
    function SaveDocument(const FileName: string): Boolean;
    procedure SyncViewerToEditor;
    procedure UpdateInterface;
    procedure UpdateStatusBar;
    procedure SetupControls(Reset: Boolean);
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
  Winapi.ShellAPI,
  Winapi.Windows,
  Vcl.Graphics;

{$R *.dfm}

const
  SampleMarkdown = '''
# TMarkDownViewer

This is a native **VCL** markdown viewer component. It paints markdown text directly, supports `inline code`, and can be created at runtime - no WebView or browser required.

## Inline formatting

- **Bold**, *italic*, ***bold italic***, and ~~strikethrough~~ spans
- Nested styles such as **bold with an *italic* word** and a [**bold link**](https://www.embarcadero.com/)
- Escaped characters remain literal: \*not italic\*, \[not a link\], and \`not code\`
- Hard line breaks: this line ends with two spaces
  so it continues on the next line in the same paragraph.

Automatic links work too: https://www.embarcadero.com/ and <https://docwiki.embarcadero.com/>. Email addresses such as <support@example.com> become mailto links. [Reference-style links][docwiki] are resolved from definitions elsewhere, and the same reference can be reused, including this [DocWiki shortcut][docwiki].

HTML entities are decoded: &copy; 2024, 100&nbsp;&times;&nbsp;200, an em dash &mdash; a euro &#8364; and an &amp; itself.

Setext heading underlines
-------------------------

A line underlined with `=` or `-` becomes a heading, so the line above renders as a second-level heading.

> Block quotes stand out from the surrounding text. The component lives in the
> package, but this demo creates it in code so it does not need to be installed.

---

## Task lists (click a checkbox!)

The checkboxes below are interactive - click one in the preview to toggle it.

- [x] Render headings, lists, and inline styles
- [x] Render tables and images
  - [x] Nested completed task
  - [ ] Nested pending task
- [ ] Toggle me with the mouse

## Tables

| Feature | Status | Align Center | Align Right |
| :--- | :--- | :---: | ---: |
| **Inline styles** | Done | `code` | $100.00 |
| *Tables* | Done | [DocWiki][docwiki] | $1,500.00 |
| ~~Old API~~ | Removed | Center | $45.50 |

## Nested lists

- Top-level item
  - Nested item
    - Deeper nested item
- Another top-level item

## Images

![Sample local image alt text](sample-image.jpg)

If the image path is missing or remote, the viewer displays the alt text instead.

## Code blocks

Fenced code renders in the configurable code font (`CodeFontName`), with syntax
highlighting for over 20 languages.

### Delphi / Pascal

```pascal
var
  Viewer: TMarkDownViewer;
begin
  Viewer := TMarkDownViewer.Create(Self);
  Viewer.Parent := Self;
  Viewer.Align := alClient;
  Viewer.MarkdownText := '# Hello, **markdown**';
end;
```

### C

```c
#include <stdio.h>
#define MAX 100

int main(void) {
    for (int i = 0; i < MAX; i++) {
        if (i % 2 == 0) printf("%d\n", i);
    }
    return 0;
}
```

### C++

```cpp
#include <vector>
#include <string>

class Greeter {
    std::string name;
public:
    explicit Greeter(std::string n) : name(std::move(n)) {}
    auto greet() const -> std::string {
        return "Hello, " + name + "!";
    }
};
```

### C#

```cs
using System;
using System.Threading.Tasks;

record Person(string Name, int Age);

class Program {
    static async Task Main() {
        var p = new Person("Alice", 30);
        Console.WriteLine(p);
    }
}
```

### Java

```java
import java.util.stream.*;

public class Demo {
    public static void main(String[] args) {
        var nums = IntStream.range(1, 10)
            .filter(n -> n % 2 == 0)
            .boxed().toList();
        System.out.println(nums);
    }
}
```

### JavaScript

```js
const greet = (name) => {
  const msg = `Hello, ${name}!`;
  console.log(msg);
  return { name, msg };
};
greet("World");
```

### TypeScript

```ts
interface User {
  name: string;
  readonly id: number;
}

async function fetchUser(id: number): Promise<User> {
  const res = await fetch(`/api/user/${id}`);
  return res.json() as Promise<User>;
}
```

### Python

```python
import json

def process(items: list[int]) -> dict[str, int]:
    """Group items by parity."""
    return {
        "even": sum(1 for i in items if i % 2 == 0),
        "odd": sum(1 for i in items if i % 2 != 0),
    }

print(process([1, 2, 3, 4, 5]))
```

### Ruby

```ruby
class User
  attr_accessor :name

  def initialize(name:)
    @name = name
  end

  def greet
    "Hello, #{@name}!"
  end
end

puts User.new(name: "Alice").greet
```

### Go

```go
package main

import (
    "fmt"
    "strings"
)

func shout(s string) string {
    return strings.ToUpper(s)
}

func main() {
    fmt.Println(shout("hello"))
}
```

### Rust

```rust
fn factorial(n: u64) -> u64 {
    match n {
        0 | 1 => 1,
        _     => n * factorial(n - 1),
    }
}

fn main() {
    println!("5! = {}", factorial(5));
}
```

### PHP

```php
<?php

function greet(string $name): string {
    return "Hello, " . htmlspecialchars($name) . "!";
}

echo greet("<World>");
```

### SQL

```sql
SELECT u.name, COUNT(o.id) AS order_count
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE u.active = 1
GROUP BY u.name
HAVING COUNT(o.id) > 5
ORDER BY order_count DESC;
```

### JSON

```json
{
    "name": "my-app",
    "version": "1.0.0",
    "dependencies": {
        "react": "^18.0"
    },
    "debug": true,
    "count": 42
}
```

### YAML

```yaml
server:
  host: 0.0.0.0
  port: 8080

database:
  driver: postgresql
  pool: 10

logging:
  level: debug
```

### Shell / Bash

```sh
#!/bin/bash
# Backup script

SRC="$HOME/docs"
DST="/backup/$(date +%Y%m%d)"

if [ -d "$SRC" ]; then
    echo "Backing up $SRC to $DST"
    cp -r "$SRC" "$DST"
else
    echo "Source not found" >&2
    exit 1
fi
```

### HTML

```html
<!DOCTYPE html>
<html>
<head><title>Demo</title></head>
<body>
    <div class="container">
        <h1>TMarkDownViewer</h1>
        <p>Native VCL component.</p>
    </div>
</body>
</html>
```

### CSS

```css
.container {
    display: flex;
    justify-content: center;
    margin: 16px;
}

.title {
    font-size: 24px;
    color: #333;
}
```

### INI / Config

```ini
; Application settings
[Server]
Host=localhost
Port=8080

[Database]
Driver=PostgreSQL
ConnectionString=host=db.local;port=5432
```

---

Use the find box above to highlight matches, then press **Enter** for the next match or **Shift+Enter** for the previous one.

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

procedure TMainForm.btnResetPropertiesClick(Sender: TObject);
begin
  SetupControls(True);
end;

procedure TMainForm.cbbHeadingRuleColorChange(Sender: TObject);
begin
  Viewer.HeadingRuleColor := cbbHeadingRuleColor.Selected;
end;

procedure TMainForm.cbbCodeBackgroundColorChange(Sender: TObject);
begin
  Viewer.CodeBackgroundColor := cbbCodeBackgroundColor.Selected;
end;

procedure TMainForm.cbbQuoteBarColorChange(Sender: TObject);
begin
  Viewer.QuoteBarColor := cbbQuoteBarColor.Selected;
end;

procedure TMainForm.cbbLinkColorChange(Sender: TObject);
begin
  Viewer.LinkColor := cbbLinkColor.Selected;
end;

procedure TMainForm.cbbSearchHighlightColorChange(Sender: TObject);
begin
  Viewer.SearchHighlightColor := cbbSearchHighlightColor.Selected;
end;

procedure TMainForm.cbbBackgroundColorChange(Sender: TObject);
begin
  Viewer.Color := cbbBackgroundColor.Selected;
end;

procedure TMainForm.cmbCodeFontNameChange(Sender: TObject);
begin
  if cmbCodeFontName.Text <> '' then
    Viewer.CodeFontName := cmbCodeFontName.Text;
end;

procedure TMainForm.EditorChanged(Sender: TObject);
begin
  if FLoading then
    Exit;

  FLoading := True;
  try
    Viewer.Markdown.Assign(Editor.Lines);
  finally
    FLoading := False;
  end;
  SetModified(True);
end;

procedure TMainForm.EditorWindowProc(var Message: TMessage);
begin
  FEditorWindowProc(Message);
  if (Message.Msg = WM_VSCROLL) or (Message.Msg = WM_MOUSEWHEEL) or
    (Message.Msg = WM_KEYDOWN) then
    SyncViewerToEditor;
  if (Message.Msg = WM_KEYDOWN) or (Message.Msg = WM_LBUTTONUP) then
    UpdateStatusBar;
end;

procedure TMainForm.FindChanged(Sender: TObject);
begin
  Viewer.SearchText := FindEdit.Text;
  UpdateStatusBar;
end;

procedure TMainForm.SetupControls(Reset: Boolean);
begin
  if Reset then
  begin
    cbbHeadingRuleColor.Selected := clNone;
    Viewer.HeadingRuleColor := clNone;

    cbbCodeBackgroundColor.Selected := clDefault;
    Viewer.CodeBackgroundColor := clDefault;

    cbbQuoteBarColor.Selected := clDefault;
    Viewer.QuoteBarColor := clDefault;

    cbbLinkColor.Selected := clDefault;
    Viewer.LinkColor := clDefault;

    cbbSearchHighlightColor.Selected := clDefault;
    Viewer.SearchHighlightColor := clDefault;

    cbbBackgroundColor.Selected := clDefault;

    cmbCodeFontName.Text := 'Consolas';
    Viewer.CodeFontName := 'Consolas';
  end
  else
  begin
    cbbHeadingRuleColor.Selected := Viewer.HeadingRuleColor;
    cbbCodeBackgroundColor.Selected := Viewer.CodeBackgroundColor;
    cbbQuoteBarColor.Selected := Viewer.QuoteBarColor;
    cbbLinkColor.Selected := Viewer.LinkColor;
    cbbSearchHighlightColor.Selected := Viewer.SearchHighlightColor;
    cbbBackgroundColor.Selected := Viewer.Color;
    cmbCodeFontName.Text := Viewer.CodeFontName;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FEditorWindowProc := Editor.WindowProc;
  Editor.WindowProc := EditorWindowProc;
  OpenDialog.Filter := 'Markdown files|*.md;*.markdown;*.mdown|Text files|*.txt|All files|*.*';
  SaveDialog.Filter := OpenDialog.Filter;
  SaveDialog.DefaultExt := 'md';
  SaveDialog.Options := SaveDialog.Options + [ofOverwritePrompt, ofPathMustExist];
  SetDocumentText(SampleMarkdown, '');
  FindEdit.OnKeyDown := FindEditKeyDown;
  FindEdit.OnKeyPress := FindEditKeyPress;
  FindEdit.Text := 'markdown';
  SetupControls(False);
  UpdateInterface;
end;

procedure TMainForm.FindEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key <> VK_RETURN then
    Exit;
  if ssShift in Shift then
    Viewer.FindPrevious
  else
    Viewer.FindNext;
  Key := 0;
end;

procedure TMainForm.FindEditKeyPress(Sender: TObject; var Key: Char);
begin
  // A single-line edit beeps on Enter because there is no default button to
  // absorb it; OnKeyDown already runs the search, so swallow the character
  // here (OnKeyDown cannot suppress the translated WM_CHAR) to stop the ding.
  if CharInSet(Key, [#13, #10]) then
    Key := #0;
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
  if ShellExecute(Handle, 'open', PChar(Url), nil, nil, SW_SHOWNORMAL) <= 32 then
    MessageDlg('Unable to open the link:' + sLineBreak + Url,
      mtError, [mbOK], 0);
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
  if FindEdit.Focused then
    FindEdit.CopyToClipboard
  else if Editor.Focused then
    Editor.CopyToClipboard
  else
    Viewer.CopySelection;
end;

procedure TMainForm.CutClick(Sender: TObject);
begin
  if FindEdit.Focused then
    FindEdit.CutToClipboard
  else if Editor.CanFocus then
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

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
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
    Lines.DefaultEncoding := TEncoding.UTF8;
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
  if FindEdit.Focused then
    FindEdit.PasteFromClipboard
  else if Editor.CanFocus then
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

procedure TMainForm.ReadOnlyClick(Sender: TObject);
begin
  ReadOnlyMenuItem.Checked := not ReadOnlyMenuItem.Checked;
  Viewer.ReadOnly := ReadOnlyMenuItem.Checked;
  Editor.ReadOnly := ReadOnlyMenuItem.Checked;
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
  if FindEdit.Focused then
    FindEdit.SelectAll
  else if Viewer.Focused then
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
  if FindEdit.Focused then
    FindEdit.Undo
  else if Viewer.Focused then
    Viewer.Undo
  else if Editor.CanFocus then
  begin
    Editor.SetFocus;
    Editor.Undo;
  end;
end;

procedure TMainForm.ViewerChanged(Sender: TObject);
begin
  if FLoading then
    Exit;

  FLoading := True;
  try
    Editor.Lines.Assign(Viewer.Markdown);
  finally
    FLoading := False;
  end;
  SetModified(True);
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
  UpdateStatusBar;
  SaveMenuItem.Enabled := FModified;
  SaveButton.Enabled := FModified;
  ReloadMenuItem.Enabled := FCurrentFileName <> '';
  ReloadButton.Enabled := ReloadMenuItem.Enabled;
end;

procedure TMainForm.UpdateStatusBar;
var
  ColumnNumber: Integer;
  DocumentName: string;
  LineNumber: Integer;
  MatchCount: Integer;
  MatchPosition: Integer;
  SearchSource: string;
  SearchValue: string;
begin
  if FCurrentFileName = '' then
    DocumentName := 'Sample/unsaved document'
  else
    DocumentName := FCurrentFileName;

  LineNumber := Editor.Perform(EM_LINEFROMCHAR, Editor.SelStart, 0);
  ColumnNumber := Editor.SelStart -
    Editor.Perform(EM_LINEINDEX, LineNumber, 0);

  MatchCount := 0;
  SearchValue := LowerCase(FindEdit.Text);
  if SearchValue <> '' then
  begin
    SearchSource := LowerCase(Editor.Text);
    MatchPosition := PosEx(SearchValue, SearchSource, 1);
    while MatchPosition > 0 do
    begin
      Inc(MatchCount);
      MatchPosition := PosEx(SearchValue, SearchSource,
        MatchPosition + Length(SearchValue));
    end;
  end;

  StatusBar.SimpleText := Format('%s | Ln %d, Col %d | %d match%s',
    [DocumentName, LineNumber + 1, ColumnNumber + 1, MatchCount,
    IfThen(MatchCount = 1, '', 'es')]);
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
