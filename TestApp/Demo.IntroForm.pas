unit Demo.IntroForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TfrmIntro = class(TForm)
    btnBasicDemo: TButton;
    btnStreamingDemo: TButton;
    procedure btnBasicDemoClick(Sender: TObject);
    procedure btnStreamingDemoClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmIntro: TfrmIntro;

implementation

uses
  Demo.MainForm, Demo.StreamingForm;

{$R *.dfm}

procedure TfrmIntro.btnBasicDemoClick(Sender: TObject);
begin
  TMainForm.Create(Application).Show;
end;

procedure TfrmIntro.btnStreamingDemoClick(Sender: TObject);
begin
  TfrmStreaming.Create(Application).Show;
end;

end.
