unit uMensagemMobile;

interface

type
  TRespostaMensagemMobile = reference to procedure(
    const AConfirmado: Boolean
  );

  TTipoMensagemMobile = (
    tmInformacao,
    tmSucesso,
    tmAviso,
    tmErro
  );

  TMensagemMobile = class
  private
    class var FSobreposicao: TObject;
    class procedure Fechar(Sender: TObject); static;
    class procedure Criar(
      const AMensagem: string;
      const ATipo: TTipoMensagemMobile;
      const ATitulo: string;
      const AConfirmacao: Boolean;
      const AOnResposta: TRespostaMensagemMobile;
      const ATextoConfirmar: string;
      const ATextoCancelar: string
    ); static;
  public
    class procedure Exibir(
      const AMensagem: string;
      const ATipo: TTipoMensagemMobile = tmAviso;
      const ATitulo: string = ''
    ); static;
    class procedure Confirmar(
      const AMensagem: string;
      const AOnResposta: TRespostaMensagemMobile;
      const ATitulo: string = 'Confirmacao';
      const ATextoConfirmar: string = 'Confirmar';
      const ATextoCancelar: string = 'Cancelar'
    ); static;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  System.UITypes,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Objects,
  FMX.Layouts,
  FMX.StdCtrls,
  FMX.Ani,
  uConstantes;

type
  TAcaoMensagemMobile = class(TComponent)
  private
    FOnResposta: TRespostaMensagemMobile;
    procedure Responder(const AConfirmado: Boolean; Sender: TObject);
  public
    procedure Fechar(Sender: TObject);
    procedure Confirmar(Sender: TObject);
    procedure Cancelar(Sender: TObject);
    property OnResposta: TRespostaMensagemMobile
      read FOnResposta write FOnResposta;
  end;

procedure TAcaoMensagemMobile.Fechar(Sender: TObject);
begin
  TMensagemMobile.Fechar(Sender);
end;

procedure TAcaoMensagemMobile.Responder(
  const AConfirmado: Boolean;
  Sender: TObject);
var
  LOnResposta: TRespostaMensagemMobile;
begin
  LOnResposta := FOnResposta;
  TMensagemMobile.Fechar(Sender);

  if Assigned(LOnResposta) then
    LOnResposta(AConfirmado);
end;

procedure TAcaoMensagemMobile.Confirmar(Sender: TObject);
begin
  Responder(True, Sender);
end;

procedure TAcaoMensagemMobile.Cancelar(Sender: TObject);
begin
  Responder(False, Sender);
end;

class procedure TMensagemMobile.Fechar(Sender: TObject);
var
  LSobreposicao: TLayout;
begin
  if not (FSobreposicao is TLayout) then
    Exit;

  LSobreposicao := TLayout(FSobreposicao);
  FSobreposicao := nil;
  LSobreposicao.Enabled := False;
  LSobreposicao.Opacity := 0;

  TThread.ForceQueue(nil,
    procedure
    begin
      LSobreposicao.Free;
    end
  );
end;

class procedure TMensagemMobile.Criar(
  const AMensagem: string;
  const ATipo: TTipoMensagemMobile;
  const ATitulo: string;
  const AConfirmacao: Boolean;
  const AOnResposta: TRespostaMensagemMobile;
  const ATextoConfirmar: string;
  const ATextoCancelar: string);
var
  LForm: TCommonCustomForm;
  LSobreposicao: TLayout;
  LFundo: TRectangle;
  LCartao: TRectangle;
  LCirculo: TCircle;
  LIcone: TLabel;
  LTitulo: TLabel;
  LMensagem: TLabel;
  LBotao: TRectangle;
  LTextoBotao: TLabel;
  LBotaoSecundario: TRectangle;
  LTextoBotaoSecundario: TLabel;
  LAcao: TAcaoMensagemMobile;
  LCorDestaque: TAlphaColor;
  LIconeTexto: string;
  LTituloTexto: string;
  LAlturaCartao: Single;
