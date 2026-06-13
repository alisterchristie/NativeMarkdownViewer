unit MarkdownViewer.Highlight;

interface

uses
  System.Generics.Collections,
  System.SysUtils;

type
  TSourceTokenKind = (stPlain, stKeyword, stComment, stString, stNumber, stType, stPreprocessor, stSymbol);

  TSourceToken = record
    Text: string;
    Kind: TSourceTokenKind;
    Offset: Integer; // 0-based offset within the source block text
  end;

  IMarkdownSyntaxHighlighter = interface
    ['{6BCDF912-3D7E-4E7B-B410-64DECCBD5D34}']
    function GetLanguageName: string;
    function Highlight(const AText: string): TArray<TSourceToken>;
  end;

  TMarkdownSyntaxHighlighterRegistry = class
  private
    class var FHighlighters: TDictionary<string, IMarkdownSyntaxHighlighter>;
    class constructor Create;
    class destructor Destroy;
  public
    class procedure RegisterHighlighter(const ALang: string; const AHighlighter: IMarkdownSyntaxHighlighter);
    class function GetHighlighter(const ALang: string): IMarkdownSyntaxHighlighter;
  end;

  TDelphiSyntaxHighlighter = class(TInterfacedObject, IMarkdownSyntaxHighlighter)
  private
    FKeywords: THashSet<string>;
    FTypes: THashSet<string>;
    procedure InitializeKeywordsAndTypes;
  public
    constructor Create;
    destructor Destroy; override;
    function GetLanguageName: string;
    function Highlight(const AText: string): TArray<TSourceToken>;
  end;

  TSQLSyntaxHighlighter = class(TInterfacedObject, IMarkdownSyntaxHighlighter)
  private
    FKeywords: THashSet<string>;
    procedure InitializeKeywords;
  public
    constructor Create;
    destructor Destroy; override;
    function GetLanguageName: string;
    function Highlight(const AText: string): TArray<TSourceToken>;
  end;

implementation

{ TMarkdownSyntaxHighlighterRegistry }

class constructor TMarkdownSyntaxHighlighterRegistry.Create;
var
  DelphiHL: IMarkdownSyntaxHighlighter;
  SqlHL: IMarkdownSyntaxHighlighter;
begin
  FHighlighters := TDictionary<string, IMarkdownSyntaxHighlighter>.Create;
  
  // Register default highlighters
  DelphiHL := TDelphiSyntaxHighlighter.Create;
  RegisterHighlighter('pascal', DelphiHL);
  RegisterHighlighter('delphi', DelphiHL);
  RegisterHighlighter('pas', DelphiHL);
  
  SqlHL := TSQLSyntaxHighlighter.Create;
  RegisterHighlighter('sql', SqlHL);
end;

class destructor TMarkdownSyntaxHighlighterRegistry.Destroy;
begin
  FHighlighters.Free;
end;

class procedure TMarkdownSyntaxHighlighterRegistry.RegisterHighlighter(
  const ALang: string; const AHighlighter: IMarkdownSyntaxHighlighter);
begin
  FHighlighters.AddOrSetValue(LowerCase(ALang), AHighlighter);
end;

class function TMarkdownSyntaxHighlighterRegistry.GetHighlighter(
  const ALang: string): IMarkdownSyntaxHighlighter;
begin
  if not FHighlighters.TryGetValue(LowerCase(ALang), Result) then
    Result := nil;
end;

{ TDelphiSyntaxHighlighter }

constructor TDelphiSyntaxHighlighter.Create;
begin
  inherited Create;
  FKeywords := THashSet<string>.Create;
  FTypes := THashSet<string>.Create;
  InitializeKeywordsAndTypes;
end;

destructor TDelphiSyntaxHighlighter.Destroy;
begin
  FKeywords.Free;
  FTypes.Free;
  inherited Destroy;
end;

function TDelphiSyntaxHighlighter.GetLanguageName: string;
begin
  Result := 'Delphi';
end;

