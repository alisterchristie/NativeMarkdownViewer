unit IDEStringHighlighter;

interface

procedure Register;

implementation

uses
  System.Classes,
  System.Generics.Collections,
  System.Math,
  System.SysUtils,
  System.Types,
  Vcl.Controls,
  Vcl.Graphics,
  ToolsAPI,
  ToolsAPI.Editor,
  MarkdownViewer.Highlight;

type
  TStringPaintToken = record
    Line: Integer;
    StartCol: Integer;
    EndCol: Integer;
    Kind: TSourceTokenKind;
  end;

  TFileHighlightCache = class
  public
    Stamp: TDateTime;
    Tokens: TArray<TStringPaintToken>;
  end;

  TMultilineStringEditorNotifier = class(TNTACodeEditorNotifier)
  private
    FCache: TObjectDictionary<string, TFileHighlightCache>;
    FCodeEditorServices: INTACodeEditorServices280;
    FNotifierIndex: Integer;
    function CacheForContext(const Context: INTACodeEditorPaintContext): TFileHighlightCache;
    function ReadBufferText(const Buffer: IOTAEditBuffer): string;
    procedure DoPaintText(const Rect: TRect; const ColNum: SmallInt; const Text: string;
      const SyntaxCode: TOTASyntaxCode; const Hilight, BeforeEvent: Boolean;
      var AllowDefaultPainting: Boolean; const Context: INTACodeEditorPaintContext);
    procedure ParseAnnotatedStrings(const Source: string; const Tokens: TList<TStringPaintToken>);
    procedure AddHighlightedString(const Source: string; const LineStarts: TArray<Integer>;
      const Lang: string; ContentStart, ContentEnd: Integer; const Tokens: TList<TStringPaintToken>);
    function TokenColor(AKind: TSourceTokenKind): TColor;
    function TokenStyle(AKind: TSourceTokenKind): TFontStyles;
    function TokenSyntaxCode(AKind: TSourceTokenKind): TOTASyntaxCode;
  protected
    function AllowedEvents: TCodeEditorEvents; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure RegisterNotifier;
    procedure UnregisterNotifier;
  end;

var
  GNotifier: TMultilineStringEditorNotifier;

function BuildLineStarts(const Source: string): TArray<Integer>;
var
  I: Integer;
  Starts: TList<Integer>;
begin
  Starts := TList<Integer>.Create;
  try
    Starts.Add(1);
    for I := 1 to Length(Source) do
      if Source[I] = #10 then
        Starts.Add(I + 1);
    Result := Starts.ToArray;
  finally
    Starts.Free;
  end;
end;

function FindLineForOffset(const LineStarts: TArray<Integer>; Offset: Integer): Integer;
var
  L, H, M: Integer;
begin
  Result := 1;
  L := 0;
  H := High(LineStarts);
  while L <= H do
  begin
    M := (L + H) div 2;
    if LineStarts[M] <= Offset then
    begin
      Result := M + 1;
      L := M + 1;
    end
    else
      H := M - 1;
  end;
end;

function LineContentEndExclusive(const Source: string; const LineStarts: TArray<Integer>; Line: Integer): Integer;
begin
  if Line < Length(LineStarts) then
  begin
    Result := LineStarts[Line] - 1;
    if (Result > LineStarts[Line - 1]) and (Source[Result - 1] = #13) then
      Dec(Result);
  end
  else
    Result := Length(Source) + 1;
end;

function SamePascalSourceFile(const FileName: string): Boolean;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(FileName));
  Result := (Ext = '.pas') or (Ext = '.dpr') or (Ext = '.dpk') or (Ext = '.inc');
end;

function IsLanguageChar(C: Char): Boolean;
begin
  Result := CharInSet(C, ['a'..'z', 'A'..'Z', '0'..'9', '_', '+', '#', '-']);
end;

function TryExtractLanguage(const CommentText: string; out Lang: string): Boolean;
var
  I, Start: Integer;
  Candidate: string;
begin
  Result := False;
  Lang := '';
  I := 1;
  while I <= Length(CommentText) do
  begin
    while (I <= Length(CommentText)) and not IsLanguageChar(CommentText[I]) do
      Inc(I);
    Start := I;
    while (I <= Length(CommentText)) and IsLanguageChar(CommentText[I]) do
      Inc(I);

    if I > Start then
    begin
      Candidate := LowerCase(Copy(CommentText, Start, I - Start));
      if TMarkdownSyntaxHighlighterRegistry.GetHighlighter(Candidate) <> nil then
      begin
        Lang := Candidate;
        Exit(True);
      end;
    end;
  end;
