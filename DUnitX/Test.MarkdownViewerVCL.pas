unit Test.MarkdownViewerVCL;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TMarkDownViewerTests = class
  public
    [Test]
    procedure UsesReadableDefaultFont;
    [Test]
    procedure AppendsMarkdownWithoutReplacingExistingText;
  end;

implementation

uses
  MarkdownViewerVCL;

procedure TMarkDownViewerTests.UsesReadableDefaultFont;
var
  Viewer: TMarkDownViewer;
begin
  Viewer := TMarkDownViewer.Create(nil);
  try
    Assert.AreEqual(10, Viewer.Font.Size);
  finally
    Viewer.Free;
  end;
end;

procedure TMarkDownViewerTests.AppendsMarkdownWithoutReplacingExistingText;
var
  Viewer: TMarkDownViewer;
begin
  Viewer := TMarkDownViewer.Create(nil);
  try
    Viewer.MarkdownText := '# Heading';
    Viewer.AppendMarkdownText(sLineBreak + '- Item');
    Assert.IsTrue(Pos('# Heading', Viewer.MarkdownText) > 0);
    Assert.IsTrue(Pos('- Item', Viewer.MarkdownText) > 0);
  finally
    Viewer.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TMarkDownViewerTests);

end.
