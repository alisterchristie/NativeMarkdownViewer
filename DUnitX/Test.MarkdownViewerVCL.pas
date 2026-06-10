unit Test.MarkdownViewerVCL;

interface

uses
  DUnitX.TestFramework,
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  MarkdownViewerVCL;

type
  TTestMarkDownViewer = class(TMarkDownViewer)
  public
    procedure PressKey(Value: Word; Shift: TShiftState = []);
    procedure TypeCharacter(Value: Char);
    procedure ClickMouse(X, Y: Integer);
    procedure DragMouse(X1, Y1, X2, Y2: Integer);
    function HoverShowsLink(X, Y: Integer): Boolean;
  end;

  [TestFixture]
  TMarkDownViewerTests = class
  private
    FChangeCount: Integer;
    FForm: TForm;
    FViewer: TTestMarkDownViewer;
    FLinkUrl: string;
    procedure HandleViewerChange(Sender: TObject);
    procedure HandleLinkClick(Sender: TObject; const Url: string);
    procedure RepaintViewer;
    procedure ShowViewer(AWidth, AHeight: Integer);
    function FindLinkPoint(out X, Y: Integer): Boolean;
  public
    [TearDown]
    procedure TearDown;
    [Test]
    procedure UsesReadableDefaultFont;
    [Test]
    procedure ReadOnlyIsEnabledByDefault;
    [Test]
    procedure ExposesExpectedColorDefaults;
    [Test]
    procedure PropertiesRoundTrip;
    [Test]
    procedure LoadFromFileSetsBasePathAndContent;
    [Test]
    procedure SelectAllCopiesRenderedPlainText;
    [Test]
    procedure HardLineBreakCopiesAsLineBreak;
    [Test]
    procedure FullSelectionCopyMarkdownReturnsSource;
    [Test]
    procedure PartialSelectionCopyReconstructsBoldMarkdown;
    [Test]
    procedure ClickingLinkFiresOnLinkClick;
    [Test]
    procedure MouseDragSelectsText;
    [Test]
    procedure TableRendersCellsAndAlignments;
    [Test]
    procedure ImageBlockRendersWithHeight;
    [Test]
    procedure InvalidImageFallsBackToAltText;
    [Test]
    procedure RemoteImageUrlShowsAltText;
    [Test]
    procedure SelectionHighlightRendersForPartialSelection;
    [Test]
    procedure AppendsMarkdownWithoutReplacingExistingText;
    [Test]
    procedure AppendFiresOnChange;
    [Test]
    procedure AppendHandlesSplitLineBreak;
    [Test]
    procedure TypingPreservesScrollPosition;
    [Test]
    procedure DirectEditingInsertsTextAndSupportsUndo;
    [Test]
    procedure DirectEditingSupportsMultipleUndoAndRedo;
    [Test]
    procedure DirectEditingMovesCaretVertically;
    [Test]
    procedure DirectEditingSupportsHomeAndEnd;
    [Test]
    procedure DirectEditingSupportsPageNavigation;
    [Test]
    procedure DirectEditingSupportsControlHomeAndEnd;
    [Test]
    procedure DirectEditingInsertsInsideWrappedParagraph;
    [Test]
    procedure DirectEditingInsertsInsideMultiLineParagraph;
    [Test]
    procedure DirectEditingBackspaceJoinsBlocks;
    [Test]
    procedure DirectEditingArrowSkipsLineBreakPair;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  System.UITypes,
  Vcl.Graphics,
  Winapi.Windows;

function CreateTempBitmap(AWidth, AHeight: Integer): string;
var
  Bmp: Vcl.Graphics.TBitmap;
begin
  Result := TPath.Combine(TPath.GetTempPath,
    'KaiMvImg_' + TGuid.NewGuid.ToString + '.bmp');
  Bmp := Vcl.Graphics.TBitmap.Create;
  try
    Bmp.SetSize(AWidth, AHeight);
    Bmp.Canvas.Brush.Color := clSkyBlue;
    Bmp.Canvas.FillRect(Rect(0, 0, AWidth, AHeight));
    Bmp.SaveToFile(Result);
  finally
    Bmp.Free;
  end;
end;

