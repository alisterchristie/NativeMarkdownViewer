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
  MarkdownViewer.Model;

type
  TMarkDownLinkClickEvent = procedure(Sender: TObject; const Url: string) of object;

  TMarkDownViewer = class(TCustomControl)
  private
    FMarkdown: TStringList;
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
    FOnChange: TNotifyEvent;
    FOnLinkClick: TMarkDownLinkClickEvent;
    FOnScroll: TNotifyEvent;
    function GetCachedImage(const ImagePath: string): TPicture;
    function GetMarkdown: TStrings;
    function GetMarkdownText: string;
    function GetMaxScrollPosition: Integer;
    function HasSelection: Boolean;
    function HitTestTextPosition(X, Y: Integer): Integer;
    function IsMarkdownStored: Boolean;
    function SelectableToSourcePosition(Position: Integer): Integer;
    function SourceToSelectablePosition(Position: Integer): Integer;
    procedure ClearSelection;
    procedure ClearInlineTokenCaches;
    procedure CopySelectionToClipboard(PlainText: Boolean);
    procedure DeleteSelectionOrCharacter(Backwards: Boolean);
    procedure InsertTextAtSelection(const Value: string);
    procedure InvalidateLayout;
    procedure MarkdownChanged(Sender: TObject);
    procedure MoveCaret(Delta: Integer; ExtendSelection: Boolean);
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
    function GetEffectiveBackground: TColor;
    function GetEffectiveTextColor: TColor;
    function GetEffectiveSelectionBackground: TColor;
    function GetEffectiveSelectionTextColor: TColor;
    function GetEffectiveGridlineColor: TColor;
    function GetEffectiveTableHeaderColor: TColor;
    function GetEffectiveCodeBackgroundColor: TColor;
    function GetEffectiveSearchHighlightColor: TColor;
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
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Paint; override;
    procedure Resize; override;
    procedure SetStyleElements(const Value: TStyleElements); override;
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
  MarkdownViewer.Renderer;

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

function IsWhitespaceText(const S: string): Boolean;
var
  I: Integer;
