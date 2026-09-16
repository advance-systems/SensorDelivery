unit uFramePedidos;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Layouts, FMX.Controls.Presentation, FMX.Edit, uSensorIcons,
  uFrameItemPedido, uFrameItemProduto, uMensagem, FMX.Ani, uFramePopupMenu;

type
  TfraPedidos = class(TFrame)
    lytPrincipal: TLayout;
    lytItensPedidos: TLayout;
    rctMenuAcoes: TRectangle;
    rctVerDetalhes: TRectangle;
    rctAlterarStatus: TRectangle;
    rctImprimir: TRectangle;
    rctCancelar: TRectangle;
    rctOverlayDetalhes: TRectangle;
    rctPainelDetalhes: TRectangle;
    lytTopoDetalhes: TLayout;
    lblTituloDetalhes: TLabel;
    rctFecharDetalhes: TRectangle;
    pthFecharDetalhes: TPath;
    vsbDetalhes: TVertScrollBox;
    lytConteudoDetalhes: TLayout;
    rctResumoPedido: TRectangle;
    lblDetalheNumero: TLabel;
    lblDetalheHorario: TLabel;
    rctDetalheStatus: TRectangle;
    lblDetalheStatus: TLabel;
    rctDetalheCliente: TRectangle;
    lblTituloCliente: TLabel;
    lblDetalheCliente: TLabel;
    lblDetalheTelefone: TLabel;
    rctDetalheEntrega: TRectangle;
    lblTituloEntrega: TLabel;
    lblDetalheTipo: TLabel;
    lblDetalheEndereco: TLabel;
    rctDetalheValores: TRectangle;
    lblSubtotalTitulo: TLabel;
    lblSubtotalValor: TLabel;
    lblTaxaTitulo: TLabel;
    lblTaxaValor: TLabel;
    linValores: TLine;
    lblTotalTitulo: TLabel;
    lblDetalheTotal: TLabel;
    rctProdutos: TRectangle;
    lblTituloProdutos: TLabel;
    vsbProdutos: TVertScrollBox;
    lytProdutos: TLayout;
    lblDescontoTitulo: TLabel;
    lblDescontoValor: TLabel;
    lytSubtotal: TLayout;
    lytTaxaEntrega: TLayout;
    lytDesconto: TLayout;
    lytTotal: TLayout;
    lytRodapeDetalhes: TLayout;
    rctFundoRodape: TRectangle;
    rctAlterarStatusDetalhe: TRectangle;
    lblAlterarStatusDetalhe: TLabel;
    rctImprimirDetalhe: TRectangle;
    lblImprimirPedido: TLabel;
    rctCancelarDetalhe: TRectangle;
    lblCancelarDetalhe: TLabel;
    rctMenuStatus: TRectangle;
    rctStatusNovo: TRectangle;
    lblStatusNovo: TLabel;
    rctStatusConfirmado: TRectangle;
    lblStatusConfirmado: TLabel;
    RectAnimation1: TRectAnimation;
    rctStatusEmPreparo: TRectangle;
    lblStatusEmPreparo: TLabel;
    rctStatusPronto: TRectangle;
    lblStatusPronto: TLabel;
    rctStatusEmEntrega: TRectangle;
    lblStatusEmEntrega: TLabel;
    rctStatusFinalizado: TRectangle;
    lblStatusFinalizado: TLabel;

    procedure rctVerDetalhesClick(Sender: TObject);
    procedure rctAlterarStatusClick(Sender: TObject);
    procedure rctImprimirClick(Sender: TObject);
    procedure rctCancelarClick(Sender: TObject);

    procedure ItemMenuMouseEnter(Sender: TObject);
    procedure ItemMenuMouseLeave(Sender: TObject);
    procedure rctFecharDetalhesClick(Sender: TObject);
    procedure rctAlterarStatusDetalheClick(Sender: TObject);
    procedure rctImprimirDetalheClick(Sender: TObject);
    procedure rctCancelarDetalheClick(Sender: TObject);
    procedure BotaoAlterarMouseEnter(Sender: TObject);
    procedure BotaoAlterarMouseLeave(Sender: TObject);
    procedure BotaoSecundarioMouseEnter(Sender: TObject);
    procedure BotaoSecundarioMouseLeave(Sender: TObject);
    procedure BotaoCancelarMouseEnter(Sender: TObject);
    procedure BotaoCancelarMouseLeave(Sender: TObject);
    procedure StatusMouseEnter(Sender: TObject);
    procedure StatusMouseLeave(Sender: TObject);
    procedure rctStatusNovoClick(Sender: TObject);
    procedure rctStatusConfirmadoClick(Sender: TObject);
    procedure rctStatusEmPreparoClick(Sender: TObject);
    procedure rctStatusProntoClick(Sender: TObject);
    procedure rctStatusEmEntregaClick(Sender: TObject);
    procedure rctStatusFinalizadoClick(Sender: TObject);
  private
    FItemPedidoSelecionado: TfraItemPedido;
    FPopupStatus: TfraPopupMenu;

    procedure PedidoAcoesClick(Sender: TObject);
    procedure AbrirMenuAcoes(const AItem: TfraItemPedido);
    procedure FecharMenuAcoes;
    procedure AdicionarPedido(const ANumero: string; const ACliente: string; const ATelefone: string;
      const ATipo: string; const AStatus: string; const AHorario: string; const AEndereco: string; const ATotal: Currency);
    procedure CarregarPedidosTeste;
    procedure AbrirDetalhesPedido;
    procedure FecharDetalhesPedido;
    procedure LimparProdutos;
    procedure AdicionarProduto(const AQuantidade: Integer; const ADescricao: string;
      const AComplementos: string; const AValor: Currency);
    procedure CarregarProdutosTeste;
    procedure PreencherDetalhesEntrega;
    procedure AbrirMenuStatus;
    procedure FecharMenuStatus;
    procedure AplicarStatusSelecionado(const AStatus: string);
    procedure CriarPopupStatus;
    procedure PopupStatusItemClick(Sender: TObject; const AIdentificador: string);
  public
    constructor Create(AOwner: TComponent); override;

    procedure PrepararTela;
  end;
