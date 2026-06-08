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
  private
    FEditor: TMemo;
    FSplitter: TSplitter;
    FViewer: TMarkDownViewer;
    procedure EditorChanged(Sender: TObject);
    procedure LinkClicked(Sender: TObject; const Url: string);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  MainForm: TMainForm;

implementation

uses
  Winapi.Windows,
  Vcl.Dialogs;

const
  SampleMarkdown = '''
# TMarkDownViewer

This is a native **VCL** markdown viewer component. It paints markdown text directly, supports `inline code`, and can be created at runtime.

## Supported examples

- Headings
- **Bold** and *italic* spans
- Ordered and unordered lists
- Nested lists
- Block quotes
- Code blocks
- Tables
- Task lists
- Local images with fallback alt text
- [Clickable links](https://www.embarcadero.com/)

> The component is in the package, but this demo creates it in code so it does not need to be installed in the IDE.

---

## Tables

| Header Column 1 | Header Column 2 | Align Center | Align Right |
| :--- | :--- | :---: | ---: |
| Left row data 1 | Sample value A | Center text | $100.00 |
| Left row data 2 | Sample value B | Center text | $1,500.00 |
| Left row data 3 | Sample value C | Center text | $45.50 |

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
''';

procedure TMainForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.ExStyle := (Params.ExStyle or WS_EX_APPWINDOW) and not WS_EX_TOOLWINDOW;
end;

constructor TMainForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := 'TMarkDownViewer Demo';
  Width := 980;
  Height := 680;
  Position := poScreenCenter;

  FEditor := TMemo.Create(Self);
  FEditor.Parent := Self;
  FEditor.Align := alLeft;
  FEditor.Width := 390;
  FEditor.ScrollBars := ssBoth;
  FEditor.WordWrap := True;
  FEditor.Lines.Text := SampleMarkdown;

  FSplitter := TSplitter.Create(Self);
  FSplitter.Parent := Self;
  FSplitter.Align := alLeft;
  FSplitter.Width := 6;

  FViewer := TMarkDownViewer.Create(Self);
  FViewer.Parent := Self;
  FViewer.Align := alClient;
  FViewer.OnLinkClick := LinkClicked;
  FViewer.MarkdownText := SampleMarkdown;
  FEditor.OnChange := EditorChanged;
end;

procedure TMainForm.EditorChanged(Sender: TObject);
begin
  if FViewer <> nil then
    FViewer.Markdown.Assign(FEditor.Lines);
end;

procedure TMainForm.LinkClicked(Sender: TObject; const Url: string);
begin
  ShowMessage(Url);
end;

end.
