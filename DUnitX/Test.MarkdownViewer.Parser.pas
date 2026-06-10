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
    procedure ParseInlineParsesEmphasisCodeAndStrike;
    [Test]
    procedure ParseInlineParsesBoldItalic;
    [Test]
    procedure ParseInlineIgnoresUnderscoreInsideWords;
    [Test]
    procedure ParseInlineIgnoresSpacedAsterisks;
    [Test]
    procedure ParseInlineRespectsEscapes;
    [Test]
    procedure ParseInlineParsesInlineLink;
    [Test]
    procedure ParseInlineResolvesReferenceLink;
    [Test]
    procedure ParseInlineDetectsAutoLink;
    [Test]
    procedure ExtractLinkReferencesCollectsUrls;
  end;

implementation

uses
  System.Classes,
  System.SysUtils,
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

procedure TMarkDownParserTests.ParseInlineParsesBoldItalic;
var
  Tokens: TMarkDownInlineList;
begin
  Tokens := TMarkDownBlockParser.ParseInline('***both***');
  try
    Assert.AreEqual(1, Tokens.Count);
    Assert.IsTrue(Tokens[0].Kind = ikBoldItalic);
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
    Assert.IsTrue(Tokens[0].Kind = ikText);
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
    Assert.IsTrue(Tokens[0].Kind = ikText);
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
    Assert.IsTrue(Tokens[0].Kind = ikText);
    Assert.AreEqual('a ', Tokens[0].Text);
    Assert.IsTrue(Tokens[1].Kind = ikBold);
    Assert.AreEqual('b', Tokens[1].Text);
    Assert.IsTrue(Tokens[3].Kind = ikItalic);
    Assert.AreEqual('c', Tokens[3].Text);
    Assert.IsTrue(Tokens[5].Kind = ikCode);
    Assert.AreEqual('d', Tokens[5].Text);
    Assert.IsTrue(Tokens[7].Kind = ikStrike);
    Assert.AreEqual('e', Tokens[7].Text);
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
    Assert.IsTrue(Tokens[0].Kind = ikText);
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
    Assert.IsTrue(Tokens[0].Kind = ikLink);
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
    Assert.IsTrue(Tokens[0].Kind = ikLink);
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
    Assert.IsTrue(Tokens[1].Kind = ikLink);
    Assert.AreEqual('https://example.com', Tokens[1].Url);
    Assert.IsTrue(Tokens[2].Kind = ikText);
    Assert.AreEqual(' today.', Tokens[2].Text);
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

initialization
  TDUnitX.RegisterTestFixture(TMarkDownParserTests);

end.