implementation

{$R *.fmx}

procedure TfraPedidos.AdicionarPedido(const ANumero, ACliente, ATelefone, ATipo,
  AStatus, AHorario: string; const AEndereco: string; const ATotal: Currency);
var
  LItem: TfraItemPedido;
begin
  LItem := TfraItemPedido.Create(nil);
  LItem.Name := '';

  LItem.Parent := lytItensPedidos;
  LItem.Align := TAlignLayout.Top;
  LItem.Height := 72;
  LItem.Margins.Bottom := 8;

  LItem.Preencher(
    ANumero,
    ACliente,
    ATelefone,
    ATipo,
    AStatus,
    AHorario,
    AEndereco,
    ATotal
  );

  LItem.OnAcoesClick := PedidoAcoesClick;

  lytItensPedidos.Height :=
    lytItensPedidos.Height +
    LItem.Height +
    LItem.Margins.Bottom;
end;

procedure TfraPedidos.CarregarPedidosTeste;
begin
  lytItensPedidos.Height := 0;

  AdicionarPedido(
    '#1048',
    'João da Silva',
    '(47) 99912-3456',
    'Delivery',
    'Novo',
    '19:32',
    'Rua das Flores, 120 - Centro',
    84.90
  );

  AdicionarPedido(
    '#1047',
    'Mariana Souza',
    '(47) 98845-1122',
    'Retirada',
    'Em preparo',
    '19:24',
    '',
    56.00
  );

  AdicionarPedido(
    '#1046',
    'Carlos Mendes',
    '(47) 99671-4432',
    'Delivery',
    'Pronto',
    '19:10',
    'Rua das Flores, 120 - Centro',
    112.50
  );

  AdicionarPedido(
    '#1045',
    'Fernanda Lima',
    '(47) 99106-7788',
    'Delivery',
    'Em entrega',
    '18:58',
    '',
    73.40
  );

  AdicionarPedido(
    '#1044',
    'Ricardo Alves',
    '(47) 98431-5566',
    'Retirada',
    'Finalizado',
    '18:42',
    'Rua das Flores, 120 - Centro',
    49.90
  );
