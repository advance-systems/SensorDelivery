unit uMensagem;

interface

uses
  System.SysUtils,
  System.Classes,
  System.UITypes,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Objects,
  FMX.StdCtrls, FMX.Controls.Presentation;

type
  TTipoMensagem = (
    tmInformacao,
    tmSucesso,
    tmAtencao,
    tmErro,
    tmConfirmacao
  );

  TfrmMensagem = class(TForm)
    rctFundo: TRectangle;
    rctMensagem: TRectangle;
    crcIcone: TCircle;
    lblTitulo: TLabel;
    lblMensagem: TLabel;
    rctBotaoCancelar: TRectangle;
    lblCancelar: TLabel;
    rctBotaoConfirmar: TRectangle;
    lblConfirmar: TLabel;
    pthIcone: TPath;
    procedure rctBotaoCancelarClick(Sender: TObject);
    procedure rctBotaoConfirmarClick(Sender: TObject);
  private
    procedure ConfigurarTipo(const ATipo: TTipoMensagem);
  public
    class function Exibir(
      const ATitulo: string;
      const AMensagem: string;
      const ATipo: TTipoMensagem = tmInformacao;
      const AExibirCancelar: Boolean = False;
      const ATextoConfirmar: string = 'OK';
      const ATextoCancelar: string = 'Cancelar'
    ): Boolean;
  end;

implementation

{$R *.fmx}

uses uSensorIcons;

procedure TfrmMensagem.ConfigurarTipo(const ATipo: TTipoMensagem);
begin
  rctBotaoConfirmar.Enabled := True;
  rctBotaoConfirmar.Opacity := 1;

  case ATipo of
    tmInformacao:
      begin
        crcIcone.Fill.Color := $3343A5FF;
        rctBotaoConfirmar.Fill.Color := $FF43A5FF;

        TSensorIcon.Informacao(
          pthIcone,
          $FF43A5FF
        );
      end;

    tmSucesso:
      begin
        crcIcone.Fill.Color := $3336D276;
        rctBotaoConfirmar.Fill.Color := $FF36D276;

        TSensorIcon.Sucesso(
          pthIcone,
          $FF36D276
        );
      end;

    tmAtencao:
      begin
        crcIcone.Fill.Color := $33FFA21A;
        rctBotaoConfirmar.Fill.Color := $FFFFA21A;

        TSensorIcon.Atencao(
          pthIcone,
          $FFFFA21A
        );
      end;

    tmErro:
      begin
        crcIcone.Fill.Color := $33FF5A65;
        rctBotaoConfirmar.Fill.Color := $FFFF5A65;

        TSensorIcon.Erro(
          pthIcone,
          $FFFF5A65
        );
      end;

    tmConfirmacao:
      begin
        crcIcone.Fill.Color := $339B6CFF;
        rctBotaoConfirmar.Fill.Color := $FF9B6CFF;

        TSensorIcon.Confirmacao(
          pthIcone,
          $FF9B6CFF
        );
      end;
  end;
end;

class function TfrmMensagem.Exibir(
  const ATitulo: string;
  const AMensagem: string;
  const ATipo: TTipoMensagem;
  const AExibirCancelar: Boolean;
  const ATextoConfirmar: string;
  const ATextoCancelar: string): Boolean;
var
  LForm: TfrmMensagem;
begin
  LForm := TfrmMensagem.Create(nil);
  try
    LForm.lblTitulo.Text := ATitulo;
    LForm.lblMensagem.Text := AMensagem;
    LForm.lblConfirmar.Text := ATextoConfirmar;
    LForm.lblCancelar.Text := ATextoCancelar;

    LForm.rctBotaoCancelar.Visible := AExibirCancelar;
    LForm.ConfigurarTipo(ATipo);

    Result := LForm.ShowModal = mrOk;
  finally
    LForm.Free;
  end;
end;

procedure TfrmMensagem.rctBotaoCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmMensagem.rctBotaoConfirmarClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

end.
