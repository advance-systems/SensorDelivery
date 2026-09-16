unit uNavegacaoCampos;

interface

uses
  System.Classes, System.UITypes,
  FMX.Types, FMX.Controls;

type
  TNavegacaoCampos = class(TComponent)
  private
    FControles: TArray<TControl>;
    procedure CampoKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure FocarProximo(const Atual: TControl);
    procedure FocarAnterior(const Atual: TControl);
  public
    constructor Create(AOwner: TComponent;
      const AControles: array of TControl); reintroduce;
    class procedure Aplicar(AOwner: TComponent;
      const AControles: array of TControl); static;
  end;

implementation

constructor TNavegacaoCampos.Create(AOwner: TComponent;
  const AControles: array of TControl);
var
  I: Integer;
begin
  inherited Create(AOwner);
  SetLength(FControles, Length(AControles));
  for I := 0 to High(AControles) do
  begin
    FControles[I] := AControles[I];
    if Assigned(FControles[I]) then
      FControles[I].OnKeyDown := CampoKeyDown;
  end;
end;

class procedure TNavegacaoCampos.Aplicar(AOwner: TComponent;
  const AControles: array of TControl);
begin
  TNavegacaoCampos.Create(AOwner, AControles);
end;

procedure TNavegacaoCampos.CampoKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkUp then
  begin
    Key := 0;
    KeyChar := #0;
    if Sender is TControl then
      FocarAnterior(TControl(Sender));
    Exit;
  end;

  if (Key <> vkReturn) and (KeyChar <> #13) then
    Exit;

  Key := 0;
  KeyChar := #0;
  if Sender is TControl then
    FocarProximo(TControl(Sender));
end;

procedure TNavegacaoCampos.FocarAnterior(const Atual: TControl);
var
  I, J: Integer;
begin
  for I := 0 to High(FControles) do
    if FControles[I] = Atual then
    begin
      for J := I - 1 downto 0 do
        if Assigned(FControles[J]) and FControles[J].Visible and
           FControles[J].Enabled and FControles[J].CanFocus then
        begin
          FControles[J].SetFocus;
          Exit;
        end;
      Exit;
    end;
end;

procedure TNavegacaoCampos.FocarProximo(const Atual: TControl);
var
  I, J: Integer;
begin
  for I := 0 to High(FControles) do
    if FControles[I] = Atual then
    begin
      for J := I + 1 to High(FControles) do
        if Assigned(FControles[J]) and FControles[J].Visible and
           FControles[J].Enabled and FControles[J].CanFocus then
        begin
          FControles[J].SetFocus;
          Exit;
        end;
      Exit;
    end;
end;

end.
