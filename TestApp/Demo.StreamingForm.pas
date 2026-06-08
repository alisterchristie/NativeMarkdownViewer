unit Demo.StreamingForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtDlgs,
  Vcl.ExtCtrls,
  MarkdownViewerVCL, Vcl.ComCtrls;

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
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

procedure TfrmStreaming.btnLoadClick(Sender: TObject);
begin
  if OpenTextFileDialog1.Execute then
  begin
    MarkDownViewer1.LoadFromFile(OpenTextFileDialog1.FileName);
  end;
end;

procedure TfrmStreaming.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

end.
