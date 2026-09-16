unit uPedidoLocal;

interface

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  System.Classes;

type
  TPedidoLocal = class
  private
    class function NomeArquivo: string; static;
  public
    class procedure Salvar(
      const APedidoId: string;
      const ANumeroPedido: Integer
    ); static;

    class function Carregar(
      out APedidoId: string;
      out ANumeroPedido: Integer
    ): Boolean; static;

    class procedure Limpar; static;
  end;

implementation

class function TPedidoLocal.NomeArquivo: string;
var
  LPastaBase: string;
  LPastaApp: string;
begin
  {$IF DEFINED(MSWINDOWS)}
  LPastaBase := TPath.GetHomePath;
  {$ELSE}
  LPastaBase := TPath.GetDocumentsPath;
  {$ENDIF}

  LPastaApp :=
    TPath.Combine(
      LPastaBase,
      'SensorDelivery'
    );

  if not TDirectory.Exists(LPastaApp) then
    TDirectory.CreateDirectory(LPastaApp);

  Result :=
    TPath.Combine(
      LPastaApp,
      'pedido_atual.json'
    );
end;

class procedure TPedidoLocal.Salvar(
  const APedidoId: string;
  const ANumeroPedido: Integer);
var
  LJSON: TJSONObject;
begin
  if APedidoId.Trim.IsEmpty then
    Exit;

  LJSON := TJSONObject.Create;
  try
    LJSON.AddPair(
      'pedido_id',
      APedidoId
    );

    LJSON.AddPair(
      'numero',
      TJSONNumber.Create(ANumeroPedido)
    );

    TFile.WriteAllText(
      NomeArquivo,
      LJSON.ToJSON,
      TEncoding.UTF8
    );
  finally
    LJSON.Free;
  end;
end;

class function TPedidoLocal.Carregar(
  out APedidoId: string;
  out ANumeroPedido: Integer): Boolean;
var
  LTexto: string;
  LJSON: TJSONObject;
begin
  Result := False;

  APedidoId := '';
  ANumeroPedido := 0;

  if not TFile.Exists(NomeArquivo) then
    Exit;

  LTexto :=
    TFile.ReadAllText(
      NomeArquivo,
      TEncoding.UTF8
    );

  LJSON :=
    TJSONObject.ParseJSONValue(LTexto)
      as TJSONObject;

  if not Assigned(LJSON) then
    Exit;

  try
    APedidoId :=
      LJSON.GetValue<string>(
        'pedido_id',
        ''
      );

    ANumeroPedido :=
      LJSON.GetValue<Integer>(
        'numero',
        0
      );

    Result :=
      not APedidoId.Trim.IsEmpty;

  finally
    LJSON.Free;
  end;
end;

class procedure TPedidoLocal.Limpar;
begin
  if TFile.Exists(NomeArquivo) then
    TFile.Delete(NomeArquivo);
end;

end.