end;

procedure TfraPedidos.PedidoAcoesClick(Sender: TObject);
begin
  if not (Sender is TfraItemPedido) then
    Exit;

  AbrirMenuAcoes(TfraItemPedido(Sender));
end;

procedure TfraPedidos.AbrirMenuAcoes(const AItem: TfraItemPedido);
var
  LPonto: TPointF;
begin
  if not Assigned(AItem) then
    Exit;

  FItemPedidoSelecionado := AItem;

  LPonto := AItem.rctAcoes.LocalToAbsolute(
    PointF(
      AItem.rctAcoes.Width,
      AItem.rctAcoes.Height
    )
  );

  LPonto := lytPrincipal.AbsoluteToLocal(LPonto);

  rctMenuAcoes.Position.X :=
    LPonto.X - rctMenuAcoes.Width;

  rctMenuAcoes.Position.Y :=
    LPonto.Y + 4;

  rctMenuAcoes.BringToFront;
  rctMenuAcoes.Visible := True;
end;

procedure TfraPedidos.FecharMenuAcoes;
begin
  rctMenuAcoes.Visible := False;
end;

procedure TfraPedidos.AbrirDetalhesPedido;
begin
  if not Assigned(FItemPedidoSelecionado) then
    Exit;

  lblDetalheNumero.Text :=
    'Pedido ' + FItemPedidoSelecionado.NumeroPedido;

  lblDetalheCliente.Text :=
    FItemPedidoSelecionado.Cliente;

  lblDetalheTelefone.Text :=
    FItemPedidoSelecionado.Telefone;

  lblDetalheTipo.Text :=
    FItemPedidoSelecionado.TipoPedido;

  lblDetalheStatus.Text :=
    FItemPedidoSelecionado.StatusPedido;

  lblDetalheHorario.Text :=
    'Horário: ' + FItemPedidoSelecionado.Horario;

  lblDetalheEndereco.Text :=
    'Endereço ainda não informado';

  lblSubtotalValor.Text :=
    FormatFloat(
      '"R$ " #,##0.00',
      FItemPedidoSelecionado.Total
    );

  lblTaxaValor.Text := 'R$ 0,00';

  lblDetalheTotal.Text :=
    FItemPedidoSelecionado.TotalFormatado;

  CarregarProdutosTeste;
  PreencherDetalhesEntrega;
  FecharMenuAcoes;

  vsbDetalhes.ViewportPosition := PointF(0, 0);
  rctOverlayDetalhes.BringToFront;
  rctOverlayDetalhes.Visible := True;
end;

procedure TfraPedidos.FecharDetalhesPedido;
begin
  rctOverlayDetalhes.Visible := False;
end;

constructor TfraPedidos.Create(AOwner: TComponent);
begin
  inherited;

  rctOverlayDetalhes.Visible := False;
  rctMenuAcoes.Visible := False;

  CriarPopupStatus;
  CarregarPedidosTeste;
end;

procedure TfraPedidos.LimparProdutos;
var
  I: Integer;
begin
  for I := lytProdutos.ChildrenCount - 1 downto 0 do
    lytProdutos.Children[I].Free;

  lytProdutos.Height := 0;
end;

procedure TfraPedidos.AdicionarProduto(
  const AQuantidade: Integer;
  const ADescricao: string;
  const AComplementos: string;
  const AValor: Currency);
var
  LItem: TfraItemProduto;
