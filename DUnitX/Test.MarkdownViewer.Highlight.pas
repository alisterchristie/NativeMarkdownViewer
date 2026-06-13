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
  end;

implementation

uses
  System.SysUtils,
  MarkdownViewer.Highlight;

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

initialization
  TDUnitX.RegisterTestFixture(TMarkdownHighlightTests);

end.
