unit Test.MarkdownViewer.Highlight;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TMarkdownHighlightTests = class
  public
    [Test]
    procedure TestDelphiKeywords;
    [Test]
    procedure TestDelphiComments;
    [Test]
    procedure TestDelphiStrings;
    [Test]
    procedure TestDelphiMultilineStrings;
    [Test]
    procedure TestDelphiGenerics;
    [Test]
    procedure TestDelphiNumbers;
    [Test]
    procedure TestDelphiAnonymousMethods;
    [Test]
    procedure TestSQLKeywords;
    [Test]
    procedure TestSQLComments;
    [Test]
    procedure TestSQLStrings;
    [Test]
    procedure TestSQLNumbers;
    [Test]
    procedure TestRegistry;

    // C-family generic highlighter tests
    [Test]
    procedure TestCKeywords;
    [Test]
    procedure TestCComments;
    [Test]
    procedure TestCStrings;
    [Test]
    procedure TestCNumbers;
    [Test]
    procedure TestCPreprocessor;
    [Test]
    procedure TestCPPKeywords;
    [Test]
    procedure TestCSharpKeywords;
    [Test]
    procedure TestJavaKeywords;
    [Test]
    procedure TestJSKeywords;
    [Test]
    procedure TestJSTemplateLiterals;
    [Test]
    procedure TestTSKeywords;
    [Test]
    procedure TestGoKeywords;
    [Test]
    procedure TestRustKeywords;
    [Test]
    procedure TestPHPKeywords;

    // Python
    [Test]
    procedure TestPythonKeywords;
    [Test]
    procedure TestPythonComments;
    [Test]
    procedure TestPythonStrings;
    [Test]
    procedure TestPythonTripleQuotedStrings;
    [Test]
    procedure TestPythonNumbers;

    // Ruby
    [Test]
    procedure TestRubyKeywords;
    [Test]
    procedure TestRubyComments;
    [Test]
    procedure TestRubySymbols;

    // HTML / XML
    [Test]
    procedure TestHTMLTags;
    [Test]
    procedure TestHTMLComments;

    // CSS
    [Test]
    procedure TestCSSProperties;
    [Test]
    procedure TestCSSComments;

    // JSON
    [Test]
    procedure TestJSONStrings;
    [Test]
    procedure TestJSONNumbers;
    [Test]
    procedure TestJSONLiterals;

    // YAML
    [Test]
    procedure TestYAMLComments;
    [Test]
    procedure TestYAMLLiterals;

    // Shell
    [Test]
    procedure TestShellKeywords;
    [Test]
    procedure TestShellVariables;

    // INI
    [Test]
    procedure TestINISections;
    [Test]
    procedure TestINIComments;
    [Test]
    procedure TestINIKeyValue;

    // Registry coverage
    [Test]
    procedure TestRegistryAllLanguages;

    // Delphi form files (.dfm) and source-file aliases
    [Test]
    procedure TestDfmKeywords;
    [Test]
    procedure TestDfmPropertyValues;
    [Test]
    procedure TestDfmCharConstants;
    [Test]
    procedure TestDelphiSourceFileAliases;

    // Whole-stream invariants (the regression guard against the zero-length /
    // infinite-loop class of lexer bug).
    [Test]
    procedure TestTokenStreamInvariantsAllLanguages;
    [Test]
    procedure TestTokenStreamInvariantsAdversarialInput;

    [Test]
    procedure TestLaTeXHighlighter;
    [Test]
    procedure TestPowerShellHighlighter;
    [Test]
    procedure TestBatchHighlighter;
    [Test]
    procedure TestVBHighlighter;

    // Cached per-block tokenization
    [Test]
    procedure TestBlockHighlightTokensMatchRegistry;
    [Test]
    procedure TestBlockHighlightTokensFallBackToNil;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  MarkdownViewer.Model,
  MarkdownViewer.Highlight;

// Assert that a highlighter's output tiles the input exactly: tokens are
// contiguous from offset 0, none are zero-length, and concatenating their
// text reproduces the input verbatim. Any violation indicates a lexer that
// dropped, overlapped, or (worst case) failed to advance over input.
procedure AssertTokenStreamValid(const HL: IMarkdownSyntaxHighlighter;
  const AInput: string);
var
  Tokens: TArray<TSourceToken>;
  I, Expected: Integer;
  Rebuilt: string;
begin
  Tokens := HL.Highlight(AInput);
  Expected := 0;
  Rebuilt := '';
  for I := 0 to High(Tokens) do
  begin
    Assert.IsTrue(Length(Tokens[I].Text) > 0,
      Format('%s: zero-length token at index %d for input %s',
        [HL.GetLanguageName, I, QuotedStr(AInput)]));
    Assert.AreEqual(Expected, Tokens[I].Offset,
      Format('%s: non-contiguous offset at index %d for input %s',
        [HL.GetLanguageName, I, QuotedStr(AInput)]));
    Inc(Expected, Length(Tokens[I].Text));
    Rebuilt := Rebuilt + Tokens[I].Text;
  end;
  Assert.AreEqual(Length(AInput), Expected,
    Format('%s: tokens do not span the whole input %s',
      [HL.GetLanguageName, QuotedStr(AInput)]));
  Assert.AreEqual(AInput, Rebuilt,
    Format('%s: concatenated tokens differ from input %s',
      [HL.GetLanguageName, QuotedStr(AInput)]));
end;

{ TMarkdownHighlightTests }

