unit Test.MarkdownViewer.Renderer;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TMarkDownRendererTests = class
  public
    [Test]
    procedure CentersMarkerInColumn;
    [Test]
    procedure OversizedMarkerDoesNotMoveBeforeColumn;
    [Test]
    procedure NilCanvasStateCanBeRestored;
  end;

implementation

uses
  MarkdownViewer.Renderer;

procedure TMarkDownRendererTests.CentersMarkerInColumn;
begin
  Assert.AreEqual(107, CenterMarkerLeft(100, 22, 8));
end;

procedure TMarkDownRendererTests.OversizedMarkerDoesNotMoveBeforeColumn;
begin
  Assert.AreEqual(100, CenterMarkerLeft(100, 22, 30));
end;

procedure TMarkDownRendererTests.NilCanvasStateCanBeRestored;
var
  State: TCanvasState;
begin
  State := TCanvasState.Save(nil);
  State.Restore;
  Assert.Pass;
end;

initialization
  TDUnitX.RegisterTestFixture(TMarkDownRendererTests);

end.
