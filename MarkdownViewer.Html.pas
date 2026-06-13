unit MarkdownViewer.Html;

// Converts markdown to an HTML fragment, reusing the same block/inline parser
// the viewer renders with. Output is a fragment (no <html>/<body> wrapper) so
// callers can embed it; MarkdownToHtmlDocument wraps it in a minimal document.

interface

uses
  System.Classes;

function MarkdownToHtml(const Markdown: string;
  References: TStrings = nil): string;
function MarkdownToHtmlDocument(const Markdown: string;
  const Title: string = ''): string;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  Vcl.Graphics,
  MarkdownViewer.Model,
  MarkdownViewer.Parser;

function HtmlEscape(const S: string): string;
begin
  Result := StringReplace(S, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
end;

// Render one inline run with its emphasis nested inside an optional link.
function EmitToken(const Token: TMarkDownInlineToken): string;
begin
  if Token.LineBreak then
    Exit('<br />');

  Result := HtmlEscape(Token.Text);
  if Token.IsCode then
    Result := '<code>' + Result + '</code>';
  if fsStrikeOut in Token.Style then
    Result := '<del>' + Result + '</del>';
  if fsItalic in Token.Style then
    Result := '<em>' + Result + '</em>';
  if fsBold in Token.Style then
    Result := '<strong>' + Result + '</strong>';
  if Token.IsHighlighted then
    Result := '<mark>' + Result + '</mark>';
  if Token.Url <> '' then
    Result := '<a href="' + HtmlEscape(Token.Url) + '">' + Result + '</a>';
end;

function EmitInline(const Text: string; References: TStrings): string;
var
  Tokens: TMarkDownInlineList;
  Token: TMarkDownInlineToken;
begin
  Result := '';
  Tokens := TMarkDownBlockParser.ParseInline(Text, References);
  try
    for Token in Tokens do
      Result := Result + EmitToken(Token);
  finally
    Tokens.Free;
  end;
end;

// 'left'/'center'/'right' for a separator cell such as :---, :---: or ---:.
function CellAlignment(const Cell: string): string;
var
  T: string;
  L, R: Boolean;
begin
  T := Trim(Cell);
  L := T.StartsWith(':');
  R := T.EndsWith(':');
  if L and R then
    Result := 'center'
  else if R then
    Result := 'right'
  else if L then
    Result := 'left'
  else
    Result := '';
end;

function EmitTable(const TableText: string; References: TStrings): string;
var
  Lines: TStringList;
  Cells: TStringList;
  Aligns: TArray<string>;
  Builder: TStringBuilder;
  Row, Col: Integer;
  Style: string;

  procedure AppendRow(RowIndex: Integer; const ATag: string);
  var
    C: Integer;
  begin
    Cells.Clear;
    TMarkDownBlockParser.SplitTableRow(Lines[RowIndex], Cells);
    Builder.Append('<tr>');
    for C := 0 to Cells.Count - 1 do
    begin
      if (C < Length(Aligns)) and (Aligns[C] <> '') then
        Style := ' style="text-align:' + Aligns[C] + '"'
      else
        Style := '';
      Builder.Append('<' + ATag + Style + '>');
      Builder.Append(EmitInline(Cells[C], References));
      Builder.Append('</' + ATag + '>');
    end;
    Builder.Append('</tr>');
  end;

begin
  Lines := TStringList.Create;
  Cells := TStringList.Create;
  Builder := TStringBuilder.Create;
  try
    Lines.Text := TableText;
    if Lines.Count < 2 then
      Exit('');

    Cells.Clear;
    TMarkDownBlockParser.SplitTableRow(Lines[1], Cells);
    SetLength(Aligns, Cells.Count);
    for Col := 0 to Cells.Count - 1 do
      Aligns[Col] := CellAlignment(Cells[Col]);

    Builder.Append('<table>'#10'<thead>'#10);
    AppendRow(0, 'th');
    Builder.Append(#10'</thead>'#10'<tbody>'#10);
    for Row := 2 to Lines.Count - 1 do
    begin
      AppendRow(Row, 'td');
      Builder.Append(#10);
    end;
    Builder.Append('</tbody>'#10'</table>');
    Result := Builder.ToString;
  finally
    Builder.Free;
    Cells.Free;
    Lines.Free;
  end;
end;

function MarkdownToHtml(const Markdown: string; References: TStrings): string;
var
  Lines: TStringList;
  OwnRefs: TStringList;
  Refs: TStrings;
  Blocks: TMarkDownBlockList;
  Builder: TStringBuilder;
  I: Integer;
  Block: TMarkDownBlock;
  OpenIndents: TList<Integer>;
  OpenOrdered: TList<Boolean>;

  function ListTag(Ordered: Boolean): string;
  begin
    if Ordered then
      Result := 'ol'
    else
      Result := 'ul';
  end;

  // Close every open list deeper than KeepIndent (and the <li> each sits in).
  procedure CloseListsDeeperThan(KeepIndent: Integer);
  begin
    while (OpenIndents.Count > 0) and (OpenIndents.Last > KeepIndent) do
    begin
      Builder.Append('</li></' + ListTag(OpenOrdered.Last) + '>'#10);
      OpenIndents.Delete(OpenIndents.Count - 1);
      OpenOrdered.Delete(OpenOrdered.Count - 1);
    end;
  end;

  procedure EmitListItem(AItem: TMarkDownBlock);
  begin
    CloseListsDeeperThan(AItem.IndentLevel);
    if (OpenIndents.Count = 0) or (AItem.IndentLevel > OpenIndents.Last) then
    begin
      Builder.Append('<' + ListTag(AItem.Ordered) + '>'#10);
      OpenIndents.Add(AItem.IndentLevel);
      OpenOrdered.Add(AItem.Ordered);
    end
    else
      Builder.Append('</li>'#10); // close the previous sibling
    Builder.Append('<li>');
    if AItem.IsTask then
    begin
      if AItem.TaskChecked then
        Builder.Append('<input type="checkbox" checked disabled /> ')
      else
        Builder.Append('<input type="checkbox" disabled /> ');
    end;
    Builder.Append(EmitInline(AItem.Text, Refs));
  end;

  procedure CloseAllLists;
  begin
    while OpenIndents.Count > 0 do
    begin
      Builder.Append('</li></' + ListTag(OpenOrdered.Last) + '>'#10);
      OpenIndents.Delete(OpenIndents.Count - 1);
      OpenOrdered.Delete(OpenOrdered.Count - 1);
    end;
  end;

begin
  Lines := TStringList.Create;
  OwnRefs := nil;
  Blocks := nil;
  Builder := TStringBuilder.Create;
  OpenIndents := TList<Integer>.Create;
  OpenOrdered := TList<Boolean>.Create;
  try
    Lines.Text := Markdown;
    if References <> nil then
      Refs := References
    else
    begin
      OwnRefs := TStringList.Create;
      TMarkDownBlockParser.ExtractLinkReferences(Lines, OwnRefs);
      Refs := OwnRefs;
    end;

    Blocks := TMarkDownBlockParser.ParseBlocks(Lines);
    for I := 0 to Blocks.Count - 1 do
    begin
      Block := Blocks[I];
      if Block.Kind <> bkListItem then
        CloseAllLists;
      case Block.Kind of
        bkHeading:
          Builder.Append('<h' + IntToStr(Block.Level) + '>' +
            EmitInline(Block.Text, Refs) + '</h' + IntToStr(Block.Level) +
            '>'#10);
        bkParagraph:
          Builder.Append('<p>' + EmitInline(Block.Text, Refs) + '</p>'#10);
        bkQuote:
          Builder.Append('<blockquote>' + EmitInline(Block.Text, Refs) +
            '</blockquote>'#10);
        bkListItem:
          EmitListItem(Block);
        bkCodeBlock:
          Builder.Append('<pre><code>' + HtmlEscape(Block.Text) +
            '</code></pre>'#10);
        bkRule:
          Builder.Append('<hr />'#10);
        bkImage:
          Builder.Append('<p><img src="' + HtmlEscape(Block.Url) +
            '" alt="' + HtmlEscape(Block.Text) + '" /></p>'#10);
        bkTable:
          Builder.Append(EmitTable(Block.Text, Refs) + #10);
      end;
    end;
    CloseAllLists;
    Result := Builder.ToString;
  finally
    OpenOrdered.Free;
    OpenIndents.Free;
    Builder.Free;
    Blocks.Free;
    OwnRefs.Free;
    Lines.Free;
  end;
end;

function MarkdownToHtmlDocument(const Markdown, Title: string): string;
begin
  Result := '<!DOCTYPE html>'#10 + '<html>'#10 + '<head>'#10 +
    '<meta charset="utf-8" />'#10 + '<title>' + HtmlEscape(Title) +
    '</title>'#10 + '</head>'#10 + '<body>'#10 +
    MarkdownToHtml(Markdown) + '</body>'#10 + '</html>'#10;
end;

end.
