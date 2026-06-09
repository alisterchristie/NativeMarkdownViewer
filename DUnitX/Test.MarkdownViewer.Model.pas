unit Test.MarkdownViewer.Model;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TMarkDownModelTests = class
  public
    [Test]
    procedure NewBlockHasInvalidLayout;
    [Test]
    procedure BlockOwnsInlineTokens;
  end;

implementation

uses
  MarkdownViewer.Model;

procedure TMarkDownModelTests.NewBlockHasInvalidLayout;
var
  Block: TMarkDownBlock;
begin
  Block := TMarkDownBlock.Create;
  try
    Assert.AreEqual(-1, Block.LayoutHeight);
    Assert.AreEqual(-1, Block.LayoutWidth);
  finally
    Block.Free;
  end;
end;

procedure TMarkDownModelTests.BlockOwnsInlineTokens;
var
  Block: TMarkDownBlock;
begin
  Block := TMarkDownBlock.Create;
  Block.InlineTokens := TMarkDownInlineList.Create;
  Block.InlineTokens.Add(Default(TMarkDownInlineToken));
  Assert.AreEqual(1, Block.InlineTokens.Count);
  Block.Free;
end;

initialization
  TDUnitX.RegisterTestFixture(TMarkDownModelTests);

end.
