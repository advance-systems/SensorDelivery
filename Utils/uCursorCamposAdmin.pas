unit uCursorCamposAdmin;

interface

uses
  System.Classes, FMX.Types, FMX.Edit, FMX.Memo;

type
  TCursorCamposAdmin = class(TComponent)
  private
    procedure ConfigurarControle(const AObjeto: TFmxObject);
    procedure AplicarEstilo(Sender: TObject);
    procedure CampoEntrou(Sender: TObject);
  public
    class procedure Aplicar(const AOwner: TComponent;
      const ARaiz: TFmxObject); static;
  end;

implementation

class procedure TCursorCamposAdmin.Aplicar(const AOwner: TComponent;
  const ARaiz: TFmxObject);
var
  LConfigurador: TCursorCamposAdmin;
begin
  LConfigurador := TCursorCamposAdmin.Create(AOwner);
  LConfigurador.ConfigurarControle(ARaiz);
end;

procedure TCursorCamposAdmin.ConfigurarControle(const AObjeto: TFmxObject);
var
  I: Integer;
begin
  if AObjeto is TEdit then
  begin
    TEdit(AObjeto).ApplyStyleLookup;
    AplicarEstilo(AObjeto);
  end
  else if AObjeto is TMemo then
  begin
    TMemo(AObjeto).ApplyStyleLookup;
    AplicarEstilo(AObjeto);
  end;

  for I := 0 to AObjeto.ChildrenCount - 1 do
    ConfigurarControle(AObjeto.Children[I]);
end;

procedure TCursorCamposAdmin.AplicarEstilo(Sender: TObject);
begin
  if Sender is TEdit then
  begin
    TEdit(Sender).Caret.BeginUpdate;
    try
      TEdit(Sender).Caret.DefaultColor := $FFFFFFFF;
      TEdit(Sender).Caret.Color := $FFFFFFFF;
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
      TMemo(Sender).Caret.DefaultColor := $FFFFFFFF;
      TMemo(Sender).Caret.Color := $FFFFFFFF;
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

procedure TCursorCamposAdmin.CampoEntrou(Sender: TObject);
begin
  AplicarEstilo(Sender);
end;

end.