begin
  LItem := TfraItemProduto.Create(nil);
  try
    LItem.Parent := lytProdutos;
    LItem.Align := TAlignLayout.Top;

    LItem.Margins.Left := 0;
    LItem.Margins.Top := 0;
    LItem.Margins.Right := 0;
    LItem.Margins.Bottom := 8;

    LItem.Preencher(
      AQuantidade,
      ADescricao,
      AComplementos,
      AValor
    );

    lytProdutos.Height :=
      lytProdutos.Height +
      LItem.Height +
      LItem.Margins.Bottom;

  except
    LItem.Free;
    raise;
  end;
end;

procedure TfraPedidos.CarregarProdutosTeste;
begin
  LimparProdutos;

  AdicionarProduto(
    2,
    'Pizza Calabresa G',
    '• Borda Cheddar' + sLineBreak +
    '• Sem cebola',
    84.90
  );

  AdicionarProduto(
    1,
    'Coca-Cola 2L',
    '',
    14.00
  );
end;

procedure TfraPedidos.PrepararTela;
begin
  FItemPedidoSelecionado := nil;

  rctMenuAcoes.Visible := False;
  rctOverlayDetalhes.Visible := False;
end;

procedure TfraPedidos.PreencherDetalhesEntrega;
begin
  if not Assigned(FItemPedidoSelecionado) then
    Exit;

  lblDetalheTipo.Text :=
    FItemPedidoSelecionado.TipoPedido;

  if SameText(
    FItemPedidoSelecionado.TipoPedido,
    'Retirada'
  ) then
  begin
    lblDetalheEndereco.Text :=
      'Retirada no estabelecimento';
  end
  else
  begin
    lblDetalheEndereco.Text :=
      FItemPedidoSelecionado.Endereco;
  end;
end;

procedure TfraPedidos.AbrirMenuStatus;
var
  LPonto: TPointF;
begin
  LPonto := rctAlterarStatusDetalhe.LocalToAbsolute(
    PointF(
      rctAlterarStatusDetalhe.Width,
      0
    )
  );

  LPonto := rctOverlayDetalhes.AbsoluteToLocal(LPonto);

  rctMenuStatus.Position.X :=
    LPonto.X - rctMenuStatus.Width;

  rctMenuStatus.Position.Y :=
    LPonto.Y - rctMenuStatus.Height - 6;

  rctMenuStatus.BringToFront;
  rctMenuStatus.Visible := True;
end;

procedure TfraPedidos.FecharMenuStatus;
begin
  rctMenuStatus.Visible := False;
end;

procedure TfraPedidos.AplicarStatusSelecionado(
  const AStatus: string);
begin
  if not Assigned(FItemPedidoSelecionado) then
    Exit;

  FItemPedidoSelecionado.AlterarStatus(AStatus);

  lblDetalheStatus.Text := AStatus;

  if SameText(AStatus, 'Novo') then
  begin
    rctDetalheStatus.Fill.Color := $332B7FFF;
    lblDetalheStatus.TextSettings.FontColor := $FF5B9DFF;
  end
  else if SameText(AStatus, 'Confirmado') then
  begin
    rctDetalheStatus.Fill.Color := $3343A5FF;
    lblDetalheStatus.TextSettings.FontColor := $FF43A5FF;
  end
  else if SameText(AStatus, 'Em preparo') then
  begin
    rctDetalheStatus.Fill.Color := $33FFA21A;
    lblDetalheStatus.TextSettings.FontColor := $FFFFA21A;
  end
  else if SameText(AStatus, 'Pronto') then
  begin
    rctDetalheStatus.Fill.Color := $3336D276;
    lblDetalheStatus.TextSettings.FontColor := $FF36D276;
  end
  else if SameText(AStatus, 'Em entrega') then
  begin
    rctDetalheStatus.Fill.Color := $3343A5FF;
    lblDetalheStatus.TextSettings.FontColor := $FF43A5FF;
  end
  else if SameText(AStatus, 'Finalizado') then
  begin
    rctDetalheStatus.Fill.Color := $339B6CFF;
    lblDetalheStatus.TextSettings.FontColor := $FF9B6CFF;
  end;

  FecharMenuStatus;
