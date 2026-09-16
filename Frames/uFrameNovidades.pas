unit uFrameNovidades;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Objects,
  FMX.Layouts, FMX.StdCtrls, FMX.Controls.Presentation;

type
  TfraNovidades = class(TFrame)
  private
    FConteudo: TVertScrollBox;
    procedure CriarCabecalho;
    procedure AdicionarVersao(const AVersao, AData, AResumo: string;
      const AItens: array of string; const AAtual: Boolean = False);
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  uVersaoSistema;

constructor TfraNovidades.Create(AOwner: TComponent);
begin
  inherited;
  Align := TAlignLayout.Client;

  FConteudo := TVertScrollBox.Create(Self);
  FConteudo.Parent := Self;
  FConteudo.Align := TAlignLayout.Client;
  FConteudo.Padding.Rect := RectF(24, 18, 24, 24);
  FConteudo.ShowScrollBars := True;

  CriarCabecalho;
  AdicionarVersao(VERSAO_SISTEMA, '24/08/2026',
    'Identificação das versões e histórico de melhorias.', [
      'Número da versão visível no painel administrativo e no aplicativo móvel.',
      'Nova tela Novidades, com as alterações organizadas por versão.',
      'Dados do novo pedido carregados dinamicamente pela API.'
    ], True);
  AdicionarVersao('1.1.3', '24/08/2026',
    'Cardápio administrativo sem dados demonstrativos fixos.', [
      'Categorias, produtos, tamanhos, sabores, bordas e adicionais vindos do banco.',
      'Taxa de entrega obtida da configuração da empresa.',
      'Pacote de reinstalação limpa atualizado.'
    ]);
  AdicionarVersao('1.1.2', '22/08/2026',
    'Aprimoramentos no instalador completo.', [
      'Correção da restauração do banco inicial.',
      'Tratamento de instalações existentes e nomes do PostgreSQL.'
    ]);
  AdicionarVersao('1.1.1', '22/08/2026',
    'Instalação automatizada para o computador do cliente.', [
      'PostgreSQL, banco inicial, API e serviço do Windows configurados pelo instalador.',
      'Atalho do painel administrativo criado automaticamente.'
    ]);
  AdicionarVersao('1.1.0', '21/08/2026',
    'Segurança, operação e pagamentos.', [
      'Login, usuários, empresas e permissões por módulo e operação.',
      'Alertas de novos pedidos e configuração do som.',
      'Fluxo PIX e integrações de pagamento.'
    ]);
  AdicionarVersao('1.0.0', '20/08/2026',
    'Primeira versão operacional do Sensor Delivery.', [
      'Central de pedidos, clientes, cardápio e entregadores.',
      'Aplicativo móvel para montagem e acompanhamento dos pedidos.'
    ]);
end;

procedure TfraNovidades.CriarCabecalho;
var
  Cabecalho: TLayout;
  Rotulo: TLabel;
begin
  Cabecalho := TLayout.Create(Self);
  Cabecalho.Parent := FConteudo;
  Cabecalho.Align := TAlignLayout.Top;
  Cabecalho.Position.Y := 10000;
  Cabecalho.Height := 104;
  Cabecalho.Margins.Bottom := 14;

  Rotulo := TLabel.Create(Self);
  Rotulo.Parent := Cabecalho;
  Rotulo.Position.Point := PointF(0, 4);
  Rotulo.Width := 520;
  Rotulo.Height := 36;
  Rotulo.Text := 'Novidades e versões';
  Rotulo.StyledSettings := [];
  Rotulo.TextSettings.Font.Family := 'Manrope';
  Rotulo.TextSettings.Font.Size := 24;
  Rotulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  Rotulo.TextSettings.FontColor := $FFF4F7FB;

  Rotulo := TLabel.Create(Self);
  Rotulo.Parent := Cabecalho;
  Rotulo.Position.Point := PointF(0, 45);
  Rotulo.Width := 650;
  Rotulo.Height := 24;
  Rotulo.Text := 'Acompanhe as melhorias entregues no Sensor Delivery.';
  Rotulo.StyledSettings := [];
  Rotulo.TextSettings.Font.Family := 'Manrope';
  Rotulo.TextSettings.Font.Size := 11;
  Rotulo.TextSettings.FontColor := $FF9CAABC;

  Rotulo := TLabel.Create(Self);
  Rotulo.Parent := Cabecalho;
  Rotulo.Position.Point := PointF(0, 75);
  Rotulo.Width := 210;
  Rotulo.Height := 24;
  Rotulo.Text := 'Versão instalada: ' + VERSAO_SISTEMA;
  Rotulo.StyledSettings := [];
  Rotulo.TextSettings.Font.Family := 'Manrope';
  Rotulo.TextSettings.Font.Size := 11;
  Rotulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  Rotulo.TextSettings.FontColor := $FF9B6CFF;
