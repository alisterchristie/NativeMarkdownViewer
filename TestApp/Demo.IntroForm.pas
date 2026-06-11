unit Demo.IntroForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TfrmIntro = class(TForm)
    btnBasicDemo: TButton;
    btnStreamingDemo: TButton;
    cbbStyle: TComboBox;
    lblStyle: TLabel;
    procedure btnBasicDemoClick(Sender: TObject);
    procedure btnStreamingDemoClick(Sender: TObject);
  private
    FStyleFiles: TStringList; // display name -> .vsf path (as Name=Value pairs)
    procedure PopulateStyles;
    procedure StyleSelected(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  frmIntro: TfrmIntro;

implementation

uses
  System.IOUtils, Vcl.Themes, Demo.MainForm, Demo.StreamingForm;

{$R *.dfm}

const
  StylesDir = 'C:\Users\Public\Documents\Embarcadero\Studio\37.0\Styles';

function StyleIsRegistered(const AName: string): Boolean;
var
  Name: string;
begin
  for Name in TStyleManager.StyleNames do
    if SameText(Name, AName) then
      Exit(True);
  Result := False;
end;

constructor TfrmIntro.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FStyleFiles := TStringList.Create;
  cbbStyle.Style := csDropDownList;
  cbbStyle.OnChange := StyleSelected;
  PopulateStyles;
end;

destructor TfrmIntro.Destroy;
begin
  FStyleFiles.Free;
  inherited Destroy;
end;

// Lists the installed compiled (.vsf) styles plus the built-in Windows style,
// using each style's own display name.
procedure TfrmIntro.PopulateStyles;
var
  FileName: string;
  Info: TStyleInfo;
begin
  cbbStyle.Items.BeginUpdate;
  try
    cbbStyle.Items.Clear;
    FStyleFiles.Clear;
    cbbStyle.Items.Add('Windows'); // restores the default OS look
    if TDirectory.Exists(StylesDir) then
      for FileName in TDirectory.GetFiles(StylesDir, '*.vsf') do
        if TStyleManager.IsValidStyle(FileName, Info) and
          (cbbStyle.Items.IndexOf(Info.Name) < 0) then
        begin
          cbbStyle.Items.Add(Info.Name);
          FStyleFiles.Values[Info.Name] := FileName;
        end;
    cbbStyle.ItemIndex := cbbStyle.Items.IndexOf(TStyleManager.ActiveStyle.Name);
  finally
    cbbStyle.Items.EndUpdate;
  end;
end;

procedure TfrmIntro.StyleSelected(Sender: TObject);
var
  StyleName: string;
  FileName: string;
begin
  if cbbStyle.ItemIndex < 0 then
    Exit;
  StyleName := cbbStyle.Items[cbbStyle.ItemIndex];
  try
    // Load the style from disk on first use; built-in and already-loaded
    // styles are applied straight away by name.
    if not StyleIsRegistered(StyleName) then
    begin
      FileName := FStyleFiles.Values[StyleName];
      if (FileName <> '') and TStyleManager.IsValidStyle(FileName) then
        TStyleManager.LoadFromFile(FileName);
    end;
    TStyleManager.SetStyle(StyleName);
  except
    on E: Exception do
      ShowMessage(Format('Could not apply style "%s": %s', [StyleName, E.Message]));
  end;
end;

procedure TfrmIntro.btnBasicDemoClick(Sender: TObject);
begin
  TMainForm.Create(Application).Show;
end;

procedure TfrmIntro.btnStreamingDemoClick(Sender: TObject);
begin
  TfrmStreaming.Create(Application).Show;
end;

end.
