# Kai Markdown Viewer

Native VCL markdown viewer component for Delphi.

`TMarkDownViewer` is a custom VCL control that renders markdown directly with VCL/GDI. It does not use WebView, HTML, or an embedded browser, and it can be created at runtime without installing the package into the IDE.

## Contents

- `MarkdownViewerVCL.pas` - component source (`TMarkDownViewer`)
- `MarkdownViewer.Model.pas` - block, inline-token, and text-run model types
- `MarkdownViewer.Parser.pas` - markdown-to-block parsing (including tail-only streaming reparse)
- `MarkdownViewer.Renderer.pas` - layout and GDI rendering helpers
- `MarkdownViewer.Highlight.pas` - pluggable code-block syntax highlighters and their registry
- `MarkdownViewer.Html.pas` - HTML export helpers
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

- Headings (`#` style and `===`/`---` setext underlines)
- Underline rule beneath H1/H2 headings (`HeadingRuleColor`, `clNone` to disable)
- Paragraphs
- Bold and italic spans
- Strikethrough spans
- Nested inline formatting (e.g. bold containing italic, or styled link text)
- Hard line breaks from two trailing spaces or a trailing backslash
- Escaped markdown punctuation
- HTML entities (named, decimal, and hex)
- Automatic links
- Angle-bracket email autolinks
- Reference-style links
- Inline code
- Fenced code blocks
- Syntax highlighting of fenced code blocks for 25+ languages (configurable via `SyntaxColors`)
- Block quotes
- Horizontal rules
- Ordered and unordered lists
- Nested list indentation
- Task lists with checked and unchecked boxes
- Clickable task checkboxes that toggle the source (`AllowTaskToggle`)
- Pipe tables with left, center, and right alignment
- Inline formatting and links inside table cells
- Local images with scaled rendering and alt-text fallback
- Clickable markdown links
- Vertical scrolling
- Keyboard scrolling
- Mouse text selection
- Copy selected markdown with `Ctrl+C`
- Copy selected plain text with `Ctrl+Shift+C`
- Read the current selection as markdown or plain text via `SelectedText`
- Case-insensitive find highlighting with next/previous navigation
- Configurable code font (`CodeFontName`, monospace fallback)
- Highlight syntax using double equals (`==highlighted==`)
- Superscript (`^sup^`) and subscript (`~sub~`) spans
- Common emoji shortcode parsing (e.g. `:smile:`, `:warning:`)
- Floating clipboard "Copy" button when hovering code blocks
- Incremental streaming with tail-only block parsing
- Optional in-place editing of the rendered markdown source
- Undo and redo of edits
- Caret navigation, insertion, and deletion mapped back to the markdown source

Strikethrough uses double tildes:

```markdown
This is ~~no longer current~~.
```

Highlighting uses double equals:

```markdown
This is ==highlighted== text.
```

Superscript uses carats, and subscript uses tildes:

```markdown
Here is a formula: E = mc^2^.
Water is H~2~O.
```

Emoji shortcodes are parsed automatically:

```markdown
This is a success :check: and a warning :warning:.
```

Inline emphasis nests, so a span can carry more than one style, and link text
can be formatted:

```markdown
This is **bold with _italic_ inside**, and a [**bold link**](https://example.com/).
```

End a line with two spaces or a backslash to force a hard line break within a
paragraph:

```markdown
First line.<two spaces>
Second line, same paragraph.
```

Prefix markdown punctuation with a backslash to render it literally:

```markdown
\*not italic\* and \[not a link\]
```

A line of text underlined with `=` or `-` becomes a heading:

```markdown
Title becomes an H1
===================

Subtitle becomes an H2
----------------------
```

HTML entities are decoded, including named, decimal, and hex forms:

```markdown
&copy; 2024 &mdash; 100&nbsp;&times;&nbsp;200, &#169;, and &#x20AC;
```

URLs using `http://`, `https://`, or `www.` are linked automatically. Angle-bracket URL and email autolinks are also supported:

```markdown
https://www.embarcadero.com/
<https://docwiki.embarcadero.com/>
<support@example.com>
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
// SearchHighlightColor auto-adapts to the background; set explicitly to override:
// Viewer.SearchHighlightColor := $00BFFFFF;
```

`FindNext` and `FindPrevious` move the selection to the next or previous match
(wrapping around the document) and scroll it into view, and `SearchMatchCount`
returns the number of matches:

```pascal
if Viewer.FindNext then
  StatusBar.SimpleText := Format('%d matches', [Viewer.SearchMatchCount]);
```

Fenced and inline code render in a monospace font you can change, with an
automatic fallback when the requested font is not installed:

```pascal
Viewer.CodeFontName := 'Cascadia Code';
```

Fenced code blocks are syntax highlighted when the opening fence carries a
language tag. The tag is matched case-insensitively against a registry of
built-in highlighters:

````markdown
```pascal
procedure Hello;
begin
  WriteLn('Hi');   // greet
end;
```
````

Built-in languages (with the fence tags that select them):

| Language | Tags |
| :--- | :--- |
| Delphi / Object Pascal | `pascal`, `objectpascal`, `objpas`, `delphi`, `pas`, `dpr`, `dpk`, `pp`, `lpr` |
| Delphi form file | `dfm` |
| C / C++ / C# | `c`; `cpp`, `c++`, `cxx`, `cc`, `hpp`; `cs`, `csharp`, `c#` |
| Java / JavaScript / TypeScript | `java`; `js`, `javascript`; `ts`, `typescript` |
| Go / Rust / PHP | `go`; `rs`, `rust`; `php` |
| Python / Ruby | `py`, `python`; `rb`, `ruby` |
| SQL | `sql` |
| HTML / XML / CSS | `html`, `htm`; `xml`; `css` |
| JSON / YAML | `json`; `yaml`, `yml` |
| Shell / INI | `sh`, `bash`, `shell`; `ini`, `cfg`, `conf` |

Token colours and font styles are exposed through the `SyntaxColors` property.
Each token kind (keyword, comment, string, number, type, preprocessor, symbol,
and plain) has a colour and a style. Colours default to `clDefault`, which
resolves to a theme-aware palette that adapts to light and dark backgrounds;
set a colour explicitly to override it:

```pascal
Viewer.SyntaxColors.KeywordColor := clNavy;
Viewer.SyntaxColors.CommentStyle := [fsItalic];
```

An unrecognized or missing language tag falls back to plain, unhighlighted
code. Additional languages can be registered at runtime with
`TMarkdownSyntaxHighlighterRegistry.RegisterHighlighter`.

Task list checkboxes are clickable by default and toggle the underlying
markdown source (set `AllowTaskToggle := False` for a static preview).

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

While editing, you can use:
- `Tab` / `Shift+Tab` on list items (bullet, numbered, or checklists) to indent/outdent the line.
- `Tab` / `Shift+Tab` on headings to increase/decrease the heading level.

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

## HTML Export

The current markdown can be exported to HTML. `AsHtml` returns an HTML fragment,
and `AsHtmlDocument` wraps it in a complete document with an optional title:

```pascal
Fragment := Viewer.AsHtml;
Page := Viewer.AsHtmlDocument('My Notes');
```

The conversion is also available without a control through
`MarkdownToHtml` / `MarkdownToHtmlDocument` in `MarkdownViewer.Html`.

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
