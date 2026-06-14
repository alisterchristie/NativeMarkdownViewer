unit Test.MarkdownViewerVCL;

interface

uses
  DUnitX.TestFramework,
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  MarkdownViewerVCL,
  MarkdownViewer.Model;

type
  TTestMarkDownViewer = class(TMarkDownViewer)
  public
    procedure PressKey(Value: Word; Shift: TShiftState = []);
    procedure TypeCharacter(Value: Char);
    procedure ClickMouse(X, Y: Integer);
    procedure DoubleClickMouse(X, Y: Integer);
    procedure DragMouse(X1, Y1, X2, Y2: Integer);
    function HoverShowsLink(X, Y: Integer): Boolean;
    function GetRunContainingCaret: TMarkDownTextRun;
  end;

  [TestFixture]
  TMarkDownViewerTests = class
  private
    FChangeCount: Integer;
    FScrollCount: Integer;
    FForm: TForm;
    FViewer: TTestMarkDownViewer;
    FLinkUrl: string;
    procedure HandleViewerChange(Sender: TObject);
    procedure HandleViewerScroll(Sender: TObject);
    procedure HandleLinkClick(Sender: TObject; const Url: string);
    procedure RepaintViewer;
    procedure ShowViewer(AWidth, AHeight: Integer);
    procedure ShowTallViewer;
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
    procedure CutCopiesAndRemovesSelection;
    [Test]
    procedure CopyPasteRoundTripsThroughClipboard;
    [Test]
    procedure VScrollMessageScrollsAndFiresOnScroll;
    [Test]
    procedure MouseWheelScrollsDown;
    [Test]
    procedure GetDlgCodeRequestsArrowKeys;
    [Test]
    procedure SetMarkdownPropertyReplacesContent;
    [Test]
    procedure AppendingLinkReferenceClearsTokenCaches;
    [Test]
    procedure ClickingUnsafeLinkWithoutHandlerIsIgnored;
    [Test]
    procedure CodeFontNameDefaultsToConsolas;
    [Test]
    procedure CodeFontNameRoundTrips;
    [Test]
    procedure SearchMatchCountCountsOccurrences;
    [Test]
    procedure FindNextCyclesThroughMatches;
    [Test]
    procedure FindPreviousMovesBackward;
    [Test]
    procedure TaskCheckboxClickToggles;
    [Test]
    procedure TaskToggleCanBeUndone;
    [Test]
    procedure DisablingTaskToggleIgnoresClicks;
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
    [Test]
    procedure DirectEditingEnterRestsCaretOnBlankLine;
    [Test]
    procedure DirectEditingCaretCanRestBetweenParagraphs;
    [Test]
    procedure TabConvertsParagraphToHeading;
    [Test]
    procedure TabIncreasesHeadingLevel;
    [Test]
    procedure ShiftTabDecreasesHeadingLevel;
    [Test]
    procedure ShiftTabOnH1StripsToParagraph;
    [Test]
    procedure TabDemotesSetextHeading;
    [Test]
    procedure TabIndentsBulletListItem;
    [Test]
    procedure ShiftTabOutdentsBulletListItem;
    [Test]
    procedure TabIndentsChecklistItem;
    [Test]
    procedure CtrlKInsertsLink;
    [Test]
    procedure CtrlKWrapsSelectionInLink;
    [Test]
    procedure CtrlSpaceTogglesCheckbox;
    [Test]
    procedure Ctrl1To6SetsHeadingLevel;
    [Test]
    procedure Ctrl0StripsHeading;
    [Test]
    procedure AltUpDownMovesLine;
    [Test]
    procedure AltUpDownPreservesCaretOffset;
    [Test]
    procedure CtrlTAndCtrlHFormatting;
    [Test]
    procedure AutoPairsOpeningBracketsAndQuotes;
    [Test]
    procedure PreventsAutoPairingQuotesAfterWordChars;
    [Test]
    procedure StepsOverClosingBracketsAndQuotes;
    [Test]
    procedure BackspaceDeletesBracketAndQuotePairs;
    [Test]
    procedure TabOnHeadingPreservesCaretColumn;
    [Test]
    procedure ReadOnlyArrowKeysScroll;
    [Test]
    procedure RendersQuoteBlockWithDefaultColors;
    [Test]
    procedure SearchTextHighlightsMatchesOnPaint;
    [Test]
    procedure CtrlASelectsAllText;
    [Test]
    procedure CtrlZUndoesAndCtrlYRedoes;
    [Test]
    procedure DeleteKeyRemovesSelection;
    [Test]
    procedure CtrlBWrapsSelectionInBold;
    [Test]
    procedure CtrlBTogglesBoldOff;
    [Test]
    procedure CtrlIWrapsSelectionInItalic;
    [Test]
    procedure CtrlEWrapsSelectionInCode;
    [Test]
    procedure CtrlBBoldsPartialSelection;
    [Test]
    procedure CtrlRightMovesByWord;
    [Test]
    procedure CtrlBackspaceDeletesWord;
    [Test]
    procedure CtrlDeleteDeletesWordForward;
    [Test]
    procedure TypingBracketWrapsSelection;
    [Test]
    procedure TypingCharWithoutSelectionInsertsLiterally;
    [Test]
    procedure ToggleStrikethroughWrapsSelection;
    [Test]
    procedure ToggleBoldMethodMatchesShortcut;
    [Test]
    procedure SelectWordAtCaretSelectsWord;
    [Test]
    procedure DoubleClickSelectsWord;
    [Test]
    procedure EnterContinuesBulletList;
    [Test]
    procedure EnterIncrementsOrderedList;
    [Test]
    procedure EnterContinuesTaskAsUnchecked;
    [Test]
    procedure EnterOnEmptyItemExitsList;
    [Test]
    procedure EnterInMiddleOfListInsertsItem;
    [Test]
    procedure CodeBlockWithoutHighlightingRendersWithoutException;
    [Test]
    procedure CodeBlockWithHighlightingRendersWithoutException;
    [Test]
    procedure HoverOverCodeBlockShowsCopyButton;
    [Test]
    procedure ClickingCopyButtonCopiesToClipboard;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  System.UITypes,
  Vcl.Graphics,
  Vcl.Clipbrd,
  Winapi.Messages,
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

