unit MarkdownViewerVCL;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.Types,
  Winapi.Messages,
  Winapi.Windows,
  Vcl.Controls,
  Vcl.Graphics;

type
  TMarkDownLinkClickEvent = procedure(Sender: TObject; const Url: string) of object;

  TMarkDownBlockKind = (bkParagraph, bkHeading, bkQuote, bkListItem, bkCodeBlock, bkRule, bkTable);

  TMarkDownBlock = class
  public
    Kind: TMarkDownBlockKind;
    Text: string;
    Level: Integer;
    Ordered: Boolean;
    Number: Integer;
    IsTask: Boolean;
    TaskChecked: Boolean;
  end;

  TMarkDownLinkHit = record
    Rect: TRect;
    Url: string;
  end;

  TMarkDownBlockList = TObjectList<TMarkDownBlock>;
  TMarkDownLinkHitList = TList<TMarkDownLinkHit>;

  TMarkDownViewer = class(TCustomControl)
  private
    FMarkdown: TStringList;
    FBlocks: TMarkDownBlockList;
    FLinkHits: TMarkDownLinkHitList;
    FScrollPos: Integer;
    FContentHeight: Integer;
    FLinkColor: TColor;
    FCodeBackgroundColor: TColor;
    FQuoteBarColor: TColor;
    FOnLinkClick: TMarkDownLinkClickEvent;
    function GetMarkdown: TStrings;
    function GetMarkdownText: string;
    function IsMarkdownStored: Boolean;
    procedure MarkdownChanged(Sender: TObject);
    procedure SetCodeBackgroundColor(const Value: TColor);
    procedure SetLinkColor(const Value: TColor);
    procedure SetMarkdown(const Value: TStrings);
    procedure SetMarkdownText(const Value: string);
    procedure SetQuoteBarColor(const Value: TColor);
    procedure UpdateScrollBar;
    procedure WMErasBkgnd(var Message: TMessage); message WM_ERASEBKGND;
    procedure WMVScroll(var Message: TWMVScroll); message WM_VSCROLL;
    procedure WMMouseWheel(var Message: TWMMouseWheel); message WM_MOUSEWHEEL;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure LoadFromFile(const FileName: string);
    property MarkdownText: string read GetMarkdownText write SetMarkdownText;
  published
    property Align;
    property Anchors;
    property Color default clWindow;
    property CodeBackgroundColor: TColor read FCodeBackgroundColor write SetCodeBackgroundColor default $00F2F2F2;
    property Constraints;
    property Enabled;
    property Font;
    property LinkColor: TColor read FLinkColor write SetLinkColor default clHighlight;
    property Markdown: TStrings read GetMarkdown write SetMarkdown stored IsMarkdownStored;
    property ParentColor;
    property ParentFont;
    property PopupMenu;
    property QuoteBarColor: TColor read FQuoteBarColor write SetQuoteBarColor default clSilver;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property OnClick;
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
  end;

procedure Register;

implementation

uses
  System.UITypes,
  System.Math,
  System.StrUtils,
  System.SysUtils,
  Winapi.ShellAPI;

const
  MarkdownPadding = 14;
  ParagraphSpacing = 9;

type
  TMarkDownInlineKind = (ikText, ikBold, ikItalic, ikBoldItalic, ikCode, ikLink);

  TMarkDownInlineToken = record
    Kind: TMarkDownInlineKind;
    Text: string;
    Url: string;
  end;

  TMarkDownInlineList = TList<TMarkDownInlineToken>;

function TrimLeftOnly(const S: string): string;
var
  I: Integer;
