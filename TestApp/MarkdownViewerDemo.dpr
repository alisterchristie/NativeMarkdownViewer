program MarkdownViewerDemo;

uses
  Vcl.Forms,
  Demo.MainForm in 'Demo.MainForm.pas',
  MarkdownViewerVCL in '..\MarkdownViewerVCL.pas',
  Demo.IntroForm in 'Demo.IntroForm.pas' {frmIntro},
  Demo.StreamingForm in 'Demo.StreamingForm.pas' {frmStreaming};

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmIntro, frmIntro);
  Application.Run;
end.