procedure TTestMarkDownViewer.DoubleClickMouse(X, Y: Integer);
begin
  MouseDown(mbLeft, [], X, Y);
  MouseUp(mbLeft, [], X, Y);
  MouseDown(mbLeft, [ssDouble], X, Y);
  DblClick;
  MouseUp(mbLeft, [], X, Y);
end;

function TTestMarkDownViewer.GetRunContainingCaret: TMarkDownTextRun;
begin
  Result := RunContainingCaret;
end;

procedure TMarkDownViewerTests.HandleViewerChange(Sender: TObject);
begin
  Inc(FChangeCount);
end;

procedure TMarkDownViewerTests.HandleViewerScroll(Sender: TObject);
begin
  Inc(FScrollCount);
end;

procedure TMarkDownViewerTests.ShowTallViewer;
var
  I: Integer;
  Source: TStringList;
begin
  ShowViewer(400, 120);
  Source := TStringList.Create;
  try
    for I := 1 to 40 do
    begin
      Source.Add('# Heading ' + I.ToString);
      Source.Add('');
    end;
    FViewer.Markdown.Assign(Source);
  finally
    Source.Free;
  end;
  RepaintViewer;
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
    Assert.AreEqual(Integer(clDefault), Integer(Viewer.LinkColor));
    Assert.AreEqual(Integer(clDefault), Integer(Viewer.CodeBackgroundColor));
    Assert.AreEqual(Integer(clDefault), Integer(Viewer.QuoteBarColor));
    Assert.AreEqual(Integer(clDefault), Integer(Viewer.HeadingRuleColor));
    Assert.AreEqual(Integer(clDefault), Integer(Viewer.SearchHighlightColor));
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
    Viewer.HeadingRuleColor := clNavy;
    Viewer.SearchHighlightColor := clAqua;
    Viewer.BasePath := 'C:\docs\';
    Viewer.SearchText := 'needle';
    Viewer.ReadOnly := False;

    Assert.AreEqual(Integer(clRed), Integer(Viewer.LinkColor));
    Assert.AreEqual(Integer(clYellow), Integer(Viewer.CodeBackgroundColor));
    Assert.AreEqual(Integer(clGreen), Integer(Viewer.QuoteBarColor));
    Assert.AreEqual(Integer(clNavy), Integer(Viewer.HeadingRuleColor));
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

procedure TMarkDownViewerTests.CutCopiesAndRemovesSelection;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'hello';
  RepaintViewer;

  FViewer.SelectAll;
  FViewer.PressKey(Ord('X'), [ssCtrl]);

  Assert.AreEqual('', FViewer.MarkdownText.Trim);
end;

procedure TMarkDownViewerTests.CopyPasteRoundTripsThroughClipboard;
var
  Attempt: Integer;
  Pasted: Boolean;
begin
  ShowViewer(400, 300);

  // The clipboard is a shared OS resource; another process can briefly hold it,
  // so retry the round trip a few times before deciding it really failed.
  Pasted := False;
  for Attempt := 1 to 5 do
  begin
    FViewer.MarkdownText := 'AB';
    RepaintViewer;
    FViewer.SelectAll;
    FViewer.CopySelection(True);
    FViewer.PressKey(VK_END, [ssCtrl]);
    FViewer.PressKey(Ord('V'), [ssCtrl]);
    if FViewer.MarkdownText.Trim = 'ABAB' then
    begin
      Pasted := True;
      Break;
    end;
  end;

  Assert.IsTrue(Pasted, 'clipboard copy/paste did not round trip');
end;

procedure TMarkDownViewerTests.VScrollMessageScrollsAndFiresOnScroll;
begin
  ShowTallViewer;
  FViewer.OnScroll := HandleViewerScroll;
  FScrollCount := 0;

  FViewer.Perform(WM_VSCROLL, SB_LINEDOWN, 0);

  Assert.IsTrue(FViewer.ScrollPosition > 0, 'scrollbar message did not scroll');
  Assert.IsTrue(FScrollCount > 0, 'OnScroll did not fire');
end;

procedure TMarkDownViewerTests.MouseWheelScrollsDown;
begin
  ShowTallViewer;

  FViewer.Perform(WM_MOUSEWHEEL, MakeWParam(0, Word(-WHEEL_DELTA)), 0);

  Assert.IsTrue(FViewer.ScrollPosition > 0, 'mouse wheel did not scroll');
end;

procedure TMarkDownViewerTests.GetDlgCodeRequestsArrowKeys;
var
  Code: Integer;
begin
  ShowViewer(400, 300);
  FViewer.ReadOnly := True;
  Code := FViewer.Perform(WM_GETDLGCODE, 0, 0);
  Assert.AreNotEqual(0, Code and DLGC_WANTARROWS);

  // Editing additionally claims character and all keys.
  FViewer.ReadOnly := False;
  Code := FViewer.Perform(WM_GETDLGCODE, 0, 0);
  Assert.AreNotEqual(0, Code and DLGC_WANTALLKEYS);
end;

procedure TMarkDownViewerTests.SetMarkdownPropertyReplacesContent;
var
  Viewer: TMarkDownViewer;
  Source: TStringList;