begin
  I := 1;
  while (I <= Length(S)) and CharInSet(S[I], [' ', #9]) do
    Inc(I);
  Result := Copy(S, I, MaxInt);
end;

function StartsWithFence(const S: string): Boolean;
begin
  Result := Copy(TrimLeftOnly(S), 1, 3) = '```';
end;

function IsRuleLine(const S: string): Boolean;
var
  I: Integer;
  C: Char;
  T: string;
begin
  T := StringReplace(Trim(S), ' ', '', [rfReplaceAll]);
  Result := Length(T) >= 3;
  if not Result then
    Exit;

  C := T[1];
  Result := CharInSet(C, ['-', '*', '_']);
  if Result then
    for I := 2 to Length(T) do
      if T[I] <> C then
      begin
        Result := False;
        Break;
      end;
end;

procedure SplitTableRow(const Line: string; Cells: TStrings);
var
  S: string;
  I: Integer;
  Start: Integer;
begin
  Cells.Clear;
  S := Trim(Line);
  if (S <> '') and (S[1] = '|') then
    Delete(S, 1, 1);
  if (S <> '') and (S[Length(S)] = '|') then
    Delete(S, Length(S), 1);

  Start := 1;
  for I := 1 to Length(S) do
    if S[I] = '|' then
    begin
      Cells.Add(Trim(Copy(S, Start, I - Start)));
      Start := I + 1;
    end;
  Cells.Add(Trim(Copy(S, Start, MaxInt)));
end;

function IsPipeTableRow(const Line: string): Boolean;
var
  T: string;
begin
  T := Trim(Line);
  Result := (T <> '') and (Pos('|', T) > 0);
end;

function IsTableAlignCell(const Cell: string): Boolean;
var
  I: Integer;
  DashCount: Integer;
  T: string;
begin
  T := Trim(Cell);
  Result := T <> '';
  if not Result then
    Exit;

  if T[1] = ':' then
    Delete(T, 1, 1);
  if (T <> '') and (T[Length(T)] = ':') then
    Delete(T, Length(T), 1);

  DashCount := 0;
  for I := 1 to Length(T) do
    if T[I] = '-' then
      Inc(DashCount)
    else if not CharInSet(T[I], [' ', #9]) then
    begin
      Result := False;
      Exit;
    end;

  Result := DashCount >= 3;
end;

function IsTableSeparator(const Line: string): Boolean;
var
  Cells: TStringList;
  I: Integer;
begin
  Result := False;
  if not IsPipeTableRow(Line) then
    Exit;

  Cells := TStringList.Create;
  try
    SplitTableRow(Line, Cells);
    Result := Cells.Count > 0;
    for I := 0 to Cells.Count - 1 do
      if not IsTableAlignCell(Cells[I]) then
      begin
        Result := False;
        Break;
      end;
  finally
    Cells.Free;
  end;
end;

function IsTableStart(Lines: TStrings; Index: Integer): Boolean;
begin
  Result := (Index + 1 < Lines.Count) and IsPipeTableRow(Lines[Index]) and IsTableSeparator(Lines[Index + 1]);
end;

procedure ExtractTaskMarker(var Text: string; out IsTask, TaskChecked: Boolean);
var
  T: string;
begin
  T := TrimLeftOnly(Text);
  IsTask := (Length(T) >= 3) and (T[1] = '[') and (T[3] = ']') and
    ((T[2] = ' ') or (UpCase(T[2]) = 'X')) and
    ((Length(T) = 3) or CharInSet(T[4], [' ', #9]));
  TaskChecked := IsTask and (UpCase(T[2]) = 'X');
  if IsTask then
    Text := Trim(Copy(T, 4, MaxInt));
end;

function TryParseHeading(const Line: string; out Text: string; out Level: Integer): Boolean;
var
  I: Integer;
  T: string;
begin
  T := TrimLeftOnly(Line);
  I := 1;
  while (I <= Length(T)) and (I <= 6) and (T[I] = '#') do
    Inc(I);

  Level := I - 1;
  Result := (Level > 0) and (I <= Length(T)) and CharInSet(T[I], [' ', #9]);
  if Result then
    Text := Trim(Copy(T, I + 1, MaxInt));
end;

function TryParseListItem(const Line: string; out Text: string; out Ordered: Boolean; out Number: Integer): Boolean;
var
  I: Integer;
  T: string;
  Digits: string;
begin
  T := TrimLeftOnly(Line);
  Result := False;
  Ordered := False;
  Number := 0;

  if (Length(T) >= 2) and CharInSet(T[1], ['-', '*', '+']) and CharInSet(T[2], [' ', #9]) then
  begin
    Text := Trim(Copy(T, 3, MaxInt));
    Result := True;
    Exit;
  end;

  I := 1;
  while (I <= Length(T)) and CharInSet(T[I], ['0'..'9']) do
    Inc(I);

  if (I > 1) and (I < Length(T)) and (T[I] = '.') and CharInSet(T[I + 1], [' ', #9]) then
  begin
    Digits := Copy(T, 1, I - 1);
    Number := StrToIntDef(Digits, 0);
    Text := Trim(Copy(T, I + 2, MaxInt));
    Ordered := True;
    Result := True;
  end;
end;

function NewBlock(AKind: TMarkDownBlockKind; const Text: string): TMarkDownBlock;
begin
  Result := TMarkDownBlock.Create;
  Result.Kind := AKind;
  Result.Text := Text;
  Result.Level := 0;
  Result.Ordered := False;
  Result.Number := 0;
  Result.IsTask := False;
  Result.TaskChecked := False;
end;

function ParseBlocks(Lines: TStrings): TMarkDownBlockList;
var
  I: Integer;
  HeadingText: string;
  ListText: string;
  QuoteText: string;
  CodeText: string;
  TableText: string;
  ParagraphText: string;
  Level: Integer;
  Number: Integer;
  Ordered: Boolean;
  IsTask: Boolean;
  TaskChecked: Boolean;
  Block: TMarkDownBlock;

  procedure CommitParagraph;
  begin
    if Trim(ParagraphText) <> '' then
      Result.Add(NewBlock(bkParagraph, Trim(ParagraphText)));
    ParagraphText := '';
  end;

begin
  Result := TMarkDownBlockList.Create(True);
  ParagraphText := '';
  I := 0;
  while I < Lines.Count do
  begin
    if StartsWithFence(Lines[I]) then
    begin
      CommitParagraph;
      Inc(I);
      CodeText := '';
      while (I < Lines.Count) and not StartsWithFence(Lines[I]) do
      begin
        if CodeText <> '' then
          CodeText := CodeText + sLineBreak;
        CodeText := CodeText + Lines[I];
        Inc(I);
      end;
      Result.Add(NewBlock(bkCodeBlock, CodeText));
      if I < Lines.Count then
        Inc(I);
      Continue;
    end;

    if Trim(Lines[I]) = '' then
    begin
      CommitParagraph;
      Inc(I);
      Continue;
    end;

    if IsTableStart(Lines, I) then
    begin
      CommitParagraph;
      TableText := Lines[I] + sLineBreak + Lines[I + 1];
      Inc(I, 2);
      while (I < Lines.Count) and (Trim(Lines[I]) <> '') and IsPipeTableRow(Lines[I]) do
      begin
        TableText := TableText + sLineBreak + Lines[I];
        Inc(I);
      end;
      Result.Add(NewBlock(bkTable, TableText));
      Continue;
    end;

    if TryParseHeading(Lines[I], HeadingText, Level) then
    begin
      CommitParagraph;
      Block := NewBlock(bkHeading, HeadingText);
      Block.Level := Level;
      Result.Add(Block);
      Inc(I);
      Continue;
    end;

    if IsRuleLine(Lines[I]) then
    begin
      CommitParagraph;
      Result.Add(NewBlock(bkRule, ''));
      Inc(I);
      Continue;
    end;

    if Copy(TrimLeftOnly(Lines[I]), 1, 1) = '>' then
    begin
      CommitParagraph;
      QuoteText := Trim(Copy(TrimLeftOnly(Lines[I]), 2, MaxInt));
      Inc(I);
      while (I < Lines.Count) and (Copy(TrimLeftOnly(Lines[I]), 1, 1) = '>') do
      begin
        QuoteText := QuoteText + ' ' + Trim(Copy(TrimLeftOnly(Lines[I]), 2, MaxInt));
        Inc(I);
      end;
      Result.Add(NewBlock(bkQuote, QuoteText));
      Continue;
    end;

    if TryParseListItem(Lines[I], ListText, Ordered, Number) then
    begin
      CommitParagraph;
      ExtractTaskMarker(ListText, IsTask, TaskChecked);
      Block := NewBlock(bkListItem, ListText);
      Block.Ordered := Ordered;
      Block.Number := Number;
      Block.IsTask := IsTask;
      Block.TaskChecked := TaskChecked;
      Result.Add(Block);
      Inc(I);
      Continue;
    end;

    if ParagraphText <> '' then
      ParagraphText := ParagraphText + ' ';
    ParagraphText := ParagraphText + Trim(Lines[I]);
    Inc(I);
  end;

  CommitParagraph;
end;

procedure AddToken(Tokens: TMarkDownInlineList; AKind: TMarkDownInlineKind; const Text: string; const Url: string = '');
var
  Token: TMarkDownInlineToken;
begin
  if Text = '' then
    Exit;
  Token.Kind := AKind;
  Token.Text := Text;
  Token.Url := Url;
  Tokens.Add(Token);
end;

function ParseInline(const Text: string): TMarkDownInlineList;
var
  I: Integer;
  J: Integer;
  K: Integer;
  Buffer: string;

  procedure FlushBuffer;
  begin
    AddToken(Result, ikText, Buffer);
    Buffer := '';
  end;

begin
  Result := TMarkDownInlineList.Create;
  Buffer := '';
  I := 1;
  while I <= Length(Text) do
  begin
    if Text[I] = '`' then
    begin
      J := PosEx('`', Text, I + 1);
      if J > I then
      begin
        FlushBuffer;
        AddToken(Result, ikCode, Copy(Text, I + 1, J - I - 1));
        I := J + 1;
        Continue;
      end;
    end;

    if Copy(Text, I, 2) = '**' then
    begin
      J := PosEx('**', Text, I + 2);
      if J > I then
      begin
        FlushBuffer;
        AddToken(Result, ikBold, Copy(Text, I + 2, J - I - 2));
        I := J + 2;
        Continue;
      end;
    end;

    if Copy(Text, I, 2) = '__' then
    begin
      J := PosEx('__', Text, I + 2);
      if J > I then
      begin
        FlushBuffer;
        AddToken(Result, ikBold, Copy(Text, I + 2, J - I - 2));
        I := J + 2;
        Continue;
      end;
    end;

    if CharInSet(Text[I], ['*', '_']) then
    begin
      J := PosEx(Text[I], Text, I + 1);
      if J > I then
      begin
        FlushBuffer;
        AddToken(Result, ikItalic, Copy(Text, I + 1, J - I - 1));
        I := J + 1;
        Continue;
      end;
    end;

    if Text[I] = '[' then
    begin
      J := PosEx(']', Text, I + 1);
      if (J > I) and (J < Length(Text)) and (Text[J + 1] = '(') then
      begin
        K := PosEx(')', Text, J + 2);
        if K > J then
        begin
          FlushBuffer;
          AddToken(Result, ikLink, Copy(Text, I + 1, J - I - 1), Copy(Text, J + 2, K - J - 2));
          I := K + 1;
          Continue;
        end;
      end;
    end;

    Buffer := Buffer + Text[I];
    Inc(I);
  end;
  FlushBuffer;
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
  FLinkColor := clHighlight;
  FCodeBackgroundColor := $00F2F2F2;
  FQuoteBarColor := clSilver;
  FMarkdown := TStringList.Create;
  FMarkdown.OnChange := MarkdownChanged;
  FBlocks := TMarkDownBlockList.Create(True);
  FLinkHits := TMarkDownLinkHitList.Create;
end;

destructor TMarkDownViewer.Destroy;
begin
  FLinkHits.Free;
  FBlocks.Free;
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
  Invalidate;
end;

function TMarkDownViewer.GetMarkdownText: string;
begin
  Result := FMarkdown.Text;
end;

function TMarkDownViewer.GetMarkdown: TStrings;
begin
  Result := FMarkdown;
end;

function TMarkDownViewer.IsMarkdownStored: Boolean;
begin
  Result := FMarkdown.Count > 0;
end;

procedure TMarkDownViewer.LoadFromFile(const FileName: string);
begin
  FMarkdown.LoadFromFile(FileName);
end;

procedure TMarkDownViewer.MarkdownChanged(Sender: TObject);
var
  Blocks: TMarkDownBlockList;
begin
  Blocks := ParseBlocks(FMarkdown);
  FBlocks.Free;
  FBlocks := Blocks;
  FScrollPos := 0;
  Invalidate;
  UpdateScrollBar;
end;

procedure TMarkDownViewer.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
  Hit: TMarkDownLinkHit;
begin
  inherited;
  if Button <> mbLeft then
    Exit;

  if FLinkHits <> nil then
    for I := 0 to FLinkHits.Count - 1 do
    begin
      Hit := FLinkHits[I];
      if PtInRect(Hit.Rect, Point(X, Y)) then
      begin
        if Assigned(FOnLinkClick) then
          FOnLinkClick(Self, Hit.Url)
        else
          ShellExecute(Handle, 'open', PChar(Hit.Url), nil, nil, SW_SHOWNORMAL);
        Break;
      end;
    end;
end;

procedure TMarkDownViewer.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
  IsLink: Boolean;
begin
  inherited;
  IsLink := False;
  if FLinkHits <> nil then
    for I := 0 to FLinkHits.Count - 1 do
      if PtInRect(FLinkHits[I].Rect, Point(X, Y)) then
      begin
        IsLink := True;
        Break;
      end;

  if IsLink then
    Cursor := crHandPoint
  else
    Cursor := crDefault;
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
  Bullet: string;
  TextIndent: Integer;

  procedure AssignBaseFont(Style: TFontStyles; SizeDelta: Integer; const FontName: string = '');
  begin
    Canvas.Font.Assign(Font);
    Canvas.Font.Style := Style;
    Canvas.Font.Size := Max(1, Font.Size + SizeDelta);
    if FontName <> '' then
      Canvas.Font.Name := FontName;
  end;

  procedure AssignInlineFont(Kind: TMarkDownInlineKind; BaseStyle: TFontStyles; SizeDelta: Integer);
  begin
    Canvas.Font.Assign(Font);
    Canvas.Font.Size := Max(1, Font.Size + SizeDelta);
    Canvas.Font.Style := BaseStyle;
    case Kind of
      ikBold:
        Canvas.Font.Style := BaseStyle + [fsBold];
      ikItalic:
        Canvas.Font.Style := BaseStyle + [fsItalic];
      ikBoldItalic:
        Canvas.Font.Style := BaseStyle + [fsBold, fsItalic];
      ikCode:
        begin
          Canvas.Font.Name := 'Consolas';
          Canvas.Font.Style := [];
        end;
      ikLink:
        begin
          Canvas.Font.Color := FLinkColor;
          Canvas.Font.Style := BaseStyle + [fsUnderline];
        end;
    end;
  end;

  function NextAtom(const S: string; var Index: Integer): string;
  var
    Start: Integer;
    WantSpace: Boolean;
  begin
    Start := Index;
    WantSpace := CharInSet(S[Index], [' ', #9]);
    while (Index <= Length(S)) and (CharInSet(S[Index], [' ', #9]) = WantSpace) do
      Inc(Index);
    Result := Copy(S, Start, Index - Start);
    Result := StringReplace(Result, #9, '    ', [rfReplaceAll]);
  end;

  function DrawInline(ATokens: TMarkDownInlineList; ALeft, ATop, AWidth: Integer; ADraw: Boolean;
    BaseStyle: TFontStyles = []; SizeDelta: Integer = 0): Integer;
  var
    TokenIndex: Integer;
    AtomIndex: Integer;
    X: Integer;
    YPos: Integer;
    RightEdge: Integer;
    Atom: string;
    AtomWidth: Integer;
    AtomRect: TRect;
    Hit: TMarkDownLinkHit;
    OldBrushColor: TColor;
    OldBrushStyle: TBrushStyle;
    OldBkMode: Integer;
  begin
    X := ALeft;
    YPos := ATop;
    RightEdge := ALeft + AWidth;
    AssignBaseFont(BaseStyle, SizeDelta);
    LineHeight := Canvas.TextHeight('Wg') + 5;

    for TokenIndex := 0 to ATokens.Count - 1 do
    begin
      AssignInlineFont(ATokens[TokenIndex].Kind, BaseStyle, SizeDelta);
      AtomIndex := 1;
      while AtomIndex <= Length(ATokens[TokenIndex].Text) do
      begin
        Atom := NextAtom(ATokens[TokenIndex].Text, AtomIndex);
        AtomWidth := Canvas.TextWidth(Atom);
        if (Trim(Atom) <> '') and (X > ALeft) and (X + AtomWidth > RightEdge) then
        begin
          X := ALeft;
          Inc(YPos, LineHeight);
        end;

        if (ADraw) and (YPos + LineHeight >= 0) and (YPos <= ClientHeight) then
        begin
          AtomRect := Rect(X, YPos, X + AtomWidth, YPos + LineHeight);
          if ATokens[TokenIndex].Kind = ikCode then
          begin
            OldBrushColor := Canvas.Brush.Color;
            OldBrushStyle := Canvas.Brush.Style;
            Canvas.Brush.Color := FCodeBackgroundColor;
            Canvas.Brush.Style := bsSolid;
            Canvas.FillRect(Rect(AtomRect.Left - 2, AtomRect.Top + 1, AtomRect.Right + 2, AtomRect.Bottom - 1));
            Canvas.Brush.Color := OldBrushColor;
            Canvas.Brush.Style := OldBrushStyle;
          end;
          OldBkMode := SetBkMode(Canvas.Handle, TRANSPARENT);
          Canvas.TextOut(X, YPos + 2, Atom);
          SetBkMode(Canvas.Handle, OldBkMode);
          if (ATokens[TokenIndex].Kind = ikLink) and (Trim(Atom) <> '') and (FLinkHits <> nil) then
          begin
            Hit.Rect := AtomRect;
            Hit.Url := ATokens[TokenIndex].Url;
            FLinkHits.Add(Hit);
          end;
        end;
        Inc(X, AtomWidth);
      end;
    end;

    Result := YPos + LineHeight - ATop;
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
    Aligns: array of TAlignment;
    ColCount: Integer;
    RowHeight: Integer;
    VisibleRow: Integer;
    SourceIndex: Integer;
    Col: Integer;
    X: Integer;
    TotalWidth: Integer;
    CellText: string;
    CellRect: TRect;
    TextRect: TRect;
    Flags: Integer;
    OldBkMode: Integer;
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
        SplitTableRow(SourceLines[SourceIndex], Rows.Last);
        if SourceIndex <> 1 then
          ColCount := Max(ColCount, Rows.Last.Count);
      end;

      if ColCount = 0 then
        Exit;

      SplitTableRow(SourceLines[1], AlignCells);
      SetLength(ColWidths, ColCount);
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

      RowHeight := Canvas.TextHeight('Wg') + 14;
      VisibleRow := 0;
      for SourceIndex := 0 to Rows.Count - 1 do
      begin
        if SourceIndex = 1 then
          Continue;

        X := ALeft;
        for Col := 0 to ColCount - 1 do
        begin
          CellRect := Rect(X, ATop + (VisibleRow * RowHeight), X + ColWidths[Col], ATop + ((VisibleRow + 1) * RowHeight));
          if SourceIndex = 0 then
            Canvas.Brush.Color := $00F7F7F7
          else
            Canvas.Brush.Color := Color;
          Canvas.FillRect(CellRect);
          Canvas.Pen.Color := clSilver;
          Canvas.Brush.Style := bsClear;
          Canvas.Rectangle(CellRect);
          Canvas.Brush.Style := bsSolid;

          if Col < Rows[SourceIndex].Count then
            CellText := Rows[SourceIndex][Col]
          else
            CellText := '';

          Canvas.Font.Assign(Font);
          if SourceIndex = 0 then
            Canvas.Font.Style := [fsBold]
          else
            Canvas.Font.Style := [];

          TextRect := Rect(CellRect.Left + 8, CellRect.Top + 1, CellRect.Right - 8, CellRect.Bottom - 1);
          Flags := DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS;
          case Aligns[Col] of
            taCenter:
              Flags := Flags or DT_CENTER;
            taRightJustify:
              Flags := Flags or DT_RIGHT;
          else
            Flags := Flags or DT_LEFT;
          end;
          OldBkMode := SetBkMode(Canvas.Handle, TRANSPARENT);
          DrawText(Canvas.Handle, PChar(CellText), Length(CellText), TextRect, Flags);
          SetBkMode(Canvas.Handle, OldBkMode);
          Inc(X, ColWidths[Col]);
        end;
        Inc(VisibleRow);
      end;

      Result := VisibleRow * RowHeight;
    finally
      AlignCells.Free;
      Rows.Free;
      SourceLines.Free;
    end;
  end;

begin
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  FLinkHits.Clear;

  Blocks := FBlocks;
  Y := MarkdownPadding - FScrollPos;
  TextLeft := MarkdownPadding;
  ContentWidth := Max(10, ClientWidth - (MarkdownPadding * 2) - GetSystemMetrics(SM_CXVSCROLL));

  for I := 0 to Blocks.Count - 1 do
  begin
    Block := Blocks[I];
    case Block.Kind of
      bkHeading:
        begin
          AssignBaseFont([fsBold], Max(1, 8 - (Block.Level * 2)));
          Tokens := ParseInline(Block.Text);
          try
            TokenHeight := DrawInline(Tokens, TextLeft, Y, ContentWidth, True, [fsBold], Max(1, 8 - (Block.Level * 2)));
          finally
            Tokens.Free;
          end;
          Inc(Y, TokenHeight + ParagraphSpacing + 2);
        end;
      bkQuote:
        begin
          Tokens := ParseInline(Block.Text);
          try
            TokenHeight := DrawInline(Tokens, TextLeft + 13, Y, ContentWidth - 13, True);
          finally
            Tokens.Free;
          end;
          R := Rect(TextLeft, Y + 2, TextLeft + 4, Y + TokenHeight);
          Canvas.Brush.Color := FQuoteBarColor;
          Canvas.FillRect(R);
          Inc(Y, TokenHeight + ParagraphSpacing);
        end;
      bkListItem:
        begin
          AssignBaseFont([], 0);
          TextIndent := 28;
          if Block.IsTask then
          begin
            CheckRect := Rect(TextLeft, Y + 3, TextLeft + 15, Y + 18);
            if Block.TaskChecked then
              DrawFrameControl(Canvas.Handle, CheckRect, DFC_BUTTON, DFCS_BUTTONCHECK or DFCS_CHECKED)
            else
              DrawFrameControl(Canvas.Handle, CheckRect, DFC_BUTTON, DFCS_BUTTONCHECK);
          end
          else
          begin
            if Block.Ordered then
              Bullet := IntToStr(Block.Number) + '.'
            else
              Bullet := #$2022;
            Canvas.TextOut(TextLeft, Y + 2, Bullet);
          end;
          Tokens := ParseInline(Block.Text);
          try
            TokenHeight := DrawInline(Tokens, TextLeft + TextIndent, Y, ContentWidth - TextIndent, True);
          finally
            Tokens.Free;
          end;
          Inc(Y, TokenHeight + 3);
        end;
      bkTable:
        begin
          TokenHeight := DrawTable(Block.Text, TextLeft, Y, ContentWidth);
          Inc(Y, TokenHeight + ParagraphSpacing);
        end;
      bkCodeBlock:
        begin
          AssignBaseFont([], 0, 'Consolas');
          LineHeight := Canvas.TextHeight('Wg') + 5;
          Lines := TStringList.Create;
          try
            Lines.Text := Block.Text;
            TokenHeight := Max(1, Lines.Count) * LineHeight + 16;
            R := Rect(TextLeft, Y + 2, TextLeft + ContentWidth, Y + TokenHeight);
            Canvas.Brush.Color := FCodeBackgroundColor;
            Canvas.FillRect(R);
            Canvas.Brush.Style := bsClear;
            for LineIndex := 0 to Lines.Count - 1 do
              Canvas.TextOut(TextLeft + 8, Y + 8 + (LineIndex * LineHeight), Lines[LineIndex]);
            Canvas.Brush.Style := bsSolid;
          finally
            Lines.Free;
          end;
          Inc(Y, TokenHeight + ParagraphSpacing);
        end;
      bkRule:
        begin
          Canvas.Pen.Color := clSilver;
          Canvas.MoveTo(TextLeft, Y + 8);
          Canvas.LineTo(TextLeft + ContentWidth, Y + 8);
          Inc(Y, 18);
        end;
    else
      Tokens := ParseInline(Block.Text);
      try
        TokenHeight := DrawInline(Tokens, TextLeft, Y, ContentWidth, True);
      finally
        Tokens.Free;
      end;
      Inc(Y, TokenHeight + ParagraphSpacing);
    end;
  end;

  TotalHeight := Y + FScrollPos + MarkdownPadding;
  if TotalHeight <> FContentHeight then
  begin
    FContentHeight := TotalHeight;
    UpdateScrollBar;
  end;
end;

procedure TMarkDownViewer.Resize;
begin
  inherited;
  UpdateScrollBar;
  Invalidate;
end;

procedure TMarkDownViewer.SetCodeBackgroundColor(const Value: TColor);
begin
  if FCodeBackgroundColor <> Value then
  begin
    FCodeBackgroundColor := Value;
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

procedure TMarkDownViewer.WMErasBkgnd(var Message: TMessage);
begin
  Message.Result := 1;
end;

procedure TMarkDownViewer.WMMouseWheel(var Message: TWMMouseWheel);
var
  Delta: Integer;
begin
  Delta := -Message.WheelDelta div WHEEL_DELTA;
  FScrollPos := FScrollPos + (Delta * 3 * Max(16, Canvas.TextHeight('Wg')));
  UpdateScrollBar;
  Invalidate;
  Message.Result := 1;
end;

procedure TMarkDownViewer.WMVScroll(var Message: TWMVScroll);
var
  ScrollInfo: TScrollInfo;
begin
  ZeroMemory(@ScrollInfo, SizeOf(ScrollInfo));
  ScrollInfo.cbSize := SizeOf(ScrollInfo);
  ScrollInfo.fMask := SIF_ALL;
  GetScrollInfo(Handle, SB_VERT, ScrollInfo);

  case Message.ScrollCode of
    SB_LINEUP:
      Dec(FScrollPos, 24);
    SB_LINEDOWN:
      Inc(FScrollPos, 24);
    SB_PAGEUP:
      Dec(FScrollPos, ClientHeight);
    SB_PAGEDOWN:
      Inc(FScrollPos, ClientHeight);
    SB_THUMBPOSITION, SB_THUMBTRACK:
      FScrollPos := ScrollInfo.nTrackPos;
  end;

  UpdateScrollBar;
  Invalidate;
end;
end.
