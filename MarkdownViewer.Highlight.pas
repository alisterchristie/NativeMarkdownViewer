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

  TGenericSyntaxHighlighter = class(TInterfacedObject, IMarkdownSyntaxHighlighter)
  private
    FLanguageName: string;
    FKeywords: THashSet<string>;
    FTypes: THashSet<string>;
    FSupportsPreprocessor: Boolean;
  public
    constructor Create(const ALanguageName: string;
      const AKeywords, ATypes: TArray<string>; ASupportsPreprocessor: Boolean);
    destructor Destroy; override;
    function GetLanguageName: string;
    function Highlight(const AText: string): TArray<TSourceToken>;
  end;

  TPythonSyntaxHighlighter = class(TInterfacedObject, IMarkdownSyntaxHighlighter)
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

  TRubySyntaxHighlighter = class(TInterfacedObject, IMarkdownSyntaxHighlighter)
  private
    FKeywords: THashSet<string>;
    procedure InitializeKeywords;
  public
    constructor Create;
    destructor Destroy; override;
    function GetLanguageName: string;
    function Highlight(const AText: string): TArray<TSourceToken>;
  end;

  TMarkupSyntaxHighlighter = class(TInterfacedObject, IMarkdownSyntaxHighlighter)
  private
    FLanguageName: string;
  public
    constructor Create(const ALanguageName: string);
    function GetLanguageName: string;
    function Highlight(const AText: string): TArray<TSourceToken>;
  end;

  TCSSSyntaxHighlighter = class(TInterfacedObject, IMarkdownSyntaxHighlighter)
  private
    FProperties: THashSet<string>;
    procedure InitializeProperties;
  public
    constructor Create;
    destructor Destroy; override;
    function GetLanguageName: string;
    function Highlight(const AText: string): TArray<TSourceToken>;
  end;

  TJSONSyntaxHighlighter = class(TInterfacedObject, IMarkdownSyntaxHighlighter)
  public
    function GetLanguageName: string;
    function Highlight(const AText: string): TArray<TSourceToken>;
  end;

  TYAMLSyntaxHighlighter = class(TInterfacedObject, IMarkdownSyntaxHighlighter)
  public
    function GetLanguageName: string;
    function Highlight(const AText: string): TArray<TSourceToken>;
  end;

  TShellSyntaxHighlighter = class(TInterfacedObject, IMarkdownSyntaxHighlighter)
  private
    FKeywords: THashSet<string>;
    procedure InitializeKeywords;
  public
    constructor Create;
    destructor Destroy; override;
    function GetLanguageName: string;
    function Highlight(const AText: string): TArray<TSourceToken>;
  end;

  TINISyntaxHighlighter = class(TInterfacedObject, IMarkdownSyntaxHighlighter)
  public
    function GetLanguageName: string;
    function Highlight(const AText: string): TArray<TSourceToken>;
  end;

implementation

{ TMarkdownSyntaxHighlighterRegistry }

class constructor TMarkdownSyntaxHighlighterRegistry.Create;
var
  DelphiHL: IMarkdownSyntaxHighlighter;
  SqlHL: IMarkdownSyntaxHighlighter;
  GenHL: IMarkdownSyntaxHighlighter;
  PyHL: IMarkdownSyntaxHighlighter;
