unit MarkdownViewer.Renderer;

interface

uses
  Vcl.Graphics;

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

implementation

uses
  System.Math,
  Winapi.Windows;

function CenterMarkerLeft(ColumnLeft, ColumnWidth, MarkerWidth: Integer): Integer;
begin
  Result := ColumnLeft + Max(0, (ColumnWidth - MarkerWidth) div 2);
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