procedure TDelphiSyntaxHighlighter.InitializeKeywordsAndTypes;
const
  Keywords: array[0..66] of string = (
    'and', 'array', 'as', 'asm', 'begin', 'case', 'class', 'const', 'constructor',
    'destructor', 'dispinterface', 'div', 'do', 'downto', 'else', 'end', 'except',
    'exports', 'file', 'finalization', 'finally', 'for', 'function', 'goto', 'if',
    'implementation', 'in', 'inherited', 'initialization', 'inline', 'interface',
    'is', 'label', 'library', 'mod', 'nil', 'not', 'object', 'of', 'on', 'or', 'out',
    'packed', 'procedure', 'program', 'property', 'raise', 'record', 'repeat',
    'resourcestring', 'set', 'shl', 'shr', 'string', 'then', 'threadvar', 'to', 'try',
    'type', 'unit', 'until', 'uses', 'value', 'var', 'while', 'with', 'xor'
  );
  Directives: array[0..41] of string = (
    'absolute', 'abstract', 'assembler', 'automated', 'cdecl', 'deprecated', 'dispid',
    'dynamic', 'export', 'external', 'far', 'forward', 'helper', 'implements', 'local',
    'message', 'name', 'near', 'nodefault', 'overload', 'override', 'pascal', 'platform',
    'private', 'protected', 'public', 'published', 'read', 'readonly', 'register',
    'reintroduced', 'requires', 'resident', 'safecall', 'stdcall', 'stored', 'strict',
    'unsafe', 'virtual', 'write', 'writeonly', 'reference'
  );
  Types: array[0..17] of string = (
    'integer', 'cardinal', 'shortint', 'smallint', 'longint', 'int64', 'byte', 'word',
    'longword', 'boolean', 'char', 'ansichar', 'widechar', 'string', 'unicodestring',
    'ansistring', 'widestring', 'real'
  );
var
  K: string;
begin
  for K in Keywords do
    FKeywords.Add(K);
  for K in Directives do
    FKeywords.Add(K);
  for K in Types do
    FTypes.Add(K);
end;

function TDelphiSyntaxHighlighter.Highlight(const AText: string): TArray<TSourceToken>;
var
  Tokens: TList<TSourceToken>;
  I, N: Integer;
  StartPos: Integer;

  procedure AddToken(AKind: TSourceTokenKind; ALength: Integer);
  var
    Token: TSourceToken;
  begin
    if ALength <= 0 then Exit;
    Token.Text := Copy(AText, StartPos, ALength);
    Token.Kind := AKind;
    Token.Offset := StartPos - 1;
    Tokens.Add(Token);
    I := StartPos + ALength;
  end;

  function IsKeyword(const S: string): Boolean;
  begin
    Result := FKeywords.Contains(LowerCase(S));
  end;

  function IsType(const S: string): Boolean;
  begin
    Result := FTypes.Contains(LowerCase(S));
  end;

  function IsIdentChar(C: Char): Boolean;
  begin
    Result := CharInSet(C, ['a'..'z', 'A'..'Z', '_', '0'..'9']) or (Ord(C) > 127);
  end;

  function IsIdentStart(C: Char): Boolean;
  begin
    Result := CharInSet(C, ['a'..'z', 'A'..'Z', '_']) or (Ord(C) > 127);
  end;

