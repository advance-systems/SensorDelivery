unit uImagemUpload;

interface

uses System.Classes;

type
  TImagemUpload = class
  public
    class function SelecionarEEnviar(const AOwner: TComponent;
      out AURL: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils, System.JSON, System.Net.HttpClient,
  System.Net.HttpClientComponent, FMX.Dialogs, uSessaoAdmin, uApiConfig;

function URL_UPLOAD: string;
begin
  Result := TApiConfig.Url('/api/uploads/imagens');
end;

class function TImagemUpload.SelecionarEEnviar(const AOwner: TComponent;
  out AURL: string): Boolean;
var
  Dialogo: TOpenDialog;
  HTTP: TNetHTTPClient;
  Arquivo: TFileStream;
  Resposta: IHTTPResponse;
  Valor: TJSONValue;
  Extensao: string;
begin
  Result := False; AURL := '';
  Dialogo := TOpenDialog.Create(AOwner);
  try
    Dialogo.Title := 'Selecionar imagem';
    Dialogo.Filter := 'Imagens|*.jpg;*.jpeg;*.png;*.webp;*.gif';
    if not Dialogo.Execute then Exit;
    Extensao := LowerCase(ExtractFileExt(Dialogo.FileName));
    HTTP := TNetHTTPClient.Create(nil);
    TSessaoAdmin.ConfigurarCliente(HTTP);
    Arquivo := TFileStream.Create(Dialogo.FileName, fmOpenRead or fmShareDenyWrite);
    Valor := nil;
    try
      if (Extensao = '.jpg') or (Extensao = '.jpeg') then HTTP.ContentType := 'image/jpeg'
      else if Extensao = '.png' then HTTP.ContentType := 'image/png'
      else if Extensao = '.webp' then HTTP.ContentType := 'image/webp'
      else if Extensao = '.gif' then HTTP.ContentType := 'image/gif'
      else raise Exception.Create('Formato de imagem não suportado.');
      HTTP.Accept := 'application/json';
      Resposta := HTTP.Post(URL_UPLOAD, Arquivo);
      Valor := TJSONObject.ParseJSONValue(Resposta.ContentAsString(TEncoding.UTF8));
      if Resposta.StatusCode <> 201 then
      begin
        if Valor is TJSONObject then
          raise Exception.Create(TJSONObject(Valor).GetValue<string>('erro',
            'Não foi possível enviar a imagem.'));
        raise Exception.Create('Não foi possível enviar a imagem.');
      end;
      if not (Valor is TJSONObject) then raise Exception.Create('Resposta inválida do upload.');
      AURL := TJSONObject(Valor).GetValue<string>('url', '');
      Result := not AURL.IsEmpty;
    finally
      Valor.Free; Arquivo.Free; HTTP.Free;
    end;
  finally
    Dialogo.Free;
  end;
end;

end.
