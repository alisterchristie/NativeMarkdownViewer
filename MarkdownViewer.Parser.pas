unit MarkdownViewer.Parser;

interface

uses
  System.Classes,
  MarkdownViewer.Model;

type
  TMarkDownBlockParser = class sealed
  public
    class function CountLeadingSpaces(const S: string): Integer; static;
    class procedure ExtractLinkReferences(Lines: TStrings;
      References: TStrings); static;
    class procedure ExtractTaskMarker(var Text: string;
      out IsTask, TaskChecked: Boolean); static;
    class function IsPipeTableRow(const Line: string): Boolean; static;
    class function IsRuleLine(const S: string): Boolean; static;
    class function IsSetextUnderline(const Line: string;
      out Level: Integer): Boolean; static;
    class function IsTableStart(Lines: TStrings; Index: Integer): Boolean; static;
    class function ParseBlocks(Lines: TStrings;
      StartLine: Integer = 0): TMarkDownBlockList; static;
    class function ParseInline(const Text: string;
      References: TStrings = nil;
      const SourceMap: TArray<Integer> = nil): TMarkDownInlineList; static;
    class function StartsWithFence(const S: string): Boolean; static;
    class function ExtractFenceLanguage(const S: string): string; static;
    class procedure SplitTableRow(const Line: string; Cells: TStrings); static;
    class function TrimLeftOnly(const S: string): string; static;
    class function TryParseHeading(const Line: string; out Text: string;
      out Level: Integer): Boolean; static;
    class function TryParseImage(const Line: string; out AltText,
      Url: string): Boolean; static;
    class function TryParseLinkReference(const Line: string;
      out ReferenceName, Url: string): Boolean; static;
    class function TryParseListItem(const Line: string; out Text: string;
      out Ordered: Boolean; out Number, IndentLevel: Integer): Boolean; static;
    // Fills each block's SourceMap (Text character -> document offset). Public
    // so it can be exercised directly by tests.
    class procedure AssignSourceMaps(Blocks: TMarkDownBlockList;
      Lines: TStrings); static;
  private
    class function IsTableAlignCell(const Cell: string): Boolean; static;
    class function IsTableSeparator(const Line: string): Boolean; static;
  end;

implementation

uses
  System.Character,
  System.Generics.Collections,
  System.Math,
  System.StrUtils,
  System.SysUtils,
  Vcl.Graphics;

class function TMarkDownBlockParser.TrimLeftOnly(const S: string): string;
var
  I: Integer;