end;

procedure TfraPedidos.CriarPopupStatus;
begin
  FPopupStatus := TfraPopupMenu.Create(Self);
  FPopupStatus.Name := '';
  FPopupStatus.Parent := rctOverlayDetalhes;
  FPopupStatus.Width := 220;
  FPopupStatus.Visible := False;

  FPopupStatus.AdicionarItem(
    'NOVO',
    'Novo'
  );

  FPopupStatus.AdicionarItem(
    'CONFIRMADO',
    'Confirmado'
  );

  FPopupStatus.AdicionarItem(
    'EM_PREPARO',
    'Em preparo'
  );

  FPopupStatus.AdicionarItem(
    'PRONTO',
    'Pronto'
  );

  FPopupStatus.AdicionarItem(
    'EM_ENTREGA',
    'Em entrega'
  );

  FPopupStatus.AdicionarItem(
    'FINALIZADO',
    'Finalizado'
  );

  FPopupStatus.OnItemClick :=
    PopupStatusItemClick;
end;

procedure TfraPedidos.ItemMenuMouseEnter(Sender: TObject);
begin
  if Sender is TRectangle then
    TRectangle(Sender).Fill.Color := $FF18283B;
end;

procedure TfraPedidos.ItemMenuMouseLeave(Sender: TObject);
begin
  if Sender is TRectangle then
    TRectangle(Sender).Fill.Color := $00FFFFFF;
end;

procedure TfraPedidos.rctVerDetalhesClick(Sender: TObject);
begin
  FecharMenuAcoes;

  if not Assigned(FItemPedidoSelecionado) then
    Exit;

  FecharMenuAcoes;
  AbrirDetalhesPedido;
end;

procedure TfraPedidos.rctAlterarStatusClick(Sender: TObject);
begin
  FecharMenuAcoes;

  if not Assigned(FItemPedidoSelecionado) then
    Exit;

  // Abrir alteração de status.
end;

procedure TfraPedidos.rctImprimirClick(Sender: TObject);
begin
  FecharMenuAcoes;

  if not Assigned(FItemPedidoSelecionado) then
    Exit;

  // Imprimir pedido.
end;

procedure TfraPedidos.rctCancelarClick(Sender: TObject);
begin
  FecharMenuAcoes;

  if not Assigned(FItemPedidoSelecionado) then
    Exit;

  // Confirmar cancelamento.
end;

procedure TfraPedidos.rctFecharDetalhesClick(Sender: TObject);
begin
  FecharDetalhesPedido;
end;

procedure TfraPedidos.rctAlterarStatusDetalheClick(
  Sender: TObject);
var
  LPonto: TPointF;
begin
  if not Assigned(FItemPedidoSelecionado) then
    Exit;

  LPonto :=
    rctAlterarStatusDetalhe.LocalToAbsolute(
      PointF(
        rctAlterarStatusDetalhe.Width,
        0
      )
    );

  LPonto :=
    rctOverlayDetalhes.AbsoluteToLocal(LPonto);

  FPopupStatus.Abrir(
    LPonto.X - FPopupStatus.Width,
    LPonto.Y - FPopupStatus.Height - 6
  );
end;

procedure TfraPedidos.rctImprimirDetalheClick(Sender: TObject);
begin
  if not Assigned(FItemPedidoSelecionado) then
    Exit;

  // Depois ligaremos à impressão.
end;

procedure TfraPedidos.rctCancelarDetalheClick(Sender: TObject);
begin
  if not Assigned(FItemPedidoSelecionado) then
    Exit;

  if not TfrmMensagem.Exibir(
    'Cancelar pedido',
    'Deseja realmente cancelar o pedido ' +
      FItemPedidoSelecionado.NumeroPedido + '?',
    tmConfirmacao,
    True,
    'Cancelar pedido',
    'Voltar'
  ) then
    Exit;

  FItemPedidoSelecionado.AlterarStatus('Cancelado');

  lblDetalheStatus.Text := 'Cancelado';

  rctDetalheStatus.Fill.Color := $33FF6570;
  lblDetalheStatus.TextSettings.FontColor := $FFFF6570;
