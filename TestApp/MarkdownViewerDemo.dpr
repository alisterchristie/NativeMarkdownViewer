program MarkdownViewerDemo;

uses
  Vcl.Forms,
  Demo.MainForm in 'Demo.MainForm.pas',
  MarkdownViewerVCL in '..\MarkdownViewerVCL.pas';

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
