unit uApiConfig;

interface

type
  TApiConfig = class
  private
    class var FBaseUrl: string;
    class function CarregarBaseUrl: string; static;
    class function Normalizar(const Valor: string): string; static;
  public
    class function BaseUrl: string; static;
    class function Url(const Caminho: string): string; static;
    class procedure DefinirBaseUrl(const Valor: string); static;
    class procedure RestaurarPadrao; static;
    class procedure Recarregar; static;
  end;

implementation

uses
  System.SysUtils, System.IniFiles, System.IOUtils;

const
  URL_API_PADRAO = 'https://sensordelivery-production.up.railway.app';
  ARQUIVO_CONFIGURACAO = 'sensor-delivery.ini';

function ArquivoConfiguracaoGravavel: string;
begin
  Result := TPath.Combine(TPath.GetDocumentsPath, ARQUIVO_CONFIGURACAO);
end;

class function TApiConfig.Normalizar(const Valor: string): string;
begin
  Result := Valor.Trim;
  while Result.EndsWith('/') do
    Delete(Result, Result.Length, 1);

  if not Result.StartsWith('http://', True) and
     not Result.StartsWith('https://', True) then
    raise Exception.Create(
      'O endereço da API deve começar com http:// ou https://.');
end;

class function TApiConfig.CarregarBaseUrl: string;
var
  Ini: TIniFile;
  Arquivo, Valor: string;
begin
  Valor := GetEnvironmentVariable('SENSOR_DELIVERY_API_URL');
  if not Valor.Trim.IsEmpty then
    Exit(Normalizar(Valor));

{$IF DEFINED(ANDROID)}
  Arquivo := ArquivoConfiguracaoGravavel;
{$ELSE}
  Arquivo := TPath.Combine(ExtractFilePath(ParamStr(0)), ARQUIVO_CONFIGURACAO);
  if not TFile.Exists(Arquivo) then
    Arquivo := ArquivoConfiguracaoGravavel;
{$ENDIF}

  if TFile.Exists(Arquivo) then
  begin
    Ini := TIniFile.Create(Arquivo);
    try
      Valor := Ini.ReadString('API', 'BaseURL', URL_API_PADRAO);
    finally
      Ini.Free;
    end;
  end
  else
    Valor := URL_API_PADRAO;

  Result := Normalizar(Valor);
end;

class procedure TApiConfig.DefinirBaseUrl(const Valor: string);
var
  Ini: TIniFile;
  Arquivo, URL: string;
begin
  if Valor.Trim.IsEmpty then
    URL := URL_API_PADRAO
  else
    URL := Normalizar(Valor);

  Arquivo := ArquivoConfiguracaoGravavel;
  ForceDirectories(ExtractFilePath(Arquivo));
  Ini := TIniFile.Create(Arquivo);
  try
    Ini.WriteString('API', 'BaseURL', URL);
  finally
    Ini.Free;
  end;
  FBaseUrl := URL;
end;

class procedure TApiConfig.RestaurarPadrao;
begin
  DefinirBaseUrl(URL_API_PADRAO);
end;

class function TApiConfig.BaseUrl: string;
begin
  if FBaseUrl.IsEmpty then
    FBaseUrl := CarregarBaseUrl;
  Result := FBaseUrl;
end;

class function TApiConfig.Url(const Caminho: string): string;
begin
  if Caminho.IsEmpty then
    Exit(BaseUrl);
  if Caminho.StartsWith('/') then
    Result := BaseUrl + Caminho
  else
    Result := BaseUrl + '/' + Caminho;
end;

class procedure TApiConfig.Recarregar;
begin
  FBaseUrl := '';
end;

end.
