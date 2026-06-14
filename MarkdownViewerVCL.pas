unit MarkdownViewerVCL;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.Types,
  Winapi.Messages,
  Winapi.Windows,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.Themes,
  MarkdownViewer.Model,
  MarkdownViewer.Highlight;

type
  TMarkDownLinkClickEvent = procedure(Sender: TObject; const Url: string) of object;

  TMarkdownSyntaxColors = class(TPersistent)
  private
    FPlainColor: TColor;
    FKeywordColor: TColor;
    FCommentColor: TColor;
    FStringColor: TColor;
    FNumberColor: TColor;
    FTypeColor: TColor;
    FPreprocessorColor: TColor;
    FSymbolColor: TColor;

    FPlainStyle: TFontStyles;
    FKeywordStyle: TFontStyles;
    FCommentStyle: TFontStyles;
    FStringStyle: TFontStyles;
    FNumberStyle: TFontStyles;
    FTypeStyle: TFontStyles;
    FPreprocessorStyle: TFontStyles;
    FSymbolStyle: TFontStyles;

    FOwner: TComponent;
    procedure SetPlainColor(Value: TColor);
    procedure SetKeywordColor(Value: TColor);
    procedure SetCommentColor(Value: TColor);
    procedure SetStringColor(Value: TColor);
    procedure SetNumberColor(Value: TColor);
    procedure SetTypeColor(Value: TColor);
    procedure SetPreprocessorColor(Value: TColor);
    procedure SetSymbolColor(Value: TColor);

    procedure SetPlainStyle(Value: TFontStyles);
    procedure SetKeywordStyle(Value: TFontStyles);
    procedure SetCommentStyle(Value: TFontStyles);
    procedure SetStringStyle(Value: TFontStyles);
    procedure SetNumberStyle(Value: TFontStyles);
    procedure SetTypeStyle(Value: TFontStyles);
    procedure SetPreprocessorStyle(Value: TFontStyles);
    procedure SetSymbolStyle(Value: TFontStyles);

    procedure Changed;
  public
    constructor Create(AOwner: TComponent);
    procedure Assign(Source: TPersistent); override;
  published
    property PlainColor: TColor read FPlainColor write SetPlainColor default clDefault;
    property KeywordColor: TColor read FKeywordColor write SetKeywordColor default clDefault;
    property CommentColor: TColor read FCommentColor write SetCommentColor default clDefault;
    property StringColor: TColor read FStringColor write SetStringColor default clDefault;
    property NumberColor: TColor read FNumberColor write SetNumberColor default clDefault;
    property TypeColor: TColor read FTypeColor write SetTypeColor default clDefault;
    property PreprocessorColor: TColor read FPreprocessorColor write SetPreprocessorColor default clDefault;
    property SymbolColor: TColor read FSymbolColor write SetSymbolColor default clDefault;

    property PlainStyle: TFontStyles read FPlainStyle write SetPlainStyle default [];
    property KeywordStyle: TFontStyles read FKeywordStyle write SetKeywordStyle default [fsBold];
    property CommentStyle: TFontStyles read FCommentStyle write SetCommentStyle default [fsItalic];
    property StringStyle: TFontStyles read FStringStyle write SetStringStyle default [];
    property NumberStyle: TFontStyles read FNumberStyle write SetNumberStyle default [];
    property TypeStyle: TFontStyles read FTypeStyle write SetTypeStyle default [];
    property PreprocessorStyle: TFontStyles read FPreprocessorStyle write SetPreprocessorStyle default [];
    property SymbolStyle: TFontStyles read FSymbolStyle write SetSymbolStyle default [];
  end;

  TMarkDownViewer = class(TCustomControl)
  private
    FMarkdown: TStringList;
    FSyntaxColors: TMarkdownSyntaxColors;
    FBlocks: TMarkDownBlockList;
    FLinkHits: TMarkDownLinkHitList;
    FTaskHits: TMarkDownTaskHitList;
    FTextRuns: TMarkDownTextRunList;
    FCopyChunks: TMarkDownCopyChunkList;
    FSelectableText: string;
    FScrollPos: Integer;
    FContentHeight: Integer;
    FLastBlockTop: Integer;
    FSelectionAnchor: Integer;
    FSelectionCaret: Integer;
    FDesiredCaretX: Integer;
    FSelecting: Boolean;
    FLinkColor: TColor;
    FCodeBackgroundColor: TColor;
    FQuoteBarColor: TColor;
    FHeadingRuleColor: TColor;
    FSearchHighlightColor: TColor;
    FHighlightColor: TColor;
    FBasePath: string;
    FImageCache: TObjectDictionary<string, TPicture>;
    FImageAges: TDictionary<string, TDateTime>;
    FLinkReferences: TStringList;
    FSearchText: string;
    FCodeFontName: string;
    FEffectiveCodeFont: string;
    FAllowTaskToggle: Boolean;
    FAppendEndedWithCR: Boolean;
    FUpdatingMarkdown: Boolean;
    FReadOnly: Boolean;
    FUndoStack: TStringList;
    FRedoStack: TStringList;
    FApplyingEdit: Boolean;
    FHoveredCodeBlock: TMarkDownBlock;
    FHoveredCopyButton: Boolean;
    FCopiedTicks: Cardinal;
    FCopiedBlock: TMarkDownBlock;
    FOnChange: TNotifyEvent;
    FOnLinkClick: TMarkDownLinkClickEvent;
    FOnScroll: TNotifyEvent;
    function GetCodeBlockRect(ABlock: TMarkDownBlock): TRect; overload;
    function GetCodeBlockCopyBtnRect(ABlock: TMarkDownBlock): TRect; overload;
    function GetEffectiveCodeButtonColor: TColor;
    function GetEffectiveCodeButtonHoverColor: TColor;
    function GetEffectiveCodeButtonBorderColor: TColor;
    function GetEffectiveCodeButtonHoverBorderColor: TColor;
    function GetEffectiveCodeButtonTextColor: TColor;
    function GetEffectiveCodeButtonHoverTextColor: TColor;
    procedure SetSyntaxColors(Value: TMarkdownSyntaxColors);
    function IsBackgroundDark: Boolean;
    function GetEffectivePlainColor: TColor;
    function GetEffectiveKeywordColor: TColor;
    function GetEffectiveCommentColor: TColor;
    function GetEffectiveStringColor: TColor;
    function GetEffectiveNumberColor: TColor;
    function GetEffectiveTypeColor: TColor;
    function GetEffectivePreprocessorColor: TColor;
    function GetEffectiveSymbolColor: TColor;
    function GetSyntaxColor(Kind: TSourceTokenKind): TColor;
    function GetSyntaxStyle(Kind: TSourceTokenKind): TFontStyles;
    function GetCachedImage(const ImagePath: string): TPicture;
    function GetMarkdown: TStrings;
    function GetMarkdownText: string;
    function GetMaxScrollPosition: Integer;
    function HasSelection: Boolean;
    function HitTestTextPosition(X, Y: Integer): Integer;
    function IsMarkdownStored: Boolean;
    function SelectableToSourcePosition(Position: Integer): Integer;
    function SourceToSelectablePosition(Position: Integer): Integer;
    function SelectableOffsetInChunk(const Chunk: TMarkDownCopyChunk;
      SourcePos: Integer): Integer;
    // Selectable-text builders, used while Paint walks the block layout.
    function SliceMap(const Map: TArray<Integer>;
      Start0, Count: Integer): TArray<Integer>;
    function SliceMapValue(const Map: TArray<Integer>; Index: Integer): Integer;
    function ResolveChunkSourceMap(const AText: string;
      const AProvided: TArray<Integer>; AHasSource: Boolean): TArray<Integer>;
    procedure AddCopyChunk(TextStart: Integer; const ASourceMap: TArray<Integer>;
      const AText, AMarkdownText: string);
    function AddSelectableRun(const ARect: TRect; const AText: string;
      const ASourceMap: TArray<Integer>;
      const AMarkdownText: string = ''): Integer;
    procedure AddSelectableText(const AText: string;
      const AMarkdownText: string = ''; AHasSource: Boolean = True;
      const ASourceMap: TArray<Integer> = nil);
    procedure AddSelectableBreak(AHasSource: Boolean = True;
      ASourceStart: Integer = -1; AForce: Boolean = False);
    procedure DrawCaret;
    function SelectionRange(out SelStart, SelEnd: Integer): Boolean;
    procedure DrawSelectionBackground(const AText: string;
      TextX, TextY, TextHeight, TextStart: Integer);
    procedure DrawSelectableText(const AText: string;
      TextX, TextY, TextStart: Integer);
    procedure AssignBaseFont(Style: TFontStyles; SizeDelta: Integer;
      const FontName: string = '');
    procedure AssignInlineFont(const Token: TMarkDownInlineToken;
      BaseStyle: TFontStyles; SizeDelta: Integer);
    function DrawInline(ATokens: TMarkDownInlineList;
      ALeft, ATop, AWidth: Integer; ADraw: Boolean; BaseStyle: TFontStyles = [];
      SizeDelta: Integer = 0; AAlignment: TAlignment = taLeftJustify;
      const AMarkdownLinePrefix: string = '';
      AEmitAnchor: Boolean = False): Integer;
    function InlineTokensForBlock(ABlock: TMarkDownBlock): TMarkDownInlineList;
    function ResolveImagePath(const Url: string): string;
    function DrawImageBlock(const AltText, Url: string;
      ALeft, ATop, AWidth: Integer): Integer;
    function TableAlignmentFromCell(const Cell: string): TAlignment;
    function DrawTable(const TableText: string; ALeft, ATop, AWidth: Integer;
      const ABlockSourceMap: TArray<Integer>): Integer;
    function DrawBlocks(TextLeft, ContentWidth, Y: Integer): Integer;
    function BlockEndSourceLine(ABlock: TMarkDownBlock): Integer;
    function DrawEditableBlankLine(TextLeft, ContentWidth, Y,
      ALineIdx: Integer): Integer;
    procedure ClearSelection;
    procedure ClearInlineTokenCaches;
    procedure CopySelectionToClipboard(PlainText: Boolean);
    procedure DeleteSelectionOrCharacter(Backwards: Boolean);
    procedure InsertTextAtSelection(const Value: string);
    procedure InsertNewLine;
    procedure ToggleInlineFormat(const AMarker: string);
    function WrapSelectionWith(const AOpen, AClose: string): Boolean;
    procedure InvalidateLayout;
    procedure MarkdownChanged(Sender: TObject);
    procedure MoveCaret(Delta: Integer; ExtendSelection: Boolean);
    function WordTarget(Direction: Integer): Integer;
    procedure MoveCaretWord(Direction: Integer; ExtendSelection: Boolean);
    procedure DeleteWord(Backwards: Boolean);
    procedure MoveCaretLineBoundary(ToEnd, ExtendSelection: Boolean);
    procedure MoveCaretPage(Direction: Integer; ExtendSelection: Boolean);
    procedure MoveCaretVertical(Direction: Integer; ExtendSelection: Boolean);
    procedure MoveCaretDocumentBoundary(ToEnd, ExtendSelection: Boolean);
    procedure ScrollCaretIntoView;
    procedure SelectAllText;
    procedure SetBasePath(const Value: string);
    procedure SetCodeBackgroundColor(const Value: TColor);
    procedure SetCodeFontName(const Value: string);
    procedure SetHeadingRuleColor(const Value: TColor);
    procedure ToggleTaskAtLine(SourceLine: Integer);
    procedure SetReadOnly(const Value: Boolean);
    procedure SetLinkColor(const Value: TColor);
    procedure SetHighlightColor(const Value: TColor);
    procedure SetMarkdown(const Value: TStrings);
    procedure SetMarkdownText(const Value: string);
    procedure SetQuoteBarColor(const Value: TColor);
    procedure SetSearchHighlightColor(const Value: TColor);
    procedure SetSearchText(const Value: string);
    procedure SetScrollPosition(const Value: Integer);
    function SourcePosToLine(SourcePos: Integer): Integer;
    function GetBlockAtLine(LineIdx: Integer): TMarkDownBlock;
    function LineStartSourcePos(LineIdx: Integer): Integer;
    function GetHeadingPrefixLength(const Line: string): Integer;
    procedure PushUndoState;
    procedure ApplyMarkdownLine(ALineIndex: Integer; const ANewLine: string);
    procedure ApplyMarkdownText(const ANewText: string);
    procedure FinishEditAtSource(ASourcePos: Integer);
    procedure SetCaret(NewPosition: Integer; ExtendSelection: Boolean);
    procedure CollapseSelectionToEdge(Direction: Integer; ExtendSelection: Boolean);
    function RunContainingCaret: TMarkDownTextRun;
    procedure EnsureDesiredCaretX(const ARun: TMarkDownTextRun);
    function HandleCtrlKey(Key: Word; Shift: TShiftState): Boolean;
    function HandleEditingKey(Key: Word; Shift: TShiftState): Boolean;
    function HandleReadOnlyKey(Key: Word; Shift: TShiftState): Boolean;
    function ThemedColor(AThemedColor, AFallback: TColor): TColor;
    function GetEffectiveBackground: TColor;
    function GetEffectiveTextColor: TColor;
    function GetEffectiveSelectionBackground: TColor;
    function GetEffectiveSelectionTextColor: TColor;
    function GetEffectiveGridlineColor: TColor;
    function GetEffectiveTableHeaderColor: TColor;
    procedure GetBackgroundChannels(out R, G, B: Integer; out IsLight: Boolean);
    function GetEffectiveCodeBackgroundColor: TColor;
    function GetEffectiveSearchHighlightColor: TColor;
    function GetEffectiveHighlightColor: TColor;
    function GetEffectiveHeadingRuleColor: TColor;
    function GetEffectiveQuoteBarColor: TColor;
    function GetEffectiveLinkColor: TColor;
    function UseThemedColors: Boolean;
    procedure UpdateScrollBar;
    procedure WMEraseBkgnd(var Message: TMessage); message WM_ERASEBKGND;
    procedure WMGetDlgCode(var Message: TMessage); message WM_GETDLGCODE;
    procedure WMVScroll(var Message: TWMVScroll); message WM_VSCROLL;
    procedure WMMouseWheel(var Message: TWMMouseWheel); message WM_MOUSEWHEEL;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMStyleChanged(var Message: TMessage); message CM_STYLECHANGED;
    procedure WMTimer(var Message: TWMTimer); message WM_TIMER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DblClick; override;
    procedure Paint; override;
    procedure Resize; override;
    procedure SetStyleElements(const Value: TStyleElements); override;
    function GetCodeBlockCount: Integer;
    function GetCodeBlockRect(Index: Integer): TRect; overload;
    function GetCodeBlockCopyBtnRect(Index: Integer): TRect; overload;
    function IsCopyButtonHovered: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AppendMarkdownText(const Value: string);
    procedure CopySelection(PlainText: Boolean = False);
    function SelectedText(PlainText: Boolean = False): string;
    function FindNext: Boolean;
    function FindPrevious: Boolean;
    function SearchMatchCount: Integer;
    procedure LoadFromFile(const FileName: string);
    procedure Redo;
    procedure SelectAll;
    procedure Undo;
    procedure ChangeHeadingLevel(Delta: Integer);
    procedure SetHeadingLevel(TargetLevel: Integer);
    procedure ChangeListIndent(Delta: Integer);
    procedure MoveLineUpDown(Delta: Integer);
    procedure ToggleBold;
    procedure ToggleItalic;
    procedure ToggleStrikethrough;
    procedure ToggleInlineCode;
    procedure ToggleHighlight;
    procedure ToggleLink;
    procedure SelectWordAtCaret;
    function AsHtml: string;
    function AsHtmlDocument(const ATitle: string = ''): string;
    property MarkdownText: string read GetMarkdownText write SetMarkdownText;
    property MaxScrollPosition: Integer read GetMaxScrollPosition;
    property ScrollPosition: Integer read FScrollPos write SetScrollPosition;
  published
    property Align;
    property Anchors;
    property AllowTaskToggle: Boolean read FAllowTaskToggle write FAllowTaskToggle default True;
    property BasePath: string read FBasePath write SetBasePath;
    property Color default clWindow;
    property CodeBackgroundColor: TColor read FCodeBackgroundColor write SetCodeBackgroundColor default clDefault;
    property CodeFontName: string read FCodeFontName write SetCodeFontName;
    property Constraints;
    property HeadingRuleColor: TColor read FHeadingRuleColor write SetHeadingRuleColor default clDefault;
    property HighlightColor: TColor read FHighlightColor write SetHighlightColor default clDefault;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly default True;
    property Enabled;
    property Font;
    property LinkColor: TColor read FLinkColor write SetLinkColor default clDefault;
    property Markdown: TStrings read GetMarkdown write SetMarkdown stored IsMarkdownStored;
    property ParentColor;
    property ParentFont;
    property PopupMenu;
    property QuoteBarColor: TColor read FQuoteBarColor write SetQuoteBarColor default clDefault;
    property SearchHighlightColor: TColor read FSearchHighlightColor write SetSearchHighlightColor default clDefault;
    property SearchText: string read FSearchText write SetSearchText;
    property SyntaxColors: TMarkdownSyntaxColors read FSyntaxColors write SetSyntaxColors;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property OnClick;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnLinkClick: TMarkDownLinkClickEvent read FOnLinkClick write FOnLinkClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnScroll: TNotifyEvent read FOnScroll write FOnScroll;
  end;

procedure Register;

implementation

uses
  System.UITypes,
  System.Character,
  System.Math,
  System.StrUtils,
  System.SysUtils,
  Winapi.ShellAPI,
  Vcl.Clipbrd,
  Vcl.Forms,
  Vcl.Imaging.jpeg,
  Vcl.Imaging.pngimage,
  MarkdownViewer.Parser,
  MarkdownViewer.Renderer,
  MarkdownViewer.Html;

const
  MarkdownPadding = 14;
  ParagraphSpacing = 9;
  MaxUndoDepth = 100;

// Returns the requested font if it is installed, otherwise a monospace fallback
// that ships with Windows so code blocks always render in a fixed-width face.
function ResolveMonospaceFont(const Name: string): string;
begin
  if (Name <> '') and (Screen.Fonts.IndexOf(Name) >= 0) then
    Result := Name
  else
    Result := 'Courier New';
end;

// Flips a `[ ]` task marker to `[x]` (or back) in a source line, returning the
// line unchanged when it holds no task marker.
function FlipTaskMarker(const Line: string): string;
var
  I: Integer;
begin
  Result := Line;
  for I := 1 to Length(Line) - 2 do
    if (Line[I] = '[') and (Line[I + 2] = ']') and
      ((Line[I + 1] = ' ') or (UpCase(Line[I + 1]) = 'X')) then
    begin
      if Line[I + 1] = ' ' then
        Result := Copy(Line, 1, I) + 'x' + Copy(Line, I + 2, MaxInt)
      else
        Result := Copy(Line, 1, I) + ' ' + Copy(Line, I + 2, MaxInt);
      Exit;
    end;
end;

// Only shell out for URL schemes that cannot run local programs; anything
// else in a document (file paths, custom schemes) must go through the
// OnLinkClick event so the host application decides.
function IsSafeLinkUrl(const Url: string): Boolean;
begin
  Result := StartsText('http://', Url) or StartsText('https://', Url) or
    StartsText('mailto:', Url);
end;

procedure TrySetClipboardText(const Value: string);
begin
  try
    Clipboard.AsText := Value;
  except
    // Another process holds the clipboard; losing the copy beats raising.
  end;
end;

function ReadClipboardText: string;
begin
  try
    Result := Clipboard.AsText;
  except
    Result := '';
  end;
end;

procedure Register;
begin
  RegisterComponents('Kai', [TMarkDownViewer]);
end;

constructor TMarkDownViewer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csCaptureMouse];
  DoubleBuffered := True;
  Width := 360;
  Height := 260;
  TabStop := True;
  Color := clWindow;
  ParentColor := False;
  FLinkColor := clDefault;
  FCodeBackgroundColor := clDefault;
  FQuoteBarColor := clDefault;
  FHeadingRuleColor := clDefault;
  FSearchHighlightColor := clDefault;
  FHighlightColor := clDefault;
  FMarkdown := TStringList.Create;
  FMarkdown.OnChange := MarkdownChanged;
  FSyntaxColors := TMarkdownSyntaxColors.Create(Self);
  FLinkReferences := TStringList.Create;
  FLinkReferences.CaseSensitive := False;
  FCodeFontName := 'Consolas';
  FEffectiveCodeFont := ResolveMonospaceFont(FCodeFontName);
  FAllowTaskToggle := True;
  FBlocks := TMarkDownBlockList.Create(True);
  FLinkHits := TMarkDownLinkHitList.Create;
  FTaskHits := TMarkDownTaskHitList.Create;
  FTextRuns := TMarkDownTextRunList.Create;
  FCopyChunks := TMarkDownCopyChunkList.Create;
  FImageCache := TObjectDictionary<string, TPicture>.Create([doOwnsValues]);
  FImageAges := TDictionary<string, TDateTime>.Create;
  FUndoStack := TStringList.Create;
  FRedoStack := TStringList.Create;
  FDesiredCaretX := -1;
  FReadOnly := True;
  StyleElements := [seFont, seClient];
  Font.Size := 10;
  FHoveredCodeBlock := nil;
  FHoveredCopyButton := False;
  FCopiedTicks := 0;
  FCopiedBlock := nil;