procedure TMarkdownHighlightTests.TestDelphiKeywords;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('delphi');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('begin constructor class end;');
  // Expected: keywords for begin, constructor, class, end, plain for spaces, symbol for ';'
  Assert.IsTrue(Length(Tokens) >= 7);
  Assert.AreEqual(stKeyword, Tokens[0].Kind);
  Assert.AreEqual('begin', Tokens[0].Text);
  Assert.AreEqual(stKeyword, Tokens[2].Kind);
  Assert.AreEqual('constructor', Tokens[2].Text);
  Assert.AreEqual(stKeyword, Tokens[4].Kind);
  Assert.AreEqual('class', Tokens[4].Text);
  Assert.AreEqual(stKeyword, Tokens[6].Kind);
  Assert.AreEqual('end', Tokens[6].Text);
  Assert.AreEqual(stSymbol, Tokens[7].Kind);
  Assert.AreEqual(';', Tokens[7].Text);
end;

procedure TMarkdownHighlightTests.TestDelphiComments;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('pascal');
  Assert.IsTrue(HL <> nil);

  // Line comment
  Tokens := HL.Highlight('// this is a comment'#13#10'begin');
  Assert.IsTrue(Length(Tokens) >= 3);
  Assert.AreEqual(stComment, Tokens[0].Kind);
  Assert.AreEqual('// this is a comment', Tokens[0].Text);
  Assert.AreEqual(stPlain, Tokens[1].Kind);
  Assert.AreEqual(stKeyword, Tokens[2].Kind);

  // Curly comment
  Tokens := HL.Highlight('{ curly }');
  Assert.AreEqual(1, Length(Tokens));
  Assert.AreEqual(stComment, Tokens[0].Kind);
  Assert.AreEqual('{ curly }', Tokens[0].Text);

  // Compiler directive curly
  Tokens := HL.Highlight('{$IFDEF DEBUG}');
  Assert.AreEqual(1, Length(Tokens));
  Assert.AreEqual(stPreprocessor, Tokens[0].Kind);
  Assert.AreEqual('{$IFDEF DEBUG}', Tokens[0].Text);

  // Paren-star comment
  Tokens := HL.Highlight('(* star comment *)');
  Assert.AreEqual(1, Length(Tokens));
  Assert.AreEqual(stComment, Tokens[0].Kind);
  Assert.AreEqual('(* star comment *)', Tokens[0].Text);
end;

procedure TMarkdownHighlightTests.TestDelphiStrings;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('delphi');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('''hello ''''world''''''');
  Assert.AreEqual(1, Length(Tokens));
  Assert.AreEqual(stString, Tokens[0].Kind);
  Assert.AreEqual('''hello ''''world''''''', Tokens[0].Text);
end;

procedure TMarkdownHighlightTests.TestDelphiMultilineStrings;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('delphi');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('''''''line1'#13#10'line2''''''');
  Assert.AreEqual(1, Length(Tokens));
  Assert.AreEqual(stString, Tokens[0].Kind);
  Assert.AreEqual('''''''line1'#13#10'line2''''''', Tokens[0].Text);
end;

procedure TMarkdownHighlightTests.TestDelphiGenerics;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('delphi');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('TList<T>');
  Assert.IsTrue(Length(Tokens) >= 4);
  Assert.AreEqual('TList', Tokens[0].Text);
  Assert.AreEqual(stSymbol, Tokens[1].Kind);
  Assert.AreEqual('<', Tokens[1].Text);
  Assert.AreEqual('T', Tokens[2].Text);
  Assert.AreEqual(stSymbol, Tokens[3].Kind);
  Assert.AreEqual('>', Tokens[3].Text);
end;

procedure TMarkdownHighlightTests.TestDelphiNumbers;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('delphi');
  Assert.IsTrue(HL <> nil);

  // Hex
  Tokens := HL.Highlight('$FF00');
  Assert.AreEqual(1, Length(Tokens));
  Assert.AreEqual(stNumber, Tokens[0].Kind);
  Assert.AreEqual('$FF00', Tokens[0].Text);

  // Dec & Float
  Tokens := HL.Highlight('123 4.56');
  Assert.IsTrue(Length(Tokens) >= 3);
  Assert.AreEqual(stNumber, Tokens[0].Kind);
  Assert.AreEqual('123', Tokens[0].Text);
  Assert.AreEqual(stNumber, Tokens[2].Kind);
  Assert.AreEqual('4.56', Tokens[2].Text);
end;

procedure TMarkdownHighlightTests.TestDelphiAnonymousMethods;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('delphi');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('reference to procedure');
  Assert.IsTrue(Length(Tokens) >= 5);
  Assert.AreEqual(stKeyword, Tokens[0].Kind);
  Assert.AreEqual('reference', Tokens[0].Text);
  Assert.AreEqual(stKeyword, Tokens[2].Kind);
  Assert.AreEqual('to', Tokens[2].Text);
  Assert.AreEqual(stKeyword, Tokens[4].Kind);
  Assert.AreEqual('procedure', Tokens[4].Text);
end;

procedure TMarkdownHighlightTests.TestSQLKeywords;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('sql');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('select * from users where id = 1');
  Assert.IsTrue(Length(Tokens) >= 11);
  Assert.AreEqual(stKeyword, Tokens[0].Kind);
  Assert.AreEqual('select', Tokens[0].Text);
  Assert.AreEqual(stSymbol, Tokens[2].Kind);
  Assert.AreEqual('*', Tokens[2].Text);
  Assert.AreEqual(stKeyword, Tokens[4].Kind);
  Assert.AreEqual('from', Tokens[4].Text);
  Assert.AreEqual(stKeyword, Tokens[8].Kind);
  Assert.AreEqual('where', Tokens[8].Text);
end;

procedure TMarkdownHighlightTests.TestSQLComments;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('sql');
  Assert.IsTrue(HL <> nil);

  // SQL line comment
  Tokens := HL.Highlight('-- SQL comment'#13#10'select');
  Assert.IsTrue(Length(Tokens) >= 3);
  Assert.AreEqual(stComment, Tokens[0].Kind);
  Assert.AreEqual('-- SQL comment', Tokens[0].Text);

  // SQL block comment
  Tokens := HL.Highlight('/* comment */');
  Assert.AreEqual(1, Length(Tokens));
  Assert.AreEqual(stComment, Tokens[0].Kind);
  Assert.AreEqual('/* comment */', Tokens[0].Text);
end;

procedure TMarkdownHighlightTests.TestSQLStrings;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('sql');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('''SQL string ''''with'''' quotes''');
  Assert.AreEqual(1, Length(Tokens));
  Assert.AreEqual(stString, Tokens[0].Kind);
  Assert.AreEqual('''SQL string ''''with'''' quotes''', Tokens[0].Text);
end;

procedure TMarkdownHighlightTests.TestSQLNumbers;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('sql');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('123.45');
  Assert.AreEqual(1, Length(Tokens));
  Assert.AreEqual(stNumber, Tokens[0].Kind);
  Assert.AreEqual('123.45', Tokens[0].Text);
end;

procedure TMarkdownHighlightTests.TestRegistry;
var
  HL1, HL2, HL3: IMarkdownSyntaxHighlighter;
begin
  HL1 := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('delphi');
  HL2 := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('pascal');
  HL3 := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('PAS');
  Assert.IsTrue(HL1 <> nil);
  Assert.AreSame(HL1, HL2);
  Assert.AreSame(HL1, HL3);

  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('unknown_lang') = nil);
end;

// ---------------------------------------------------------------------------
// C-family generic highlighter tests
// ---------------------------------------------------------------------------

procedure TMarkdownHighlightTests.TestCKeywords;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('c');
  Assert.IsTrue(HL <> nil);
  Assert.AreEqual('C', HL.GetLanguageName);

  Tokens := HL.Highlight('int main(void) {');
  // Tokens: int(0=stKeyword) ' '(1) main(2=stPlain) ( (3=stSymbol) void(4=stKeyword) )(5=stSymbol) ' '(6) {(7=stSymbol)
  Assert.IsTrue(Length(Tokens) = 8);
  Assert.AreEqual(stKeyword, Tokens[0].Kind);
  Assert.AreEqual('int', Tokens[0].Text);
  Assert.AreEqual(stPlain, Tokens[2].Kind);
  Assert.AreEqual('main', Tokens[2].Text);
  Assert.AreEqual(stKeyword, Tokens[4].Kind);
  Assert.AreEqual('void', Tokens[4].Text);
end;

procedure TMarkdownHighlightTests.TestCComments;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('c');
  Assert.IsTrue(HL <> nil);

  // Line comment
  Tokens := HL.Highlight('// comment'#13#10'int x;');
  Assert.IsTrue(Length(Tokens) >= 3);
  Assert.AreEqual(stComment, Tokens[0].Kind);
  Assert.AreEqual('// comment', Tokens[0].Text);

  // Block comment
  Tokens := HL.Highlight('/* block */x');
  Assert.IsTrue(Length(Tokens) >= 2);
  Assert.AreEqual(stComment, Tokens[0].Kind);
  Assert.AreEqual('/* block */', Tokens[0].Text);
end;

procedure TMarkdownHighlightTests.TestCStrings;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('c');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('"hello\nworld"');
  Assert.AreEqual(1, Length(Tokens));
  Assert.AreEqual(stString, Tokens[0].Kind);
  Assert.AreEqual('"hello\nworld"', Tokens[0].Text);
end;

procedure TMarkdownHighlightTests.TestCNumbers;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('c');
  Assert.IsTrue(HL <> nil);

  // Hex
  Tokens := HL.Highlight('0xFF');
  Assert.AreEqual(1, Length(Tokens));
  Assert.AreEqual(stNumber, Tokens[0].Kind);
  Assert.AreEqual('0xFF', Tokens[0].Text);

  // Float
  Tokens := HL.Highlight('3.14f');
  Assert.AreEqual(1, Length(Tokens));
  Assert.AreEqual(stNumber, Tokens[0].Kind);
end;

procedure TMarkdownHighlightTests.TestCPreprocessor;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('c');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('#include <stdio.h>');
  Assert.AreEqual(1, Length(Tokens));
  Assert.AreEqual(stPreprocessor, Tokens[0].Kind);
  Assert.AreEqual('#include <stdio.h>', Tokens[0].Text);
end;

procedure TMarkdownHighlightTests.TestCPPKeywords;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('cpp');
  Assert.IsTrue(HL <> nil);
  Assert.AreEqual('C++', HL.GetLanguageName);

  Tokens := HL.Highlight('class MyClass : public Base {');
  Assert.IsTrue(Length(Tokens) >= 7);
  Assert.AreEqual(stKeyword, Tokens[0].Kind);
  Assert.AreEqual('class', Tokens[0].Text);
  Assert.AreEqual(stKeyword, Tokens[6].Kind);
  Assert.AreEqual('public', Tokens[6].Text);
end;

procedure TMarkdownHighlightTests.TestCSharpKeywords;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('csharp');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('using System; namespace App {');
  // using(0=stKeyword) ' '(1) System(2=stType) ;(3=stSymbol) ' '(4) namespace(5=stKeyword) ' '(6) App(7=stPlain) ' '(8) {(9=stSymbol)
  Assert.IsTrue(Length(Tokens) >= 7);
  Assert.AreEqual(stKeyword, Tokens[0].Kind);
  Assert.AreEqual('using', Tokens[0].Text);
  Assert.AreEqual(stKeyword, Tokens[5].Kind);
  Assert.AreEqual('namespace', Tokens[5].Text);
end;

procedure TMarkdownHighlightTests.TestJavaKeywords;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('java');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('public class Hello {');
  Assert.IsTrue(Length(Tokens) >= 5);
  Assert.AreEqual(stKeyword, Tokens[0].Kind);
  Assert.AreEqual('public', Tokens[0].Text);
  Assert.AreEqual(stKeyword, Tokens[2].Kind);
  Assert.AreEqual('class', Tokens[2].Text);
end;

procedure TMarkdownHighlightTests.TestJSKeywords;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('javascript');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('const x = "hello";');
  // const(0=stKeyword) ' '(1) x(2=stPlain) ' '(3) =(4=stSymbol) ' '(5) "hello"(6=stString) ;(7=stSymbol)
  Assert.IsTrue(Length(Tokens) >= 7);
  Assert.AreEqual(stKeyword, Tokens[0].Kind);
  Assert.AreEqual('const', Tokens[0].Text);
  Assert.AreEqual(stString, Tokens[6].Kind);
end;

procedure TMarkdownHighlightTests.TestJSTemplateLiterals;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('js');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('`hello ${name}`');
  Assert.AreEqual(1, Length(Tokens));
  Assert.AreEqual(stString, Tokens[0].Kind);
  Assert.AreEqual('`hello ${name}`', Tokens[0].Text);
end;

procedure TMarkdownHighlightTests.TestTSKeywords;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('typescript');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('interface User { name: string; }');
  Assert.IsTrue(Length(Tokens) >= 7);
  Assert.AreEqual(stKeyword, Tokens[0].Kind);
  Assert.AreEqual('interface', Tokens[0].Text);
end;

procedure TMarkdownHighlightTests.TestGoKeywords;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('go');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('func main() {');
  Assert.IsTrue(Length(Tokens) >= 5);
  Assert.AreEqual(stKeyword, Tokens[0].Kind);
  Assert.AreEqual('func', Tokens[0].Text);
end;

procedure TMarkdownHighlightTests.TestRustKeywords;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('rust');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('fn main() {');
  Assert.IsTrue(Length(Tokens) >= 5);
  Assert.AreEqual(stKeyword, Tokens[0].Kind);
  Assert.AreEqual('fn', Tokens[0].Text);
end;

procedure TMarkdownHighlightTests.TestPHPKeywords;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('php');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('<?php echo "hello";');
  // <(0=stSymbol) ?(1=stSymbol) php(2=stPlain) ' '(3) echo(4=stKeyword) ' '(5) "hello"(6=stString) ;(7=stSymbol)
  Assert.IsTrue(Length(Tokens) >= 7);
  Assert.AreEqual(stKeyword, Tokens[4].Kind);
  Assert.AreEqual('echo', Tokens[4].Text);
end;

// ---------------------------------------------------------------------------
// Python
// ---------------------------------------------------------------------------

procedure TMarkdownHighlightTests.TestPythonKeywords;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('python');
  Assert.IsTrue(HL <> nil);
  Assert.AreEqual('Python', HL.GetLanguageName);

  Tokens := HL.Highlight('def hello():'#13#10'    return "world"');
  // def(0=stKeyword) ' '(1) hello(2=stPlain) ((3=stSymbol) )(4=stSymbol) :(5=stSymbol)
  // CRLF+spaces(6=stPlain) return(7=stKeyword) ' '(8) "world"(9=stString)
  Assert.IsTrue(Length(Tokens) >= 8);
  Assert.AreEqual(stKeyword, Tokens[0].Kind);
  Assert.AreEqual('def', Tokens[0].Text);
  Assert.AreEqual(stKeyword, Tokens[7].Kind);
  Assert.AreEqual('return', Tokens[7].Text);
end;

procedure TMarkdownHighlightTests.TestPythonComments;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('py');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('# this is a comment'#13#10'x = 1');
  Assert.IsTrue(Length(Tokens) >= 3);
  Assert.AreEqual(stComment, Tokens[0].Kind);
  Assert.AreEqual('# this is a comment', Tokens[0].Text);
end;

procedure TMarkdownHighlightTests.TestPythonStrings;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('python');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('"double" ''single''');
  Assert.IsTrue(Length(Tokens) >= 3);
  Assert.AreEqual(stString, Tokens[0].Kind);
  Assert.AreEqual('"double"', Tokens[0].Text);
  Assert.AreEqual(stString, Tokens[2].Kind);
  Assert.AreEqual('''single''', Tokens[2].Text);
end;

procedure TMarkdownHighlightTests.TestPythonTripleQuotedStrings;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('python');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('"""doc string"""');
  Assert.AreEqual(1, Length(Tokens));
  Assert.AreEqual(stString, Tokens[0].Kind);
  Assert.AreEqual('"""doc string"""', Tokens[0].Text);

  Tokens := HL.Highlight('''''''doc string''''''');
  Assert.AreEqual(1, Length(Tokens));
  Assert.AreEqual(stString, Tokens[0].Kind);
end;

procedure TMarkdownHighlightTests.TestPythonNumbers;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('python');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('0xFF 0o77 0b1010 42 3.14 1e10');
  Assert.IsTrue(Length(Tokens) >= 11);
  Assert.AreEqual(stNumber, Tokens[0].Kind);
  Assert.AreEqual('0xFF', Tokens[0].Text);
  Assert.AreEqual(stNumber, Tokens[2].Kind);
  Assert.AreEqual('0o77', Tokens[2].Text);
  Assert.AreEqual(stNumber, Tokens[4].Kind);
  Assert.AreEqual('0b1010', Tokens[4].Text);
end;

// ---------------------------------------------------------------------------
// Ruby
// ---------------------------------------------------------------------------

procedure TMarkdownHighlightTests.TestRubyKeywords;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('ruby');
  Assert.IsTrue(HL <> nil);
  Assert.AreEqual('Ruby', HL.GetLanguageName);

  Tokens := HL.Highlight('def hello'#13#10'  "world"'#13#10'end');
  // def(0=stKeyword) ' '(1) hello(2=stPlain) CRLF+spaces(3=stPlain)
  // "world"(4=stString) CRLF(5=stPlain) end(6=stKeyword)
  Assert.IsTrue(Length(Tokens) >= 6);
  Assert.AreEqual(stKeyword, Tokens[0].Kind);
  Assert.AreEqual('def', Tokens[0].Text);
  Assert.AreEqual(stKeyword, Tokens[6].Kind);
  Assert.AreEqual('end', Tokens[6].Text);
end;

procedure TMarkdownHighlightTests.TestRubyComments;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('rb');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('# comment'#13#10'x = 1');
  Assert.IsTrue(Length(Tokens) >= 3);
  Assert.AreEqual(stComment, Tokens[0].Kind);
  Assert.AreEqual('# comment', Tokens[0].Text);

  // =begin ... =end block comment
  Tokens := HL.Highlight('=begin'#13#10'multiline'#13#10'=end x');
  Assert.IsTrue(Length(Tokens) >= 2);
  Assert.AreEqual(stComment, Tokens[0].Kind);
end;

procedure TMarkdownHighlightTests.TestRubySymbols;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('ruby');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight(':symbol');
  Assert.AreEqual(1, Length(Tokens));
  Assert.AreEqual(stSymbol, Tokens[0].Kind);
  Assert.AreEqual(':symbol', Tokens[0].Text);
end;

// ---------------------------------------------------------------------------
// HTML / XML
// ---------------------------------------------------------------------------

procedure TMarkdownHighlightTests.TestHTMLTags;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('html');
  Assert.IsTrue(HL <> nil);
  Assert.AreEqual('HTML', HL.GetLanguageName);

  Tokens := HL.Highlight('<div class="main"><p>Hello</p></div>');
  Assert.IsTrue(Length(Tokens) >= 4);
  Assert.AreEqual(stKeyword, Tokens[0].Kind);
  // Content tokens vary depending on tag handler behavior; verify tags are keyword
end;

procedure TMarkdownHighlightTests.TestHTMLComments;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('html');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('<!-- comment --><p>text</p>');
  Assert.IsTrue(Length(Tokens) >= 4);
  Assert.AreEqual(stComment, Tokens[0].Kind);
  Assert.AreEqual('<!-- comment -->', Tokens[0].Text);
end;

// ---------------------------------------------------------------------------
// CSS
// ---------------------------------------------------------------------------

procedure TMarkdownHighlightTests.TestCSSProperties;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('css');
  Assert.IsTrue(HL <> nil);
  Assert.AreEqual('CSS', HL.GetLanguageName);

  Tokens := HL.Highlight('.main { color: red; }');
  // .main(0=stPlain) ' '(1) {(2=stSymbol) ' '(3) color(4=stKeyword) :(5=stPlain) ' '(6) red(7=stPlain) ;(8=stSymbol) ' '(9) }(10=stSymbol)
  Assert.IsTrue(Length(Tokens) >= 7);
  Assert.AreEqual(stKeyword, Tokens[4].Kind);
  Assert.AreEqual('color', Tokens[4].Text);
end;

procedure TMarkdownHighlightTests.TestCSSComments;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('css');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('/* comment */ .class { }');
  Assert.IsTrue(Length(Tokens) >= 4);
  Assert.AreEqual(stComment, Tokens[0].Kind);
  Assert.AreEqual('/* comment */', Tokens[0].Text);
end;

// ---------------------------------------------------------------------------
// JSON
// ---------------------------------------------------------------------------

procedure TMarkdownHighlightTests.TestJSONStrings;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('json');
  Assert.IsTrue(HL <> nil);
  Assert.AreEqual('JSON', HL.GetLanguageName);

  Tokens := HL.Highlight('{ "key": "value" }');
  // {(0=stSymbol) ' '(1) "key"(2=stString) :(3=stSymbol) ' '(4) "value"(5=stString) ' '(6) }(7=stSymbol)
  Assert.IsTrue(Length(Tokens) >= 6);
  Assert.AreEqual(stString, Tokens[2].Kind);
  Assert.AreEqual('"key"', Tokens[2].Text);
  Assert.AreEqual(stString, Tokens[5].Kind);
  Assert.AreEqual('"value"', Tokens[5].Text);
end;

procedure TMarkdownHighlightTests.TestJSONNumbers;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('json');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('42');
  Assert.AreEqual(1, Length(Tokens));
  Assert.AreEqual(stNumber, Tokens[0].Kind);
  Assert.AreEqual('42', Tokens[0].Text);

  Tokens := HL.Highlight('3.14');
  Assert.AreEqual(1, Length(Tokens));
  Assert.AreEqual(stNumber, Tokens[0].Kind);

  Tokens := HL.Highlight('-1.5e10');
  Assert.AreEqual(1, Length(Tokens));
  Assert.AreEqual(stNumber, Tokens[0].Kind);
end;

procedure TMarkdownHighlightTests.TestJSONLiterals;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('json');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('true false null');
  Assert.IsTrue(Length(Tokens) >= 5);
  Assert.AreEqual(stKeyword, Tokens[0].Kind);
  Assert.AreEqual('true', Tokens[0].Text);
  Assert.AreEqual(stKeyword, Tokens[2].Kind);
  Assert.AreEqual('false', Tokens[2].Text);
  Assert.AreEqual(stKeyword, Tokens[4].Kind);
  Assert.AreEqual('null', Tokens[4].Text);
end;

// ---------------------------------------------------------------------------
// YAML
// ---------------------------------------------------------------------------

procedure TMarkdownHighlightTests.TestYAMLComments;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('yaml');
  Assert.IsTrue(HL <> nil);
  Assert.AreEqual('YAML', HL.GetLanguageName);

  Tokens := HL.Highlight('# comment'#13#10'key: value');
  Assert.IsTrue(Length(Tokens) >= 3);
  Assert.AreEqual(stComment, Tokens[0].Kind);
  Assert.AreEqual('# comment', Tokens[0].Text);
end;

procedure TMarkdownHighlightTests.TestYAMLLiterals;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('yml');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('true false yes no null');
  Assert.IsTrue(Length(Tokens) >= 9);
  Assert.AreEqual(stKeyword, Tokens[0].Kind);
  Assert.AreEqual('true', Tokens[0].Text);
  Assert.AreEqual(stKeyword, Tokens[2].Kind);
  Assert.AreEqual('false', Tokens[2].Text);
end;

// ---------------------------------------------------------------------------
// Shell
// ---------------------------------------------------------------------------

procedure TMarkdownHighlightTests.TestShellKeywords;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('bash');
  Assert.IsTrue(HL <> nil);
  Assert.AreEqual('Shell', HL.GetLanguageName);

  Tokens := HL.Highlight('if [ -f file ]; then');
  // if(0=stKeyword) ' '(1) [(2=stSymbol) ' '(3) -(4=stSymbol) f(5=stPlain) ' '(6) file(7=stPlain) ' '(8) ](9=stSymbol) ;(10=stSymbol) ' '(11) then(12=stKeyword)
  Assert.IsTrue(Length(Tokens) >= 11);
  Assert.AreEqual(stKeyword, Tokens[0].Kind);
  Assert.AreEqual('if', Tokens[0].Text);
  Assert.AreEqual(stKeyword, Tokens[12].Kind);
  Assert.AreEqual('then', Tokens[12].Text);
end;

procedure TMarkdownHighlightTests.TestShellVariables;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('sh');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('echo $HOME ${PATH}');
  Assert.IsTrue(Length(Tokens) >= 5);
  Assert.AreEqual(stKeyword, Tokens[0].Kind);
  Assert.AreEqual('echo', Tokens[0].Text);
  Assert.AreEqual(stType, Tokens[2].Kind);
  Assert.AreEqual('$HOME', Tokens[2].Text);
  Assert.AreEqual(stType, Tokens[4].Kind);
  Assert.AreEqual('${PATH}', Tokens[4].Text);
end;

// ---------------------------------------------------------------------------
// INI / Config
// ---------------------------------------------------------------------------

procedure TMarkdownHighlightTests.TestINISections;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('ini');
  Assert.IsTrue(HL <> nil);
  Assert.AreEqual('INI', HL.GetLanguageName);

  Tokens := HL.Highlight('[section]');
  Assert.AreEqual(1, Length(Tokens));
  Assert.AreEqual(stKeyword, Tokens[0].Kind);
  Assert.AreEqual('[section]', Tokens[0].Text);
end;

procedure TMarkdownHighlightTests.TestINIComments;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('ini');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('; comment'#13#10'[section]');
  Assert.IsTrue(Length(Tokens) >= 3);
  Assert.AreEqual(stComment, Tokens[0].Kind);
  Assert.AreEqual('; comment', Tokens[0].Text);

  Tokens := HL.Highlight('# comment'#13#10'key=val');
  Assert.IsTrue(Length(Tokens) >= 3);
  Assert.AreEqual(stComment, Tokens[0].Kind);
end;

procedure TMarkdownHighlightTests.TestINIKeyValue;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('ini');
  Assert.IsTrue(HL <> nil);

  Tokens := HL.Highlight('key=value');
  Assert.IsTrue(Length(Tokens) >= 3);
  Assert.AreEqual(stType, Tokens[0].Kind);
  Assert.AreEqual('key', Tokens[0].Text);
  Assert.AreEqual(stSymbol, Tokens[1].Kind);
  Assert.AreEqual('=', Tokens[1].Text);
end;

// ---------------------------------------------------------------------------
// Registry coverage
// ---------------------------------------------------------------------------

procedure TMarkdownHighlightTests.TestRegistryAllLanguages;
begin
  // Delphi / Pascal
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('delphi') <> nil);
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('pascal') <> nil);
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('pas') <> nil);

  // SQL
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('sql') <> nil);

  // C-family
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('c') <> nil);
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('cpp') <> nil);
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('c++') <> nil);
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('csharp') <> nil);
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('cs') <> nil);
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('java') <> nil);
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('js') <> nil);
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('javascript') <> nil);
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('ts') <> nil);
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('typescript') <> nil);
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('go') <> nil);
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('rust') <> nil);
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('rs') <> nil);
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('php') <> nil);

  // Python
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('py') <> nil);
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('python') <> nil);

  // Ruby
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('rb') <> nil);
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('ruby') <> nil);

  // HTML / XML
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('html') <> nil);
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('xml') <> nil);

  // CSS
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('css') <> nil);

  // JSON
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('json') <> nil);

  // YAML
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('yaml') <> nil);
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('yml') <> nil);

  // Shell
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('sh') <> nil);
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('bash') <> nil);
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('shell') <> nil);

  // INI
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('ini') <> nil);
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('cfg') <> nil);
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('conf') <> nil);

  // Unknown
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('xyz') = nil);
end;

