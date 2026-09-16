unit uCursorCamposMobile;

interface

uses
  System.Classes, FMX.Types, FMX.Edit, FMX.Memo;

type
  TCursorCamposMobile = class(TComponent)
  private
    procedure ConfigurarControle(const AObjeto: TFmxObject);
    procedure AplicarEstilo(Sender: TObject);
    procedure CampoEntrou(Sender: TObject);
  public
    class procedure Aplicar(const AOwner: TComponent;
      const ARaiz: TFmxObject); static;
  end;

implementation

class procedure TCursorCamposMobile.Aplicar(const AOwner: TComponent;
  const ARaiz: TFmxObject);
var
  LConfigurador: TCursorCamposMobile;
begin
  LConfigurador := TCursorCamposMobile.Create(AOwner);
  LConfigurador.ConfigurarControle(ARaiz);
end;

procedure TCursorCamposMobile.ConfigurarControle(const AObjeto: TFmxObject);
var
  I: Integer;
begin
  if AObjeto is TEdit then
  begin
    TEdit(AObjeto).OnApplyStyleLookup := AplicarEstilo;
    TEdit(AObjeto).OnEnter := CampoEntrou;
  end
  else if AObjeto is TMemo then
  begin
    TMemo(AObjeto).OnApplyStyleLookup := AplicarEstilo;
    TMemo(AObjeto).OnEnter := CampoEntrou;
  end;

  for I := 0 to AObjeto.ChildrenCount - 1 do
    ConfigurarControle(AObjeto.Children[I]);
end;

procedure TCursorCamposMobile.AplicarEstilo(Sender: TObject);
begin
  if Sender is TEdit then
  begin
    TEdit(Sender).Caret.BeginUpdate;
    try
      TEdit(Sender).Caret.DefaultColor := $FFFF4B0A;
      TEdit(Sender).Caret.Color := $FFFF4B0A;
      TEdit(Sender).Caret.Width := 2;
      TEdit(Sender).Caret.Interval := 500;
      TEdit(Sender).Caret.Visible := True;
    finally
      TEdit(Sender).Caret.EndUpdate;
    end;
    if TEdit(Sender).IsFocused then
      TEdit(Sender).Caret.Show;
  end
  else if Sender is TMemo then
  begin
    TMemo(Sender).Caret.BeginUpdate;
    try
      TMemo(Sender).Caret.DefaultColor := $FFFF4B0A;
      TMemo(Sender).Caret.Color := $FFFF4B0A;
      TMemo(Sender).Caret.Width := 2;
      TMemo(Sender).Caret.Interval := 500;
      TMemo(Sender).Caret.Visible := True;
    finally
      TMemo(Sender).Caret.EndUpdate;
    end;
    if TMemo(Sender).IsFocused then
      TMemo(Sender).Caret.Show;
  end;
end;

procedure TCursorCamposMobile.CampoEntrou(Sender: TObject);
begin
  AplicarEstilo(Sender);
end;

end.
