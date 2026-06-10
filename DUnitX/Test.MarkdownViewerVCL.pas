unit Test.MarkdownViewerVCL;

interface

uses
  DUnitX.TestFramework,
  System.Classes,
  Vcl.Forms,
  MarkdownViewerVCL;

type
  TTestMarkDownViewer = class(TMarkDownViewer)
  public
    procedure PressKey(Value: Word; Shift: TShiftState = []);
    procedure TypeCharacter(Value: Char);
  end;

  [TestFixture]
  TMarkDownViewerTests = class
  private
    FChangeCount: Integer;
    FForm: TForm;
    FViewer: TTestMarkDownViewer;
    procedure HandleViewerChange(Sender: TObject);
    procedure RepaintViewer;
    procedure ShowViewer(AWidth, AHeight: Integer);
  public
    [TearDown]
    procedure TearDown;
    [Test]
    procedure UsesReadableDefaultFont;
    [Test]
    procedure ReadOnlyIsEnabledByDefault;
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
  System.SysUtils,
  Winapi.Windows;

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

procedure TMarkDownViewerTests.HandleViewerChange(Sender: TObject);
begin
  Inc(FChangeCount);
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