end;

procedure TfraNovidades.AdicionarVersao(const AVersao, AData, AResumo: string;
  const AItens: array of string; const AAtual: Boolean);
var
  Cartao: TRectangle;
  Rotulo: TLabel;
  I: Integer;
  TextoItens: string;
begin
  TextoItens := '';
  for I := Low(AItens) to High(AItens) do
  begin
    if TextoItens <> '' then
      TextoItens := TextoItens + sLineBreak;
    TextoItens := TextoItens + '  •  ' + AItens[I];
  end;

  Cartao := TRectangle.Create(Self);
  Cartao.Parent := FConteudo;
  Cartao.Align := TAlignLayout.Top;
  Cartao.Position.Y := 10000;
  Cartao.Width := 900;
  Cartao.Height := 104 + (Length(AItens) * 23);
  Cartao.Margins.Bottom := 12;
  Cartao.Fill.Color := $FF132238;
  Cartao.Stroke.Color := $FF29415E;
  Cartao.XRadius := 10;
  Cartao.YRadius := 10;

  Rotulo := TLabel.Create(Self);
  Rotulo.Parent := Cartao;
  Rotulo.Position.Point := PointF(18, 14);
  Rotulo.Width := 240;
  Rotulo.Height := 25;
  Rotulo.Text := 'Versão ' + AVersao;
  if AAtual then
    Rotulo.Text := Rotulo.Text + '  •  ATUAL';
  Rotulo.StyledSettings := [];
  Rotulo.TextSettings.Font.Family := 'Manrope';
  Rotulo.TextSettings.Font.Size := 15;
  Rotulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  if AAtual then
    Rotulo.TextSettings.FontColor := $FF9B6CFF
  else
    Rotulo.TextSettings.FontColor := $FFF4F7FB;

  Rotulo := TLabel.Create(Self);
  Rotulo.Parent := Cartao;
  Rotulo.Position.Point := PointF(Cartao.Width - 140, 16);
  Rotulo.Anchors := [TAnchorKind.akTop, TAnchorKind.akRight];
  Rotulo.Width := 120;
  Rotulo.Height := 22;
  Rotulo.Text := AData;
  Rotulo.StyledSettings := [];
  Rotulo.TextSettings.HorzAlign := TTextAlign.Trailing;
  Rotulo.TextSettings.Font.Family := 'Manrope';
  Rotulo.TextSettings.Font.Size := 10;
  Rotulo.TextSettings.FontColor := $FF8391A5;

  Rotulo := TLabel.Create(Self);
  Rotulo.Parent := Cartao;
  Rotulo.Position.Point := PointF(18, 46);
  Rotulo.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akRight];
  Rotulo.Width := Cartao.Width - 36;
  Rotulo.Height := 23;
  Rotulo.Text := AResumo;
  Rotulo.StyledSettings := [];
  Rotulo.TextSettings.Font.Family := 'Manrope';
  Rotulo.TextSettings.Font.Size := 11;
  Rotulo.TextSettings.FontColor := $FFD5DCE6;

  Rotulo := TLabel.Create(Self);
  Rotulo.Parent := Cartao;
  Rotulo.Position.Point := PointF(18, 76);
  Rotulo.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akRight];
  Rotulo.Width := Cartao.Width - 36;
  Rotulo.Height := Length(AItens) * 23 + 8;
  Rotulo.Text := TextoItens;
  Rotulo.StyledSettings := [];
  Rotulo.TextSettings.Font.Family := 'Manrope';
  Rotulo.TextSettings.Font.Size := 10.5;
  Rotulo.TextSettings.FontColor := $FF9CAABC;
  Rotulo.TextSettings.WordWrap := True;
end;

end.