begin
  I := 1;
  while (I <= Length(S)) and CharInSet(S[I], [' ', #9]) do
    Inc(I);
  Result := Copy(S, I, MaxInt);
end;

class function TMarkDownBlockParser.StartsWithFence(const S: string): Boolean;
begin
  Result := Copy(TrimLeftOnly(S), 1, 3) = '```';
end;

class function TMarkDownBlockParser.ExtractFenceLanguage(const S: string): string;
var
  T: string;
  I: Integer;
begin
  T := Trim(S);
  if (Length(T) >= 3) and (Copy(T, 1, 3) = '```') then
  begin
    T := Trim(Copy(T, 4, MaxInt));
    I := 1;
    while (I <= Length(T)) and not CharInSet(T[I], [' ', #9, #13, #10]) do
      Inc(I);
    Result := Copy(T, 1, I - 1);
  end
  else
    Result := '';
end;

class function TMarkDownBlockParser.IsRuleLine(const S: string): Boolean;
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
        Exit(False);
end;

class function TMarkDownBlockParser.IsSetextUnderline(const Line: string;
  out Level: Integer): Boolean;
var
  T: string;
  I: Integer;
  C: Char;
begin
  Result := False;
  Level := 0;
  T := Trim(Line);
  if T = '' then
    Exit;

  C := T[1];
  if C = '=' then
    Level := 1
  else if C = '-' then
    Level := 2
  else
    Exit;

  for I := 2 to Length(T) do
    if T[I] <> C then
      Exit;
  Result := True;
end;

class function TMarkDownBlockParser.TryParseLinkReference(const Line: string;
  out ReferenceName, Url: string): Boolean;
var
  CloseBracket: Integer;
  Rest: string;
  SpacePos: Integer;
  T: string;
begin
  T := Trim(Line);
  Result := (Length(T) > 4) and (T[1] = '[');
  if not Result then
    Exit;

  CloseBracket := Pos(']:', T);
  Result := CloseBracket > 2;
  if not Result then
    Exit;

  ReferenceName := LowerCase(Trim(Copy(T, 2, CloseBracket - 2)));
  Rest := Trim(Copy(T, CloseBracket + 2, MaxInt));
  SpacePos := Pos(' ', Rest);
  if SpacePos > 0 then
    Rest := Copy(Rest, 1, SpacePos - 1);
  Url := Trim(Rest);
  Result := (ReferenceName <> '') and (Url <> '');
end;

class procedure TMarkDownBlockParser.SplitTableRow(const Line: string;
  Cells: TStrings);
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

class function TMarkDownBlockParser.IsPipeTableRow(
  const Line: string): Boolean;
var
  T: string;
begin
  T := Trim(Line);
  Result := (T <> '') and (Pos('|', T) > 0);
end;

class function TMarkDownBlockParser.IsTableAlignCell(
  const Cell: string): Boolean;
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
      Exit(False);

  Result := DashCount >= 3;
end;

class function TMarkDownBlockParser.IsTableSeparator(
  const Line: string): Boolean;
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
        Exit(False);
  finally
    Cells.Free;
  end;
end;

class function TMarkDownBlockParser.IsTableStart(Lines: TStrings;
  Index: Integer): Boolean;
begin
  Result := (Index >= 0) and (Index + 1 < Lines.Count) and
    IsPipeTableRow(Lines[Index]) and IsTableSeparator(Lines[Index + 1]);
end;

class procedure TMarkDownBlockParser.ExtractTaskMarker(var Text: string;
  out IsTask, TaskChecked: Boolean);
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

class function TMarkDownBlockParser.CountLeadingSpaces(
  const S: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to Length(S) do
    if S[I] = ' ' then
      Inc(Result)
    else if S[I] = #9 then
      Inc(Result, 4)
    else
      Break;
end;

class function TMarkDownBlockParser.TryParseImage(const Line: string;
  out AltText, Url: string): Boolean;
var
  T: string;
  CloseBracket: Integer;
  CloseParen: Integer;
begin
  T := Trim(Line);
  Result := Copy(T, 1, 2) = '![';
  if not Result then
    Exit;

  CloseBracket := PosEx(']', T, 3);
  Result := (CloseBracket > 2) and (CloseBracket < Length(T)) and
    (T[CloseBracket + 1] = '(');
  if not Result then
    Exit;

  CloseParen := PosEx(')', T, CloseBracket + 2);
  Result := CloseParen > CloseBracket + 2;
  if Result then
  begin
    AltText := Copy(T, 3, CloseBracket - 3);
    Url := Copy(T, CloseBracket + 2, CloseParen - CloseBracket - 2);
  end;
end;

class function TMarkDownBlockParser.TryParseHeading(const Line: string;
  out Text: string; out Level: Integer): Boolean;
var
  I: Integer;
  T: string;
begin
  T := TrimLeftOnly(Line);
  I := 1;
  while (I <= Length(T)) and (I <= 6) and (T[I] = '#') do
    Inc(I);

  Level := I - 1;
  Result := (Level > 0) and (I <= Length(T)) and
    CharInSet(T[I], [' ', #9]);
  if Result then
    Text := Trim(Copy(T, I + 1, MaxInt));
end;

class function TMarkDownBlockParser.TryParseListItem(const Line: string;
  out Text: string; out Ordered: Boolean; out Number,
  IndentLevel: Integer): Boolean;
var
  I: Integer;
  T: string;
  Digits: string;
begin
  T := TrimLeftOnly(Line);
  Result := False;
  Ordered := False;
  Number := 0;
  IndentLevel := CountLeadingSpaces(Line) div 2;

  if (Length(T) >= 2) and CharInSet(T[1], ['-', '*', '+']) and
    CharInSet(T[2], [' ', #9]) then
  begin
    Text := Trim(Copy(T, 3, MaxInt));
    Exit(True);
  end;

  I := 1;
  while (I <= Length(T)) and CharInSet(T[I], ['0'..'9']) do
    Inc(I);

  if (I > 1) and (I < Length(T)) and (T[I] = '.') and
    CharInSet(T[I + 1], [' ', #9]) then
  begin
    Digits := Copy(T, 1, I - 1);
    Number := StrToIntDef(Digits, 0);
    Text := Trim(Copy(T, I + 2, MaxInt));
    Ordered := True;
    Result := True;
  end;
end;

class procedure TMarkDownBlockParser.ExtractLinkReferences(Lines: TStrings;
  References: TStrings);
var
  I: Integer;
  ReferenceName: string;
  ReferenceUrl: string;
begin
  References.BeginUpdate;
  try
    References.Clear;
    for I := 0 to Lines.Count - 1 do
      if TryParseLinkReference(Lines[I], ReferenceName, ReferenceUrl) then
        References.Values[ReferenceName] := ReferenceUrl;
  finally
    References.EndUpdate;
  end;
end;

// Returns the paragraph text contributed by a source line and reports whether
// that line ends with a hard line break (two or more trailing spaces, or a
// single unescaped trailing backslash). A break backslash is stripped.
function ParagraphLineText(const Line: string; out HardBreak: Boolean): string;
var
  Backslashes: Integer;
  P: Integer;
begin
  HardBreak := (Length(Line) >= 2) and (Line[Length(Line)] = ' ') and
    (Line[Length(Line) - 1] = ' ');

  Result := Trim(Line);

  if not HardBreak and (Result <> '') and (Result[Length(Result)] = '\') then
  begin
    Backslashes := 0;
    P := Length(Result);
    while (P >= 1) and (Result[P] = '\') do
    begin
      Inc(Backslashes);
      Dec(P);
    end;
    if Odd(Backslashes) then
    begin
      HardBreak := True;
      Result := TrimRight(Copy(Result, 1, Length(Result) - 1));
    end;
  end;
end;

function NewBlock(AKind: TMarkDownBlockKind; const Text: string;
  SourceStartLine: Integer): TMarkDownBlock;
begin
  Result := TMarkDownBlock.Create;
  Result.Kind := AKind;
  Result.Text := Text;
  Result.Url := '';
  Result.Level := 0;
  Result.IndentLevel := 0;
  Result.Ordered := False;
  Result.Number := 0;
  Result.IsTask := False;
  Result.TaskChecked := False;
  Result.CodeLanguage := '';
  Result.SourceStartLine := SourceStartLine;
end;

class function TMarkDownBlockParser.ParseBlocks(Lines: TStrings;
  StartLine: Integer): TMarkDownBlockList;
var
  I: Integer;
  HeadingText: string;
  ListText: string;
  QuoteText: string;
  CodeText: string;
  TableText: string;
  ImageAlt: string;
  ImageUrl: string;
  ParagraphText: string;
  ParagraphStartLine: Integer;
  ParagraphLine: string;
  PrevHardBreak: Boolean;
  CurrentHardBreak: Boolean;
  ReferenceName: string;
  ReferenceUrl: string;
  Level: Integer;
  IndentLevel: Integer;
  Number: Integer;
  Ordered: Boolean;
  IsTask: Boolean;
  TaskChecked: Boolean;
  BlockStartLine: Integer;
  Block: TMarkDownBlock;

  procedure CommitParagraph;
  begin
    if Trim(ParagraphText) <> '' then
      Result.Add(NewBlock(bkParagraph, Trim(ParagraphText), ParagraphStartLine));
    ParagraphText := '';
    ParagraphStartLine := -1;
    PrevHardBreak := False;
  end;

begin
  Result := TMarkDownBlockList.Create(True);
  ParagraphText := '';
  ParagraphStartLine := -1;
  PrevHardBreak := False;
  I := Max(0, StartLine);
  while I < Lines.Count do
  begin
    if StartsWithFence(Lines[I]) then
    begin
      CommitParagraph;
      BlockStartLine := I;
      Inc(I);
      CodeText := '';
      while (I < Lines.Count) and not StartsWithFence(Lines[I]) do
      begin
        if CodeText <> '' then
          CodeText := CodeText + sLineBreak;
        CodeText := CodeText + Lines[I];
        Inc(I);
      end;
      Block := NewBlock(bkCodeBlock, CodeText, BlockStartLine);
      Block.CodeLanguage := ExtractFenceLanguage(Lines[BlockStartLine]);
      Result.Add(Block);
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

    // A line of '=' or '-' directly under paragraph text is a setext heading
    // underline; without pending text a '-' run falls through to a rule.
    if (ParagraphText <> '') and IsSetextUnderline(Lines[I], Level) then
    begin
      Block := NewBlock(bkHeading, Trim(ParagraphText), ParagraphStartLine);
      Block.Level := Level;
      Result.Add(Block);
      ParagraphText := '';
      ParagraphStartLine := -1;
      PrevHardBreak := False;
      Inc(I);
      Continue;
    end;

    if TryParseLinkReference(Lines[I], ReferenceName, ReferenceUrl) then
    begin
      CommitParagraph;
      Inc(I);
      Continue;
    end;

    if TryParseImage(Lines[I], ImageAlt, ImageUrl) then
    begin
      CommitParagraph;
      Block := NewBlock(bkImage, ImageAlt, I);
      Block.Url := ImageUrl;
      Result.Add(Block);
      Inc(I);
      Continue;
    end;

    if IsTableStart(Lines, I) then
    begin
      CommitParagraph;
      BlockStartLine := I;
      TableText := Lines[I] + sLineBreak + Lines[I + 1];
      Inc(I, 2);
      while (I < Lines.Count) and (Trim(Lines[I]) <> '') and
        IsPipeTableRow(Lines[I]) do
      begin
        TableText := TableText + sLineBreak + Lines[I];
        Inc(I);
      end;
      Result.Add(NewBlock(bkTable, TableText, BlockStartLine));
      Continue;
    end;

    if TryParseHeading(Lines[I], HeadingText, Level) then
    begin
      CommitParagraph;
      Block := NewBlock(bkHeading, HeadingText, I);
      Block.Level := Level;
      Result.Add(Block);
      Inc(I);
      Continue;
    end;

    if IsRuleLine(Lines[I]) then
    begin
      CommitParagraph;
      Result.Add(NewBlock(bkRule, '', I));
      Inc(I);
      Continue;
    end;

    if Copy(TrimLeftOnly(Lines[I]), 1, 1) = '>' then
    begin
      CommitParagraph;
      BlockStartLine := I;
      QuoteText := Trim(Copy(TrimLeftOnly(Lines[I]), 2, MaxInt));
      Inc(I);
      while (I < Lines.Count) and
        (Copy(TrimLeftOnly(Lines[I]), 1, 1) = '>') do
      begin
        QuoteText := QuoteText + ' ' +
          Trim(Copy(TrimLeftOnly(Lines[I]), 2, MaxInt));
        Inc(I);
      end;
      Result.Add(NewBlock(bkQuote, QuoteText, BlockStartLine));
      Continue;
    end;

    if TryParseListItem(Lines[I], ListText, Ordered, Number, IndentLevel) then
    begin
      CommitParagraph;
      ExtractTaskMarker(ListText, IsTask, TaskChecked);
      Block := NewBlock(bkListItem, ListText, I);
      Block.Ordered := Ordered;
      Block.Number := Number;
      Block.IndentLevel := IndentLevel;
      Block.IsTask := IsTask;
      Block.TaskChecked := TaskChecked;
      Result.Add(Block);
      Inc(I);
      Continue;
    end;

    ParagraphLine := ParagraphLineText(Lines[I], CurrentHardBreak);
    if ParagraphText = '' then
      ParagraphStartLine := I
    else if PrevHardBreak then
      ParagraphText := ParagraphText + #10
    else
      ParagraphText := ParagraphText + ' ';
    ParagraphText := ParagraphText + ParagraphLine;
    PrevHardBreak := CurrentHardBreak;
    Inc(I);
  end;

  CommitParagraph;
  AssignSourceMaps(Result, Lines);
end;

// Reconstructs each block's text from its source lines using the same cleaning
// the assembly above applied, recording the document offset of every character
// so the viewer can map rendered text back to the source without guessing.
// Only the kinds handled here get a map; the rest are left empty and the caller
// falls back to its heuristic for them.
class procedure TMarkDownBlockParser.AssignSourceMaps(
  Blocks: TMarkDownBlockList; Lines: TStrings);
var
  LineBase: TArray<Integer>;
  BlockIndex: Integer;
  Block: TMarkDownBlock;

  function LeadingWs(const S: string): Integer;
  begin
    Result := 0;
    while (Result < Length(S)) and CharInSet(S[Result + 1], [' ', #9]) do
      Inc(Result);
  end;

  // Append the contiguous slice Lines[LineIdx][FromCol .. FromCol+Count-1].
  procedure AddSlice(Map: TList<Integer>; LineIdx, FromCol, Count: Integer);
  var
    D: Integer;
  begin
    for D := 0 to Count - 1 do
      Map.Add(LineBase[LineIdx] + (FromCol - 1) + D);
  end;

  // Append one synthetic separator character mapped to the line break that
  // follows LineIdx (the position of the CR after the line's last character).
  procedure AddJoin(Map: TList<Integer>; LineIdx: Integer);
  begin
    Map.Add(LineBase[LineIdx] + Length(Lines[LineIdx]));
  end;

  // Append the two synthetic characters of a CRLF join (used where blocks keep
  // lines verbatim, joined by sLineBreak), mapped to the CR and LF positions.
  procedure AddCrLfJoin(Map: TList<Integer>; LineIdx: Integer);
  begin
    Map.Add(LineBase[LineIdx] + Length(Lines[LineIdx]));
    Map.Add(LineBase[LineIdx] + Length(Lines[LineIdx]) + 1);
  end;

  // A block whose Text is a contiguous slice of its single source line (list
  // items, image alt text): locate the slice past any leading whitespace.
  procedure MapSingleLine(ABlock: TMarkDownBlock; Map: TList<Integer>);
  var
    Line: string;
    FromCol: Integer;
  begin
    Line := Lines[ABlock.SourceStartLine];
    FromCol := PosEx(ABlock.Text, Line, LeadingWs(Line) + 1);
    if FromCol > 0 then
      AddSlice(Map, ABlock.SourceStartLine, FromCol, Length(ABlock.Text));
  end;

  // A block that keeps its source lines verbatim, joined by sLineBreak (code
  // blocks and tables). StartOffset skips a leading fence line when present.
  procedure MapJoinedLines(ABlock: TMarkDownBlock; Map: TList<Integer>;
    StartOffset: Integer; StopAtFence: Boolean);
  var
    LineIdx: Integer;
    PrevLineIdx: Integer;
    Text: string;
    First: Boolean;
  begin
    LineIdx := ABlock.SourceStartLine + StartOffset;
    PrevLineIdx := LineIdx;
    First := True;
    Text := '';
    while LineIdx < Lines.Count do
    begin
      if StopAtFence and StartsWithFence(Lines[LineIdx]) then
        Break;
      if not First then
      begin
        AddCrLfJoin(Map, PrevLineIdx);
        Text := Text + sLineBreak;
      end;
      AddSlice(Map, LineIdx, 1, Length(Lines[LineIdx]));
      Text := Text + Lines[LineIdx];
      PrevLineIdx := LineIdx;
      First := False;
      Inc(LineIdx);
      if Text = ABlock.Text then
        Break;
    end;
  end;

  // Walk consecutive paragraph lines from StartLine, appending each line's
  // trimmed text joined by a space (or a newline after a hard break), until the
  // reconstruction equals Block.Text. Used for paragraphs and setext headings.
  procedure MapParagraph(ABlock: TMarkDownBlock; Map: TList<Integer>);
  var
    LineIdx: Integer;
    PrevLineIdx: Integer;
    Para: string;
    Text: string;
    HardBreak: Boolean;
    PrevHardBreak: Boolean;
    First: Boolean;
  begin
    LineIdx := ABlock.SourceStartLine;
    PrevLineIdx := LineIdx;
    PrevHardBreak := False;
    First := True;
    Text := '';
    while (LineIdx < Lines.Count) and (Trim(Lines[LineIdx]) <> '') do
    begin
      Para := ParagraphLineText(Lines[LineIdx], HardBreak);
      if not First then
      begin
        AddJoin(Map, PrevLineIdx);
        if PrevHardBreak then
          Text := Text + #10
        else
          Text := Text + ' ';
      end;
      AddSlice(Map, LineIdx, LeadingWs(Lines[LineIdx]) + 1, Length(Para));
      Text := Text + Para;
      PrevHardBreak := HardBreak;
      PrevLineIdx := LineIdx;
      First := False;
      Inc(LineIdx);
      if Text = ABlock.Text then
        Break;
    end;
  end;

  procedure MapAtxHeading(ABlock: TMarkDownBlock; Map: TList<Integer>);
  var
    Line: string;
    T: string;
    LeadingInLine: Integer;
    ContentTPos: Integer;
  begin
    Line := Lines[ABlock.SourceStartLine];
    LeadingInLine := LeadingWs(Line);
    T := TrimLeftOnly(Line);
    // T[Level+1] is the required space after the hashes; content follows it,
    // with any further leading whitespace trimmed off.
    ContentTPos := (ABlock.Level + 2) + LeadingWs(Copy(T, ABlock.Level + 2, MaxInt));
    AddSlice(Map, ABlock.SourceStartLine, LeadingInLine + ContentTPos,
      Length(ABlock.Text));
  end;

  procedure MapQuote(ABlock: TMarkDownBlock; Map: TList<Integer>);
  var
    LineIdx: Integer;
    PrevLineIdx: Integer;
    T: string;
    Content: string;
    FromCol: Integer;
    Text: string;
    First: Boolean;
  begin
    LineIdx := ABlock.SourceStartLine;
    PrevLineIdx := LineIdx;
    First := True;
    Text := '';
    while (LineIdx < Lines.Count) and
      (Copy(TrimLeftOnly(Lines[LineIdx]), 1, 1) = '>') do
    begin
      T := TrimLeftOnly(Lines[LineIdx]);
      Content := Trim(Copy(T, 2, MaxInt));
      // Line column of the content: leading ws + the '>' + ws trimmed after it.
      FromCol := LeadingWs(Lines[LineIdx]) + 2 + LeadingWs(Copy(T, 2, MaxInt));
      if not First then
      begin
        AddJoin(Map, PrevLineIdx);
        Text := Text + ' ';
      end;
      AddSlice(Map, LineIdx, FromCol, Length(Content));
      Text := Text + Content;
      PrevLineIdx := LineIdx;
      First := False;
      Inc(LineIdx);
      if Text = ABlock.Text then
        Break;
    end;
  end;

  function IsAtxHeading(ABlock: TMarkDownBlock): Boolean;
  var
    DummyText: string;
    DummyLevel: Integer;
  begin
    Result := (ABlock.SourceStartLine >= 0) and
      (ABlock.SourceStartLine < Lines.Count) and
      TryParseHeading(Lines[ABlock.SourceStartLine], DummyText, DummyLevel);
  end;

var
  Map: TList<Integer>;
  Acc: Integer;
  I: Integer;
begin
  SetLength(LineBase, Lines.Count + 1);
  Acc := 0;
  for I := 0 to Lines.Count - 1 do
  begin
    LineBase[I] := Acc;
    Inc(Acc, Length(Lines[I]) + 2);
  end;
  LineBase[Lines.Count] := Acc;

  for BlockIndex := 0 to Blocks.Count - 1 do
  begin
    Block := Blocks[BlockIndex];
    if (Block.SourceStartLine < 0) or (Block.SourceStartLine >= Lines.Count) or
      (Block.Text = '') then
      Continue;

    Map := TList<Integer>.Create;
    try
      case Block.Kind of
        bkParagraph:
          MapParagraph(Block, Map);
        bkHeading:
          if IsAtxHeading(Block) then
            MapAtxHeading(Block, Map)
          else
            MapParagraph(Block, Map);
        bkQuote:
          MapQuote(Block, Map);
        bkListItem, bkImage:
          MapSingleLine(Block, Map);
        bkCodeBlock:
          MapJoinedLines(Block, Map, 1, True);
        bkTable:
          MapJoinedLines(Block, Map, 0, False);
      else
        Continue; // bkRule has no mappable text
      end;

      // Only trust a map that accounts for every character of Text; otherwise
      // leave it empty so the caller falls back rather than mis-mapping.
      if Map.Count = Length(Block.Text) then
      begin
        if Map.Count > 0 then
          Map.Add(Map[Map.Count - 1] + 1)
        else
          Map.Add(LineBase[Block.SourceStartLine]);
        Block.SourceMap := Map.ToArray;
      end;
    finally
      Map.Free;
    end;
  end;
end;

procedure AddRun(Tokens: TMarkDownInlineList; const Text: string;
  Style: TFontStyles; IsHighlighted: Boolean; IsCode: Boolean; const Url: string;
  const AMap: TArray<Integer>);
var
  Token: TMarkDownInlineToken;
begin
  if Text = '' then
    Exit;
  Token := Default(TMarkDownInlineToken);
  Token.Text := Text;
  Token.Style := Style;
  Token.IsHighlighted := IsHighlighted;
  Token.IsCode := IsCode;
  Token.Url := Url;
  // A map is only attached when it lines up with Text; a mismatch means the
  // caller had no usable source map, so leave it empty and let the viewer fall
  // back rather than risk a wrong mapping.
  if Length(AMap) = Length(Text) + 1 then
    Token.SourceMap := AMap;
  Tokens.Add(Token);
end;

// Returns Map[Start0 .. Start0 + LenChars] (LenChars + 1 entries: one per
// character of the sub-slice plus the trailing end position). Empty when Map is
// empty or the range would fall outside it, so callers degrade gracefully.
function SubMap(const Map: TArray<Integer>;
  Start0, LenChars: Integer): TArray<Integer>;
var
  I: Integer;
begin
  if (Length(Map) = 0) or (Start0 < 0) or
    (Start0 + LenChars + 1 > Length(Map)) then
    Exit(nil);
  SetLength(Result, LenChars + 1);
  for I := 0 to LenChars do
    Result[I] := Map[Start0 + I];
end;

procedure AddLineBreak(Tokens: TMarkDownInlineList);
var
  Token: TMarkDownInlineToken;
begin
  Token := Default(TMarkDownInlineToken);
  Token.LineBreak := True;
  Tokens.Add(Token);
end;

function IsEscapedAt(const Text: string; Index: Integer): Boolean;
var
  I: Integer;
  SlashCount: Integer;
begin
  SlashCount := 0;
  I := Index - 1;
  while (I >= 1) and (Text[I] = '\') do
  begin
    Inc(SlashCount);
    Dec(I);
  end;
  Result := Odd(SlashCount);
end;

function FindUnescaped(const Needle, Text: string; StartPos: Integer): Integer;
begin
  Result := PosEx(Needle, Text, StartPos);
  while (Result > 0) and IsEscapedAt(Text, Result) do
    Result := PosEx(Needle, Text, Result + Length(Needle));
end;

function IsWordChar(C: Char): Boolean;
begin
  Result := C.IsLetterOrDigit;
end;

// Emphasis delimiters must hug their content (no space just inside them),
// and underscore delimiters must additionally sit at word boundaries so
// snake_case identifiers are not italicized.
function CanOpenEmphasis(const Text: string; Index, DelimLen: Integer;
  RequireWordBoundary: Boolean): Boolean;
begin
  Result := (Index + DelimLen <= Length(Text)) and
    not CharInSet(Text[Index + DelimLen], [' ', #9]);
  if Result and RequireWordBoundary then
    Result := (Index = 1) or not IsWordChar(Text[Index - 1]);
end;

function CanCloseEmphasis(const Text: string; CloserIndex, DelimLen: Integer;
  RequireWordBoundary: Boolean): Boolean;
begin
  Result := (CloserIndex > 1) and
    not CharInSet(Text[CloserIndex - 1], [' ', #9]);
  if Result and RequireWordBoundary then
    Result := (CloserIndex + DelimLen > Length(Text)) or
      not IsWordChar(Text[CloserIndex + DelimLen]);
end;

function IsAutoLinkBoundary(const Text: string; Index: Integer): Boolean;
begin
  Result := (Index = 1) or CharInSet(Text[Index - 1], [' ', #9, '(', '[', '{', '<', '>', '"', '''']);
end;

// A loose check that S looks like an email address: a single @ with text on
// both sides, a dot in the domain, and no whitespace or angle brackets.
function LooksLikeEmail(const S: string): Boolean;
var
  AtPos: Integer;
  I: Integer;
begin
  Result := False;
  AtPos := Pos('@', S);
  if (AtPos <= 1) or (AtPos >= Length(S)) then
    Exit;
  if Pos('@', Copy(S, AtPos + 1, MaxInt)) > 0 then
    Exit; // more than one @
  if Pos('.', Copy(S, AtPos + 1, MaxInt)) = 0 then
    Exit; // no dot in the domain
  for I := 1 to Length(S) do
    if CharInSet(S[I], [' ', #9, #13, #10, '<', '>']) then
      Exit;
  Result := True;
end;

function TryReadAutoLink(const Text: string; Index: Integer; out DisplayText, Url: string;
  out NextIndex: Integer; out DisplayStart: Integer): Boolean;
var
  I: Integer;
  HasScheme: Boolean;
begin
  Result := False;
  DisplayText := '';
  Url := '';
  NextIndex := Index;
  DisplayStart := Index;

  if Text[Index] = '<' then
  begin
    I := PosEx('>', Text, Index + 1);
    if I > Index + 1 then
    begin
      DisplayText := Copy(Text, Index + 1, I - Index - 1);
      if StartsText('http://', DisplayText) or StartsText('https://', DisplayText) then
      begin
        Url := DisplayText;
        NextIndex := I + 1;
        DisplayStart := Index + 1;
        Exit(True);
      end;
      if LooksLikeEmail(DisplayText) then
      begin
        Url := 'mailto:' + DisplayText;
        NextIndex := I + 1;
        DisplayStart := Index + 1;
        Exit(True);
      end;
      DisplayText := '';
    end;
  end;

  if not IsAutoLinkBoundary(Text, Index) then
    Exit;

  HasScheme := StartsText('http://', Copy(Text, Index, MaxInt)) or
    StartsText('https://', Copy(Text, Index, MaxInt));
  if not HasScheme and not StartsText('www.', Copy(Text, Index, MaxInt)) then
    Exit;

  I := Index;
  while (I <= Length(Text)) and not CharInSet(Text[I], [' ', #9, #13, #10, '<', '>', '"']) do
    Inc(I);
  DisplayText := Copy(Text, Index, I - Index);
  while (DisplayText <> '') and CharInSet(DisplayText[Length(DisplayText)], ['.', ',', ';', ':', '!', '?']) do
  begin
    Dec(I);
    Delete(DisplayText, Length(DisplayText), 1);
  end;
  if DisplayText = '' then
    Exit;

  if HasScheme then
    Url := DisplayText
  else
    Url := 'https://' + DisplayText;
  NextIndex := I;
  Result := True;
end;

// Decodes an HTML entity beginning at Text[Index] ('&'). On success returns the
// decoded text, advances Index past the trailing ';', and returns True. Numeric
// (&#169; / &#xA9;) and a set of common named entities are supported.
function TryDecodeEntity(const Text: string; var Index: Integer;
  out Decoded: string): Boolean;
const
  Names: array[0..23, 0..1] of string = (
    ('amp', '&'), ('lt', '<'), ('gt', '>'), ('quot', '"'), ('apos', ''''),
    ('nbsp', #$00A0), ('copy', #$00A9), ('reg', #$00AE), ('trade', #$2122),
    ('mdash', #$2014), ('ndash', #$2013), ('hellip', #$2026), ('deg', #$00B0),
    ('plusmn', #$00B1), ('times', #$00D7), ('divide', #$00F7), ('euro', #$20AC),
    ('pound', #$00A3), ('cent', #$00A2), ('yen', #$00A5), ('sect', #$00A7),
    ('middot', #$00B7), ('laquo', #$00AB), ('raquo', #$00BB));
var
  SemiPos: Integer;
  Body: string;
  Code: Integer;
  I: Integer;
begin
  Result := False;
  Decoded := '';
  SemiPos := PosEx(';', Text, Index + 1);
  if (SemiPos = 0) or (SemiPos - Index > 32) then
    Exit;
  Body := Copy(Text, Index + 1, SemiPos - Index - 1);
  if Body = '' then
    Exit;

  if Body[1] = '#' then
  begin
    if (Length(Body) > 1) and (UpCase(Body[2]) = 'X') then
      Code := StrToIntDef('$' + Copy(Body, 3, MaxInt), -1)
    else
      Code := StrToIntDef(Copy(Body, 2, MaxInt), -1);
    if (Code < 1) or (Code > $FFFF) then
      Exit;
    Decoded := Char(Code);
    Index := SemiPos + 1;
    Exit(True);
  end;

  for I := Low(Names) to High(Names) do
    if Names[I, 0] = Body then
    begin
      Decoded := Names[I, 1];
      Index := SemiPos + 1;
      Exit(True);
    end;
end;

// Strips an optional "title" from a link destination, e.g. (url "title").
function LinkDestination(const Inside: string): string;
var
  SpacePos: Integer;
begin
  Result := Trim(Inside);
  SpacePos := Pos(' ', Result);
  if SpacePos > 0 then
    Result := Trim(Copy(Result, 1, SpacePos - 1));
end;

function TryGetEmoji(const Code: string; out Emoji: string): Boolean;
begin
  Result := True;
  if Code = 'smile' then Emoji := #$D83D#$DE0A
  else if Code = 'warning' then Emoji := #$26A0#$FE0F
  else if Code = 'check' then Emoji := #$D805#$DF05
  else if Code = 'star' then Emoji := #$2B50
  else if Code = 'fire' then Emoji := #$D83D#$DD25
  else if Code = 'info' then Emoji := #$2139#$FE0F
  else if Code = 'heart' then Emoji := #$2764#$FE0F
  else if Code = 'thumbsup' then Emoji := #$D83D#$DC4D
  else if Code = 'thumbsdown' then Emoji := #$D83D#$DC4E
  else if Code = 'rocket' then Emoji := #$D83D#$DE80
  else if Code = 'bulb' then Emoji := #$D83D#$DCA1
  else if Code = 'lock' then Emoji := #$D83D#$DD12
  else if Code = 'key' then Emoji := #$D83D#$DD11
  else if Code = 'eyes' then Emoji := #$D83D#$DC40
  else Result := False;
end;

function EmojiMap(const Map: TArray<Integer>; StartIdx, EndIdx, EmojiLen: Integer): TArray<Integer>;
var
  K: Integer;
begin
  if Length(Map) = 0 then
    Exit(nil);
  SetLength(Result, EmojiLen + 1);
  for K := 0 to EmojiLen - 1 do
    Result[K] := Map[StartIdx];
  Result[EmojiLen] := Map[EndIdx];
end;

// Recursively splits Text into styled runs. BaseStyle and BaseUrl are inherited
// from any enclosing emphasis or link span, so nested formatting accumulates
// (e.g. bold text inside a link keeps both the bold style and the link url).
// Map (when present) carries the document offset of every character of Text,
// so each emitted token can record where its rendered text came from in the
// source. Sub-spans pass the matching slice of Map down recursively.
procedure ParseRuns(const Text: string; References: TStrings;
  BaseStyle: TFontStyles; IsHighlighted: Boolean; const BaseUrl: string; Tokens: TMarkDownInlineList;
  const Map: TArray<Integer>);
var
  I: Integer;
  J: Integer;
  K: Integer;
  C: Integer;
  NextIndex: Integer;
  DisplayStart: Integer;
  EntityStart: Integer;
  Buffer: string;
  LinkText: string;
  Marker: string;
  ReferenceName: string;
  LinkUrl: string;
  Decoded: string;
  HasMap: Boolean;
  BufferMap: TList<Integer>;
  BufferEnd: Integer;

  // The accumulated buffer's per-character offsets plus a trailing end position.
  function CurrentBufferMap: TArray<Integer>;
  begin
    if not HasMap then
      Exit(nil);
    Result := BufferMap.ToArray;
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := BufferEnd;
  end;

  procedure FlushBuffer;
  begin
    AddRun(Tokens, Buffer, BaseStyle, IsHighlighted, False, BaseUrl, CurrentBufferMap);
    Buffer := '';
    if HasMap then
      BufferMap.Clear;
  end;

  // Record a buffered character that starts at document offset StartOffset and
  // whose source ends just before AfterOffset.
  procedure PushChar(StartOffset, AfterOffset: Integer);
  begin
    if HasMap then
    begin
      BufferMap.Add(StartOffset);
      BufferEnd := AfterOffset;
    end;
  end;

begin
  HasMap := Length(Map) = Length(Text) + 1;
  BufferEnd := 0;
  BufferMap := TList<Integer>.Create;
  try
    Buffer := '';
    I := 1;
    while I <= Length(Text) do
    begin
      if (Text[I] = '\') and (I < Length(Text)) and
        CharInSet(Text[I + 1], ['\', '`', '*', '_', '{', '}', '[', ']', '(', ')', '#', '+', '-', '.', '!', '>', '~', '|']) then
      begin
        Buffer := Buffer + Text[I + 1];
        if HasMap then
          PushChar(Map[I - 1], Map[I + 1]); // covers the backslash and the char
        Inc(I, 2);
        Continue;
      end;

      // A bare line feed marks a hard line break introduced by the block parser
      // (two trailing spaces or a trailing backslash in the source).
      if Text[I] = #10 then
      begin
        FlushBuffer;
        AddLineBreak(Tokens);
        Inc(I);
        Continue;
      end;

      if Text[I] = '&' then
      begin
        EntityStart := I;
        if TryDecodeEntity(Text, I, Decoded) then
        begin
          Buffer := Buffer + Decoded;
          if HasMap then
            for C := 1 to Length(Decoded) do
              PushChar(Map[EntityStart - 1], Map[I - 1]); // whole &...; span
          Continue;
        end;
      end;

      if Text[I] = ':' then
      begin
        J := I + 1;
        while (J <= Length(Text)) and CharInSet(Text[J], ['a'..'z', 'A'..'Z', '0'..'9', '_', '-']) do
          Inc(J);
        if (J > I + 1) and (J <= Length(Text)) and (Text[J] = ':') then
        begin
          ReferenceName := Copy(Text, I + 1, J - I - 1);
          if TryGetEmoji(ReferenceName, Decoded) then
          begin
            FlushBuffer;
            AddRun(Tokens, Decoded, BaseStyle, IsHighlighted, False, BaseUrl,
              EmojiMap(Map, I - 1, J, Length(Decoded)));
            I := J + 1;
            Continue;
          end;
        end;
      end;

      if TryReadAutoLink(Text, I, LinkText, LinkUrl, NextIndex, DisplayStart) then
      begin
        FlushBuffer;
        AddRun(Tokens, LinkText, BaseStyle, IsHighlighted, False, LinkUrl,
          SubMap(Map, DisplayStart - 1, Length(LinkText)));
        I := NextIndex;
        Continue;
      end;

      if Text[I] = '`' then
      begin
        J := FindUnescaped('`', Text, I + 1);
        if J > I then
        begin
          FlushBuffer;
          AddRun(Tokens, Copy(Text, I + 1, J - I - 1), BaseStyle, IsHighlighted, True, BaseUrl,
            SubMap(Map, I, J - I - 1));
          I := J + 1;
          Continue;
        end;
      end;

      Marker := Copy(Text, I, 3);
      if (Marker = '***') or (Marker = '___') then
      begin
        if CanOpenEmphasis(Text, I, 3, Marker = '___') then
        begin
          J := FindUnescaped(Marker, Text, I + 3);
          if (J > I + 3) and CanCloseEmphasis(Text, J, 3, Marker = '___') then
          begin
            FlushBuffer;
            ParseRuns(Copy(Text, I + 3, J - I - 3), References,
              BaseStyle + [fsBold, fsItalic], IsHighlighted, BaseUrl, Tokens,
              SubMap(Map, I + 2, J - I - 3));
            I := J + 3;
            Continue;
          end;
        end;
      end;

      if (Copy(Text, I, 2) = '==') and CanOpenEmphasis(Text, I, 2, False) then
      begin
        J := FindUnescaped('==', Text, I + 2);
        if (J > I + 2) and CanCloseEmphasis(Text, J, 2, False) then
        begin
          FlushBuffer;
          ParseRuns(Copy(Text, I + 2, J - I - 2), References,
            BaseStyle, True, BaseUrl, Tokens,
            SubMap(Map, I + 1, J - I - 2));
          I := J + 2;
          Continue;
        end;
      end;

      if (Copy(Text, I, 2) = '~~') and CanOpenEmphasis(Text, I, 2, False) then
      begin
        J := FindUnescaped('~~', Text, I + 2);
        if (J > I + 2) and CanCloseEmphasis(Text, J, 2, False) then
        begin
          FlushBuffer;
          ParseRuns(Copy(Text, I + 2, J - I - 2), References,
            BaseStyle + [fsStrikeOut], IsHighlighted, BaseUrl, Tokens,
            SubMap(Map, I + 1, J - I - 2));
          I := J + 2;
          Continue;
        end;
      end;

      if (Copy(Text, I, 2) = '**') and CanOpenEmphasis(Text, I, 2, False) then
      begin
        J := FindUnescaped('**', Text, I + 2);
        if (J > I + 2) and CanCloseEmphasis(Text, J, 2, False) then
        begin
          FlushBuffer;
          ParseRuns(Copy(Text, I + 2, J - I - 2), References,
            BaseStyle + [fsBold], IsHighlighted, BaseUrl, Tokens,
            SubMap(Map, I + 1, J - I - 2));
          I := J + 2;
          Continue;
        end;
      end;

      if (Copy(Text, I, 2) = '__') and CanOpenEmphasis(Text, I, 2, True) then
      begin
        J := FindUnescaped('__', Text, I + 2);
        if (J > I + 2) and CanCloseEmphasis(Text, J, 2, True) then
        begin
          FlushBuffer;
          ParseRuns(Copy(Text, I + 2, J - I - 2), References,
            BaseStyle + [fsBold], IsHighlighted, BaseUrl, Tokens,
            SubMap(Map, I + 1, J - I - 2));
          I := J + 2;
          Continue;
        end;
      end;

      if CharInSet(Text[I], ['*', '_']) and
        CanOpenEmphasis(Text, I, 1, Text[I] = '_') then
      begin
        J := FindUnescaped(Text[I], Text, I + 1);
        if (J > I + 1) and CanCloseEmphasis(Text, J, 1, Text[I] = '_') then
        begin
          FlushBuffer;
          ParseRuns(Copy(Text, I + 1, J - I - 1), References,
            BaseStyle + [fsItalic], IsHighlighted, BaseUrl, Tokens,
            SubMap(Map, I, J - I - 1));
          I := J + 1;
          Continue;
        end;
      end;

      // Links are only parsed at the top level (no link is opened inside another
      // link), so a non-empty BaseUrl skips link recognition.
      if (BaseUrl = '') and (Text[I] = '[') then
      begin
        J := FindUnescaped(']', Text, I + 1);
        if (J > I) and (J < Length(Text)) and (Text[J + 1] = '(') then
        begin
          K := FindUnescaped(')', Text, J + 2);
          if K > J then
          begin
            FlushBuffer;
            ParseRuns(Copy(Text, I + 1, J - I - 1), References, BaseStyle, IsHighlighted,
              LinkDestination(Copy(Text, J + 2, K - J - 2)), Tokens,
              SubMap(Map, I, J - I - 1));
            I := K + 1;
            Continue;
          end;
        end;

        if (References <> nil) and (J > I) and (J < Length(Text)) and (Text[J + 1] = '[') then
        begin
          K := FindUnescaped(']', Text, J + 2);
          if K > J then
          begin
            LinkText := Copy(Text, I + 1, J - I - 1);
            ReferenceName := Trim(Copy(Text, J + 2, K - J - 2));
            if ReferenceName = '' then
              ReferenceName := LinkText;
            LinkUrl := References.Values[LowerCase(ReferenceName)];
            if LinkUrl <> '' then
            begin
              FlushBuffer;
              ParseRuns(LinkText, References, BaseStyle, IsHighlighted, LinkUrl, Tokens,
                SubMap(Map, I, J - I - 1));
              I := K + 1;
              Continue;
            end;
          end;
        end;
      end;

      Buffer := Buffer + Text[I];
      if HasMap then
        PushChar(Map[I - 1], Map[I]);
      Inc(I);
    end;
    FlushBuffer;
  finally
    BufferMap.Free;
  end;
end;

class function TMarkDownBlockParser.ParseInline(const Text: string;
  References: TStrings; const SourceMap: TArray<Integer>): TMarkDownInlineList;
begin
  Result := TMarkDownInlineList.Create;
  ParseRuns(Text, References, [], False, '', Result, SourceMap);
end;

end.
