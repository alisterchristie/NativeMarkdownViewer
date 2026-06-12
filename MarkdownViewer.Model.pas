unit MarkdownViewer.Model;

interface

uses
  System.Generics.Collections,
  System.Types,
  Vcl.Graphics;

type
  TMarkDownBlockKind = (bkParagraph, bkHeading, bkQuote, bkListItem,
    bkCodeBlock, bkRule, bkTable, bkImage);

  // An inline run carries combinable emphasis (Style) so spans can nest,
  // e.g. bold containing italic, or a link whose text is bold. IsCode marks a
  // monospace code span, Url (when non-empty) marks the run as part of a link,
  // and LineBreak marks a hard line break (Text is empty for break tokens).
  TMarkDownInlineToken = record
    Text: string;
    Style: TFontStyles;
    IsCode: Boolean;
    Url: string;
    LineBreak: Boolean;
    // Maps each character of Text to its 0-based document offset, with one
    // trailing entry for the position just past the last character (same shape
    // as TMarkDownBlock.SourceMap). Empty when the token was parsed without a
    // block source map, in which case the viewer falls back to its heuristic.
    SourceMap: TArray<Integer>;
  end;

  TMarkDownInlineList = TList<TMarkDownInlineToken>;

  TMarkDownBlock = class
  public
    Kind: TMarkDownBlockKind;
    Text: string;
    Url: string;
    Level: Integer;
    IndentLevel: Integer;
    Ordered: Boolean;
    Number: Integer;
    IsTask: Boolean;
    TaskChecked: Boolean;
    SourceStartLine: Integer;
    // Maps each character of Text back to its 0-based offset in the original
    // document (FMarkdown.Text). SourceMap[i] is the offset of Text[i+1];
    // SourceMap has one extra trailing entry for the position just past the
    // last character. Synthetic characters Text gains during block assembly
    // (the spaces/newlines that join wrapped source lines) map to the line
    // break they stand for. Empty when the block carries no mappable text.
    SourceMap: TArray<Integer>;
    InlineTokens: TMarkDownInlineList;
    LayoutTop: Integer;
    LayoutHeight: Integer;
    LayoutWidth: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  TMarkDownLinkHit = record
    Rect: TRect;
    Url: string;
  end;

  // A clickable task-list checkbox: its on-screen rectangle and the source line
  // that holds the `[ ]`/`[x]` marker to toggle.
  TMarkDownTaskHit = record
    Rect: TRect;
    SourceLine: Integer;
  end;

  TMarkDownBlockList = TObjectList<TMarkDownBlock>;
  TMarkDownLinkHitList = TList<TMarkDownLinkHit>;
  TMarkDownTaskHitList = TList<TMarkDownTaskHit>;

  TMarkDownTextRun = record
    FontName: string;
    FontSize: Integer;
    FontStyle: TFontStyles;
    MarkdownText: string;
    Rect: TRect;
    SourceStartIndex: Integer;
    StartIndex: Integer;
    Text: string;
  end;

  TMarkDownTextRunList = TList<TMarkDownTextRun>;

  TMarkDownCopyChunk = record
    MarkdownText: string;
    SourceStartIndex: Integer;
    StartIndex: Integer;
    Text: string;
  end;

  TMarkDownCopyChunkList = TList<TMarkDownCopyChunk>;

implementation

constructor TMarkDownBlock.Create;
begin
  inherited Create;
  LayoutHeight := -1;
  LayoutWidth := -1;
end;

destructor TMarkDownBlock.Destroy;
begin
  InlineTokens.Free;
  inherited Destroy;
end;

end.
