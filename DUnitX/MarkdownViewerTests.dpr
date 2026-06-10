program MarkdownViewerTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  Test.MarkdownViewer.Model in 'Test.MarkdownViewer.Model.pas',
  Test.MarkdownViewer.Parser in 'Test.MarkdownViewer.Parser.pas',
  Test.MarkdownViewer.Renderer in 'Test.MarkdownViewer.Renderer.pas',
  Test.MarkdownViewerVCL in 'Test.MarkdownViewerVCL.pas',
  Test.Demo.MainForm in 'Test.Demo.MainForm.pas',
  Demo.MainForm in '..\TestApp\Demo.MainForm.pas' {MainForm},
  MarkdownViewer.Model in '..\MarkdownViewer.Model.pas',
  MarkdownViewer.Parser in '..\MarkdownViewer.Parser.pas',
  MarkdownViewer.Renderer in '..\MarkdownViewer.Renderer.pas',
  MarkdownViewerVCL in '..\MarkdownViewerVCL.pas';

var
  Runner: ITestRunner;
  Results: IRunResults;
begin
  try
    TDUnitX.CheckCommandLine;
    Runner := TDUnitX.CreateRunner;
    Runner.UseRTTI := True;
    Runner.AddLogger(TDUnitXConsoleLogger.Create(True));
    Runner.AddLogger(TDUnitXXMLNUnitFileLogger.Create(
      TDUnitX.Options.XMLOutputFile));
    Results := Runner.Execute;
    if not Results.AllPassed then
      ExitCode := EXIT_ERRORS;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := EXIT_ERRORS;
    end;
  end;
end.