end;

destructor TMarkDownViewer.Destroy;
begin
  if HandleAllocated then
    KillTimer(Handle, 1);
  FRedoStack.Free;
  FUndoStack.Free;
  FImageAges.Free;
  FImageCache.Free;
  FCopyChunks.Free;
  FTextRuns.Free;
  FTaskHits.Free;
  FLinkHits.Free;
  FBlocks.Free;
  FLinkReferences.Free;
  FMarkdown.Free;
  FSyntaxColors.Free;
  inherited Destroy;
end;

procedure TMarkDownViewer.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := Params.Style or WS_VSCROLL;
end;

procedure TMarkDownViewer.CMFontChanged(var Message: TMessage);
begin
  inherited;
  InvalidateLayout;
  Invalidate;
end;

procedure TMarkDownViewer.CMStyleChanged(var Message: TMessage);
begin
  inherited;
  InvalidateLayout;
  Invalidate;
end;

procedure TMarkDownViewer.SetStyleElements(const Value: TStyleElements);
begin
  if StyleElements <> Value then
  begin
    inherited SetStyleElements(Value);
    Invalidate;
  end;
end;

function TMarkDownViewer.UseThemedColors: Boolean;
begin
  Result := TStyleManager.IsCustomStyleActive and (seClient in StyleElements);
end;

// When a VCL style is active (and skinning the client) colours come from the
// style; otherwise fall back to the supplied plain colour.
function TMarkDownViewer.ThemedColor(AThemedColor, AFallback: TColor): TColor;
begin
  if UseThemedColors then
    Result := StyleServices.GetSystemColor(AThemedColor)
  else
    Result := AFallback;
end;

function TMarkDownViewer.GetEffectiveBackground: TColor;
begin
  // An explicitly chosen Color wins, even under a VCL style; the default
  // (clWindow) follows the active style so the control blends into the theme.
  if Color <> clWindow then
    Result := Color
  else
    Result := ThemedColor(clWindow, Color);
end;

function TMarkDownViewer.GetEffectiveTextColor: TColor;
begin
  Result := ThemedColor(clWindowText, Font.Color);
end;

function TMarkDownViewer.GetEffectiveSelectionBackground: TColor;
begin
  if TStyleManager.IsCustomStyleActive then
    Result := StyleServices.GetSystemColor(clHighlight)
  else
    Result := clHighlight;
end;

function TMarkDownViewer.GetEffectiveSelectionTextColor: TColor;
begin
  if TStyleManager.IsCustomStyleActive then
    Result := StyleServices.GetSystemColor(clHighlightText)
  else
    Result := clHighlightText;
end;

function TMarkDownViewer.GetEffectiveGridlineColor: TColor;
begin
  Result := ThemedColor(clBtnShadow, clSilver);
end;

function TMarkDownViewer.GetEffectiveTableHeaderColor: TColor;
begin
  Result := ThemedColor(clBtnFace, $00F7F7F7);
end;

{ TMarkdownSyntaxColors }

constructor TMarkdownSyntaxColors.Create(AOwner: TComponent);
begin
  inherited Create;
  FOwner := AOwner;
  FPlainColor := clDefault;
  FKeywordColor := clDefault;
  FCommentColor := clDefault;
  FStringColor := clDefault;
  FNumberColor := clDefault;
  FTypeColor := clDefault;
  FPreprocessorColor := clDefault;
  FSymbolColor := clDefault;

  FPlainStyle := [];
  FKeywordStyle := [fsBold];
  FCommentStyle := [fsItalic];
  FStringStyle := [];
  FNumberStyle := [];
  FTypeStyle := [];
  FPreprocessorStyle := [];
  FSymbolStyle := [];
end;

procedure TMarkdownSyntaxColors.Assign(Source: TPersistent);
var
  Src: TMarkdownSyntaxColors;
begin
  if Source is TMarkdownSyntaxColors then
  begin
    Src := TMarkdownSyntaxColors(Source);
    FPlainColor := Src.PlainColor;
    FKeywordColor := Src.KeywordColor;
    FCommentColor := Src.CommentColor;
    FStringColor := Src.StringColor;
    FNumberColor := Src.NumberColor;
    FTypeColor := Src.TypeColor;
    FPreprocessorColor := Src.PreprocessorColor;
    FSymbolColor := Src.SymbolColor;

    FPlainStyle := Src.PlainStyle;
    FKeywordStyle := Src.KeywordStyle;
    FCommentStyle := Src.CommentStyle;
    FStringStyle := Src.StringStyle;
    FNumberStyle := Src.NumberStyle;
    FTypeStyle := Src.TypeStyle;
    FPreprocessorStyle := Src.PreprocessorStyle;
    FSymbolStyle := Src.SymbolStyle;
    Changed;
  end
  else
    inherited Assign(Source);
end;

procedure TMarkdownSyntaxColors.Changed;
begin
  if (FOwner <> nil) and (FOwner is TCustomControl) then
    TCustomControl(FOwner).Invalidate;
end;

procedure TMarkdownSyntaxColors.SetPlainColor(Value: TColor);
begin
  if FPlainColor <> Value then
  begin
    FPlainColor := Value;
    Changed;
  end;
end;

procedure TMarkdownSyntaxColors.SetKeywordColor(Value: TColor);
begin
  if FKeywordColor <> Value then
  begin
    FKeywordColor := Value;
    Changed;
  end;
end;

procedure TMarkdownSyntaxColors.SetCommentColor(Value: TColor);
begin
  if FCommentColor <> Value then
  begin
    FCommentColor := Value;
    Changed;
  end;
end;

procedure TMarkdownSyntaxColors.SetStringColor(Value: TColor);
begin
  if FStringColor <> Value then
  begin
    FStringColor := Value;
    Changed;
  end;
end;

procedure TMarkdownSyntaxColors.SetNumberColor(Value: TColor);
begin
  if FNumberColor <> Value then
  begin
    FNumberColor := Value;
    Changed;
  end;
end;

procedure TMarkdownSyntaxColors.SetTypeColor(Value: TColor);
begin
  if FTypeColor <> Value then
  begin
    FTypeColor := Value;
    Changed;
  end;
end;

procedure TMarkdownSyntaxColors.SetPreprocessorColor(Value: TColor);
begin
  if FPreprocessorColor <> Value then
  begin
    FPreprocessorColor := Value;
    Changed;
  end;
end;

procedure TMarkdownSyntaxColors.SetSymbolColor(Value: TColor);
begin
  if FSymbolColor <> Value then
  begin
    FSymbolColor := Value;
    Changed;
  end;
end;

procedure TMarkdownSyntaxColors.SetPlainStyle(Value: TFontStyles);
begin
  if FPlainStyle <> Value then
  begin
    FPlainStyle := Value;
    Changed;
  end;
end;

procedure TMarkdownSyntaxColors.SetKeywordStyle(Value: TFontStyles);
begin
  if FKeywordStyle <> Value then
  begin
    FKeywordStyle := Value;
    Changed;
  end;
end;

procedure TMarkdownSyntaxColors.SetCommentStyle(Value: TFontStyles);
begin
  if FCommentStyle <> Value then
  begin
    FCommentStyle := Value;
    Changed;
  end;
end;

procedure TMarkdownSyntaxColors.SetStringStyle(Value: TFontStyles);
begin
  if FStringStyle <> Value then
  begin
    FStringStyle := Value;
    Changed;
  end;
end;

procedure TMarkdownSyntaxColors.SetNumberStyle(Value: TFontStyles);
begin
  if FNumberStyle <> Value then
  begin
    FNumberStyle := Value;
    Changed;
  end;
end;

procedure TMarkdownSyntaxColors.SetTypeStyle(Value: TFontStyles);
begin
  if FTypeStyle <> Value then
  begin
    FTypeStyle := Value;
    Changed;
  end;
end;

procedure TMarkdownSyntaxColors.SetPreprocessorStyle(Value: TFontStyles);
begin
  if FPreprocessorStyle <> Value then
  begin
    FPreprocessorStyle := Value;
    Changed;
  end;
end;

procedure TMarkdownSyntaxColors.SetSymbolStyle(Value: TFontStyles);
begin
  if FSymbolStyle <> Value then
  begin
    FSymbolStyle := Value;
    Changed;
  end;
end;

{ TMarkDownViewer - Syntax Highlight Helpers }

procedure TMarkDownViewer.SetSyntaxColors(Value: TMarkdownSyntaxColors);
begin
  FSyntaxColors.Assign(Value);
  Invalidate;
end;

function TMarkDownViewer.IsBackgroundDark: Boolean;
var
  R, G, B: Integer;
  IsLight: Boolean;
begin
  GetBackgroundChannels(R, G, B, IsLight);
  Result := not IsLight;
end;

function TMarkDownViewer.GetEffectivePlainColor: TColor;
begin
  if FSyntaxColors.PlainColor <> clDefault then
    Exit(FSyntaxColors.PlainColor);
  Result := GetEffectiveTextColor;
end;

function TMarkDownViewer.GetEffectiveKeywordColor: TColor;
begin
  if FSyntaxColors.KeywordColor <> clDefault then
    Exit(FSyntaxColors.KeywordColor);
  if IsBackgroundDark then
    Result := $00FF9010 // Light blue
  else
    Result := clBlue;
end;

function TMarkDownViewer.GetEffectiveCommentColor: TColor;
begin
  if FSyntaxColors.CommentColor <> clDefault then
    Exit(FSyntaxColors.CommentColor);
  if IsBackgroundDark then
    Result := $0070A070 // Light green
  else
    Result := $00008000; // Dark green
end;

function TMarkDownViewer.GetEffectiveStringColor: TColor;
begin
  if FSyntaxColors.StringColor <> clDefault then
    Exit(FSyntaxColors.StringColor);
  if IsBackgroundDark then
    Result := $0080C0FF // Light orange
  else
    Result := $00001090; // Dark orange/red
end;

function TMarkDownViewer.GetEffectiveNumberColor: TColor;
begin
  if FSyntaxColors.NumberColor <> clDefault then
    Exit(FSyntaxColors.NumberColor);
  if IsBackgroundDark then
    Result := $00FFB070 // Light orange/brown
  else
    Result := $000040A0; // Brown
end;

function TMarkDownViewer.GetEffectiveTypeColor: TColor;
begin
  if FSyntaxColors.TypeColor <> clDefault then
    Exit(FSyntaxColors.TypeColor);
  if IsBackgroundDark then
    Result := $0080FFFF // Yellow
  else
    Result := clNavy;
end;

function TMarkDownViewer.GetEffectivePreprocessorColor: TColor;
begin
  if FSyntaxColors.PreprocessorColor <> clDefault then
    Exit(FSyntaxColors.PreprocessorColor);
  if IsBackgroundDark then
    Result := $00A0A0A0 // Light gray
  else
    Result := $00606060; // Dark gray
end;

function TMarkDownViewer.GetEffectiveSymbolColor: TColor;
begin
  if FSyntaxColors.SymbolColor <> clDefault then
    Exit(FSyntaxColors.SymbolColor);
  if IsBackgroundDark then
    Result := $00D0D0D0 // Light gray
  else
    Result := $00303030; // Dark gray
end;

function TMarkDownViewer.GetSyntaxColor(Kind: TSourceTokenKind): TColor;
begin
  case Kind of
    stKeyword: Result := GetEffectiveKeywordColor;
    stComment: Result := GetEffectiveCommentColor;
    stString: Result := GetEffectiveStringColor;
    stNumber: Result := GetEffectiveNumberColor;
    stType: Result := GetEffectiveTypeColor;
    stPreprocessor: Result := GetEffectivePreprocessorColor;
    stSymbol: Result := GetEffectiveSymbolColor;
  else
    Result := GetEffectivePlainColor;
  end;
end;

function TMarkDownViewer.GetSyntaxStyle(Kind: TSourceTokenKind): TFontStyles;
begin
  case Kind of
    stKeyword: Result := FSyntaxColors.KeywordStyle;
    stComment: Result := FSyntaxColors.CommentStyle;
    stString: Result := FSyntaxColors.StringStyle;
    stNumber: Result := FSyntaxColors.NumberStyle;
    stType: Result := FSyntaxColors.TypeStyle;
    stPreprocessor: Result := FSyntaxColors.PreprocessorStyle;
    stSymbol: Result := FSyntaxColors.SymbolStyle;
  else
    Result := FSyntaxColors.PlainStyle;
  end;
end;

// Decompose the effective background into 8-bit channels and report whether
// it reads as light (so derived colours know which way to shift for contrast).
procedure TMarkDownViewer.GetBackgroundChannels(out R, G, B: Integer;
  out IsLight: Boolean);
var
  BaseColor: TColor;
begin
  BaseColor := ColorToRGB(GetEffectiveBackground);
  R := GetRValue(BaseColor);
  G := GetGValue(BaseColor);
  B := GetBValue(BaseColor);
  IsLight := (0.299 * R + 0.587 * G + 0.114 * B) > 128;
end;

function TMarkDownViewer.GetEffectiveCodeBackgroundColor: TColor;
var
  R, G, B: Integer;
  IsLight: Boolean;
begin
  if FCodeBackgroundColor <> clDefault then
    Exit(FCodeBackgroundColor);

  GetBackgroundChannels(R, G, B, IsLight);
  if IsLight then
    Result := RGB(Max(0, R - 28), Max(0, G - 28), Max(0, B - 28))
  else
    Result := RGB(Min(255, R + 32), Min(255, G + 32), Min(255, B + 32));
end;

function TMarkDownViewer.GetEffectiveSearchHighlightColor: TColor;
var
  R, G, B: Integer;
  IsLight: Boolean;
begin
  if FSearchHighlightColor <> clDefault then
    Exit(FSearchHighlightColor);

  GetBackgroundChannels(R, G, B, IsLight);
  if IsLight then
    Result := RGB(Min(255, R + 20), Min(255, G + 20), Max(0, B - 40))
  else
    Result := RGB(Min(255, R + 64), Min(255, G + 64), Min(255, B + 72));
end;

function TMarkDownViewer.GetEffectiveHighlightColor: TColor;
var
  R, G, B: Integer;
  IsLight: Boolean;
begin
  if FHighlightColor <> clDefault then
    Exit(FHighlightColor);

  GetBackgroundChannels(R, G, B, IsLight);
  if IsLight then
    Result := RGB(255, 255, 160) // Soft yellow
  else
    Result := RGB(96, 96, 0);    // Dark gold/yellow
end;

function TMarkDownViewer.GetEffectiveHeadingRuleColor: TColor;
begin
  if FHeadingRuleColor = clNone then
    Exit(clNone);
  if FHeadingRuleColor <> clDefault then
    Exit(FHeadingRuleColor);
  Result := GetEffectiveCodeBackgroundColor;
end;

function TMarkDownViewer.GetEffectiveQuoteBarColor: TColor;
begin
  if FQuoteBarColor <> clDefault then
    Exit(FQuoteBarColor);
  Result := GetEffectiveGridlineColor;
end;

function TMarkDownViewer.GetEffectiveLinkColor: TColor;
begin
  if FLinkColor <> clDefault then
    Exit(FLinkColor);
  Result := GetEffectiveSelectionBackground;
end;

procedure TMarkDownViewer.ClearInlineTokenCaches;
var
  Block: TMarkDownBlock;
begin
  for Block in FBlocks do
    FreeAndNil(Block.InlineTokens);
end;

procedure TMarkDownViewer.InvalidateLayout;
var
  Block: TMarkDownBlock;
begin
  for Block in FBlocks do
  begin
    Block.LayoutHeight := -1;
    Block.LayoutWidth := -1;
  end;
end;

// Ctrl-modified keys: clipboard, undo/redo, select-all and document-boundary
// navigation. Returns True when the key was consumed.
function TMarkDownViewer.HandleCtrlKey(Key: Word; Shift: TShiftState): Boolean;
var
  OldSourcePos: Integer;
  LineIdx: Integer;
begin
  Result := True;
  case Key of
    Ord('A'):
      SelectAllText;
    Ord('0'), VK_NUMPAD0:
      if not FReadOnly then
        SetHeadingLevel(0)
      else
        Result := False;
    Ord('1')..Ord('6'), VK_NUMPAD1..VK_NUMPAD6:
      if not FReadOnly then
      begin
        if (Key >= VK_NUMPAD1) and (Key <= VK_NUMPAD6) then
          SetHeadingLevel(Key - VK_NUMPAD1 + 1)
        else
          SetHeadingLevel(Key - Ord('0'));
      end
      else
        Result := False;
    Ord('B'):
      if not FReadOnly then
        ToggleBold
      else
        Result := False;
    Ord('I'):
      if not FReadOnly then
        ToggleItalic
      else
        Result := False;
    Ord('E'):
      if not FReadOnly then
        ToggleInlineCode
      else
        Result := False;
    Ord('K'):
      if not FReadOnly then
        ToggleLink
      else
        Result := False;
    Ord('T'):
      if not FReadOnly then
        ToggleStrikethrough
      else
        Result := False;
    Ord('H'):
      if not FReadOnly then
        ToggleHighlight
      else
        Result := False;
    Ord('C'):
      CopySelectionToClipboard(ssShift in Shift);
    Ord('V'):
      if not FReadOnly then
        InsertTextAtSelection(ReadClipboardText)
      else
        Result := False;
    Ord('X'):
      if not FReadOnly and HasSelection then
      begin
        CopySelectionToClipboard(False);
        InsertTextAtSelection('');
      end
      else
        Result := False;
    Ord('Y'):
      if not FReadOnly then
        Redo
      else
        Result := False;
    Ord('Z'):
      if not FReadOnly then
      begin
        if ssShift in Shift then
          Redo
        else
          Undo;
      end
      else
        Result := False;
    VK_INSERT:
      CopySelectionToClipboard(True);
    VK_SPACE:
      if FAllowTaskToggle then
      begin
        OldSourcePos := SelectableToSourcePosition(FSelectionCaret);
        LineIdx := SourcePosToLine(OldSourcePos);
        ToggleTaskAtLine(LineIdx);
        FinishEditAtSource(OldSourcePos);
      end
      else
        Result := False;
    VK_LEFT:
      if not FReadOnly then
        MoveCaretWord(-1, ssShift in Shift)
      else
        Result := False;
    VK_RIGHT:
      if not FReadOnly then
        MoveCaretWord(1, ssShift in Shift)
      else
        Result := False;
    VK_BACK:
      if not FReadOnly then
        DeleteWord(True)
      else
        Result := False;
    VK_DELETE:
      if not FReadOnly then
        DeleteWord(False)
      else
        Result := False;
    VK_HOME:
      if not FReadOnly then
        MoveCaretDocumentBoundary(False, ssShift in Shift)
      else
        SetScrollPosition(0);
    VK_END:
      if not FReadOnly then
        MoveCaretDocumentBoundary(True, ssShift in Shift)
      else
        SetScrollPosition(FContentHeight);
  else
    Result := False;
  end;
end;

// Editing keys (when not read-only): caret movement, deletion and Tab heading
// level changes. Returns True when the key was consumed.
function TMarkDownViewer.HandleEditingKey(Key: Word; Shift: TShiftState): Boolean;
var
  OldSourcePos: Integer;
  LineIdx: Integer;
  Block: TMarkDownBlock;
begin
  Result := True;
  case Key of
    VK_LEFT:
      MoveCaret(-1, ssShift in Shift);
    VK_RIGHT:
      MoveCaret(1, ssShift in Shift);
    VK_UP:
      if ssAlt in Shift then
        MoveLineUpDown(-1)
      else
        MoveCaretVertical(-1, ssShift in Shift);
    VK_DOWN:
      if ssAlt in Shift then
        MoveLineUpDown(1)
      else
        MoveCaretVertical(1, ssShift in Shift);
    VK_HOME:
      MoveCaretLineBoundary(False, ssShift in Shift);
    VK_END:
      MoveCaretLineBoundary(True, ssShift in Shift);
    VK_PRIOR:
      MoveCaretPage(-1, ssShift in Shift);
    VK_NEXT:
      MoveCaretPage(1, ssShift in Shift);
    VK_BACK:
      DeleteSelectionOrCharacter(True);
    VK_DELETE:
      DeleteSelectionOrCharacter(False);
    VK_ESCAPE:
      ClearSelection;
    VK_TAB:
      begin
        OldSourcePos := SelectableToSourcePosition(FSelectionCaret);
        LineIdx := SourcePosToLine(OldSourcePos);
        Block := GetBlockAtLine(LineIdx);
        if (Block <> nil) and (Block.Kind = bkListItem) then
        begin
          if ssShift in Shift then
            ChangeListIndent(-1)
          else
            ChangeListIndent(1);
        end
        else
        begin
          if ssShift in Shift then
            ChangeHeadingLevel(-1)
          else
            ChangeHeadingLevel(1);
        end;
      end;
  else
    Result := False;
  end;
end;