begin
  Result := S <> '';
  for I := 1 to Length(S) do
    if not CharInSet(S[I], [' ', #9, #13, #10]) then
      Exit(False);
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
  FMarkdown := TStringList.Create;
  FMarkdown.OnChange := MarkdownChanged;
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
end;

destructor TMarkDownViewer.Destroy;
begin
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

function TMarkDownViewer.GetEffectiveBackground: TColor;
begin
  if UseThemedColors then
    Result := StyleServices.GetSystemColor(clWindow)
  else
    Result := Color;
end;

function TMarkDownViewer.GetEffectiveTextColor: TColor;
begin
  if UseThemedColors then
    Result := StyleServices.GetSystemColor(clWindowText)
  else
    Result := Font.Color;
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
  if UseThemedColors then
    Result := StyleServices.GetSystemColor(clBtnShadow)
  else
    Result := clSilver;
end;

function TMarkDownViewer.GetEffectiveTableHeaderColor: TColor;
begin
  if UseThemedColors then
    Result := StyleServices.GetSystemColor(clBtnFace)
  else
    Result := $00F7F7F7;
end;

function TMarkDownViewer.GetEffectiveCodeBackgroundColor: TColor;
var
  BaseColor: TColor;
  R, G, B: Integer;
  Luminance: Double;
begin
  if FCodeBackgroundColor <> clDefault then
    Exit(FCodeBackgroundColor);

  BaseColor := ColorToRGB(GetEffectiveBackground);
  R := GetRValue(BaseColor);
  G := GetGValue(BaseColor);
  B := GetBValue(BaseColor);
  Luminance := 0.299 * R + 0.587 * G + 0.114 * B;

  if Luminance > 128 then
    Result := RGB(Max(0, R - 28), Max(0, G - 28), Max(0, B - 28))
  else
    Result := RGB(Min(255, R + 32), Min(255, G + 32), Min(255, B + 32));
end;

function TMarkDownViewer.GetEffectiveSearchHighlightColor: TColor;
var
  BaseColor: TColor;
  R, G, B: Integer;
  Luminance: Double;
begin
  if FSearchHighlightColor <> clDefault then
    Exit(FSearchHighlightColor);

  BaseColor := ColorToRGB(GetEffectiveBackground);
  R := GetRValue(BaseColor);
  G := GetGValue(BaseColor);
  B := GetBValue(BaseColor);
  Luminance := 0.299 * R + 0.587 * G + 0.114 * B;

  if Luminance > 128 then
    Result := RGB(Min(255, R + 20), Min(255, G + 20), Max(0, B - 40))
  else
    Result := RGB(Min(255, R + 64), Min(255, G + 64), Min(255, B + 72));
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

procedure TMarkDownViewer.KeyDown(var Key: Word; Shift: TShiftState);
var
  Handled: Boolean;
begin
  inherited KeyDown(Key, Shift);
  Handled := True;

  if ssCtrl in Shift then
  begin
    case Key of
      Ord('A'):
        SelectAllText;
      Ord('C'):
        CopySelectionToClipboard(ssShift in Shift);
      Ord('V'):
        if not FReadOnly then
          InsertTextAtSelection(ReadClipboardText)
        else
          Handled := False;
      Ord('X'):
        if not FReadOnly and HasSelection then
        begin
          CopySelectionToClipboard(False);
          InsertTextAtSelection('');
        end
        else
          Handled := False;
      Ord('Y'):
        if not FReadOnly then
          Redo
        else
          Handled := False;
      Ord('Z'):
        if not FReadOnly then
        begin
          if ssShift in Shift then
            Redo
          else
            Undo;
        end
        else
          Handled := False;
      VK_INSERT:
        CopySelectionToClipboard(True);
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
      Handled := False;
    end;
  end
  else if not FReadOnly then
  begin
    case Key of
      VK_LEFT:
        MoveCaret(-1, ssShift in Shift);
      VK_RIGHT:
        MoveCaret(1, ssShift in Shift);
      VK_UP:
        MoveCaretVertical(-1, ssShift in Shift);
      VK_DOWN:
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
        if ssShift in Shift then
          ChangeHeadingLevel(-1)
        else
          ChangeHeadingLevel(1);
    else
      Handled := False;
    end;
  end
  else
  begin
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
      Handled := False;
    end;
  end;

  if Handled then
    Key := 0;
end;

procedure TMarkDownViewer.KeyPress(var Key: Char);
begin
  inherited KeyPress(Key);
  if FReadOnly then
    Exit;

  case Key of
    #8:
      Key := #0;
    #13:
      begin
        InsertTextAtSelection(sLineBreak);
        Key := #0;
      end;
    #32..#65535:
      begin
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
begin
  Result := 0;
  Position := EnsureRange(Position, 0, Length(FSelectableText));
  for I := 0 to FCopyChunks.Count - 1 do
  begin
    Chunk := FCopyChunks[I];
    if Chunk.SourceStartIndex < 0 then
      Continue;
    if Position < Chunk.StartIndex then
      Exit(Chunk.SourceStartIndex);
    if (Position = Chunk.StartIndex + Length(Chunk.Text)) and
      (I < FCopyChunks.Count - 1) and
      (FCopyChunks[I + 1].StartIndex = Position) and
      (FCopyChunks[I + 1].SourceStartIndex >= 0) then
      Continue;
    if Position <= Chunk.StartIndex + Length(Chunk.Text) then
      Exit(Chunk.SourceStartIndex +
        EnsureRange(Position - Chunk.StartIndex, 0, Length(Chunk.Text)));
    Result := Chunk.SourceStartIndex + Length(Chunk.Text);
  end;
  Result := EnsureRange(Result, 0, Length(FMarkdown.Text));
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
    if Chunk.SourceStartIndex < 0 then
      Continue;
    if Position < Chunk.SourceStartIndex then
      Exit(Chunk.StartIndex);
    if Position <= Chunk.SourceStartIndex + Length(Chunk.Text) then
      Exit(Chunk.StartIndex +
        EnsureRange(Position - Chunk.SourceStartIndex, 0, Length(Chunk.Text)));
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
begin
  if HasSelection then
  begin
    InsertTextAtSelection('');
    Exit;
  end;

  if Backwards then
  begin
    if FSelectionCaret = 0 then
      Exit;
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
  SavedScrollPos: Integer;
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

  SourceText := FMarkdown.Text;
  FUndoStack.Add(SourceText);
  while FUndoStack.Count > MaxUndoDepth do
    FUndoStack.Delete(0);
  FRedoStack.Clear;
  Delete(SourceText, SourceStart + 1, SourceEnd - SourceStart);
  Insert(Value, SourceText, SourceStart + 1);
  NewSourceCaret := SourceStart + Length(Value);

  SavedScrollPos := FScrollPos;
  FApplyingEdit := True;
  try
    FMarkdown.Text := SourceText;
  finally
    FApplyingEdit := False;
  end;
  FScrollPos := SavedScrollPos;
  UpdateScrollBar;
  Repaint;
  FSelectionCaret := SourceToSelectablePosition(NewSourceCaret);
  FSelectionAnchor := FSelectionCaret;
  FDesiredCaretX := -1;
  ScrollCaretIntoView;
  Invalidate;
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

  FSelectionCaret := NewPosition;
  if not ExtendSelection then
    FSelectionAnchor := NewPosition;
  FDesiredCaretX := -1;
  ScrollCaretIntoView;
  Invalidate;
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

  FSelectionCaret := NewPosition;
  if not ExtendSelection then
    FSelectionAnchor := NewPosition;
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
  Run: TMarkDownTextRun;
begin
  if FSelectableText = '' then
    Repaint;
  if FTextRuns.Count = 0 then
    Exit;

  CurrentRun := FTextRuns.Last;
  for I := 0 to FTextRuns.Count - 1 do
  begin
    Run := FTextRuns[I];
    if (FSelectionCaret >= Run.StartIndex) and
      (FSelectionCaret <= Run.StartIndex + Length(Run.Text)) then
    begin
      CurrentRun := Run;
      if FSelectionCaret = Run.StartIndex then
        Break;
    end;
  end;

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

  FSelectionCaret := NewPosition;
  if not ExtendSelection then
    FSelectionAnchor := NewPosition;
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
  LocalPosition: Integer;
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

  if not ExtendSelection and HasSelection then
  begin
    if Direction < 0 then
      FSelectionCaret := Min(FSelectionAnchor, FSelectionCaret)
    else
      FSelectionCaret := Max(FSelectionAnchor, FSelectionCaret);
    FSelectionAnchor := FSelectionCaret;
  end;

  CurrentRun := FTextRuns.Last;
  for I := 0 to FTextRuns.Count - 1 do
  begin
    Run := FTextRuns[I];
    if (FSelectionCaret >= Run.StartIndex) and
      (FSelectionCaret <= Run.StartIndex + Length(Run.Text)) then
    begin
      CurrentRun := Run;
      if FSelectionCaret = Run.StartIndex then
        Break;
    end;
  end;

  if FDesiredCaretX < 0 then
  begin
    Canvas.Font.Assign(Font);
    Canvas.Font.Name := CurrentRun.FontName;
    Canvas.Font.Size := CurrentRun.FontSize;
    Canvas.Font.Style := CurrentRun.FontStyle;
    LocalPosition := EnsureRange(FSelectionCaret - CurrentRun.StartIndex,
      0, Length(CurrentRun.Text));
    FDesiredCaretX := CurrentRun.Rect.Left +
      Canvas.TextWidth(Copy(CurrentRun.Text, 1, LocalPosition));
  end;

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

  FSelectionCaret := NewPosition;
  if not ExtendSelection then
    FSelectionAnchor := NewPosition;
  SetScrollPosition(FScrollPos + TargetTop - CurrentTop);
end;

procedure TMarkDownViewer.MoveCaretVertical(Direction: Integer;
  ExtendSelection: Boolean);
var
  CurrentRun: TMarkDownTextRun;
  CurrentTop: Integer;
  I: Integer;
  LocalPosition: Integer;
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

  if not ExtendSelection and HasSelection then
  begin
    if Direction < 0 then
      FSelectionCaret := Min(FSelectionAnchor, FSelectionCaret)
    else
      FSelectionCaret := Max(FSelectionAnchor, FSelectionCaret);
    FSelectionAnchor := FSelectionCaret;
  end;

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

  if FDesiredCaretX < 0 then
  begin
    Canvas.Font.Assign(Font);
    Canvas.Font.Name := CurrentRun.FontName;
    Canvas.Font.Size := CurrentRun.FontSize;
    Canvas.Font.Style := CurrentRun.FontStyle;
    LocalPosition := EnsureRange(FSelectionCaret - CurrentRun.StartIndex,
      0, Length(CurrentRun.Text));
    FDesiredCaretX := CurrentRun.Rect.Left +
      Canvas.TextWidth(Copy(CurrentRun.Text, 1, LocalPosition));
  end;

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

  FSelectionCaret := NewPosition;
  if not ExtendSelection then
    FSelectionAnchor := NewPosition;

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

procedure TMarkDownViewer.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Position: Integer;
begin
  inherited;
  if CanFocus then
    SetFocus;
  if Button <> mbLeft then
    Exit;

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

  if IsTaskBox or (IsLink and (FReadOnly or (ssCtrl in Shift))) then
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

procedure TMarkDownViewer.Paint;
var
  Blocks: TMarkDownBlockList;
  I: Integer;
  Y: Integer;
  TextLeft: Integer;
  ContentWidth: Integer;
  LineHeight: Integer;
  TotalHeight: Integer;
  TokenHeight: Integer;
  Tokens: TMarkDownInlineList;
  Block: TMarkDownBlock;
  Lines: TStringList;
  LineIndex: Integer;
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
  SourceScanPosition: Integer;
  SourceText: string;

  function InlineTokensForBlock(ABlock: TMarkDownBlock): TMarkDownInlineList;
  begin
    if ABlock.InlineTokens = nil then
      ABlock.InlineTokens := TMarkDownBlockParser.ParseInline(ABlock.Text, FLinkReferences);
    Result := ABlock.InlineTokens;
  end;

  function SelectionRange(out SelStart, SelEnd: Integer): Boolean;
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

  function FindSourceStart(const AText: string): Integer;
  var
    FoundAt: Integer;
  begin
    Result := -1;
    if AText = '' then
      Exit;

    // Rendered whitespace rarely matches the source exactly: paragraph
    // lines are joined with a space where the source has a line break,
    // and syntax such as '**' sits between words. Match any whitespace
    // run instead of searching for the literal text, otherwise the scan
    // position jumps into a later line and derails every atom after it.
    if IsWhitespaceText(AText) then
    begin
      FoundAt := SourceScanPosition;
      while (FoundAt <= Length(SourceText)) and
        not CharInSet(SourceText[FoundAt], [' ', #9, #13, #10]) do
        Inc(FoundAt);
      if FoundAt > Length(SourceText) then
        Exit;
      Result := FoundAt - 1;
      // An exact match consumes only itself so consecutive line breaks
      // (blank lines in code blocks) map one atom per break; otherwise
      // consume the whole run, e.g. a join space standing in for a CRLF.
      if Copy(SourceText, FoundAt, Length(AText)) = AText then
        SourceScanPosition := FoundAt + Length(AText)
      else
      begin
        while (FoundAt <= Length(SourceText)) and
          CharInSet(SourceText[FoundAt], [' ', #9, #13, #10]) do
          Inc(FoundAt);
        SourceScanPosition := FoundAt;
      end;
      Exit;
    end;

    FoundAt := PosEx(AText, SourceText, SourceScanPosition);
    if FoundAt = 0 then
      Exit;
    Result := FoundAt - 1;
    SourceScanPosition := FoundAt + Length(AText);
  end;

  procedure AddCopyChunk(TextStart, SourceStart: Integer;
    const AText, AMarkdownText: string);
  var
    Chunk: TMarkDownCopyChunk;
  begin
    if AText = '' then
      Exit;

    Chunk.StartIndex := TextStart;
    Chunk.SourceStartIndex := SourceStart;
    Chunk.Text := AText;
    if AMarkdownText <> '' then
      Chunk.MarkdownText := AMarkdownText
    else
      Chunk.MarkdownText := AText;
    FCopyChunks.Add(Chunk);
  end;

  function AddSelectableRun(const ARect: TRect; const AText: string;
    const AMarkdownText: string = ''): Integer;
  var
    Run: TMarkDownTextRun;
  begin
    Result := Length(FSelectableText);
    if AText = '' then
      Exit;

    Run.Rect := ARect;
    Run.FontName := Canvas.Font.Name;
    Run.FontSize := Canvas.Font.Size;
    Run.FontStyle := Canvas.Font.Style;
    if AMarkdownText <> '' then
      Run.MarkdownText := AMarkdownText
    else
      Run.MarkdownText := AText;
    Run.StartIndex := Result;
    Run.SourceStartIndex := FindSourceStart(AText);
    Run.Text := AText;
    FTextRuns.Add(Run);
    FSelectableText := FSelectableText + AText;
    AddCopyChunk(Result, Run.SourceStartIndex, AText, AMarkdownText);
  end;

  procedure AddSelectableText(const AText: string; const AMarkdownText: string = '';
    AHasSource: Boolean = True);
  var
    SourceStart: Integer;
    TextStart: Integer;
  begin
    if AText = '' then
      Exit;

    TextStart := Length(FSelectableText);
    FSelectableText := FSelectableText + AText;
    if AHasSource then
      SourceStart := FindSourceStart(AText)
    else
      SourceStart := -1;
    AddCopyChunk(TextStart, SourceStart, AText, AMarkdownText);
  end;

  // AHasSource=False marks breaks that exist only in the rendered layout
  // (word wrap, table cell separators); they must not consume source text
  // or the caret-to-source mapping derails for everything that follows.
  procedure AddSelectableBreak(AHasSource: Boolean = True);
  begin
    if FSelectableText = '' then
      Exit;
    if not EndsText(sLineBreak, FSelectableText) then
      AddSelectableText(sLineBreak, '', AHasSource);
  end;

  procedure DrawCaret;
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

  procedure DrawSelectionBackground(const AText: string; TextX, TextY, TextHeight, TextStart: Integer);
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

  procedure DrawSelectableText(const AText: string; TextX, TextY, TextStart: Integer);
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

  procedure AssignBaseFont(Style: TFontStyles; SizeDelta: Integer; const FontName: string = '');
  begin
    Canvas.Font.Assign(Font);
    Canvas.Font.Style := Style;
    Canvas.Font.Size := Max(1, Font.Size + SizeDelta);
    if FontName <> '' then
      Canvas.Font.Name := FontName;
    if UseThemedColors then
      Canvas.Font.Color := GetEffectiveTextColor;
  end;

  procedure AssignInlineFont(const Token: TMarkDownInlineToken; BaseStyle: TFontStyles; SizeDelta: Integer);
  begin
    Canvas.Font.Assign(Font);
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

  function DrawInline(ATokens: TMarkDownInlineList; ALeft, ATop, AWidth: Integer; ADraw: Boolean;
    BaseStyle: TFontStyles = []; SizeDelta: Integer = 0;
    AAlignment: TAlignment = taLeftJustify; const AMarkdownLinePrefix: string = ''): Integer;
  var
    TokenIndex: Integer;
    AtomIndex: Integer;
    AtomStart: Integer;
    LineUsed: Integer;
    X: Integer;
    YPos: Integer;
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
          TextStart := AddSelectableRun(AtomRect, Atom, AtomMarkdown);
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
            DrawSearchHighlights(Atom, X, YPos + 2, LineHeight - 2);
            DrawSelectionBackground(Atom, X, YPos + 2, LineHeight - 2, TextStart);
            OldBkMode := SetBkMode(Canvas.Handle, TRANSPARENT);
            DrawSelectableText(Atom, X, YPos + 2, TextStart);
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

    Result := YPos + LineHeight - ATop;
  end;

  function ResolveImagePath(const Url: string): string;
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

  function DrawImageBlock(const AltText, Url: string; ALeft, ATop, AWidth: Integer): Integer;
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

  function TableAlignmentFromCell(const Cell: string): TAlignment;
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

  function DrawTable(const TableText: string; ALeft, ATop, AWidth: Integer): Integer;
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

          CellTokens := TMarkDownBlockParser.ParseInline(CellText, FLinkReferences);
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
        AddSelectableBreak;
        Inc(RowTop, RowHeight);
      end;

      Result := RowTop - ATop;
    finally
      AlignCells.Free;
      Rows.Free;
      SourceLines.Free;
    end;
  end;

begin
  Canvas.Brush.Color := GetEffectiveBackground;
  Canvas.FillRect(ClientRect);

  FLinkHits.Clear;
  FTaskHits.Clear;
  FTextRuns.Clear;
  FCopyChunks.Clear;
  FSelectableText := '';
  SourceText := FMarkdown.Text;
  SourceScanPosition := 1;

  Blocks := FBlocks;
  Y := MarkdownPadding - FScrollPos;
  FLastBlockTop := Y;
  TextLeft := MarkdownPadding;
  ContentWidth := Max(10, ClientWidth - (MarkdownPadding * 2) - GetSystemMetrics(SM_CXVSCROLL));

  for I := 0 to Blocks.Count - 1 do
  begin
    if I = Blocks.Count - 1 then
      FLastBlockTop := Y;
    Block := Blocks[I];
    Block.LayoutTop := Y + FScrollPos;
    case Block.Kind of
      bkHeading:
        begin
          AssignBaseFont([fsBold], HeadingFontSizeDelta(Block.Level));
          Tokens := InlineTokensForBlock(Block);
          TokenHeight := DrawInline(Tokens, TextLeft, Y, ContentWidth, True, [fsBold],
            HeadingFontSizeDelta(Block.Level), taLeftJustify, StringOfChar('#', Block.Level) + ' ');
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
            [], 0, taLeftJustify, '> ');
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
            [], 0, taLeftJustify, StringOfChar(' ', Max(0, Block.IndentLevel) * 2) + ListMarker);
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
            TokenHeight := DrawTable(Block.Text, TextLeft, Y, ContentWidth);
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
            TokenHeight := Max(1, Lines.Count) * LineHeight + 16;
            R := Rect(TextLeft, Y + 2, TextLeft + ContentWidth, Y + TokenHeight);
            CanvasState := TCanvasState.Save(Canvas);
            try
              Canvas.Brush.Color := GetEffectiveCodeBackgroundColor;
              Canvas.FillRect(R);
              Canvas.Brush.Style := bsClear;
              for LineIndex := 0 to Lines.Count - 1 do
              begin
                LineTextStart := AddSelectableRun(
                  Rect(TextLeft + 8, Y + 8 + (LineIndex * LineHeight),
                    TextLeft + 8 + Canvas.TextWidth(Lines[LineIndex]),
                    Y + 8 + (LineIndex * LineHeight) + LineHeight),
                  Lines[LineIndex]);
                if (Y + 8 + (LineIndex * LineHeight) + LineHeight >= 0) and
                  (Y + 8 + (LineIndex * LineHeight) <= ClientHeight) then
                begin
                  DrawSelectionBackground(Lines[LineIndex], TextLeft + 8,
                    Y + 8 + (LineIndex * LineHeight), LineHeight, LineTextStart);
                  OldBkMode := SetBkMode(Canvas.Handle, TRANSPARENT);
                  DrawSelectableText(Lines[LineIndex], TextLeft + 8,
                    Y + 8 + (LineIndex * LineHeight), LineTextStart);
                  SetBkMode(Canvas.Handle, OldBkMode);
                end;
                // Unconditional break so blank code lines survive in the
                // selectable text (AddSelectableBreak collapses repeats).
                if LineIndex < Lines.Count - 1 then
                  AddSelectableText(sLineBreak);
              end;
              Canvas.Brush.Style := bsSolid;
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
      TokenHeight := DrawInline(Tokens, TextLeft, Y, ContentWidth, True);
      Inc(Y, TokenHeight + ParagraphSpacing);
    end;
    Block.LayoutHeight := Y + FScrollPos - Block.LayoutTop;
    Block.LayoutWidth := ContentWidth;
    AddSelectableBreak;
  end;

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
  while (P > 0) and (P + 1 < SourcePos) do
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
  SavedScrollPos: Integer;
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

    FUndoStack.Add(FMarkdown.Text);
    while FUndoStack.Count > MaxUndoDepth do
      FUndoStack.Delete(0);
    FRedoStack.Clear;

    SavedScrollPos := FScrollPos;
    FApplyingEdit := True;
    try
      FMarkdown[LineIdx] := NewLine;
    finally
      FApplyingEdit := False;
    end;
    FScrollPos := SavedScrollPos;
    UpdateScrollBar;

    NewSourcePos := OldSourcePos + 2;
    Repaint;
    FSelectionCaret := SourceToSelectablePosition(NewSourcePos);
    FSelectionAnchor := FSelectionCaret;
    FDesiredCaretX := -1;
    ScrollCaretIntoView;
    Invalidate;
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
        FUndoStack.Add(FMarkdown.Text);
        while FUndoStack.Count > MaxUndoDepth do
          FUndoStack.Delete(0);
        FRedoStack.Clear;
        SavedScrollPos := FScrollPos;
        FApplyingEdit := True;
        try
          FMarkdown[UnderlineIdx] := '';
        finally
          FApplyingEdit := False;
        end;
        FScrollPos := SavedScrollPos;
        UpdateScrollBar;
        Repaint;
        FSelectionCaret := SourceToSelectablePosition(OldSourcePos);
        FSelectionAnchor := FSelectionCaret;
        FDesiredCaretX := -1;
        ScrollCaretIntoView;
        Invalidate;
        Exit;
      end;
      // H2 → H1: change underline from - to =
      UnderlineLen := Length(Trim(FMarkdown[UnderlineIdx]));
      NewLine := StringOfChar('=', UnderlineLen);
    end;

    FUndoStack.Add(FMarkdown.Text);
    while FUndoStack.Count > MaxUndoDepth do
      FUndoStack.Delete(0);
    FRedoStack.Clear;

    SavedScrollPos := FScrollPos;
    FApplyingEdit := True;
    try
      FMarkdown[UnderlineIdx] := NewLine;
    finally
      FApplyingEdit := False;
    end;
    FScrollPos := SavedScrollPos;
    UpdateScrollBar;

    // Setext underline change doesn't affect caret position mapping
    Repaint;
    FSelectionCaret := SourceToSelectablePosition(OldSourcePos);
    FSelectionAnchor := FSelectionCaret;
    FDesiredCaretX := -1;
    ScrollCaretIntoView;
    Invalidate;
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

    FUndoStack.Add(FMarkdown.Text);
    while FUndoStack.Count > MaxUndoDepth do
      FUndoStack.Delete(0);
    FRedoStack.Clear;
    SavedScrollPos := FScrollPos;
    FApplyingEdit := True;
    try
      FMarkdown[Block.SourceStartLine] := NewLine;
    finally
      FApplyingEdit := False;
    end;
    FScrollPos := SavedScrollPos;
    UpdateScrollBar;

    // Caret shifts back by the prefix length (including the space after #)
    NewSourcePos := OldSourcePos - OldPrefixLen;
    if NewSourcePos < 0 then
      NewSourcePos := 0;
    Repaint;
    FSelectionCaret := SourceToSelectablePosition(NewSourcePos);
    FSelectionAnchor := FSelectionCaret;
    FDesiredCaretX := -1;
    ScrollCaretIntoView;
    Invalidate;
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

  FUndoStack.Add(FMarkdown.Text);
  while FUndoStack.Count > MaxUndoDepth do
    FUndoStack.Delete(0);
  FRedoStack.Clear;

  SavedScrollPos := FScrollPos;
  FApplyingEdit := True;
  try
    FMarkdown[Block.SourceStartLine] := NewLine;
  finally
    FApplyingEdit := False;
  end;
  FScrollPos := SavedScrollPos;
  UpdateScrollBar;

  // Adjust caret: if it was past the prefix, shift by prefix delta
  if OldSourcePos >= LineStartSourcePos(Block.SourceStartLine) + OldPrefixLen then
    NewSourcePos := OldSourcePos + PrefixDelta
  else
    NewSourcePos := OldSourcePos;

  Repaint;
  FSelectionCaret := SourceToSelectablePosition(NewSourcePos);
  FSelectionAnchor := FSelectionCaret;
  FDesiredCaretX := -1;
  ScrollCaretIntoView;
  Invalidate;
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

  FUndoStack.Add(FMarkdown.Text);
  while FUndoStack.Count > MaxUndoDepth do
    FUndoStack.Delete(0);
  FRedoStack.Clear;

  FApplyingEdit := True;
  try
    FMarkdown[SourceLine] := NewLine;
  finally
    FApplyingEdit := False;
  end;
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
  SavedScrollPos: Integer;
begin
  if FReadOnly or (FUndoStack.Count = 0) then
    Exit;
  FRedoStack.Add(FMarkdown.Text);
  SavedScrollPos := FScrollPos;
  FApplyingEdit := True;
  try
    FMarkdown.Text := FUndoStack[FUndoStack.Count - 1];
  finally
    FApplyingEdit := False;
  end;
  FUndoStack.Delete(FUndoStack.Count - 1);
  FScrollPos := SavedScrollPos;
  UpdateScrollBar;
  Repaint;
  FSelectionAnchor := 0;
  FSelectionCaret := 0;
  Invalidate;
end;

procedure TMarkDownViewer.Redo;
var
  SavedScrollPos: Integer;
begin
  if FReadOnly or (FRedoStack.Count = 0) then
    Exit;
  FUndoStack.Add(FMarkdown.Text);
  SavedScrollPos := FScrollPos;
  FApplyingEdit := True;
  try
    FMarkdown.Text := FRedoStack[FRedoStack.Count - 1];
  finally
    FApplyingEdit := False;
  end;
  FRedoStack.Delete(FRedoStack.Count - 1);
  FScrollPos := SavedScrollPos;
  UpdateScrollBar;
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
