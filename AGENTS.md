# AGENTS.md

## Project

This repository contains a Delphi VCL markdown viewer component package, a VCL demo application, and a DUnitX test project.

- Package: `KaiMarkdownViewer.dproj` / `KaiMarkdownViewer.dpk`
- Component unit: `MarkdownViewerVCL.pas` (the `TMarkDownViewer` control)
- Supporting units:
  - `MarkdownViewer.Model.pas` - block, inline-token, and text-run model types
  - `MarkdownViewer.Parser.pas` - markdown-to-block parsing and streaming reparse
  - `MarkdownViewer.Renderer.pas` - layout and GDI rendering helpers
- Demo app: `TestApp/MarkdownViewerDemo.dproj`
- Demo forms:
  - `TestApp/Demo.IntroForm.pas` - launcher for the basic and streaming demos
  - `TestApp/Demo.MainForm.pas` - editor/preview demo
  - `TestApp/Demo.StreamingForm.pas` - incremental streaming demo
- Tests: `DUnitX/MarkdownViewerTests.dproj`
- Render tool: `Tools/MarkdownRender/MarkdownRender.dproj` - console app that renders a markdown file to a PNG (see Verifying Rendering)
- Project group: `MarkdownGroup.groupproj` (package, demo, tests, and render tool)

The component class is `TMarkDownViewer` in the `MarkdownViewerVCL` unit. The unit
splits parsing, the document model, and rendering into the three `MarkdownViewer.*`
units; keep new parser/renderer logic in those units rather than in the control.

## RAD Studio / Kai Workflow

Prefer the RAD Studio IDE-aware Kai MCP tools when files are open in the IDE.

- Use the IDE buffer as the source of truth for open files.
- Check open files with `listOpenFiles` before editing.
- Use `getEditorLines` or `getEditorContent` for open files.
- Use `applyEdit` for targeted edits in open IDE buffers.
- Use disk edits only for closed files, or when Kai cannot expose a project XML buffer.
- Do not call `reloadFile` unless the user explicitly confirms it, because it can discard unsaved IDE changes.

If an IDE buffer is modified after an edit and there is no save tool available, mirror the same verified change to disk when needed so command-line builds and future sessions see the update.

## Build And Verification

Use RAD Studio builds first when the IDE is active:

```powershell
# Via Kai:
compileProjects([
  "C:\\Users\\Alister\\Documents\\Embarcadero\\Studio\\Projects\\KaiMarkdownViewer\\KaiMarkdownViewer.dproj",
  "C:\\Users\\Alister\\Documents\\Embarcadero\\Studio\\Projects\\KaiMarkdownViewer\\TestApp\\MarkdownViewerDemo.dproj"
], true)
```

For command-line verification with RAD Studio 37.0:

```bat
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"
MSBuild KaiMarkdownViewer.dproj /t:Build /p:Config=Debug /p:Platform=Win32
```

If the public BPL output is locked because the package is loaded in RAD Studio, redirect package outputs:

```bat
MSBuild KaiMarkdownViewer.dproj /t:Build /p:Config=Debug /p:Platform=Win32 /p:DCC_BplOutput=.\Win32\Verify /p:DCC_DcpOutput=.\Win32\Verify /p:DCC_DcuOutput=.\Win32\Verify
```

For the demo, use redirected output if `MarkdownViewerDemo.exe` is running:

```bat
cd TestApp
MSBuild MarkdownViewerDemo.dproj /t:Build /p:Config=Debug /p:Platform=Win32 /p:DCC_ExeOutput=.\Win32\Verify /p:DCC_DcuOutput=.\Win32\Verify
```

Build and run the DUnitX tests:

```bat
MSBuild DUnitX\MarkdownViewerTests.dproj /t:Build /p:Config=Debug /p:Platform=Win32
DUnitX\Win32\Debug\MarkdownViewerTests.exe --exitbehavior:Continue
```

## Verifying Rendering

To check how markdown actually renders without driving the GUI, use the
`MarkdownRender` tool, which renders a markdown file to a PNG with the real
`TMarkDownViewer`. This is the reliable way to confirm visual changes (heading
rules, tables, images, spacing, etc.).

```bat
MSBuild Tools\MarkdownRender\MarkdownRender.dproj /t:Build /p:Config=Debug /p:Platform=Win32
Tools\MarkdownRender\Win32\Debug\MarkdownRender.exe input.md output.png 800
```

Write a small markdown file exercising the feature under test, render it, then
open the PNG. Prefer this over screenshotting the running demo.

## Coding Notes

- Keep the viewer native VCL/GDI; do not introduce WebView or browser dependencies without explicit user approval.
- Keep `TMarkDownViewer` usable at runtime without installing the package into the IDE.
- Preserve the demo pattern where the component is created in code.
- Prefer small, focused parser/rendering changes over broad rewrites.
- The control supports optional in-place editing (`ReadOnly`, `Undo`/`Redo`, `OnChange`).
  Edits and caret motion are mapped back to the markdown source, so keep the
  selectable-text-to-source position mapping consistent when changing parsing or layout.
- Keep source ASCII unless there is a clear Delphi/VCL reason to use Unicode text.

## Generated Files

Build outputs, local IDE metadata, package binaries, and debug executables are ignored by `.gitignore`. Do not rely on generated `Win32/`, `Win64/`, `*.dcu`, `*.bpl`, or `*.exe` files as source artifacts.