begin
  Tokens := TList<TSourceToken>.Create;
  try
    I := 1;
    N := Length(AText);
    while I <= N do
    begin
      StartPos := I;

      // 1. Whitespace
      if CharInSet(AText[I], [' ', #9, #13, #10]) then
      begin
        while (I <= N) and CharInSet(AText[I], [' ', #9, #13, #10]) do
          Inc(I);
        AddToken(stPlain, I - StartPos);
        Continue;
      end;

      // 2. Delphi 12 Multi-line string (starts with ''')
      if (I + 2 <= N) and (AText[I] = '''') and (AText[I+1] = '''') and (AText[I+2] = '''') then
      begin
        I := I + 3;
        while I <= N do
        begin
          if (I + 2 <= N) and (AText[I] = '''') and (AText[I+1] = '''') and (AText[I+2] = '''') then
          begin
            I := I + 3;
            Break;
          end;
          Inc(I);
        end;
        AddToken(stString, I - StartPos);
        Continue;
      end;

      // 3. Regular string or Char (starts with ')
      if AText[I] = '''' then
      begin
        Inc(I);
        while I <= N do
        begin
          if AText[I] = '''' then
          begin
            Inc(I);
            // Handle escaped quote (double single quotes: '')
            if (I <= N) and (AText[I] = '''') then
              Inc(I)
            else
              Break;
          end
          else if CharInSet(AText[I], [#13, #10]) then
            Break // Unterminated single-line string
          else
            Inc(I);
        end;
        AddToken(stString, I - StartPos);
        Continue;
      end;

      // 4. Line Comment (//)
      if (I + 1 <= N) and (AText[I] = '/') and (AText[I+1] = '/') then
      begin
        I := I + 2;
        while (I <= N) and not CharInSet(AText[I], [#13, #10]) do
          Inc(I);
        AddToken(stComment, I - StartPos);
        Continue;
      end;

      // 5. Curly Comment ({}) or Compiler Directive ({$})
      if AText[I] = '{' then
      begin
        Inc(I);
        if (I <= N) and (AText[I] = '$') then
        begin
          while (I <= N) and (AText[I] <> '}') do
            Inc(I);
          if I <= N then Inc(I);
          AddToken(stPreprocessor, I - StartPos);
        end
        else
        begin
          while (I <= N) and (AText[I] <> '}') do
            Inc(I);
          if I <= N then Inc(I);
          AddToken(stComment, I - StartPos);
        end;
        Continue;
      end;

      // 6. Paren-Star Comment ((**))
      if (I + 1 <= N) and (AText[I] = '(') and (AText[I+1] = '*') then
      begin
        I := I + 2;
        while I <= N do
        begin
          if (I + 1 <= N) and (AText[I] = '*') and (AText[I+1] = ')') then
          begin
            I := I + 2;
            Break;
          end;
          Inc(I);
        end;
        AddToken(stComment, I - StartPos);
        Continue;
      end;

      // 7. Numbers
      // Hex: $1A2F
      if AText[I] = '$' then
      begin
        Inc(I);
        while (I <= N) and CharInSet(AText[I], ['0'..'9', 'a'..'f', 'A'..'F']) do
          Inc(I);
        AddToken(stNumber, I - StartPos);
        Continue;
      end;
      // Float/Decimal
      if CharInSet(AText[I], ['0'..'9']) then
      begin
        while (I <= N) and CharInSet(AText[I], ['0'..'9']) do
          Inc(I);
        // Check if dot is followed by digit (float, not range 1..10)
        if (I + 1 <= N) and (AText[I] = '.') and CharInSet(AText[I+1], ['0'..'9']) then
        begin
          I := I + 2;
          while (I <= N) and CharInSet(AText[I], ['0'..'9']) do
            Inc(I);
        end;
        // Exponent
        if (I <= N) and CharInSet(AText[I], ['e', 'E']) then
        begin
          Inc(I);
          if (I <= N) and CharInSet(AText[I], ['+', '-']) then
            Inc(I);
          while (I <= N) and CharInSet(AText[I], ['0'..'9']) do
            Inc(I);
        end;
        AddToken(stNumber, I - StartPos);
        Continue;
      end;

      // 8. Identifiers / Keywords / Types
      if IsIdentStart(AText[I]) then
      begin
        while (I <= N) and IsIdentChar(AText[I]) do
          Inc(I);

        if IsKeyword(Copy(AText, StartPos, I - StartPos)) then
          AddToken(stKeyword, I - StartPos)
        else if IsType(Copy(AText, StartPos, I - StartPos)) then
          AddToken(stType, I - StartPos)
        else
          AddToken(stPlain, I - StartPos);
        Continue;
      end;

      // 9. Symbols / Operators
      if CharInSet(AText[I], ['+', '-', '*', '/', '=', '<', '>', '@', '^', '.', ',', ':', ';', '(', ')', '[', ']']) then
      begin
        Inc(I);
        AddToken(stSymbol, I - StartPos);
        Continue;
      end;

      // Fallback
      Inc(I);
      AddToken(stPlain, I - StartPos);
    end;
    Result := Tokens.ToArray;
  finally
    Tokens.Free;
  end;
end;

{ TSQLSyntaxHighlighter }

constructor TSQLSyntaxHighlighter.Create;
begin
  inherited Create;
  FKeywords := THashSet<string>.Create;
  InitializeKeywords;
end;

destructor TSQLSyntaxHighlighter.Destroy;
begin
  FKeywords.Free;
  inherited Destroy;
end;

function TSQLSyntaxHighlighter.GetLanguageName: string;
begin
  Result := 'SQL';
end;

procedure TSQLSyntaxHighlighter.InitializeKeywords;
const
  Keywords: array[0..89] of string = (
    'select', 'insert', 'update', 'delete', 'from', 'where', 'join', 'left', 'right',
    'inner', 'outer', 'on', 'group', 'by', 'having', 'order', 'create', 'table', 'alter',
    'drop', 'index', 'view', 'into', 'values', 'set', 'as', 'and', 'or', 'not', 'in',
    'is', 'null', 'like', 'between', 'exists', 'all', 'any', 'some', 'primary', 'key',
    'foreign', 'references', 'constraint', 'check', 'unique', 'default', 'cascade',
    'restrict', 'trigger', 'procedure', 'function', 'returns', 'declare', 'begin', 'end',
    'if', 'else', 'while', 'loop', 'case', 'when', 'then', 'cast', 'convert', 'union',
    'intersect', 'except', 'database', 'schema', 'grant', 'revoke', 'commit', 'rollback',
    'transaction', 'exec', 'execute', 'varchar', 'char', 'int', 'integer', 'float',
    'double', 'numeric', 'decimal', 'date', 'time', 'timestamp', 'boolean', 'bit', 'text'
  );
var
  K: string;
begin
  for K in Keywords do
    FKeywords.Add(K);
end;

function TSQLSyntaxHighlighter.Highlight(const AText: string): TArray<TSourceToken>;
var
  Tokens: TList<TSourceToken>;
  I, N: Integer;
  StartPos: Integer;

  procedure AddToken(AKind: TSourceTokenKind; ALength: Integer);
  var
    Token: TSourceToken;
  begin
    if ALength <= 0 then Exit;
    Token.Text := Copy(AText, StartPos, ALength);
    Token.Kind := AKind;
    Token.Offset := StartPos - 1;
    Tokens.Add(Token);
    I := StartPos + ALength;
  end;

  function IsKeyword(const S: string): Boolean;
  begin
    Result := FKeywords.Contains(LowerCase(S));
  end;

  function IsIdentChar(C: Char): Boolean;
  begin
    Result := CharInSet(C, ['a'..'z', 'A'..'Z', '_', '0'..'9']) or (Ord(C) > 127);
  end;

  function IsIdentStart(C: Char): Boolean;
  begin
    Result := CharInSet(C, ['a'..'z', 'A'..'Z', '_']) or (Ord(C) > 127);
  end;

begin
  Tokens := TList<TSourceToken>.Create;
  try
    I := 1;
    N := Length(AText);
    while I <= N do
    begin
      StartPos := I;

      // 1. Whitespace
      if CharInSet(AText[I], [' ', #9, #13, #10]) then
      begin
        while (I <= N) and CharInSet(AText[I], [' ', #9, #13, #10]) do
          Inc(I);
        AddToken(stPlain, I - StartPos);
        Continue;
      end;

      // 2. Line Comment (--)
      if (I + 1 <= N) and (AText[I] = '-') and (AText[I+1] = '-') then
      begin
        I := I + 2;
        while (I <= N) and not CharInSet(AText[I], [#13, #10]) do
          Inc(I);
        AddToken(stComment, I - StartPos);
        Continue;
      end;

      // 3. Block Comment (/* */)
      if (I + 1 <= N) and (AText[I] = '/') and (AText[I+1] = '*') then
      begin
        I := I + 2;
        while I <= N do
        begin
          if (I + 1 <= N) and (AText[I] = '*') and (AText[I+1] = '/') then
          begin
            I := I + 2;
            Break;
          end;
          Inc(I);
        end;
        AddToken(stComment, I - StartPos);
        Continue;
      end;

      // 4. String (starts with ')
      if AText[I] = '''' then
      begin
        Inc(I);
        while I <= N do
        begin
          if AText[I] = '''' then
          begin
            Inc(I);
            // Escaped quote: ''
            if (I <= N) and (AText[I] = '''') then
              Inc(I)
            else
              Break;
          end
          else
            Inc(I);
        end;
        AddToken(stString, I - StartPos);
        Continue;
      end;

      // 5. Delimited Identifier in Double Quotes (e.g. "table_name")
      if AText[I] = '"' then
      begin
        Inc(I);
        while (I <= N) and (AText[I] <> '"') do
          Inc(I);
        if I <= N then Inc(I);
        AddToken(stPlain, I - StartPos);
        Continue;
      end;

      // Delimited Identifier in Brackets (e.g. [table_name])
      if AText[I] = '[' then
      begin
        Inc(I);
        while (I <= N) and (AText[I] <> ']') do
          Inc(I);
        if I <= N then Inc(I);
        AddToken(stPlain, I - StartPos);
        Continue;
      end;

      // 6. Numbers
      if CharInSet(AText[I], ['0'..'9']) then
      begin
        while (I <= N) and CharInSet(AText[I], ['0'..'9']) do
          Inc(I);
        if (I + 1 <= N) and (AText[I] = '.') and CharInSet(AText[I+1], ['0'..'9']) then
        begin
          I := I + 2;
          while (I <= N) and CharInSet(AText[I], ['0'..'9']) do
            Inc(I);
        end;
        AddToken(stNumber, I - StartPos);
        Continue;
      end;

      // 7. Identifiers / Keywords
      if IsIdentStart(AText[I]) then
      begin
        while (I <= N) and IsIdentChar(AText[I]) do
          Inc(I);

        if IsKeyword(Copy(AText, StartPos, I - StartPos)) then
          AddToken(stKeyword, I - StartPos)
        else
          AddToken(stPlain, I - StartPos);
        Continue;
      end;

      // 8. Symbols
      if CharInSet(AText[I], ['+', '-', '*', '/', '=', '<', '>', ',', '.', ';', '(', ')', '!']) then
      begin
        Inc(I);
        AddToken(stSymbol, I - StartPos);
        Continue;
      end;

      // Fallback
      Inc(I);
      AddToken(stPlain, I - StartPos);
    end;
    Result := Tokens.ToArray;
  finally
    Tokens.Free;
  end;
end;

end.