end;

procedure TfraPedidos.BotaoAlterarMouseEnter(Sender: TObject);
begin
  rctAlterarStatusDetalhe.Fill.Color := $FF9B78FF;
end;

procedure TfraPedidos.BotaoAlterarMouseLeave(Sender: TObject);
begin
  rctAlterarStatusDetalhe.Fill.Color := $FF8C63FF;
end;

procedure TfraPedidos.BotaoSecundarioMouseEnter(Sender: TObject);
begin
  rctImprimirDetalhe.Fill.Color := $FF1C2E45;
  rctImprimirDetalhe.Stroke.Color := $FF3A506C;
end;

procedure TfraPedidos.BotaoSecundarioMouseLeave(Sender: TObject);
begin
  rctImprimirDetalhe.Fill.Color := $FF152439;
  rctImprimirDetalhe.Stroke.Color := $FF2A405B;
end;

procedure TfraPedidos.BotaoCancelarMouseEnter(Sender: TObject);
begin
  rctCancelarDetalhe.Fill.Color := $33FF6570;
  rctCancelarDetalhe.Stroke.Color := $99FF6570;
end;

procedure TfraPedidos.BotaoCancelarMouseLeave(Sender: TObject);
begin
  rctCancelarDetalhe.Fill.Color := $221F2A3A;
  rctCancelarDetalhe.Stroke.Color := $66FF6570;
end;

procedure TfraPedidos.rctStatusNovoClick(Sender: TObject);
begin
  AplicarStatusSelecionado('Novo');
end;

procedure TfraPedidos.rctStatusConfirmadoClick(Sender: TObject);
begin
  AplicarStatusSelecionado('Confirmado');
end;

procedure TfraPedidos.rctStatusEmPreparoClick(Sender: TObject);
begin
  AplicarStatusSelecionado('Em preparo');
end;

procedure TfraPedidos.rctStatusProntoClick(Sender: TObject);
begin
  AplicarStatusSelecionado('Pronto');
end;

procedure TfraPedidos.rctStatusEmEntregaClick(Sender: TObject);
begin
  AplicarStatusSelecionado('Em entrega');
end;

procedure TfraPedidos.rctStatusFinalizadoClick(Sender: TObject);
begin
  AplicarStatusSelecionado('Finalizado');
end;

procedure TfraPedidos.StatusMouseEnter(Sender: TObject);
begin
  if Sender is TRectangle then
  begin
    TRectangle(Sender).Fill.Color := $FF1A2C42;
    TRectangle(Sender).Stroke.Color := $FF35506E;
  end;
end;

procedure TfraPedidos.StatusMouseLeave(Sender: TObject);
begin
  if Sender is TRectangle then
  begin
    TRectangle(Sender).Fill.Color := $00FFFFFF;
    TRectangle(Sender).Stroke.Kind := TBrushKind.None;
  end;
end;

procedure TfraPedidos.PopupStatusItemClick(Sender: TObject; const AIdentificador: string);
begin
  if SameText(AIdentificador, 'NOVO') then
    AplicarStatusSelecionado('Novo')
  else if SameText(AIdentificador, 'CONFIRMADO') then
    AplicarStatusSelecionado('Confirmado')
  else if SameText(AIdentificador, 'EM_PREPARO') then
    AplicarStatusSelecionado('Em preparo')
  else if SameText(AIdentificador, 'PRONTO') then
    AplicarStatusSelecionado('Pronto')
  else if SameText(AIdentificador, 'EM_ENTREGA') then
    AplicarStatusSelecionado('Em entrega')
  else if SameText(AIdentificador, 'FINALIZADO') then
    AplicarStatusSelecionado('Finalizado');
end;

end.