// Read-only keys: scrolling only. Returns True when the key was consumed.
function TMarkDownViewer.HandleReadOnlyKey(Key: Word; Shift: TShiftState): Boolean;
begin
  Result := True;
  case Key of
    VK_UP:
      SetScrollPosition(FScrollPos - 24);
    VK_DOWN:
      SetScrollPosition(FScrollPos + 24);
    VK_PRIOR:
      SetScrollPosition(FScrollPos - ClientHeight);
    VK_NEXT:
      SetScrollPosition(FScrollPos + ClientHeight);
    VK_HOME:
      SetScrollPosition(0);
    VK_END:
      SetScrollPosition(FContentHeight);
    VK_ESCAPE:
      ClearSelection;
    VK_SPACE:
      if ssShift in Shift then
        SetScrollPosition(FScrollPos - ClientHeight)
      else
        SetScrollPosition(FScrollPos + ClientHeight);
  else
    Result := False;
  end;
end;

procedure TMarkDownViewer.KeyDown(var Key: Word; Shift: TShiftState);
var
  Handled: Boolean;
begin
  inherited KeyDown(Key, Shift);

  if ssCtrl in Shift then
    Handled := HandleCtrlKey(Key, Shift)
  else if not FReadOnly then
    Handled := HandleEditingKey(Key, Shift)
  else
    Handled := HandleReadOnlyKey(Key, Shift);

  if Handled then
    Key := 0;
end;

procedure TMarkDownViewer.KeyPress(var Key: Char);
var
  Wrapped: Boolean;
  OldSourcePos: Integer;
  SourceText: string;
  PrevChar: Char;
  NextChar: Char;
  PairChar: Char;
  IsOpening: Boolean;
  IsClosing: Boolean;
