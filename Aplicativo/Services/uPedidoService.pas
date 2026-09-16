unit uPedidoService;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.Net.URLClient,
  System.Net.HttpClient,
  System.Net.HttpClientComponent,
  uPedidoModel, uApiConfig;

type
  EPedidoService = class(Exception);

  TRespostaPedido = class
  public
    Sucesso: Boolean;
    StatusCode: Integer;
    Mensagem: string;
    PedidoId: Integer;
    NumeroPedido: string;
    JSONResposta: string;
  end;

  TPedidoService = class
  private
    class function ExtrairMensagemErro(
      const AConteudo: string
    ): string; static;

    class procedure LerRespostaSucesso(
      const AConteudo: string;
      AResposta: TRespostaPedido
    ); static;
  public
    class function EnviarPedido(
      APedido: TPedido
    ): TRespostaPedido; static;
  end;

implementation

class function TPedidoService.ExtrairMensagemErro(
  const AConteudo: string): string;
var
  LJSONValue: TJSONValue;
  LJSONObject: TJSONObject;
begin
  Result := '';

  if Trim(AConteudo) = '' then
    Exit;

  LJSONValue := TJSONObject.ParseJSONValue(AConteudo);

  try
    if LJSONValue is TJSONObject then
    begin
      LJSONObject := TJSONObject(LJSONValue);

      if not LJSONObject.TryGetValue<string>(
        'mensagem',
        Result
      ) then
      begin
        if not LJSONObject.TryGetValue<string>(
          'message',
          Result
        ) then
        begin
          LJSONObject.TryGetValue<string>(
            'erro',
            Result
          );
        end;
      end;
    end;
  finally
    LJSONValue.Free;
  end;

  if Result = '' then
    Result := AConteudo;
end;

class procedure TPedidoService.LerRespostaSucesso(
  const AConteudo: string;
  AResposta: TRespostaPedido);
var
  LJSONValue: TJSONValue;
  LJSONObject: TJSONObject;
begin
  if not Assigned(AResposta) then
    Exit;

  if Trim(AConteudo) = '' then
  begin
    AResposta.Mensagem :=
      'Pedido enviado com sucesso.';

    Exit;
  end;

  LJSONValue := TJSONObject.ParseJSONValue(AConteudo);

  try
    if not (LJSONValue is TJSONObject) then
    begin
      AResposta.Mensagem :=
        'Pedido enviado com sucesso.';

      Exit;
    end;

    LJSONObject := TJSONObject(LJSONValue);

    if not LJSONObject.TryGetValue<string>(
      'mensagem',
      AResposta.Mensagem
    ) then
    begin
      LJSONObject.TryGetValue<string>(
        'message',
        AResposta.Mensagem
      );
    end;

    LJSONObject.TryGetValue<Integer>(
      'pedido_id',
      AResposta.PedidoId
    );

    if AResposta.PedidoId = 0 then
    begin
      LJSONObject.TryGetValue<Integer>(
        'id',
        AResposta.PedidoId
      );
    end;

    LJSONObject.TryGetValue<string>(
      'numero_pedido',
      AResposta.NumeroPedido
    );

    if AResposta.NumeroPedido = '' then
    begin
      LJSONObject.TryGetValue<string>(
        'numero',
        AResposta.NumeroPedido
      );
    end;

    if AResposta.Mensagem = '' then
      AResposta.Mensagem :=
        'Pedido enviado com sucesso.';
  finally
    LJSONValue.Free;
  end;
end;

class function TPedidoService.EnviarPedido(
  APedido: TPedido): TRespostaPedido;
var
  LHTTP: TNetHTTPClient;
  LConteudo: TStringStream;
  LRespostaHTTP: IHTTPResponse;
  LJSONPedido: string;
  LConteudoResposta: string;
begin
  Result := TRespostaPedido.Create;

  Result.Sucesso := False;
  Result.StatusCode := 0;
  Result.Mensagem := '';
  Result.PedidoId := 0;
  Result.NumeroPedido := '';
  Result.JSONResposta := '';

  if not Assigned(APedido) then
  begin
    Result.Mensagem :=
      'O pedido não foi informado.';

    Exit;
  end;

  LHTTP := TNetHTTPClient.Create(nil);

  try
    LHTTP.ConnectionTimeout := 10000;
    LHTTP.ResponseTimeout := 30000;
    LHTTP.Accept := 'application/json';
    LHTTP.ContentType := 'application/json';

    LHTTP.CustomHeaders['Accept'] :=
      'application/json';

    LHTTP.CustomHeaders['Content-Type'] :=
      'application/json; charset=utf-8';

    LJSONPedido := APedido.ToJSONString;

    LConteudo := TStringStream.Create(
      LJSONPedido,
      TEncoding.UTF8
    );

    try
      try
        LRespostaHTTP := LHTTP.Post(
          TApiConfig.Url('/pedidos'),
          LConteudo
        );

        Result.StatusCode :=
          LRespostaHTTP.StatusCode;

        LConteudoResposta :=
          LRespostaHTTP.ContentAsString(
            TEncoding.UTF8
          );

        Result.JSONResposta :=
          LConteudoResposta;

        Result.Sucesso :=
          (Result.StatusCode >= 200) and
          (Result.StatusCode <= 299);

        if Result.Sucesso then
        begin
          LerRespostaSucesso(
            LConteudoResposta,
            Result
          );
        end
        else
        begin
          Result.Mensagem :=
            ExtrairMensagemErro(
              LConteudoResposta
            );

          if Result.Mensagem = '' then
          begin
            Result.Mensagem :=
              Format(
                'A API retornou o código HTTP %d.',
                [Result.StatusCode]
              );
          end;
        end;

      except
        on E: ENetHTTPClientException do
        begin
          Result.Sucesso := False;

          Result.Mensagem :=
            'Não foi possível conectar com a API.' +
            sLineBreak +
            sLineBreak +
            E.Message;
        end;

        on E: Exception do
        begin
          Result.Sucesso := False;

          Result.Mensagem :=
            'Erro ao enviar o pedido:' +
            sLineBreak +
            sLineBreak +
            E.Message;
        end;
      end;
    finally
      LConteudo.Free;
    end;
  finally
    LHTTP.Free;
  end;
end;

end.
