unit Demo.MainForm;

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.StdCtrls,
  MarkdownViewerVCL;

type
  TMainForm = class(TForm)
    Editor: TMemo;
    FindEdit: TEdit;
    FindLabel: TLabel;
    FindPanel: TPanel;
    Splitter: TSplitter;
    Viewer: TMarkDownViewer;
    procedure EditorChanged(Sender: TObject);
    procedure FindChanged(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LinkClicked(Sender: TObject; const Url: string);
  private
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  end;

implementation

uses
  System.SysUtils,
  Winapi.Windows,
  Vcl.Dialogs;

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

procedure TMainForm.EditorChanged(Sender: TObject);
begin
  Viewer.Markdown.Assign(Editor.Lines);
end;

procedure TMainForm.FindChanged(Sender: TObject);
begin
  Viewer.SearchText := FindEdit.Text;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Editor.Lines.Text := SampleMarkdown;
  Viewer.BasePath := ExtractFilePath(Application.ExeName);
  Viewer.MarkdownText := SampleMarkdown;
  FindEdit.Text := 'markdown';
end;

procedure TMainForm.LinkClicked(Sender: TObject; const Url: string);
begin
  ShowMessage(Url);
end;

end.
