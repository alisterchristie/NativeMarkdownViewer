unit Test.MarkdownViewer.Parser;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TMarkDownParserTests = class
  public
    [Test]
    procedure ParsesHeading;
    [Test]
    procedure ParsesNestedOrderedListItem;
    [Test]
    procedure ExtractsCheckedTask;
    [Test]
    procedure RecognizesTableStart;
    [Test]
    procedure ParseBlocksJoinsParagraphLines;
    [Test]
    procedure ParseBlocksGroupsFencedCode;
    [Test]
    procedure ParseBlocksMergesQuoteLines;
    [Test]
    procedure ParseBlocksGroupsTableRows;
    [Test]
    procedure ParseBlocksSkipsLinkReferenceDefinitions;
    [Test]
    procedure ParseBlocksParsesImageBlock;
    [Test]
    procedure ParseBlocksParsesTaskListItem;
    [Test]
    procedure ParseBlocksHonorsStartLine;
    [Test]
    procedure ParseBlocksTreatsHashWithoutSpaceAsParagraph;
    [Test]
    procedure ParseBlocksRequiresSeparatorForTable;
    [Test]
    procedure ParseBlocksAddsHardBreakForTrailingSpaces;
    [Test]
    procedure ParseBlocksAddsHardBreakForTrailingBackslash;
    [Test]
    procedure ParseInlineParsesEmphasisCodeAndStrike;
    [Test]
    procedure ParseInlineParsesBoldItalic;
    [Test]
    procedure ParseInlineNestsEmphasis;
    [Test]
    procedure ParseInlineStylesLinkText;
    [Test]
    procedure ParseInlineIgnoresUnderscoreInsideWords;
    [Test]
    procedure ParseInlineIgnoresSpacedAsterisks;
    [Test]
    procedure ParseInlineRespectsEscapes;
    [Test]
    procedure ParseInlineParsesInlineLink;
    [Test]
    procedure ParseInlineStripsLinkTitle;
    [Test]
    procedure ParseInlineResolvesReferenceLink;
    [Test]
    procedure ParseInlineDetectsAutoLink;
    [Test]
    procedure ParseInlineEmitsHardLineBreakToken;
    [Test]
    procedure ParseInlineDetectsEmailAutoLink;
    [Test]
    procedure ParseInlineDecodesHtmlEntities;
    [Test]
    procedure ParseInlineLeavesInvalidEntityLiteral;
    [Test]
    procedure IsSetextUnderlineRecognizesUnderlines;
    [Test]
    procedure ParseBlocksParsesSetextHeadings;
    [Test]
    procedure ParseBlocksKeepsRuleWithoutParagraph;
    [Test]
    procedure ParseInlineLeavesUnterminatedEmphasisAsText;
    [Test]
    procedure ParseInlineLeavesUnterminatedCodeAsText;
    [Test]
    procedure ExtractLinkReferencesCollectsUrls;
    [Test]
    procedure CountLeadingSpacesCountsSpacesAndTabs;
    [Test]
    procedure TrimLeftOnlyRemovesLeadingWhitespaceOnly;
    [Test]
    procedure StartsWithFenceRecognizesIndentedFence;
    [Test]
    procedure IsRuleLineAcceptsRulesAndRejectsOthers;
    [Test]
    procedure IsPipeTableRowDetectsPipe;
    [Test]
    procedure SplitTableRowSplitsCells;
    [Test]
    procedure TryParseImageParsesAltAndUrl;
    [Test]
    procedure TryParseImageRejectsNonImage;
    [Test]
    procedure TryParseLinkReferenceParsesNameAndUrl;
    [Test]
    procedure TryParseLinkReferenceDropsTitle;
    [Test]
    procedure TryParseListItemHandlesBulletsAndNumbers;
    [Test]
    procedure TryParseListItemRejectsPlainText;
    [Test]
    procedure SourceMapMapsParagraphToSource;
    [Test]
    procedure SourceMapHandlesMultiLineParagraphJoin;
    [Test]
    procedure SourceMapHandlesHardBreakParagraph;
    [Test]
    procedure SourceMapHandlesAtxHeadingOffset;
    [Test]
    procedure SourceMapHandlesMarkupAndEntities;
    [Test]
    procedure SourceMapHandlesQuoteAcrossLines;
    [Test]
    procedure SourceMapHandlesIndentedHeading;
  end;

implementation

uses
  System.Classes,
  System.SysUtils,
  Vcl.Graphics,
  MarkdownViewer.Model,
  MarkdownViewer.Parser;

procedure TMarkDownParserTests.ParsesHeading;
var
  Text: string;
  Level: Integer;
