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
    class function IsTableStart(Lines: TStrings; Index: Integer): Boolean; static;
    class function ParseBlocks(Lines: TStrings;
      StartLine: Integer = 0): TMarkDownBlockList; static;
    class function ParseInline(const Text: string;
      References: TStrings = nil): TMarkDownInlineList; static;
    class function StartsWithFence(const S: string): Boolean; static;
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
  private
    class function IsTableAlignCell(const Cell: string): Boolean; static;
    class function IsTableSeparator(const Line: string): Boolean; static;
  end;

implementation

uses
  System.Math,
  System.StrUtils,
  System.SysUtils;

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
  end;

begin
  Result := TMarkDownBlockList.Create(True);
  ParagraphText := '';
  ParagraphStartLine := -1;
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
      Result.Add(NewBlock(bkCodeBlock, CodeText, BlockStartLine));
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

    if ParagraphText = '' then
      ParagraphStartLine := I
    else
      ParagraphText := ParagraphText + ' ';
    ParagraphText := ParagraphText + Trim(Lines[I]);
    Inc(I);
  end;

  CommitParagraph;
end;

procedure AddToken(Tokens: TMarkDownInlineList; AKind: TMarkDownInlineKind;
  const Text: string; const Url: string = '');
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

function IsAutoLinkBoundary(const Text: string; Index: Integer): Boolean;
begin
  Result := (Index = 1) or CharInSet(Text[Index - 1], [' ', #9, '(', '[', '{', '<', '>', '"', '''']);
end;

function TryReadAutoLink(const Text: string; Index: Integer; out DisplayText, Url: string;
  out NextIndex: Integer): Boolean;
var
  I: Integer;
  HasScheme: Boolean;
begin
  Result := False;
  DisplayText := '';
  Url := '';
  NextIndex := Index;

  if (Text[Index] = '<') and
    (StartsText('http://', Copy(Text, Index + 1, MaxInt)) or StartsText('https://', Copy(Text, Index + 1, MaxInt))) then
  begin
    I := PosEx('>', Text, Index + 1);
    if I > Index + 1 then
    begin
      DisplayText := Copy(Text, Index + 1, I - Index - 1);
      Url := DisplayText;
      NextIndex := I + 1;
      Exit(True);
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

class function TMarkDownBlockParser.ParseInline(const Text: string;
  References: TStrings): TMarkDownInlineList;
var
  I: Integer;
  J: Integer;
  K: Integer;
  NextIndex: Integer;
  Buffer: string;
  LinkText: string;
  ReferenceName: string;
  LinkUrl: string;

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
    if (Text[I] = '\') and (I < Length(Text)) and
      CharInSet(Text[I + 1], ['\', '`', '*', '_', '{', '}', '[', ']', '(', ')', '#', '+', '-', '.', '!', '>', '~', '|']) then
    begin
      Buffer := Buffer + Text[I + 1];
      Inc(I, 2);
      Continue;
    end;

    if TryReadAutoLink(Text, I, LinkText, LinkUrl, NextIndex) then
    begin
      FlushBuffer;
      AddToken(Result, ikLink, LinkText, LinkUrl);
      I := NextIndex;
      Continue;
    end;

    if Text[I] = '`' then
    begin
      J := FindUnescaped('`', Text, I + 1);
      if J > I then
      begin
        FlushBuffer;
        AddToken(Result, ikCode, Copy(Text, I + 1, J - I - 1));
        I := J + 1;
        Continue;
      end;
    end;

    if Copy(Text, I, 2) = '~~' then
    begin
      J := FindUnescaped('~~', Text, I + 2);
      if J > I then
      begin
        FlushBuffer;
        AddToken(Result, ikStrike, Copy(Text, I + 2, J - I - 2));
        I := J + 2;
        Continue;
      end;
    end;

    if Copy(Text, I, 2) = '**' then
    begin
      J := FindUnescaped('**', Text, I + 2);
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
      J := FindUnescaped('__', Text, I + 2);
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
      J := FindUnescaped(Text[I], Text, I + 1);
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
      J := FindUnescaped(']', Text, I + 1);
      if (J > I) and (J < Length(Text)) and (Text[J + 1] = '(') then
      begin
        K := FindUnescaped(')', Text, J + 2);
        if K > J then
        begin
          FlushBuffer;
          AddToken(Result, ikLink, Copy(Text, I + 1, J - I - 1), Copy(Text, J + 2, K - J - 2));
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
            AddToken(Result, ikLink, LinkText, LinkUrl);
            I := K + 1;
            Continue;
          end;
        end;
      end;
    end;

    Buffer := Buffer + Text[I];
    Inc(I);
  end;
  FlushBuffer;
end;

end.
