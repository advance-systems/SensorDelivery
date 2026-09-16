unit uSessaoAdmin;

interface

uses
  System.Classes, System.Generics.Collections, System.Net.HttpClientComponent;

type
  TEmpresaSessao = class
  public
    Id: string;
    NomeFantasia: string;
    Principal: Boolean;
  end;

  TSessaoAdmin = class
  private
    class var FToken: string;
    class var FUsuarioId: string;
    class var FUsuarioNome: string;
    class var FUsuarioEmail: string;
    class var FUsuarioTipo: string;
    class var FEmpresaId: string;
    class var FEmpresaNome: string;
    class var FEmpresas: TObjectList<TEmpresaSessao>;
    class var FPermissoes: TStringList;
    class procedure GarantirListas; static;
    class procedure LerResposta(const AConteudo: string); static;
  public
    class function Login(const AEmail, ASenha: string; out AErro: string): Boolean; static;
    class function SelecionarEmpresa(const AEmpresaId: string; out AErro: string): Boolean; static;
    class procedure ConfigurarCliente(const AHTTP: TNetHTTPClient); static;
    class function Pode(const ACodigo: string): Boolean; static;
    class procedure Encerrar; static;
    class property Token: string read FToken;
    class property UsuarioId: string read FUsuarioId;
    class property UsuarioNome: string read FUsuarioNome;
    class property UsuarioEmail: string read FUsuarioEmail;
    class property UsuarioTipo: string read FUsuarioTipo;
    class property EmpresaId: string read FEmpresaId;
    class property EmpresaNome: string read FEmpresaNome;
    class property Empresas: TObjectList<TEmpresaSessao> read FEmpresas;
  end;

implementation

uses
  System.SysUtils, System.JSON, System.Net.HttpClient, System.Net.URLClient,
  uApiConfig;

function URL_AUTH: string;
begin
  Result := TApiConfig.Url('/api/auth');
end;

class procedure TSessaoAdmin.GarantirListas;
begin
  if not Assigned(FEmpresas) then
    FEmpresas := TObjectList<TEmpresaSessao>.Create(True);
  if not Assigned(FPermissoes) then
  begin
    FPermissoes := TStringList.Create;
    FPermissoes.CaseSensitive := False;
    FPermissoes.Sorted := True;
    FPermissoes.Duplicates := dupIgnore;
  end;
end;

class procedure TSessaoAdmin.LerResposta(const AConteudo: string);
var
  Valor, Item: TJSONValue;
  Raiz, Usuario, Empresa, Objeto: TJSONObject;
  Lista: TJSONArray;
  EmpresaSessao: TEmpresaSessao;
begin
  GarantirListas;
  Valor := TJSONObject.ParseJSONValue(AConteudo);
  try
    if not (Valor is TJSONObject) then
      raise Exception.Create('Resposta de autenticação inválida.');
    Raiz := TJSONObject(Valor);
    FToken := Raiz.GetValue<string>('token', '');
    Usuario := Raiz.GetValue<TJSONObject>('usuario');
    Empresa := Raiz.GetValue<TJSONObject>('empresa');
    if (FToken = '') or not Assigned(Usuario) or not Assigned(Empresa) then
      raise Exception.Create('A API não retornou os dados completos da sessão.');

    FUsuarioId := Usuario.GetValue<string>('id', '');
    FUsuarioNome := Usuario.GetValue<string>('nome', '');
    FUsuarioEmail := Usuario.GetValue<string>('email', '');
    FUsuarioTipo := Usuario.GetValue<string>('tipo', '');
    FEmpresaId := Empresa.GetValue<string>('id', '');
    FEmpresaNome := Empresa.GetValue<string>('nomeFantasia', '');

    FEmpresas.Clear;
    Lista := Raiz.GetValue<TJSONArray>('empresas');
    if Assigned(Lista) then
      for Item in Lista do
        if Item is TJSONObject then
        begin
          Objeto := TJSONObject(Item);
          EmpresaSessao := TEmpresaSessao.Create;
          EmpresaSessao.Id := Objeto.GetValue<string>('id', '');
          EmpresaSessao.NomeFantasia := Objeto.GetValue<string>('nome_fantasia', '');
          EmpresaSessao.Principal := Objeto.GetValue<Boolean>('principal', False);
          FEmpresas.Add(EmpresaSessao);
        end;

    FPermissoes.Clear;
    Lista := Raiz.GetValue<TJSONArray>('permissoes');
    if Assigned(Lista) then
      for Item in Lista do
        FPermissoes.Add(Item.Value);
  finally
    Valor.Free;
  end;