begin
  Assert.IsTrue(TMarkDownBlockParser.TryParseHeading('### Heading', Text,
    Level));
  Assert.AreEqual(3, Level);
  Assert.AreEqual('Heading', Text);
end;

procedure TMarkDownParserTests.ParsesNestedOrderedListItem;
var
  Text: string;
  Ordered: Boolean;
  Number: Integer;
  IndentLevel: Integer;
begin
  Assert.IsTrue(TMarkDownBlockParser.TryParseListItem('    12. Item', Text,
    Ordered, Number, IndentLevel));
  Assert.IsTrue(Ordered);
  Assert.AreEqual(12, Number);
  Assert.AreEqual(2, IndentLevel);
  Assert.AreEqual('Item', Text);
end;

procedure TMarkDownParserTests.ExtractsCheckedTask;
var
  Text: string;
  IsTask: Boolean;
  Checked: Boolean;
begin
  Text := '[x] Completed';
  TMarkDownBlockParser.ExtractTaskMarker(Text, IsTask, Checked);
  Assert.IsTrue(IsTask);
  Assert.IsTrue(Checked);
  Assert.AreEqual('Completed', Text);
end;

procedure TMarkDownParserTests.RecognizesTableStart;
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('| Left | Right |');
    Lines.Add('| :--- | ---: |');
    Assert.IsTrue(TMarkDownBlockParser.IsTableStart(Lines, 0));
  finally
    Lines.Free;
  end;
end;

procedure TMarkDownParserTests.ParseBlocksJoinsParagraphLines;
var
  Blocks: TMarkDownBlockList;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  Blocks := nil;
  try
    Lines.Add('alpha bravo');
    Lines.Add('charlie');
    Blocks := TMarkDownBlockParser.ParseBlocks(Lines);
    Assert.AreEqual(1, Blocks.Count);
    Assert.IsTrue(Blocks[0].Kind = bkParagraph);
    Assert.AreEqual('alpha bravo charlie', Blocks[0].Text);
    Assert.AreEqual(0, Blocks[0].SourceStartLine);
  finally
    Blocks.Free;
    Lines.Free;
  end;
end;

procedure TMarkDownParserTests.ParseBlocksGroupsFencedCode;
var
  Blocks: TMarkDownBlockList;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  Blocks := nil;
  try
    Lines.Add('```');
    Lines.Add('line1');
    Lines.Add('line2');
    Lines.Add('```');
    Blocks := TMarkDownBlockParser.ParseBlocks(Lines);
    Assert.AreEqual(1, Blocks.Count);
    Assert.IsTrue(Blocks[0].Kind = bkCodeBlock);
    Assert.AreEqual('line1' + sLineBreak + 'line2', Blocks[0].Text);
  finally
    Blocks.Free;
    Lines.Free;
  end;
end;

procedure TMarkDownParserTests.ParseBlocksMergesQuoteLines;
var
  Blocks: TMarkDownBlockList;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  Blocks := nil;
  try
    Lines.Add('> alpha');
    Lines.Add('> bravo');
    Blocks := TMarkDownBlockParser.ParseBlocks(Lines);
    Assert.AreEqual(1, Blocks.Count);
    Assert.IsTrue(Blocks[0].Kind = bkQuote);
    Assert.AreEqual('alpha bravo', Blocks[0].Text);
  finally
    Blocks.Free;
    Lines.Free;
  end;
end;

procedure TMarkDownParserTests.ParseBlocksGroupsTableRows;
var
  Blocks: TMarkDownBlockList;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  Blocks := nil;
  try
    Lines.Add('| a | b |');
    Lines.Add('| --- | --- |');
    Lines.Add('| 1 | 2 |');
    Lines.Add('plain text');
    Blocks := TMarkDownBlockParser.ParseBlocks(Lines);
    Assert.AreEqual(2, Blocks.Count);
    Assert.IsTrue(Blocks[0].Kind = bkTable);
    Assert.IsTrue(Blocks[0].Text.Contains('| 1 | 2 |'), Blocks[0].Text);
    Assert.IsTrue(Blocks[1].Kind = bkParagraph);
  finally
    Blocks.Free;
    Lines.Free;
  end;
end;

procedure TMarkDownParserTests.ParseBlocksSkipsLinkReferenceDefinitions;
var
  Blocks: TMarkDownBlockList;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  Blocks := nil;
  try
    Lines.Add('[ref]: https://example.com');
    Blocks := TMarkDownBlockParser.ParseBlocks(Lines);
    Assert.AreEqual(0, Blocks.Count);
  finally
    Blocks.Free;
    Lines.Free;
  end;