begin
  Viewer := TMarkDownViewer.Create(nil);
  Source := TStringList.Create;
  try
    Source.Add('# Assigned');
    Viewer.Markdown := Source;
    Assert.IsTrue(Viewer.MarkdownText.Contains('# Assigned'), Viewer.MarkdownText);
  finally
    Source.Free;
    Viewer.Free;
  end;
end;

procedure TMarkDownViewerTests.AppendingLinkReferenceClearsTokenCaches;
var
  Viewer: TMarkDownViewer;
begin
  // Appending a new link-reference definition changes the reference table,
  // which clears the cached inline tokens so later blocks re-resolve links.
  Viewer := TMarkDownViewer.Create(nil);
  try
    Viewer.MarkdownText := 'See [docs][ref].';
    Viewer.AppendMarkdownText(sLineBreak + sLineBreak + '[ref]: https://example.com');
    Assert.IsTrue(Viewer.MarkdownText.Contains('[ref]: https://example.com'),
      Viewer.MarkdownText);
  finally
    Viewer.Free;
  end;
end;

procedure TMarkDownViewerTests.ClickingUnsafeLinkWithoutHandlerIsIgnored;
var
  LinkX, LinkY: Integer;
begin
  // With no OnLinkClick handler and a non-web URL, the safety check rejects the
  // URL so nothing is launched. The test just confirms the path runs cleanly.
  ShowViewer(400, 300);
  FViewer.ReadOnly := True;
  FViewer.MarkdownText := '[open](customscheme:payload)';
  RepaintViewer;

  Assert.IsTrue(FindLinkPoint(LinkX, LinkY), 'no link region was rendered');
  FViewer.ClickMouse(LinkX, LinkY);

  Assert.Pass;
end;

procedure TMarkDownViewerTests.CodeFontNameDefaultsToConsolas;
var
  Viewer: TMarkDownViewer;
begin
  Viewer := TMarkDownViewer.Create(nil);
  try
    Assert.AreEqual('Consolas', Viewer.CodeFontName);
  finally
    Viewer.Free;
  end;
end;

procedure TMarkDownViewerTests.CodeFontNameRoundTrips;
var
  Viewer: TMarkDownViewer;
begin
  Viewer := TMarkDownViewer.Create(nil);
  try
    Viewer.CodeFontName := 'Courier New';
    Assert.AreEqual('Courier New', Viewer.CodeFontName);
  finally
    Viewer.Free;
  end;
end;

procedure TMarkDownViewerTests.SearchMatchCountCountsOccurrences;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'one match two match three';
  RepaintViewer;

  FViewer.SearchText := 'match';
  Assert.AreEqual(2, FViewer.SearchMatchCount);
end;

procedure TMarkDownViewerTests.FindNextCyclesThroughMatches;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'Apple apple APPLE';
  RepaintViewer;
  FViewer.SearchText := 'apple';

  // Case-insensitive matching, original case preserved, wrap at the end.
  Assert.IsTrue(FViewer.FindNext);
  Assert.AreEqual('Apple', FViewer.SelectedText(True));
  Assert.IsTrue(FViewer.FindNext);
  Assert.AreEqual('apple', FViewer.SelectedText(True));
  Assert.IsTrue(FViewer.FindNext);
  Assert.AreEqual('APPLE', FViewer.SelectedText(True));
  Assert.IsTrue(FViewer.FindNext);
  Assert.AreEqual('Apple', FViewer.SelectedText(True));
end;

procedure TMarkDownViewerTests.FindPreviousMovesBackward;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'Apple apple APPLE';
  RepaintViewer;
  FViewer.SearchText := 'apple';

  FViewer.FindNext;            // Apple
  FViewer.FindNext;            // apple
  Assert.IsTrue(FViewer.FindPrevious);
  Assert.AreEqual('Apple', FViewer.SelectedText(True));
end;

procedure TMarkDownViewerTests.TaskCheckboxClickToggles;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '- [ ] task';
  RepaintViewer;

  // The checkbox sits near the top-left of the first list item.
  FViewer.ClickMouse(24, 24);
  Assert.IsTrue(FViewer.MarkdownText.Contains('[x]'), FViewer.MarkdownText);

  RepaintViewer;
  FViewer.ClickMouse(24, 24);
  Assert.IsTrue(FViewer.MarkdownText.Contains('[ ]'), FViewer.MarkdownText);
end;

procedure TMarkDownViewerTests.TaskToggleCanBeUndone;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '- [ ] task';
  RepaintViewer;

  FViewer.ClickMouse(24, 24);
  Assert.IsTrue(FViewer.MarkdownText.Contains('[x]'), FViewer.MarkdownText);

  FViewer.Undo;
  Assert.IsTrue(FViewer.MarkdownText.Contains('[ ]'), FViewer.MarkdownText);
end;