end;

class function TSessaoAdmin.Login(const AEmail, ASenha: string;
  out AErro: string): Boolean;
var
  HTTP: TNetHTTPClient;
  JSON: TJSONObject;
  Stream: TStringStream;
  Resposta: IHTTPResponse;
  Valor: TJSONValue;
begin
  Result := False;
  AErro := '';
  HTTP := TNetHTTPClient.Create(nil);
  JSON := TJSONObject.Create;
  try
    JSON.AddPair('email', AEmail.Trim);
    JSON.AddPair('senha', ASenha);
    Stream := TStringStream.Create(JSON.ToJSON, TEncoding.UTF8);
    try
      HTTP.ContentType := 'application/json';
      Resposta := HTTP.Post(URL_AUTH + '/login', Stream);
    finally
      Stream.Free;
    end;
    if Resposta.StatusCode <> 200 then
    begin
      Valor := TJSONObject.ParseJSONValue(Resposta.ContentAsString(TEncoding.UTF8));
      try
        if Valor is TJSONObject then
          AErro := TJSONObject(Valor).GetValue<string>('erro', 'Não foi possível entrar no sistema.')
        else
          AErro := 'Não foi possível entrar no sistema.';
      finally
        Valor.Free;
      end;
      Exit;
    end;
    LerResposta(Resposta.ContentAsString(TEncoding.UTF8));
    Result := True;
  except
    on E: Exception do
      AErro := E.Message;
  end;
  JSON.Free;
  HTTP.Free;
end;

class function TSessaoAdmin.SelecionarEmpresa(const AEmpresaId: string;
  out AErro: string): Boolean;
var
  HTTP: TNetHTTPClient;
  JSON: TJSONObject;
  Stream: TStringStream;
  Resposta: IHTTPResponse;
  Valor: TJSONValue;
begin
  Result := False;
  AErro := '';
  HTTP := TNetHTTPClient.Create(nil);
  JSON := TJSONObject.Create;
  try
    ConfigurarCliente(HTTP);
    HTTP.ContentType := 'application/json';
    JSON.AddPair('empresaId', AEmpresaId);
    Stream := TStringStream.Create(JSON.ToJSON, TEncoding.UTF8);
    try
      Resposta := HTTP.Post(URL_AUTH + '/selecionar-empresa', Stream);
    finally
      Stream.Free;
    end;
    if Resposta.StatusCode <> 200 then
    begin
      Valor := TJSONObject.ParseJSONValue(Resposta.ContentAsString(TEncoding.UTF8));
      try
        if Valor is TJSONObject then
          AErro := TJSONObject(Valor).GetValue<string>('erro', 'Não foi possível selecionar a empresa.')
        else
          AErro := 'Não foi possível selecionar a empresa.';
      finally
        Valor.Free;
      end;
      Exit;
    end;
    LerResposta(Resposta.ContentAsString(TEncoding.UTF8));
    Result := True;
  except
    on E: Exception do AErro := E.Message;
  end;
  JSON.Free;
  HTTP.Free;
end;

class procedure TSessaoAdmin.ConfigurarCliente(const AHTTP: TNetHTTPClient);
begin
  if Assigned(AHTTP) and not FToken.IsEmpty then
    AHTTP.CustomHeaders['Authorization'] := 'Bearer ' + FToken;
end;

class function TSessaoAdmin.Pode(const ACodigo: string): Boolean;
begin
  GarantirListas;
  Result := SameText(FUsuarioTipo, 'ADMIN') or (FPermissoes.IndexOf(ACodigo) >= 0);
end;

class procedure TSessaoAdmin.Encerrar;
begin
  FToken := '';
  FUsuarioId := '';
  FUsuarioNome := '';
  FUsuarioEmail := '';
  FUsuarioTipo := '';
  FEmpresaId := '';
  FEmpresaNome := '';
  FreeAndNil(FEmpresas);
  FreeAndNil(FPermissoes);
end;

initialization
  TSessaoAdmin.GarantirListas;

finalization
  TSessaoAdmin.Encerrar;

end.