end;

procedure TMarkDownParserTests.ParseBlocksParsesImageBlock;
var
  Blocks: TMarkDownBlockList;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  Blocks := nil;
  try
    Lines.Add('![alt text](img.png)');
    Blocks := TMarkDownBlockParser.ParseBlocks(Lines);
    Assert.AreEqual(1, Blocks.Count);
    Assert.IsTrue(Blocks[0].Kind = bkImage);
    Assert.AreEqual('alt text', Blocks[0].Text);
    Assert.AreEqual('img.png', Blocks[0].Url);
  finally
    Blocks.Free;
    Lines.Free;
  end;
end;

procedure TMarkDownParserTests.ParseBlocksParsesTaskListItem;
var
  Blocks: TMarkDownBlockList;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  Blocks := nil;
  try
    Lines.Add('- [x] Done');
    Blocks := TMarkDownBlockParser.ParseBlocks(Lines);
    Assert.AreEqual(1, Blocks.Count);
    Assert.IsTrue(Blocks[0].Kind = bkListItem);
    Assert.IsTrue(Blocks[0].IsTask);
    Assert.IsTrue(Blocks[0].TaskChecked);
    Assert.AreEqual('Done', Blocks[0].Text);
  finally
    Blocks.Free;
    Lines.Free;
  end;
end;

procedure TMarkDownParserTests.ParseBlocksHonorsStartLine;
var
  Blocks: TMarkDownBlockList;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  Blocks := nil;
  try
    Lines.Add('# alpha');
    Lines.Add('');
    Lines.Add('# bravo');
    Blocks := TMarkDownBlockParser.ParseBlocks(Lines, 2);
    Assert.AreEqual(1, Blocks.Count);
    Assert.IsTrue(Blocks[0].Kind = bkHeading);
    Assert.AreEqual('bravo', Blocks[0].Text);
    Assert.AreEqual(2, Blocks[0].SourceStartLine);
  finally
    Blocks.Free;
    Lines.Free;
  end;
end;

procedure TMarkDownParserTests.ParseBlocksTreatsHashWithoutSpaceAsParagraph;
var
  Blocks: TMarkDownBlockList;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  Blocks := nil;
  try
    Lines.Add('#tag');
    Blocks := TMarkDownBlockParser.ParseBlocks(Lines);
    Assert.AreEqual(1, Blocks.Count);
    Assert.IsTrue(Blocks[0].Kind = bkParagraph);
    Assert.AreEqual('#tag', Blocks[0].Text);
  finally
    Blocks.Free;
    Lines.Free;
  end;
end;

procedure TMarkDownParserTests.ParseBlocksRequiresSeparatorForTable;
var
  Blocks: TMarkDownBlockList;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  Blocks := nil;
  try
    Lines.Add('| a | b |');
    Blocks := TMarkDownBlockParser.ParseBlocks(Lines);
    Assert.AreEqual(1, Blocks.Count);
    Assert.IsTrue(Blocks[0].Kind = bkParagraph);
  finally
    Blocks.Free;
    Lines.Free;
  end;
end;