begin
  inherited KeyPress(Key);
  if FReadOnly then
    Exit;

  case Key of
    #8:
      Key := #0;
    #13:
      begin
        InsertNewLine;
        Key := #0;
      end;
    #32..#65535:
      begin
        // Typing an opening bracket/quote over a selection wraps it.
        if HasSelection then
        begin
          case Key of
            '(': Wrapped := WrapSelectionWith('(', ')');
            '[': Wrapped := WrapSelectionWith('[', ']');
            '{': Wrapped := WrapSelectionWith('{', '}');
            '"': Wrapped := WrapSelectionWith('"', '"');
            '''': Wrapped := WrapSelectionWith('''', '''');
            '`': Wrapped := WrapSelectionWith('`', '`');
          else
            Wrapped := False;
          end;
          if not Wrapped then
            InsertTextAtSelection(Key);
          Key := #0;
          Exit;
        end;

        // No selection: check for over-typing skip or auto-pairing
        OldSourcePos := SelectableToSourcePosition(FSelectionCaret);
        SourceText := FMarkdown.Text;
        
        // Find next character (if any) and previous character (if any)
        if (OldSourcePos >= 0) and (OldSourcePos < Length(SourceText)) then
          NextChar := SourceText[OldSourcePos + 1]
        else
          NextChar := #0;

        if (OldSourcePos > 0) and (OldSourcePos <= Length(SourceText)) then
          PrevChar := SourceText[OldSourcePos]
        else
          PrevChar := #0;

        // 1. Check for over-typing skip (step over existing closing character)
        IsClosing := CharInSet(Key, [')', ']', '}', '"', '''', '`']);
        if IsClosing and (NextChar = Key) then
        begin
          FinishEditAtSource(OldSourcePos + 1);
          Key := #0;
          Exit;
        end;

        // 2. Check for auto-pairing
        IsOpening := CharInSet(Key, ['(', '[', '{', '"', '''', '`']);
        if IsOpening then
        begin
          // For quote characters, skip auto-pairing if preceded by a word character
          if CharInSet(Key, ['"', '''']) and CharInSet(PrevChar, ['a'..'z', 'A'..'Z', '0'..'9', '_']) then
          begin
            InsertTextAtSelection(Key);
            Key := #0;
            Exit;
          end;

          case Key of
            '(': PairChar := ')';
            '[': PairChar := ']';
            '{': PairChar := '}';
          else
            PairChar := Key; // symmetric quotes: ", ', `
          end;

          InsertTextAtSelection(Key + PairChar);
          FinishEditAtSource(OldSourcePos + 1);
          Key := #0;
          Exit;
        end;

        InsertTextAtSelection(Key);
        Key := #0;
      end;
  end;
end;

function TMarkDownViewer.GetCachedImage(const ImagePath: string): TPicture;
var
  Age: TDateTime;
begin
  if not FileAge(ImagePath, Age) then
    Age := 0;
  if FImageCache.TryGetValue(ImagePath, Result) then
  begin
    if FImageAges[ImagePath] = Age then
      Exit;
    FImageCache.Remove(ImagePath);
    FImageAges.Remove(ImagePath);
  end;

  // A nil entry records a failed load so the file is not retried every paint.
  Result := TPicture.Create;
  try
    Result.LoadFromFile(ImagePath);
  except
    FreeAndNil(Result);
  end;
  FImageCache.Add(ImagePath, Result);
  FImageAges.Add(ImagePath, Age);
end;

function TMarkDownViewer.GetMarkdownText: string;
begin
  Result := FMarkdown.Text;
end;

function TMarkDownViewer.GetMarkdown: TStrings;
begin
  Result := FMarkdown;
end;

function TMarkDownViewer.GetMaxScrollPosition: Integer;
begin
  Result := Max(0, FContentHeight - ClientHeight);
end;

function TMarkDownViewer.HasSelection: Boolean;
begin
  Result := FSelectionAnchor <> FSelectionCaret;
end;

function TMarkDownViewer.HitTestTextPosition(X, Y: Integer): Integer;
var
  I: Integer;
  C: Integer;
  Run: TMarkDownTextRun;
  PrefixWidth: Integer;
  CharMid: Integer;
  LineCandidate: Integer;
begin
  Result := 0;
  LineCandidate := -1;
  if (FTextRuns = nil) or (FTextRuns.Count = 0) then
    Exit;

  for I := 0 to FTextRuns.Count - 1 do
  begin
    Run := FTextRuns[I];
    if (Y >= Run.Rect.Top) and (Y <= Run.Rect.Bottom) then
    begin
      if X < Run.Rect.Left then
        Exit(Run.StartIndex);

      if X <= Run.Rect.Right then
      begin
        Canvas.Font.Assign(Font);
        Canvas.Font.Name := Run.FontName;
        Canvas.Font.Size := Run.FontSize;
        Canvas.Font.Style := Run.FontStyle;
        for C := 1 to Length(Run.Text) do
        begin
          PrefixWidth := Canvas.TextWidth(Copy(Run.Text, 1, C - 1));
          CharMid := Run.Rect.Left + PrefixWidth +
            (Canvas.TextWidth(Copy(Run.Text, C, 1)) div 2);
          if X < CharMid then
            Exit(Run.StartIndex + C - 1);
        end;
        Exit(Run.StartIndex + Length(Run.Text));
      end;

      LineCandidate := Run.StartIndex + Length(Run.Text);
    end;
  end;

  if LineCandidate >= 0 then
    Exit(LineCandidate);

  if Y < FTextRuns[0].Rect.Top then
    Exit(0);

  Result := Length(FSelectableText);
end;

function TMarkDownViewer.IsMarkdownStored: Boolean;
begin
  Result := FMarkdown.Count > 0;
end;

function TMarkDownViewer.SelectableToSourcePosition(Position: Integer): Integer;
var
  Chunk: TMarkDownCopyChunk;
  I: Integer;
  Local: Integer;
begin
  Result := 0;
  Position := EnsureRange(Position, 0, Length(FSelectableText));
  for I := 0 to FCopyChunks.Count - 1 do
  begin
    Chunk := FCopyChunks[I];
    if Length(Chunk.SourceMap) = 0 then
      Continue;
    if Position < Chunk.StartIndex then
      Exit(Chunk.SourceMap[0]);
    if (Position = Chunk.StartIndex + Length(Chunk.Text)) and
      (I < FCopyChunks.Count - 1) and
      (FCopyChunks[I + 1].StartIndex = Position) and
      (Length(FCopyChunks[I + 1].SourceMap) > 0) then
      Continue;
    if Position <= Chunk.StartIndex + Length(Chunk.Text) then
    begin
      Local := EnsureRange(Position - Chunk.StartIndex, 0, Length(Chunk.Text));
      Exit(Chunk.SourceMap[Local]);
    end;
    Result := Chunk.SourceMap[Length(Chunk.Text)];
  end;
  Result := EnsureRange(Result, 0, Length(FMarkdown.Text));
end;

// The character index within a chunk whose source covers SourcePos. SourceMap
// is monotonic, so this is the last entry that does not exceed SourcePos -
// keeping the caret on, say, a decoded entity for any offset inside its span.
function TMarkDownViewer.SelectableOffsetInChunk(
  const Chunk: TMarkDownCopyChunk; SourcePos: Integer): Integer;
var
  K: Integer;
begin
  Result := 0;
  for K := 0 to Length(Chunk.Text) do
    if Chunk.SourceMap[K] <= SourcePos then
      Result := K
    else
      Break;
end;

function TMarkDownViewer.SourceToSelectablePosition(Position: Integer): Integer;
var
  Chunk: TMarkDownCopyChunk;
  I: Integer;
begin
  Result := 0;
  Position := EnsureRange(Position, 0, Length(FMarkdown.Text));
  for I := 0 to FCopyChunks.Count - 1 do
  begin
    Chunk := FCopyChunks[I];
    if Length(Chunk.SourceMap) = 0 then
      Continue;
    if Position < Chunk.SourceMap[0] then
      Exit(Chunk.StartIndex);
    if Position <= Chunk.SourceMap[Length(Chunk.Text)] then
      Exit(Chunk.StartIndex + SelectableOffsetInChunk(Chunk, Position));
    Result := Chunk.StartIndex + Length(Chunk.Text);
  end;
  Result := EnsureRange(Result, 0, Length(FSelectableText));
end;

procedure TMarkDownViewer.ClearSelection;
begin
  if HasSelection then
  begin
    FSelectionAnchor := 0;
    FSelectionCaret := 0;
    Invalidate;
  end
  else
  begin
    FSelectionAnchor := 0;
    FSelectionCaret := 0;
  end;
end;

function TMarkDownViewer.SelectedText(PlainText: Boolean): string;
var
  Chunk: TMarkDownCopyChunk;
  ChunkIndex: Integer;
  LocalEnd: Integer;
  LocalStart: Integer;
  SelStart: Integer;
  SelEnd: Integer;
begin
  Result := '';
  if not HasSelection then
    Exit;

  SelStart := Min(FSelectionAnchor, FSelectionCaret);
  SelEnd := Max(FSelectionAnchor, FSelectionCaret);
  if PlainText then
    Exit(Copy(FSelectableText, SelStart + 1, SelEnd - SelStart));

  if (SelStart = 0) and (SelEnd = Length(FSelectableText)) then
    Exit(FMarkdown.Text);

  for ChunkIndex := 0 to FCopyChunks.Count - 1 do
  begin
    Chunk := FCopyChunks[ChunkIndex];
    if Chunk.Text = '' then
      Continue;
    if (SelEnd <= Chunk.StartIndex) or
      (SelStart >= Chunk.StartIndex + Length(Chunk.Text)) then
      Continue;

    LocalStart := Max(0, SelStart - Chunk.StartIndex);
    LocalEnd := Min(Length(Chunk.Text), SelEnd - Chunk.StartIndex);
    if LocalStart >= LocalEnd then
      Continue;

    if (LocalStart = 0) and (LocalEnd = Length(Chunk.Text)) then
      Result := Result + Chunk.MarkdownText
    else
      Result := Result + Copy(Chunk.Text, LocalStart + 1, LocalEnd - LocalStart);
  end;
end;

procedure TMarkDownViewer.CopySelectionToClipboard(PlainText: Boolean);
begin
  if not HasSelection then
    Exit;
  TrySetClipboardText(SelectedText(PlainText));
end;

procedure TMarkDownViewer.CopySelection(PlainText: Boolean);
begin
  CopySelectionToClipboard(PlainText);
end;

procedure TMarkDownViewer.DeleteSelectionOrCharacter(Backwards: Boolean);
var
  SourcePos: Integer;
  SourceText: string;
  PrevChar: Char;
  NextChar: Char;
  IsPair: Boolean;
begin
  if HasSelection then
  begin
    InsertTextAtSelection('');
    Exit;
  end;

  if Backwards then
  begin
    // Check for backticks pair first, as it can occur when FSelectionCaret is 0 (since backticks are hidden markup)
    SourcePos := SelectableToSourcePosition(FSelectionCaret);
    SourceText := FMarkdown.Text;
    if (SourcePos >= 0) and (SourcePos + 1 < Length(SourceText)) then
    begin
      if (SourceText[SourcePos + 1] = '`') and (SourceText[SourcePos + 2] = '`') then
      begin
        PushUndoState;
        Delete(SourceText, SourcePos + 1, 2);
        ApplyMarkdownText(SourceText);
        FinishEditAtSource(SourcePos);
        Exit;
      end;
    end;

    if FSelectionCaret = 0 then
      Exit;

    SourcePos := SelectableToSourcePosition(FSelectionCaret);
    SourceText := FMarkdown.Text;
    if (SourcePos > 0) and (SourcePos < Length(SourceText)) then
    begin
      PrevChar := SourceText[SourcePos];
      NextChar := SourceText[SourcePos + 1];
      IsPair := False;
      if (PrevChar = '(') and (NextChar = ')') then IsPair := True
      else if (PrevChar = '[') and (NextChar = ']') then IsPair := True
      else if (PrevChar = '{') and (NextChar = '}') then IsPair := True
      else if (PrevChar = '"') and (NextChar = '"') then IsPair := True
      else if (PrevChar = '''') and (NextChar = '''') then IsPair := True;

      if IsPair then
      begin
        PushUndoState;
        Delete(SourceText, SourcePos, 2);
        ApplyMarkdownText(SourceText);
        FinishEditAtSource(SourcePos - 1);
        Exit;
      end;
    end;

    FSelectionAnchor := FSelectionCaret - 1;
    if (FSelectionCaret >= 2) and
      (((FSelectableText[FSelectionCaret] = #10) and
        (FSelectableText[FSelectionCaret - 1] = #13)) or
       (FSelectableText[FSelectionCaret].IsLowSurrogate and
        FSelectableText[FSelectionCaret - 1].IsHighSurrogate)) then
      FSelectionAnchor := FSelectionCaret - 2;
  end
  else
  begin
    if FSelectionCaret >= Length(FSelectableText) then
      Exit;
    FSelectionAnchor := FSelectionCaret + 1;
    if (FSelectionCaret + 2 <= Length(FSelectableText)) and
      (((FSelectableText[FSelectionCaret + 1] = #13) and
        (FSelectableText[FSelectionCaret + 2] = #10)) or
       (FSelectableText[FSelectionCaret + 1].IsHighSurrogate and
        FSelectableText[FSelectionCaret + 2].IsLowSurrogate)) then
      FSelectionAnchor := FSelectionCaret + 2;
  end;
  InsertTextAtSelection('');
end;

procedure TMarkDownViewer.InsertTextAtSelection(const Value: string);
var
  NewSourceCaret: Integer;
  SelEnd: Integer;
  SelStart: Integer;
  SourceEnd: Integer;
  SourceStart: Integer;
  SourceText: string;
  Temp: Integer;
begin
  if FReadOnly then
    Exit;
  if FSelectableText = '' then
    Repaint;

  SelStart := Min(FSelectionAnchor, FSelectionCaret);
  SelEnd := Max(FSelectionAnchor, FSelectionCaret);
  SourceStart := SelectableToSourcePosition(SelStart);
  SourceEnd := SelectableToSourcePosition(SelEnd);
  if SourceEnd < SourceStart then
  begin
    Temp := SourceStart;
    SourceStart := SourceEnd;
    SourceEnd := Temp;
  end;

  PushUndoState;
  SourceText := FMarkdown.Text;
  Delete(SourceText, SourceStart + 1, SourceEnd - SourceStart);
  Insert(Value, SourceText, SourceStart + 1);
  NewSourceCaret := SourceStart + Length(Value);

  ApplyMarkdownText(SourceText);
  FinishEditAtSource(NewSourceCaret);
end;

// Insert a line break, continuing a list or block quote the caret sits in: the
// bullet/number/quote marker carries to the next line (ordered numbers
// increment); pressing Enter on an empty item clears its marker to leave the
// construct. Plain lines just get a line break.
procedure TMarkDownViewer.InsertNewLine;
var
  OldSourcePos: Integer;
  LineIdx: Integer;
  Line: string;
  Lead: string;
  T: string;
  Content: string;
  Prefix: string;
  I: Integer;
  Num: Integer;
begin
  if HasSelection then
  begin
    InsertTextAtSelection(sLineBreak);
    Exit;
  end;

  OldSourcePos := SelectableToSourcePosition(FSelectionCaret);
  LineIdx := SourcePosToLine(OldSourcePos);
  if (LineIdx < 0) or (LineIdx >= FMarkdown.Count) then
  begin
    InsertTextAtSelection(sLineBreak);
    Exit;
  end;

  Line := FMarkdown[LineIdx];
  T := TMarkDownBlockParser.TrimLeftOnly(Line);
  Lead := Copy(Line, 1, Length(Line) - Length(T));
  Prefix := '';
  Content := '';

  if (Length(T) >= 2) and CharInSet(T[1], ['-', '*', '+']) and (T[2] = ' ') then
  begin
    Content := Copy(T, 3, MaxInt);
    if (Copy(Content, 1, 4) = '[ ] ') or (Copy(Content, 1, 4) = '[x] ') or
      (Copy(Content, 1, 4) = '[X] ') then
    begin
      Content := Copy(Content, 5, MaxInt);
      Prefix := Lead + T[1] + ' [ ] '; // continue as a new unchecked task
    end
    else
      Prefix := Lead + T[1] + ' ';
  end
  else
  begin
    I := 1;
    while (I <= Length(T)) and CharInSet(T[I], ['0'..'9']) do
      Inc(I);
    if (I > 1) and (I < Length(T)) and (T[I] = '.') and (T[I + 1] = ' ') then
    begin
      Num := StrToIntDef(Copy(T, 1, I - 1), 0);
      Content := Copy(T, I + 2, MaxInt);
      Prefix := Lead + IntToStr(Num + 1) + '. ';
    end;
    // Block quotes merge consecutive '>' lines into one block, so the continued
    // empty line has no caret anchor; leave them to a plain line break.
  end;

  if Prefix = '' then
  begin
    InsertTextAtSelection(sLineBreak);
    Exit;
  end;

  if Trim(Content) = '' then
  begin
    // Empty item: clear the marker to leave the construct.
    PushUndoState;
    ApplyMarkdownLine(LineIdx, '');
    FinishEditAtSource(LineStartSourcePos(LineIdx));
    Exit;
  end;

  InsertTextAtSelection(sLineBreak + Prefix);
end;

// Wrap the selection in AMarker (e.g. '**' for bold, '*' for italic), or unwrap
// it when it is already wrapped. With no selection, insert an empty pair and
// place the caret between the markers ready to type. The selection is preserved
// over the formatted text so the shortcut can be pressed again to toggle off.
procedure TMarkDownViewer.ToggleInlineFormat(const AMarker: string);
var
  SelStart: Integer;
  SelEnd: Integer;
  SourceStart: Integer;
  SourceEnd: Integer;
  Temp: Integer;
  MarkerLen: Integer;
  SourceText: string;
  Selected: string;
  NewSelStart: Integer;
  NewSelEnd: Integer;
begin
  if FReadOnly then
    Exit;
  if FSelectableText = '' then
    Repaint;
  MarkerLen := Length(AMarker);

  SelStart := Min(FSelectionAnchor, FSelectionCaret);
  SelEnd := Max(FSelectionAnchor, FSelectionCaret);
  SourceStart := SelectableToSourcePosition(SelStart);
  SourceEnd := SelectableToSourcePosition(SelEnd);
  if SourceEnd < SourceStart then
  begin
    Temp := SourceStart;
    SourceStart := SourceEnd;
    SourceEnd := Temp;
  end;

  PushUndoState;
  SourceText := FMarkdown.Text;

  // Markers must hug the content (emphasis cannot have whitespace just inside
  // it), so shrink the range past any selected leading/trailing whitespace -
  // this also drops the trailing line break a select-all picks up.
  while (SourceStart < SourceEnd) and
    CharInSet(SourceText[SourceStart + 1], [' ', #9, #13, #10]) do
    Inc(SourceStart);
  while (SourceEnd > SourceStart) and
    CharInSet(SourceText[SourceEnd], [' ', #9, #13, #10]) do
    Dec(SourceEnd);

  // Mapping the selection edges can land just inside the markers (a select-all
  // reaches past the closing pair via the trailing break). Pull any markers
  // that fall inside the range out of it, so the range bounds the content with
  // its markers (if any) just outside - making the toggle decision symmetric.
  if SourceStart < SourceEnd then
  begin
    if Copy(SourceText, SourceStart + 1, MarkerLen) = AMarker then
      Inc(SourceStart, MarkerLen);
    if (SourceEnd - MarkerLen >= SourceStart) and
      (Copy(SourceText, SourceEnd - MarkerLen + 1, MarkerLen) = AMarker) then
      Dec(SourceEnd, MarkerLen);
  end;

  if SourceStart = SourceEnd then
  begin
    Insert(AMarker + AMarker, SourceText, SourceStart + 1);
    NewSelStart := SourceStart + MarkerLen;
    NewSelEnd := NewSelStart;
  end
  else if (SourceStart >= MarkerLen) and
    (SourceEnd + MarkerLen <= Length(SourceText)) and
    (Copy(SourceText, SourceStart - MarkerLen + 1, MarkerLen) = AMarker) and
    (Copy(SourceText, SourceEnd + 1, MarkerLen) = AMarker) then
  begin
    // The selection is already wrapped (the markers sit just outside it, since
    // they are not part of the rendered text) - remove them to toggle off.
    Delete(SourceText, SourceEnd + 1, MarkerLen);
    Delete(SourceText, SourceStart - MarkerLen + 1, MarkerLen);
    NewSelStart := SourceStart - MarkerLen;
    NewSelEnd := SourceEnd - MarkerLen;
  end
  else
  begin
    Selected := Copy(SourceText, SourceStart + 1, SourceEnd - SourceStart);
    Delete(SourceText, SourceStart + 1, SourceEnd - SourceStart);
    Insert(AMarker + Selected + AMarker, SourceText, SourceStart + 1);
    NewSelStart := SourceStart + MarkerLen;
    NewSelEnd := NewSelStart + Length(Selected);
  end;

  ApplyMarkdownText(SourceText);
  Repaint;
  FSelectionAnchor := SourceToSelectablePosition(NewSelStart);
  FSelectionCaret := SourceToSelectablePosition(NewSelEnd);
  FDesiredCaretX := -1;
  ScrollCaretIntoView;
  Invalidate;
end;

// Surround the selection with AOpen/AClose (auto-pairing brackets and quotes),
// keeping the selection over the wrapped content. Returns False (and does
// nothing) when there is no usable selection, so the caller inserts the
// character literally instead.
function TMarkDownViewer.WrapSelectionWith(const AOpen, AClose: string): Boolean;
var
  SelStart: Integer;
  SelEnd: Integer;
  SourceStart: Integer;
  SourceEnd: Integer;
  Temp: Integer;
  SourceText: string;
  Selected: string;
begin
  Result := False;
  if FReadOnly or not HasSelection then
    Exit;

  SelStart := Min(FSelectionAnchor, FSelectionCaret);
  SelEnd := Max(FSelectionAnchor, FSelectionCaret);
  SourceStart := SelectableToSourcePosition(SelStart);
  SourceEnd := SelectableToSourcePosition(SelEnd);
  if SourceEnd < SourceStart then
  begin
    Temp := SourceStart;
    SourceStart := SourceEnd;
    SourceEnd := Temp;
  end;

  SourceText := FMarkdown.Text;
  while (SourceStart < SourceEnd) and
    CharInSet(SourceText[SourceStart + 1], [' ', #9, #13, #10]) do
    Inc(SourceStart);
  while (SourceEnd > SourceStart) and
    CharInSet(SourceText[SourceEnd], [' ', #9, #13, #10]) do
    Dec(SourceEnd);
  if SourceStart = SourceEnd then
    Exit;

  PushUndoState;
  Selected := Copy(SourceText, SourceStart + 1, SourceEnd - SourceStart);
  Delete(SourceText, SourceStart + 1, SourceEnd - SourceStart);
  Insert(AOpen + Selected + AClose, SourceText, SourceStart + 1);

  ApplyMarkdownText(SourceText);
  Repaint;
  FSelectionAnchor := SourceToSelectablePosition(SourceStart + Length(AOpen));
  FSelectionCaret := SourceToSelectablePosition(
    SourceStart + Length(AOpen) + Length(Selected));
  FDesiredCaretX := -1;
  ScrollCaretIntoView;
  Invalidate;
  Result := True;
end;

// Move the caret to NewPosition, dragging the selection anchor with it unless
// the selection is being extended.
procedure TMarkDownViewer.SetCaret(NewPosition: Integer;
  ExtendSelection: Boolean);
begin
  FSelectionCaret := NewPosition;
  if not ExtendSelection then
    FSelectionAnchor := NewPosition;
end;

// Before a plain (non-extending) vertical/page move, drop an existing
// selection onto the edge the caret is moving away from.
procedure TMarkDownViewer.CollapseSelectionToEdge(Direction: Integer;
  ExtendSelection: Boolean);
begin
  if ExtendSelection or not HasSelection then
    Exit;
  if Direction < 0 then
    FSelectionCaret := Min(FSelectionAnchor, FSelectionCaret)
  else
    FSelectionCaret := Max(FSelectionAnchor, FSelectionCaret);
  FSelectionAnchor := FSelectionCaret;
end;

// The text run the caret currently sits in, preferring the run that starts at
// the caret when it lands on a boundary. Callers must have at least one run.
function TMarkDownViewer.RunContainingCaret: TMarkDownTextRun;
var
  I: Integer;
  Run: TMarkDownTextRun;
begin
  Result := FTextRuns.Last;
  for I := 0 to FTextRuns.Count - 1 do
  begin
    Run := FTextRuns[I];
    if (FSelectionCaret >= Run.StartIndex) and
      (FSelectionCaret <= Run.StartIndex + Length(Run.Text)) then
    begin
      Result := Run;
      if FSelectionCaret = Run.StartIndex then
        Break;
    end;
  end;
end;

// Lock in the pixel column the caret should track across vertical moves, based
// on its position within ARun. No-op once a desired column is already set.
procedure TMarkDownViewer.EnsureDesiredCaretX(const ARun: TMarkDownTextRun);
var
  LocalPosition: Integer;
begin
  if FDesiredCaretX >= 0 then
    Exit;
  Canvas.Font.Assign(Font);
  Canvas.Font.Name := ARun.FontName;
  Canvas.Font.Size := ARun.FontSize;
  Canvas.Font.Style := ARun.FontStyle;
  LocalPosition := EnsureRange(FSelectionCaret - ARun.StartIndex,
    0, Length(ARun.Text));
  FDesiredCaretX := ARun.Rect.Left +
    Canvas.TextWidth(Copy(ARun.Text, 1, LocalPosition));
end;

procedure TMarkDownViewer.MoveCaret(Delta: Integer; ExtendSelection: Boolean);
var
  NewPosition: Integer;
begin
  if FSelectableText = '' then
    Repaint;
  if not ExtendSelection and HasSelection then
  begin
    if Delta < 0 then
      NewPosition := Min(FSelectionAnchor, FSelectionCaret)
    else
      NewPosition := Max(FSelectionAnchor, FSelectionCaret);
  end
  else
    NewPosition := EnsureRange(FSelectionCaret + Delta, 0,
      Length(FSelectableText));

  if (NewPosition > 0) and (NewPosition < Length(FSelectableText)) and
    (FSelectableText[NewPosition] = #13) and
    (FSelectableText[NewPosition + 1] = #10) then
  begin
    if Delta < 0 then
      Dec(NewPosition)
    else
      Inc(NewPosition);
  end;

  SetCaret(NewPosition, ExtendSelection);
  FDesiredCaretX := -1;
  ScrollCaretIntoView;
  Invalidate;
end;

// The selectable position a word-wise move from the caret lands on: forward to
// the start of the next word (over the rest of this word then whitespace), or
// back to the start of the current/previous word.
function TMarkDownViewer.WordTarget(Direction: Integer): Integer;
  function IsBreak(Index: Integer): Boolean;
  begin
    Result := (Index < 1) or (Index > Length(FSelectableText)) or
      CharInSet(FSelectableText[Index], [' ', #9, #13, #10]);
  end;
begin
  Result := EnsureRange(FSelectionCaret, 0, Length(FSelectableText));
  if Direction > 0 then
  begin
    while (Result < Length(FSelectableText)) and not IsBreak(Result + 1) do
      Inc(Result);
    while (Result < Length(FSelectableText)) and IsBreak(Result + 1) do
      Inc(Result);
  end
  else
  begin
    while (Result > 0) and IsBreak(Result) do
      Dec(Result);
    while (Result > 0) and not IsBreak(Result) do
      Dec(Result);
  end;
end;

procedure TMarkDownViewer.MoveCaretWord(Direction: Integer;
  ExtendSelection: Boolean);
begin
  if FSelectableText = '' then
    Repaint;
  SetCaret(WordTarget(Direction), ExtendSelection);
  FDesiredCaretX := -1;
  ScrollCaretIntoView;
  Invalidate;
end;

procedure TMarkDownViewer.DeleteWord(Backwards: Boolean);
begin
  if FReadOnly then
    Exit;
  if FSelectableText = '' then
    Repaint;
  if HasSelection then
  begin
    InsertTextAtSelection('');
    Exit;
  end;
  if Backwards then
    FSelectionAnchor := WordTarget(-1)
  else
    FSelectionAnchor := WordTarget(1);
  if FSelectionAnchor = FSelectionCaret then
    Exit;
  InsertTextAtSelection('');
end;

procedure TMarkDownViewer.MoveCaretDocumentBoundary(ToEnd,
  ExtendSelection: Boolean);
var
  NewPosition: Integer;
begin
  if FSelectableText = '' then
    Repaint;
  if ToEnd then
  begin
    if FTextRuns.Count > 0 then
      NewPosition := FTextRuns.Last.StartIndex +
        Length(FTextRuns.Last.Text)
    else
      NewPosition := Length(FSelectableText);
  end
  else
    NewPosition := 0;

  SetCaret(NewPosition, ExtendSelection);
  FDesiredCaretX := -1;
  if ToEnd then
    SetScrollPosition(FContentHeight)
  else
    SetScrollPosition(0);
end;

procedure TMarkDownViewer.MoveCaretLineBoundary(ToEnd,
  ExtendSelection: Boolean);
var
  CurrentRun: TMarkDownTextRun;
  CurrentTop: Integer;
  I: Integer;
  NewPosition: Integer;
begin
  if FSelectableText = '' then
    Repaint;
  if FTextRuns.Count = 0 then
    Exit;

  CurrentRun := RunContainingCaret;

  CurrentTop := CurrentRun.Rect.Top;
  if ToEnd then
  begin
    NewPosition := CurrentRun.StartIndex + Length(CurrentRun.Text);
    for I := 0 to FTextRuns.Count - 1 do
      if FTextRuns[I].Rect.Top = CurrentTop then
        NewPosition := Max(NewPosition, FTextRuns[I].StartIndex +
          Length(FTextRuns[I].Text));
  end
  else
  begin
    NewPosition := CurrentRun.StartIndex;
    for I := 0 to FTextRuns.Count - 1 do
      if FTextRuns[I].Rect.Top = CurrentTop then
        NewPosition := Min(NewPosition, FTextRuns[I].StartIndex);
  end;

  SetCaret(NewPosition, ExtendSelection);
  FDesiredCaretX := -1;
  Invalidate;
end;

procedure TMarkDownViewer.MoveCaretPage(Direction: Integer;
  ExtendSelection: Boolean);
var
  CurrentRun: TMarkDownTextRun;
  CurrentTop: Integer;
  DesiredTop: Integer;
  I: Integer;
  NewPosition: Integer;
  Run: TMarkDownTextRun;
  TargetBottom: Integer;
  TargetDistance: Integer;
  TargetTop: Integer;
begin
  if FSelectableText = '' then
    Repaint;
  if FTextRuns.Count = 0 then
    Exit;

  CollapseSelectionToEdge(Direction, ExtendSelection);

  CurrentRun := RunContainingCaret;

  EnsureDesiredCaretX(CurrentRun);

  CurrentTop := CurrentRun.Rect.Top;
  DesiredTop := CurrentTop + (Direction * Max(1, ClientHeight -
    CurrentRun.Rect.Height));
  TargetTop := CurrentTop;
  TargetDistance := High(Integer);
  for I := 0 to FTextRuns.Count - 1 do
  begin
    Run := FTextRuns[I];
    if ((Direction < 0) and (Run.Rect.Top >= CurrentTop)) or
      ((Direction > 0) and (Run.Rect.Top <= CurrentTop)) then
      Continue;
    if Abs(Run.Rect.Top - DesiredTop) < TargetDistance then
    begin
      TargetDistance := Abs(Run.Rect.Top - DesiredTop);
      TargetTop := Run.Rect.Top;
    end;
  end;
  if TargetTop = CurrentTop then
    Exit;

  TargetBottom := TargetTop;
  for I := 0 to FTextRuns.Count - 1 do
    if FTextRuns[I].Rect.Top = TargetTop then
      TargetBottom := Max(TargetBottom, FTextRuns[I].Rect.Bottom);
  NewPosition := HitTestTextPosition(FDesiredCaretX,
    TargetTop + ((TargetBottom - TargetTop) div 2));

  SetCaret(NewPosition, ExtendSelection);
  SetScrollPosition(FScrollPos + TargetTop - CurrentTop);
end;

procedure TMarkDownViewer.MoveCaretVertical(Direction: Integer;
  ExtendSelection: Boolean);
var
  CurrentRun: TMarkDownTextRun;
  CurrentTop: Integer;
  I: Integer;
  NewPosition: Integer;
  Run: TMarkDownTextRun;
  TargetBottom: Integer;
  TargetTop: Integer;
  TargetY: Integer;
begin
  if FSelectableText = '' then
    Repaint;
  if FTextRuns.Count = 0 then
    Exit;

  CollapseSelectionToEdge(Direction, ExtendSelection);

  CurrentRun := FTextRuns.Last;
  for I := 0 to FTextRuns.Count - 1 do
  begin
    Run := FTextRuns[I];
    if FSelectionCaret <= Run.StartIndex + Length(Run.Text) then
    begin
      CurrentRun := Run;
      Break;
    end;
  end;

  EnsureDesiredCaretX(CurrentRun);

  CurrentTop := CurrentRun.Rect.Top;
  if Direction < 0 then
  begin
    TargetTop := Low(Integer);
    for I := 0 to FTextRuns.Count - 1 do
      if (FTextRuns[I].Rect.Top < CurrentTop) and
        (FTextRuns[I].Rect.Top > TargetTop) then
        TargetTop := FTextRuns[I].Rect.Top;
    if TargetTop = Low(Integer) then
      Exit;
  end
  else
  begin
    TargetTop := High(Integer);
    for I := 0 to FTextRuns.Count - 1 do
      if (FTextRuns[I].Rect.Top > CurrentTop) and
        (FTextRuns[I].Rect.Top < TargetTop) then
        TargetTop := FTextRuns[I].Rect.Top;
    if TargetTop = High(Integer) then
      Exit;
  end;

  TargetBottom := TargetTop;
  for I := 0 to FTextRuns.Count - 1 do
    if FTextRuns[I].Rect.Top = TargetTop then
      TargetBottom := Max(TargetBottom, FTextRuns[I].Rect.Bottom);
  TargetY := TargetTop + ((TargetBottom - TargetTop) div 2);
  NewPosition := HitTestTextPosition(FDesiredCaretX, TargetY);

  SetCaret(NewPosition, ExtendSelection);

  if TargetTop < 0 then
    SetScrollPosition(FScrollPos + TargetTop - MarkdownPadding)
  else if TargetBottom > ClientHeight then
    SetScrollPosition(FScrollPos + TargetBottom - ClientHeight +
      MarkdownPadding)
  else
    Invalidate;
end;

procedure TMarkDownViewer.AppendMarkdownText(const Value: string);
var
  Block: TMarkDownBlock;
  I: Integer;
  NewBlocks: TMarkDownBlockList;
  ReparseLine: Integer;
  SegmentStart: Integer;
  StartIndex: Integer;
  UpdateRect: TRect;
  OldReferences: string;
begin
  if Value = '' then
    Exit;

  StartIndex := 1;
  if FAppendEndedWithCR and (Value[1] = #10) then
    StartIndex := 2;
  FAppendEndedWithCR := Value[Length(Value)] = #13;
  if StartIndex > Length(Value) then
    Exit;

  if FBlocks.Count > 0 then
    ReparseLine := FBlocks.Last.SourceStartLine
  else
    ReparseLine := 0;

  FUpdatingMarkdown := True;
  FMarkdown.BeginUpdate;
  try
    if FMarkdown.Count = 0 then
      FMarkdown.Add('');

    SegmentStart := StartIndex;
    I := StartIndex;
    while I <= Length(Value) do
    begin
      if CharInSet(Value[I], [#10, #13]) then
      begin
        FMarkdown[FMarkdown.Count - 1] := FMarkdown[FMarkdown.Count - 1] +
          Copy(Value, SegmentStart, I - SegmentStart);
        if (Value[I] = #13) and (I < Length(Value)) and (Value[I + 1] = #10) then
          Inc(I);
        FMarkdown.Add('');
        SegmentStart := I + 1;
      end;
      Inc(I);
    end;

    if SegmentStart <= Length(Value) then
      FMarkdown[FMarkdown.Count - 1] := FMarkdown[FMarkdown.Count - 1] +
        Copy(Value, SegmentStart, MaxInt);
  finally
    FMarkdown.EndUpdate;
    FUpdatingMarkdown := False;
  end;

  OldReferences := FLinkReferences.Text;
  TMarkDownBlockParser.ExtractLinkReferences(FMarkdown, FLinkReferences);
  if FLinkReferences.Text <> OldReferences then
    ClearInlineTokenCaches;
  while (FBlocks.Count > 0) and (FBlocks.Last.SourceStartLine >= ReparseLine) do
    FBlocks.Delete(FBlocks.Count - 1);

  NewBlocks := TMarkDownBlockParser.ParseBlocks(FMarkdown, ReparseLine);
  try
    while NewBlocks.Count > 0 do
    begin
      Block := NewBlocks.Extract(NewBlocks[0]);
      FBlocks.Add(Block);
    end;
  finally
    NewBlocks.Free;
  end;

  FSelectionAnchor := 0;
  FSelectionCaret := 0;
  FSelectableText := '';
  FTextRuns.Clear;
  FCopyChunks.Clear;
  if HandleAllocated then
  begin
    UpdateRect := Rect(0, EnsureRange(FLastBlockTop, 0, Max(0, ClientHeight - 1)),
      ClientWidth, ClientHeight);
    Winapi.Windows.InvalidateRect(Handle, @UpdateRect, False);
  end
  else
    Invalidate;
  UpdateScrollBar;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TMarkDownViewer.LoadFromFile(const FileName: string);
begin
  FBasePath := ExtractFilePath(FileName);
  FMarkdown.LoadFromFile(FileName);
end;

procedure TMarkDownViewer.MarkdownChanged(Sender: TObject);
var
  Blocks: TMarkDownBlockList;
begin
  if FUpdatingMarkdown then
    Exit;

  if not FApplyingEdit then
  begin
    FUndoStack.Clear;
    FRedoStack.Clear;
  end;
  FAppendEndedWithCR := False;
  TMarkDownBlockParser.ExtractLinkReferences(FMarkdown, FLinkReferences);
  Blocks := TMarkDownBlockParser.ParseBlocks(FMarkdown);
  FBlocks.Free;
  FBlocks := Blocks;
  FScrollPos := 0;
  FSelectionAnchor := 0;
  FSelectionCaret := 0;
  FSelectableText := '';
  if FTextRuns <> nil then
    FTextRuns.Clear;
  if FCopyChunks <> nil then
    FCopyChunks.Clear;
  Invalidate;
  UpdateScrollBar;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TMarkDownViewer.GetCodeBlockRect(ABlock: TMarkDownBlock): TRect;
var
  ContentWidth: Integer;
begin
  ContentWidth := Max(10, ClientWidth - (MarkdownPadding * 2) - GetSystemMetrics(SM_CXVSCROLL));
  Result := Rect(
    MarkdownPadding,
    ABlock.LayoutTop - FScrollPos + 2,
    MarkdownPadding + ContentWidth,
    ABlock.LayoutTop - FScrollPos + ABlock.LayoutHeight - ParagraphSpacing
  );
end;

function TMarkDownViewer.GetCodeBlockCopyBtnRect(ABlock: TMarkDownBlock): TRect;
var
  BlockRect: TRect;
  BtnWidth, BtnHeight: Integer;
  BtnText: string;
  SavedFont: TFont;
begin
  BlockRect := GetCodeBlockRect(ABlock);
  
  SavedFont := TFont.Create;
  try
    SavedFont.Assign(Canvas.Font);
    Canvas.Font.Assign(Font);
    Canvas.Font.Size := 8;
    Canvas.Font.Style := [];
    
    BtnText := 'Copy';
    if (FCopiedBlock = ABlock) and (GetTickCount - FCopiedTicks < 1500) then
      BtnText := 'Copied!';
      
    BtnWidth := Canvas.TextWidth(BtnText) + 12;
    BtnHeight := Canvas.TextHeight(BtnText) + 6;
    
    Result := Rect(
      BlockRect.Right - BtnWidth - 6,
      BlockRect.Top + 6,
      BlockRect.Right - 6,
      BlockRect.Top + 6 + BtnHeight
    );
  finally
    Canvas.Font.Assign(SavedFont);
    SavedFont.Free;
  end;
end;

function TMarkDownViewer.GetEffectiveCodeButtonColor: TColor;
begin
  if IsBackgroundDark then
    Result := RGB(60, 60, 60)
  else
    Result := RGB(240, 240, 240);
end;

function TMarkDownViewer.GetEffectiveCodeButtonHoverColor: TColor;
begin
  if IsBackgroundDark then
    Result := RGB(80, 80, 80)
  else
    Result := RGB(220, 220, 220);
end;

function TMarkDownViewer.GetEffectiveCodeButtonBorderColor: TColor;
begin
  if IsBackgroundDark then
    Result := RGB(80, 80, 80)
  else
    Result := RGB(200, 200, 200);
end;

function TMarkDownViewer.GetEffectiveCodeButtonHoverBorderColor: TColor;
begin
  if IsBackgroundDark then
    Result := RGB(100, 100, 100)
  else
    Result := RGB(170, 170, 170);
end;

function TMarkDownViewer.GetEffectiveCodeButtonTextColor: TColor;
begin
  if IsBackgroundDark then
    Result := RGB(180, 180, 180)
  else
    Result := RGB(100, 100, 100);
end;

function TMarkDownViewer.GetEffectiveCodeButtonHoverTextColor: TColor;
begin
  if IsBackgroundDark then
    Result := RGB(240, 240, 240)
  else
    Result := RGB(60, 60, 60);
end;

function TMarkDownViewer.GetCodeBlockCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FBlocks.Count - 1 do
    if FBlocks[I].Kind = bkCodeBlock then
      Inc(Result);
end;

function TMarkDownViewer.GetCodeBlockRect(Index: Integer): TRect;
var
  I, Count: Integer;
begin
  Count := 0;
  for I := 0 to FBlocks.Count - 1 do
    if FBlocks[I].Kind = bkCodeBlock then
    begin
      if Count = Index then
        Exit(GetCodeBlockRect(FBlocks[I]));
      Inc(Count);
    end;
  Result := Rect(0, 0, 0, 0);
end;

function TMarkDownViewer.GetCodeBlockCopyBtnRect(Index: Integer): TRect;
var
  I, Count: Integer;
begin
  Count := 0;
  for I := 0 to FBlocks.Count - 1 do
    if FBlocks[I].Kind = bkCodeBlock then
    begin
      if Count = Index then
        Exit(GetCodeBlockCopyBtnRect(FBlocks[I]));
      Inc(Count);
    end;
  Result := Rect(0, 0, 0, 0);
end;

function TMarkDownViewer.IsCopyButtonHovered: Boolean;
begin
  Result := FHoveredCopyButton;
end;

procedure TMarkDownViewer.WMTimer(var Message: TWMTimer);
begin
  if Message.TimerID = 1 then
  begin
    if HandleAllocated then
      KillTimer(Handle, 1);
    Invalidate;
  end;
end;

procedure TMarkDownViewer.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if (FHoveredCodeBlock <> nil) or FHoveredCopyButton then
  begin
    FHoveredCodeBlock := nil;
    FHoveredCopyButton := False;
    Invalidate;
  end;
end;

procedure TMarkDownViewer.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Position: Integer;
begin
  inherited;
  if CanFocus then
    SetFocus;
  if Button <> mbLeft then
    Exit;

  if (FHoveredCodeBlock <> nil) and FHoveredCopyButton then
  begin
    FSelecting := False;
    Exit;
  end;

  Position := HitTestTextPosition(X, Y);
  FDesiredCaretX := -1;
  if not (ssShift in Shift) then
    FSelectionAnchor := Position;
  FSelectionCaret := Position;
  FSelecting := True;
  MouseCapture := True;
  Invalidate;
end;

procedure TMarkDownViewer.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
  IsLink: Boolean;
  IsTaskBox: Boolean;
  NewHoveredBlock: TMarkDownBlock;
  NewHoveredBtn: Boolean;
  R: TRect;
  BtnRect: TRect;
begin
  inherited;
  if FSelecting then
  begin
    if Y < 0 then
      SetScrollPosition(FScrollPos + Y)
    else if Y > ClientHeight then
      SetScrollPosition(FScrollPos + (Y - ClientHeight));
    FSelectionCaret := HitTestTextPosition(X, Y);
    Invalidate;
  end;

  NewHoveredBlock := nil;
  NewHoveredBtn := False;
  for I := 0 to FBlocks.Count - 1 do
  begin
    if FBlocks[I].Kind = bkCodeBlock then
    begin
      R := GetCodeBlockRect(FBlocks[I]);
      if PtInRect(R, Point(X, Y)) then
      begin
        NewHoveredBlock := FBlocks[I];
        BtnRect := GetCodeBlockCopyBtnRect(NewHoveredBlock);
        if PtInRect(BtnRect, Point(X, Y)) then
          NewHoveredBtn := True;
        Break;
      end;
    end;
  end;

  if (FHoveredCodeBlock <> NewHoveredBlock) or (FHoveredCopyButton <> NewHoveredBtn) then
  begin
    FHoveredCodeBlock := NewHoveredBlock;
    FHoveredCopyButton := NewHoveredBtn;
    Invalidate;
  end;

  IsLink := False;
  if FLinkHits <> nil then
    for I := 0 to FLinkHits.Count - 1 do
      if PtInRect(FLinkHits[I].Rect, Point(X, Y)) then
      begin
        IsLink := True;
        Break;
      end;

  IsTaskBox := False;
  if FAllowTaskToggle and (FTaskHits <> nil) then
    for I := 0 to FTaskHits.Count - 1 do
      if PtInRect(FTaskHits[I].Rect, Point(X, Y)) then
      begin
        IsTaskBox := True;
        Break;
      end;

  if FHoveredCopyButton or IsTaskBox or (IsLink and (FReadOnly or (ssCtrl in Shift))) then
    Cursor := crHandPoint
  else
    if not FReadOnly then
      Cursor := crIBeam
    else
      Cursor := crDefault;
end;

procedure TMarkDownViewer.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
  Hit: TMarkDownLinkHit;
begin
  inherited;
  if Button <> mbLeft then
    Exit;

  if FHoveredCopyButton and (FHoveredCodeBlock <> nil) then
  begin
    TrySetClipboardText(FHoveredCodeBlock.Text);
    FCopiedTicks := GetTickCount;
    FCopiedBlock := FHoveredCodeBlock;
    if HandleAllocated then
      SetTimer(Handle, 1, 1500, nil);
    Invalidate;
    FSelecting := False;
    MouseCapture := False;
    Exit;
  end;

  if FSelecting then
  begin
    FSelectionCaret := HitTestTextPosition(X, Y);
    FSelecting := False;
    MouseCapture := False;
    Invalidate;
  end;

  if HasSelection then
    Exit;

  // Task checkboxes toggle on a plain click whether or not the view is editable.
  if FAllowTaskToggle and (FTaskHits <> nil) then
    for I := 0 to FTaskHits.Count - 1 do
      if PtInRect(FTaskHits[I].Rect, Point(X, Y)) then
      begin
        ToggleTaskAtLine(FTaskHits[I].SourceLine);
        Exit;
      end;

  if not FReadOnly and not (ssCtrl in Shift) then
    Exit;

  if FLinkHits <> nil then
    for I := 0 to FLinkHits.Count - 1 do
    begin
      Hit := FLinkHits[I];
      if PtInRect(Hit.Rect, Point(X, Y)) then
      begin
        if Assigned(FOnLinkClick) then
          FOnLinkClick(Self, Hit.Url)
        else if IsSafeLinkUrl(Hit.Url) then
          ShellExecute(Handle, 'open', PChar(Hit.Url), nil, nil, SW_SHOWNORMAL);
        Break;
      end;
    end;
end;

// Returns Map[Start0 .. Start0+Count] (Count+1 entries), or empty when Map is
// empty or the range falls outside it - so an unmapped token degrades to no
// source instead of slicing garbage.
function TMarkDownViewer.SliceMap(const Map: TArray<Integer>;
  Start0, Count: Integer): TArray<Integer>;
var
  K: Integer;
begin
  if (Length(Map) = 0) or (Start0 < 0) or
    (Start0 + Count + 1 > Length(Map)) then
    Exit(nil);
  SetLength(Result, Count + 1);
  for K := 0 to Count do
    Result[K] := Map[Start0 + K];
end;

// The document offset at Index in Map, or -1 when out of range - the source
// position of a line break, used when emitting break chunks.
function TMarkDownViewer.SliceMapValue(const Map: TArray<Integer>;
  Index: Integer): Integer;
begin
  if (Index >= 0) and (Index < Length(Map)) then
    Result := Map[Index]
  else
    Result := -1;
end;

// A chunk's per-character source map: the exact map the inline parser (or a
// block/code/table render path) hands down when it lines up with the text,
// otherwise empty - text with no source, e.g. a wrap-only break.
function TMarkDownViewer.ResolveChunkSourceMap(const AText: string;
  const AProvided: TArray<Integer>; AHasSource: Boolean): TArray<Integer>;
begin
  if AHasSource and (Length(AProvided) = Length(AText) + 1) then
    Result := AProvided
  else
    Result := nil;
end;

procedure TMarkDownViewer.AddCopyChunk(TextStart: Integer;
  const ASourceMap: TArray<Integer>; const AText, AMarkdownText: string);
var
  Chunk: TMarkDownCopyChunk;
begin
  if AText = '' then
    Exit;

  Chunk.StartIndex := TextStart;
  Chunk.SourceMap := ASourceMap;
  Chunk.Text := AText;
  if AMarkdownText <> '' then
    Chunk.MarkdownText := AMarkdownText
  else
    Chunk.MarkdownText := AText;
  FCopyChunks.Add(Chunk);
end;

function TMarkDownViewer.AddSelectableRun(const ARect: TRect;
  const AText: string; const ASourceMap: TArray<Integer>;
  const AMarkdownText: string): Integer;
var
  Run: TMarkDownTextRun;
  Map: TArray<Integer>;
begin
  Result := Length(FSelectableText);
  if AText = '' then
    Exit;

  Map := ResolveChunkSourceMap(AText, ASourceMap, True);
  Run.Rect := ARect;
  Run.FontName := Canvas.Font.Name;
  Run.FontSize := Canvas.Font.Size;
  Run.FontStyle := Canvas.Font.Style;
  if AMarkdownText <> '' then
    Run.MarkdownText := AMarkdownText
  else
    Run.MarkdownText := AText;
  Run.StartIndex := Result;
  if Length(Map) > 0 then
    Run.SourceStartIndex := Map[0]
  else
    Run.SourceStartIndex := -1;
  Run.Text := AText;
  FTextRuns.Add(Run);
  FSelectableText := FSelectableText + AText;
  AddCopyChunk(Result, Map, AText, AMarkdownText);
end;

procedure TMarkDownViewer.AddSelectableText(const AText: string;
  const AMarkdownText: string; AHasSource: Boolean;
  const ASourceMap: TArray<Integer>);
var
  TextStart: Integer;
begin
  if AText = '' then
    Exit;

  TextStart := Length(FSelectableText);
  FSelectableText := FSelectableText + AText;
  AddCopyChunk(TextStart, ResolveChunkSourceMap(AText, ASourceMap, AHasSource),
    AText, AMarkdownText);
end;

// AHasSource=False marks breaks that exist only in the rendered layout (word
// wrap, table cell separators) and carry no source. A break between blocks or
// table rows passes ASourceStart - the document offset of the line break it
// stands for - so it maps exactly without the FindSourceStart heuristic.
procedure TMarkDownViewer.AddSelectableBreak(AHasSource: Boolean;
  ASourceStart: Integer; AForce: Boolean);
var
  Map: TArray<Integer>;
  K: Integer;
begin
  if FSelectableText = '' then
    Exit;
  // AForce keeps a break that would otherwise collapse onto the previous one,
  // so an empty block (e.g. a freshly continued list item) keeps a distinct
  // selectable position the caret can occupy.
  if (not AForce) and EndsText(sLineBreak, FSelectableText) then
    Exit;
  if ASourceStart >= 0 then
  begin
    SetLength(Map, Length(sLineBreak) + 1);
    for K := 0 to Length(sLineBreak) do
      Map[K] := ASourceStart + K;
    AddSelectableText(sLineBreak, '', True, Map);
  end
  else
    AddSelectableText(sLineBreak, '', AHasSource);
end;

procedure TMarkDownViewer.DrawCaret;
var
  CaretPosition: Integer;
  I: Integer;
  Run: TMarkDownTextRun;
  X: Integer;
begin
  if FReadOnly or not Focused or HasSelection or
    (FTextRuns.Count = 0) then
    Exit;

  CaretPosition := EnsureRange(FSelectionCaret, 0,
    Length(FSelectableText));
  Run := FTextRuns.Last;
  for I := 0 to FTextRuns.Count - 1 do
  begin
    Run := FTextRuns[I];
    if CaretPosition <= Run.StartIndex + Length(Run.Text) then
      Break;
  end;

  Canvas.Font.Assign(Font);
  Canvas.Font.Name := Run.FontName;
  Canvas.Font.Size := Run.FontSize;
  Canvas.Font.Style := Run.FontStyle;
  X := Run.Rect.Left + Canvas.TextWidth(Copy(Run.Text, 1,
    EnsureRange(CaretPosition - Run.StartIndex, 0, Length(Run.Text))));
  Canvas.Pen.Color := GetEffectiveTextColor;
  Canvas.MoveTo(X, Run.Rect.Top + 1);
  Canvas.LineTo(X, Run.Rect.Bottom - 1);
end;

// The current selection as a [SelStart, SelEnd) range over the selectable
// text; False (with zeroed bounds) when there is no selection.
function TMarkDownViewer.SelectionRange(out SelStart, SelEnd: Integer): Boolean;
begin
  Result := HasSelection;
  if Result then
  begin
    SelStart := Min(FSelectionAnchor, FSelectionCaret);
    SelEnd := Max(FSelectionAnchor, FSelectionCaret);
  end
  else
  begin
    SelStart := 0;
    SelEnd := 0;
  end;
end;

// Paint the selection highlight behind whatever part of AText (a run starting
// at selectable index TextStart) falls inside the selection.
procedure TMarkDownViewer.DrawSelectionBackground(const AText: string;
  TextX, TextY, TextHeight, TextStart: Integer);
var
  SelStart: Integer;
  SelEnd: Integer;
  LocalStart: Integer;
  LocalEnd: Integer;
  HighlightRect: TRect;
  OldColor: TColor;
  OldStyle: TBrushStyle;
begin
  if not SelectionRange(SelStart, SelEnd) then
    Exit;

  LocalStart := Max(0, SelStart - TextStart);
  LocalEnd := Min(Length(AText), SelEnd - TextStart);
  if LocalStart >= LocalEnd then
    Exit;

  HighlightRect := Rect(
    TextX + Canvas.TextWidth(Copy(AText, 1, LocalStart)),
    TextY,
    TextX + Canvas.TextWidth(Copy(AText, 1, LocalEnd)),
    TextY + TextHeight);

  OldColor := Canvas.Brush.Color;
  OldStyle := Canvas.Brush.Style;
  Canvas.Brush.Color := GetEffectiveSelectionBackground;
  Canvas.Brush.Style := bsSolid;
  Canvas.FillRect(HighlightRect);
  Canvas.Brush.Color := OldColor;
  Canvas.Brush.Style := OldStyle;
end;

// Draw AText, switching to the selection text colour for the portion that
// falls inside the selection (TextStart is the run's selectable index).
procedure TMarkDownViewer.DrawSelectableText(const AText: string;
  TextX, TextY, TextStart: Integer);
var
  SelStart: Integer;
  SelEnd: Integer;
  LocalStart: Integer;
  LocalEnd: Integer;
  XPos: Integer;
  PrefixText: string;
  SelectedText: string;
  SuffixText: string;
  OldFontColor: TColor;
begin
  if not SelectionRange(SelStart, SelEnd) then
  begin
    Canvas.TextOut(TextX, TextY, AText);
    Exit;
  end;

  LocalStart := Max(0, SelStart - TextStart);
  LocalEnd := Min(Length(AText), SelEnd - TextStart);
  if LocalStart >= LocalEnd then
  begin
    Canvas.TextOut(TextX, TextY, AText);
    Exit;
  end;

  PrefixText := Copy(AText, 1, LocalStart);
  SelectedText := Copy(AText, LocalStart + 1, LocalEnd - LocalStart);
  SuffixText := Copy(AText, LocalEnd + 1, MaxInt);

  XPos := TextX;
  if PrefixText <> '' then
  begin
    Canvas.TextOut(XPos, TextY, PrefixText);
    Inc(XPos, Canvas.TextWidth(PrefixText));
  end;

  OldFontColor := Canvas.Font.Color;
  Canvas.Font.Color := GetEffectiveSelectionTextColor;
  Canvas.TextOut(XPos, TextY, SelectedText);
  Canvas.Font.Color := OldFontColor;
  Inc(XPos, Canvas.TextWidth(SelectedText));

  if SuffixText <> '' then
    Canvas.TextOut(XPos, TextY, SuffixText);
end;

// Reset the canvas font to the control's base font with a style and size delta,
// optionally a different face (used for code).
procedure TMarkDownViewer.AssignBaseFont(Style: TFontStyles; SizeDelta: Integer;
  const FontName: string);
begin
  Canvas.Font.Assign(Font);
  Canvas.Font.Style := Style;
  Canvas.Font.Size := Max(1, Font.Size + SizeDelta);
  if FontName <> '' then
    Canvas.Font.Name := FontName;
  if UseThemedColors then
    Canvas.Font.Color := GetEffectiveTextColor;
end;

// Set the canvas font for a single inline token, combining the block's base
// style with the token's emphasis, switching to the code face for code spans
// and to the link colour (underlined) for links.
procedure TMarkDownViewer.AssignInlineFont(const Token: TMarkDownInlineToken;
  BaseStyle: TFontStyles; SizeDelta: Integer);
begin
  Canvas.Font.Assign(Font);
  if Token.IsSuperscript or Token.IsSubscript then
    SizeDelta := SizeDelta - 3;
  Canvas.Font.Size := Max(1, Font.Size + SizeDelta);
  if Token.IsCode then
  begin
    // Code keeps its own emphasis but not the surrounding block style.
    Canvas.Font.Name := FEffectiveCodeFont;
    Canvas.Font.Style := Token.Style;
  end
  else
    Canvas.Font.Style := BaseStyle + Token.Style;
  if Token.Url <> '' then
  begin
    Canvas.Font.Color := GetEffectiveLinkColor;
    Canvas.Font.Style := Canvas.Font.Style + [fsUnderline];
  end
  else if UseThemedColors then
    Canvas.Font.Color := GetEffectiveTextColor;
end;

function TMarkDownViewer.DrawInline(ATokens: TMarkDownInlineList;
  ALeft, ATop, AWidth: Integer; ADraw: Boolean; BaseStyle: TFontStyles;
  SizeDelta: Integer; AAlignment: TAlignment;
  const AMarkdownLinePrefix: string; AEmitAnchor: Boolean): Integer;
  var
    TokenIndex: Integer;
    AtomIndex: Integer;
    AtomStart: Integer;
    LineUsed: Integer;
    X: Integer;
    YPos: Integer;
    StartLen: Integer;
    AnchorRun: TMarkDownTextRun;
    LineHeight: Integer;
    Atom: string;
    AtomWidth: Integer;
    AtomRect: TRect;
    Hit: TMarkDownLinkHit;
    OldBrushColor: TColor;
    OldBrushStyle: TBrushStyle;
    OldBkMode: Integer;
    PendingMarkdownPrefix: string;
    AtomMarkdown: string;
    TextStart: Integer;
    TextY: Integer;

    procedure DrawSearchHighlights(const AText: string; TextX, TextY, TextHeight: Integer);
    var
      SearchIn: string;
      SearchFor: string;
      FoundAt: Integer;
      HighlightRect: TRect;
      OldColor: TColor;
      OldStyle: TBrushStyle;
    begin
      if (FSearchText = '') or (AText = '') then
        Exit;

      SearchIn := LowerCase(AText);
      SearchFor := LowerCase(FSearchText);
      FoundAt := Pos(SearchFor, SearchIn);
      while FoundAt > 0 do
      begin
        HighlightRect := Rect(
          TextX + Canvas.TextWidth(Copy(AText, 1, FoundAt - 1)),
          TextY,
          TextX + Canvas.TextWidth(Copy(AText, 1, FoundAt + Length(FSearchText) - 1)),
          TextY + TextHeight);

        OldColor := Canvas.Brush.Color;
        OldStyle := Canvas.Brush.Style;
        Canvas.Brush.Color := GetEffectiveSearchHighlightColor;
        Canvas.Brush.Style := bsSolid;
        Canvas.FillRect(HighlightRect);
        Canvas.Brush.Color := OldColor;
        Canvas.Brush.Style := OldStyle;

        FoundAt := PosEx(SearchFor, SearchIn, FoundAt + Length(SearchFor));
      end;
    end;

    function MeasureLineWidth(StartToken, StartAtom: Integer): Integer;
    var
      MeasureToken: Integer;
      MeasureAtom: Integer;
      MeasureText: string;
      MeasureWidth: Integer;
    begin
      Result := 0;
      for MeasureToken := StartToken to ATokens.Count - 1 do
      begin
        if ATokens[MeasureToken].LineBreak then
          Exit;
        AssignInlineFont(ATokens[MeasureToken], BaseStyle, SizeDelta);
        if MeasureToken = StartToken then
          MeasureAtom := StartAtom
        else
          MeasureAtom := 1;
        while MeasureAtom <= Length(ATokens[MeasureToken].Text) do
        begin
          MeasureText := NextAtom(ATokens[MeasureToken].Text, MeasureAtom);
          MeasureWidth := Canvas.TextWidth(MeasureText);
          if (Trim(MeasureText) <> '') and (Result > 0) and (Result + MeasureWidth > AWidth) then
            Exit;
          Inc(Result, MeasureWidth);
        end;
      end;
    end;

    function AlignedX(StartToken, StartAtom: Integer): Integer;
    var
      Available: Integer;
    begin
      Available := Max(0, AWidth - MeasureLineWidth(StartToken, StartAtom));
      Result := ALeft + AlignmentOffset(AAlignment, Available);
    end;

  begin
    YPos := ATop;
    AssignBaseFont(BaseStyle, SizeDelta);
    LineHeight := Canvas.TextHeight('Wg') + 5;
    StartLen := Length(FSelectableText);
    if ATokens.Count > 0 then
      X := AlignedX(0, 1)
    else
      X := ALeft;
    LineUsed := 0;
    PendingMarkdownPrefix := AMarkdownLinePrefix;

    for TokenIndex := 0 to ATokens.Count - 1 do
    begin
      if ATokens[TokenIndex].LineBreak then
      begin
        if ADraw then
          AddSelectableBreak(False);
        Inc(YPos, LineHeight);
        LineUsed := 0;
        X := AlignedX(TokenIndex + 1, 1);
        Continue;
      end;
      AssignInlineFont(ATokens[TokenIndex], BaseStyle, SizeDelta);
      AtomIndex := 1;
      while AtomIndex <= Length(ATokens[TokenIndex].Text) do
      begin
        AtomStart := AtomIndex;
        Atom := NextAtom(ATokens[TokenIndex].Text, AtomIndex);
        AtomWidth := Canvas.TextWidth(Atom);
        if (Trim(Atom) <> '') and (LineUsed > 0) and (LineUsed + AtomWidth > AWidth) then
        begin
          if ADraw then
            AddSelectableBreak(False);
          Inc(YPos, LineHeight);
          LineUsed := 0;
          X := AlignedX(TokenIndex, AtomStart);
          AssignInlineFont(ATokens[TokenIndex], BaseStyle, SizeDelta);
        end;

        if ADraw then
        begin
          AtomRect := Rect(X, YPos, X + AtomWidth, YPos + LineHeight);
          AtomMarkdown := MarkdownForAtom(ATokens[TokenIndex], Atom);
          if (PendingMarkdownPrefix <> '') and (Trim(Atom) <> '') then
          begin
            AtomMarkdown := PendingMarkdownPrefix + AtomMarkdown;
            PendingMarkdownPrefix := '';
          end;
          TextStart := AddSelectableRun(AtomRect, Atom,
            SliceMap(ATokens[TokenIndex].SourceMap, AtomStart - 1, Length(Atom)),
            AtomMarkdown);
          if (YPos + LineHeight >= 0) and (YPos <= ClientHeight) then
          begin
            if ATokens[TokenIndex].IsCode then
            begin
              OldBrushColor := Canvas.Brush.Color;
              OldBrushStyle := Canvas.Brush.Style;
              Canvas.Brush.Color := GetEffectiveCodeBackgroundColor;
              Canvas.Brush.Style := bsSolid;
              Canvas.FillRect(Rect(AtomRect.Left - 2, AtomRect.Top + 1, AtomRect.Right + 2, AtomRect.Bottom - 1));
              Canvas.Brush.Color := OldBrushColor;
              Canvas.Brush.Style := OldBrushStyle;
            end;
            if ATokens[TokenIndex].IsHighlighted then
            begin
              OldBrushColor := Canvas.Brush.Color;
              OldBrushStyle := Canvas.Brush.Style;
              Canvas.Brush.Color := GetEffectiveHighlightColor;
              Canvas.Brush.Style := bsSolid;
              Canvas.FillRect(AtomRect);
              Canvas.Brush.Color := OldBrushColor;
              Canvas.Brush.Style := OldBrushStyle;
            end;
            DrawSearchHighlights(Atom, X, YPos + 2, LineHeight - 2);
            DrawSelectionBackground(Atom, X, YPos + 2, LineHeight - 2, TextStart);
            OldBkMode := SetBkMode(Canvas.Handle, TRANSPARENT);
            TextY := YPos + 2;
            if ATokens[TokenIndex].IsSuperscript then
              Dec(TextY, 3)
            else if ATokens[TokenIndex].IsSubscript then
              Inc(TextY, 6);
            DrawSelectableText(Atom, X, TextY, TextStart);
            SetBkMode(Canvas.Handle, OldBkMode);
            if (ATokens[TokenIndex].Url <> '') and (Trim(Atom) <> '') and (FLinkHits <> nil) then
            begin
              Hit.Rect := AtomRect;
              Hit.Url := ATokens[TokenIndex].Url;
              FLinkHits.Add(Hit);
            end;
          end;
        end;
        Inc(X, AtomWidth);
        Inc(LineUsed, AtomWidth);
      end;
    end;

    // An empty block (e.g. a continued list item) draws no atoms, so add a
    // zero-width run at the content position to give the caret a home there.
    if ADraw and AEmitAnchor and (Length(FSelectableText) = StartLen) then
    begin
      AnchorRun := Default(TMarkDownTextRun);
      AnchorRun.Rect := Rect(ALeft, ATop, ALeft, ATop + LineHeight);
      AnchorRun.FontName := Canvas.Font.Name;
      AnchorRun.FontSize := Canvas.Font.Size;
      AnchorRun.FontStyle := Canvas.Font.Style;
      AnchorRun.StartIndex := Length(FSelectableText);
      AnchorRun.SourceStartIndex := -1;
      FTextRuns.Add(AnchorRun);
    end;

    Result := YPos + LineHeight - ATop;
  end;

function TMarkDownViewer.InlineTokensForBlock(ABlock: TMarkDownBlock): TMarkDownInlineList;
  begin
    if ABlock.InlineTokens = nil then
      ABlock.InlineTokens := TMarkDownBlockParser.ParseInline(ABlock.Text,
        FLinkReferences, ABlock.SourceMap);
    Result := ABlock.InlineTokens;
  end;

function TMarkDownViewer.ResolveImagePath(const Url: string): string;
  begin
    Result := Trim(Url);
    if (Result = '') or ContainsText(Result, '://') then
      Exit;

    if ExtractFileDrive(Result) <> '' then
      Exit;
    if Copy(Result, 1, 2) = '\\' then
      Exit;

    if FBasePath <> '' then
      Result := ExpandFileName(IncludeTrailingPathDelimiter(FBasePath) + Result)
    else
      Result := ExpandFileName(Result);
  end;

function TMarkDownViewer.DrawImageBlock(const AltText, Url: string; ALeft, ATop, AWidth: Integer): Integer;
  var
    Picture: TPicture;
    ImagePath: string;
    DrawWidth: Integer;
    DrawHeight: Integer;
    TextRect: TRect;
    OldBkMode: Integer;
  begin
    Result := Canvas.TextHeight('Wg') + 10;
    ImagePath := ResolveImagePath(Url);
    Picture := nil;
    if (ImagePath <> '') and not ContainsText(ImagePath, '://') and FileExists(ImagePath) then
      Picture := GetCachedImage(ImagePath);

    if Picture = nil then
    begin
      Canvas.Font.Assign(Font);
      Canvas.Font.Style := [fsItalic];
      if UseThemedColors then
        Canvas.Font.Color := GetEffectiveTextColor;
      TextRect := Rect(ALeft, ATop, ALeft + AWidth, ATop + Result);
      OldBkMode := SetBkMode(Canvas.Handle, TRANSPARENT);
      DrawText(Canvas.Handle, PChar(AltText), Length(AltText), TextRect, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
      SetBkMode(Canvas.Handle, OldBkMode);
      Exit;
    end;

    if (Picture.Width <= 0) or (Picture.Height <= 0) then
      Exit;

    DrawWidth := Min(AWidth, Picture.Width);
    DrawHeight := MulDiv(Picture.Height, DrawWidth, Picture.Width);
    if (ATop + DrawHeight >= 0) and (ATop <= ClientHeight) then
      Canvas.StretchDraw(Rect(ALeft, ATop, ALeft + DrawWidth, ATop + DrawHeight), Picture.Graphic);
    Result := DrawHeight;
  end;

function TMarkDownViewer.TableAlignmentFromCell(const Cell: string): TAlignment;
  var
    T: string;
    StartsWithColon: Boolean;
    EndsWithColon: Boolean;
  begin
    T := Trim(Cell);
    StartsWithColon := (T <> '') and (T[1] = ':');
    EndsWithColon := (T <> '') and (T[Length(T)] = ':');
    if StartsWithColon and EndsWithColon then
      Result := taCenter
    else if EndsWithColon then
      Result := taRightJustify
    else
      Result := taLeftJustify;
  end;

function TMarkDownViewer.DrawTable(const TableText: string; ALeft, ATop, AWidth: Integer;
    const ABlockSourceMap: TArray<Integer>): Integer;
  var
    SourceLines: TStringList;
    Rows: TObjectList<TStringList>;
    AlignCells: TStringList;
    ColWidths: array of Integer;
    RowHeights: array of Integer;
    Aligns: array of TAlignment;
    ColCount: Integer;
    RowHeight: Integer;
    RowTop: Integer;
    SourceIndex: Integer;
    Col: Integer;
    X: Integer;
    TotalWidth: Integer;
    CellText: string;
    CellRect: TRect;
    CellTokens: TMarkDownInlineList;
    RowBlockPos: TArray<Integer>;
    CellSearchCol: Integer;
    CellCol: Integer;

    function MeasureCellHeight(const AText: string; ACellWidth: Integer; AHeader: Boolean): Integer;
    var
      CellStyle: TFontStyles;
    begin
      if AHeader then
        CellStyle := [fsBold]
      else
        CellStyle := [];
      CellTokens := TMarkDownBlockParser.ParseInline(AText, FLinkReferences);
      try
        Result := DrawInline(CellTokens, 0, 0, Max(1, ACellWidth - 16), False, CellStyle) + 14;
      finally
        CellTokens.Free;
      end;
    end;
  begin
    Result := 0;
    SourceLines := TStringList.Create;
    Rows := TObjectList<TStringList>.Create(True);
    AlignCells := TStringList.Create;
    try
      SourceLines.Text := TableText;
      if SourceLines.Count < 2 then
        Exit;

      // Document offset of each source row's start within Block.Text, so cells
      // can be mapped back to the source through Block.SourceMap.
      SetLength(RowBlockPos, SourceLines.Count);
      for SourceIndex := 0 to SourceLines.Count - 1 do
        if SourceIndex = 0 then
          RowBlockPos[SourceIndex] := 0
        else
          RowBlockPos[SourceIndex] := RowBlockPos[SourceIndex - 1] +
            Length(SourceLines[SourceIndex - 1]) + Length(sLineBreak);

      ColCount := 0;
      for SourceIndex := 0 to SourceLines.Count - 1 do
      begin
        Rows.Add(TStringList.Create);
        TMarkDownBlockParser.SplitTableRow(SourceLines[SourceIndex], Rows.Last);
        if SourceIndex <> 1 then
          ColCount := Max(ColCount, Rows.Last.Count);
      end;

      if ColCount = 0 then
        Exit;

      TMarkDownBlockParser.SplitTableRow(SourceLines[1], AlignCells);
      SetLength(ColWidths, ColCount);
      SetLength(RowHeights, Rows.Count);
      SetLength(Aligns, ColCount);
      AssignBaseFont([], 0);
      for Col := 0 to ColCount - 1 do
      begin
        ColWidths[Col] := 60;
        if Col < AlignCells.Count then
          Aligns[Col] := TableAlignmentFromCell(AlignCells[Col])
        else
          Aligns[Col] := taLeftJustify;
      end;

      for SourceIndex := 0 to Rows.Count - 1 do
        if SourceIndex <> 1 then
          for Col := 0 to Min(ColCount, Rows[SourceIndex].Count) - 1 do
            ColWidths[Col] := Max(ColWidths[Col], Canvas.TextWidth(Rows[SourceIndex][Col]) + 24);

      TotalWidth := 0;
      for Col := 0 to ColCount - 1 do
        Inc(TotalWidth, ColWidths[Col]);
      if TotalWidth > AWidth then
      begin
        for Col := 0 to ColCount - 1 do
          ColWidths[Col] := Max(42, MulDiv(ColWidths[Col], AWidth, TotalWidth));
      end
      else if ColCount > 0 then
        Inc(ColWidths[ColCount - 1], AWidth - TotalWidth);

      for SourceIndex := 0 to Rows.Count - 1 do
      begin
        if SourceIndex = 1 then
          Continue;
        RowHeights[SourceIndex] := Canvas.TextHeight('Wg') + 14;
        for Col := 0 to ColCount - 1 do
        begin
          if Col < Rows[SourceIndex].Count then
            CellText := Rows[SourceIndex][Col]
          else
            CellText := '';
          RowHeights[SourceIndex] := Max(RowHeights[SourceIndex], MeasureCellHeight(CellText, ColWidths[Col], SourceIndex = 0));
        end;
      end;

      RowTop := ATop;
      for SourceIndex := 0 to Rows.Count - 1 do
      begin
        if SourceIndex = 1 then
          Continue;

        RowHeight := RowHeights[SourceIndex];
        X := ALeft;
        CellSearchCol := 1;
        for Col := 0 to ColCount - 1 do
        begin
          CellRect := Rect(X, RowTop, X + ColWidths[Col], RowTop + RowHeight);
          if SourceIndex = 0 then
            Canvas.Brush.Color := GetEffectiveTableHeaderColor
          else
            Canvas.Brush.Color := GetEffectiveBackground;
          Canvas.FillRect(CellRect);
          Canvas.Pen.Color := GetEffectiveGridlineColor;
          Canvas.Brush.Style := bsClear;
          Canvas.Rectangle(CellRect);
          Canvas.Brush.Style := bsSolid;

          if Col < Rows[SourceIndex].Count then
            CellText := Rows[SourceIndex][Col]
          else
            CellText := '';

          // Locate the (trimmed) cell within its source line, advancing a cursor
          // so repeated cell text still maps to the right column.
          CellCol := PosEx(CellText, SourceLines[SourceIndex], CellSearchCol);
          if (CellText <> '') and (CellCol > 0) then
          begin
            CellTokens := TMarkDownBlockParser.ParseInline(CellText,
              FLinkReferences,
              SliceMap(ABlockSourceMap, RowBlockPos[SourceIndex] + CellCol - 1,
                Length(CellText)));
            CellSearchCol := CellCol + Length(CellText);
          end
          else
            CellTokens := TMarkDownBlockParser.ParseInline(CellText,
              FLinkReferences);
          try
            if SourceIndex = 0 then
              DrawInline(CellTokens, CellRect.Left + 8, CellRect.Top + 5,
                Max(1, CellRect.Width - 16), True, [fsBold], 0, Aligns[Col])
            else
              DrawInline(CellTokens, CellRect.Left + 8, CellRect.Top + 5,
                Max(1, CellRect.Width - 16), True, [], 0, Aligns[Col]);
          finally
            CellTokens.Free;
          end;
          if Col < ColCount - 1 then
            AddSelectableText(#9, '', False);
          Inc(X, ColWidths[Col]);
        end;
        AddSelectableBreak(True, SliceMapValue(ABlockSourceMap,
          RowBlockPos[SourceIndex] + Length(SourceLines[SourceIndex])));
        Inc(RowTop, RowHeight);
      end;

      Result := RowTop - ATop;
    finally
      AlignCells.Free;
      Rows.Free;
      SourceLines.Free;
    end;
  end;

function TMarkDownViewer.DrawBlocks(TextLeft, ContentWidth, Y: Integer): Integer;
var
  Blocks: TMarkDownBlockList;
  I: Integer;
  LineHeight: Integer;
  TokenHeight: Integer;
  Tokens: TMarkDownInlineList;
  Block: TMarkDownBlock;
  Lines: TStringList;
  LineIndex: Integer;
  CodePos: Integer;
  R: TRect;
  CheckRect: TRect;
  TaskHit: TMarkDownTaskHit;
  CanvasState: TCanvasState;
  Bullet: string;
  ListMarker: string;
  ListLeft: Integer;
  MarkerLeft: Integer;
  TextIndent: Integer;
  LineTextStart: Integer;
  OldBkMode: Integer;
  SyntaxTokens: TArray<TSourceToken>;
  TokenIndex: Integer;
  CurrentX: Integer;
  LineStart: Integer;
  LineEnd: Integer;
  TokenOffset: Integer;
  TokenLen: Integer;
  StartPos: Integer;
  EndPos: Integer;
  SubText: string;
  NextSourceLine: Integer;
  CanvasStateBtn: TCanvasState;
  BtnRect: TRect;
  BtnText: string;
  TextX: Integer;
  TextY: Integer;
begin
  Blocks := FBlocks;
  FLastBlockTop := Y;
  NextSourceLine := 0;
  for I := 0 to Blocks.Count - 1 do
  begin
    Block := Blocks[I];
    // When editing, blank source lines between blocks are rendered as empty,
    // cursor-addressable lines (read-only preview keeps them collapsed).
    if not FReadOnly then
      while NextSourceLine < Block.SourceStartLine do
      begin
        if (NextSourceLine < FMarkdown.Count) and
          (Trim(FMarkdown[NextSourceLine]) = '') then
          Y := DrawEditableBlankLine(TextLeft, ContentWidth, Y, NextSourceLine);
        Inc(NextSourceLine);
      end;
    if I = Blocks.Count - 1 then
      FLastBlockTop := Y;
    Block.LayoutTop := Y + FScrollPos;
    case Block.Kind of
      bkHeading:
        begin
          AssignBaseFont([fsBold], HeadingFontSizeDelta(Block.Level));
          Tokens := InlineTokensForBlock(Block);
          TokenHeight := DrawInline(Tokens, TextLeft, Y, ContentWidth, True, [fsBold],
            HeadingFontSizeDelta(Block.Level), taLeftJustify, StringOfChar('#', Block.Level) + ' ', True);
          // Top-level headings get a subtle underline rule, like common renderers.
          if (Block.Level <= 2) and (GetEffectiveHeadingRuleColor <> clNone) then
          begin
            Canvas.Pen.Color := GetEffectiveHeadingRuleColor;
            Canvas.MoveTo(TextLeft, Y + TokenHeight + 3);
            Canvas.LineTo(TextLeft + ContentWidth, Y + TokenHeight + 3);
          end;
          Inc(Y, TokenHeight + ParagraphSpacing + 2);
        end;
      bkQuote:
        begin
          Tokens := InlineTokensForBlock(Block);
          TokenHeight := DrawInline(Tokens, TextLeft + 13, Y, ContentWidth - 13, True,
            [], 0, taLeftJustify, '> ', True);
          R := Rect(TextLeft, Y + 2, TextLeft + 4, Y + TokenHeight);
          CanvasState := TCanvasState.Save(Canvas);
          try
            Canvas.Brush.Color := GetEffectiveQuoteBarColor;
            Canvas.FillRect(R);
          finally
            CanvasState.Restore;
          end;
          Inc(Y, TokenHeight + ParagraphSpacing);
        end;
      bkListItem:
        begin
          AssignBaseFont([], 0);
          ListLeft := TextLeft + (Max(0, Block.IndentLevel) * 16);
          TextIndent := 22;
          if Block.IsTask then
          begin
            MarkerLeft := CenterMarkerLeft(ListLeft, TextIndent, 15);
            CheckRect := Rect(MarkerLeft, Y + 3, MarkerLeft + 15, Y + 18);
            if Block.TaskChecked then
              DrawFrameControl(Canvas.Handle, CheckRect, DFC_BUTTON, DFCS_BUTTONCHECK or DFCS_CHECKED)
            else
              DrawFrameControl(Canvas.Handle, CheckRect, DFC_BUTTON, DFCS_BUTTONCHECK);
            TaskHit.Rect := CheckRect;
            TaskHit.SourceLine := Block.SourceStartLine;
            FTaskHits.Add(TaskHit);
          end
          else
          begin
            if Block.Ordered then
            begin
              Bullet := IntToStr(Block.Number) + '.';
              MarkerLeft := CenterMarkerLeft(ListLeft, TextIndent,
                Canvas.TextWidth(Bullet));
              Canvas.TextOut(MarkerLeft, Y, Bullet);
            end
            else
            begin
              Bullet := #$25CF;
              MarkerLeft := CenterMarkerLeft(ListLeft, TextIndent,
                Canvas.TextWidth(Bullet));
              Canvas.TextOut(MarkerLeft, Y, Bullet);
            end;
          end;

          if Block.IsTask then
          begin
            if Block.TaskChecked then
              ListMarker := '- [x] '
            else
              ListMarker := '- [ ] ';
          end
          else if Block.Ordered then
            ListMarker := IntToStr(Block.Number) + '. '
          else
            ListMarker := '- ';

          Tokens := InlineTokensForBlock(Block);
          TokenHeight := DrawInline(Tokens, ListLeft + TextIndent, Y,
            Max(10, ContentWidth - (ListLeft - TextLeft) - TextIndent), True,
            [], 0, taLeftJustify, StringOfChar(' ', Max(0, Block.IndentLevel) * 2) + ListMarker, True);
          Inc(Y, TokenHeight + 3);
        end;
      bkImage:
        begin
          TokenHeight := DrawImageBlock(Block.Text, Block.Url, TextLeft, Y, ContentWidth);
          Inc(Y, TokenHeight + ParagraphSpacing);
        end;
      bkTable:
        begin
          CanvasState := TCanvasState.Save(Canvas);
          try
            TokenHeight := DrawTable(Block.Text, TextLeft, Y, ContentWidth,
              Block.SourceMap);
          finally
            CanvasState.Restore;
          end;
          Inc(Y, TokenHeight + ParagraphSpacing);
        end;
      bkCodeBlock:
        begin
          AssignBaseFont([], 0, FEffectiveCodeFont);
          LineHeight := Canvas.TextHeight('Wg') + 5;
          Lines := TStringList.Create;
          try
            Lines.Text := Block.Text;
            CodePos := 0;
            TokenHeight := Max(1, Lines.Count) * LineHeight + 16;
            R := Rect(TextLeft, Y + 2, TextLeft + ContentWidth, Y + TokenHeight);
            CanvasState := TCanvasState.Save(Canvas);
            try
              Canvas.Brush.Color := GetEffectiveCodeBackgroundColor;
              Canvas.FillRect(R);
              Canvas.Brush.Style := bsClear;
              
              SyntaxTokens := Block.HighlightTokens;

              for LineIndex := 0 to Lines.Count - 1 do
              begin
                LineTextStart := AddSelectableRun(
                  Rect(TextLeft + 8, Y + 8 + (LineIndex * LineHeight),
                    TextLeft + 8 + Canvas.TextWidth(Lines[LineIndex]),
                    Y + 8 + (LineIndex * LineHeight) + LineHeight),
                  Lines[LineIndex],
                  SliceMap(Block.SourceMap, CodePos, Length(Lines[LineIndex])));
                if (Y + 8 + (LineIndex * LineHeight) + LineHeight >= 0) and
                  (Y + 8 + (LineIndex * LineHeight) <= ClientHeight) then
                begin
                  DrawSelectionBackground(Lines[LineIndex], TextLeft + 8,
                    Y + 8 + (LineIndex * LineHeight), LineHeight, LineTextStart);
                  OldBkMode := SetBkMode(Canvas.Handle, TRANSPARENT);
                  
                  if SyntaxTokens <> nil then
                  begin
                    CurrentX := TextLeft + 8;
                    LineStart := CodePos;
                    LineEnd := LineStart + Length(Lines[LineIndex]);
                    for TokenIndex := 0 to Length(SyntaxTokens) - 1 do
                    begin
                      TokenOffset := SyntaxTokens[TokenIndex].Offset;
                      TokenLen := Length(SyntaxTokens[TokenIndex].Text);
                      StartPos := Max(TokenOffset, LineStart);
                      EndPos := Min(TokenOffset + TokenLen, LineEnd);
                      if StartPos < EndPos then
                      begin
                        SubText := Copy(SyntaxTokens[TokenIndex].Text, StartPos - TokenOffset + 1, EndPos - StartPos);
                        Canvas.Font.Color := GetSyntaxColor(SyntaxTokens[TokenIndex].Kind);
                        Canvas.Font.Style := GetSyntaxStyle(SyntaxTokens[TokenIndex].Kind);
                        DrawSelectableText(SubText, CurrentX,
                          Y + 8 + (LineIndex * LineHeight), LineTextStart + (StartPos - LineStart));
                        Inc(CurrentX, Canvas.TextWidth(SubText));
                      end;
                    end;
                  end
                  else
                  begin
                    Canvas.Font.Color := GetEffectivePlainColor;
                    Canvas.Font.Style := [];
                    DrawSelectableText(Lines[LineIndex], TextLeft + 8,
                      Y + 8 + (LineIndex * LineHeight), LineTextStart);
                  end;
                  
                  SetBkMode(Canvas.Handle, OldBkMode);
                end;
                
                Inc(CodePos, Length(Lines[LineIndex]));
                // Unconditional break so blank code lines survive in the
                // selectable text (AddSelectableBreak collapses repeats).
                if LineIndex < Lines.Count - 1 then
                begin
                  AddSelectableText(sLineBreak, '', True,
                    SliceMap(Block.SourceMap, CodePos, Length(sLineBreak)));
                  Inc(CodePos, Length(sLineBreak));
                end;
              end;
              Canvas.Brush.Style := bsSolid;
              // Draw copy button if this block is hovered
              if Block = FHoveredCodeBlock then
              begin
                BtnRect := GetCodeBlockCopyBtnRect(Block);
                CanvasStateBtn := TCanvasState.Save(Canvas);
                try
                  // Draw button background
                  Canvas.Pen.Style := psSolid;
                  if FHoveredCopyButton then
                  begin
                    Canvas.Brush.Color := GetEffectiveCodeButtonHoverColor;
                    Canvas.Pen.Color := GetEffectiveCodeButtonHoverBorderColor;
                  end
                  else
                  begin
                    Canvas.Brush.Color := GetEffectiveCodeButtonColor;
                    Canvas.Pen.Color := GetEffectiveCodeButtonBorderColor;
                  end;
                  Canvas.RoundRect(BtnRect.Left, BtnRect.Top, BtnRect.Right, BtnRect.Bottom, 4, 4);
                  
                  // Draw text
                  Canvas.Font.Assign(Font);
                  Canvas.Font.Size := 8;
                  Canvas.Font.Style := [];
                  if FHoveredCopyButton then
                    Canvas.Font.Color := GetEffectiveCodeButtonHoverTextColor
                  else
                    Canvas.Font.Color := GetEffectiveCodeButtonTextColor;
                    
                  BtnText := 'Copy';
                  if (FCopiedBlock = Block) and (GetTickCount - FCopiedTicks < 1500) then
                    BtnText := 'Copied!';
                  
                  // Center text in button
                  OldBkMode := SetBkMode(Canvas.Handle, TRANSPARENT);
                  TextX := BtnRect.Left + (BtnRect.Width - Canvas.TextWidth(BtnText)) div 2;
                  TextY := BtnRect.Top + (BtnRect.Height - Canvas.TextHeight(BtnText)) div 2;
                  Canvas.TextOut(TextX, TextY, BtnText);
                  SetBkMode(Canvas.Handle, OldBkMode);
                finally
                  CanvasStateBtn.Restore;
                end;
              end;
            finally
              CanvasState.Restore;
            end;
          finally
            Lines.Free;
          end;
          Inc(Y, TokenHeight + ParagraphSpacing);
        end;
      bkRule:
        begin
          Canvas.Pen.Color := GetEffectiveGridlineColor;
          Canvas.MoveTo(TextLeft, Y + 8);
          Canvas.LineTo(TextLeft + ContentWidth, Y + 8);
          Inc(Y, 18);
        end;
    else
      Tokens := InlineTokensForBlock(Block);
      TokenHeight := DrawInline(Tokens, TextLeft, Y, ContentWidth, True,
        [], 0, taLeftJustify, '', True);
      Inc(Y, TokenHeight + ParagraphSpacing);
    end;
    Block.LayoutHeight := Y + FScrollPos - Block.LayoutTop;
    Block.LayoutWidth := ContentWidth;
    if (Block.Text = '') and
      (Block.Kind in [bkParagraph, bkHeading, bkQuote, bkListItem]) and
      (Block.SourceStartLine >= 0) and (Block.SourceStartLine < FMarkdown.Count) then
      // Empty content block: force a non-collapsing break whose source is the
      // caret position just past the marker, so the anchor maps there.
      AddSelectableBreak(True, LineStartSourcePos(Block.SourceStartLine) +
        Length(FMarkdown[Block.SourceStartLine]), True)
    else
      // The break after a block maps to the line break following its last
      // source character (the source map's end sentinel).
      AddSelectableBreak(True,
        SliceMapValue(Block.SourceMap, Length(Block.SourceMap) - 1));
    if not FReadOnly then
      NextSourceLine := Max(NextSourceLine, BlockEndSourceLine(Block) + 1);
  end;
  // Trailing blank lines (e.g. the empty line left by pressing Enter at the end
  // of the document) get their own addressable slot when editing.
  if not FReadOnly then
    while NextSourceLine < FMarkdown.Count do
    begin
      if Trim(FMarkdown[NextSourceLine]) = '' then
        Y := DrawEditableBlankLine(TextLeft, ContentWidth, Y, NextSourceLine);
      Inc(NextSourceLine);
    end;
  Result := Y;
end;

// The last source line a block occupies, derived from its source map's end
// sentinel (the offset just past the block's final source character). Falls
// back to the start line for blocks that carry no mappable text.
function TMarkDownViewer.BlockEndSourceLine(ABlock: TMarkDownBlock): Integer;
begin
  if Length(ABlock.SourceMap) > 0 then
    Result := SourcePosToLine(
      SliceMapValue(ABlock.SourceMap, Length(ABlock.SourceMap) - 1))
  else
    Result := ABlock.SourceStartLine;
  Result := Max(Result, ABlock.SourceStartLine);
end;

// Render one blank source line as an empty, cursor-addressable line: a
// zero-width layout anchor for the caret plus a forced (non-collapsing)
// selectable break mapped to the line's source position.
function TMarkDownViewer.DrawEditableBlankLine(TextLeft, ContentWidth, Y,
  ALineIdx: Integer): Integer;
var
  EmptyTokens: TMarkDownInlineList;
  TokenHeight: Integer;
begin
  AssignBaseFont([], 0);
  EmptyTokens := TMarkDownInlineList.Create;
  try
    TokenHeight := DrawInline(EmptyTokens, TextLeft, Y, ContentWidth, True,
      [], 0, taLeftJustify, '', True);
  finally
    EmptyTokens.Free;
  end;
  Result := Y + TokenHeight;
  AddSelectableBreak(True, LineStartSourcePos(ALineIdx), True);
end;

procedure TMarkDownViewer.Paint;
var
  Y: Integer;
  TextLeft: Integer;
  ContentWidth: Integer;
  TotalHeight: Integer;
begin
  Canvas.Brush.Color := GetEffectiveBackground;
  Canvas.FillRect(ClientRect);

  FLinkHits.Clear;
  FTaskHits.Clear;
  FTextRuns.Clear;
  FCopyChunks.Clear;
  FSelectableText := '';

  TextLeft := MarkdownPadding;
  ContentWidth := Max(10, ClientWidth - (MarkdownPadding * 2) - GetSystemMetrics(SM_CXVSCROLL));
  Y := DrawBlocks(TextLeft, ContentWidth, MarkdownPadding - FScrollPos);

  TotalHeight := Y + FScrollPos + MarkdownPadding;
  if TotalHeight <> FContentHeight then
  begin
    FContentHeight := TotalHeight;
    UpdateScrollBar;
  end;
  DrawCaret;
end;

procedure TMarkDownViewer.Resize;
begin
  inherited;
  InvalidateLayout;
  UpdateScrollBar;
  Invalidate;
end;

function TMarkDownViewer.SourcePosToLine(SourcePos: Integer): Integer;
var
  S: string;
  P: Integer;
begin
  S := FMarkdown.Text;
  if SourcePos <= 0 then Exit(0);
  if SourcePos >= Length(S) then Exit(Max(0, FMarkdown.Count - 1));

  Result := 0;
  P := Pos(#13#10, S);
  while (P > 0) and (P + 1 <= SourcePos) do
  begin
    Inc(Result);
    P := PosEx(#13#10, S, P + 2);
  end;
  Result := EnsureRange(Result, 0, FMarkdown.Count - 1);
end;

function TMarkDownViewer.LineStartSourcePos(LineIdx: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to LineIdx - 1 do
    Inc(Result, Length(FMarkdown[I]) + 2);
end;

function TMarkDownViewer.GetBlockAtLine(LineIdx: Integer): TMarkDownBlock;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FBlocks.Count - 1 do
    if FBlocks[I].SourceStartLine <= LineIdx then
      Result := FBlocks[I]
    else
      Break;
end;

function TMarkDownViewer.GetHeadingPrefixLength(const Line: string): Integer;
var
  T: string;
begin
  T := TMarkDownBlockParser.TrimLeftOnly(Line);
  Result := 0;
  while (Result < Length(T)) and (T[Result + 1] = '#') do
    Inc(Result);
  if Result > 0 then
    Result := Result + Length(Line) - Length(T) + 1; // +1 for the space after #
end;

// Snapshot the current document onto the undo stack, cap its depth and drop
// the redo history. Call once immediately before mutating FMarkdown.
procedure TMarkDownViewer.PushUndoState;
begin
  FUndoStack.Add(FMarkdown.Text);
  while FUndoStack.Count > MaxUndoDepth do
    FUndoStack.Delete(0);
  FRedoStack.Clear;
end;

// Replace a single source line while preserving the scroll position. The
// FApplyingEdit guard stops MarkdownChanged from clearing undo/redo and
// resetting the view as if the text had been assigned from outside.
procedure TMarkDownViewer.ApplyMarkdownLine(ALineIndex: Integer;
  const ANewLine: string);
var
  SavedScrollPos: Integer;
begin
  SavedScrollPos := FScrollPos;
  FApplyingEdit := True;
  try
    FMarkdown[ALineIndex] := ANewLine;
  finally
    FApplyingEdit := False;
  end;
  FScrollPos := SavedScrollPos;
  UpdateScrollBar;
end;

// Replace the whole document while preserving the scroll position.
procedure TMarkDownViewer.ApplyMarkdownText(const ANewText: string);
var
  SavedScrollPos: Integer;
begin
  SavedScrollPos := FScrollPos;
  FApplyingEdit := True;
  try
    FMarkdown.Text := ANewText;
  finally
    FApplyingEdit := False;
  end;
  FScrollPos := SavedScrollPos;
  UpdateScrollBar;
end;

// Repaint to rebuild the layout, then collapse the selection onto the caret
// mapped from a source position and bring it into view.
procedure TMarkDownViewer.FinishEditAtSource(ASourcePos: Integer);
begin
  Repaint;
  FSelectionCaret := SourceToSelectablePosition(ASourcePos);
  FSelectionAnchor := FSelectionCaret;
  FDesiredCaretX := -1;
  ScrollCaretIntoView;
  Invalidate;
end;

procedure TMarkDownViewer.SetHeadingLevel(TargetLevel: Integer);
var
  Block: TMarkDownBlock;
  LineIdx: Integer;
  OldLine: string;
  NewLine: string;
  OldSourcePos: Integer;
  NewSourcePos: Integer;
  OldLevel: Integer;
  OldPrefixLen: Integer;
  NewPrefixLen: Integer;
  PrefixDelta: Integer;
  T: string;
  LineStart: Integer;
  UnderlineIdx: Integer;
begin
  if FReadOnly then Exit;
  if FSelectableText = '' then Exit;
  TargetLevel := EnsureRange(TargetLevel, 0, 6);

  OldSourcePos := SelectableToSourcePosition(FSelectionCaret);
  LineIdx := SourcePosToLine(OldSourcePos);
  Block := GetBlockAtLine(LineIdx);
  if Block = nil then Exit;

  // If already at target level, do nothing
  if (Block.Kind = bkParagraph) and (TargetLevel = 0) then Exit;
  if (Block.Kind = bkHeading) and (Block.Level = TargetLevel) then Exit;

  if (LineIdx < 0) or (LineIdx >= FMarkdown.Count) then Exit;

  if TargetLevel = 0 then
  begin
    // Convert heading to paragraph (strip heading markers)
    if Block.Kind <> bkHeading then Exit;
    if (Block.SourceStartLine < 0) or (Block.SourceStartLine >= FMarkdown.Count) then Exit;

    // Check if this is a setext heading (underline on next line)
    UnderlineIdx := Block.SourceStartLine + 1;
    if (UnderlineIdx < FMarkdown.Count) and
       TMarkDownBlockParser.IsSetextUnderline(FMarkdown[UnderlineIdx], OldLevel) then
    begin
      // Strip underline
      PushUndoState;
      ApplyMarkdownLine(UnderlineIdx, '');
      FinishEditAtSource(OldSourcePos);
      Exit;
    end;

    // ATX heading
    OldLine := FMarkdown[Block.SourceStartLine];
    OldPrefixLen := GetHeadingPrefixLength(OldLine);
    T := TMarkDownBlockParser.TrimLeftOnly(OldLine);
    LineStart := Length(OldLine) - Length(T);
    NewLine := Copy(OldLine, 1, LineStart) + Copy(T, OldPrefixLen + 1, MaxInt);

    PushUndoState;
    ApplyMarkdownLine(Block.SourceStartLine, NewLine);
    NewSourcePos := Max(0, OldSourcePos - OldPrefixLen);
    FinishEditAtSource(NewSourcePos);
    Exit;
  end;

  // Convert paragraph (or other block) to heading, or change existing heading level
  if Block.Kind <> bkHeading then
  begin
    // Convert paragraph to heading level TargetLevel
    OldLine := FMarkdown[LineIdx];
    NewLine := StringOfChar('#', TargetLevel) + ' ' + OldLine;
    
    PushUndoState;
    ApplyMarkdownLine(LineIdx, NewLine);
    NewSourcePos := Min(OldSourcePos + TargetLevel + 1,
      LineStartSourcePos(LineIdx) + Length(NewLine));
    FinishEditAtSource(NewSourcePos);
    Exit;
  end;

  // Existing heading block - check if it's setext heading
  UnderlineIdx := Block.SourceStartLine + 1;
  if (UnderlineIdx < FMarkdown.Count) and
     TMarkDownBlockParser.IsSetextUnderline(FMarkdown[UnderlineIdx], OldLevel) then
  begin
    // For setext headings: convert them to ATX heading first of the TargetLevel
    OldLine := FMarkdown[Block.SourceStartLine];
    NewLine := StringOfChar('#', TargetLevel) + ' ' + OldLine;
    
    PushUndoState;
    // Remove the setext underline and update the header text line to ATX format
    ApplyMarkdownLine(UnderlineIdx, '');
    ApplyMarkdownLine(Block.SourceStartLine, NewLine);
    NewSourcePos := Min(OldSourcePos + TargetLevel + 1,
      LineStartSourcePos(Block.SourceStartLine) + Length(NewLine));
    FinishEditAtSource(NewSourcePos);
    Exit;
  end;

  // ATX heading - change existing # count
  OldLine := FMarkdown[Block.SourceStartLine];
  OldPrefixLen := GetHeadingPrefixLength(OldLine);
  OldLevel := Block.Level;
  
  T := TMarkDownBlockParser.TrimLeftOnly(OldLine);
  LineStart := Length(OldLine) - Length(T);
  NewLine := Copy(OldLine, 1, LineStart) + StringOfChar('#', TargetLevel) +
    Copy(T, OldLevel + 1, MaxInt);

  if NewLine = OldLine then Exit;

  NewPrefixLen := GetHeadingPrefixLength(NewLine);
  PrefixDelta := NewPrefixLen - OldPrefixLen;

  PushUndoState;
  ApplyMarkdownLine(Block.SourceStartLine, NewLine);

  if OldSourcePos >= LineStartSourcePos(Block.SourceStartLine) + OldPrefixLen then
    NewSourcePos := OldSourcePos + PrefixDelta
  else
    NewSourcePos := OldSourcePos;
  NewSourcePos := Min(NewSourcePos,
    LineStartSourcePos(Block.SourceStartLine) + Length(NewLine));
  FinishEditAtSource(NewSourcePos);
end;

procedure TMarkDownViewer.ChangeHeadingLevel(Delta: Integer);
var
  Block: TMarkDownBlock;
  LineIdx: Integer;
  OldLine: string;
  NewLine: string;
  OldPrefixLen: Integer;
  NewPrefixLen: Integer;
  PrefixDelta: Integer;
  OldSourcePos: Integer;
  NewSourcePos: Integer;
  LineStart: Integer;
  T: string;
  OldLevel: Integer;
  NewLevel: Integer;
  UnderlineIdx: Integer;
  UnderlineLen: Integer;
begin
  if FReadOnly then Exit;
  if FSelectableText = '' then Exit;

  OldSourcePos := SelectableToSourcePosition(FSelectionCaret);
  LineIdx := SourcePosToLine(OldSourcePos);
  Block := GetBlockAtLine(LineIdx);
  if Block = nil then Exit;

  if Block.Kind <> bkHeading then
  begin
    if Block.Kind <> bkParagraph then Exit;
    if Delta <= 0 then Exit;
    if (LineIdx < 0) or (LineIdx >= FMarkdown.Count) then Exit;
    OldLine := FMarkdown[LineIdx];
    NewLine := '# ' + OldLine;
    if NewLine = OldLine then Exit;

    PushUndoState;
    ApplyMarkdownLine(LineIdx, NewLine);
    NewSourcePos := Min(OldSourcePos + 2,
      LineStartSourcePos(LineIdx) + Length(NewLine));
    FinishEditAtSource(NewSourcePos);
    Exit;
  end;

  // Block is a heading - guard against stale/invalid SourceStartLine
  if (Block.SourceStartLine < 0) or (Block.SourceStartLine >= FMarkdown.Count) then Exit;

  // Check if this is a setext heading (underline on next line)
  UnderlineIdx := Block.SourceStartLine + 1;
  if (UnderlineIdx < FMarkdown.Count) and
     TMarkDownBlockParser.IsSetextUnderline(FMarkdown[UnderlineIdx], OldLevel) then
  begin
    // Setext heading: promote to H1 or demote to H2
    if Delta = 0 then Exit;
    if Delta > 0 then
    begin
      // Demote H1→H2 (change = to -) or H2 stays H2
      if Block.Level = 2 then Exit;
      // H1 → H2: change underline from = to -
      UnderlineLen := Length(Trim(FMarkdown[UnderlineIdx]));
      NewLine := StringOfChar('-', UnderlineLen);
    end
    else
    begin
      // Promote H2→H1 (change - to =), or H1 → paragraph (remove underline)
      if Block.Level = 1 then
      begin
        // Strip underline: the text line becomes a plain paragraph
        PushUndoState;
        ApplyMarkdownLine(UnderlineIdx, '');
        FinishEditAtSource(OldSourcePos);
        Exit;
      end;
      // H2 → H1: change underline from - to =
      UnderlineLen := Length(Trim(FMarkdown[UnderlineIdx]));
      NewLine := StringOfChar('=', UnderlineLen);
    end;

    PushUndoState;
    ApplyMarkdownLine(UnderlineIdx, NewLine);
    // Setext underline change doesn't affect caret position mapping
    FinishEditAtSource(OldSourcePos);
    Exit;
  end;

  // ATX heading: change # count or strip prefix
  if (Block.SourceStartLine < 0) or (Block.SourceStartLine >= FMarkdown.Count) then Exit;
  OldLine := FMarkdown[Block.SourceStartLine];
  OldPrefixLen := GetHeadingPrefixLength(OldLine);
  OldLevel := Block.Level;
  if OldLevel + Delta = OldLevel then Exit;

  // When promoting past H1, strip the # prefix back to plain text
  if OldLevel + Delta < 1 then
  begin
    T := TMarkDownBlockParser.TrimLeftOnly(OldLine);
    LineStart := Length(OldLine) - Length(T);
    NewLine := Copy(OldLine, 1, LineStart) + Copy(T, OldLevel + 2, MaxInt);

    PushUndoState;
    ApplyMarkdownLine(Block.SourceStartLine, NewLine);

    // Caret shifts back by the prefix length (including the space after #)
    NewSourcePos := OldSourcePos - OldPrefixLen;
    if NewSourcePos < 0 then
      NewSourcePos := 0;
    NewSourcePos := Min(NewSourcePos,
      LineStartSourcePos(Block.SourceStartLine) + Length(NewLine));
    FinishEditAtSource(NewSourcePos);
    Exit;
  end;

  NewLevel := EnsureRange(OldLevel + Delta, 1, 6);
  if NewLevel = OldLevel then Exit;

  // Build new line: preserve leading whitespace, replace # count, keep rest
  T := TMarkDownBlockParser.TrimLeftOnly(OldLine);
  LineStart := Length(OldLine) - Length(T);
  NewLine := Copy(OldLine, 1, LineStart) + StringOfChar('#', NewLevel) +
    Copy(T, OldLevel + 1, MaxInt);

  if NewLine = OldLine then Exit;

  NewPrefixLen := GetHeadingPrefixLength(NewLine);
  PrefixDelta := NewPrefixLen - OldPrefixLen;

  PushUndoState;
  ApplyMarkdownLine(Block.SourceStartLine, NewLine);

  // Adjust caret: if it was past the prefix, shift by prefix delta
  if OldSourcePos >= LineStartSourcePos(Block.SourceStartLine) + OldPrefixLen then
    NewSourcePos := OldSourcePos + PrefixDelta
  else
    NewSourcePos := OldSourcePos;
  NewSourcePos := Min(NewSourcePos,
    LineStartSourcePos(Block.SourceStartLine) + Length(NewLine));
  FinishEditAtSource(NewSourcePos);
end;

procedure TMarkDownViewer.ChangeListIndent(Delta: Integer);
var
  Block: TMarkDownBlock;
  LineIdx: Integer;
  OldLine: string;
  NewLine: string;
  OldSourcePos: Integer;
  NewSourcePos: Integer;
begin
  if FReadOnly then Exit;
  if FSelectableText = '' then Exit;

  OldSourcePos := SelectableToSourcePosition(FSelectionCaret);
  LineIdx := SourcePosToLine(OldSourcePos);
  Block := GetBlockAtLine(LineIdx);
  if Block = nil then Exit;
  if Block.Kind <> bkListItem then Exit;
  if (LineIdx < 0) or (LineIdx >= FMarkdown.Count) then Exit;

  OldLine := FMarkdown[LineIdx];
  if Delta > 0 then
  begin
    // Indent: add 2 spaces to the beginning of the line
    NewLine := '  ' + OldLine;
  end
  else
  begin
    // Outdent: remove up to 2 spaces from the beginning of the line
    if OldLine.StartsWith('  ') then
      NewLine := Copy(OldLine, 3, MaxInt)
    else if OldLine.StartsWith(' ') then
      NewLine := Copy(OldLine, 2, MaxInt)
    else
      Exit;
  end;

  if NewLine = OldLine then Exit;

  PushUndoState;
  ApplyMarkdownLine(LineIdx, NewLine);

  NewSourcePos := Max(LineStartSourcePos(LineIdx), OldSourcePos + (Length(NewLine) - Length(OldLine)));
  FinishEditAtSource(NewSourcePos);
end;

procedure TMarkDownViewer.MoveLineUpDown(Delta: Integer);
var
  OldSourcePos: Integer;
  LineIdx: Integer;
  TargetLineIdx: Integer;
  LineText: string;
  CaretOffset: Integer;
  NewLineStartPos: Integer;
  NewSourcePos: Integer;
begin
  if FReadOnly then Exit;
  if FSelectableText = '' then Exit;
  if Delta = 0 then Exit;

  OldSourcePos := SelectableToSourcePosition(FSelectionCaret);
  LineIdx := SourcePosToLine(OldSourcePos);
  TargetLineIdx := LineIdx + Delta;

  if (LineIdx < 0) or (LineIdx >= FMarkdown.Count) then Exit;
  if (TargetLineIdx < 0) or (TargetLineIdx >= FMarkdown.Count) then Exit;

  LineText := FMarkdown[LineIdx];
  CaretOffset := OldSourcePos - LineStartSourcePos(LineIdx);

  PushUndoState;

  FApplyingEdit := True;
  FMarkdown.BeginUpdate;
  try
    FMarkdown.Exchange(LineIdx, TargetLineIdx);
  finally
    FMarkdown.EndUpdate;
    FApplyingEdit := False;
  end;

  MarkdownChanged(Self);

  NewLineStartPos := LineStartSourcePos(TargetLineIdx);
  NewSourcePos := Min(NewLineStartPos + CaretOffset, NewLineStartPos + Length(LineText));
  FinishEditAtSource(NewSourcePos);
end;

procedure TMarkDownViewer.ToggleTaskAtLine(SourceLine: Integer);
var
  NewLine: string;
begin
  if (SourceLine < 0) or (SourceLine >= FMarkdown.Count) then
    Exit;
  NewLine := FlipTaskMarker(FMarkdown[SourceLine]);
  if NewLine = FMarkdown[SourceLine] then
    Exit;

  PushUndoState;
  ApplyMarkdownLine(SourceLine, NewLine);
end;

function TMarkDownViewer.SearchMatchCount: Integer;
var
  Hay: string;
  Needle: string;
  FoundAt: Integer;
begin
  Result := 0;
  if FSearchText = '' then
    Exit;
  if FSelectableText = '' then
    Repaint;

  Hay := LowerCase(FSelectableText);
  Needle := LowerCase(FSearchText);
  FoundAt := Pos(Needle, Hay);
  while FoundAt > 0 do
  begin
    Inc(Result);
    FoundAt := PosEx(Needle, Hay, FoundAt + Length(Needle));
  end;
end;

function TMarkDownViewer.FindNext: Boolean;
var
  Hay: string;
  Needle: string;
  FoundAt: Integer;
begin
  Result := False;
  if FSearchText = '' then
    Exit;
  if FSelectableText = '' then
    Repaint;

  Hay := LowerCase(FSelectableText);
  Needle := LowerCase(FSearchText);
  FoundAt := PosEx(Needle, Hay, Max(FSelectionAnchor, FSelectionCaret) + 1);
  if FoundAt = 0 then
    FoundAt := Pos(Needle, Hay); // wrap to the top
  if FoundAt = 0 then
    Exit;

  FSelectionAnchor := FoundAt - 1;
  FSelectionCaret := FoundAt - 1 + Length(FSearchText);
  ScrollCaretIntoView;
  Invalidate;
  Result := True;
end;

function TMarkDownViewer.FindPrevious: Boolean;
var
  Hay: string;
  Needle: string;
  Limit: Integer;
  FoundAt: Integer;
  Best: Integer;
  Last: Integer;
begin
  Result := False;
  if FSearchText = '' then
    Exit;
  if FSelectableText = '' then
    Repaint;

  Hay := LowerCase(FSelectableText);
  Needle := LowerCase(FSearchText);

  // Walk every match in order; Best keeps the last one that starts before the
  // current selection, and Last keeps the final match for wrap-around.
  Limit := Min(FSelectionAnchor, FSelectionCaret);
  Best := 0;
  Last := 0;
  FoundAt := Pos(Needle, Hay);
  while FoundAt > 0 do
  begin
    Last := FoundAt;
    if FoundAt <= Limit then
      Best := FoundAt;
    FoundAt := PosEx(Needle, Hay, FoundAt + 1);
  end;
  if Best = 0 then
    Best := Last; // wrap to the last match
  if Best = 0 then
    Exit;

  FSelectionAnchor := Best - 1;
  FSelectionCaret := Best - 1 + Length(FSearchText);
  ScrollCaretIntoView;
  Invalidate;
  Result := True;
end;

procedure TMarkDownViewer.ScrollCaretIntoView;
var
  I: Integer;
  Run: TMarkDownTextRun;
begin
  if FTextRuns.Count = 0 then
    Exit;

  Run := FTextRuns.Last;
  for I := 0 to FTextRuns.Count - 1 do
  begin
    Run := FTextRuns[I];
    if FSelectionCaret <= Run.StartIndex + Length(Run.Text) then
      Break;
  end;

  if Run.Rect.Top < 0 then
    SetScrollPosition(FScrollPos + Run.Rect.Top - MarkdownPadding)
  else if Run.Rect.Bottom > ClientHeight then
    SetScrollPosition(FScrollPos + Run.Rect.Bottom - ClientHeight + MarkdownPadding);
end;

procedure TMarkDownViewer.SelectAllText;
begin
  if FSelectableText = '' then
    Repaint;

  FSelectionAnchor := 0;
  FSelectionCaret := Length(FSelectableText);
  Invalidate;
end;

procedure TMarkDownViewer.SelectAll;
begin
  SelectAllText;
end;

// Inline-format commands, exposed so a host can drive them from a toolbar or
// menu (the Ctrl+B/I/E shortcuts call these). Each wraps the selection in the
// matching markdown markers, or removes them when already applied.
procedure TMarkDownViewer.ToggleBold;
begin
  ToggleInlineFormat('**');
end;

procedure TMarkDownViewer.ToggleItalic;
begin
  ToggleInlineFormat('*');
end;

procedure TMarkDownViewer.ToggleStrikethrough;
begin
  ToggleInlineFormat('~~');
end;

procedure TMarkDownViewer.ToggleInlineCode;
begin
  ToggleInlineFormat('`');
end;

procedure TMarkDownViewer.ToggleHighlight;
begin
  ToggleInlineFormat('==');
end;

procedure TMarkDownViewer.ToggleLink;
var
  SelStart, SelEnd: Integer;
  SourceStart, SourceEnd, Temp: Integer;
  SourceText, Selected: string;
  NewCaret: Integer;
  OldSourcePos: Integer;
begin
  if FReadOnly then Exit;
  if FSelectableText = '' then Exit;

  if not HasSelection then
  begin
    OldSourcePos := SelectableToSourcePosition(FSelectionCaret);
    SourceText := FMarkdown.Text;
    PushUndoState;
    Insert('[]()', SourceText, OldSourcePos + 1);
    ApplyMarkdownText(SourceText);
    NewCaret := SourceToSelectablePosition(OldSourcePos + 1);
    FSelectionAnchor := NewCaret;
    FSelectionCaret := NewCaret;
    FDesiredCaretX := -1;
    ScrollCaretIntoView;
    Invalidate;
    Exit;
  end;

  SelStart := Min(FSelectionAnchor, FSelectionCaret);
  SelEnd := Max(FSelectionAnchor, FSelectionCaret);
  SourceStart := SelectableToSourcePosition(SelStart);
  SourceEnd := SelectableToSourcePosition(SelEnd);
  if SourceEnd < SourceStart then
  begin
    Temp := SourceStart;
    SourceStart := SourceEnd;
    SourceEnd := Temp;
  end;

  SourceText := FMarkdown.Text;
  PushUndoState;
  Selected := Copy(SourceText, SourceStart + 1, SourceEnd - SourceStart);
  Delete(SourceText, SourceStart + 1, SourceEnd - SourceStart);
  Insert('[' + Selected + ']()', SourceText, SourceStart + 1);
  ApplyMarkdownText(SourceText);
  
  NewCaret := SourceToSelectablePosition(SourceStart + Length(Selected) + 3);
  FSelectionAnchor := NewCaret;
  FSelectionCaret := NewCaret;
  FDesiredCaretX := -1;
  ScrollCaretIntoView;
  Invalidate;
end;

// Select the run of non-whitespace characters around the caret (the word under
// it), as on a double-click. Does nothing when the caret is on whitespace.
procedure TMarkDownViewer.SelectWordAtCaret;
var
  L: Integer;
  R: Integer;
  function IsBreak(Index: Integer): Boolean;
  begin
    Result := (Index < 1) or (Index > Length(FSelectableText)) or
      CharInSet(FSelectableText[Index], [' ', #9, #13, #10]);
  end;
begin
  if FSelectableText = '' then
    Repaint;
  L := EnsureRange(FSelectionCaret, 0, Length(FSelectableText));
  R := L;
  while (L > 0) and not IsBreak(L) do
    Dec(L);
  while (R < Length(FSelectableText)) and not IsBreak(R + 1) do
    Inc(R);
  if R <= L then
    Exit;
  FSelectionAnchor := L;
  FSelectionCaret := R;
  FDesiredCaretX := -1;
  Invalidate;
end;

procedure TMarkDownViewer.DblClick;
begin
  inherited DblClick;
  SelectWordAtCaret;
end;

// The current document rendered as an HTML fragment, using the same parser the
// viewer paints with (link references resolved from the document).
function TMarkDownViewer.AsHtml: string;
begin
  Result := MarkdownToHtml(FMarkdown.Text, FLinkReferences);
end;

function TMarkDownViewer.AsHtmlDocument(const ATitle: string): string;
begin
  Result := MarkdownToHtmlDocument(FMarkdown.Text, ATitle);
end;

procedure TMarkDownViewer.SetCodeBackgroundColor(const Value: TColor);
begin
  if FCodeBackgroundColor <> Value then
  begin
    FCodeBackgroundColor := Value;
    Invalidate;
  end;
end;

procedure TMarkDownViewer.SetCodeFontName(const Value: string);
begin
  if FCodeFontName <> Value then
  begin
    FCodeFontName := Value;
    FEffectiveCodeFont := ResolveMonospaceFont(Value);
    InvalidateLayout;
    Invalidate;
  end;
end;

procedure TMarkDownViewer.SetHeadingRuleColor(const Value: TColor);
begin
  if FHeadingRuleColor <> Value then
  begin
    FHeadingRuleColor := Value;
    Invalidate;
  end;
end;

procedure TMarkDownViewer.SetBasePath(const Value: string);
begin
  if FBasePath <> Value then
  begin
    FBasePath := Value;
    Invalidate;
  end;
end;

procedure TMarkDownViewer.SetLinkColor(const Value: TColor);
begin
  if FLinkColor <> Value then
  begin
    FLinkColor := Value;
    Invalidate;
  end;
end;

procedure TMarkDownViewer.SetMarkdown(const Value: TStrings);
begin
  FMarkdown.Assign(Value);
end;

procedure TMarkDownViewer.SetMarkdownText(const Value: string);
begin
  FMarkdown.Text := Value;
end;

procedure TMarkDownViewer.SetQuoteBarColor(const Value: TColor);
begin
  if FQuoteBarColor <> Value then
  begin
    FQuoteBarColor := Value;
    Invalidate;
  end;
end;

procedure TMarkDownViewer.SetSearchHighlightColor(const Value: TColor);
begin
  if FSearchHighlightColor <> Value then
  begin
    FSearchHighlightColor := Value;
    Invalidate;
  end;
end;

procedure TMarkDownViewer.SetHighlightColor(const Value: TColor);
begin
  if FHighlightColor <> Value then
  begin
    FHighlightColor := Value;
    Invalidate;
  end;
end;

procedure TMarkDownViewer.SetSearchText(const Value: string);
begin
  if FSearchText <> Value then
  begin
    FSearchText := Value;
    Invalidate;
  end;
end;

procedure TMarkDownViewer.SetScrollPosition(const Value: Integer);
var
  NewPosition: Integer;
begin
  NewPosition := EnsureRange(Value, 0, MaxScrollPosition);
  if FScrollPos <> NewPosition then
  begin
    FScrollPos := NewPosition;
    UpdateScrollBar;
    Invalidate;
    if Assigned(FOnScroll) then
      FOnScroll(Self);
  end;
end;

procedure TMarkDownViewer.SetReadOnly(const Value: Boolean);
begin
  if FReadOnly <> Value then
  begin
    FReadOnly := Value;
    ClearSelection;
    Invalidate;
  end;
end;

procedure TMarkDownViewer.Undo;
var
  NewText: string;
begin
  if FReadOnly or (FUndoStack.Count = 0) then
    Exit;
  FRedoStack.Add(FMarkdown.Text);
  NewText := FUndoStack[FUndoStack.Count - 1];
  FUndoStack.Delete(FUndoStack.Count - 1);
  ApplyMarkdownText(NewText);
  Repaint;
  FSelectionAnchor := 0;
  FSelectionCaret := 0;
  Invalidate;
end;

procedure TMarkDownViewer.Redo;
var
  NewText: string;
begin
  if FReadOnly or (FRedoStack.Count = 0) then
    Exit;
  FUndoStack.Add(FMarkdown.Text);
  NewText := FRedoStack[FRedoStack.Count - 1];
  FRedoStack.Delete(FRedoStack.Count - 1);
  ApplyMarkdownText(NewText);
  Repaint;
  FSelectionAnchor := 0;
  FSelectionCaret := 0;
  Invalidate;
end;

procedure TMarkDownViewer.UpdateScrollBar;
var
  ScrollInfo: TScrollInfo;
  MaxPos: Integer;
begin
  if not HandleAllocated then
    Exit;

  MaxPos := Max(0, FContentHeight - ClientHeight);
  if FScrollPos > MaxPos then
    FScrollPos := MaxPos;
  if FScrollPos < 0 then
    FScrollPos := 0;

  ZeroMemory(@ScrollInfo, SizeOf(ScrollInfo));
  ScrollInfo.cbSize := SizeOf(ScrollInfo);
  ScrollInfo.fMask := SIF_RANGE or SIF_PAGE or SIF_POS;
  ScrollInfo.nMin := 0;
  ScrollInfo.nMax := Max(0, FContentHeight - 1);
  ScrollInfo.nPage := ClientHeight;
  ScrollInfo.nPos := FScrollPos;
  SetScrollInfo(Handle, SB_VERT, ScrollInfo, True);
  ShowScrollBar(Handle, SB_VERT, FContentHeight > ClientHeight);
end;

procedure TMarkDownViewer.WMEraseBkgnd(var Message: TMessage);
begin
  Message.Result := 1;
end;

procedure TMarkDownViewer.WMGetDlgCode(var Message: TMessage);
begin
  inherited;
  // Leave Tab free for dialog navigation when read-only; while editing the
  // control needs every key (Tab, Enter, Escape) like a multi-line edit.
  Message.Result := Message.Result or DLGC_WANTARROWS;
  if not FReadOnly then
    Message.Result := Message.Result or DLGC_WANTCHARS or DLGC_WANTALLKEYS or DLGC_WANTTAB;
end;

procedure TMarkDownViewer.WMMouseWheel(var Message: TWMMouseWheel);
var
  Delta: Integer;
begin
  Delta := -Message.WheelDelta div WHEEL_DELTA;
  SetScrollPosition(FScrollPos + (Delta * 3 * Max(16, Canvas.TextHeight('Wg'))));
  Message.Result := 1;
end;

procedure TMarkDownViewer.WMVScroll(var Message: TWMVScroll);
var
  NewPosition: Integer;
  ScrollInfo: TScrollInfo;
begin
  ZeroMemory(@ScrollInfo, SizeOf(ScrollInfo));
  ScrollInfo.cbSize := SizeOf(ScrollInfo);
  ScrollInfo.fMask := SIF_ALL;
  GetScrollInfo(Handle, SB_VERT, ScrollInfo);

  NewPosition := FScrollPos;
  case Message.ScrollCode of
    SB_LINEUP:
      Dec(NewPosition, 24);
    SB_LINEDOWN:
      Inc(NewPosition, 24);
    SB_PAGEUP:
      Dec(NewPosition, ClientHeight);
    SB_PAGEDOWN:
      Inc(NewPosition, ClientHeight);
    SB_THUMBPOSITION, SB_THUMBTRACK:
      NewPosition := ScrollInfo.nTrackPos;
  end;

  SetScrollPosition(NewPosition);
end;
end.
