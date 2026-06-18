program HighlighterTest;

uses
  Vcl.Forms,
  FormHilighterTest in 'FormHilighterTest.pas' {Form51};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm51, Form51);
  Application.Run;
end.
