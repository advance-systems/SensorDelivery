unit uEmpresaApp;

interface

type
  TEmpresaApp = class
  private
    class var FId: string;
    class var FNome: string;
    class var FLogoUrl: string;
    class procedure Carregar; static;
  public
    class function Id: string; static;
    class function Nome: string; static;
    class function LogoUrl: string; static;
    class procedure Selecionar(const AId, ANome: string;
      const ALogoUrl: string = ''); static;
    class procedure Limpar; static;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.JSON,
  System.Net.HttpClient, System.Net.HttpClientComponent, uApiConfig;

function URL_EMPRESAS: string;
begin
  Result := TApiConfig.Url('/api/loja/empresas');
end;

class procedure TEmpresaApp.Carregar;
var
  HTTP: TNetHTTPClient;
  Resposta: IHTTPResponse;
  Valor: TJSONValue;
  Lista: TJSONArray;
  Empresa: TJSONObject;
begin
  if not FId.IsEmpty then Exit;
  HTTP := TNetHTTPClient.Create(nil);
  Valor := nil;
  try
    HTTP.ConnectionTimeout := 3000;
    HTTP.ResponseTimeout := 5000;
    Resposta := HTTP.Get(URL_EMPRESAS);
    if Resposta.StatusCode <> 200 then
      raise Exception.Create('Não foi possível identificar a loja.');
    Valor := TJSONObject.ParseJSONValue(Resposta.ContentAsString(TEncoding.UTF8));
    if not (Valor is TJSONObject) then
      raise Exception.Create('A API retornou uma lista de lojas inválida.');
    Lista := TJSONObject(Valor).GetValue<TJSONArray>('empresas');
    if not Assigned(Lista) or (Lista.Count = 0) then
      raise Exception.Create('Nenhuma loja ativa foi encontrada.');
    Empresa := Lista.Items[0] as TJSONObject;
    FId := Empresa.GetValue<string>('id', '');
    FNome := Empresa.GetValue<string>('nome_fantasia', '');
    FLogoUrl := Empresa.GetValue<string>('logo_url', '');
    if FId.IsEmpty then
      raise Exception.Create('A loja retornada pela API é inválida.');
  finally
    Valor.Free;
    HTTP.Free;
  end;
end;

class function TEmpresaApp.Id: string;
begin
  Carregar;
  Result := FId;
end;

class function TEmpresaApp.Nome: string;
begin
  Carregar;
  Result := FNome;
end;

class function TEmpresaApp.LogoUrl: string;
begin
  Carregar;
  Result := FLogoUrl;
end;

class procedure TEmpresaApp.Selecionar(const AId, ANome, ALogoUrl: string);
begin
  FId := AId.Trim;
  FNome := ANome.Trim;
  FLogoUrl := ALogoUrl.Trim;
end;

class procedure TEmpresaApp.Limpar;
begin
  FId := '';
  FNome := '';
  FLogoUrl := '';
end;

end.
