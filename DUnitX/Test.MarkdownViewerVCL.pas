unit Test.MarkdownViewerVCL;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TMarkDownViewerTests = class
  private
    FChangeCount: Integer;
    procedure HandleViewerChange(Sender: TObject);
  public
    [Test]
    procedure UsesReadableDefaultFont;
    [Test]
    procedure AppendsMarkdownWithoutReplacingExistingText;
    [Test]
    procedure AppendFiresOnChange;
    [Test]
    procedure TypingPreservesScrollPosition;
    [Test]
    procedure ReadOnlyIsEnabledByDefault;
    [Test]
    procedure DirectEditingInsertsTextAndSupportsUndo;
    [Test]
    procedure DirectEditingMovesCaretVertically;
    [Test]
    procedure DirectEditingSupportsHomeAndEnd;
    [Test]
    procedure DirectEditingSupportsPageNavigation;
    [Test]
    procedure DirectEditingSupportsControlHomeAndEnd;
  end;

implementation

uses
  System.Classes,
  System.SysUtils,
  Winapi.Windows,
  Vcl.Forms,
  MarkdownViewerVCL;

type
  TTestMarkDownViewer = class(TMarkDownViewer)
  public
    procedure PressKey(Value: Word; Shift: TShiftState = []);
    procedure TypeCharacter(Value: Char);
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

procedure TMarkDownViewerTests.DirectEditingMovesCaretVertically;
var
  Form: TForm;
  Viewer: TTestMarkDownViewer;
begin
  Form := TForm.Create(nil);
  try
    Viewer := TTestMarkDownViewer.Create(Form);
    Viewer.Parent := Form;
    Viewer.SetBounds(0, 0, 400, 300);
    Viewer.ReadOnly := False;
    Viewer.MarkdownText := '# first' + sLineBreak + sLineBreak + '# second';
    Form.Show;
    Application.ProcessMessages;
    Viewer.Repaint;

    Viewer.PressKey(VK_DOWN);
    Viewer.TypeCharacter('X');
    Assert.IsTrue(Viewer.MarkdownText.Contains(sLineBreak + sLineBreak + '# Xsecond'),
      Viewer.MarkdownText);

    Viewer.PressKey(VK_UP);
    Viewer.TypeCharacter('Y');
    Assert.IsTrue(Pos('Y', Copy(Viewer.MarkdownText, 1,
      Pos(sLineBreak, Viewer.MarkdownText) - 1)) > 0, Viewer.MarkdownText);
  finally
    Form.Free;
  end;
end;

procedure TMarkDownViewerTests.DirectEditingSupportsControlHomeAndEnd;
var
  Form: TForm;
  Viewer: TTestMarkDownViewer;
begin
  Form := TForm.Create(nil);
  try
    Viewer := TTestMarkDownViewer.Create(Form);
    Viewer.Parent := Form;
    Viewer.SetBounds(0, 0, 400, 300);
    Viewer.ReadOnly := False;
    Viewer.MarkdownText := '# first' + sLineBreak + sLineBreak + '# second';
    Form.Show;
    Application.ProcessMessages;
    Viewer.Repaint;

    Viewer.PressKey(VK_END, [ssCtrl]);
    Viewer.TypeCharacter('X');
    Assert.IsTrue(Viewer.MarkdownText.Contains('# secondX'),
      Viewer.MarkdownText);

    Viewer.PressKey(VK_HOME, [ssCtrl]);
    Viewer.TypeCharacter('Y');
    Assert.IsTrue(Viewer.MarkdownText.StartsWith('# Yfirst'),
      Viewer.MarkdownText);

    Viewer.PressKey(VK_HOME, [ssCtrl]);
    Viewer.PressKey(VK_END, [ssCtrl, ssShift]);
    Viewer.TypeCharacter('Z');
    Assert.IsTrue(Viewer.MarkdownText.StartsWith('# Z'),
      Viewer.MarkdownText);
  finally
    Form.Free;
  end;
end;

procedure TMarkDownViewerTests.DirectEditingSupportsHomeAndEnd;
var
  Form: TForm;
  Viewer: TTestMarkDownViewer;
