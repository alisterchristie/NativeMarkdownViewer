unit MarkdownViewer.Parser;

interface

uses
  System.Classes;

type
  TMarkDownBlockParser = class sealed
  public
    class function CountLeadingSpaces(const S: string): Integer; static;
    class procedure ExtractTaskMarker(var Text: string;
      out IsTask, TaskChecked: Boolean); static;
    class function IsPipeTableRow(const Line: string): Boolean; static;
    class function IsRuleLine(const S: string): Boolean; static;
    class function IsTableStart(Lines: TStrings; Index: Integer): Boolean; static;
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

end.
