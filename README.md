# Kai Markdown Viewer

Native VCL markdown viewer component for Delphi.

`TMarkDownViewer` is a custom VCL control that renders markdown directly with VCL/GDI. It does not use WebView, HTML, or an embedded browser, and it can be created at runtime without installing the package into the IDE.

## Contents

- `MarkdownViewerVCL.pas` - component source
- `KaiMarkdownViewer.dpk` - Delphi package source
- `KaiMarkdownViewer.dproj` - package project
- `TestApp/MarkdownViewerDemo.dproj` - VCL demo app
- `TestApp/Demo.MainForm.pas` - demo form that creates `TMarkDownViewer` at runtime

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
- Copy selected text with `Ctrl+C`
- Case-insensitive find highlighting

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

## Demo Application

Open and run:

```text
TestApp/MarkdownViewerDemo.dproj
```

The demo creates `TMarkDownViewer` at runtime, so the package does not need to be installed into the IDE to try the component.

## Keyboard Navigation

When the viewer has focus, it supports:

- Up and Down arrows
- Page Up and Page Down
- Home and End
- Space and Shift+Space
- Ctrl+A
- Ctrl+C
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

## Notes

This is a lightweight native markdown renderer, not a full CommonMark implementation. It is intended for typical application help, notes, preview panes, and embedded documentation where native VCL rendering and simple deployment are more important than exhaustive markdown compatibility.