end;

function IsTripleQuoteAt(const Source: string; Index: Integer): Boolean;
begin
  Result := (Index + 2 <= Length(Source)) and
    (Source[Index] = #39) and (Source[Index + 1] = #39) and (Source[Index + 2] = #39);
end;

{ TMultilineStringEditorNotifier }

constructor TMultilineStringEditorNotifier.Create;
begin
  inherited Create;
  FNotifierIndex := -1;
  FCache := TObjectDictionary<string, TFileHighlightCache>.Create([doOwnsValues]);
  Supports(BorlandIDEServices, INTACodeEditorServices280, FCodeEditorServices);
  OnEditorPaintText := DoPaintText;
end;

destructor TMultilineStringEditorNotifier.Destroy;
begin
  UnregisterNotifier;
  FCache.Free;
  inherited Destroy;
end;

function TMultilineStringEditorNotifier.AllowedEvents: TCodeEditorEvents;
begin
  Result := [cevPaintTextEvents];
end;

procedure TMultilineStringEditorNotifier.RegisterNotifier;
begin
  if (FNotifierIndex < 0) and (FCodeEditorServices <> nil) then
    FNotifierIndex := FCodeEditorServices.AddEditorEventsNotifier(Self);
end;

procedure TMultilineStringEditorNotifier.UnregisterNotifier;
begin
  if (FNotifierIndex >= 0) and (FCodeEditorServices <> nil) then
  begin
    FCodeEditorServices.RemoveEditorEventsNotifier(FNotifierIndex);
    FNotifierIndex := -1;
  end;
end;

function TMultilineStringEditorNotifier.ReadBufferText(const Buffer: IOTAEditBuffer): string;
const
  ChunkSize = 8192;
var
  Reader: IOTAEditReader;
  Bytes: TBytes;
  Memory: TMemoryStream;
  Position: Longint;
  ReadCount: Longint;
begin
  Result := '';
  if Buffer = nil then
    Exit;

  Reader := Buffer.CreateReader;
  if Reader = nil then
    Exit;

  Memory := TMemoryStream.Create;
  try
    SetLength(Bytes, ChunkSize);
    Position := 0;
    repeat
      ReadCount := Reader.GetText(Position, PAnsiChar(@Bytes[0]), ChunkSize);
      if ReadCount > 0 then
      begin
        Memory.WriteBuffer(Bytes[0], ReadCount);
        Inc(Position, ReadCount);
      end;
    until ReadCount < ChunkSize;

    SetLength(Bytes, Memory.Size);
    if Length(Bytes) > 0 then
    begin
      Memory.Position := 0;
      Memory.ReadBuffer(Bytes[0], Length(Bytes));
      Result := TEncoding.UTF8.GetString(Bytes);
      while (Result <> '') and (Result[Length(Result)] = #0) do
        Delete(Result, Length(Result), 1);
    end;
  finally
    Memory.Free;
  end;
end;

function TMultilineStringEditorNotifier.CacheForContext(
  const Context: INTACodeEditorPaintContext): TFileHighlightCache;
var
  Buffer: IOTAEditBuffer;
  Key: string;
  Source: string;
  Stamp: TDateTime;
  TokenList: TList<TStringPaintToken>;
begin
  Result := nil;
  if (Context = nil) or not SamePascalSourceFile(Context.FileName) then
    Exit;

  Buffer := nil;
  if Context.EditView <> nil then
    Buffer := Context.EditView.Buffer;
  if Buffer = nil then
    Exit;

  Key := LowerCase(Context.FileName);
  Stamp := Buffer.GetCurrentDate;
  if FCache.TryGetValue(Key, Result) and (Result.Stamp = Stamp) then
    Exit;

  Source := ReadBufferText(Buffer);
  TokenList := TList<TStringPaintToken>.Create;
  try
    ParseAnnotatedStrings(Source, TokenList);
    if Result = nil then
    begin
      Result := TFileHighlightCache.Create;
      FCache.Add(Key, Result);
    end;
    Result.Stamp := Stamp;
    Result.Tokens := TokenList.ToArray;
  finally
    TokenList.Free;
  end;
end;

procedure TMultilineStringEditorNotifier.ParseAnnotatedStrings(const Source: string;
  const Tokens: TList<TStringPaintToken>);
var
  I, J: Integer;
  PendingLang: string;
  Lang: string;
  CommentText: string;
  LineStarts: TArray<Integer>;
begin
  PendingLang := '';
  LineStarts := BuildLineStarts(Source);
  I := 1;
  while I <= Length(Source) do
  begin
    if IsTripleQuoteAt(Source, I) then
    begin
      J := I + 3;
      while (J <= Length(Source)) and not IsTripleQuoteAt(Source, J) do
        Inc(J);
      if PendingLang <> '' then
        AddHighlightedString(Source, LineStarts, PendingLang, I + 3, J, Tokens);
      PendingLang := '';
      if J <= Length(Source) then
        I := J + 3
      else
        Break;
      Continue;
    end;

    if Source[I] = '{' then
    begin
      J := I + 1;
      while (J <= Length(Source)) and (Source[J] <> '}') do
        Inc(J);
      if J <= Length(Source) then
      begin
        CommentText := Copy(Source, I + 1, J - I - 1);
        if (CommentText <> '') and (CommentText[1] <> '$') and
          TryExtractLanguage(CommentText, Lang) then
          PendingLang := Lang;
        I := J + 1;
        Continue;
      end;
    end;

    if (I + 1 <= Length(Source)) and (Source[I] = '(') and (Source[I + 1] = '*') then
    begin
      J := I + 2;
      while (J + 1 <= Length(Source)) and not ((Source[J] = '*') and (Source[J + 1] = ')')) do
        Inc(J);
      if J + 1 <= Length(Source) then
      begin
        CommentText := Copy(Source, I + 2, J - I - 2);
        if TryExtractLanguage(CommentText, Lang) then
          PendingLang := Lang;
        I := J + 2;
        Continue;
      end;
    end;

    if (I + 1 <= Length(Source)) and (Source[I] = '/') and (Source[I + 1] = '/') then
    begin
      J := I + 2;
      while (J <= Length(Source)) and not CharInSet(Source[J], [#13, #10]) do
        Inc(J);
      CommentText := Copy(Source, I + 2, J - I - 2);
      if TryExtractLanguage(CommentText, Lang) then
        PendingLang := Lang;
      I := J;
      Continue;
    end;

    if Source[I] = #39 then
    begin
      PendingLang := '';
      Inc(I);
      while I <= Length(Source) do
      begin
        if Source[I] = #39 then
        begin
          Inc(I);
          if (I <= Length(Source)) and (Source[I] = #39) then
            Inc(I)
          else
            Break;
        end
        else
          Inc(I);
      end;
      Continue;
    end;

    if Source[I] = ';' then
      PendingLang := '';
    Inc(I);
  end;
end;

procedure TMultilineStringEditorNotifier.AddHighlightedString(const Source: string;
  const LineStarts: TArray<Integer>; const Lang: string; ContentStart, ContentEnd: Integer;
  const Tokens: TList<TStringPaintToken>);
var
  HL: IMarkdownSyntaxHighlighter;
  Content: string;
  SourceTokens: TArray<TSourceToken>;
  SourceToken: TSourceToken;
  AbsStart, AbsEnd: Integer;
  Line, LastLine: Integer;
  LineStart, LineEnd: Integer;
  SegStart, SegEnd: Integer;
  PaintToken: TStringPaintToken;
begin
  if ContentEnd <= ContentStart then
    Exit;

  HL := TMarkdownSyntaxHighlighterRegistry.GetHighlighter(Lang);
  if HL = nil then
    Exit;

  Content := Copy(Source, ContentStart, ContentEnd - ContentStart);
  SourceTokens := HL.Highlight(Content);
  for SourceToken in SourceTokens do
  begin
    if SourceToken.Text = '' then
      Continue;

    AbsStart := ContentStart + SourceToken.Offset;
    AbsEnd := AbsStart + Length(SourceToken.Text);
    Line := FindLineForOffset(LineStarts, AbsStart);
    LastLine := FindLineForOffset(LineStarts, Max(AbsStart, AbsEnd - 1));
    while Line <= LastLine do
    begin
      LineStart := LineStarts[Line - 1];
      LineEnd := LineContentEndExclusive(Source, LineStarts, Line);
      SegStart := Max(AbsStart, LineStart);
      SegEnd := Min(AbsEnd, LineEnd);
      if SegStart < SegEnd then
      begin
        PaintToken.Line := Line;
        PaintToken.StartCol := SegStart - LineStart + 1;
        PaintToken.EndCol := SegEnd - LineStart + 1;
        PaintToken.Kind := SourceToken.Kind;
        Tokens.Add(PaintToken);
      end;
      Inc(Line);
    end;
  end;
end;

function TMultilineStringEditorNotifier.TokenSyntaxCode(AKind: TSourceTokenKind): TOTASyntaxCode;
begin
  case AKind of
    stKeyword: Result := atReservedWord;
    stComment: Result := atComment;
    stString: Result := atString;
    stNumber: Result := atNumber;
    stPreprocessor: Result := atPreproc;
    stSymbol: Result := atSymbol;
  else
    Result := atIdentifier;
  end;
end;

function TMultilineStringEditorNotifier.TokenColor(AKind: TSourceTokenKind): TColor;
var
  Options: INTACodeEditorOptions;
begin
  Options := nil;
  if FCodeEditorServices <> nil then
    Options := FCodeEditorServices.GetCodeEditorOptions;
  if Options <> nil then
    Exit(Options.FontColor[TokenSyntaxCode(AKind)]);

  case AKind of
    stKeyword: Result := clBlue;
    stComment: Result := clGreen;
    stString: Result := clMaroon;
    stNumber: Result := clPurple;
    stType: Result := clTeal;
    stPreprocessor: Result := clGray;
    stSymbol: Result := clWindowText;
  else
    Result := clWindowText;
  end;
end;

function TMultilineStringEditorNotifier.TokenStyle(AKind: TSourceTokenKind): TFontStyles;
var
  Options: INTACodeEditorOptions;
begin
  Options := nil;
  if FCodeEditorServices <> nil then
    Options := FCodeEditorServices.GetCodeEditorOptions;
  if Options <> nil then
    Exit(Options.FontStyles[TokenSyntaxCode(AKind)]);
  Result := [];
end;

procedure TMultilineStringEditorNotifier.DoPaintText(const Rect: TRect; const ColNum: SmallInt;
  const Text: string; const SyntaxCode: TOTASyntaxCode; const Hilight, BeforeEvent: Boolean;
  var AllowDefaultPainting: Boolean; const Context: INTACodeEditorPaintContext);
var
  Cache: TFileHighlightCache;
  Token: TStringPaintToken;
  Line: Integer;
  TextStart, TextEnd: Integer;
  OverlapStart, OverlapEnd: Integer;
  Fragment: string;
  X: Integer;
  SavedFont: TFont;
  SavedBrushStyle: TBrushStyle;
begin
  if BeforeEvent or Hilight or (SyntaxCode <> atString) then
    Exit;

  Cache := CacheForContext(Context);
  if (Cache = nil) or (Length(Cache.Tokens) = 0) then
    Exit;

  Line := Context.LogicalLineNum;
  if Line <= 0 then
    Line := Context.EditorLineNum;
  TextStart := ColNum;
  TextEnd := ColNum + Length(Text);

  SavedFont := TFont.Create;
  try
    SavedFont.Assign(Context.Canvas.Font);
    SavedBrushStyle := Context.Canvas.Brush.Style;
    Context.Canvas.Brush.Style := bsClear;
    for Token in Cache.Tokens do
    begin
      if Token.Line <> Line then
        Continue;

      OverlapStart := Max(Token.StartCol, TextStart);
      OverlapEnd := Min(Token.EndCol, TextEnd);
      if OverlapStart >= OverlapEnd then
        Continue;

      Fragment := Copy(Text, OverlapStart - TextStart + 1, OverlapEnd - OverlapStart);
      if Fragment = '' then
        Continue;

      Context.Canvas.Font.Color := TokenColor(Token.Kind);
      Context.Canvas.Font.Style := TokenStyle(Token.Kind);
      X := Rect.Left + (OverlapStart - TextStart) * Context.CellSize.cx;
      Context.Canvas.TextRect(Rect, X, Rect.Top, Fragment);
    end;
    Context.Canvas.Font.Assign(SavedFont);
    Context.Canvas.Brush.Style := SavedBrushStyle;
  finally
    SavedFont.Free;
  end;
end;

procedure Register;
begin
  if GNotifier = nil then
  begin
    GNotifier := TMultilineStringEditorNotifier.Create;
    GNotifier.RegisterNotifier;
  end;
end;

initialization

finalization
  FreeAndNil(GNotifier);

end.
