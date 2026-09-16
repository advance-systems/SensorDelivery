unit uFrameEntradaLoja;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation;

type
  TfraEntradaLoja = class(TFrame)
    rctFundo: TRectangle;
    imgLogo: TImage;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    rctEmpresa: TRectangle;
    rctImagemEmpresa: TRectangle;
    imgEmpresa: TImage;
    lblNomeEmpresa: TLabel;
    lblEnderecoEmpresa: TLabel;
    cirStatusEmpresa: TCircle;
    lblStatusEmpresa: TLabel;
    lblHorarioEmpresa: TLabel;
    lblEntrarEmpresa: TLabel;
    procedure rctEmpresaClick(Sender: TObject);
  private
    FLojaAberta: Boolean;
    FOnEntrarLoja: TNotifyEvent;

    procedure AtualizarVisual;
    procedure CarregarLogo(const ALogoUrl: string);
  public
    procedure ConfigurarLoja(
      const ANome: string;
      const AEndereco: string;
      const AAberta: Boolean;
      const AHorario: string;
      const ALogoUrl: string
    );

    property OnEntrarLoja: TNotifyEvent
      read FOnEntrarLoja
      write FOnEntrarLoja;
  end;

implementation

{$R *.fmx}

uses
  System.Net.HttpClient, System.Net.HttpClientComponent, uApiConfig;

procedure TfraEntradaLoja.ConfigurarLoja(
  const ANome: string;
  const AEndereco: string;
  const AAberta: Boolean;
  const AHorario: string;
  const ALogoUrl: string);
begin
  FLojaAberta := AAberta;

  lblNomeEmpresa.Text := ANome;
  lblEnderecoEmpresa.Text := AEndereco;
  lblHorarioEmpresa.Text := AHorario;
  CarregarLogo(ALogoUrl);

  AtualizarVisual;
end;

procedure TfraEntradaLoja.CarregarLogo(const ALogoUrl:string);
var
  HTTP:TNetHTTPClient;
  Resposta:IHTTPResponse;
  Conteudo:TMemoryStream;
  URL:string;
begin
  imgEmpresa.Bitmap.Clear(TAlphaColors.Null);
  URL:=ALogoUrl.Trim;
  if URL.IsEmpty then Exit;
  if URL.StartsWith('/') then URL:=TApiConfig.Url(URL);

  HTTP:=TNetHTTPClient.Create(nil);
  Conteudo:=TMemoryStream.Create;
  try
    try
      HTTP.ConnectionTimeout:=5000;
      HTTP.ResponseTimeout:=8000;
      Resposta:=HTTP.Get(URL,Conteudo);
      if (Resposta.StatusCode>=200) and (Resposta.StatusCode<300) then begin
        Conteudo.Position:=0;
        imgEmpresa.Bitmap.LoadFromStream(Conteudo);
      end;
    except
      { A tela continua funcionando sem imagem se o arquivo estiver indisponível. }
    end;
  finally
    Conteudo.Free;
    HTTP.Free;
  end;
end;

procedure TfraEntradaLoja.rctEmpresaClick(Sender: TObject);
begin
  if Assigned(FOnEntrarLoja) then
    FOnEntrarLoja(Self);
end;

procedure TfraEntradaLoja.AtualizarVisual;
begin
  if FLojaAberta then
  begin
    cirStatusEmpresa.Fill.Color := $FF24A865;

    lblStatusEmpresa.Text := 'Aberto';
    lblStatusEmpresa.TextSettings.FontColor :=
      $FF24A865;

    lblEntrarEmpresa.Text := 'Ver card' + Char($00E1) + 'pio  >';
    lblEntrarEmpresa.TextSettings.FontColor :=
      $FFFF4B0A;
  end
  else
  begin
    cirStatusEmpresa.Fill.Color := $FFE84D4D;

    lblStatusEmpresa.Text := 'Fechado';
    lblStatusEmpresa.TextSettings.FontColor :=
      $FFE84D4D;

    lblEntrarEmpresa.Text := 'Ver hor' + Char($00E1) + 'rios  >';
    lblEntrarEmpresa.TextSettings.FontColor :=
      $FFFF4B0A;
  end;
end;

end.
