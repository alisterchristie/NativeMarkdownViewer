# AGENTS.md

## Project

This repository contains a Delphi VCL markdown viewer component package and a small VCL demo application.

- Package: `KaiMarkdownViewer.dproj` / `KaiMarkdownViewer.dpk`
- Component unit: `MarkdownViewerVCL.pas`
- Demo app: `TestApp/MarkdownViewerDemo.dproj`
- Demo form: `TestApp/Demo.MainForm.pas`

The component class is `TMarkDownViewer` in the `MarkdownViewerVCL` unit.

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

## Coding Notes

- Keep the viewer native VCL/GDI; do not introduce WebView or browser dependencies without explicit user approval.
- Keep `TMarkDownViewer` usable at runtime without installing the package into the IDE.
- Preserve the demo pattern where the component is created in code.
- Prefer small, focused parser/rendering changes over broad rewrites.
- Keep source ASCII unless there is a clear Delphi/VCL reason to use Unicode text.

## Generated Files

Build outputs, local IDE metadata, package binaries, and debug executables are ignored by `.gitignore`. Do not rely on generated `Win32/`, `Win64/`, `*.dcu`, `*.bpl`, or `*.exe` files as source artifacts.
