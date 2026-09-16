unit uFrameContaMobile;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, FMX.Layouts, FMX.Edit;

type
  TfraContaMobile = class(TFrame)
    rctTopoConta: TRectangle;
    lblTituloConta: TLabel;
    lblSubtituloConta: TLabel;
    vsbConta: TVertScrollBox;
    lblDadosPessoais: TLabel;
    rctDadosPessoais: TRectangle;
    lblNome: TLabel;
    edtNome: TEdit;
    lblTelefone: TLabel;
    edtTelefone: TEdit;
    lblEndereco: TLabel;
    rctEndereco: TRectangle;
    lblCEP: TLabel;
    edtCEP: TEdit;
    lblRua: TLabel;
    edtRua: TEdit;
    lblNumero: TLabel;
    edtNumero: TEdit;
    lblBairro: TLabel;
    edtBairro: TEdit;
    lblComplemento: TLabel;
    edtComplemento: TEdit;
    lblCidade: TLabel;
    edtCidade: TEdit;
    lblUF: TLabel;
    edtUF: TEdit;
    rctSalvar: TRectangle;
    lblSalvar: TLabel;
    lblVersaoApp: TLabel;
    lblServidorAPI: TLabel;
    rctServidorAPI: TRectangle;
    lblEnderecoAPI: TLabel;
    edtServidorAPI: TEdit;
    lblAjudaServidorAPI: TLabel;
    procedure rctSalvarClick(Sender: TObject);
  private
    procedure CarregarDados;
    procedure SalvarDados;
  public
    constructor Create(AOwner: TComponent); override;
    procedure PrepararTela;
  end;

implementation

{$R *.fmx}

uses uClienteLocal, uTelefoneDispositivo, uMensagemMobile, uVersaoApp,
  uCursorCamposMobile, uApiConfig;

constructor TfraContaMobile.Create(AOwner: TComponent);
begin
  inherited;
  TCursorCamposMobile.Aplicar(Self, Self);
end;

procedure TfraContaMobile.PrepararTela;
begin
  lblVersaoApp.Text := VERSAO_APP_TEXTO;
  CarregarDados;

  if Assigned(vsbConta) then
    vsbConta.ViewportPosition := PointF(0, 0);
end;

procedure TfraContaMobile.CarregarDados;
var
  LCliente: TClienteLocal;
begin
  LCliente := TClienteLocal.Create;

  try
    LCliente.Carregar;

    edtNome.Text := LCliente.Nome;
    edtTelefone.Text := LCliente.Telefone;

    edtCEP.Text := LCliente.Cep;
    edtRua.Text := LCliente.Endereco;
    edtNumero.Text := LCliente.Numero;
    edtBairro.Text := LCliente.Bairro;
    edtComplemento.Text := LCliente.Complemento;
    edtCidade.Text := LCliente.Cidade;
    edtUF.Text := UpperCase(Trim(LCliente.UF));
    edtServidorAPI.Text := TApiConfig.BaseUrl;

  finally
    LCliente.Free;
  end;

  if Trim(edtTelefone.Text).IsEmpty then
    TTelefoneDispositivo.Obter(
      procedure(const ATelefone:string)
      begin
        if Trim(edtTelefone.Text).IsEmpty and not ATelefone.IsEmpty then
          edtTelefone.Text:=ATelefone;
      end);
end;

procedure TfraContaMobile.SalvarDados;
var
  LCliente: TClienteLocal;
begin
  try
    TApiConfig.DefinirBaseUrl(Trim(edtServidorAPI.Text));
  except
    on E: Exception do
    begin
      TMensagemMobile.Exibir(E.Message);
      edtServidorAPI.SetFocus;
      Exit;
    end;
  end;

  if Trim(edtNome.Text).IsEmpty then
  begin
    TMensagemMobile.Exibir('Informe seu nome.');
    edtNome.SetFocus;
    Exit;
  end;

  if Trim(edtTelefone.Text).IsEmpty then
  begin
    TMensagemMobile.Exibir('Informe seu telefone ou WhatsApp.');
    edtTelefone.SetFocus;
    Exit;
  end;

  LCliente := TClienteLocal.Create;

  try
    LCliente.Nome := Trim(edtNome.Text);
    LCliente.Telefone := Trim(edtTelefone.Text);

    LCliente.Cep := Trim(edtCEP.Text);
    LCliente.Endereco := Trim(edtRua.Text);
    LCliente.Numero := Trim(edtNumero.Text);
    LCliente.Bairro := Trim(edtBairro.Text);
    LCliente.Complemento := Trim(edtComplemento.Text);
    LCliente.Cidade := Trim(edtCidade.Text);
    if Trim(edtUF.Text) <> '' then
    begin
      if Length(Trim(edtUF.Text)) <> 2 then
      begin
        TMensagemMobile.Exibir('Informe a UF com 2 letras.');
        edtUF.SetFocus;
        Exit;
      end;
    end;

    edtUF.Text := UpperCase(Trim(edtUF.Text));
    LCliente.UF := edtUF.Text;

    LCliente.Salvar;

    TMensagemMobile.Exibir(
      'Dados salvos com sucesso.',
      tmSucesso
    );

  finally
    LCliente.Free;
  end;
end;

procedure TfraContaMobile.rctSalvarClick(
  Sender: TObject);
begin
  SalvarDados;
end;

end.
