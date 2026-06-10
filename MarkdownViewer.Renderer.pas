unit MarkdownViewer.Renderer;

interface

uses
  System.Classes,
  Vcl.Graphics,
  MarkdownViewer.Model;

type
  TCanvasState = record
  private
    FCanvas: TCanvas;
    FSavedDC: Integer;
  public
    class function Save(ACanvas: TCanvas): TCanvasState; static;
    procedure Restore;
  end;

function CenterMarkerLeft(ColumnLeft, ColumnWidth, MarkerWidth: Integer): Integer;

// Returns the next atom from S starting at Index (a run of whitespace or a run
// of non-whitespace), advancing Index past it. Tabs in the result are expanded
// to four spaces so they measure and draw consistently. Index must be in range.
function NextAtom(const S: string; var Index: Integer): string;

// Rebuilds the markdown source for one rendered atom from its inline-token
// styling. Used when copying a selection as markdown.
function MarkdownForAtom(const Token: TMarkDownInlineToken;
  const AtomText: string): string;

// Horizontal offset to add to the left edge for the given alignment, where
// Available is the unused width on the line.
function AlignmentOffset(AAlignment: TAlignment; Available: Integer): Integer;

// Point-size delta (relative to the base font) for a heading of the given
// level; clamped so deep headings stay at least slightly larger than body text.
function HeadingFontSizeDelta(Level: Integer): Integer;

implementation

uses
  System.Math,
  System.SysUtils,
  Winapi.Windows;

function CenterMarkerLeft(ColumnLeft, ColumnWidth, MarkerWidth: Integer): Integer;
begin
  Result := ColumnLeft + Max(0, (ColumnWidth - MarkerWidth) div 2);
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

function MarkdownForAtom(const Token: TMarkDownInlineToken;
  const AtomText: string): string;
begin
  if Trim(AtomText) = '' then
    Exit(AtomText);

  Result := AtomText;
  if Token.IsCode then
    Result := '`' + Result + '`';
  if fsStrikeOut in Token.Style then
    Result := '~~' + Result + '~~';
  if (fsBold in Token.Style) and (fsItalic in Token.Style) then
    Result := '***' + Result + '***'
  else if fsBold in Token.Style then
    Result := '**' + Result + '**'
  else if fsItalic in Token.Style then
    Result := '*' + Result + '*';
  if Token.Url <> '' then
    Result := '[' + Result + '](' + Token.Url + ')';
end;

function AlignmentOffset(AAlignment: TAlignment; Available: Integer): Integer;
begin
  case AAlignment of
    taCenter:
      Result := Available div 2;
    taRightJustify:
      Result := Available;
  else
    Result := 0;
  end;
end;

function HeadingFontSizeDelta(Level: Integer): Integer;
begin
  Result := Max(1, 8 - (Level * 2));
end;

class function TCanvasState.Save(ACanvas: TCanvas): TCanvasState;
begin
  Result.FCanvas := ACanvas;
  if ACanvas <> nil then
    Result.FSavedDC := SaveDC(ACanvas.Handle)
  else
    Result.FSavedDC := 0;
end;

procedure TCanvasState.Restore;
begin
  if (FCanvas <> nil) and (FSavedDC <> 0) then
  begin
    RestoreDC(FCanvas.Handle, FSavedDC);
    FSavedDC := 0;
  end;
end;

end.
