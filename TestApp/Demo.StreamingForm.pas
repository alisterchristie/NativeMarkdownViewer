unit Demo.StreamingForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.Math,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtDlgs,
  Vcl.ExtCtrls,
  MarkdownViewerVCL,
  Vcl.ComCtrls;

type
  TfrmStreaming = class(TForm)
    MarkDownViewer1: TMarkDownViewer;
    pnlTop: TPanel;
    OpenTextFileDialog1: TOpenTextFileDialog;
    btnLoad: TButton;
    Timer1: TTimer;
    TrackBar1: TTrackBar;
    procedure btnLoadClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Timer1Timer(Sender: TObject);
  private
    FSourcePosition: Integer;
    FSourceText: string;
  public
  end;

implementation

{$R *.dfm}

procedure TfrmStreaming.btnLoadClick(Sender: TObject);
var
  Source: TStringList;
begin
  Timer1.Enabled := False;
  if not OpenTextFileDialog1.Execute then
    Exit;

  Source := TStringList.Create;
  try
    Source.LoadFromFile(OpenTextFileDialog1.FileName);
    FSourceText := Source.Text;
  finally
    Source.Free;
  end;

  FSourcePosition := 1;
  MarkDownViewer1.BasePath := ExtractFilePath(OpenTextFileDialog1.FileName);
  MarkDownViewer1.MarkdownText := '';
  Timer1.Enabled := FSourceText <> '';
end;

procedure TfrmStreaming.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Timer1.Enabled := False;
  Action := caFree;
end;

procedure TfrmStreaming.Timer1Timer(Sender: TObject);
var
  CharacterCount: Integer;
  Chunk: string;
begin
  CharacterCount := Min(TrackBar1.Position,
    Length(FSourceText) - FSourcePosition + 1);
  if CharacterCount <= 0 then
  begin
    Timer1.Enabled := False;
    Exit;
  end;

  Chunk := Copy(FSourceText, FSourcePosition, CharacterCount);
  Inc(FSourcePosition, CharacterCount);
  MarkDownViewer1.AppendMarkdownText(Chunk);

  if FSourcePosition > Length(FSourceText) then
    Timer1.Enabled := False;
end;

end.
