unit FormHilighterTest;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TForm51 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form51: TForm51;

const
  SQL = {SQL}
    '''
    SELECT u.name, COUNT(o.id) AS order_count
    FROM users u
    LEFT JOIN orders o ON u.id = o.user_id
    WHERE u.active = 1
    GROUP BY u.name
    HAVING COUNT(o.id) > 5
    ORDER BY order_count DESC;

    ''';
    PascalString = {Pascal}
    '''
    var
      Viewer: TMarkDownViewer;
    begin
      Viewer := TMarkDownViewer.Create(Self);
      Viewer.Parent := Self;
      Viewer.Align := alClient;
      Viewer.MarkdownText := '# Hello, **markdown**';
    end;
    ''';


implementation

{$R *.dfm}

procedure TForm51.Button1Click(Sender: TObject);
var
  Python: string;
begin
  Python := {Python}
  '''
  import json

  def process(items: list[int]) -> dict[str, int]:
      """Group items by parity."""
      return {
          "even": sum(1 for i in items if i % 2 == 0),
          "odd": sum(1 for i in items if i % 2 != 0),
      }

  print(process([1, 2, 3, 4, 5]))
  ''';
  ShowMessage(Python);
end;

procedure TForm51.Button2Click(Sender: TObject);
begin
  ShowMessage( {C++}
    '''
    #include <vector>
    #include <string>

    class Greeter {
        std::string name;
    public:
        explicit Greeter(std::string n) : name(std::move(n)) {}
        auto greet() const -> std::string {
            return "Hello, " + name + "!";
        }
    };
    '''
  );
end;

end.
