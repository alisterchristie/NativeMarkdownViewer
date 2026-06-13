unit Test.MarkdownViewer.Html;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TMarkdownHtmlTests = class
  public
    [Test]
    procedure HeadingEmitsHTag;
    [Test]
    procedure ParagraphWrapsInP;
    [Test]
    procedure InlineStylesEmitTags;
    [Test]
    procedure LinkEmitsAnchor;
    [Test]
    procedure InlineCodeEmitsCode;
    [Test]
    procedure EscapesHtmlSpecials;
    [Test]
    procedure BlockquoteEmitsTag;
    [Test]
    procedure BulletListEmitsUl;
    [Test]
    procedure OrderedListEmitsOl;
    [Test]
    procedure NestedListNestsUl;
    [Test]
    procedure TaskListEmitsCheckbox;
    [Test]
    procedure CodeBlockEmitsPre;
    [Test]
    procedure RuleEmitsHr;
    [Test]
    procedure ImageEmitsImg;
    [Test]
    procedure TableEmitsTableWithAlignment;
    [Test]
    procedure DocumentWrapsFragment;
  end;

implementation

uses
  System.SysUtils,
  MarkdownViewer.Html;

procedure TMarkdownHtmlTests.HeadingEmitsHTag;
begin
  Assert.IsTrue(MarkdownToHtml('## Hello').Contains('<h2>Hello</h2>'),
    MarkdownToHtml('## Hello'));
end;

procedure TMarkdownHtmlTests.ParagraphWrapsInP;
begin
  Assert.IsTrue(MarkdownToHtml('Just text').Contains('<p>Just text</p>'));
end;

procedure TMarkdownHtmlTests.InlineStylesEmitTags;
var
  Html: string;
begin
  Html := MarkdownToHtml('a **b** and *c* and ~~d~~');
  Assert.IsTrue(Html.Contains('<strong>b</strong>'), Html);
  Assert.IsTrue(Html.Contains('<em>c</em>'), Html);
  Assert.IsTrue(Html.Contains('<del>d</del>'), Html);
end;

procedure TMarkdownHtmlTests.LinkEmitsAnchor;
begin
  Assert.IsTrue(MarkdownToHtml('[text](https://x.io)').Contains(
    '<a href="https://x.io">text</a>'), MarkdownToHtml('[text](https://x.io)'));
end;

procedure TMarkdownHtmlTests.InlineCodeEmitsCode;
begin
  Assert.IsTrue(MarkdownToHtml('run `code` now').Contains('<code>code</code>'));
end;

procedure TMarkdownHtmlTests.EscapesHtmlSpecials;
var
  Html: string;
begin
  Html := MarkdownToHtml('1 < 2 & 3 > 0');
  Assert.IsTrue(Html.Contains('&lt;'), Html);
  Assert.IsTrue(Html.Contains('&amp;'), Html);
  Assert.IsTrue(Html.Contains('&gt;'), Html);
  Assert.IsFalse(Html.Contains(' < '), Html);
end;

procedure TMarkdownHtmlTests.BlockquoteEmitsTag;
begin
  Assert.IsTrue(MarkdownToHtml('> quoted').Contains(
    '<blockquote>quoted</blockquote>'));
end;

procedure TMarkdownHtmlTests.BulletListEmitsUl;
var
  Html: string;
begin
  Html := MarkdownToHtml('- one'#13#10'- two');
  Assert.IsTrue(Html.Contains('<ul>'), Html);
  Assert.IsTrue(Html.Contains('<li>one'), Html);
  Assert.IsTrue(Html.Contains('<li>two'), Html);
  Assert.IsTrue(Html.Contains('</ul>'), Html);
end;

procedure TMarkdownHtmlTests.OrderedListEmitsOl;
var
  Html: string;
begin
  Html := MarkdownToHtml('1. one'#13#10'2. two');
  Assert.IsTrue(Html.Contains('<ol>'), Html);
  Assert.IsTrue(Html.Contains('</ol>'), Html);
end;

procedure TMarkdownHtmlTests.NestedListNestsUl;
var
  Html: string;
  FirstUl, SecondUl: Integer;
begin
  Html := MarkdownToHtml('- top'#13#10'  - nested');
  // Two <ul> opens with no </ul> between them indicates nesting.
  FirstUl := Html.IndexOf('<ul>');
  SecondUl := Html.IndexOf('<ul>', FirstUl + 1);
  Assert.IsTrue(SecondUl > FirstUl, Html);
  Assert.IsTrue(Html.IndexOf('</ul>') > SecondUl, Html);
end;

procedure TMarkdownHtmlTests.TaskListEmitsCheckbox;
var
  Html: string;
begin
  Html := MarkdownToHtml('- [x] done'#13#10'- [ ] todo');
  Assert.IsTrue(Html.Contains('type="checkbox" checked'), Html);
  Assert.IsTrue(Html.Contains('type="checkbox" disabled'), Html);
end;

procedure TMarkdownHtmlTests.CodeBlockEmitsPre;
var
  Html: string;
begin
  Html := MarkdownToHtml('```'#13#10'a < b'#13#10'```');
  Assert.IsTrue(Html.Contains('<pre><code>'), Html);
  Assert.IsTrue(Html.Contains('a &lt; b'), Html); // escaped, not parsed
end;

procedure TMarkdownHtmlTests.RuleEmitsHr;
begin
  Assert.IsTrue(MarkdownToHtml('---').Contains('<hr />'));
end;

procedure TMarkdownHtmlTests.ImageEmitsImg;
begin
  Assert.IsTrue(MarkdownToHtml('![alt](pic.png)').Contains(
    '<img src="pic.png" alt="alt" />'), MarkdownToHtml('![alt](pic.png)'));
end;

procedure TMarkdownHtmlTests.TableEmitsTableWithAlignment;
var
  Html: string;
begin
  Html := MarkdownToHtml('| a | b |'#13#10'| :--- | ---: |'#13#10'| 1 | 2 |');
  Assert.IsTrue(Html.Contains('<table>'), Html);
  Assert.IsTrue(Html.Contains('<th'), Html);
  Assert.IsTrue(Html.Contains('text-align:right'), Html);
  Assert.IsTrue(Html.Contains('<td'), Html);
end;

procedure TMarkdownHtmlTests.DocumentWrapsFragment;
var
  Html: string;
begin
  Html := MarkdownToHtmlDocument('# Hi', 'My Title');
  Assert.IsTrue(Html.StartsWith('<!DOCTYPE html>'), Html);
  Assert.IsTrue(Html.Contains('<title>My Title</title>'), Html);
  Assert.IsTrue(Html.Contains('<h1>Hi</h1>'), Html);
  Assert.IsTrue(Html.Contains('</html>'), Html);
end;

initialization
  TDUnitX.RegisterTestFixture(TMarkdownHtmlTests);

end.
