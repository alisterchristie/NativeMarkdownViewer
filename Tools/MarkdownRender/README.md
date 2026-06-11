# MarkdownRender

A small command-line tool that renders a markdown file to a PNG using the same
`TMarkDownViewer` control as the demo. It exists so rendering changes can be
verified by looking at an image, without driving the GUI.

The output image is sized to fit the full document (it measures the content
height with a 1px viewport, then captures the whole thing).

## Usage

```text
MarkdownRender <input.md> [output.png] [width]
```

- `input.md` - markdown file to render (read as UTF-8). Relative image paths
  resolve against the file's folder.
- `output.png` - optional; defaults to the input name with a `.png` suffix.
- `width` - optional pixel width; defaults to 800.

## Build and run

```bat
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"
MSBuild Tools\MarkdownRender\MarkdownRender.dproj /t:Build /p:Config=Debug /p:Platform=Win32
Tools\MarkdownRender\Win32\Debug\MarkdownRender.exe sample.md sample.png 760
```

The project is part of `MarkdownGroup.groupproj`.