procedure TMarkDownViewerTests.DisablingTaskToggleIgnoresClicks;
begin
  ShowViewer(400, 300);
  FViewer.AllowTaskToggle := False;
  FViewer.MarkdownText := '- [ ] task';
  RepaintViewer;

  FViewer.ClickMouse(24, 24);
  Assert.IsTrue(FViewer.MarkdownText.Contains('[ ]'), FViewer.MarkdownText);
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

  // Repaint between key presses the way the real message loop does, so the
  // scroll tracks the caret instead of accumulating an over-scroll from stale
  // layout (which would otherwise leave the caret off-screen).
  for I := 1 to 30 do
  begin
    FViewer.PressKey(VK_DOWN);
    RepaintViewer;
  end;
  SavedScrollPos := FViewer.ScrollPosition;
  Assert.IsTrue(SavedScrollPos > 0,
    'expected caret movement to scroll the view');

  // Typing where the caret already sits must not jump the view.
  FViewer.TypeCharacter('X');
  RepaintViewer;
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

  // When editing, the empty line between the headings is its own caret stop, so
  // reaching the second heading takes two Down presses.
  FViewer.PressKey(VK_DOWN);
  FViewer.PressKey(VK_DOWN);
  FViewer.TypeCharacter('X');
  Assert.IsTrue(FViewer.MarkdownText.Contains(sLineBreak + sLineBreak + '# Xsecond'),
    FViewer.MarkdownText);

  FViewer.PressKey(VK_UP);
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

  // Down lands on the empty line first, then on the second heading. The first
  // backspace removes the blank line (and the heading marker); the second joins
  // the now-adjacent blocks.
  FViewer.PressKey(VK_DOWN);
  FViewer.PressKey(VK_DOWN);
  FViewer.PressKey(VK_BACK);
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

  // Each Right press crosses one CRLF pair without stopping between the CR and
  // LF; the empty line between the headings is one such stop along the way.
  FViewer.PressKey(VK_END);
  FViewer.PressKey(VK_RIGHT);
  FViewer.PressKey(VK_RIGHT);
  FViewer.TypeCharacter('X');

  Assert.IsTrue(FViewer.MarkdownText.Contains('# Xbravo'),
    FViewer.MarkdownText);
end;

