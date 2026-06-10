# Kai Markdown Viewer

Native VCL markdown viewer component for Delphi.

`TMarkDownViewer` is a custom VCL control that renders markdown directly with VCL/GDI. It does not use WebView, HTML, or an embedded browser, and it can be created at runtime without installing the package into the IDE.

## Contents

- `MarkdownViewerVCL.pas` - component source (`TMarkDownViewer`)
- `MarkdownViewer.Model.pas` - block, inline-token, and text-run model types
- `MarkdownViewer.Parser.pas` - markdown-to-block parsing (including tail-only streaming reparse)
- `MarkdownViewer.Renderer.pas` - layout and GDI rendering helpers
- `KaiMarkdownViewer.dpk` - Delphi package source
- `KaiMarkdownViewer.dproj` - package project
- `MarkdownGroup.groupproj` - project group (package, demo, and tests)
- `TestApp/MarkdownViewerDemo.dproj` - VCL demo app
- `TestApp/Demo.IntroForm.pas` - launcher form for the basic and streaming demos
- `TestApp/Demo.MainForm.pas` - editor/preview demo that creates `TMarkDownViewer` at runtime
- `TestApp/Demo.StreamingForm.pas` - incremental streaming demo
- `DUnitX/MarkdownViewerTests.dproj` - DUnitX test project

## Features

Supported rendering includes:

- Headings
- Paragraphs
- Bold and italic spans
- Strikethrough spans
- Escaped markdown punctuation
- Automatic links
- Reference-style links
- Inline code
- Fenced code blocks
- Block quotes
- Horizontal rules
- Ordered and unordered lists
- Nested list indentation
- Task lists with checked and unchecked boxes
- Pipe tables with left, center, and right alignment
- Inline formatting and links inside table cells
- Local images with scaled rendering and alt-text fallback
- Clickable markdown links
- Vertical scrolling
- Keyboard scrolling
- Mouse text selection
- Copy selected markdown with `Ctrl+C`
- Copy selected plain text with `Ctrl+Shift+C`
- Case-insensitive find highlighting
- Incremental streaming with tail-only block parsing
- Optional in-place editing of the rendered markdown source
- Undo and redo of edits
- Caret navigation, insertion, and deletion mapped back to the markdown source

Strikethrough uses double tildes:

```markdown
This is ~~no longer current~~.
```

Prefix markdown punctuation with a backslash to render it literally:

```markdown
\*not italic\* and \[not a link\]
```

URLs using `http://`, `https://`, or `www.` are linked automatically. Angle-bracket autolinks are also supported:

```markdown
https://www.embarcadero.com/
<https://docwiki.embarcadero.com/>
```

Reference-style links are resolved from definitions in the markdown:

```markdown
Read the [DocWiki][docwiki].

[docwiki]: https://docwiki.embarcadero.com/
```

The table syntax supports the common markdown alignment row:

```markdown
| Header Column 1 | Header Column 2 | Align Center | Align Right |
| :--- | :--- | :---: | ---: |
| Left row data 1 | Sample value A | Center text | $100.00 |
```

Inline markdown is supported inside table cells:

```markdown
| Name | Status |
| :--- | :---: |
| **Current** | `active` |
| ~~Retired~~ | [Details](https://example.com/) |
```

Task list items are recognized in list items:

```markdown
- [x] Completed item
- [ ] Remaining item
```

Nested list indentation is based on leading spaces:

```markdown
- Parent item
  - Child item
    - Grandchild item
```

Images use standard markdown image syntax. Local paths are resolved relative to `BasePath`, or relative to the loaded markdown file when using `LoadFromFile`.

```markdown
![Alt text](images/example.png)
```

## Basic Usage

Add `MarkdownViewerVCL` to your `uses` clause and create the control like any other VCL control:

```pascal
uses
  MarkdownViewerVCL;

var
  Viewer: TMarkDownViewer;
begin
  Viewer := TMarkDownViewer.Create(Self);
  Viewer.Parent := Self;
  Viewer.Align := alClient;
  Viewer.MarkdownText := '# Hello' + sLineBreak + sLineBreak + 'This is **markdown**.';
end;
```