begin
  FHighlighters := TDictionary<string, IMarkdownSyntaxHighlighter>.Create;

  // Register default highlighters
  DelphiHL := TDelphiSyntaxHighlighter.Create;
  RegisterHighlighter('pascal', DelphiHL);
  RegisterHighlighter('delphi', DelphiHL);
  RegisterHighlighter('pas', DelphiHL);

  SqlHL := TSQLSyntaxHighlighter.Create;
  RegisterHighlighter('sql', SqlHL);

  // C
  GenHL := TGenericSyntaxHighlighter.Create('C',
    ['auto','break','case','char','const','continue','default','do','double',
     'else','enum','extern','float','for','goto','if','int','long','register',
     'return','short','signed','sizeof','static','struct','switch','typedef',
     'union','unsigned','void','volatile','while','bool','inline','restrict',
     'alignas','alignof','noreturn','static_assert','thread_local',
     'define','elif','else','endif','error','ifdef','ifndef','include','line',
     'pragma','undef'],
    ['int','char','float','double','void','short','long','unsigned','signed',
     'size_t','ssize_t','ptrdiff_t','intptr_t','uintptr_t','int8_t','int16_t',
     'int32_t','int64_t','uint8_t','uint16_t','uint32_t','uint64_t',
     'bool','wchar_t','FILE','time_t','clock_t','div_t','ldiv_t'],
    True);
  RegisterHighlighter('c', GenHL);

  // C++
  GenHL := TGenericSyntaxHighlighter.Create('C++',
    ['alignas','alignof','and','and_eq','asm','auto','bitand','bitor','bool',
     'break','case','catch','char','char8_t','char16_t','char32_t','class',
     'compl','concept','const','consteval','constexpr','constinit','const_cast',
     'continue','co_await','co_return','co_yield','decltype','default','delete',
     'do','double','dynamic_cast','else','enum','explicit','export','extern',
     'false','float','for','friend','goto','if','import','inline','int','long',
     'module','mutable','namespace','new','noexcept','not','not_eq','nullptr',
     'operator','or','or_eq','override','private','protected','public',
     'register','reinterpret_cast','requires','return','short','signed',
     'sizeof','static','static_assert','static_cast','struct','switch',
     'template','this','thread_local','throw','true','try','typedef','typeid',
     'typename','union','unsigned','using','virtual','void','volatile','wchar_t',
     'while','xor','xor_eq'],
    ['bool','char','char8_t','char16_t','char32_t','wchar_t','short','int',
     'long','float','double','void','size_t','string','wstring','u16string',
     'u32string','vector','map','set','list','deque','array','tuple','pair',
     'shared_ptr','unique_ptr','weak_ptr','istream','ostream','iostream',
     'fstream','stringstream','ifstream','ofstream','function','optional',
     'variant','any','string_view','span','mutex','lock_guard','thread',
     'condition_variable','promise','future','atomic','exception','runtime_error',
     'logic_error','initializer_list','chrono'],
    True);
  RegisterHighlighter('cpp', GenHL);
  RegisterHighlighter('c++', GenHL);
  RegisterHighlighter('cxx', GenHL);
  RegisterHighlighter('cc', GenHL);
  RegisterHighlighter('hpp', GenHL);

  // C#
  GenHL := TGenericSyntaxHighlighter.Create('C#',
    ['abstract','as','base','bool','break','byte','case','catch','char',
     'checked','class','const','continue','decimal','default','delegate','do',
     'double','else','enum','event','explicit','extern','false','finally','fixed',
     'float','for','foreach','goto','if','implicit','in','int','interface',
     'internal','is','lock','long','namespace','new','null','object','operator',
     'out','override','params','private','protected','public','readonly','ref',
     'return','sbyte','sealed','short','sizeof','stackalloc','static','string',
     'struct','switch','this','throw','true','try','typeof','uint','ulong',
     'unchecked','unsafe','ushort','using','var','virtual','void','volatile',
     'while','add','alias','async','await','dynamic','get','global','init',
     'nint','notnull','nuint','partial','record','remove','required','scoped',
     'set','value','when','where','yield'],
    ['bool','byte','sbyte','char','decimal','double','float','int','uint','long',
     'ulong','short','ushort','object','string','var','void','nint','nuint',
     'DateTime','TimeSpan','Guid','Task','List','Dictionary','Array','Tuple',
     'Enum','Exception','Stream','File','String','Int32','Int64','Boolean',
     'Single','Double','Decimal','StringBuilder','IEnumerable','IEnumerator',
     'IDisposable','IAsyncEnumerable','Task<T>','ValueTask','Nullable',
     'ReadOnlySpan','Span','Memory','CancellationToken','Uri','HttpClient',
     'JsonSerializer'],
    True);
  RegisterHighlighter('cs', GenHL);
  RegisterHighlighter('csharp', GenHL);

  // Java
  GenHL := TGenericSyntaxHighlighter.Create('Java',
    ['abstract','assert','boolean','break','byte','case','catch','char','class',
     'const','continue','default','do','double','else','enum','extends','final',
     'finally','float','for','goto','if','implements','import','instanceof',
     'int','interface','long','native','new','package','private','protected',
     'public','return','short','static','strictfp','super','switch',
     'synchronized','this','throw','throws','transient','try','void','volatile',
     'while','var','module','exports','opens','requires','to','with','provides',
     'uses','record','sealed','permits','yield','non-sealed'],
    ['boolean','byte','char','double','float','int','long','short','void',
     'String','Object','Class','Integer','Long','Double','Float','Boolean',
     'Byte','Short','Character','List','Map','Set','ArrayList','HashMap',
     'HashSet','StringBuilder','Exception','RuntimeException','Throwable',
     'Thread','Runnable','Comparable','Serializable','Iterator','Optional',
     'Stream','BigDecimal','BigInteger','LocalDate','LocalTime','LocalDateTime',
     'Instant','Duration','Period','Path','File','Files','HttpClient',
     'HttpRequest','HttpResponse','JsonObject','JsonArray'],
    False);
  RegisterHighlighter('java', GenHL);

  // JavaScript
  GenHL := TGenericSyntaxHighlighter.Create('JavaScript',
    ['async','await','break','case','catch','class','const','continue',
     'debugger','default','delete','do','else','enum','export','extends',
     'false','finally','for','function','if','import','in','instanceof',
     'let','new','null','of','return','static','super','switch','this',
     'throw','true','try','typeof','var','void','while','with','yield',
     'from','as','get','set','target','implements','interface','package',
     'private','protected','public'],
    ['undefined','null','Boolean','Number','String','Symbol','BigInt','Object',
     'Array','Function','Date','RegExp','Error','Map','Set','WeakMap','WeakSet',
     'Promise','Proxy','Reflect','Math','JSON','Intl','ArrayBuffer','DataView',
     'Int8Array','Uint8Array','Int16Array','Uint16Array','Int32Array',
     'Uint32Array','Float32Array','Float64Array','BigInt64Array',
     'BigUint64Array','console','document','window','Element','Event','Node',
     'HTMLElement','FormData','Blob','File','FileReader','URL','URLSearchParams',
     'Headers','Request','Response','fetch','TextEncoder','TextDecoder',
     'WebSocket','EventSource','Worker','localStorage','sessionStorage',
     'setTimeout','clearTimeout','setInterval','clearInterval'],
    False);
  RegisterHighlighter('js', GenHL);
  RegisterHighlighter('javascript', GenHL);

  // TypeScript
  GenHL := TGenericSyntaxHighlighter.Create('TypeScript',
    ['async','await','break','case','catch','class','const','continue',
     'debugger','default','delete','do','else','enum','export','extends',
     'false','finally','for','function','if','import','in','instanceof',
     'let','new','null','of','return','static','super','switch','this',
     'throw','true','try','typeof','var','void','while','with','yield',
     'type','interface','namespace','module','declare','abstract','implements',
     'readonly','keyof','infer','never','unknown','any','as','is','satisfies',
     'override','protected','private','public','get','set','from','target',
     'unique','global','intrinsic','out','asserts'],
    ['undefined','null','Boolean','Number','String','Symbol','BigInt','Object',
     'Array','Function','Date','RegExp','Error','Map','Set','WeakMap','WeakSet',
     'Promise','Proxy','Reflect','Math','JSON','Intl','ArrayBuffer','DataView',
     'Int8Array','Uint8Array','Int16Array','Uint16Array','Int32Array',
     'Uint32Array','Float32Array','Float64Array','BigInt64Array',
     'BigUint64Array','console','document','window','Element','Event','Node',
     'HTMLElement','FormData','Blob','File','FileReader','URL','URLSearchParams',
     'Headers','Request','Response','TextEncoder','TextDecoder',
     'Partial','Required','Readonly','Pick','Omit','Record','Exclude','Extract',
     'NonNullable','ReturnType','InstanceType','Parameters',
     'Awaited','Promise<T>','Map<K,V>','Set<T>','Array<T>','ReadonlyArray<T>'],
    False);
  RegisterHighlighter('ts', GenHL);
  RegisterHighlighter('typescript', GenHL);

  // Go
  GenHL := TGenericSyntaxHighlighter.Create('Go',
    ['break','case','chan','const','continue','default','defer','else',
     'fallthrough','for','func','go','goto','if','import','interface','map',
     'package','range','return','select','struct','switch','type','var'],
    ['bool','byte','complex64','complex128','error','float32','float64','int',
     'int8','int16','int32','int64','rune','string','uint','uint8','uint16',
     'uint32','uint64','uintptr','nil','true','false','iota',
     'any','comparable','Writer','Reader','Closer','Seeker','ReadWriter',
     'ReadCloser','WriteCloser','ReadWriteCloser','Context','Handler',
     'ResponseWriter','Request','ServeMux','DB','Tx','Rows','Row','Result',
     'Scanner','Encoder','Decoder','Marshaler','Unmarshaler','Logger'],
    False);
  RegisterHighlighter('go', GenHL);

  // Rust
  GenHL := TGenericSyntaxHighlighter.Create('Rust',
    ['as','async','await','break','const','continue','crate','dyn','else',
     'enum','extern','false','fn','for','if','impl','in','let','loop','match',
     'mod','move','mut','pub','ref','return','self','Self','static','struct',
     'super','trait','true','type','union','unsafe','use','where','while',
     'yield','abstract','become','box','do','final','macro','override',
     'priv','try','typeof','unsized','virtual'],
    ['bool','char','f32','f64','i8','i16','i32','i64','i128','isize','str',
     'String','u8','u16','u32','u64','u128','usize','Vec','Option','Result',
     'Box','Rc','Arc','RefCell','Cell','Mutex','RwLock','HashMap','HashSet',
     'BTreeMap','BTreeSet','VecDeque','LinkedList','BinaryHeap',
     'Iterator','IntoIterator','From','Into','Default','Clone','Copy','Debug',
     'Display','PartialEq','Eq','PartialOrd','Ord','Fn','FnMut','FnOnce','Drop',
     'Error','Path','PathBuf','File','Read','Write','Seek','BufReader',
     'BufWriter','Cursor','SocketAddr','TcpListener','TcpStream','UdpSocket',
     'Thread','JoinHandle','Duration','Instant','SystemTime'],
    False);
  RegisterHighlighter('rs', GenHL);
  RegisterHighlighter('rust', GenHL);

  // PHP
  GenHL := TGenericSyntaxHighlighter.Create('PHP',
    ['abstract','and','array','as','break','callable','case','catch','class',
     'clone','const','continue','declare','default','die','do','echo','else',
     'elseif','empty','enddeclare','endfor','endforeach','endif','endswitch',
     'endwhile','eval','exit','extends','final','finally','fn','for','foreach',
     'function','global','goto','if','implements','include','include_once',
     'instanceof','insteadof','interface','isset','list','match','namespace',
     'new','or','print','private','protected','public','readonly','require',
     'require_once','return','static','switch','throw','trait','try','unset',
     'use','var','while','xor','yield','from','enum','never'],
    ['int','float','bool','string','array','object','callable','iterable',
     'mixed','void','null','true','false','self','static','parent',
     'DateTime','DateTimeImmutable','DateTimeZone','DateInterval','DatePeriod',
     'Exception','Error','Throwable','PDO','PDOStatement','mysqli',
     'JsonSerializable','Stringable','Traversable','Iterator','IteratorAggregate',
     'Countable','ArrayAccess','Serializable','Closure','Generator',
     'SplFileInfo','SplFileObject','DirectoryIterator','RecursiveIteratorIterator',
     'filter_var','preg_match','json_encode','json_decode',
     'array_map','array_filter','array_reduce','array_merge'],
    False);
  RegisterHighlighter('php', GenHL);

  // Python
  PyHL := TPythonSyntaxHighlighter.Create;
  RegisterHighlighter('py', PyHL);
  RegisterHighlighter('python', PyHL);

  // Ruby
  PyHL := TRubySyntaxHighlighter.Create;
  RegisterHighlighter('rb', PyHL);
  RegisterHighlighter('ruby', PyHL);

  // HTML / XML
  PyHL := TMarkupSyntaxHighlighter.Create('HTML');
  RegisterHighlighter('html', PyHL);
  RegisterHighlighter('htm', PyHL);
  PyHL := TMarkupSyntaxHighlighter.Create('XML');
  RegisterHighlighter('xml', PyHL);

  // CSS
  GenHL := TCSSSyntaxHighlighter.Create;
  RegisterHighlighter('css', GenHL);

  // JSON
  GenHL := TJSONSyntaxHighlighter.Create;
  RegisterHighlighter('json', GenHL);

  // YAML
  GenHL := TYAMLSyntaxHighlighter.Create;
  RegisterHighlighter('yaml', GenHL);
  RegisterHighlighter('yml', GenHL);

  // Shell / Bash
  GenHL := TShellSyntaxHighlighter.Create;
  RegisterHighlighter('sh', GenHL);
  RegisterHighlighter('bash', GenHL);
  RegisterHighlighter('shell', GenHL);

  // INI / Config
  GenHL := TINISyntaxHighlighter.Create;
  RegisterHighlighter('ini', GenHL);
  RegisterHighlighter('cfg', GenHL);
  RegisterHighlighter('conf', GenHL);
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