function CreateCorruptImageFile: string;
begin
  Result := TPath.Combine(TPath.GetTempPath,
    'KaiMvImg_' + TGuid.NewGuid.ToString + '.bmp');
  TFile.WriteAllText(Result, 'this is not a bitmap');
end;

procedure TTestMarkDownViewer.PressKey(Value: Word; Shift: TShiftState);
var
  Key: Word;
begin
  Key := Value;
  KeyDown(Key, Shift);
end;

procedure TTestMarkDownViewer.TypeCharacter(Value: Char);
begin
  KeyPress(Value);
end;

procedure TTestMarkDownViewer.ClickMouse(X, Y: Integer);
begin
  MouseDown(mbLeft, [], X, Y);
  MouseUp(mbLeft, [], X, Y);
end;

procedure TTestMarkDownViewer.DragMouse(X1, Y1, X2, Y2: Integer);
begin
  MouseDown(mbLeft, [], X1, Y1);
  MouseMove([], X2, Y2);
  MouseUp(mbLeft, [], X2, Y2);
end;

function TTestMarkDownViewer.HoverShowsLink(X, Y: Integer): Boolean;
begin
  MouseMove([], X, Y);
  Result := Cursor = crHandPoint;
end;

procedure TMarkDownViewerTests.HandleViewerChange(Sender: TObject);
begin
  Inc(FChangeCount);
end;

procedure TMarkDownViewerTests.HandleLinkClick(Sender: TObject; const Url: string);
begin
  FLinkUrl := Url;
end;

// Locates a point inside a rendered link by sweeping the client area for the
// hand cursor the viewer shows over links (requires ReadOnly). This keeps the
// click tests independent of fonts, margins, and exact layout geometry.
function TMarkDownViewerTests.FindLinkPoint(out X, Y: Integer): Boolean;
var
  PX, PY: Integer;
begin
  Result := False;
  PY := 0;
  while PY < FViewer.ClientHeight do
  begin
    PX := 0;
    while PX < FViewer.ClientWidth do
    begin
      if FViewer.HoverShowsLink(PX, PY) then
      begin
        X := PX;
        Y := PY;
        Exit(True);
      end;
      Inc(PX, 2);
    end;
    Inc(PY, 3);
  end;
end;

procedure TMarkDownViewerTests.ShowViewer(AWidth, AHeight: Integer);
begin
  FForm := TForm.Create(nil);
  FViewer := TTestMarkDownViewer.Create(FForm);
  FViewer.Parent := FForm;
  FViewer.SetBounds(0, 0, AWidth, AHeight);
  FViewer.ReadOnly := False;
  FForm.Show;
end;

procedure TMarkDownViewerTests.RepaintViewer;
begin
  Application.ProcessMessages;
  FViewer.Repaint;
end;

procedure TMarkDownViewerTests.TearDown;
begin
  FreeAndNil(FForm);
  FViewer := nil;
end;

procedure TMarkDownViewerTests.UsesReadableDefaultFont;
var
  Viewer: TMarkDownViewer;
begin
  Viewer := TMarkDownViewer.Create(nil);
  try
    Assert.IsTrue(Viewer.Font.Size >= 10, Viewer.Font.Size.ToString);
  finally
    Viewer.Free;
  end;
end;

procedure TMarkDownViewerTests.ReadOnlyIsEnabledByDefault;
var
  Viewer: TMarkDownViewer;
begin
  Viewer := TMarkDownViewer.Create(nil);
  try
    Assert.IsTrue(Viewer.ReadOnly);
  finally
    Viewer.Free;
  end;
end;

procedure TMarkDownViewerTests.ExposesExpectedColorDefaults;
var
  Viewer: TMarkDownViewer;
begin
  Viewer := TMarkDownViewer.Create(nil);
  try
    Assert.AreEqual(Integer(clHighlight), Integer(Viewer.LinkColor));
    Assert.AreEqual(Integer($00F2F2F2), Integer(Viewer.CodeBackgroundColor));
    Assert.AreEqual(Integer(clSilver), Integer(Viewer.QuoteBarColor));
    Assert.AreEqual(Integer($00BFFFFF), Integer(Viewer.SearchHighlightColor));
  finally
    Viewer.Free;
  end;
end;

procedure TMarkDownViewerTests.PropertiesRoundTrip;
var
  Viewer: TMarkDownViewer;