procedure TMarkDownParserTests.ParseBlocksAddsHardBreakForTrailingSpaces;
var
  Blocks: TMarkDownBlockList;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  Blocks := nil;
  try
    Lines.Add('first line  ');
    Lines.Add('second line');
    Blocks := TMarkDownBlockParser.ParseBlocks(Lines);
    Assert.AreEqual(1, Blocks.Count);
    Assert.IsTrue(Blocks[0].Kind = bkParagraph);
    Assert.AreEqual('first line'#10'second line', Blocks[0].Text);
  finally
    Blocks.Free;
    Lines.Free;
  end;
end;

procedure TMarkDownParserTests.ParseBlocksAddsHardBreakForTrailingBackslash;
var
  Blocks: TMarkDownBlockList;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  Blocks := nil;
  try
    Lines.Add('first line\');
    Lines.Add('second line');
    Blocks := TMarkDownBlockParser.ParseBlocks(Lines);
    Assert.AreEqual(1, Blocks.Count);
    Assert.AreEqual('first line'#10'second line', Blocks[0].Text);
  finally
    Blocks.Free;
    Lines.Free;
  end;
end;

procedure TMarkDownParserTests.ParseInlineParsesBoldItalic;
var
  Tokens: TMarkDownInlineList;
begin
  Tokens := TMarkDownBlockParser.ParseInline('***both***');
  try
    Assert.AreEqual(1, Tokens.Count);
    Assert.IsTrue(Tokens[0].Style = [fsBold, fsItalic]);
    Assert.AreEqual('both', Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TMarkDownParserTests.ParseInlineIgnoresUnderscoreInsideWords;
var
  Tokens: TMarkDownInlineList;
begin
  Tokens := TMarkDownBlockParser.ParseInline('snake_case_name');
  try
    Assert.AreEqual(1, Tokens.Count);
    Assert.IsTrue(Tokens[0].Style = []);
    Assert.AreEqual('snake_case_name', Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TMarkDownParserTests.ParseInlineIgnoresSpacedAsterisks;
var
  Tokens: TMarkDownInlineList;
begin
  Tokens := TMarkDownBlockParser.ParseInline('a * b * c');
  try
    Assert.AreEqual(1, Tokens.Count);
    Assert.IsTrue(Tokens[0].Style = []);
    Assert.AreEqual('a * b * c', Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TMarkDownParserTests.ParseInlineParsesEmphasisCodeAndStrike;
var
  Tokens: TMarkDownInlineList;
begin
  Tokens := TMarkDownBlockParser.ParseInline('a **b** *c* `d` ~~e~~');
  try
    Assert.AreEqual(8, Tokens.Count);
    Assert.IsTrue(Tokens[0].Style = []);
    Assert.AreEqual('a ', Tokens[0].Text);
    Assert.IsTrue(Tokens[1].Style = [fsBold]);
    Assert.AreEqual('b', Tokens[1].Text);
    Assert.IsTrue(Tokens[3].Style = [fsItalic]);
    Assert.AreEqual('c', Tokens[3].Text);
    Assert.IsTrue(Tokens[5].IsCode);
    Assert.AreEqual('d', Tokens[5].Text);
    Assert.IsTrue(Tokens[7].Style = [fsStrikeOut]);
    Assert.AreEqual('e', Tokens[7].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TMarkDownParserTests.ParseInlineNestsEmphasis;
var
  Tokens: TMarkDownInlineList;
begin
  Tokens := TMarkDownBlockParser.ParseInline('**bold _and italic_**');
  try
    Assert.AreEqual(2, Tokens.Count);
    Assert.IsTrue(Tokens[0].Style = [fsBold]);
    Assert.AreEqual('bold ', Tokens[0].Text);
    Assert.IsTrue(Tokens[1].Style = [fsBold, fsItalic]);
    Assert.AreEqual('and italic', Tokens[1].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TMarkDownParserTests.ParseInlineStylesLinkText;
var
  Tokens: TMarkDownInlineList;
begin
  Tokens := TMarkDownBlockParser.ParseInline('[**bold** link](https://example.com)');
  try
    Assert.AreEqual(2, Tokens.Count);
    Assert.IsTrue(Tokens[0].Style = [fsBold]);
    Assert.AreEqual('bold', Tokens[0].Text);
    Assert.AreEqual('https://example.com', Tokens[0].Url);
    Assert.IsTrue(Tokens[1].Style = []);
    Assert.AreEqual(' link', Tokens[1].Text);
    Assert.AreEqual('https://example.com', Tokens[1].Url);
  finally
    Tokens.Free;
  end;
end;

procedure TMarkDownParserTests.ParseInlineRespectsEscapes;
var
  Tokens: TMarkDownInlineList;
begin
  Tokens := TMarkDownBlockParser.ParseInline('\*not bold\*');
  try
    Assert.AreEqual(1, Tokens.Count);
    Assert.IsTrue(Tokens[0].Style = []);
    Assert.AreEqual('*not bold*', Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TMarkDownParserTests.ParseInlineParsesInlineLink;
var
  Tokens: TMarkDownInlineList;
begin
  Tokens := TMarkDownBlockParser.ParseInline('[title](https://example.com)');
  try
    Assert.AreEqual(1, Tokens.Count);
    Assert.AreEqual('title', Tokens[0].Text);
    Assert.AreEqual('https://example.com', Tokens[0].Url);
  finally
    Tokens.Free;
  end;
end;

procedure TMarkDownParserTests.ParseInlineStripsLinkTitle;
var
  Tokens: TMarkDownInlineList;
begin
  Tokens := TMarkDownBlockParser.ParseInline('[title](https://example.com "tip")');
  try
    Assert.AreEqual(1, Tokens.Count);
    Assert.AreEqual('title', Tokens[0].Text);
    Assert.AreEqual('https://example.com', Tokens[0].Url);
  finally
    Tokens.Free;
  end;
end;

procedure TMarkDownParserTests.ParseInlineResolvesReferenceLink;
var
  References: TStringList;
  Tokens: TMarkDownInlineList;
begin
  References := TStringList.Create;
  Tokens := nil;
  try
    References.Values['ref'] := 'https://example.com';
    Tokens := TMarkDownBlockParser.ParseInline('[title][ref]', References);
    Assert.AreEqual(1, Tokens.Count);
    Assert.AreEqual('title', Tokens[0].Text);
    Assert.AreEqual('https://example.com', Tokens[0].Url);
  finally
    Tokens.Free;
    References.Free;
  end;
end;

procedure TMarkDownParserTests.ParseInlineDetectsAutoLink;
var
  Tokens: TMarkDownInlineList;
begin
  Tokens := TMarkDownBlockParser.ParseInline('visit https://example.com today.');
  try
    Assert.AreEqual(3, Tokens.Count);
    Assert.AreEqual('https://example.com', Tokens[1].Url);
    Assert.IsFalse(Tokens[2].LineBreak);
    Assert.AreEqual(' today.', Tokens[2].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TMarkDownParserTests.ParseInlineEmitsHardLineBreakToken;
var
  Tokens: TMarkDownInlineList;
begin
  Tokens := TMarkDownBlockParser.ParseInline('foo'#10'bar');
  try
    Assert.AreEqual(3, Tokens.Count);
    Assert.AreEqual('foo', Tokens[0].Text);
    Assert.IsTrue(Tokens[1].LineBreak);
    Assert.AreEqual('bar', Tokens[2].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TMarkDownParserTests.ExtractLinkReferencesCollectsUrls;
var
  Lines: TStringList;
  References: TStringList;
begin
  Lines := TStringList.Create;
  References := TStringList.Create;
  try
    Lines.Add('[one]: https://one.example');
    Lines.Add('[two]: https://two.example trailing title');
    TMarkDownBlockParser.ExtractLinkReferences(Lines, References);
    Assert.AreEqual('https://one.example', References.Values['one']);
    Assert.AreEqual('https://two.example', References.Values['two']);
  finally
    References.Free;
    Lines.Free;
  end;
end;

procedure TMarkDownParserTests.ParseInlineDetectsEmailAutoLink;
var
  Tokens: TMarkDownInlineList;
begin
  Tokens := TMarkDownBlockParser.ParseInline('Mail <a@b.com> now');
  try
    Assert.AreEqual(3, Tokens.Count);
    Assert.AreEqual('Mail ', Tokens[0].Text);
    Assert.AreEqual('a@b.com', Tokens[1].Text);
    Assert.AreEqual('mailto:a@b.com', Tokens[1].Url);
    Assert.AreEqual(' now', Tokens[2].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TMarkDownParserTests.ParseInlineDecodesHtmlEntities;
var
  Tokens: TMarkDownInlineList;
begin
  Tokens := TMarkDownBlockParser.ParseInline('A &amp; B &copy; C &#169; D &#x2122;');
  try
    Assert.AreEqual(1, Tokens.Count);
    Assert.AreEqual('A & B ' + #$00A9 + ' C ' + #$00A9 + ' D ' + #$2122,
      Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TMarkDownParserTests.ParseInlineLeavesInvalidEntityLiteral;
var
  Tokens: TMarkDownInlineList;
begin
  Tokens := TMarkDownBlockParser.ParseInline('AT&T and R&D');
  try
    Assert.AreEqual(1, Tokens.Count);
    Assert.AreEqual('AT&T and R&D', Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TMarkDownParserTests.IsSetextUnderlineRecognizesUnderlines;
var
  Level: Integer;
begin
  Assert.IsTrue(TMarkDownBlockParser.IsSetextUnderline('===', Level));
  Assert.AreEqual(1, Level);
  Assert.IsTrue(TMarkDownBlockParser.IsSetextUnderline('-----', Level));
  Assert.AreEqual(2, Level);
  Assert.IsFalse(TMarkDownBlockParser.IsSetextUnderline('-x-', Level));
  Assert.IsFalse(TMarkDownBlockParser.IsSetextUnderline('', Level));
end;

procedure TMarkDownParserTests.ParseBlocksParsesSetextHeadings;
var
  Blocks: TMarkDownBlockList;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  Blocks := nil;
  try
    Lines.Add('Title One');
    Lines.Add('===');
    Lines.Add('');
    Lines.Add('Title Two');
    Lines.Add('---');
    Blocks := TMarkDownBlockParser.ParseBlocks(Lines);
    Assert.AreEqual(2, Blocks.Count);
    Assert.IsTrue(Blocks[0].Kind = bkHeading);
    Assert.AreEqual(1, Blocks[0].Level);
    Assert.AreEqual('Title One', Blocks[0].Text);
    Assert.IsTrue(Blocks[1].Kind = bkHeading);
    Assert.AreEqual(2, Blocks[1].Level);
    Assert.AreEqual('Title Two', Blocks[1].Text);
  finally
    Blocks.Free;
    Lines.Free;
  end;
end;

procedure TMarkDownParserTests.ParseBlocksKeepsRuleWithoutParagraph;
var
  Blocks: TMarkDownBlockList;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  Blocks := nil;
  try
    Lines.Add('text');
    Lines.Add('');
    Lines.Add('---');
    Blocks := TMarkDownBlockParser.ParseBlocks(Lines);
    Assert.AreEqual(2, Blocks.Count);
    Assert.IsTrue(Blocks[0].Kind = bkParagraph);
    Assert.IsTrue(Blocks[1].Kind = bkRule);
  finally
    Blocks.Free;
    Lines.Free;
  end;
end;

procedure TMarkDownParserTests.ParseInlineLeavesUnterminatedEmphasisAsText;
var
  Tokens: TMarkDownInlineList;
begin
  Tokens := TMarkDownBlockParser.ParseInline('**unterminated');
  try
    Assert.AreEqual(1, Tokens.Count);
    Assert.IsTrue(Tokens[0].Style = []);
    Assert.AreEqual('**unterminated', Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TMarkDownParserTests.ParseInlineLeavesUnterminatedCodeAsText;
var
  Tokens: TMarkDownInlineList;
begin
  Tokens := TMarkDownBlockParser.ParseInline('`code');
  try
    Assert.AreEqual(1, Tokens.Count);
    Assert.IsFalse(Tokens[0].IsCode);
    Assert.AreEqual('`code', Tokens[0].Text);
  finally
    Tokens.Free;
  end;
end;

procedure TMarkDownParserTests.CountLeadingSpacesCountsSpacesAndTabs;
begin
  Assert.AreEqual(3, TMarkDownBlockParser.CountLeadingSpaces('   x'));
  Assert.AreEqual(4, TMarkDownBlockParser.CountLeadingSpaces(#9'x'));
  Assert.AreEqual(6, TMarkDownBlockParser.CountLeadingSpaces('  '#9'x'));
  Assert.AreEqual(0, TMarkDownBlockParser.CountLeadingSpaces('x'));
end;

procedure TMarkDownParserTests.TrimLeftOnlyRemovesLeadingWhitespaceOnly;
begin
  Assert.AreEqual('abc  ', TMarkDownBlockParser.TrimLeftOnly('   abc  '));
  Assert.AreEqual('x', TMarkDownBlockParser.TrimLeftOnly(#9#9'x'));
  Assert.AreEqual('abc', TMarkDownBlockParser.TrimLeftOnly('abc'));
end;

procedure TMarkDownParserTests.StartsWithFenceRecognizesIndentedFence;
begin
  Assert.IsTrue(TMarkDownBlockParser.StartsWithFence('```'));
  Assert.IsTrue(TMarkDownBlockParser.StartsWithFence('```pascal'));
  Assert.IsTrue(TMarkDownBlockParser.StartsWithFence('   ```'));
  Assert.IsFalse(TMarkDownBlockParser.StartsWithFence('``'));
  Assert.IsFalse(TMarkDownBlockParser.StartsWithFence('text'));
end;

procedure TMarkDownParserTests.IsRuleLineAcceptsRulesAndRejectsOthers;
begin
  Assert.IsTrue(TMarkDownBlockParser.IsRuleLine('---'));
  Assert.IsTrue(TMarkDownBlockParser.IsRuleLine('***'));
  Assert.IsTrue(TMarkDownBlockParser.IsRuleLine('___'));
  Assert.IsTrue(TMarkDownBlockParser.IsRuleLine('- - -'));
  Assert.IsFalse(TMarkDownBlockParser.IsRuleLine('--'));
  Assert.IsFalse(TMarkDownBlockParser.IsRuleLine('-*-'));
  Assert.IsFalse(TMarkDownBlockParser.IsRuleLine('abc'));
end;

procedure TMarkDownParserTests.IsPipeTableRowDetectsPipe;
begin
  Assert.IsTrue(TMarkDownBlockParser.IsPipeTableRow('| a | b |'));
  Assert.IsTrue(TMarkDownBlockParser.IsPipeTableRow('a | b'));
  Assert.IsFalse(TMarkDownBlockParser.IsPipeTableRow('plain'));
  Assert.IsFalse(TMarkDownBlockParser.IsPipeTableRow(''));
end;

procedure TMarkDownParserTests.SplitTableRowSplitsCells;
var
  Cells: TStringList;
begin
  Cells := TStringList.Create;
  try
    TMarkDownBlockParser.SplitTableRow('| a | b |', Cells);
    Assert.AreEqual(2, Cells.Count);
    Assert.AreEqual('a', Cells[0]);
    Assert.AreEqual('b', Cells[1]);

    TMarkDownBlockParser.SplitTableRow('one | two', Cells);
    Assert.AreEqual(2, Cells.Count);
    Assert.AreEqual('one', Cells[0]);
    Assert.AreEqual('two', Cells[1]);
  finally
    Cells.Free;
  end;
end;

procedure TMarkDownParserTests.TryParseImageParsesAltAndUrl;
var
  AltText: string;
  Url: string;
begin
  Assert.IsTrue(TMarkDownBlockParser.TryParseImage('![alt](pic.png)', AltText, Url));
  Assert.AreEqual('alt', AltText);
  Assert.AreEqual('pic.png', Url);
end;

procedure TMarkDownParserTests.TryParseImageRejectsNonImage;
var
  AltText: string;
  Url: string;
begin
  Assert.IsFalse(TMarkDownBlockParser.TryParseImage('![alt]', AltText, Url));
  Assert.IsFalse(TMarkDownBlockParser.TryParseImage('plain text', AltText, Url));
end;

procedure TMarkDownParserTests.TryParseLinkReferenceParsesNameAndUrl;
var
  Name: string;
  Url: string;
begin
  Assert.IsTrue(TMarkDownBlockParser.TryParseLinkReference(
    '[ref]: https://example.com', Name, Url));
  Assert.AreEqual('ref', Name);
  Assert.AreEqual('https://example.com', Url);
  Assert.IsFalse(TMarkDownBlockParser.TryParseLinkReference('not a ref', Name, Url));
end;

procedure TMarkDownParserTests.TryParseLinkReferenceDropsTitle;
var
  Name: string;
  Url: string;
begin
  Assert.IsTrue(TMarkDownBlockParser.TryParseLinkReference(
    '[ref]: https://example.com "Title"', Name, Url));
  Assert.AreEqual('https://example.com', Url);
end;

procedure TMarkDownParserTests.TryParseListItemHandlesBulletsAndNumbers;
var
  Text: string;
  Ordered: Boolean;
  Number: Integer;
  IndentLevel: Integer;
begin
  Assert.IsTrue(TMarkDownBlockParser.TryParseListItem('* bullet', Text,
    Ordered, Number, IndentLevel));
  Assert.IsFalse(Ordered);
  Assert.AreEqual('bullet', Text);

  Assert.IsTrue(TMarkDownBlockParser.TryParseListItem('+ plus', Text,
    Ordered, Number, IndentLevel));
  Assert.IsFalse(Ordered);
  Assert.AreEqual('plus', Text);

  Assert.IsTrue(TMarkDownBlockParser.TryParseListItem('3. third', Text,
    Ordered, Number, IndentLevel));
  Assert.IsTrue(Ordered);
  Assert.AreEqual(3, Number);
  Assert.AreEqual('third', Text);
end;

procedure TMarkDownParserTests.TryParseListItemRejectsPlainText;
var
  Text: string;
  Ordered: Boolean;
  Number: Integer;
  IndentLevel: Integer;
begin
  Assert.IsFalse(TMarkDownBlockParser.TryParseListItem('plain text', Text,
    Ordered, Number, IndentLevel));
end;

// Verifies the invariant that every character of Block.Text maps to a document
// offset holding the same character - except the synthetic spaces/newlines that
// join wrapped source lines, which map to the CR of the line break they stand
// for. Also checks the map has the expected length and trailing sentinel.
procedure AssertSourceMapValid(Lines: TStringList; Block: TMarkDownBlock);
var
  Doc: string;
  I: Integer;
  Off: Integer;
  SrcCh: Char;
  BlkCh: Char;
begin
  Doc := Lines.Text;
  Assert.AreEqual(Length(Block.Text) + 1, Length(Block.SourceMap),
    'map length for "' + Block.Text + '"');
  for I := 0 to Length(Block.Text) - 1 do
  begin
    Off := Block.SourceMap[I];
    Assert.IsTrue((Off >= 0) and (Off < Length(Doc)),
      Format('offset %d out of range at index %d', [Off, I]));
    SrcCh := Doc[Off + 1];
    BlkCh := Block.Text[I + 1];
    if CharInSet(BlkCh, [' ', #10]) then
      Assert.IsTrue((SrcCh = BlkCh) or (SrcCh = #13),
        Format('join at index %d maps to offset %d (ord %d)',
          [I, Off, Ord(SrcCh)]))
    else
      Assert.AreEqual(BlkCh, SrcCh,
        Format('index %d "%s" maps to offset %d "%s"', [I, BlkCh, Off, SrcCh]));
  end;
end;

procedure TMarkDownParserTests.SourceMapMapsParagraphToSource;
var
  Blocks: TMarkDownBlockList;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  Blocks := nil;
  try
    Lines.Add('Hello world');
    Blocks := TMarkDownBlockParser.ParseBlocks(Lines);
    AssertSourceMapValid(Lines, Blocks[0]);
    Assert.AreEqual(0, Blocks[0].SourceMap[0]);
  finally
    Blocks.Free;
    Lines.Free;
  end;
end;

procedure TMarkDownParserTests.SourceMapHandlesMultiLineParagraphJoin;
var
  Blocks: TMarkDownBlockList;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  Blocks := nil;
  try
    Lines.Add('alpha bravo');
    Lines.Add('charlie');
    Blocks := TMarkDownBlockParser.ParseBlocks(Lines);
    Assert.AreEqual('alpha bravo charlie', Blocks[0].Text);
    AssertSourceMapValid(Lines, Blocks[0]);
    // 'charlie' begins at the start of the second source line.
    Assert.AreEqual(Length('alpha bravo') + 2,
      Blocks[0].SourceMap[Length('alpha bravo ')]);
  finally
    Blocks.Free;
    Lines.Free;
  end;
end;

procedure TMarkDownParserTests.SourceMapHandlesHardBreakParagraph;
var
  Blocks: TMarkDownBlockList;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  Blocks := nil;
  try
    Lines.Add('alpha  ');
    Lines.Add('bravo');
    Blocks := TMarkDownBlockParser.ParseBlocks(Lines);
    Assert.AreEqual('alpha'#10'bravo', Blocks[0].Text);
    AssertSourceMapValid(Lines, Blocks[0]);
  finally
    Blocks.Free;
    Lines.Free;
  end;
end;

procedure TMarkDownParserTests.SourceMapHandlesAtxHeadingOffset;
var
  Blocks: TMarkDownBlockList;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  Blocks := nil;
  try
    Lines.Add('## Heading');
    Blocks := TMarkDownBlockParser.ParseBlocks(Lines);
    Assert.AreEqual('Heading', Blocks[0].Text);
    AssertSourceMapValid(Lines, Blocks[0]);
    Assert.AreEqual(3, Blocks[0].SourceMap[0]);
  finally
    Blocks.Free;
    Lines.Free;
  end;
end;

procedure TMarkDownParserTests.SourceMapHandlesMarkupAndEntities;
var
  Blocks: TMarkDownBlockList;
  Lines: TStringList;
  I: Integer;
begin
  Lines := TStringList.Create;
  Blocks := nil;
  try
    // A single-line paragraph is identical to its source, so each character
    // must map to its own offset - including markup and entity characters.
    Lines.Add('Text **bold** and &copy; end');
    Blocks := TMarkDownBlockParser.ParseBlocks(Lines);
    AssertSourceMapValid(Lines, Blocks[0]);
    for I := 0 to Length(Blocks[0].Text) - 1 do
      Assert.AreEqual(I, Blocks[0].SourceMap[I]);
  finally
    Blocks.Free;
    Lines.Free;
  end;
end;

procedure TMarkDownParserTests.SourceMapHandlesQuoteAcrossLines;
var
  Blocks: TMarkDownBlockList;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  Blocks := nil;
  try
    Lines.Add('> alpha');
    Lines.Add('> bravo');
    Blocks := TMarkDownBlockParser.ParseBlocks(Lines);
    Assert.AreEqual('alpha bravo', Blocks[0].Text);
    AssertSourceMapValid(Lines, Blocks[0]);
    Assert.AreEqual(2, Blocks[0].SourceMap[0]);
  finally
    Blocks.Free;
    Lines.Free;
  end;
end;

procedure TMarkDownParserTests.SourceMapHandlesIndentedHeading;
var
  Blocks: TMarkDownBlockList;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  Blocks := nil;
  try
    Lines.Add('   ### Deep');
    Blocks := TMarkDownBlockParser.ParseBlocks(Lines);
    Assert.AreEqual('Deep', Blocks[0].Text);
    AssertSourceMapValid(Lines, Blocks[0]);
    Assert.AreEqual(7, Blocks[0].SourceMap[0]);
  finally
    Blocks.Free;
    Lines.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TMarkDownParserTests);

end.
