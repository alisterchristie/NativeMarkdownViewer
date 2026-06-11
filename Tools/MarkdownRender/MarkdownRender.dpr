program MarkdownRender;

// Command-line tool that renders a markdown file to a PNG image using the same
// TMarkDownViewer control as the demo, so rendering changes can be verified
// without driving the GUI. The output image is sized to fit the full document.
//
//   MarkdownRender <input.md> [output.png] [width]
//
// width defaults to 800; output defaults to the input name with a .png suffix.

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.Imaging.pngimage,
  MarkdownViewerVCL in '..\..\MarkdownViewerVCL.pas',
  MarkdownViewer.Model in '..\..\MarkdownViewer.Model.pas',
  MarkdownViewer.Parser in '..\..\MarkdownViewer.Parser.pas',
  MarkdownViewer.Renderer in '..\..\MarkdownViewer.Renderer.pas';

procedure RenderToPng(const AMarkdown, ABasePath, AOutput: string; AWidth: Integer);
var
  Host: TForm;
  Viewer: TMarkDownViewer;
  Bitmap: TBitmap;
  Png: TPngImage;
  ContentHeight: Integer;
begin
  Host := TForm.CreateNew(nil);
  try
    Host.SetBounds(0, 0, AWidth, 200);
    Viewer := TMarkDownViewer.Create(Host);
    Viewer.Parent := Host;
    Viewer.BasePath := ABasePath;
    // Measure the content height with a 1px viewport: MaxScrollPosition then
    // equals the full content height minus that single pixel.
    Viewer.SetBounds(0, 0, AWidth, 1);
    Host.Show;
    Viewer.MarkdownText := AMarkdown;
    Viewer.Repaint;
    Application.ProcessMessages;

    ContentHeight := Viewer.MaxScrollPosition + 1;
    Host.SetBounds(0, 0, AWidth, ContentHeight);
    Viewer.SetBounds(0, 0, AWidth, ContentHeight);
    Viewer.Repaint;
    Application.ProcessMessages;

    Bitmap := TBitmap.Create;
    try
      Bitmap.SetSize(Viewer.Width, Viewer.Height);
      Viewer.PaintTo(Bitmap.Canvas, 0, 0);
      Png := TPngImage.Create;
      try
        Png.Assign(Bitmap);
        Png.SaveToFile(AOutput);
      finally
        Png.Free;
      end;
    finally
      Bitmap.Free;
    end;
  finally
    Host.Free;
  end;
end;

var
  InputFile: string;
  OutputFile: string;
  Width: Integer;
  Source: TStringList;
begin
  try
    if ParamCount < 1 then
    begin
      Writeln('Usage: MarkdownRender <input.md> [output.png] [width]');
      Writeln('  Renders a markdown file to a PNG using TMarkDownViewer.');
      Writeln('  width defaults to 800; output defaults to <input>.png.');
      Halt(1);
    end;

    InputFile := ExpandFileName(ParamStr(1));
    if not FileExists(InputFile) then
    begin
      Writeln('Input file not found: ', InputFile);
      Halt(2);
    end;

    if ParamCount >= 2 then
      OutputFile := ExpandFileName(ParamStr(2))
    else
      OutputFile := ChangeFileExt(InputFile, '.png');

    if (ParamCount < 3) or not TryStrToInt(ParamStr(3), Width) then
      Width := 800;
    if Width < 50 then
      Width := 50;

    Application.Initialize;
    Source := TStringList.Create;
    try
      Source.LoadFromFile(InputFile, TEncoding.UTF8);
      RenderToPng(Source.Text, ExtractFilePath(InputFile), OutputFile, Width);
    finally
      Source.Free;
    end;
    Writeln(Format('Rendered %s -> %s (%dpx wide)', [InputFile, OutputFile, Width]));
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