You can also assign lines:

```pascal
Viewer.Markdown.Assign(Memo1.Lines);
```

To highlight matching text, assign `SearchText`:

```pascal
Viewer.SearchText := 'markdown';
Viewer.SearchHighlightColor := $00BFFFFF;
```

Or load from a file:

```pascal
Viewer.LoadFromFile('README.md');
```

For streamed content, append only the newly received text. The viewer reparses the
final unstable block instead of rebuilding the complete document:

```pascal
Viewer.AppendMarkdownText(NewChunk);
```

When loading from a file, `BasePath` is set automatically to the markdown file folder so relative image paths resolve naturally. You can also set it yourself:

```pascal
Viewer.BasePath := ExtractFilePath(Application.ExeName);
```

## Links

By default, clicking a markdown link opens it with `ShellExecute`. To handle links yourself, assign `OnLinkClick`:

```pascal
Viewer.OnLinkClick :=
  procedure(Sender: TObject; const Url: string)
  begin
    ShowMessage(Url);
  end;
```

## Editing

The viewer is read-only by default. Set `ReadOnly` to `False` to edit the
markdown source directly in the rendered view; the caret, typing, and deletion
are mapped back to the underlying markdown text:

```pascal
Viewer.ReadOnly := False;
```

Edits raise `OnChange`, and `Undo`/`Redo` walk the edit history:

```pascal
Viewer.OnChange :=
  procedure(Sender: TObject)
  begin
    StatusBar.SimpleText := 'Modified';
  end;

Viewer.Undo;
Viewer.Redo;
```

`OnScroll` fires when the vertical scroll position changes, which is useful for
synchronizing an external editor or scrollbar.

## Demo Application

Open and run:

```text
TestApp/MarkdownViewerDemo.dproj
```

The demo creates `TMarkDownViewer` at runtime, so the package does not need to be
installed into the IDE to try the component. It opens an intro launcher with two
demos:

- **Basic demo** (`Demo.MainForm`) - a side-by-side editor and preview with file
  open/save/reload commands, unsaved-change prompts, an editable preview with
  undo and a read-only toggle, clipboard commands, search highlighting, editor
  visibility and word-wrap controls, and adjustable preview/editor font sizes.
- **Streaming demo** (`Demo.StreamingForm`) - loads a text file and feeds it to
  the viewer incrementally with `AppendMarkdownText`, with a trackbar that
  controls how many characters arrive per tick.

## Keyboard Navigation

When the viewer has focus, it supports:

- Up and Down arrows
- Page Up and Page Down
- Home and End
- Space and Shift+Space
- Ctrl+A
- Ctrl+C to copy selected markdown
- Ctrl+Shift+C to copy selected plain text
- Escape to clear selection

## Building

Open `KaiMarkdownViewer.dproj` in RAD Studio and build the package.

Command-line build example for RAD Studio 37.0:

```bat
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"
MSBuild KaiMarkdownViewer.dproj /t:Build /p:Config=Debug /p:Platform=Win32
```

Build the demo:

```bat
cd TestApp
MSBuild MarkdownViewerDemo.dproj /t:Build /p:Config=Debug /p:Platform=Win32
```

## Tests

The `DUnitX/MarkdownViewerTests.dproj` console project contains focused tests
for the model, parser, renderer helpers, and VCL component. It is included in
`MarkdownGroup.groupproj`.

```bat
MSBuild DUnitX\MarkdownViewerTests.dproj /t:Build /p:Config=Debug /p:Platform=Win32
DUnitX\Win32\Debug\MarkdownViewerTests.exe --exitbehavior:Continue
```

## Notes

This is a lightweight native markdown renderer, not a full CommonMark implementation. It is intended for typical application help, notes, preview panes, and embedded documentation where native VCL rendering and simple deployment are more important than exhaustive markdown compatibility.
