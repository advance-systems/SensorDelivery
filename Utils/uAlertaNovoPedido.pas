unit uAlertaNovoPedido;

interface

type
  TAlertaNovoPedido = class
  private
    class var FUltimosPedidosAlertados: TObject;
    class var FSonsPorEmpresa: TObject;
    class function ChaveEmpresa: string; static;
    class function NormalizarSom(const ASom: string): string; static;
    class function ObterSomConfigurado: string; static;
    class function RegistrarPedido(const ANumero: Integer): Boolean; static;
    class procedure TocarSom(const ASom: string); static;
  public
    class constructor Create;
    class destructor Destroy;
    class procedure DefinirSom(const ASom: string); static;
    class procedure TestarSom(const ASom: string); static;
    class procedure Exibir(const ANumero: Integer; const ACliente: string;
      const ATotal: Currency); static;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.Generics.Collections,
  System.Net.HttpClient,
  System.Net.HttpClientComponent,
  uApiConfig,
  uMensagem,
  uSessaoAdmin
  {$IFDEF MSWINDOWS}
  , Winapi.Windows
  , Winapi.MMSystem
  {$ENDIF}
  ;

type
  TDicionarioUltimosPedidos = TDictionary<string, Integer>;
  TDicionarioSons = TDictionary<string, string>;

class constructor TAlertaNovoPedido.Create;
begin
  FUltimosPedidosAlertados := TDicionarioUltimosPedidos.Create;
  FSonsPorEmpresa := TDicionarioSons.Create;
end;

class destructor TAlertaNovoPedido.Destroy;
begin
  FSonsPorEmpresa.Free;
  FUltimosPedidosAlertados.Free;
end;

class function TAlertaNovoPedido.ChaveEmpresa: string;
begin
  Result := TSessaoAdmin.EmpresaId;
  if Result.IsEmpty then
    Result := 'empresa-atual';
end;

class function TAlertaNovoPedido.NormalizarSom(const ASom: string): string;
begin
  Result := ASom.Trim.ToUpper;
  if (Result <> 'NOTIFICACAO') and
     (Result <> 'EXCLAMACAO') and
     (Result <> 'ASTERISCO') and
     (Result <> 'ERRO') and
     (Result <> 'SEM_SOM') then
    Result := 'NOTIFICACAO';
end;

class procedure TAlertaNovoPedido.DefinirSom(const ASom: string);
begin
  TDicionarioSons(FSonsPorEmpresa).AddOrSetValue(
    ChaveEmpresa,
    NormalizarSom(ASom)
  );
end;

class function TAlertaNovoPedido.ObterSomConfigurado: string;
var
  LHTTP: TNetHTTPClient;
  LResposta: IHTTPResponse;
  LValor: TJSONValue;
  LRaiz, LConfiguracao: TJSONObject;
begin
  if TDicionarioSons(FSonsPorEmpresa).TryGetValue(ChaveEmpresa, Result) then
    Exit;

  Result := 'NOTIFICACAO';
  { Grava o padrão antes da consulta para evitar carregamentos repetidos. }
  DefinirSom(Result);

  LHTTP := TNetHTTPClient.Create(nil);
  LValor := nil;
  try
    try
      TSessaoAdmin.ConfigurarCliente(LHTTP);
      LResposta := LHTTP.Get(TApiConfig.Url('/api/configuracoes'));
      if LResposta.StatusCode <> 200 then
        Exit;

      LValor := TJSONObject.ParseJSONValue(
        LResposta.ContentAsString(TEncoding.UTF8)
      );
      if not (LValor is TJSONObject) then
        Exit;

      LRaiz := TJSONObject(LValor);
      LConfiguracao := LRaiz.GetValue<TJSONObject>('configuracao');
      if not Assigned(LConfiguracao) then
        Exit;

      Result := NormalizarSom(
        LConfiguracao.GetValue<string>('som_alerta_pedido', 'NOTIFICACAO')
      );
      DefinirSom(Result);
    except
      { Se a preferência não puder ser consultada, mantém o som padrão. }
    end;
  finally
    LValor.Free;
    LHTTP.Free;
  end;
end;

class function TAlertaNovoPedido.RegistrarPedido(
  const ANumero: Integer): Boolean;
var
  LEmpresaId: string;
  LUltimoNumero: Integer;
begin
  Result := False;

  if ANumero <= 0 then
    Exit;

  LEmpresaId := ChaveEmpresa;

  if TDicionarioUltimosPedidos(FUltimosPedidosAlertados).TryGetValue(
    LEmpresaId,
    LUltimoNumero
  ) and (ANumero <= LUltimoNumero) then
    Exit;

  TDicionarioUltimosPedidos(FUltimosPedidosAlertados).AddOrSetValue(
    LEmpresaId,
    ANumero
  );

  Result := True;
end;

class procedure TAlertaNovoPedido.TocarSom(const ASom: string);
var
  LAlias: string;
  LBeep: Cardinal;
begin
  {$IFDEF MSWINDOWS}
  if SameText(ASom, 'SEM_SOM') then
    Exit;

  LAlias := 'SystemNotification';
  LBeep := MB_ICONASTERISK;

  if SameText(ASom, 'EXCLAMACAO') then
  begin
    LAlias := 'SystemExclamation';
    LBeep := MB_ICONEXCLAMATION;
  end
  else if SameText(ASom, 'ASTERISCO') then
  begin
    LAlias := 'SystemAsterisk';
    LBeep := MB_ICONASTERISK;
  end
  else if SameText(ASom, 'ERRO') then
  begin
    LAlias := 'SystemHand';
    LBeep := MB_ICONHAND;
  end;

  if not PlaySound(
    PChar(LAlias),
    0,
    SND_ALIAS or SND_ASYNC or SND_NODEFAULT
  ) then
    MessageBeep(LBeep);
  {$ENDIF}
end;

class procedure TAlertaNovoPedido.TestarSom(const ASom: string);
var
  LSom: string;
  LFrequencia: Cardinal;
begin
  LSom := NormalizarSom(ASom);
  if SameText(LSom, 'SEM_SOM') then
    Exit;
  {$IFDEF MSWINDOWS}
  { O beep direto permite testar mesmo quando o tema do Windows não possui
    um arquivo associado ao evento escolhido. }
  LFrequencia := 880;
  if SameText(LSom, 'EXCLAMACAO') then LFrequencia := 1050
  else if SameText(LSom, 'ASTERISCO') then LFrequencia := 760
  else if SameText(LSom, 'ERRO') then LFrequencia := 520;
  Winapi.Windows.Beep(LFrequencia, 220);
  {$ELSE}
  TocarSom(LSom);
  {$ENDIF}
end;

class procedure TAlertaNovoPedido.Exibir(
  const ANumero: Integer;
  const ACliente: string;
  const ATotal: Currency);
begin
  { Registra antes da janela modal para impedir alertas repetidos dos timers. }
  if not RegistrarPedido(ANumero) then
    Exit;

  TocarSom(ObterSomConfigurado);

  TfrmMensagem.Exibir(
    'Novo pedido recebido!',
    Format(
      'Pedido #%d' + sLineBreak +
      '%s' + sLineBreak +
      'Total: %s',
      [
        ANumero,
        ACliente,
        FormatFloat('"R$ " #,##0.00', ATotal)
      ]
    ),
    tmAtencao,
    False,
    'Entendi',
    ''
  );
end;

end.
