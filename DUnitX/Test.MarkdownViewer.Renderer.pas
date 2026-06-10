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
    [Test]
    procedure NextAtomSplitsWhitespaceAndTextRuns;
    [Test]
    procedure NextAtomExpandsTabsToSpaces;
    [Test]
    procedure MarkdownForAtomWrapsBySingleStyle;
    [Test]
    procedure MarkdownForAtomWrapsCombinedStyles;
    [Test]
    procedure MarkdownForAtomLeavesBlankAtomUnwrapped;
    [Test]
    procedure AlignmentOffsetMatchesAlignment;
    [Test]
    procedure HeadingFontSizeDeltaClampsDeepLevels;
  end;

implementation

uses
  System.Classes,
  Vcl.Graphics,
  MarkdownViewer.Model,
  MarkdownViewer.Renderer;

function MakeToken(Style: TFontStyles; IsCode: Boolean;
  const Url: string): TMarkDownInlineToken;
begin
  Result := Default(TMarkDownInlineToken);
  Result.Style := Style;
  Result.IsCode := IsCode;
  Result.Url := Url;
end;

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

procedure TMarkDownRendererTests.NextAtomSplitsWhitespaceAndTextRuns;
var
  Index: Integer;
begin
  Index := 1;
  Assert.AreEqual('ab', NextAtom('ab cd', Index));
  Assert.AreEqual(3, Index);
  Assert.AreEqual(' ', NextAtom('ab cd', Index));
  Assert.AreEqual(4, Index);
  Assert.AreEqual('cd', NextAtom('ab cd', Index));
  Assert.AreEqual(6, Index);
end;

procedure TMarkDownRendererTests.NextAtomExpandsTabsToSpaces;
var
  Index: Integer;
begin
  Index := 1;
  Assert.AreEqual('    ', NextAtom(#9'x', Index));
  Assert.AreEqual(2, Index);
  Assert.AreEqual('x', NextAtom(#9'x', Index));
end;

procedure TMarkDownRendererTests.MarkdownForAtomWrapsBySingleStyle;
begin
  Assert.AreEqual('**x**', MarkdownForAtom(MakeToken([fsBold], False, ''), 'x'));
  Assert.AreEqual('*x*', MarkdownForAtom(MakeToken([fsItalic], False, ''), 'x'));
  Assert.AreEqual('~~x~~', MarkdownForAtom(MakeToken([fsStrikeOut], False, ''), 'x'));
  Assert.AreEqual('`x`', MarkdownForAtom(MakeToken([], True, ''), 'x'));
  Assert.AreEqual('[x](u)', MarkdownForAtom(MakeToken([], False, 'u'), 'x'));
end;

procedure TMarkDownRendererTests.MarkdownForAtomWrapsCombinedStyles;
begin
  Assert.AreEqual('***x***',
    MarkdownForAtom(MakeToken([fsBold, fsItalic], False, ''), 'x'));
  Assert.AreEqual('[**x**](u)',
    MarkdownForAtom(MakeToken([fsBold], False, 'u'), 'x'));
end;

procedure TMarkDownRendererTests.MarkdownForAtomLeavesBlankAtomUnwrapped;
begin
  Assert.AreEqual('   ', MarkdownForAtom(MakeToken([fsBold], False, ''), '   '));
end;

procedure TMarkDownRendererTests.AlignmentOffsetMatchesAlignment;
begin
  Assert.AreEqual(0, AlignmentOffset(taLeftJustify, 100));
  Assert.AreEqual(50, AlignmentOffset(taCenter, 100));
  Assert.AreEqual(100, AlignmentOffset(taRightJustify, 100));
end;

procedure TMarkDownRendererTests.HeadingFontSizeDeltaClampsDeepLevels;
begin
  Assert.AreEqual(6, HeadingFontSizeDelta(1));
  Assert.AreEqual(4, HeadingFontSizeDelta(2));
  Assert.AreEqual(2, HeadingFontSizeDelta(3));
  Assert.AreEqual(1, HeadingFontSizeDelta(4));
  Assert.AreEqual(1, HeadingFontSizeDelta(6));
end;

initialization
  TDUnitX.RegisterTestFixture(TMarkDownRendererTests);

end.