begin
  Viewer := TMarkDownViewer.Create(nil);
  try
    Viewer.LinkColor := clRed;
    Viewer.CodeBackgroundColor := clYellow;
    Viewer.QuoteBarColor := clGreen;
    Viewer.SearchHighlightColor := clAqua;
    Viewer.BasePath := 'C:\docs\';
    Viewer.SearchText := 'needle';
    Viewer.ReadOnly := False;

    Assert.AreEqual(Integer(clRed), Integer(Viewer.LinkColor));
    Assert.AreEqual(Integer(clYellow), Integer(Viewer.CodeBackgroundColor));
    Assert.AreEqual(Integer(clGreen), Integer(Viewer.QuoteBarColor));
    Assert.AreEqual(Integer(clAqua), Integer(Viewer.SearchHighlightColor));
    Assert.AreEqual('C:\docs\', Viewer.BasePath);
    Assert.AreEqual('needle', Viewer.SearchText);
    Assert.IsFalse(Viewer.ReadOnly);
  finally
    Viewer.Free;
  end;
end;

procedure TMarkDownViewerTests.LoadFromFileSetsBasePathAndContent;
var
  Viewer: TMarkDownViewer;
  FileName: string;
begin
  FileName := TPath.Combine(TPath.GetTempPath,
    'KaiMarkdownViewerTest_' + TGuid.NewGuid.ToString + '.md');
  TFile.WriteAllText(FileName, '# Loaded' + sLineBreak + 'body text');
  Viewer := TMarkDownViewer.Create(nil);
  try
    Viewer.LoadFromFile(FileName);
    Assert.AreEqual(ExtractFilePath(FileName), Viewer.BasePath);
    Assert.IsTrue(Viewer.MarkdownText.Contains('# Loaded'), Viewer.MarkdownText);
    Assert.IsTrue(Viewer.MarkdownText.Contains('body text'), Viewer.MarkdownText);
  finally
    Viewer.Free;
    TFile.Delete(FileName);
  end;
end;

procedure TMarkDownViewerTests.SelectAllCopiesRenderedPlainText;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '**bold _italic_**';
  RepaintViewer;

  FViewer.SelectAll;

  // The full selection picks up the trailing block break; the run text is the
  // point of interest here.
  Assert.AreEqual('bold italic', FViewer.SelectedText(True).Trim);
end;

procedure TMarkDownViewerTests.HardLineBreakCopiesAsLineBreak;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'first  ' + sLineBreak + 'second';
  RepaintViewer;

  FViewer.SelectAll;

  // Trim only removes the trailing block break, leaving the internal hard
  // break that the two trailing spaces produced.
  Assert.AreEqual('first' + sLineBreak + 'second', FViewer.SelectedText(True).Trim);
end;

procedure TMarkDownViewerTests.FullSelectionCopyMarkdownReturnsSource;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '# Heading';
  RepaintViewer;

  FViewer.SelectAll;

  Assert.AreEqual('# Heading', FViewer.SelectedText(False).Trim);
end;

procedure TMarkDownViewerTests.PartialSelectionCopyReconstructsBoldMarkdown;
var
  I: Integer;
begin
  // A partial selection bypasses the whole-document shortcut and forces the
  // per-run markdown reconstruction used for copying styled spans.
  ShowViewer(400, 300);
  FViewer.MarkdownText := '**bold** x';
  RepaintViewer;

  FViewer.PressKey(VK_HOME, [ssCtrl]);
  for I := 1 to 5 do
    FViewer.PressKey(VK_RIGHT, [ssShift]);

  Assert.IsTrue(FViewer.SelectedText(False).Contains('**bold**'),
    FViewer.SelectedText(False));
end;

procedure TMarkDownViewerTests.ClickingLinkFiresOnLinkClick;
var
  LinkX, LinkY: Integer;
begin
  ShowViewer(400, 300);
  FViewer.ReadOnly := True;
  FViewer.MarkdownText := '[Example](https://example.com/)';
  RepaintViewer;
  FViewer.OnLinkClick := HandleLinkClick;
  FLinkUrl := '';

  Assert.IsTrue(FindLinkPoint(LinkX, LinkY), 'no link region was rendered');
  FViewer.ClickMouse(LinkX, LinkY);

  Assert.AreEqual('https://example.com/', FLinkUrl);
end;

procedure TMarkDownViewerTests.MouseDragSelectsText;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'alpha bravo charlie';
  RepaintViewer;

  // Drag across the first line (content origin is at the padding offset).
  FViewer.DragMouse(0, 22, 10000, 22);

  Assert.AreEqual('alpha bravo charlie', FViewer.SelectedText(True));
end;

procedure TMarkDownViewerTests.TableRendersCellsAndAlignments;
begin
  ShowViewer(500, 300);
  FViewer.MarkdownText :=
    '| L | C | R |' + sLineBreak +
    '| :--- | :---: | ---: |' + sLineBreak +
    '| a | b | c |';
  RepaintViewer;

  FViewer.SelectAll;

  // Cells render as tab-separated selectable text with one line per row; the
  // separator row is skipped. This exercises DrawTable, MeasureCellHeight,
  // and all three branches of TableAlignmentFromCell.
  Assert.AreEqual('L'#9'C'#9'R' + sLineBreak + 'a'#9'b'#9'c',
    FViewer.SelectedText(True).Trim);
end;

procedure TMarkDownViewerTests.ImageBlockRendersWithHeight;
var
  ImageFile: string;
begin
  // A 200x400 image is taller than the 300px viewport, so loading and laying
  // it out must push the content height past the viewport.
  ImageFile := CreateTempBitmap(200, 400);
  try
    ShowViewer(400, 300);
    FViewer.BasePath := ExtractFilePath(ImageFile);
    FViewer.MarkdownText := '![alt](' + ExtractFileName(ImageFile) + ')';
    RepaintViewer;
    Assert.IsTrue(FViewer.MaxScrollPosition > 0, 'image did not add height');

    // A second paint hits the image cache rather than reloading.
    RepaintViewer;
    Assert.IsTrue(FViewer.MaxScrollPosition > 0);
  finally
    TFile.Delete(ImageFile);
  end;
end;

procedure TMarkDownViewerTests.InvalidImageFallsBackToAltText;
var
  ImageFile: string;
begin
  // The file exists but is not a valid image, so the cached load fails and the
  // alt text is drawn instead - a single short line that fits the viewport.
  ImageFile := CreateCorruptImageFile;
  try
    ShowViewer(400, 300);
    FViewer.BasePath := ExtractFilePath(ImageFile);
    FViewer.MarkdownText := '![fallback alt](' + ExtractFileName(ImageFile) + ')';
    RepaintViewer;
    Assert.AreEqual(0, FViewer.MaxScrollPosition);
  finally
    TFile.Delete(ImageFile);
  end;
end;

procedure TMarkDownViewerTests.RemoteImageUrlShowsAltText;
begin
  // A remote URL is never fetched; the alt text is drawn instead.
  ShowViewer(400, 300);
  FViewer.MarkdownText := '![remote alt](https://example.com/image.png)';
  RepaintViewer;
  Assert.AreEqual(0, FViewer.MaxScrollPosition);
end;

procedure TMarkDownViewerTests.SelectionHighlightRendersForPartialSelection;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'alpha bravo charlie';
  RepaintViewer;

  // Select two characters in the middle of the first word, then repaint so the
  // selection highlight is drawn (prefix, selected, and suffix segments).
  FViewer.PressKey(VK_HOME, [ssCtrl]);
  FViewer.PressKey(VK_RIGHT);
  FViewer.PressKey(VK_RIGHT);
  FViewer.PressKey(VK_RIGHT, [ssShift]);
  FViewer.PressKey(VK_RIGHT, [ssShift]);
  RepaintViewer;

  Assert.AreEqual('ph', FViewer.SelectedText(True));
end;

procedure TMarkDownViewerTests.AppendsMarkdownWithoutReplacingExistingText;
var
  Viewer: TMarkDownViewer;
begin
  Viewer := TMarkDownViewer.Create(nil);
  try
    Viewer.MarkdownText := '# Heading';
    Viewer.AppendMarkdownText(sLineBreak + '- Item');
    Assert.IsTrue(Pos('# Heading', Viewer.MarkdownText) > 0);
    Assert.IsTrue(Pos('- Item', Viewer.MarkdownText) > 0);
  finally
    Viewer.Free;
  end;
end;

procedure TMarkDownViewerTests.AppendFiresOnChange;
var
  Viewer: TMarkDownViewer;
begin
  Viewer := TMarkDownViewer.Create(nil);
  try
    Viewer.MarkdownText := '# Heading';
    Viewer.OnChange := HandleViewerChange;
    FChangeCount := 0;
    Viewer.AppendMarkdownText(sLineBreak + '- Item');
    Assert.AreEqual(1, FChangeCount);
  finally
    Viewer.Free;
  end;
end;

procedure TMarkDownViewerTests.AppendHandlesSplitLineBreak;
var
  Viewer: TMarkDownViewer;
begin
  Viewer := TMarkDownViewer.Create(nil);
  try
    Viewer.MarkdownText := '# a';
    Viewer.AppendMarkdownText(sLineBreak + '- one' + #13);
    Viewer.AppendMarkdownText(#10 + '- two');
    Assert.AreEqual(3, Viewer.Markdown.Count, Viewer.MarkdownText);
    Assert.AreEqual('- one', Viewer.Markdown[1]);
    Assert.AreEqual('- two', Viewer.Markdown[2]);
  finally
    Viewer.Free;
  end;
end;

procedure TMarkDownViewerTests.TypingPreservesScrollPosition;
var
  I: Integer;
  SavedScrollPos: Integer;
  Source: TStringList;
begin
  ShowViewer(400, 120);
  Source := TStringList.Create;
  try
    for I := 1 to 20 do
    begin
      Source.Add('# Heading ' + I.ToString);
      Source.Add('');
    end;
    FViewer.Markdown.Assign(Source);
  finally
    Source.Free;
  end;
  RepaintViewer;

  for I := 1 to 30 do
    FViewer.PressKey(VK_DOWN);
  SavedScrollPos := FViewer.ScrollPosition;
  Assert.IsTrue(SavedScrollPos > 0,
    'expected caret movement to scroll the view');

  FViewer.TypeCharacter('X');
  Assert.AreEqual(SavedScrollPos, FViewer.ScrollPosition);
end;

procedure TMarkDownViewerTests.DirectEditingInsertsTextAndSupportsUndo;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '# Heading';
  RepaintViewer;

  FViewer.TypeCharacter('X');
  Assert.IsTrue(FViewer.MarkdownText.StartsWith('# XHeading'),
    FViewer.MarkdownText);

  FViewer.Undo;
  Assert.IsTrue(FViewer.MarkdownText.StartsWith('# Heading'),
    FViewer.MarkdownText);
end;

procedure TMarkDownViewerTests.DirectEditingSupportsMultipleUndoAndRedo;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '# Heading';
  RepaintViewer;

  FViewer.TypeCharacter('A');
  FViewer.TypeCharacter('B');
  Assert.IsTrue(FViewer.MarkdownText.StartsWith('# ABHeading'),
    FViewer.MarkdownText);

  FViewer.Undo;
  Assert.IsTrue(FViewer.MarkdownText.StartsWith('# AHeading'),
    FViewer.MarkdownText);

  FViewer.Undo;
  Assert.IsTrue(FViewer.MarkdownText.StartsWith('# Heading'),
    FViewer.MarkdownText);

  FViewer.Redo;
  Assert.IsTrue(FViewer.MarkdownText.StartsWith('# AHeading'),
    FViewer.MarkdownText);
end;

procedure TMarkDownViewerTests.DirectEditingMovesCaretVertically;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '# first' + sLineBreak + sLineBreak + '# second';
  RepaintViewer;

  FViewer.PressKey(VK_DOWN);
  FViewer.TypeCharacter('X');
  Assert.IsTrue(FViewer.MarkdownText.Contains(sLineBreak + sLineBreak + '# Xsecond'),
    FViewer.MarkdownText);

  FViewer.PressKey(VK_UP);
  FViewer.TypeCharacter('Y');
  Assert.IsTrue(Pos('Y', Copy(FViewer.MarkdownText, 1,
    Pos(sLineBreak, FViewer.MarkdownText) - 1)) > 0, FViewer.MarkdownText);
end;

procedure TMarkDownViewerTests.DirectEditingSupportsHomeAndEnd;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '# first';
  RepaintViewer;

  FViewer.PressKey(VK_END);
  FViewer.TypeCharacter('X');
  Assert.IsTrue(FViewer.MarkdownText.StartsWith('# firstX'),
    FViewer.MarkdownText);

  FViewer.PressKey(VK_HOME);
  FViewer.TypeCharacter('Y');
  Assert.IsTrue(FViewer.MarkdownText.StartsWith('# YfirstX'),
    FViewer.MarkdownText);
end;

procedure TMarkDownViewerTests.DirectEditingSupportsPageNavigation;
var
  I: Integer;
  Source: TStringList;
begin
  ShowViewer(400, 120);
  Source := TStringList.Create;
  try
    for I := 1 to 20 do
    begin
      Source.Add('# Heading ' + I.ToString);
      Source.Add('');
    end;
    FViewer.Markdown.Assign(Source);
  finally
    Source.Free;
  end;
  RepaintViewer;

  FViewer.PressKey(VK_NEXT);
  Assert.IsTrue(FViewer.ScrollPosition > 0);
  FViewer.PressKey(VK_PRIOR);
  Assert.AreEqual(0, FViewer.ScrollPosition);
end;

procedure TMarkDownViewerTests.DirectEditingSupportsControlHomeAndEnd;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '# first' + sLineBreak + sLineBreak + '# second';
  RepaintViewer;

  FViewer.PressKey(VK_END, [ssCtrl]);
  FViewer.TypeCharacter('X');
  Assert.IsTrue(FViewer.MarkdownText.Contains('# secondX'),
    FViewer.MarkdownText);

  FViewer.PressKey(VK_HOME, [ssCtrl]);
  FViewer.TypeCharacter('Y');
  Assert.IsTrue(FViewer.MarkdownText.StartsWith('# Yfirst'),
    FViewer.MarkdownText);

  FViewer.PressKey(VK_HOME, [ssCtrl]);
  FViewer.PressKey(VK_END, [ssCtrl, ssShift]);
  FViewer.TypeCharacter('Z');
  Assert.IsTrue(FViewer.MarkdownText.StartsWith('# Z'),
    FViewer.MarkdownText);
end;

procedure TMarkDownViewerTests.DirectEditingInsertsInsideWrappedParagraph;
var
  Text: string;
begin
  ShowViewer(160, 300);
  FViewer.MarkdownText :=
    'alpha bravo charlie delta echo foxtrot golf hotel india juliet';
  RepaintViewer;

  FViewer.PressKey(VK_DOWN);
  FViewer.PressKey(VK_END);
  FViewer.TypeCharacter('X');

  Text := FViewer.MarkdownText;
  Assert.IsTrue(Pos('X', Text) > 0, Text);
  Assert.IsTrue(Pos('X', Text) < Pos('juliet', Text), Text);
end;

procedure TMarkDownViewerTests.DirectEditingInsertsInsideMultiLineParagraph;
var
  I: Integer;
begin
  ShowViewer(400, 300);
  FViewer.Markdown.Add('alpha bravo');
  FViewer.Markdown.Add('charlie delta');
  RepaintViewer;

  for I := 1 to 14 do
    FViewer.PressKey(VK_RIGHT);
  FViewer.TypeCharacter('X');

  Assert.IsTrue(FViewer.MarkdownText.Contains('chXarlie'),
    FViewer.MarkdownText);
end;

procedure TMarkDownViewerTests.DirectEditingBackspaceJoinsBlocks;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '# alpha' + sLineBreak + sLineBreak + '# bravo';
  RepaintViewer;

  FViewer.PressKey(VK_DOWN);
  FViewer.PressKey(VK_BACK);

  Assert.IsFalse(FViewer.MarkdownText.Contains(sLineBreak + sLineBreak),
    FViewer.MarkdownText);
  Assert.IsTrue(FViewer.MarkdownText.StartsWith('# alphabravo'),
    FViewer.MarkdownText);
end;

procedure TMarkDownViewerTests.DirectEditingArrowSkipsLineBreakPair;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '# alpha' + sLineBreak + sLineBreak + '# bravo';
  RepaintViewer;

  FViewer.PressKey(VK_END);
  FViewer.PressKey(VK_RIGHT);
  FViewer.TypeCharacter('X');

  Assert.IsTrue(FViewer.MarkdownText.Contains('# Xbravo'),
    FViewer.MarkdownText);
end;

initialization
  TDUnitX.RegisterTestFixture(TMarkDownViewerTests);

end.
