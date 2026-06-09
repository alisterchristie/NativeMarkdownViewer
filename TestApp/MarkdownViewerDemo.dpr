program MarkdownViewerDemo;

uses
  Vcl.Forms,
  Demo.MainForm in 'Demo.MainForm.pas' {MainForm},
  MarkdownViewerVCL in '..\MarkdownViewerVCL.pas',
  MarkdownViewer.Model in '..\MarkdownViewer.Model.pas',
  MarkdownViewer.Parser in '..\MarkdownViewer.Parser.pas',
  MarkdownViewer.Renderer in '..\MarkdownViewer.Renderer.pas',
  Demo.IntroForm in 'Demo.IntroForm.pas' {frmIntro},
  Demo.StreamingForm in 'Demo.StreamingForm.pas' {frmStreaming};

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmIntro, frmIntro);
  Application.Run;
end.