procedure TMarkDownViewerTests.DirectEditingEnterRestsCaretOnBlankLine;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'Hello';
  RepaintViewer;

  // Press Enter at the end of the line, then type: the caret must rest on the
  // newly created blank line so the text lands on its own line, not be pushed
  // onto the following non-blank line.
  FViewer.PressKey(VK_END);
  FViewer.TypeCharacter(#13);
  FViewer.TypeCharacter('X');

  Assert.IsTrue(FViewer.MarkdownText.Contains('Hello' + sLineBreak + 'X'),
    FViewer.MarkdownText);
end;

procedure TMarkDownViewerTests.DirectEditingCaretCanRestBetweenParagraphs;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'one' + sLineBreak + sLineBreak + 'two';
  RepaintViewer;

  // Down from the first paragraph lands on the empty separating line, and
  // typing there keeps it a distinct blank-line edit between the paragraphs.
  FViewer.PressKey(VK_DOWN);
  FViewer.TypeCharacter('M');

  Assert.IsTrue(FViewer.MarkdownText.Contains(
    'one' + sLineBreak + 'M' + sLineBreak + 'two'), FViewer.MarkdownText);
end;

procedure TMarkDownViewerTests.TabConvertsParagraphToHeading;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'Hello';
  RepaintViewer;

  FViewer.PressKey(VK_TAB);

  Assert.AreEqual('# Hello', Trim(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.TabIncreasesHeadingLevel;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '# Hello';
  RepaintViewer;

  FViewer.PressKey(VK_TAB);

  Assert.AreEqual('## Hello', Trim(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.ShiftTabDecreasesHeadingLevel;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '## Hello';
  RepaintViewer;

  FViewer.PressKey(VK_TAB, [ssShift]);

  Assert.AreEqual('# Hello', Trim(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.ShiftTabOnH1StripsToParagraph;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '# Hello';
  RepaintViewer;

  FViewer.PressKey(VK_TAB, [ssShift]);

  Assert.AreEqual('Hello', Trim(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.TabDemotesSetextHeading;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'Title' + sLineBreak + '===';
  RepaintViewer;

  FViewer.PressKey(VK_TAB);

  Assert.IsTrue(FViewer.MarkdownText.Contains('Title'), FViewer.MarkdownText);
  Assert.IsTrue(FViewer.MarkdownText.Contains('---'), FViewer.MarkdownText);
  Assert.IsFalse(FViewer.MarkdownText.Contains('==='), FViewer.MarkdownText);
end;

procedure TMarkDownViewerTests.TabOnHeadingPreservesCaretColumn;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '# Hello';
  RepaintViewer;

  // Caret at end of the rendered "Hello"; after the level change it should keep
  // its place in the text (shifted past the extra '#'), not jump.
  FViewer.PressKey(VK_END);
  FViewer.PressKey(VK_TAB);
  FViewer.TypeCharacter('X');

  Assert.AreEqual('## HelloX', Trim(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.TabIndentsBulletListItem;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '- Hello';
  RepaintViewer;

  FViewer.PressKey(VK_TAB);

  Assert.AreEqual('  - Hello', TrimRight(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.ShiftTabOutdentsBulletListItem;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '  - Hello';
  RepaintViewer;

  FViewer.PressKey(VK_TAB, [ssShift]);

  Assert.AreEqual('- Hello', TrimRight(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.TabIndentsChecklistItem;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '- [x] task';
  RepaintViewer;

  FViewer.PressKey(VK_TAB);

  Assert.AreEqual('  - [x] task', TrimRight(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.CtrlKInsertsLink;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'Hello';
  FViewer.ReadOnly := False;
  RepaintViewer;

  FViewer.PressKey(VK_END);
  FViewer.PressKey(Ord('K'), [ssCtrl]);

  Assert.AreEqual('Hello[]()', TrimRight(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.CtrlKWrapsSelectionInLink;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'Hello';
  FViewer.ReadOnly := False;
  RepaintViewer;

  // Select "Hello"
  FViewer.PressKey(VK_HOME);
  FViewer.PressKey(VK_END, [ssShift]);
  FViewer.PressKey(Ord('K'), [ssCtrl]);

  Assert.AreEqual('[Hello]()', TrimRight(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.CtrlSpaceTogglesCheckbox;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '- [ ] task';
  FViewer.ReadOnly := False;
  FViewer.AllowTaskToggle := True;
  RepaintViewer;

  FViewer.PressKey(VK_HOME);
  FViewer.PressKey(VK_SPACE, [ssCtrl]);

  Assert.AreEqual('- [x] task', TrimRight(FViewer.MarkdownText));

  // Toggle it back
  FViewer.PressKey(VK_SPACE, [ssCtrl]);
  Assert.AreEqual('- [ ] task', TrimRight(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.Ctrl1To6SetsHeadingLevel;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'Hello';
  FViewer.ReadOnly := False;
  RepaintViewer;

  FViewer.PressKey(VK_HOME);
  // Set to heading 1
  FViewer.PressKey(Ord('1'), [ssCtrl]);
  Assert.AreEqual('# Hello', TrimRight(FViewer.MarkdownText));

  // Set to heading 3
  FViewer.PressKey(Ord('3'), [ssCtrl]);
  Assert.AreEqual('### Hello', TrimRight(FViewer.MarkdownText));

  // Set to heading 6
  FViewer.PressKey(Ord('6'), [ssCtrl]);
  Assert.AreEqual('###### Hello', TrimRight(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.Ctrl0StripsHeading;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '### Hello';
  FViewer.ReadOnly := False;
  RepaintViewer;

  FViewer.PressKey(VK_HOME);
  FViewer.PressKey(Ord('0'), [ssCtrl]);
  Assert.AreEqual('Hello', TrimRight(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.AltUpDownMovesLine;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'Line 1' + sLineBreak + 'Line 2';
  FViewer.ReadOnly := False;
  RepaintViewer;

  // Caret on Line 1. Alt+Down moves it to the bottom.
  FViewer.PressKey(VK_HOME);
  FViewer.PressKey(VK_DOWN, [ssAlt]);
  Assert.AreEqual('Line 2' + sLineBreak + 'Line 1', TrimRight(FViewer.MarkdownText));

  // Alt+Up moves it back to the top.
  FViewer.PressKey(VK_UP, [ssAlt]);
  Assert.AreEqual('Line 1' + sLineBreak + 'Line 2', TrimRight(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.AltUpDownPreservesCaretOffset;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'Line 1' + sLineBreak + 'Line 2';
  FViewer.ReadOnly := False;
  RepaintViewer;

  // Move caret after 'n' in 'Line 1' (offset 3)
  FViewer.PressKey(VK_RIGHT);
  FViewer.PressKey(VK_RIGHT);
  FViewer.PressKey(VK_RIGHT);
  
  FViewer.PressKey(VK_DOWN, [ssAlt]);
  Assert.AreEqual('Line 2' + sLineBreak + 'Line 1', TrimRight(FViewer.MarkdownText));
  
  // Type X. Since the caret offset should be preserved, it should result in 'LinXe 1'
  FViewer.TypeCharacter('X');
  Assert.AreEqual('Line 2' + sLineBreak + 'LinXe 1', TrimRight(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.CtrlTAndCtrlHFormatting;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'Hello';
  FViewer.ReadOnly := False;
  RepaintViewer;

  // Select "Hello" and toggle strikethrough (Ctrl+T)
  FViewer.PressKey(VK_HOME);
  FViewer.PressKey(VK_END, [ssShift]);
  FViewer.PressKey(Ord('T'), [ssCtrl]);
  Assert.AreEqual('~~Hello~~', TrimRight(FViewer.MarkdownText));

  // Toggle strikethrough off (Ctrl+T)
  FViewer.PressKey(Ord('T'), [ssCtrl]);
  Assert.AreEqual('Hello', TrimRight(FViewer.MarkdownText));

  // Select "Hello" and toggle highlight (Ctrl+H)
  FViewer.PressKey(VK_HOME);
  FViewer.PressKey(VK_END, [ssShift]);
  FViewer.PressKey(Ord('H'), [ssCtrl]);
  Assert.AreEqual('==Hello==', TrimRight(FViewer.MarkdownText));

  // Toggle highlight off (Ctrl+H)
  FViewer.PressKey(Ord('H'), [ssCtrl]);
  Assert.AreEqual('Hello', TrimRight(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.AutoPairsOpeningBracketsAndQuotes;
begin
  ShowViewer(400, 300);
  FViewer.ReadOnly := False;

  // Test '(' -> '()'
  FViewer.MarkdownText := '';
  RepaintViewer;
  FViewer.TypeCharacter('(');
  Assert.AreEqual('()', TrimRight(FViewer.MarkdownText));

  // Test '[' -> '[]'
  FViewer.MarkdownText := '';
  RepaintViewer;
  FViewer.TypeCharacter('[');
  Assert.AreEqual('[]', TrimRight(FViewer.MarkdownText));

  // Test '{' -> '{}'
  FViewer.MarkdownText := '';
  RepaintViewer;
  FViewer.TypeCharacter('{');
  Assert.AreEqual('{}', TrimRight(FViewer.MarkdownText));

  // Test '"' -> '""'
  FViewer.MarkdownText := '';
  RepaintViewer;
  FViewer.TypeCharacter('"');
  Assert.AreEqual('""', TrimRight(FViewer.MarkdownText));

  // Test single quote -> ''''
  FViewer.MarkdownText := '';
  RepaintViewer;
  FViewer.TypeCharacter('''');
  Assert.AreEqual('''''', TrimRight(FViewer.MarkdownText));

  // Test backtick -> '``'
  FViewer.MarkdownText := '';
  RepaintViewer;
  FViewer.TypeCharacter('`');
  Assert.AreEqual('``', TrimRight(FViewer.MarkdownText));

  // Test selection wrapping with single quotes
  FViewer.MarkdownText := 'hello';
  RepaintViewer;
  FViewer.PressKey(Ord('A'), [ssCtrl]);
  FViewer.TypeCharacter('''');
  Assert.AreEqual('''hello''', TrimRight(FViewer.MarkdownText));

  // Test selection wrapping with backticks
  FViewer.MarkdownText := 'hello';
  RepaintViewer;
  FViewer.PressKey(Ord('A'), [ssCtrl]);
  FViewer.TypeCharacter('`');
  Assert.AreEqual('`hello`', TrimRight(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.PreventsAutoPairingQuotesAfterWordChars;
begin
  ShowViewer(400, 300);
  FViewer.ReadOnly := False;

  // Type a word char 'a', then type single quote ''''
  FViewer.MarkdownText := '';
  RepaintViewer;
  FViewer.TypeCharacter('a');
  FViewer.TypeCharacter('''');
  Assert.AreEqual('a''', TrimRight(FViewer.MarkdownText));

  // Type a word char 'x', then type double quote '"'
  FViewer.MarkdownText := '';
  RepaintViewer;
  FViewer.TypeCharacter('x');
  FViewer.TypeCharacter('"');
  Assert.AreEqual('x"', TrimRight(FViewer.MarkdownText));

  // Non-word char like '-' should still auto-pair single quote
  FViewer.MarkdownText := '';
  RepaintViewer;
  FViewer.TypeCharacter('-');
  FViewer.TypeCharacter('''');
  Assert.AreEqual('-''''', TrimRight(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.StepsOverClosingBracketsAndQuotes;
begin
  ShowViewer(400, 300);
  FViewer.ReadOnly := False;

  // Type '(' -> inserts '()', caret is in between.
  // Then type ')' -> should step over ')' rather than inserting another.
  FViewer.MarkdownText := '';
  RepaintViewer;
  FViewer.TypeCharacter('(');
  FViewer.TypeCharacter(')');
  Assert.AreEqual('()', TrimRight(FViewer.MarkdownText));

  // Type '[' then ']'
  FViewer.MarkdownText := '';
  RepaintViewer;
  FViewer.TypeCharacter('[');
  FViewer.TypeCharacter(']');
  Assert.AreEqual('[]', TrimRight(FViewer.MarkdownText));

  // Type '{' then '}'
  FViewer.MarkdownText := '';
  RepaintViewer;
  FViewer.TypeCharacter('{');
  FViewer.TypeCharacter('}');
  Assert.AreEqual('{}', TrimRight(FViewer.MarkdownText));

  // Type '"' then '"'
  FViewer.MarkdownText := '';
  RepaintViewer;
  FViewer.TypeCharacter('"');
  FViewer.TypeCharacter('"');
  Assert.AreEqual('""', TrimRight(FViewer.MarkdownText));

  // Type '''' then ''''
  FViewer.MarkdownText := '';
  RepaintViewer;
  FViewer.TypeCharacter('''');
  FViewer.TypeCharacter('''');
  Assert.AreEqual('''''', TrimRight(FViewer.MarkdownText));

  // Type '`' then '`'
  FViewer.MarkdownText := '';
  RepaintViewer;
  FViewer.TypeCharacter('`');
  FViewer.TypeCharacter('`');
  Assert.AreEqual('``', TrimRight(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.BackspaceDeletesBracketAndQuotePairs;
begin
  ShowViewer(400, 300);
  FViewer.ReadOnly := False;

  // Type '(' -> inserts '()', caret is in between. Press Backspace -> deletes both.
  FViewer.MarkdownText := '';
  RepaintViewer;
  FViewer.TypeCharacter('(');
  FViewer.PressKey(VK_BACK);
  Assert.AreEqual('', TrimRight(FViewer.MarkdownText));

  // Type '[' then Backspace
  FViewer.MarkdownText := '';
  RepaintViewer;
  FViewer.TypeCharacter('[');
  FViewer.PressKey(VK_BACK);
  Assert.AreEqual('', TrimRight(FViewer.MarkdownText));

  // Type '{' then Backspace
  FViewer.MarkdownText := '';
  RepaintViewer;
  FViewer.TypeCharacter('{');
  FViewer.PressKey(VK_BACK);
  Assert.AreEqual('', TrimRight(FViewer.MarkdownText));

  // Type '"' then Backspace
  FViewer.MarkdownText := '';
  RepaintViewer;
  FViewer.TypeCharacter('"');
  FViewer.PressKey(VK_BACK);
  Assert.AreEqual('', TrimRight(FViewer.MarkdownText));

  // Type '''' then Backspace
  FViewer.MarkdownText := '';
  RepaintViewer;
  FViewer.TypeCharacter('''');
  FViewer.PressKey(VK_BACK);
  Assert.AreEqual('', TrimRight(FViewer.MarkdownText));

  // Type '`' then Backspace
  FViewer.MarkdownText := '';
  RepaintViewer;
  FViewer.TypeCharacter('`');
  FViewer.PressKey(VK_BACK);
  Assert.AreEqual('', TrimRight(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.ReadOnlyArrowKeysScroll;
var
  I: Integer;
  Source: TStringList;
begin
  ShowViewer(300, 80);
  FViewer.ReadOnly := True;
  Source := TStringList.Create;
  try
    for I := 1 to 60 do
      Source.Add('Line ' + I.ToString);
    FViewer.Markdown.Assign(Source);
  finally
    Source.Free;
  end;
  RepaintViewer;

  Assert.AreEqual(0, FViewer.ScrollPosition);
  FViewer.PressKey(VK_NEXT);
  Assert.IsTrue(FViewer.ScrollPosition > 0, 'page down should scroll');
  FViewer.PressKey(VK_PRIOR);
  Assert.AreEqual(0, FViewer.ScrollPosition);
  FViewer.PressKey(VK_END);
  Assert.IsTrue(FViewer.ScrollPosition > 0, 'end should scroll to bottom');
  FViewer.PressKey(VK_HOME);
  Assert.AreEqual(0, FViewer.ScrollPosition);
end;

procedure TMarkDownViewerTests.RendersQuoteBlockWithDefaultColors;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '> quoted text';
  RepaintViewer;

  // Rendering the quote exercises the quote-bar colour path; the rendered text
  // round-trips through selection.
  FViewer.SelectAll;
  Assert.IsTrue(FViewer.SelectedText.Contains('quoted text'),
    FViewer.SelectedText);
end;

procedure TMarkDownViewerTests.SearchTextHighlightsMatchesOnPaint;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'find the word find here';
  FViewer.SearchText := 'find';
  RepaintViewer;

  Assert.AreEqual(2, FViewer.SearchMatchCount);
end;

procedure TMarkDownViewerTests.CtrlASelectsAllText;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'alpha bravo';
  RepaintViewer;

  FViewer.PressKey(Ord('A'), [ssCtrl]);

  Assert.AreEqual('alpha bravo', Trim(FViewer.SelectedText));
end;

procedure TMarkDownViewerTests.CtrlZUndoesAndCtrlYRedoes;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'abc';
  RepaintViewer;

  FViewer.TypeCharacter('X');
  Assert.AreEqual('Xabc', Trim(FViewer.MarkdownText));

  FViewer.PressKey(Ord('Z'), [ssCtrl]);
  Assert.AreEqual('abc', Trim(FViewer.MarkdownText));

  FViewer.PressKey(Ord('Y'), [ssCtrl]);
  Assert.AreEqual('Xabc', Trim(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.DeleteKeyRemovesSelection;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'alpha bravo';
  RepaintViewer;

  FViewer.PressKey(Ord('A'), [ssCtrl]);
  FViewer.PressKey(VK_DELETE);

  Assert.AreEqual('', Trim(FViewer.MarkdownText));
  Assert.AreEqual('', FViewer.SelectedText);
end;

procedure TMarkDownViewerTests.CtrlBWrapsSelectionInBold;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'hello world';
  RepaintViewer;

  FViewer.PressKey(Ord('A'), [ssCtrl]);
  FViewer.PressKey(Ord('B'), [ssCtrl]);

  Assert.AreEqual('**hello world**', Trim(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.CtrlBTogglesBoldOff;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'hello world';
  RepaintViewer;

  FViewer.PressKey(Ord('A'), [ssCtrl]);
  FViewer.PressKey(Ord('B'), [ssCtrl]);
  Assert.AreEqual('**hello world**', Trim(FViewer.MarkdownText));

  // The selection stays over the formatted text, so a second press toggles off.
  FViewer.PressKey(Ord('B'), [ssCtrl]);
  Assert.AreEqual('hello world', Trim(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.CtrlIWrapsSelectionInItalic;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'hello';
  RepaintViewer;

  FViewer.PressKey(Ord('A'), [ssCtrl]);
  FViewer.PressKey(Ord('I'), [ssCtrl]);

  Assert.AreEqual('*hello*', Trim(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.CtrlEWrapsSelectionInCode;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'run it';
  RepaintViewer;

  FViewer.PressKey(Ord('A'), [ssCtrl]);
  FViewer.PressKey(Ord('E'), [ssCtrl]);

  Assert.AreEqual('`run it`', Trim(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.CtrlBBoldsPartialSelection;
var
  I: Integer;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'alpha bravo charlie';
  RepaintViewer;

  // Place the caret before "bravo" (offset 6) and select the five letters.
  for I := 1 to 6 do
    FViewer.PressKey(VK_RIGHT);
  for I := 1 to 5 do
    FViewer.PressKey(VK_RIGHT, [ssShift]);
  FViewer.PressKey(Ord('B'), [ssCtrl]);

  Assert.AreEqual('alpha **bravo** charlie', Trim(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.CtrlRightMovesByWord;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'alpha bravo charlie';
  RepaintViewer;

  // From the start, Ctrl+Right then type marks the start of the second word.
  FViewer.PressKey(VK_RIGHT, [ssCtrl]);
  FViewer.TypeCharacter('-');

  Assert.AreEqual('alpha -bravo charlie', Trim(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.CtrlBackspaceDeletesWord;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'alpha bravo charlie';
  RepaintViewer;

  FViewer.PressKey(VK_END);
  FViewer.PressKey(VK_BACK, [ssCtrl]);

  Assert.AreEqual('alpha bravo', Trim(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.CtrlDeleteDeletesWordForward;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'alpha bravo charlie';
  RepaintViewer;

  // Caret at start; Ctrl+Delete removes the first word (and the space).
  FViewer.PressKey(VK_DELETE, [ssCtrl]);

  Assert.AreEqual('bravo charlie', Trim(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.TypingBracketWrapsSelection;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'hello world';
  RepaintViewer;

  FViewer.PressKey(Ord('A'), [ssCtrl]);
  FViewer.TypeCharacter('(');

  Assert.AreEqual('(hello world)', Trim(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.TypingCharWithoutSelectionInsertsLiterally;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'ab';
  RepaintViewer;

  // With auto-pairing, typing an opener without selection inserts the pair.
  FViewer.TypeCharacter('(');

  Assert.AreEqual('()ab', Trim(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.ToggleStrikethroughWrapsSelection;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'gone';
  RepaintViewer;

  FViewer.PressKey(Ord('A'), [ssCtrl]);
  FViewer.ToggleStrikethrough;

  Assert.AreEqual('~~gone~~', Trim(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.ToggleBoldMethodMatchesShortcut;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'word';
  RepaintViewer;

  FViewer.PressKey(Ord('A'), [ssCtrl]);
  FViewer.ToggleBold;

  Assert.AreEqual('**word**', Trim(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.SelectWordAtCaretSelectsWord;
var
  I: Integer;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'alpha bravo charlie';
  RepaintViewer;

  // Move the caret into the middle word, then select it.
  for I := 1 to 8 do
    FViewer.PressKey(VK_RIGHT);
  FViewer.SelectWordAtCaret;

  Assert.AreEqual('bravo', FViewer.SelectedText);
end;

procedure TMarkDownViewerTests.DoubleClickSelectsWord;
var
  I: Integer;
  Run: TMarkDownTextRun;
  X, Y: Integer;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := 'alpha bravo charlie';
  RepaintViewer;

  // Move caret into 'bravo' (index 8)
  for I := 1 to 8 do
    FViewer.PressKey(VK_RIGHT);

  Run := FViewer.GetRunContainingCaret;
  X := Run.Rect.Left + FViewer.Canvas.TextWidth(Copy(Run.Text, 1, 8 - Run.StartIndex)) - 4;
  Y := Run.Rect.Top + (Run.Rect.Bottom - Run.Rect.Top) div 2;

  FViewer.DoubleClickMouse(X, Y);

  Assert.AreEqual('bravo', FViewer.SelectedText);
end;

procedure TMarkDownViewerTests.EnterContinuesBulletList;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '- one';
  RepaintViewer;

  FViewer.PressKey(VK_END);
  FViewer.TypeCharacter(#13);
  FViewer.TypeCharacter('t');
  FViewer.TypeCharacter('w');
  FViewer.TypeCharacter('o');

  Assert.AreEqual(
    '''
    - one
    - two
    ''', Trim(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.EnterIncrementsOrderedList;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '1. first';
  RepaintViewer;

  FViewer.PressKey(VK_END);
  FViewer.TypeCharacter(#13);
  FViewer.TypeCharacter('x');

  Assert.AreEqual(
    '''
    1. first
    2. x
    ''', Trim(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.EnterContinuesTaskAsUnchecked;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '- [x] done';
  RepaintViewer;

  FViewer.PressKey(VK_END);
  FViewer.TypeCharacter(#13);
  FViewer.TypeCharacter('y');

  Assert.AreEqual(
    '''
    - [x] done
    - [ ] y
    ''', Trim(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.EnterOnEmptyItemExitsList;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText := '- ';
  RepaintViewer;

  FViewer.PressKey(VK_END);
  FViewer.TypeCharacter(#13);

  Assert.AreEqual('', Trim(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.EnterInMiddleOfListInsertsItem;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText :=
    '''
    - one
    - three
    ''';
  RepaintViewer;

  // Caret at end of "one" (first item), Enter then type makes a middle item.
  FViewer.PressKey(VK_END);
  FViewer.TypeCharacter(#13);
  FViewer.TypeCharacter('t');
  FViewer.TypeCharacter('w');
  FViewer.TypeCharacter('o');

  Assert.AreEqual(
    '''
    - one
    - two
    - three
    ''', Trim(FViewer.MarkdownText));
end;

procedure TMarkDownViewerTests.CodeBlockWithoutHighlightingRendersWithoutException;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText :=
    '''
    ```
    plain code line
    ```
    ''';
  RepaintViewer;

  FViewer.SelectAll;
  Assert.IsTrue(FViewer.SelectedText.Contains('plain code line'));
end;

procedure TMarkDownViewerTests.CodeBlockWithHighlightingRendersWithoutException;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText :=
    '''
    ```pascal
    begin
      WriteLn('Hello');
    end.
    ```
    ''';
  RepaintViewer;

  FViewer.SelectAll;
  Assert.IsTrue(FViewer.SelectedText.Contains('WriteLn'));
end;

procedure TMarkDownViewerTests.HoverOverCodeBlockShowsCopyButton;
var
  R: TRect;
  BtnRect: TRect;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText :=
    '''
    ```
    test code
    ```
    ''';
  RepaintViewer;
 
  Assert.AreEqual(1, FViewer.GetCodeBlockCount);
  R := FViewer.GetCodeBlockRect(0);
  Assert.AreNotEqual(0, R.Width);
 
  // Hover outside copy button but inside code block
  FViewer.MouseMove([], R.Left + 5, R.Top + 5);
  Assert.IsFalse(FViewer.IsCopyButtonHovered);
 
  // Hover over copy button
  BtnRect := FViewer.GetCodeBlockCopyBtnRect(0);
  Assert.AreNotEqual(0, BtnRect.Width);
  
  FViewer.MouseMove([], BtnRect.Left + BtnRect.Width div 2, BtnRect.Top + BtnRect.Height div 2);
  Assert.IsTrue(FViewer.IsCopyButtonHovered);
  Assert.AreEqual(Integer(crHandPoint), Integer(FViewer.Cursor));
end;
 
procedure TMarkDownViewerTests.ClickingCopyButtonCopiesToClipboard;
var
  BtnRect: TRect;
begin
  ShowViewer(400, 300);
  FViewer.MarkdownText :=
    '''
    ```
    my secret code
    ```
    ''';
  RepaintViewer;
 
  BtnRect := FViewer.GetCodeBlockCopyBtnRect(0);
  FViewer.MouseMove([], BtnRect.Left + BtnRect.Width div 2, BtnRect.Top + BtnRect.Height div 2);
  
  // Clear clipboard
  Clipboard.AsText := '';
  
  // Click copy button
  FViewer.ClickMouse(BtnRect.Left + BtnRect.Width div 2, BtnRect.Top + BtnRect.Height div 2);
  
  Assert.AreEqual('my secret code', Clipboard.AsText);
end;

initialization
  TDUnitX.RegisterTestFixture(TMarkDownViewerTests);

end.