// ---------------------------------------------------------------------------
// Delphi form files (.dfm) and source-file aliases
// ---------------------------------------------------------------------------

procedure TMarkdownHighlightTests.TestDfmKeywords;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('dfm');
  Assert.IsTrue(HL <> nil);
  Assert.AreEqual('DFM', HL.GetLanguageName);

  // object Button1: TButton ... end
  Tokens := HL.Highlight('object Button1: TButton'#13#10'end');
  // object(0=stKeyword) ' '(1) Button1(2=stPlain) :(3=stSymbol) ' '(4)
  // TButton(5=stPlain) CRLF(6=stPlain) end(7=stKeyword)
  Assert.AreEqual(stKeyword, Tokens[0].Kind);
  Assert.AreEqual('object', Tokens[0].Text);
  Assert.AreEqual(stPlain, Tokens[2].Kind);
  Assert.AreEqual('Button1', Tokens[2].Text);
  Assert.AreEqual(stSymbol, Tokens[3].Kind);
  Assert.AreEqual(':', Tokens[3].Text);
  Assert.AreEqual(stKeyword, Tokens[High(Tokens)].Kind);
  Assert.AreEqual('end', Tokens[High(Tokens)].Text);
end;

procedure TMarkdownHighlightTests.TestDfmPropertyValues;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('dfm');
  Assert.IsTrue(HL <> nil);

  // Qualified property name, string value, hex colour, boolean
  Tokens := HL.Highlight('Caption = ''OK''');
  Assert.AreEqual('Caption', Tokens[0].Text);
  Assert.AreEqual(stPlain, Tokens[0].Kind);
  Assert.AreEqual(stSymbol, Tokens[2].Kind);
  Assert.AreEqual('=', Tokens[2].Text);
  Assert.AreEqual(stString, Tokens[4].Kind);
  Assert.AreEqual('''OK''', Tokens[4].Text);

  // Qualified name stays one token
  Tokens := HL.Highlight('Font.Charset = DEFAULT_CHARSET');
  Assert.AreEqual('Font.Charset', Tokens[0].Text);

  // Hex colour value
  Tokens := HL.Highlight('Color = $00FF8040');
  Assert.AreEqual(stNumber, Tokens[High(Tokens)].Kind);
  Assert.AreEqual('$00FF8040', Tokens[High(Tokens)].Text);

  // Boolean literal classified as type
  Tokens := HL.Highlight('Enabled = True');
  Assert.AreEqual(stType, Tokens[High(Tokens)].Kind);
  Assert.AreEqual('True', Tokens[High(Tokens)].Text);
end;

procedure TMarkdownHighlightTests.TestDfmCharConstants;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('dfm');
  Assert.IsTrue(HL <> nil);

  // #13#10 decimal char constants -> two adjacent string tokens
  Tokens := HL.Highlight('#13#10');
  Assert.AreEqual(2, Length(Tokens));
  Assert.AreEqual(stString, Tokens[0].Kind);
  Assert.AreEqual('#13', Tokens[0].Text);
  Assert.AreEqual('#10', Tokens[1].Text);

  // #$0D hex char constant
  Tokens := HL.Highlight('#$0D');
  Assert.AreEqual(1, Length(Tokens));
  Assert.AreEqual(stString, Tokens[0].Kind);
  Assert.AreEqual('#$0D', Tokens[0].Text);
end;

procedure TMarkdownHighlightTests.TestDelphiSourceFileAliases;
var
  Delphi: IMarkdownSyntaxHighlighter;
begin
  Delphi := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('delphi');
  Assert.IsTrue(Delphi <> nil);
  // .dpr / .dpk and the other Pascal source extensions map to the Delphi lexer
  Assert.AreSame(Delphi, TMarkdownSyntaxHighlighterRegistry.GetHighlighter('dpr'));
  Assert.AreSame(Delphi, TMarkdownSyntaxHighlighterRegistry.GetHighlighter('dpk'));
  Assert.AreSame(Delphi, TMarkdownSyntaxHighlighterRegistry.GetHighlighter('objectpascal'));
  // c# is an alias of the C# highlighter
  Assert.IsTrue(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('c#') <> nil);
  Assert.AreSame(TMarkdownSyntaxHighlighterRegistry.GetHighlighter('csharp'),
    TMarkdownSyntaxHighlighterRegistry.GetHighlighter('c#'));
end;

// ---------------------------------------------------------------------------
// Whole-stream invariants
// ---------------------------------------------------------------------------

procedure TMarkdownHighlightTests.TestTokenStreamInvariantsAllLanguages;
const
  Langs: array[0..33] of string = (
    'delphi', 'dfm', 'sql', 'c', 'cpp', 'csharp', 'java', 'js', 'ts', 'go',
    'rust', 'php', 'python', 'ruby', 'html', 'xml', 'css', 'json', 'yaml',
    'sh', 'ini', 'pas', 'dpr', 'rb',
    'latex', 'tex', 'powershell', 'ps1', 'batch', 'bat', 'cmd', 'vb', 'visualbasic', 'vbs');
  // A varied sample exercising strings, comments, numbers, symbols and
  // keywords. Run through every highlighter regardless of language so each
  // lexer must tile arbitrary input without gaps or zero-length tokens.
  Samples: array[0..7] of string = (
    'function Foo(const x: Integer): string; // note',
    'SELECT * FROM t WHERE a = ''b'' AND n = 42;',
    'int main(void) { return 0xFF; /* done */ }',
    'def f(): return "x" # comment',
    '<div class="a">Hi &amp; bye</div>',
    '{ "k": [1, 2.5, true, null], "s": "v" }',
    'key: value # c'#13#10'- item',
    'object F: TForm'#13#10'  Caption = ''Hi'''#13#10'end');
var
  L, S: Integer;
  HL: IMarkdownSyntaxHighlighter;
begin
  for L := 0 to High(Langs) do
  begin
    HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter(Langs[L]);
    Assert.IsTrue(HL <> nil, 'missing highlighter: ' + Langs[L]);
    for S := 0 to High(Samples) do
      AssertTokenStreamValid(HL, Samples[S]);
  end;
end;

procedure TMarkdownHighlightTests.TestTokenStreamInvariantsAdversarialInput;
const
  Langs: array[0..33] of string = (
    'delphi', 'dfm', 'sql', 'c', 'cpp', 'csharp', 'java', 'js', 'ts', 'go',
    'rust', 'php', 'python', 'ruby', 'html', 'xml', 'css', 'json', 'yaml',
    'sh', 'ini', 'pas', 'dpr', 'rb',
    'latex', 'tex', 'powershell', 'ps1', 'batch', 'bat', 'cmd', 'vb', 'visualbasic', 'vbs');
  // Inputs that historically broke naive lexers: lone delimiters, unterminated
  // strings and comments, bare symbols, and characters outside the keyword
  // sets. None may produce a gap, overlap or non-advancing token.
  Inputs: array[0..18] of string = (
    '',
    ' ',
    #9#9,
    '"',
    '''',
    '/*',
    '//',
    '#',
    '$',
    '@',
    '`',
    '<',
    '&',
    '[',
    ':',
    '"unterminated string',
    '/* unterminated comment',
    '0x', // hex prefix with no digits
    '....::==<<>>{}[]()');
var
  L, S: Integer;
  HL: IMarkdownSyntaxHighlighter;
begin
  for L := 0 to High(Langs) do
  begin
    HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter(Langs[L]);
    Assert.IsTrue(HL <> nil, 'missing highlighter: ' + Langs[L]);
    for S := 0 to High(Inputs) do
      AssertTokenStreamValid(HL, Inputs[S]);
  end;
end;

// ---------------------------------------------------------------------------
// Cached per-block tokenization
// ---------------------------------------------------------------------------

procedure TMarkdownHighlightTests.TestBlockHighlightTokensMatchRegistry;
var
  Block: TMarkDownBlock;
  Cached, Direct, Again: TArray<TSourceToken>;
  HL: IMarkdownSyntaxHighlighter;
  I: Integer;
begin
  Block := TMarkDownBlock.Create;
  try
    Block.Kind := bkCodeBlock;
    Block.CodeLanguage := 'pascal';
    Block.Text := 'begin'#13#10'  WriteLn(''Hi'');'#13#10'end';

    HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('pascal');
    Direct := HL.Highlight(Block.Text);

    Cached := Block.HighlightTokens;
    Assert.AreEqual(Length(Direct), Length(Cached));
    for I := 0 to High(Direct) do
    begin
      Assert.AreEqual(Direct[I].Text, Cached[I].Text);
      Assert.AreEqual(Direct[I].Offset, Cached[I].Offset);
      Assert.AreEqual(Ord(Direct[I].Kind), Ord(Cached[I].Kind));
    end;

    // A second request returns the same cached tokens.
    Again := Block.HighlightTokens;
    Assert.AreEqual(Length(Cached), Length(Again));
  finally
    Block.Free;
  end;
end;

procedure TMarkdownHighlightTests.TestBlockHighlightTokensFallBackToNil;
var
  Block: TMarkDownBlock;
begin
  // Unknown language -> nil, which signals the plain (unhighlighted) path.
  Block := TMarkDownBlock.Create;
  try
    Block.Kind := bkCodeBlock;
    Block.CodeLanguage := 'no_such_language';
    Block.Text := 'plain text';
    Assert.IsTrue(Block.HighlightTokens = nil);
  finally
    Block.Free;
  end;

  // No language tag -> nil as well.
  Block := TMarkDownBlock.Create;
  try
    Block.Kind := bkCodeBlock;
    Block.CodeLanguage := '';
    Block.Text := 'plain text';
    Assert.IsTrue(Block.HighlightTokens = nil);
  finally
    Block.Free;
  end;
end;

procedure TMarkdownHighlightTests.TestLaTeXHighlighter;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('latex');
  Assert.IsNotNull(HL);

  Tokens := HL.Highlight('\begin{document} % comment'#13#10'LaTeX 123');
  Assert.IsTrue(Length(Tokens) > 0);
  Assert.AreEqual(stPreprocessor, Tokens[0].Kind);
  Assert.AreEqual('\begin', Tokens[0].Text);
end;

procedure TMarkdownHighlightTests.TestPowerShellHighlighter;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('powershell');
  Assert.IsNotNull(HL);

  Tokens := HL.Highlight('if ($x -eq 12) { Get-Process "chrome" # comment }');
  Assert.IsTrue(Length(Tokens) > 0);
  Assert.AreEqual(stKeyword, Tokens[0].Kind);
  Assert.AreEqual('if', Tokens[0].Text);
end;

procedure TMarkdownHighlightTests.TestBatchHighlighter;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('batch');
  Assert.IsNotNull(HL);

  Tokens := HL.Highlight('@echo off'#13#10'set %VAR%=12'#13#10'rem comment');
  Assert.IsTrue(Length(Tokens) > 0);
  Assert.AreEqual(stKeyword, Tokens[0].Kind);
  Assert.AreEqual('@echo', Tokens[0].Text);
end;

procedure TMarkdownHighlightTests.TestVBHighlighter;
var
  HL: IMarkdownSyntaxHighlighter;
  Tokens: TArray<TSourceToken>;
begin
  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter('vb');
  Assert.IsNotNull(HL);

  Tokens := HL.Highlight('Dim x As Integer = 42 '' comment');
  Assert.IsTrue(Length(Tokens) > 0);
  Assert.AreEqual(stKeyword, Tokens[0].Kind);
  Assert.AreEqual('Dim', Tokens[0].Text);
end;

initialization
  TDUnitX.RegisterTestFixture(TMarkdownHighlightTests);

end.