{ TGenericSyntaxHighlighter - C-family languages }

constructor TGenericSyntaxHighlighter.Create(const ALanguageName: string;
  const AKeywords, ATypes: TArray<string>; ASupportsPreprocessor: Boolean);
var
  K: string;
begin
  inherited Create;
  FLanguageName := ALanguageName;
  FSupportsPreprocessor := ASupportsPreprocessor;
  FKeywords := THashSet<string>.Create;
  FTypes := THashSet<string>.Create;
  for K in AKeywords do
    FKeywords.Add(LowerCase(K));
  for K in ATypes do
    FTypes.Add(LowerCase(K));
end;

destructor TGenericSyntaxHighlighter.Destroy;
begin
  FKeywords.Free;
  FTypes.Free;
  inherited Destroy;
end;

function TGenericSyntaxHighlighter.GetLanguageName: string;
begin
  Result := FLanguageName;
end;

function TGenericSyntaxHighlighter.Highlight(const AText: string): TArray<TSourceToken>;
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
    Result := CharInSet(C, ['a'..'z', 'A'..'Z', '_', '0'..'9', '$']) or (Ord(C) > 127);
  end;

  function IsIdentStart(C: Char): Boolean;
  begin
    Result := CharInSet(C, ['a'..'z', 'A'..'Z', '_', '$']) or (Ord(C) > 127);
  end;

  function IsHexDigit(C: Char): Boolean;
  begin
    Result := CharInSet(C, ['0'..'9', 'a'..'f', 'A'..'F']);
  end;

  procedure ConsumeBlockComment;
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
  end;

  procedure ConsumeLineComment;
  begin
    I := I + 2;
    while (I <= N) and not CharInSet(AText[I], [#13, #10]) do
      Inc(I);
    AddToken(stComment, I - StartPos);
  end;

  procedure ConsumeString(Delim: Char);
  begin
    Inc(I);
    while I <= N do
    begin
      if AText[I] = '\' then
      begin
        Inc(I);
        if I <= N then Inc(I);
      end
      else if AText[I] = Delim then
      begin
        Inc(I);
        Break;
      end
      else if CharInSet(AText[I], [#13, #10]) then
        Break
      else
        Inc(I);
    end;
    AddToken(stString, I - StartPos);
  end;

  procedure ConsumeBacktickString;
  begin
    Inc(I);
    while I <= N do
    begin
      if AText[I] = '\' then
      begin
        Inc(I);
        if I <= N then Inc(I);
      end
      else if AText[I] = '`' then
      begin
        Inc(I);
        Break;
      end
      else
        Inc(I);
    end;
    AddToken(stString, I - StartPos);
  end;

  function IsLineStart: Boolean;
  var
    J: Integer;
  begin
    if StartPos = 1 then
      Exit(True);
    J := StartPos - 1;
    while (J >= 1) and CharInSet(AText[J], [' ', #9]) do
      Dec(J);
    Result := (J = 0) or CharInSet(AText[J], [#13, #10]);
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

      // 2. Preprocessor (#if, #include, etc.)
      if FSupportsPreprocessor and (AText[I] = '#') and IsLineStart then
      begin
        I := I + 1;
        while (I <= N) and not CharInSet(AText[I], [#13, #10]) do
          Inc(I);
        AddToken(stPreprocessor, I - StartPos);
        Continue;
      end;

      // 3. Block Comment (/* */) - must check before /
      if (I + 1 <= N) and (AText[I] = '/') and (AText[I+1] = '*') then
      begin
        ConsumeBlockComment;
        Continue;
      end;

      // 4. Line Comment (//)
      if (I + 1 <= N) and (AText[I] = '/') and (AText[I+1] = '/') then
      begin
        ConsumeLineComment;
        Continue;
      end;

      // 5. Double-quoted string
      if AText[I] = '"' then
      begin
        ConsumeString('"');
        Continue;
      end;

      // 6. Single-quoted string / char literal
      if AText[I] = '''' then
      begin
        ConsumeString('''');
        Continue;
      end;

      // 7. Backtick template literal (JS/TS)
      if AText[I] = '`' then
      begin
        ConsumeBacktickString;
        Continue;
      end;

      // 8. Hex number: 0x7FFF
      if (AText[I] = '0') and (I + 1 <= N) and CharInSet(AText[I+1], ['x', 'X']) then
      begin
        I := I + 2;
        while (I <= N) and IsHexDigit(AText[I]) do
          Inc(I);
        AddToken(stNumber, I - StartPos);
        Continue;
      end;

      // 9. Binary number: 0b1010
      if (AText[I] = '0') and (I + 1 <= N) and CharInSet(AText[I+1], ['b', 'B']) then
      begin
        I := I + 2;
        while (I <= N) and CharInSet(AText[I], ['0', '1']) do
          Inc(I);
        AddToken(stNumber, I - StartPos);
        Continue;
      end;

      // 10. Octal number: 0o77
      if (AText[I] = '0') and (I + 1 <= N) and CharInSet(AText[I+1], ['o', 'O']) then
      begin
        I := I + 2;
        while (I <= N) and CharInSet(AText[I], ['0'..'7']) do
          Inc(I);
        AddToken(stNumber, I - StartPos);
        Continue;
      end;

      // 11. Decimal / Float
      if CharInSet(AText[I], ['0'..'9']) then
      begin
        while (I <= N) and CharInSet(AText[I], ['0'..'9']) do
          Inc(I);
        // Float: 3.14
        if (I + 1 <= N) and (AText[I] = '.') and CharInSet(AText[I+1], ['0'..'9']) then
        begin
          I := I + 2;
          while (I <= N) and CharInSet(AText[I], ['0'..'9']) do
            Inc(I);
        end;
        // Exponent: 1e10 or 1.5e-3
        if (I <= N) and CharInSet(AText[I], ['e', 'E']) then
        begin
          Inc(I);
          if (I <= N) and CharInSet(AText[I], ['+', '-']) then
            Inc(I);
          while (I <= N) and CharInSet(AText[I], ['0'..'9']) do
            Inc(I);
        end;
        // Type suffix: 42L, 3.14f, 100UL
        if (I <= N) and CharInSet(AText[I], ['l', 'L', 'f', 'F', 'd', 'D', 'u', 'U']) then
        begin
          Inc(I);
          if (I <= N) and CharInSet(AText[I], ['l', 'L']) then
            Inc(I);
        end;
        AddToken(stNumber, I - StartPos);
        Continue;
      end;

      // 12. Identifiers / Keywords / Types
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

      // 13. Multi-char operators and symbols
      if CharInSet(AText[I], ['+', '-', '*', '/', '%', '&', '|', '^', '~', '!',
        '=', '<', '>', '.', ',', ':', ';', '?', '(', ')', '[', ']', '{', '}', '@',
        '#', '$']) then
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

{ TPythonSyntaxHighlighter }

constructor TPythonSyntaxHighlighter.Create;
begin
  inherited Create;
  FKeywords := THashSet<string>.Create;
  FTypes := THashSet<string>.Create;
  InitializeKeywordsAndTypes;
end;

destructor TPythonSyntaxHighlighter.Destroy;
begin
  FKeywords.Free;
  FTypes.Free;
  inherited Destroy;
end;

function TPythonSyntaxHighlighter.GetLanguageName: string;
begin
  Result := 'Python';
end;

procedure TPythonSyntaxHighlighter.InitializeKeywordsAndTypes;
const
  Keywords: array[0..34] of string = (
    'False', 'None', 'True', 'and', 'as', 'assert', 'async', 'await', 'break',
    'class', 'continue', 'def', 'del', 'elif', 'else', 'except', 'finally', 'for',
    'from', 'global', 'if', 'import', 'in', 'is', 'lambda', 'nonlocal', 'not',
    'or', 'pass', 'raise', 'return', 'try', 'while', 'with', 'yield'
  );
  Types: array[0..50] of string = (
    'int', 'float', 'complex', 'bool', 'str', 'bytes', 'bytearray', 'memoryview',
    'list', 'tuple', 'range', 'dict', 'set', 'frozenset', 'type', 'object',
    'Exception', 'ValueError', 'TypeError', 'KeyError', 'IndexError',
    'AttributeError', 'RuntimeError', 'StopIteration', 'NotImplementedError',
    'OSError', 'IOError', 'FileNotFoundError', 'PermissionError',
    'ZeroDivisionError', 'ImportError', 'NameError', 'UnboundLocalError',
    'RecursionError', 'IsADirectoryError', 'NotADirectoryError',
    'ConnectionError', 'TimeoutError', 'BrokenPipeError', 'ConnectionResetError',
    'BaseException', 'GeneratorExit', 'KeyboardInterrupt', 'SystemExit',
    'SyntaxError', 'IndentationError', 'TabError', 'UnicodeError',
    'UnicodeDecodeError', 'UnicodeEncodeError', 'UnicodeTranslateError'
  );
var
  K: string;
begin
  for K in Keywords do
    FKeywords.Add(K);
  for K in Types do
    FTypes.Add(K);
end;

function TPythonSyntaxHighlighter.Highlight(const AText: string): TArray<TSourceToken>;
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
    Result := FKeywords.Contains(S);
  end;

  function IsType(const S: string): Boolean;
  begin
    Result := FTypes.Contains(S);
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

      // 2. Hash comment
      if AText[I] = '#' then
      begin
        Inc(I);
        while (I <= N) and not CharInSet(AText[I], [#13, #10]) do
          Inc(I);
        AddToken(stComment, I - StartPos);
        Continue;
      end;

      // 3. Triple-quoted string (""" """ or ''' ''')
      if (I + 2 <= N) then
      begin
        if (AText[I] = '"') and (AText[I+1] = '"') and (AText[I+2] = '"') then
        begin
          I := I + 3;
          while I <= N do
          begin
            if (I + 2 <= N) and (AText[I] = '"') and (AText[I+1] = '"') and (AText[I+2] = '"') then
            begin
              I := I + 3;
              Break;
            end;
            Inc(I);
          end;
          AddToken(stString, I - StartPos);
          Continue;
        end;
        if (AText[I] = '''') and (AText[I+1] = '''') and (AText[I+2] = '''') then
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
      end;

      // 4. Double-quoted string
      if AText[I] = '"' then
      begin
        Inc(I);
        while I <= N do
        begin
          if AText[I] = '\' then
          begin
            Inc(I);
            if I <= N then Inc(I);
          end
          else if AText[I] = '"' then
          begin
            Inc(I);
            Break;
          end
          else if CharInSet(AText[I], [#13, #10]) then
            Break
          else
            Inc(I);
        end;
        AddToken(stString, I - StartPos);
        Continue;
      end;

      // 5. Single-quoted string
      if AText[I] = '''' then
      begin
        Inc(I);
        while I <= N do
        begin
          if AText[I] = '\' then
          begin
            Inc(I);
            if I <= N then Inc(I);
          end
          else if AText[I] = '''' then
          begin
            Inc(I);
            Break;
          end
          else if CharInSet(AText[I], [#13, #10]) then
            Break
          else
            Inc(I);
        end;
        AddToken(stString, I - StartPos);
        Continue;
      end;

      // 6. Numbers
      // Hex: 0xFF
      if (AText[I] = '0') and (I + 1 <= N) and CharInSet(AText[I+1], ['x', 'X']) then
      begin
        I := I + 2;
        while (I <= N) and CharInSet(AText[I], ['0'..'9', 'a'..'f', 'A'..'F']) do
          Inc(I);
        AddToken(stNumber, I - StartPos);
        Continue;
      end;
      // Binary: 0b1010
      if (AText[I] = '0') and (I + 1 <= N) and CharInSet(AText[I+1], ['b', 'B']) then
      begin
        I := I + 2;
        while (I <= N) and CharInSet(AText[I], ['0', '1']) do
          Inc(I);
        AddToken(stNumber, I - StartPos);
        Continue;
      end;
      // Octal: 0o77
      if (AText[I] = '0') and (I + 1 <= N) and CharInSet(AText[I+1], ['o', 'O']) then
      begin
        I := I + 2;
        while (I <= N) and CharInSet(AText[I], ['0'..'7']) do
          Inc(I);
        AddToken(stNumber, I - StartPos);
        Continue;
      end;
      // Decimal / Float
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

      // 7. Identifiers / Keywords / Types
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

      // 8. Symbols / Operators
      if CharInSet(AText[I], ['+', '-', '*', '/', '%', '=', '<', '>', '!',
        '&', '|', '^', '~', '.', ',', ':', ';', '?', '@', '(', ')', '[', ']',
        '{', '}']) then
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

{ TRubySyntaxHighlighter }

constructor TRubySyntaxHighlighter.Create;
begin
  inherited Create;
  FKeywords := THashSet<string>.Create;
  InitializeKeywords;
end;

destructor TRubySyntaxHighlighter.Destroy;
begin
  FKeywords.Free;
  inherited Destroy;
end;

function TRubySyntaxHighlighter.GetLanguageName: string;
begin
  Result := 'Ruby';
end;

procedure TRubySyntaxHighlighter.InitializeKeywords;
const
  Keywords: array[0..53] of string = (
    'BEGIN', 'END', 'alias', 'and', 'begin', 'break', 'case', 'class', 'def',
    'defined?', 'do', 'else', 'elsif', 'end', 'ensure', 'false', 'for', 'if',
    'in', 'module', 'next', 'nil', 'not', 'or', 'redo', 'rescue', 'retry',
    'return', 'self', 'super', 'then', 'true', 'undef', 'unless', 'until',
    'when', 'while', 'yield', 'require', 'include', 'extend', 'prepend',
    'private', 'protected', 'public', 'attr_accessor', 'attr_reader',
    'attr_writer', 'raise', 'proc', 'lambda', 'loop', 'catch', 'throw'
  );
var
  K: string;
begin
  for K in Keywords do
    FKeywords.Add(K);
end;

function TRubySyntaxHighlighter.Highlight(const AText: string): TArray<TSourceToken>;
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
    Result := FKeywords.Contains(S);
  end;

  function IsIdentChar(C: Char): Boolean;
  begin
    Result := CharInSet(C, ['a'..'z', 'A'..'Z', '_', '0'..'9', '@', '$']) or (Ord(C) > 127);
  end;

  function IsIdentStart(C: Char): Boolean;
  begin
    Result := CharInSet(C, ['a'..'z', 'A'..'Z', '_', '@', '$']) or (Ord(C) > 127);
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

      // 2. Hash comment
      if AText[I] = '#' then
      begin
        Inc(I);
        while (I <= N) and not CharInSet(AText[I], [#13, #10]) do
          Inc(I);
        AddToken(stComment, I - StartPos);
        Continue;
      end;

      // 3. =begin..=end block comment
      if (I + 5 <= N) and (Copy(AText, I, 6) = '=begin') then
      begin
        I := I + 6;
        while I <= N do
        begin
          if (I + 3 <= N) and (Copy(AText, I, 4) = '=end') then
          begin
            I := I + 4;
            Break;
          end;
          Inc(I);
        end;
        AddToken(stComment, I - StartPos);
        Continue;
      end;

      // 4. Double-quoted string (#{...} interpolation)
      if AText[I] = '"' then
      begin
        Inc(I);
        while I <= N do
        begin
          if AText[I] = '\' then
          begin
            Inc(I);
            if I <= N then Inc(I);
          end
          else if AText[I] = '"' then
          begin
            Inc(I);
            Break;
          end
          else if CharInSet(AText[I], [#13, #10]) then
            Break
          else
            Inc(I);
        end;
        AddToken(stString, I - StartPos);
        Continue;
      end;

      // 5. Single-quoted string
      if AText[I] = '''' then
      begin
        Inc(I);
        while I <= N do
        begin
          if AText[I] = '\' then
          begin
            Inc(I);
            if I <= N then Inc(I);
          end
          else if AText[I] = '''' then
          begin
            Inc(I);
            Break;
          end
          else if CharInSet(AText[I], [#13, #10]) then
            Break
          else
            Inc(I);
        end;
        AddToken(stString, I - StartPos);
        Continue;
      end;

      // 6. Symbol (:symbol)
      if AText[I] = ':' then
      begin
        if (I + 1 <= N) and IsIdentStart(AText[I+1]) then
        begin
          Inc(I);
          while (I <= N) and IsIdentChar(AText[I]) do
            Inc(I);
          AddToken(stSymbol, I - StartPos);
          Continue;
        end;
        Inc(I);
        AddToken(stSymbol, I - StartPos);
        Continue;
      end;

      // 7. Global / instance / class variables
      if CharInSet(AText[I], ['@', '$']) then
      begin
        Inc(I);
        while (I <= N) and IsIdentChar(AText[I]) do
          Inc(I);
        AddToken(stPlain, I - StartPos);
        Continue;
      end;

      // 8. Numbers
      if (AText[I] = '0') and (I + 1 <= N) and CharInSet(AText[I+1], ['x', 'X']) then
      begin
        I := I + 2;
        while (I <= N) and CharInSet(AText[I], ['0'..'9', 'a'..'f', 'A'..'F']) do
          Inc(I);
        AddToken(stNumber, I - StartPos);
        Continue;
      end;
      if (AText[I] = '0') and (I + 1 <= N) and CharInSet(AText[I+1], ['b', 'B']) then
      begin
        I := I + 2;
        while (I <= N) and CharInSet(AText[I], ['0', '1']) do
          Inc(I);
        AddToken(stNumber, I - StartPos);
        Continue;
      end;
      if (AText[I] = '0') and (I + 1 <= N) and CharInSet(AText[I+1], ['o', 'O']) then
      begin
        I := I + 2;
        while (I <= N) and CharInSet(AText[I], ['0'..'7']) do
          Inc(I);
        AddToken(stNumber, I - StartPos);
        Continue;
      end;
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

      // 9. Identifiers / Keywords
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

      // 10. Symbols / Operators
      if CharInSet(AText[I], ['+', '-', '*', '/', '%', '=', '<', '>', '!',
        '&', '|', '^', '~', '.', ',', ':', ';', '?', '(', ')', '[', ']',
        '{', '}']) then
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

{ TMarkupSyntaxHighlighter - HTML/XML }

constructor TMarkupSyntaxHighlighter.Create(const ALanguageName: string);
begin
  inherited Create;
  FLanguageName := ALanguageName;
end;

function TMarkupSyntaxHighlighter.GetLanguageName: string;
begin
  Result := FLanguageName;
end;

function TMarkupSyntaxHighlighter.Highlight(const AText: string): TArray<TSourceToken>;
var
  Tokens: TList<TSourceToken>;
  I, N: Integer;
  StartPos: Integer;
  QuoteChar: Char;

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

  function IsIdentChar(C: Char): Boolean;
  begin
    Result := CharInSet(C, ['a'..'z', 'A'..'Z', '_', '0'..'9', '-', '.', ':']) or (Ord(C) > 127);
  end;

  function IsIdentStart(C: Char): Boolean;
  begin
    Result := CharInSet(C, ['a'..'z', 'A'..'Z', '_', ':']) or (Ord(C) > 127);
  end;

begin
  Tokens := TList<TSourceToken>.Create;
  try
    I := 1;
    N := Length(AText);
    while I <= N do
    begin
      StartPos := I;

      // 1. Comment <!-- -->
      if (I + 3 <= N) and (AText[I] = '<') and (AText[I+1] = '!') and
        (AText[I+2] = '-') and (AText[I+3] = '-') then
      begin
        I := I + 4;
        while I <= N do
        begin
          if (I + 2 <= N) and (AText[I] = '-') and (AText[I+1] = '-') and (AText[I+2] = '>') then
          begin
            I := I + 3;
            Break;
          end;
          Inc(I);
        end;
        AddToken(stComment, I - StartPos);
        Continue;
      end;

      // 2. CDATA section <![CDATA[ ]]>
      if (I + 8 <= N) and (Copy(AText, I, 9) = '<![CDATA[') then
      begin
        I := I + 9;
        while I <= N do
        begin
          if (I + 2 <= N) and (AText[I] = ']') and (AText[I+1] = ']') and (AText[I+2] = '>') then
          begin
            I := I + 3;
            Break;
          end;
          Inc(I);
        end;
        AddToken(stString, I - StartPos);
        Continue;
      end;

      // 3. Processing instruction <?xml ... ?>
      if (I + 1 <= N) and (AText[I] = '<') and (AText[I+1] = '?') then
      begin
        I := I + 2;
        while I <= N do
        begin
          if (I + 1 <= N) and (AText[I] = '?') and (AText[I+1] = '>') then
          begin
            I := I + 2;
            Break;
          end;
          Inc(I);
        end;
        AddToken(stPreprocessor, I - StartPos);
        Continue;
      end;

      // 4. DOCTYPE
      if (I + 8 <= N) and (Copy(AText, I, 9) = '<!DOCTYPE') then
      begin
        while (I <= N) and (AText[I] <> '>') do
          Inc(I);
        if I <= N then Inc(I);
        AddToken(stPreprocessor, I - StartPos);
        Continue;
      end;

      // 5. Tag: opening <div>, closing </div>, self-closing <br/>
      if AText[I] = '<' then
      begin
        Inc(I);
        // Closing tag </...>
        if (I <= N) and (AText[I] = '/') then
        begin
          Inc(I);
          while (I <= N) and (AText[I] <> '>') do
            Inc(I);
          if I <= N then Inc(I);
          AddToken(stKeyword, I - StartPos);
          Continue;
        end;

        // Tag name
        if (I <= N) and IsIdentStart(AText[I]) then
        begin
          while (I <= N) and IsIdentChar(AText[I]) do
            Inc(I);

          // Skip attributes - look for = and quoted values
          while I <= N do
          begin
            // Skip whitespace
            while (I <= N) and CharInSet(AText[I], [' ', #9, #13, #10]) do
              Inc(I);
            if I > N then Break;

            // End of tag
            if AText[I] = '>' then
            begin
              Inc(I);
              Break;
            end;
            if (I + 1 <= N) and (AText[I] = '/') and (AText[I+1] = '>') then
            begin
              I := I + 2;
              Break;
            end;

            // Quoted attribute value
            if CharInSet(AText[I], ['"', '''']) then
            begin
              QuoteChar := AText[I];
              Inc(I);
              while (I <= N) and (AText[I] <> QuoteChar) do
              begin
                if AText[I] = '>' then Break;
                Inc(I);
              end;
              if (I <= N) and (AText[I] = QuoteChar) then Inc(I);
              Continue;
            end;

            Inc(I);
          end;
          AddToken(stKeyword, I - StartPos);
          Continue;
        end;

        // Fallback for malformed
        while (I <= N) and (AText[I] <> '>') do
          Inc(I);
        if I <= N then Inc(I);
        AddToken(stPlain, I - StartPos);
        Continue;
      end;

      // 6. Entity references &amp; &lt; &#8364;
      if AText[I] = '&' then
      begin
        Inc(I);
        if (I <= N) and (AText[I] = '#') then
        begin
          Inc(I);
          while (I <= N) and CharInSet(AText[I], ['0'..'9']) do
            Inc(I);
        end
        else
        begin
          while (I <= N) and IsIdentChar(AText[I]) do
            Inc(I);
        end;
        if (I <= N) and (AText[I] = ';') then
          Inc(I);
        AddToken(stSymbol, I - StartPos);
        Continue;
      end;

      // 7. Plain text (up to next < or &)
      while (I <= N) and not CharInSet(AText[I], ['<', '&']) do
        Inc(I);
      if I > StartPos then
        AddToken(stPlain, I - StartPos)
      else
      begin
        Inc(I);
        AddToken(stPlain, 1);
      end;
    end;
    Result := Tokens.ToArray;
  finally
    Tokens.Free;
  end;
end;

{ TCSSSyntaxHighlighter }

constructor TCSSSyntaxHighlighter.Create;
begin
  inherited Create;
  FProperties := THashSet<string>.Create;
  InitializeProperties;
end;

destructor TCSSSyntaxHighlighter.Destroy;
begin
  FProperties.Free;
  inherited Destroy;
end;

function TCSSSyntaxHighlighter.GetLanguageName: string;
begin
  Result := 'CSS';
end;

procedure TCSSSyntaxHighlighter.InitializeProperties;
const
  Props: array[0..70] of string = (
    'color', 'background', 'background-color', 'background-image', 'background-size',
    'background-position', 'background-repeat', 'font', 'font-size', 'font-weight',
    'font-family', 'font-style', 'text-align', 'text-decoration', 'text-transform',
    'text-shadow', 'margin', 'margin-top', 'margin-right', 'margin-bottom',
    'margin-left', 'padding', 'padding-top', 'padding-right', 'padding-bottom',
    'padding-left', 'border', 'border-color', 'border-style', 'border-width',
    'border-radius', 'border-top', 'border-right', 'border-bottom', 'border-left',
    'width', 'height', 'max-width', 'min-width', 'max-height', 'min-height',
    'display', 'position', 'top', 'right', 'bottom', 'left', 'float', 'clear',
    'overflow', 'opacity', 'z-index', 'flex', 'grid', 'flex-direction',
    'justify-content', 'align-items', 'gap', 'transition', 'transform',
    'animation', 'box-shadow', 'cursor', 'outline', 'visibility', 'white-space',
    'line-height', 'vertical-align', 'content', 'filter', 'pointer-events'
  );
var
  S: string;
begin
  for S in Props do
    FProperties.Add(S);
end;

function TCSSSyntaxHighlighter.Highlight(const AText: string): TArray<TSourceToken>;
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

  function IsIdentChar(C: Char): Boolean;
  begin
    Result := CharInSet(C, ['a'..'z', 'A'..'Z', '_', '0'..'9', '-', '.', '#', '@']) or (Ord(C) > 127);
  end;

  function IsIdentStart(C: Char): Boolean;
  begin
    Result := CharInSet(C, ['a'..'z', 'A'..'Z', '_', '-', '.', '#', '@']) or (Ord(C) > 127);
  end;

  function IsProperty(const S: string): Boolean;
  begin
    Result := FProperties.Contains(LowerCase(S));
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

      // 2. Block Comment /* */
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

      // 3. Double-quoted string
      if AText[I] = '"' then
      begin
        Inc(I);
        while (I <= N) and (AText[I] <> '"') do
        begin
          if AText[I] = '\' then
          begin
            Inc(I);
            if I <= N then Inc(I);
          end
          else
            Inc(I);
        end;
        if I <= N then Inc(I);
        AddToken(stString, I - StartPos);
        Continue;
      end;

      // 4. Single-quoted string
      if AText[I] = '''' then
      begin
        Inc(I);
        while (I <= N) and (AText[I] <> '''') do
        begin
          if AText[I] = '\' then
          begin
            Inc(I);
            if I <= N then Inc(I);
          end
          else
            Inc(I);
        end;
        if I <= N then Inc(I);
        AddToken(stString, I - StartPos);
        Continue;
      end;

      // 5. URL function
      if (I + 3 <= N) and (Copy(AText, I, 4) = 'url(') then
      begin
        I := I + 4;
        while (I <= N) and (AText[I] <> ')') do
          Inc(I);
        if I <= N then Inc(I);
        AddToken(stString, I - StartPos);
        Continue;
      end;

      // 6. Numbers with optional units
      if CharInSet(AText[I], ['0'..'9']) then
      begin
        while (I <= N) and CharInSet(AText[I], ['0'..'9']) do
          Inc(I);
        if (I <= N) and (AText[I] = '.') then
        begin
          Inc(I);
          while (I <= N) and CharInSet(AText[I], ['0'..'9']) do
            Inc(I);
        end;
        // CSS units: px, em, rem, %, vh, vw, s, ms, deg, etc.
        while (I <= N) and CharInSet(AText[I], ['a'..'z', 'A'..'Z', '%']) do
          Inc(I);
        AddToken(stNumber, I - StartPos);
        Continue;
      end;

      // 7. Hash color #fff or #f0f0f0
      if AText[I] = '#' then
      begin
        Inc(I);
        while (I <= N) and CharInSet(AText[I], ['0'..'9', 'a'..'f', 'A'..'F']) do
          Inc(I);
        AddToken(stNumber, I - StartPos);
        Continue;
      end;

      // 8. CSS variables --var-name
      if (I + 1 <= N) and (AText[I] = '-') and (AText[I+1] = '-') then
      begin
        I := I + 2;
        while (I <= N) and IsIdentChar(AText[I]) do
          Inc(I);
        AddToken(stType, I - StartPos);
        Continue;
      end;

      // 9. Identifiers (properties, selectors, values)
      if IsIdentStart(AText[I]) then
      begin
        while (I <= N) and IsIdentChar(AText[I]) do
          Inc(I);

        if IsProperty(Copy(AText, StartPos, I - StartPos)) then
          AddToken(stKeyword, I - StartPos)
        else
          AddToken(stPlain, I - StartPos);
        Continue;
      end;

      // 10. Symbols
      if CharInSet(AText[I], ['{', '}', '(', ')', '[', ']', ':', ';', ',', '.',
        '>', '+', '~', '*', '@']) then
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

{ TJSONSyntaxHighlighter }

function TJSONSyntaxHighlighter.GetLanguageName: string;
begin
  Result := 'JSON';
end;

function TJSONSyntaxHighlighter.Highlight(const AText: string): TArray<TSourceToken>;
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

  function IsIdentChar(C: Char): Boolean;
  begin
    Result := CharInSet(C, ['a'..'z', 'A'..'Z', '_', '0'..'9', '$']) or (Ord(C) > 127);
  end;

  function IsIdentStart(C: Char): Boolean;
  begin
    Result := CharInSet(C, ['a'..'z', 'A'..'Z', '_', '$']) or (Ord(C) > 127);
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

      // 2. Double-quoted string
      if AText[I] = '"' then
      begin
        Inc(I);
        while I <= N do
        begin
          if AText[I] = '\' then
          begin
            Inc(I);
            if I <= N then Inc(I);
          end
          else if AText[I] = '"' then
          begin
            Inc(I);
            Break;
          end
          else if CharInSet(AText[I], [#13, #10]) then
            Break
          else
            Inc(I);
        end;
        AddToken(stString, I - StartPos);
        Continue;
      end;

      // 3. Numbers
      if (AText[I] = '-') and (I + 1 <= N) and CharInSet(AText[I+1], ['0'..'9']) then
      begin
        Inc(I);
        while (I <= N) and CharInSet(AText[I], ['0'..'9']) do
          Inc(I);
        if (I + 1 <= N) and (AText[I] = '.') and CharInSet(AText[I+1], ['0'..'9']) then
        begin
          I := I + 2;
          while (I <= N) and CharInSet(AText[I], ['0'..'9']) do
            Inc(I);
        end;
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

      // 4. Literals: true, false, null
      if IsIdentStart(AText[I]) then
      begin
        while (I <= N) and IsIdentChar(AText[I]) do
          Inc(I);

        if SameText(Copy(AText, StartPos, I - StartPos), 'true') or
           SameText(Copy(AText, StartPos, I - StartPos), 'false') or
           SameText(Copy(AText, StartPos, I - StartPos), 'null') then
          AddToken(stKeyword, I - StartPos)
        else
          AddToken(stPlain, I - StartPos);
        Continue;
      end;

      // 5. Symbols
      if CharInSet(AText[I], ['{', '}', '[', ']', ':', ',']) then
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

{ TYAMLSyntaxHighlighter }

function TYAMLSyntaxHighlighter.GetLanguageName: string;
begin
  Result := 'YAML';
end;

function TYAMLSyntaxHighlighter.Highlight(const AText: string): TArray<TSourceToken>;
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

  function IsIdentChar(C: Char): Boolean;
  begin
    Result := CharInSet(C, ['a'..'z', 'A'..'Z', '_', '0'..'9', '-']) or (Ord(C) > 127);
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

      // 2. Hash comment
      if AText[I] = '#' then
      begin
        Inc(I);
        while (I <= N) and not CharInSet(AText[I], [#13, #10]) do
          Inc(I);
        AddToken(stComment, I - StartPos);
        Continue;
      end;

      // 3. Double-quoted string
      if AText[I] = '"' then
      begin
        Inc(I);
        while I <= N do
        begin
          if AText[I] = '\' then
          begin
            Inc(I);
            if I <= N then Inc(I);
          end
          else if AText[I] = '"' then
          begin
            Inc(I);
            Break;
          end
          else if CharInSet(AText[I], [#13, #10]) then
            Break
          else
            Inc(I);
        end;
        AddToken(stString, I - StartPos);
        Continue;
      end;

      // 4. Single-quoted string
      if AText[I] = '''' then
      begin
        Inc(I);
        while I <= N do
        begin
          if (I + 1 <= N) and (AText[I] = '''') and (AText[I+1] = '''') then
          begin
            I := I + 2;
          end
          else if AText[I] = '''' then
          begin
            Inc(I);
            Break;
          end
          else if CharInSet(AText[I], [#13, #10]) then
            Break
          else
            Inc(I);
        end;
        AddToken(stString, I - StartPos);
        Continue;
      end;

      // 5. Flow style braces
      if CharInSet(AText[I], ['{', '}', '[', ']', ',']) then
      begin
        Inc(I);
        AddToken(stSymbol, I - StartPos);
        Continue;
      end;

      // 6. Numbers
      if CharInSet(AText[I], ['0'..'9']) or
        ((AText[I] = '-') and (I + 1 <= N) and CharInSet(AText[I+1], ['0'..'9'])) then
      begin
        if AText[I] = '-' then Inc(I);
        while (I <= N) and CharInSet(AText[I], ['0'..'9']) do
          Inc(I);
        if (I + 1 <= N) and (AText[I] = '.') and CharInSet(AText[I+1], ['0'..'9']) then
        begin
          I := I + 2;
          while (I <= N) and CharInSet(AText[I], ['0'..'9']) do
            Inc(I);
        end;
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

      // 7. YAML list indicator - or blocking scalars (|, >)
      if (AText[I] = '-') then
      begin
        Inc(I);
        AddToken(stSymbol, I - StartPos);
        Continue;
      end;

      // 8. Key-value colon (but not for time values 12:00)
      if (AText[I] = ':') then
      begin
        Inc(I);
        AddToken(stSymbol, I - StartPos);
        Continue;
      end;

      // 9. Anchor / Alias / Tag
      if CharInSet(AText[I], ['&', '*', '!']) then
      begin
        Inc(I);
        while (I <= N) and IsIdentChar(AText[I]) do
          Inc(I);
        AddToken(stType, I - StartPos);
        Continue;
      end;

      // 10. Bool / Null literals
      if IsIdentStart(AText[I]) then
      begin
        while (I <= N) and IsIdentChar(AText[I]) do
          Inc(I);

        if SameText(Copy(AText, StartPos, I - StartPos), 'true') or
           SameText(Copy(AText, StartPos, I - StartPos), 'false') or
           SameText(Copy(AText, StartPos, I - StartPos), 'yes') or
           SameText(Copy(AText, StartPos, I - StartPos), 'no') or
           SameText(Copy(AText, StartPos, I - StartPos), 'null') or
           SameText(Copy(AText, StartPos, I - StartPos), 'on') or
           SameText(Copy(AText, StartPos, I - StartPos), 'off') then
          AddToken(stKeyword, I - StartPos)
        else
          AddToken(stPlain, I - StartPos);
        Continue;
      end;

      // 11. Block scalar indicator
      if CharInSet(AText[I], ['|', '>']) then
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

{ TShellSyntaxHighlighter }

constructor TShellSyntaxHighlighter.Create;
begin
  inherited Create;
  FKeywords := THashSet<string>.Create;
  InitializeKeywords;
end;

destructor TShellSyntaxHighlighter.Destroy;
begin
  FKeywords.Free;
  inherited Destroy;
end;

function TShellSyntaxHighlighter.GetLanguageName: string;
begin
  Result := 'Shell';
end;

procedure TShellSyntaxHighlighter.InitializeKeywords;
const
  Keywords: array[0..60] of string = (
    'if', 'then', 'else', 'elif', 'fi', 'case', 'esac', 'for', 'while', 'until',
    'do', 'done', 'in', 'function', 'select', 'time', 'declare', 'typeset',
    'local', 'readonly', 'export', 'alias', 'unalias', 'unset', 'source', '.',
    'exit', 'return', 'trap', 'eval', 'exec', 'let', 'shift', 'break', 'continue',
    'echo', 'printf', 'read', 'cd', 'pwd', 'ls', 'mkdir', 'rmdir', 'rm', 'cp',
    'mv', 'cat', 'grep', 'sed', 'awk', 'test', 'true', 'false', 'set', 'shopt',
    'getopts', 'wait', 'jobs', 'fg', 'bg', 'kill'
  );
var
  K: string;
begin
  for K in Keywords do
    FKeywords.Add(K);
end;

function TShellSyntaxHighlighter.Highlight(const AText: string): TArray<TSourceToken>;
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
    Result := FKeywords.Contains(S);
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

      // 2. Hash comment (but not inside ${} or $())
      if AText[I] = '#' then
      begin
        Inc(I);
        while (I <= N) and not CharInSet(AText[I], [#13, #10]) do
          Inc(I);
        AddToken(stComment, I - StartPos);
        Continue;
      end;

      // 3. Double-quoted string
      if AText[I] = '"' then
      begin
        Inc(I);
        while I <= N do
        begin
          if AText[I] = '\' then
          begin
            Inc(I);
            if I <= N then Inc(I);
          end
          else if AText[I] = '"' then
          begin
            Inc(I);
            Break;
          end
          else if AText[I] = '`' then
          begin
            Inc(I);
            while (I <= N) and (AText[I] <> '`') do Inc(I);
            if I <= N then Inc(I);
          end
          else
            Inc(I);
        end;
        AddToken(stString, I - StartPos);
        Continue;
      end;

      // 4. Single-quoted string (literal)
      if AText[I] = '''' then
      begin
        Inc(I);
        while (I <= N) and (AText[I] <> '''') do
          Inc(I);
        if I <= N then Inc(I);
        AddToken(stString, I - StartPos);
        Continue;
      end;

      // 5. Variable reference $VAR ${VAR} $(cmd) $((expr))
      if AText[I] = '$' then
      begin
        Inc(I);
        if (I <= N) and (AText[I] = '{') then
        begin
          Inc(I);
          while (I <= N) and (AText[I] <> '}') do
            Inc(I);
          if I <= N then Inc(I);
        end
        else if (I <= N) and (AText[I] = '(') then
        begin
          Inc(I);
          if (I <= N) and (AText[I] = '(') then
          begin
            Inc(I);
            while (I <= N) and not ((AText[I] = ')') and (I + 1 <= N) and (AText[I+1] = ')')) do
              Inc(I);
            I := I + 2;
          end
          else
          begin
            while (I <= N) and (AText[I] <> ')') do
              Inc(I);
            if I <= N then Inc(I);
          end;
        end
        else
        begin
          // Simple variable
          while (I <= N) and IsIdentChar(AText[I]) do
            Inc(I);
          // Handle special vars: $?, $!, $#, $@, $*, $0..$9, $$
          if (I = StartPos + 1) and (I <= N) then
            Inc(I);
        end;
        AddToken(stType, I - StartPos);
        Continue;
      end;

      // 6. Numbers
      if CharInSet(AText[I], ['0'..'9']) then
      begin
        while (I <= N) and CharInSet(AText[I], ['0'..'9']) do
          Inc(I);
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

      // 8. Symbols / Operators
      if CharInSet(AText[I], ['+', '-', '*', '/', '%', '=', '<', '>', '!',
        '&', '|', '^', '~', '.', ',', ':', ';', '?', '(', ')', '[', ']',
        '{', '}', '@', '`']) then
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

{ TINISyntaxHighlighter }

function TINISyntaxHighlighter.GetLanguageName: string;
begin
  Result := 'INI';
end;

function TINISyntaxHighlighter.Highlight(const AText: string): TArray<TSourceToken>;
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

      // 2. Semicolon comment
      if AText[I] = ';' then
      begin
        Inc(I);
        while (I <= N) and not CharInSet(AText[I], [#13, #10]) do
          Inc(I);
        AddToken(stComment, I - StartPos);
        Continue;
      end;

      // 3. Hash comment
      if AText[I] = '#' then
      begin
        Inc(I);
        while (I <= N) and not CharInSet(AText[I], [#13, #10]) do
          Inc(I);
        AddToken(stComment, I - StartPos);
        Continue;
      end;

      // 4. Section header [SectionName]
      if AText[I] = '[' then
      begin
        Inc(I);
        while (I <= N) and (AText[I] <> ']') do
          Inc(I);
        if I <= N then Inc(I);
        AddToken(stKeyword, I - StartPos);
        Continue;
      end;

      // 5. Key=Value line - key name
      if CharInSet(AText[I], ['a'..'z', 'A'..'Z', '_', '0'..'9', '.', '-']) then
      begin
        // Scan for = sign
        while (I <= N) and (AText[I] <> '=') and not CharInSet(AText[I], [#13, #10]) do
          Inc(I);
        if (I <= N) and (AText[I] = '=') then
        begin
          // Key token
          if I > StartPos then
            AddToken(stType, I - StartPos);
          // = sign
          StartPos := I;
          Inc(I);
          AddToken(stSymbol, I - StartPos);
          Continue;
        end;

        // No = found, just a plain word
        AddToken(stPlain, I - StartPos);
        Continue;
      end;

      // 6. Quoted string values
      if CharInSet(AText[I], ['"', '''']) then
      begin
        Inc(I);
        while (I <= N) and (AText[I] <> AText[StartPos]) and not CharInSet(AText[I], [#13, #10]) do
          Inc(I);
        if I <= N then Inc(I);
        AddToken(stString, I - StartPos);
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
