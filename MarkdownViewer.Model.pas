unit MarkdownViewer.Model;

interface

uses
  System.Generics.Collections,
  System.Types,
  Vcl.Graphics;

type
  TMarkDownBlockKind = (bkParagraph, bkHeading, bkQuote, bkListItem,
    bkCodeBlock, bkRule, bkTable, bkImage);

  TMarkDownInlineKind = (ikText, ikBold, ikItalic, ikBoldItalic, ikCode,
    ikLink, ikStrike);

  TMarkDownInlineToken = record
    Kind: TMarkDownInlineKind;
    Text: string;
    Url: string;
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

  TMarkDownBlockList = TObjectList<TMarkDownBlock>;
  TMarkDownLinkHitList = TList<TMarkDownLinkHit>;

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