begin
  Form := TForm.Create(nil);
  try
    Viewer := TTestMarkDownViewer.Create(Form);
    Viewer.Parent := Form;
    Viewer.SetBounds(0, 0, 400, 300);
    Viewer.ReadOnly := False;
    Viewer.MarkdownText := '# first';
    Form.Show;
    Application.ProcessMessages;
    Viewer.Repaint;

    Viewer.PressKey(VK_END);
    Viewer.TypeCharacter('X');
    Assert.IsTrue(Viewer.MarkdownText.StartsWith('# firstX'),
      Viewer.MarkdownText);

    Viewer.PressKey(VK_HOME);
    Viewer.TypeCharacter('Y');
    Assert.IsTrue(Viewer.MarkdownText.StartsWith('# YfirstX'),
      Viewer.MarkdownText);
  finally
    Form.Free;
  end;
end;

procedure TMarkDownViewerTests.DirectEditingSupportsPageNavigation;
var
  Form: TForm;
  I: Integer;
  Source: TStringList;
  Viewer: TTestMarkDownViewer;
begin
  Form := TForm.Create(nil);
  Source := TStringList.Create;
  try
    for I := 1 to 20 do
    begin
      Source.Add('# Heading ' + I.ToString);
      Source.Add('');
    end;

    Viewer := TTestMarkDownViewer.Create(Form);
    Viewer.Parent := Form;
    Viewer.SetBounds(0, 0, 400, 120);
    Viewer.ReadOnly := False;
    Viewer.Markdown.Assign(Source);
    Form.Show;
    Application.ProcessMessages;
    Viewer.Repaint;

    Viewer.PressKey(VK_NEXT);
    Assert.IsTrue(Viewer.ScrollPosition > 0);
    Viewer.PressKey(VK_PRIOR);
    Assert.AreEqual(0, Viewer.ScrollPosition);
  finally
    Source.Free;
    Form.Free;
  end;
end;

procedure TMarkDownViewerTests.UsesReadableDefaultFont;
var
  Viewer: TMarkDownViewer;
begin
  Viewer := TMarkDownViewer.Create(nil);
  try
    Assert.AreEqual(10, Viewer.Font.Size);
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

procedure TMarkDownViewerTests.DirectEditingInsertsTextAndSupportsUndo;
var
  Form: TForm;
  Viewer: TTestMarkDownViewer;
begin
  Form := TForm.Create(nil);
  try
    Viewer := TTestMarkDownViewer.Create(Form);
    Viewer.Parent := Form;
    Viewer.SetBounds(0, 0, 400, 300);
    Viewer.ReadOnly := False;
    Viewer.MarkdownText := '# Heading';
    Viewer.Repaint;

    Viewer.TypeCharacter('X');
    Assert.IsTrue(Viewer.MarkdownText.StartsWith('X# Heading'));

    Viewer.Undo;
    Assert.IsTrue(Viewer.MarkdownText.StartsWith('# Heading'));
  finally
    Form.Free;
  end;
end;

procedure TMarkDownViewerTests.HandleViewerChange(Sender: TObject);
begin
  Inc(FChangeCount);
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

procedure TMarkDownViewerTests.TypingPreservesScrollPosition;
var
  Form: TForm;
  I: Integer;
  SavedScrollPos: Integer;
  Source: TStringList;
  Viewer: TTestMarkDownViewer;
begin
  Form := TForm.Create(nil);
  Source := TStringList.Create;
  try
    for I := 1 to 20 do
    begin
      Source.Add('# Heading ' + I.ToString);
      Source.Add('');
    end;

    Viewer := TTestMarkDownViewer.Create(Form);
    Viewer.Parent := Form;
    Viewer.SetBounds(0, 0, 400, 120);
    Viewer.ReadOnly := False;
    Viewer.Markdown.Assign(Source);
    Form.Show;
    Application.ProcessMessages;
    Viewer.Repaint;

    Viewer.ScrollPosition := Viewer.MaxScrollPosition div 2;
    SavedScrollPos := Viewer.ScrollPosition;
    Assert.IsTrue(SavedScrollPos > 0, 'expected a scrollable document');

    Viewer.TypeCharacter('X');
    Assert.AreEqual(SavedScrollPos, Viewer.ScrollPosition);
  finally
    Source.Free;
    Form.Free;
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

initialization
  TDUnitX.RegisterTestFixture(TMarkDownViewerTests);

end.
