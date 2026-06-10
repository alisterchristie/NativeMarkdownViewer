unit Test.Demo.MainForm;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TMainFormTests = class
  public
    [Test]
    procedure FormCanBeCreated;
  end;

implementation

uses
  Demo.MainForm;

procedure TMainFormTests.FormCanBeCreated;
var
  Form: TMainForm;
begin
  Form := TMainForm.Create(nil);
  try
    Assert.IsNotNull(Form.Viewer);
  finally
    Form.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TMainFormTests);

end.