begin
  LForm := Application.MainForm;
  if not Assigned(LForm) then
    Exit;

  if FSobreposicao is TLayout then
    TLayout(FSobreposicao).Free;
  FSobreposicao := nil;

  case ATipo of
    tmInformacao:
      begin
        LCorDestaque := COR_PRIMARIA;
        LIconeTexto := 'i';
        LTituloTexto := 'Informa' + Char($00E7) + Char($00E3) + 'o';
      end;
    tmSucesso:
      begin
        LCorDestaque := COR_SUCESSO;
        LIconeTexto := #10003;
        LTituloTexto := 'Tudo certo!';
      end;
    tmErro:
      begin
        LCorDestaque := COR_ERRO;
        LIconeTexto := #215;
        LTituloTexto := 'Algo deu errado';
      end;
  else
    begin
      LCorDestaque := COR_ALERTA;
      LIconeTexto := '!';
      LTituloTexto := 'Aten' + Char($00E7) + Char($00E3) + 'o';
    end;
  end;

  if not ATitulo.Trim.IsEmpty then
    LTituloTexto := ATitulo.Trim;

  LAlturaCartao := 286;
  if (Length(AMensagem) > 100) or AMensagem.Contains(sLineBreak) then
    LAlturaCartao := 330;
  if Length(AMensagem) > 220 then
    LAlturaCartao := 380;
  if AConfirmacao then
    LAlturaCartao := Max(LAlturaCartao, 306);
  LAlturaCartao := Min(LAlturaCartao, LForm.Height - 48);

  LSobreposicao := TLayout.Create(LForm);
  LSobreposicao.Parent := LForm;
  LSobreposicao.Align := TAlignLayout.Contents;
  LSobreposicao.HitTest := True;
  LSobreposicao.Opacity := 0;
  FSobreposicao := LSobreposicao;

  LFundo := TRectangle.Create(LSobreposicao);
  LFundo.Parent := LSobreposicao;
  LFundo.Align := TAlignLayout.Contents;
  LFundo.Fill.Color := $B3121726;
  LFundo.Stroke.Kind := TBrushKind.None;
  LFundo.HitTest := True;

  LCartao := TRectangle.Create(LSobreposicao);
  LCartao.Parent := LSobreposicao;
  LCartao.Align := TAlignLayout.Center;
  LCartao.Width := Min(350, Max(280, LForm.Width - 40));
  LCartao.Height := LAlturaCartao;
  LCartao.Fill.Color := COR_CARD;
  LCartao.Stroke.Color := COR_BORDA;
  LCartao.Stroke.Thickness := 1;
  LCartao.XRadius := 24;
  LCartao.YRadius := 24;
  LCartao.HitTest := True;

  LCirculo := TCircle.Create(LCartao);
  LCirculo.Parent := LCartao;
  LCirculo.Position.X := (LCartao.Width - 58) / 2;
  LCirculo.Position.Y := 24;
  LCirculo.Width := 58;
  LCirculo.Height := 58;
  LCirculo.Fill.Color := LCorDestaque;
  LCirculo.Stroke.Kind := TBrushKind.None;
  LCirculo.HitTest := False;

  LIcone := TLabel.Create(LCirculo);
  LIcone.Parent := LCirculo;
  LIcone.Align := TAlignLayout.Contents;
  LIcone.StyledSettings := [];
  LIcone.TextSettings.Font.Size := 28;
  LIcone.TextSettings.FontColor := TAlphaColors.White;
  LIcone.TextSettings.Font.Style := [TFontStyle.fsBold];
  LIcone.TextSettings.HorzAlign := TTextAlign.Center;
  LIcone.TextSettings.VertAlign := TTextAlign.Center;
  LIcone.Text := LIconeTexto;
  LIcone.HitTest := False;

  LTitulo := TLabel.Create(LCartao);
  LTitulo.Parent := LCartao;
  LTitulo.Position.X := 24;
  LTitulo.Position.Y := 94;
  LTitulo.Width := LCartao.Width - 48;
  LTitulo.Height := 30;
  LTitulo.StyledSettings := [];
  LTitulo.TextSettings.Font.Size := 20;
  LTitulo.TextSettings.FontColor := COR_TEXTO;
  LTitulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  LTitulo.TextSettings.HorzAlign := TTextAlign.Center;
  LTitulo.Text := LTituloTexto;
  LTitulo.HitTest := False;

  LMensagem := TLabel.Create(LCartao);
  LMensagem.Parent := LCartao;
  LMensagem.Position.X := 28;
  LMensagem.Position.Y := 132;
  LMensagem.Width := LCartao.Width - 56;
  LMensagem.Height := LCartao.Height - 216;
  LMensagem.StyledSettings := [];
  LMensagem.TextSettings.Font.Size := 14;
  LMensagem.TextSettings.FontColor := COR_TEXTO_SECUNDARIO;
  LMensagem.TextSettings.HorzAlign := TTextAlign.Center;
  LMensagem.TextSettings.VertAlign := TTextAlign.Leading;
  LMensagem.TextSettings.WordWrap := True;
  LMensagem.Text := AMensagem.Trim;
  LMensagem.HitTest := False;

  LBotao := TRectangle.Create(LCartao);
  LBotao.Parent := LCartao;
  LBotao.Position.X := 24;
  LBotao.Position.Y := LCartao.Height - 68;
  LBotao.Width := LCartao.Width - 48;
  LBotao.Height := 46;
  LBotao.Fill.Color := COR_PRIMARIA;
  LBotao.Stroke.Kind := TBrushKind.None;
  LBotao.XRadius := 14;
  LBotao.YRadius := 14;
  LBotao.Cursor := crHandPoint;
  LAcao := TAcaoMensagemMobile.Create(LSobreposicao);
  LAcao.OnResposta := AOnResposta;

  if AConfirmacao then
  begin
    LBotao.Position.X := (LCartao.Width / 2) + 5;
    LBotao.Width := (LCartao.Width - 58) / 2;
    LBotao.OnClick := LAcao.Confirmar;
  end
  else
    LBotao.OnClick := LAcao.Fechar;

  LTextoBotao := TLabel.Create(LBotao);
  LTextoBotao.Parent := LBotao;
  LTextoBotao.Align := TAlignLayout.Contents;
  LTextoBotao.StyledSettings := [];
  LTextoBotao.TextSettings.Font.Size := 14;
  LTextoBotao.TextSettings.FontColor := TAlphaColors.White;
  LTextoBotao.TextSettings.Font.Style := [TFontStyle.fsBold];
  LTextoBotao.TextSettings.HorzAlign := TTextAlign.Center;
  LTextoBotao.TextSettings.VertAlign := TTextAlign.Center;
  if AConfirmacao then
    LTextoBotao.Text := ATextoConfirmar
  else
    LTextoBotao.Text := 'Entendi';
  LTextoBotao.HitTest := False;

  if AConfirmacao then
  begin
    LBotaoSecundario := TRectangle.Create(LCartao);
    LBotaoSecundario.Parent := LCartao;
    LBotaoSecundario.Position.X := 24;
    LBotaoSecundario.Position.Y := LCartao.Height - 68;
    LBotaoSecundario.Width := (LCartao.Width - 58) / 2;
    LBotaoSecundario.Height := 46;
    LBotaoSecundario.Fill.Color := COR_CARD;
    LBotaoSecundario.Stroke.Color := COR_BORDA;
    LBotaoSecundario.Stroke.Thickness := 1;
    LBotaoSecundario.XRadius := 14;
    LBotaoSecundario.YRadius := 14;
    LBotaoSecundario.Cursor := crHandPoint;
    LBotaoSecundario.OnClick := LAcao.Cancelar;

    LTextoBotaoSecundario := TLabel.Create(LBotaoSecundario);
    LTextoBotaoSecundario.Parent := LBotaoSecundario;
    LTextoBotaoSecundario.Align := TAlignLayout.Contents;
    LTextoBotaoSecundario.StyledSettings := [];
    LTextoBotaoSecundario.TextSettings.Font.Size := 14;
    LTextoBotaoSecundario.TextSettings.FontColor := COR_TEXTO;
    LTextoBotaoSecundario.TextSettings.Font.Style := [TFontStyle.fsBold];
    LTextoBotaoSecundario.TextSettings.HorzAlign := TTextAlign.Center;
    LTextoBotaoSecundario.TextSettings.VertAlign := TTextAlign.Center;
    LTextoBotaoSecundario.Text := ATextoCancelar;
    LTextoBotaoSecundario.HitTest := False;
  end;

  LSobreposicao.BringToFront;
  TAnimator.AnimateFloat(
    LSobreposicao,
    'Opacity',
    1,
    0.18,
    TAnimationType.InOut,
    TInterpolationType.Quadratic
  );
end;

class procedure TMensagemMobile.Exibir(
  const AMensagem: string;
  const ATipo: TTipoMensagemMobile;
  const ATitulo: string);
begin
  Criar(
    AMensagem,
    ATipo,
    ATitulo,
    False,
    nil,
    '',
    ''
  );
end;

class procedure TMensagemMobile.Confirmar(
  const AMensagem: string;
  const AOnResposta: TRespostaMensagemMobile;
  const ATitulo: string;
  const ATextoConfirmar: string;
  const ATextoCancelar: string);
var
  LTituloSeguro: string;
begin
  LTituloSeguro := ATitulo;
  if SameText(LTituloSeguro, 'Confirmacao') then
    LTituloSeguro := 'Confirma' + Char($00E7) + Char($00E3) + 'o';
  Criar(
    AMensagem,
    tmAviso,
    LTituloSeguro,
    True,
    AOnResposta,
    ATextoConfirmar,
    ATextoCancelar
  );
end;

end.
