program MarkdownViewerDemo;

uses
  Vcl.Forms,
  Demo.MainForm in 'Demo.MainForm.pas' {MainForm},
  MarkdownViewerVCL in '..\MarkdownViewerVCL.pas',
  MarkdownViewer.Model in '..\MarkdownViewer.Model.pas',
  MarkdownViewer.Parser in '..\MarkdownViewer.Parser.pas',
  MarkdownViewer.Renderer in '..\MarkdownViewer.Renderer.pas',
  MarkdownViewer.Html in '..\MarkdownViewer.Html.pas',
  MarkdownViewer.Highlight in '..\MarkdownViewer.Highlight.pas',
  Demo.IntroForm in 'Demo.IntroForm.pas' {frmIntro},
  Demo.StreamingForm in 'Demo.StreamingForm.pas' {frmStreaming},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'TMarkdownViewer Demo';
  TStyleManager.TrySetStyle('Windows Modern SlateGray');
  Application.CreateForm(TfrmIntro, frmIntro);
  Application.Run;
end.
