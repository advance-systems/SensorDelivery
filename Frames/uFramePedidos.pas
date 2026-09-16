unit uFramePedidos;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Layouts, FMX.Controls.Presentation, FMX.Edit, uSensorIcons,
  uSessaoAdmin, uApiConfig, uAlertaNovoPedido,
  uFrameItemPedido, uFrameItemProduto, uMensagem, FMX.Ani, uFramePopupMenu,
  uFrameSensorButton, uFrameSensorEdit, uFrameItemSabor, uFrameItemBorda,
  uFrameItemAdicional, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.Presentation.Style,
  uPedidoNovo, uFrameItemNovoPedido, System.JSON, System.Net.HttpClient,
  System.Net.URLClient, System.Net.HttpClientComponent, System.DateUtils,
  System.Generics.Collections, Winapi.Windows;

type
  TTipoEntregaNovoPedido = (
    tenDelivery,
    tenRetirada
  );

  TOpcaoCatalogoPedido = class
  public
    Id: string;
    Nome: string;
    CategoriaId: string;
    Preco: Currency;
  end;

  TfraPedidos = class(TFrame)
    lytPrincipal: TLayout;
    lytItensPedidos: TLayout;
    rctOverlayDetalhes: TRectangle;
    rctPainelDetalhes: TRectangle;
    lytTopoDetalhes: TLayout;
    lblTituloDetalhes: TLabel;
    rctFecharDetalhes: TRectangle;
    pthFecharDetalhes: TPath;
    vsbDetalhes: TVertScrollBox;
    lytCabecalho: TLayout;
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
    rctOverlayNovoPedido: TRectangle;
    rctPainelNovoPedido: TRectangle;
    lytTopoNovoPedido: TLayout;
    lblTituloNovoPedido: TLabel;
    rctFecharNovoPedido: TRectangle;
    vsbNovoPedido: TVertScrollBox;
    lytConteudoNovoPedido: TLayout;
    lytRodapeNovoPedido: TLayout;
    lytDadosCliente: TLayout;
    lytTipoEntrega: TLayout;
    lblTituloTipoEntrega: TLabel;
    lytOpcoesEntrega: TLayout;
    rctEntregaDelivery: TRectangle;
    pthEntregaDelivery: TPath;
    lblEntregaDelivery: TLabel;
    rctEntregaRetirada: TRectangle;
    pthEntregaRetirada: TPath;
    lblEntregaRetirada: TLabel;
    lytEnderecoEntrega: TLayout;
    lblTituloEndereco: TLabel;
    lytLinhaEndereco1: TLayout;
    lytLinhaEndereco2: TLayout;
    lytLinhaEndereco3: TLayout;
    lytItensNovoPedido: TLayout;
    lytCabecalhoItens: TLayout;
    lblTituloItens: TLabel;
    rctListaItensNovoPedido: TRectangle;
    lblListaVazia: TLabel;
    rctOverlayAdicionarItem: TRectangle;
    rctPainelAdicionarItem: TRectangle;
    lytTopoAdicionarItem: TLayout;
    lblTituloAdicionarItem: TLabel;
    rctFecharAdicionarItem: TRectangle;
    vsbAdicionarItem: TVertScrollBox;
    lytConteudoAdicionarItem: TLayout;
    lytSelecaoProduto: TLayout;
    lblTituloProduto: TLabel;
    rctSelecionarCategoria: TRectangle;
    lblCategoriaSelecionada: TLabel;
    pthSetaCategoria: TPath;
    rctSelecionarProduto: TRectangle;
    lblProdutoSelecionado: TLabel;
    pthSetaProduto: TPath;
    rctSelecionarTamanho: TRectangle;
    lblTamanhoSelecionado: TLabel;
    pthSetaTamanho: TPath;
    lytSabores: TLayout;
    lytCabecalhoSabores: TLayout;
    lblTituloSabores: TLabel;
    lblLimiteSabores: TLabel;
    rctListaSabores: TRectangle;
    vsbListaSabores: TVertScrollBox;
    lytItensSabores: TLayout;
    lytBordas: TLayout;
    lblTituloBordas: TLabel;
    rctListaBordas: TRectangle;
    vsbListaBordas: TVertScrollBox;
    lytItensBordas: TLayout;
    lytAdicionais: TLayout;
    lblTituloAdicionais: TLabel;
    rctListaAdicionais: TRectangle;
    vsbListaAdicionais: TVertScrollBox;
    lytItensAdicionais: TLayout;
    lytFinalizacaoItem: TLayout;
    lytQuantidade: TLayout;
    lblTituloQuantidade: TLabel;
    rctDiminuirQuantidade: TRectangle;
    lblMenos: TLabel;
    lblQuantidade: TLabel;
    rctAumentarQuantidade: TRectangle;
    lblMais: TLabel;
    memObservacaoItem: TMemo;
    rctResumoValorItem: TRectangle;
    lblTituloValorItem: TLabel;
    lblValorItem: TLabel;
    lblTituloObservacao: TLabel;
    rctObservacao: TRectangle;
    lytRodapeAdicionarItem: TLayout;
    rctFundoRodapeAdicionarItem: TRectangle;
    vsbItensNovoPedido: TVertScrollBox;
    lytListaItensNovoPedido: TLayout;
    rctResumoNovoPedido: TRectangle;
    lytSubtotalNovoPedido: TLayout;
    lblSubtotalNovoPedidoTitulo: TLabel;
    lblSubtotalNovoPedidoValor: TLabel;
    lytTaxaNovoPedido: TLayout;
    lblTaxaNovoPedidoTitulo: TLabel;
    lblTaxaNovoPedidoValor: TLabel;
    linResumoNovoPedido: TLine;
    lytTotalNovoPedido: TLayout;
    lblTotalNovoPedidoTitulo: TLabel;
    lblTotalNovoPedidoValor: TLabel;
    tmrAtualizarPedidos: TTimer;

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
    procedure rctNovoPedidoClick(Sender: TObject);
    procedure rctFecharNovoPedidoClick(Sender: TObject);
    procedure rctCancelarNovoPedidoClick(Sender: TObject);
//    procedure rctSalvarNovoPedidoClick(Sender: TObject);
    procedure rctEntregaDeliveryClick(Sender: TObject);
    procedure rctEntregaRetiradaClick(Sender: TObject);
    procedure btnAdicionarItemClick(Sender: TObject);
    procedure rctFecharAdicionarItemClick(Sender: TObject);
    procedure SeletorMouseEnter(Sender: TObject);
    procedure SeletorMouseLeave(Sender: TObject);
    procedure PopupCategoriaItemClick(Sender: TObject; const AIdentificador: string);
    procedure rctSelecionarCategoriaClick(Sender: TObject);
    procedure PopupProdutoItemClick(Sender: TObject; const AIdentificador: string);
    procedure rctSelecionarProdutoClick(Sender: TObject);
    procedure PopupTamanhoItemClick(Sender: TObject; const AIdentificador: string);
    procedure rctSelecionarTamanhoClick(Sender: TObject);
    procedure rctDiminuirQuantidadeClick(Sender: TObject);
    procedure rctAumentarQuantidadeClick(Sender: TObject);
    procedure memObservacaoItemApplyStyleLookup(Sender: TObject);
    procedure btnAdicionarAoPedidoClick(Sender: TObject);
    procedure tmrAtualizarPedidosTimer(Sender: TObject);
  private
    FItemPedidoSelecionado: TfraItemPedido;
    FPopupStatus: TfraPopupMenu;
    FPopupAcoes: TfraPopupMenu;
    FBtnNovoPedido: TfraSensorButton;
    FBtnCancelarNovoPedido: TfraSensorButton;
    FBtnCriarPedido: TfraSensorButton;
    FEditCliente: TfraSensorEdit;
    FEditTelefone: TfraSensorEdit;
    FTipoEntregaNovoPedido: TTipoEntregaNovoPedido;
    FEditRua: TfraSensorEdit;
    FEditNumero: TfraSensorEdit;
    FEditBairro: TfraSensorEdit;
    FEditComplemento: TfraSensorEdit;
    FEditReferencia: TfraSensorEdit;
    FBtnAdicionarItem: TfraSensorButton;
    FPopupCategoria: TfraPopupMenu;
    FPopupProduto: TfraPopupMenu;
    FCategoriaSelecionada: string;
    FProdutoSelecionado: string;
    FPopupTamanho: TfraPopupMenu;
    FTamanhoSelecionado: string;
    FSaboresSelecionados: TStringList;
    FBordaSelecionadaId: string;
    FAdicionaisSelecionados: TStringList;
    FQuantidadeItem: Integer;
    FValorBaseItem: Currency;
    FBtnAdicionarAoPedido: TfraSensorButton;
    FPedidoNovo: TPedidoNovo;
    FUltimoNumeroPedido: Integer;
    FPrimeiraCargaPedidos: Boolean;
    FCategoriasCatalogo: TObjectList<TOpcaoCatalogoPedido>;
    FProdutosCatalogo: TObjectList<TOpcaoCatalogoPedido>;
    FVariacoesProduto: TObjectList<TOpcaoCatalogoPedido>;
    FTaxaEntregaPadrao: Currency;

    procedure PedidoAcoesClick(Sender: TObject);
    procedure AbrirMenuAcoes(const AItem: TfraItemPedido);
    procedure FecharMenuAcoes;
    procedure AdicionarPedido(const ANumero: string; const ACliente: string; const ATelefone: string;
      const ATipo: string; const AStatus: string; const AHorario: string; const AEndereco: string;
      const ATotal: Currency; const APedidoId: string = '');
    procedure AbrirDetalhesPedido;
    procedure FecharDetalhesPedido;
    procedure LimparProdutos;
    procedure AdicionarProduto(const AQuantidade: Integer; const ADescricao: string;
      const AComplementos: string; const AValor: Currency);
    procedure CarregarDetalhesPedidoAPI(const APedidoId: string);
    procedure PreencherDetalhesEntrega;
    procedure AplicarStatusSelecionado(const AStatus: string);
    procedure CriarPopupStatus;
    procedure PopupStatusItemClick(Sender: TObject; const AIdentificador: string);
    procedure CriarPopupAcoes;
    procedure PopupAcoesItemClick(Sender: TObject; const AIdentificador: string);
    procedure AbrirNovoPedido;
    procedure FecharNovoPedido;
    procedure CriarBotaoNovoPedido;
    procedure btnNovoPedidoClick(Sender: TObject);
    procedure CriarBotoesRodapeNovoPedido;
    procedure btnCancelarNovoPedidoClick(Sender: TObject);
    procedure btnCriarPedidoClick(Sender: TObject);
    procedure CriarCamposNovoPedido;
    procedure LimparNovoPedido;
    procedure SelecionarTipoEntrega(const ATipo: TTipoEntregaNovoPedido);
    procedure CriarCamposEndereco;
    procedure AtualizarVisibilidadeEndereco;
    procedure CriarBotaoAdicionarItem;
    procedure AbrirAdicionarItem;
    procedure FecharAdicionarItem;
    procedure CriarPopupCategoria;
    function CarregarCatalogoPedido: Boolean;
    procedure CarregarParametrosPedido;
    function CarregarOpcoesProduto(const AProdutoId: string): Boolean;
    function EncontrarOpcao(ALista: TObjectList<TOpcaoCatalogoPedido>;
      const AId: string): TOpcaoCatalogoPedido;
    procedure CriarPopupProduto;
    procedure AtualizarPopupProduto;
    procedure CriarPopupTamanho;
    procedure AtualizarPopupTamanho;
    procedure AtualizarVisibilidadeSabores;
    procedure AlternarSabor(const AIdentificador: string; const AItem: TRectangle; const ACheck: TRectangle);
    procedure LimparSabores;
    procedure AdicionarSabor(const ASaborId: string; const ADescricao: string; const AValor: Currency);
    procedure SaborSelecionado(Sender: TObject; const ASaborId: string; const ASelecionado: Boolean);
    procedure LimparBordas;
    procedure AdicionarBorda(const ABordaId: string; const ADescricao: string; const AValor: Currency);
    procedure BordaSelecionada(Sender: TObject; const ABordaId: string);
    procedure AtualizarVisibilidadeBordas;
    procedure LimparAdicionais;
    procedure AdicionarAdicional(const AAdicionalId: string; const ADescricao: string; const AValor: Currency);
    procedure AdicionalSelecionado(Sender: TObject; const AAdicionalId: string; const ASelecionado: Boolean);
    procedure AtualizarQuantidadeItem;
    procedure AtualizarValorItem;
    procedure DefinirValorBaseItem;
    procedure AtualizarPosicoesAdicionarItem;
    procedure CriarBotaoAdicionarAoPedido;
    procedure AtualizarListaItensNovoPedido;
    procedure ItemNovoPedidoExcluir(Sender: TObject; const AItem: TItemPedidoNovo);
    procedure AtualizarVisibilidadeAdicionais;
    procedure AtualizarTotaisNovoPedido;
    procedure PrepararPedido;
    procedure TestarPedidoMontado;
    procedure CampoNovoPedidoRecebeuFoco(Sender: TObject);
    procedure CarregarPedidosAPI;
    procedure AlertarNovoPedido(ANumero: Integer; const ACliente: string; const ATotal: Currency);
//    procedure AtualizarListaItensNovoPedido;
//    procedure AtualizarTotaisNovoPedido;
    function ObterValorSabores: Currency;
    function ObterValorBorda: Currency;
    function ObterValorAdicionais: Currency;
    function ObterValorUnitarioItem: Currency;
    function ValidarItemSelecionado: Boolean;
    function ValidarNovoPedido: Boolean;
    function MontarItemPedido: TItemPedidoNovo;
    function PedidoParaJSON: TJSONObject;
    function EnviarPedidoAPI: Boolean;
    function StatusParaAPI(const AStatus: string): string;
    function AtualizarStatusPedidoAPI(const APedidoId: string; const AStatus: string;
      out AErro: string): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure PrepararTela;
  end;

implementation

{$R *.fmx}

procedure TfraPedidos.AdicionarPedido(
  const ANumero, ACliente, ATelefone, ATipo,
  AStatus, AHorario: string;
  const AEndereco: string;
  const ATotal: Currency;
  const APedidoId: string);
const
  ESPACO = 8;
var
  LItem: TfraItemPedido;
begin
  LItem := TfraItemPedido.Create(nil);

  try
    LItem.Name := '';
    LItem.Parent := lytItensPedidos;

    LItem.Align := TAlignLayout.None;

    LItem.Position.X := 0;
    LItem.Position.Y := lytItensPedidos.Height;

    LItem.Width := lytItensPedidos.Width;
    LItem.Height := 72;

    LItem.Anchors := [
      TAnchorKind.akLeft,
      TAnchorKind.akTop,
      TAnchorKind.akRight
    ];

    LItem.Preencher(
      ANumero,
      ACliente,
      ATelefone,
      ATipo,
      AStatus,
      AHorario,
      AEndereco,
      ATotal,
      APedidoId
    );

    LItem.OnAcoesClick :=
      PedidoAcoesClick;

    lytItensPedidos.Height :=
      lytItensPedidos.Height +
      LItem.Height +
      ESPACO;

  except
    LItem.Free;
    raise;
  end;
end;

procedure TfraPedidos.PedidoAcoesClick(Sender: TObject);
begin
  if not (Sender is TfraItemPedido) then
    Exit;

  AbrirMenuAcoes(
    TfraItemPedido(Sender)
  );
end;

procedure TfraPedidos.AbrirMenuAcoes(
  const AItem: TfraItemPedido);
var
  LPonto: TPointF;
begin
  if not Assigned(AItem) then
    Exit;

  if not Assigned(FPopupAcoes) then
    Exit;

  FItemPedidoSelecionado := AItem;
  tmrAtualizarPedidos.Enabled := False;

  if Assigned(FPopupStatus) then
    FPopupStatus.Fechar;

  LPonto := AItem.rctAcoes.LocalToAbsolute(
    PointF(
      AItem.rctAcoes.Width,
      AItem.rctAcoes.Height
    )
  );

  LPonto := lytPrincipal.AbsoluteToLocal(LPonto);

  FPopupAcoes.Abrir(
    LPonto.X - FPopupAcoes.Width,
    LPonto.Y + 4
  );
end;

procedure TfraPedidos.FecharMenuAcoes;
begin
  if Assigned(FPopupAcoes) then
    FPopupAcoes.Fechar;

  if not rctOverlayDetalhes.Visible then
    tmrAtualizarPedidos.Enabled := True;
end;

procedure TfraPedidos.AbrirDetalhesPedido;
begin
  if not Assigned(FItemPedidoSelecionado) then
    Exit;

  tmrAtualizarPedidos.Enabled := False;

  if Assigned(FPopupAcoes) then
    FPopupAcoes.Fechar;

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
    'Hor�rio: ' + FItemPedidoSelecionado.Horario;

  lblDetalheEndereco.Text :=
    'Endere�o ainda n�o informado';

  lblSubtotalValor.Text :=
    FormatFloat(
      '"R$ " #,##0.00',
      FItemPedidoSelecionado.Total
    );

  lblTaxaValor.Text := 'R$ 0,00';

  lblDetalheTotal.Text :=
    FItemPedidoSelecionado.TotalFormatado;

  CarregarDetalhesPedidoAPI(FItemPedidoSelecionado.PedidoId);
  PreencherDetalhesEntrega;
  FecharMenuAcoes;

  vsbDetalhes.ViewportPosition := PointF(0, 0);
  rctOverlayDetalhes.BringToFront;
  rctOverlayDetalhes.Visible := True;
end;

procedure TfraPedidos.FecharDetalhesPedido;
begin
  if Assigned(FPopupStatus) then
    FPopupStatus.Fechar;

  if Assigned(FPopupAcoes) then
    FPopupAcoes.Fechar;

  rctOverlayDetalhes.Visible := False;

  FItemPedidoSelecionado := nil;
  tmrAtualizarPedidos.Enabled := True;

  CarregarPedidosAPI;
end;

constructor TfraPedidos.Create(AOwner: TComponent);
begin
  inherited;

  tmrAtualizarPedidos.Enabled := False;
  FCategoriasCatalogo := TObjectList<TOpcaoCatalogoPedido>.Create(True);
  FProdutosCatalogo := TObjectList<TOpcaoCatalogoPedido>.Create(True);
  FVariacoesProduto := TObjectList<TOpcaoCatalogoPedido>.Create(True);
  FTaxaEntregaPadrao := 0;

  CriarBotaoNovoPedido;
  CriarBotoesRodapeNovoPedido;
  CriarCamposNovoPedido;
  CriarCamposEndereco;
  CriarBotaoAdicionarItem;
  CriarPopupCategoria;
  CriarPopupProduto;
  CriarPopupTamanho;
  CriarBotaoAdicionarAoPedido;

  FEditCliente.Position.Y := 0;
  FEditTelefone.Position.Y := 86;
  FEditTelefone.Margins.Top := 10;

  FItemPedidoSelecionado := nil;
  FSaboresSelecionados := TStringList.Create;
  FAdicionaisSelecionados := TStringList.Create;
  FPedidoNovo := TPedidoNovo.Create;

  FQuantidadeItem := 1;
  FValorBaseItem := 0;
  FUltimoNumeroPedido := 0;
  FPrimeiraCargaPedidos := True;

  memObservacaoItem.Text := '';

  rctOverlayDetalhes.Visible := False;
  rctOverlayNovoPedido.Visible := False;
  rctOverlayAdicionarItem.Visible := False;

  lblCategoriaSelecionada.Text := 'Selecione a Categoria';
  lblProdutoSelecionado.Text := 'Selecione o Produto';
  lblTamanhoSelecionado.Text := 'Selecione o Tamanho';

  pthSetaCategoria.Data.Data := 'M2,4 L6,8 L10,4 Z';
  pthSetaProduto.Data.Data := 'M2,4 L6,8 L10,4 Z';
  pthSetaTamanho.Data.Data := 'M2,4 L6,8 L10,4 Z';

  CriarPopupStatus;
  CriarPopupAcoes;

  AtualizarQuantidadeItem;
end;

destructor TfraPedidos.Destroy;
begin
  FVariacoesProduto.Free;
  FProdutosCatalogo.Free;
  FCategoriasCatalogo.Free;
  FPedidoNovo.Free;
  FSaboresSelecionados.Free;
  FAdicionaisSelecionados.Free;
  tmrAtualizarPedidos.Enabled := False;

  inherited;
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

procedure TfraPedidos.CarregarDetalhesPedidoAPI(
  const APedidoId: string);
var
  LHTTP: TNetHTTPClient;
  LResposta: IHTTPResponse;
  LJSON: TJSONObject;
  LPedido: TJSONObject;
  LItens: TJSONArray;
  LItem: TJSONObject;
  LSabores: TJSONArray;
  LSabor: TJSONObject;

  I: Integer;
  J: Integer;
  LQuantidade: Integer;

  LProduto: string;
  LTamanho: string;
  LComplementos: string;
  LDescricaoSabor: string;
  LBorda: string;
  LObservacao: string;

  LValorItem: Currency;
  LSubtotal: Currency;
  LTaxa: Currency;
  LDesconto: Currency;
  LTotal: Currency;
begin
  if APedidoId.Trim.IsEmpty then
    Exit;

  LimparProdutos;

  LHTTP := TNetHTTPClient.Create(nil);
  TSessaoAdmin.ConfigurarCliente(LHTTP);
  LJSON := nil;

  try
    try
      LHTTP.Accept := 'application/json';
      LHTTP.ConnectionTimeout := 5000;
      LHTTP.ResponseTimeout := 15000;

      LResposta := LHTTP.Get(
        TApiConfig.Url('/api/pedidos/') +
        APedidoId +
        '/detalhes'
      );

      if LResposta.StatusCode <> 200 then
      begin
        TfrmMensagem.Exibir(
          'Erro ao carregar o pedido',
          'A API retornou o c�digo ' +
            LResposta.StatusCode.ToString +
            '.' +
            sLineBreak +
            LResposta.ContentAsString(
              TEncoding.UTF8
            ),
          tmErro,
          False,
          'OK',
          ''
        );

        Exit;
      end;

      LJSON :=
        TJSONObject.ParseJSONValue(
          LResposta.ContentAsString(
            TEncoding.UTF8
          )
        ) as TJSONObject;

      if not Assigned(LJSON) then
        Exit;

      LPedido :=
        LJSON.GetValue<TJSONObject>('pedido');

      if not Assigned(LPedido) then
        Exit;

      lblDetalheCliente.Text :=
        LPedido.GetValue<string>(
          'cliente_nome',
          ''
        );

      lblDetalheTelefone.Text :=
        LPedido.GetValue<string>(
          'cliente_telefone',
          ''
        );

      lblDetalheEndereco.Text :=
        LPedido.GetValue<string>(
          'endereco_texto',
          ''
        );

      if lblDetalheEndereco.Text.Trim.IsEmpty then
        lblDetalheEndereco.Text :=
          'Retirada no estabelecimento';

      LSubtotal :=
        StrToCurrDef(
          LPedido.GetValue<string>(
            'subtotal',
            '0'
          ),
          0,
          TFormatSettings.Invariant
        );

      LTaxa :=
        StrToCurrDef(
          LPedido.GetValue<string>(
            'taxa_entrega',
            '0'
          ),
          0,
          TFormatSettings.Invariant
        );

      LDesconto :=
        StrToCurrDef(
          LPedido.GetValue<string>(
            'desconto',
            '0'
          ),
          0,
          TFormatSettings.Invariant
        );

      LTotal :=
        StrToCurrDef(
          LPedido.GetValue<string>(
            'valor_total',
            '0'
          ),
          0,
          TFormatSettings.Invariant
        );

      lblSubtotalValor.Text :=
        FormatFloat('"R$ " #,##0.00', LSubtotal);

      lblTaxaValor.Text :=
        FormatFloat('"R$ " #,##0.00', LTaxa);

      lblDescontoValor.Text :=
        FormatFloat('"R$ " #,##0.00', LDesconto);

      lblDetalheTotal.Text :=
        FormatFloat('"R$ " #,##0.00', LTotal);

      LItens :=
        LPedido.GetValue<TJSONArray>('itens');

      if not Assigned(LItens) then
        Exit;

      for I := 0 to LItens.Count - 1 do
      begin
        LItem := LItens.Items[I] as TJSONObject;

        LQuantidade :=
          Round(
            StrToFloatDef(
              LItem.GetValue<string>(
                'quantidade',
                '1'
              ),
              1,
              TFormatSettings.Invariant
            )
          );

        LProduto :=
          LItem.GetValue<string>(
            'produto_descricao',
            ''
          );

        LTamanho :=
          LItem.GetValue<string>(
            'tamanho_descricao',
            ''
          );

        if not LTamanho.Trim.IsEmpty and
           (Pos(
             LowerCase(LTamanho),
             LowerCase(LProduto)
           ) = 0) then
          LProduto :=
            LProduto + ' - ' + LTamanho;

        LComplementos := '';

        LSabores :=
          LItem.GetValue<TJSONArray>('sabores');

        if Assigned(LSabores) then
        begin
          for J := 0 to LSabores.Count - 1 do
          begin
            LSabor :=
              LSabores.Items[J] as TJSONObject;

            LDescricaoSabor :=
              LSabor.GetValue<string>(
                'descricao',
                ''
              );

            if not LDescricaoSabor.Trim.IsEmpty then
            begin
              if not LComplementos.IsEmpty then
                LComplementos :=
                  LComplementos + sLineBreak;

              LComplementos :=
                LComplementos +
                '� ' +
                LDescricaoSabor;
            end;
          end;
        end;

        LBorda :=
          LItem.GetValue<string>(
            'borda_descricao',
            ''
          );

        if not LBorda.Trim.IsEmpty and
           not SameText(LBorda, 'Sem borda') then
        begin
          if not LComplementos.IsEmpty then
            LComplementos :=
              LComplementos + sLineBreak;

          LComplementos :=
            LComplementos +
            '� Borda: ' +
            LBorda;
        end;

        LObservacao :=
          LItem.GetValue<string>(
            'observacoes',
            ''
          );

        if not LObservacao.Trim.IsEmpty then
        begin
          if not LComplementos.IsEmpty then
            LComplementos :=
              LComplementos + sLineBreak;

          LComplementos :=
            LComplementos +
            '� Obs.: ' +
            LObservacao;
        end;

        LValorItem :=
          StrToCurrDef(
            LItem.GetValue<string>(
              'valor_total',
              '0'
            ),
            0,
            TFormatSettings.Invariant
          );

        AdicionarProduto(
          LQuantidade,
          LProduto,
          LComplementos,
          LValorItem
        );
      end;

    except
      on E: Exception do
        TfrmMensagem.Exibir(
          'Erro ao carregar o pedido',
          E.Message,
          tmErro,
          False,
          'OK',
          ''
        );
    end;
  finally
    LJSON.Free;
    LResposta := nil;
    LHTTP.Free;
  end;
end;

procedure TfraPedidos.PrepararTela;
begin
  tmrAtualizarPedidos.Enabled := False;
  FItemPedidoSelecionado := nil;

  if Assigned(FPopupAcoes) then
    FPopupAcoes.Fechar;

  if Assigned(FPopupStatus) then
    FPopupStatus.Fechar;

  rctOverlayDetalhes.Visible := False;

  vsbDetalhes.ViewportPosition := PointF(0, 0);
  CarregarPedidosAPI;
  tmrAtualizarPedidos.Enabled := True;
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

procedure TfraPedidos.AplicarStatusSelecionado(
  const AStatus: string);
var
  LErro: string;
begin
  if not Assigned(FItemPedidoSelecionado) then
    Exit;

  if Assigned(FPopupStatus) then
    FPopupStatus.Fechar;

  if not AtualizarStatusPedidoAPI(FItemPedidoSelecionado.PedidoId, AStatus, LErro) then
  begin
    TfrmMensagem.Exibir('N�o foi poss�vel alterar o status', LErro, tmErro, False, 'OK', '');
    Exit;
  end;

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

procedure TfraPedidos.CriarPopupAcoes;
begin
  FPopupAcoes := TfraPopupMenu.Create(Self);
  FPopupAcoes.Name := '';
  FPopupAcoes.Parent := lytPrincipal;
  FPopupAcoes.Width := 190;
  FPopupAcoes.Visible := False;

  FPopupAcoes.AdicionarItem(
    'DETALHES',
    'Ver detalhes'
  );

  FPopupAcoes.AdicionarItem(
    'STATUS',
    'Alterar status'
  );

  FPopupAcoes.AdicionarItem(
    'IMPRIMIR',
    'Imprimir pedido'
  );

  FPopupAcoes.AdicionarItem(
    'CANCELAR',
    'Cancelar pedido',
    $FFFF6570
  );

  FPopupAcoes.OnItemClick := PopupAcoesItemClick;
end;

procedure TfraPedidos.AbrirNovoPedido;
begin
  if not CarregarCatalogoPedido then
    Exit;
  CarregarParametrosPedido;
  LimparNovoPedido;

  if Assigned(FPopupAcoes) then
    FPopupAcoes.Fechar;

  if Assigned(FPopupStatus) then
    FPopupStatus.Fechar;

  vsbNovoPedido.ViewportPosition := PointF(0, 0);

  rctOverlayNovoPedido.BringToFront;
  rctOverlayNovoPedido.Visible := True;
end;

procedure TfraPedidos.CriarBotaoNovoPedido;
begin
  FBtnNovoPedido := TfraSensorButton.Create(Self);
  FBtnNovoPedido.Name := '';
  FBtnNovoPedido.Parent := lytCabecalho;

  FBtnNovoPedido.Align := TAlignLayout.Right;
  FBtnNovoPedido.Width := 160;
  FBtnNovoPedido.Height := 42;

  FBtnNovoPedido.Margins.Top := 8;
  FBtnNovoPedido.Margins.Right := 0;
  FBtnNovoPedido.Margins.Bottom := 26;

  FBtnNovoPedido.Texto := 'Novo Pedido';
  FBtnNovoPedido.Icone := sbiPedido;
  FBtnNovoPedido.Estilo := sbsPrimary;
  FBtnNovoPedido.OnButtonClick := btnNovoPedidoClick;
end;

procedure TfraPedidos.FecharNovoPedido;
begin
  rctOverlayNovoPedido.Visible := False;
end;

procedure TfraPedidos.CriarBotoesRodapeNovoPedido;
begin
  FBtnCancelarNovoPedido := TfraSensorButton.Create(Self);
  FBtnCancelarNovoPedido.Name := '';
  FBtnCancelarNovoPedido.Parent := lytRodapeNovoPedido;
  FBtnCancelarNovoPedido.Align := TAlignLayout.Left;
  FBtnCancelarNovoPedido.Width := 140;
  FBtnCancelarNovoPedido.Height := 42;
  FBtnCancelarNovoPedido.pthIcone.Width := 18;
  FBtnCancelarNovoPedido.pthIcone.Height := 18;

  FBtnCancelarNovoPedido.Texto := 'Cancelar';
  FBtnCancelarNovoPedido.Icone := sbiCancelar;
  FBtnCancelarNovoPedido.Estilo := sbsSecondary;
  FBtnCancelarNovoPedido.OnButtonClick := btnCancelarNovoPedidoClick;

  FBtnCriarPedido := TfraSensorButton.Create(Self);
  FBtnCriarPedido.Name := '';
  FBtnCriarPedido.Parent := lytRodapeNovoPedido;
  FBtnCriarPedido.Align := TAlignLayout.Client;
  FBtnCriarPedido.Height := 42;
  FBtnCriarPedido.Margins.Left := 10;

  FBtnCriarPedido.Texto := 'Criar Pedido';
  FBtnCriarPedido.Icone := sbiSalvar;
  FBtnCriarPedido.Estilo := sbsPrimary;
  FBtnCriarPedido.OnButtonClick := btnCriarPedidoClick;
end;

procedure TfraPedidos.CriarCamposNovoPedido;
begin
  FEditCliente := TfraSensorEdit.Create(Self);
  FEditCliente.Name := '';
  FEditCliente.Parent := lytDadosCliente;
  FEditCliente.Align := TAlignLayout.None;
  FEditCliente.Position.X := 0;
  FEditCliente.Position.Y := 0;
  FEditCliente.Height := 88;
  FEditCliente.Width := lytDadosCliente.Width;
  FEditCliente.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akRight];

  FEditCliente.Titulo := 'Cliente';
  FEditCliente.Placeholder := 'Digite o nome do cliente';
  FEditCliente.Icone := seiUsuario;
  FEditCliente.Obrigatorio := True;

  FEditTelefone := TfraSensorEdit.Create(Self);
  FEditTelefone.Name := '';
  FEditTelefone.Parent := lytDadosCliente;
  FEditTelefone.Align := TAlignLayout.None;
  FEditTelefone.Position.X := 0;
  FEditTelefone.Position.Y := 100;
  FEditTelefone.Height := 88;
  FEditTelefone.Width := lytDadosCliente.Width;
  FEditTelefone.Margins.Top := 12;
  FEditTelefone.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akRight];

  FEditTelefone.Titulo := 'Telefone';
  FEditTelefone.Placeholder := '(00) 00000-0000';
  FEditTelefone.Icone := seiTelefone;
  FEditTelefone.Obrigatorio := True;
  FEditTelefone.TipoTeclado := TVirtualKeyboardType.PhonePad;

  SelecionarTipoEntrega(tenDelivery);
end;

procedure TfraPedidos.LimparNovoPedido;
begin
  FEditCliente.Texto := '';
  FEditCliente.LimparErro;

  FEditTelefone.Texto := '';
  FEditTelefone.LimparErro;

  FEditRua.Texto := '';
  FEditRua.LimparErro;

  FEditNumero.Texto := '';
  FEditNumero.LimparErro;

  FEditBairro.Texto := '';
  FEditBairro.LimparErro;

  FEditComplemento.Texto := '';
  FEditComplemento.LimparErro;

  FEditReferencia.Texto := '';
  FEditReferencia.LimparErro;

  SelecionarTipoEntrega(tenDelivery);

  vsbNovoPedido.ViewportPosition := PointF(0, 0);

  FPedidoNovo.Itens.Clear;
  FPedidoNovo.TaxaEntrega := FTaxaEntregaPadrao;
  FPedidoNovo.Desconto := 0;

  AtualizarListaItensNovoPedido;
  AtualizarTotaisNovoPedido;
end;

procedure TfraPedidos.SelecionarTipoEntrega(
  const ATipo: TTipoEntregaNovoPedido);
begin
  FTipoEntregaNovoPedido := ATipo;

  if ATipo = tenDelivery then
  begin
    rctEntregaDelivery.Fill.Color := $FF1B2B3F;
    rctEntregaDelivery.Stroke.Color := $FF8C63FF;
    rctEntregaDelivery.Stroke.Thickness := 2;
    lblEntregaDelivery.TextSettings.FontColor := $FFF2F5F9;

    rctEntregaRetirada.Fill.Color := $FF152439;
    rctEntregaRetirada.Stroke.Color := $FF2A405B;
    rctEntregaRetirada.Stroke.Thickness := 1;
    lblEntregaRetirada.TextSettings.FontColor := $FF9AA8B9;
  end
  else
  begin
    rctEntregaRetirada.Fill.Color := $FF1B2B3F;
    rctEntregaRetirada.Stroke.Color := $FF8C63FF;
    rctEntregaRetirada.Stroke.Thickness := 2;
    lblEntregaRetirada.TextSettings.FontColor := $FFF2F5F9;

    rctEntregaDelivery.Fill.Color := $FF152439;
    rctEntregaDelivery.Stroke.Color := $FF2A405B;
    rctEntregaDelivery.Stroke.Thickness := 1;
    lblEntregaDelivery.TextSettings.FontColor := $FF9AA8B9;
  end;

  if ATipo = tenDelivery then
  begin
    FEditTelefone.ProximoCampo := FEditRua;
    FEditTelefone.OnEnterFinal := nil;
  end
  else
  begin
    FEditTelefone.ProximoCampo := nil;
    FEditTelefone.OnEnterFinal := btnCriarPedidoClick;
  end;

  AtualizarVisibilidadeEndereco;
  AtualizarTotaisNovoPedido;
end;

procedure TfraPedidos.CriarCamposEndereco;
begin
  FEditRua := TfraSensorEdit.Create(Self);
  FEditRua.Name := '';
  FEditRua.Parent := lytLinhaEndereco1;
  FEditRua.Align := TAlignLayout.Client;
  FEditRua.Titulo := 'Rua';
  FEditRua.Placeholder := 'Digite a rua';
  FEditRua.Obrigatorio := True;
  FEditRua.Position.Y := 0;

  FEditNumero := TfraSensorEdit.Create(Self);
  FEditNumero.Name := '';
  FEditNumero.Parent := lytLinhaEndereco1;
  FEditNumero.Align := TAlignLayout.Right;
  FEditNumero.Width := 110;
  FEditNumero.Margins.Left := 10;
  FEditNumero.Titulo := 'N�mero';
  FEditNumero.Placeholder := 'N�';
  FEditNumero.Obrigatorio := True;
  FEditNumero.Position.Y := 0;

  FEditBairro := TfraSensorEdit.Create(Self);
  FEditBairro.Name := '';
  FEditBairro.Parent := lytLinhaEndereco2;
  FEditBairro.Align := TAlignLayout.Client;
  FEditBairro.Titulo := 'Bairro';
  FEditBairro.Placeholder := 'Digite o bairro';
  FEditBairro.Obrigatorio := True;
  FEditBairro.Position.Y := 0;

  FEditComplemento := TfraSensorEdit.Create(Self);
  FEditComplemento.Name := '';
  FEditComplemento.Parent := lytLinhaEndereco2;
  FEditComplemento.Align := TAlignLayout.Right;
  FEditComplemento.Width := 180;
  FEditComplemento.Margins.Left := 10;
  FEditComplemento.Titulo := 'Complemento';
  FEditComplemento.Placeholder := 'Apartamento, bloco...';
  FEditComplemento.Position.Y := 0;

  FEditReferencia := TfraSensorEdit.Create(Self);
  FEditReferencia.Name := '';
  FEditReferencia.Parent := lytLinhaEndereco3;
  FEditReferencia.Align := TAlignLayout.Top;
  FEditReferencia.Height := 74;
  FEditReferencia.Margins.Top := 10;
  FEditReferencia.Titulo := 'Ponto de Refer�ncia';
  FEditReferencia.Placeholder := 'Ex.: Pr�ximo ao mercado';
  FEditReferencia.Position.Y := 178;

  FEditCliente.ProximoCampo := FEditTelefone;

  FEditTelefone.CampoAnterior := FEditCliente;
  FEditTelefone.ProximoCampo := FEditRua;

  FEditRua.CampoAnterior := FEditTelefone;
  FEditRua.ProximoCampo := FEditNumero;

  FEditNumero.CampoAnterior := FEditRua;
  FEditNumero.ProximoCampo := FEditBairro;

  FEditBairro.CampoAnterior := FEditNumero;
  FEditBairro.ProximoCampo := FEditComplemento;

  FEditComplemento.CampoAnterior := FEditBairro;
  FEditComplemento.ProximoCampo := FEditReferencia;

  FEditReferencia.CampoAnterior := FEditComplemento;
  FEditReferencia.OnEnterFinal := btnCriarPedidoClick;
end;

procedure TfraPedidos.AtualizarVisibilidadeEndereco;
begin
  lytEnderecoEntrega.Visible :=
    FTipoEntregaNovoPedido = tenDelivery;

  if lytEnderecoEntrega.Visible then
    lytEnderecoEntrega.Height := 350
  else
    lytEnderecoEntrega.Height := 0;
end;

procedure TfraPedidos.CriarBotaoAdicionarItem;
begin
  FBtnAdicionarItem := TfraSensorButton.Create(Self);
  FBtnAdicionarItem.Name := '';
  FBtnAdicionarItem.Parent := lytCabecalhoItens;
  FBtnAdicionarItem.Align := TAlignLayout.Right;
  FBtnAdicionarItem.Width := 150;
  FBtnAdicionarItem.Height := 38;

  FBtnAdicionarItem.Texto := 'Adicionar Item';
  FBtnAdicionarItem.Icone := sbiPedido;
  FBtnAdicionarItem.Estilo := sbsSecondary;
  FBtnAdicionarItem.OnButtonClick := btnAdicionarItemClick;
end;

procedure TfraPedidos.AbrirAdicionarItem;
begin
  if Assigned(FPopupAcoes) then
    FPopupAcoes.Fechar;

  if Assigned(FPopupStatus) then
    FPopupStatus.Fechar;

  LimparSabores;
  lytSabores.Visible := False;
  lytSabores.Height := 0;

  LimparBordas;
  lytBordas.Visible := False;
  lytBordas.Height := 0;

  LimparAdicionais;
  lytAdicionais.Visible := False;
  lytAdicionais.Height := 0;

  vsbAdicionarItem.ViewportPosition := PointF(0, 0);

  rctOverlayAdicionarItem.BringToFront;
  rctOverlayAdicionarItem.Visible := True;
end;

procedure TfraPedidos.FecharAdicionarItem;
begin
  rctOverlayAdicionarItem.Visible := False;
end;

procedure TfraPedidos.CriarPopupCategoria;
begin
  FPopupCategoria := TfraPopupMenu.Create(Self);
  FPopupCategoria.Name := '';
  FPopupCategoria.Parent := rctOverlayAdicionarItem;
  FPopupCategoria.Width := 260;
  FPopupCategoria.Visible := False;

  FPopupCategoria.OnItemClick :=
    PopupCategoriaItemClick;
end;

function TfraPedidos.EncontrarOpcao(
  ALista: TObjectList<TOpcaoCatalogoPedido>;
  const AId: string): TOpcaoCatalogoPedido;
var
  LOpcao: TOpcaoCatalogoPedido;
begin
  Result := nil;
  for LOpcao in ALista do
    if SameText(LOpcao.Id, AId) then
      Exit(LOpcao);
end;

function TfraPedidos.CarregarCatalogoPedido: Boolean;
var
  LHTTP: TNetHTTPClient;
  LResposta: IHTTPResponse;
  LValor: TJSONValue;
  LObjeto, LItem: TJSONObject;
  LArray: TJSONArray;
  LOpcao: TOpcaoCatalogoPedido;
  I: Integer;
  LPrecoPromocional: string;
begin
  Result := False;
  FCategoriasCatalogo.Clear;
  FProdutosCatalogo.Clear;
  FPopupCategoria.Limpar;
  FPopupProduto.Limpar;
  LHTTP := TNetHTTPClient.Create(nil);
  TSessaoAdmin.ConfigurarCliente(LHTTP);
  LValor := nil;
  try
    try
      LResposta := LHTTP.Get(
        TApiConfig.Url('/api/produtos/categorias/lista?empresaId=') +
        TSessaoAdmin.EmpresaId);
      if LResposta.StatusCode <> 200 then
        raise Exception.Create('A API não retornou as categorias do cardápio.');
      LValor := TJSONObject.ParseJSONValue(
        LResposta.ContentAsString(TEncoding.UTF8));
      if not (LValor is TJSONObject) then
        raise Exception.Create('Resposta inválida ao carregar categorias.');
      LObjeto := TJSONObject(LValor);
      LArray := LObjeto.GetValue<TJSONArray>('categorias');
      if Assigned(LArray) then
        for I := 0 to LArray.Count - 1 do
        begin
          LItem := LArray.Items[I] as TJSONObject;
          LOpcao := TOpcaoCatalogoPedido.Create;
          LOpcao.Id := LItem.GetValue<string>('id', '');
          LOpcao.Nome := LItem.GetValue<string>('nome', '');
          FCategoriasCatalogo.Add(LOpcao);
          FPopupCategoria.AdicionarItem(LOpcao.Id, LOpcao.Nome);
        end;
      FreeAndNil(LValor);

      LResposta := LHTTP.Get(
        TApiConfig.Url('/api/produtos?empresaId=') +
        TSessaoAdmin.EmpresaId);
      if LResposta.StatusCode <> 200 then
        raise Exception.Create('A API não retornou os produtos do cardápio.');
      LValor := TJSONObject.ParseJSONValue(
        LResposta.ContentAsString(TEncoding.UTF8));
      if not (LValor is TJSONObject) then
        raise Exception.Create('Resposta inválida ao carregar produtos.');
      LObjeto := TJSONObject(LValor);
      LArray := LObjeto.GetValue<TJSONArray>('produtos');
      if Assigned(LArray) then
        for I := 0 to LArray.Count - 1 do
        begin
          LItem := LArray.Items[I] as TJSONObject;
          LOpcao := TOpcaoCatalogoPedido.Create;
          LOpcao.Id := LItem.GetValue<string>('id', '');
          LOpcao.Nome := LItem.GetValue<string>('nome', '');
          LOpcao.CategoriaId := LItem.GetValue<string>('categoria_id', '');
          LOpcao.Preco := StrToCurrDef(LItem.GetValue<string>('preco', '0'),
            0, TFormatSettings.Invariant);
          LPrecoPromocional := LItem.GetValue<string>('preco_promocional', '');
          if not LPrecoPromocional.Trim.IsEmpty then
            LOpcao.Preco := StrToCurrDef(LPrecoPromocional, LOpcao.Preco,
              TFormatSettings.Invariant);
          FProdutosCatalogo.Add(LOpcao);
        end;

      if FCategoriasCatalogo.Count = 0 then
        raise Exception.Create('Nenhuma categoria com produtos disponíveis foi encontrada.');
      Result := True;
    except
      on E: Exception do
        TfrmMensagem.Exibir('Cardápio indisponível', E.Message, tmErro,
          False, 'OK', '');
    end;
  finally
    LValor.Free;
    LHTTP.Free;
  end;
end;

procedure TfraPedidos.CarregarParametrosPedido;
var
  LHTTP: TNetHTTPClient;
  LResposta: IHTTPResponse;
  LValor: TJSONValue;
begin
  FTaxaEntregaPadrao := 0;
  LHTTP := TNetHTTPClient.Create(nil);
  TSessaoAdmin.ConfigurarCliente(LHTTP);
  LValor := nil;
  try
    try
      LResposta := LHTTP.Get(
        TApiConfig.Url('/api/pedidos/parametros/novo-pedido'));
      if LResposta.StatusCode = 200 then
      begin
        LValor := TJSONObject.ParseJSONValue(
          LResposta.ContentAsString(TEncoding.UTF8));
        if LValor is TJSONObject then
          FTaxaEntregaPadrao := StrToCurrDef(
            TJSONObject(LValor).GetValue<string>('taxa_entrega', '0'),
            0, TFormatSettings.Invariant);
      end;
    except
      FTaxaEntregaPadrao := 0;
    end;
  finally
    LValor.Free;
    LHTTP.Free;
  end;
end;

function TfraPedidos.CarregarOpcoesProduto(
  const AProdutoId: string): Boolean;
var
  LHTTP: TNetHTTPClient;
  LResposta: IHTTPResponse;
  LValor: TJSONValue;
  LObjeto, LItem: TJSONObject;
  LArray: TJSONArray;
  LOpcao, LProduto: TOpcaoCatalogoPedido;
  I: Integer;
  LValorOpcao: Currency;
begin
  Result := False;
  FVariacoesProduto.Clear;
  FPopupTamanho.Limpar;
  LimparSabores;
  LimparBordas;
  LimparAdicionais;
  LHTTP := TNetHTTPClient.Create(nil);
  TSessaoAdmin.ConfigurarCliente(LHTTP);
  LValor := nil;
  try
    try
      LResposta := LHTTP.Get(
        TApiConfig.Url('/api/produtos/') + AProdutoId +
        '/opcoes?empresaId=' + TSessaoAdmin.EmpresaId);
      if LResposta.StatusCode <> 200 then
        raise Exception.Create('Não foi possível carregar as opções do produto.');
      LValor := TJSONObject.ParseJSONValue(
        LResposta.ContentAsString(TEncoding.UTF8));
      if not (LValor is TJSONObject) then
        raise Exception.Create('Resposta inválida para as opções do produto.');
      LObjeto := TJSONObject(LValor);

      LArray := LObjeto.GetValue<TJSONArray>('variacoes');
      if Assigned(LArray) then
        for I := 0 to LArray.Count - 1 do
        begin
          LItem := LArray.Items[I] as TJSONObject;
          LOpcao := TOpcaoCatalogoPedido.Create;
          LOpcao.Id := LItem.GetValue<string>('id', '');
          LOpcao.Nome := LItem.GetValue<string>('nome', '');
          LOpcao.Preco := StrToCurrDef(LItem.GetValue<string>('preco', '0'),
            0, TFormatSettings.Invariant);
          FVariacoesProduto.Add(LOpcao);
        end;
      if FVariacoesProduto.Count = 0 then
      begin
        LProduto := EncontrarOpcao(FProdutosCatalogo, AProdutoId);
        LOpcao := TOpcaoCatalogoPedido.Create;
        LOpcao.Id := 'SEM_VARIACAO';
        LOpcao.Nome := 'Único';
        if Assigned(LProduto) then LOpcao.Preco := LProduto.Preco;
        FVariacoesProduto.Add(LOpcao);
      end;
      AtualizarPopupTamanho;

      LArray := LObjeto.GetValue<TJSONArray>('sabores');
      if Assigned(LArray) then
        for I := 0 to LArray.Count - 1 do
        begin
          LItem := LArray.Items[I] as TJSONObject;
          LValorOpcao := StrToCurrDef(
            LItem.GetValue<string>('valor_adicional', '0'), 0,
            TFormatSettings.Invariant);
          AdicionarSabor(LItem.GetValue<string>('id', ''),
            LItem.GetValue<string>('nome', ''), LValorOpcao);
        end;

      LArray := LObjeto.GetValue<TJSONArray>('bordas');
      if Assigned(LArray) then
        for I := 0 to LArray.Count - 1 do
        begin
          LItem := LArray.Items[I] as TJSONObject;
          LValorOpcao := StrToCurrDef(LItem.GetValue<string>('valor', '0'),
            0, TFormatSettings.Invariant);
          AdicionarBorda(LItem.GetValue<string>('id', ''),
            LItem.GetValue<string>('nome', ''), LValorOpcao);
        end;

      LArray := LObjeto.GetValue<TJSONArray>('adicionais');
      if Assigned(LArray) then
        for I := 0 to LArray.Count - 1 do
        begin
          LItem := LArray.Items[I] as TJSONObject;
          LValorOpcao := StrToCurrDef(LItem.GetValue<string>('preco', '0'),
            0, TFormatSettings.Invariant);
          AdicionarAdicional(LItem.GetValue<string>('id', ''),
            LItem.GetValue<string>('nome', ''), LValorOpcao);
        end;

      AtualizarVisibilidadeSabores;
      AtualizarVisibilidadeBordas;
      AtualizarVisibilidadeAdicionais;
      Result := True;
    except
      on E: Exception do
        TfrmMensagem.Exibir('Opções indisponíveis', E.Message, tmErro,
          False, 'OK', '');
    end;
  finally
    LValor.Free;
    LHTTP.Free;
  end;
end;

procedure TfraPedidos.CriarPopupProduto;
begin
  FPopupProduto := TfraPopupMenu.Create(Self);
  FPopupProduto.Name := '';
  FPopupProduto.Parent := rctOverlayAdicionarItem;
  FPopupProduto.Width := 300;
  FPopupProduto.Visible := False;

  FPopupProduto.OnItemClick :=
    PopupProdutoItemClick;
end;

procedure TfraPedidos.AtualizarPopupProduto;
var
  LProduto: TOpcaoCatalogoPedido;
begin
  FPopupProduto.Limpar;
  for LProduto in FProdutosCatalogo do
    if SameText(LProduto.CategoriaId, FCategoriaSelecionada) then
      FPopupProduto.AdicionarItem(LProduto.Id, LProduto.Nome);
end;

procedure TfraPedidos.CriarPopupTamanho;
begin
  FPopupTamanho := TfraPopupMenu.Create(Self);
  FPopupTamanho.Name := '';
  FPopupTamanho.Parent := rctOverlayAdicionarItem;
  FPopupTamanho.Width := 260;
  FPopupTamanho.Visible := False;

  FPopupTamanho.OnItemClick :=
    PopupTamanhoItemClick;
end;

procedure TfraPedidos.AtualizarPopupTamanho;
var
  LVariacao: TOpcaoCatalogoPedido;
begin
  FPopupTamanho.Limpar;
  for LVariacao in FVariacoesProduto do
    FPopupTamanho.AdicionarItem(LVariacao.Id, LVariacao.Nome);
end;

procedure TfraPedidos.AtualizarVisibilidadeSabores;
var
  LMostrar: Boolean;
begin
  LMostrar := lytItensSabores.ChildrenCount > 0;

  if LMostrar then
  begin
    lytSabores.Visible := True;
    lytSabores.Height := 240;

    rctListaSabores.Visible := True;
    vsbListaSabores.Visible := True;
    lytItensSabores.Visible := True;
  end
  else
  begin
    lytSabores.Visible := False;
    lytSabores.Height := 0;
  end;

  AtualizarPosicoesAdicionarItem;
end;

procedure TfraPedidos.AlternarSabor(
  const AIdentificador: string;
  const AItem: TRectangle;
  const ACheck: TRectangle);
var
  LIndice: Integer;
begin
  LIndice := FSaboresSelecionados.IndexOf(AIdentificador);

  if LIndice >= 0 then
  begin
    FSaboresSelecionados.Delete(LIndice);

    AItem.Fill.Color := $00FFFFFF;
    ACheck.Fill.Color := $FF152439;
    ACheck.Stroke.Color := $FF2A405B;
  end
  else
  begin
    if FSaboresSelecionados.Count >= 2 then
    begin
      TfrmMensagem.Exibir(
        'Limite de Sabores',
        'Voc� pode selecionar no m�ximo 2 sabores.',
        tmAtencao,
        False,
        'OK',
        ''
      );

      Exit;
    end;

    FSaboresSelecionados.Add(AIdentificador);

    AItem.Fill.Color := $221A2C42;
    ACheck.Fill.Color := $FF8C63FF;
    ACheck.Stroke.Color := $FF8C63FF;
  end;

  lblLimiteSabores.Text :=
    Format(
      '%d de 2 sabores selecionados',
      [FSaboresSelecionados.Count]
    );
end;

procedure TfraPedidos.LimparSabores;
var
  I: Integer;
begin
  for I := lytItensSabores.ChildrenCount - 1 downto 0 do
    lytItensSabores.Children[I].Free;

  lytItensSabores.Height := 1;

  if Assigned(FSaboresSelecionados) then
    FSaboresSelecionados.Clear;

  lblLimiteSabores.Text :=
    'Selecione at� 2 Sabores';
end;

procedure TfraPedidos.memObservacaoItemApplyStyleLookup(Sender: TObject);
var
  LRecurso: TFmxObject;
begin
  LRecurso := memObservacaoItem.FindStyleResource('background');

  if LRecurso is TControl then
    TControl(LRecurso).Visible := False;
end;

procedure TfraPedidos.AdicionarSabor(
  const ASaborId: string;
  const ADescricao: string;
  const AValor: Currency);
var
  LItem: TfraItemSabor;
  LAlturaAtual: Single;
begin
  LAlturaAtual := lytItensSabores.Height;

  LItem := TfraItemSabor.Create(nil);
  try
    LItem.Name := '';
    LItem.Parent := lytItensSabores;
    LItem.Align := TAlignLayout.Top;
    LItem.Height := 42;

    LItem.Margins.Left := 0;
    LItem.Margins.Top := 0;
    LItem.Margins.Right := 0;
    LItem.Margins.Bottom := 4;

    LItem.Preencher(
      ASaborId,
      ADescricao,
      AValor
    );

    LItem.OnSelecionado := SaborSelecionado;

    lytItensSabores.Height :=
      LAlturaAtual +
      LItem.Height +
      LItem.Margins.Bottom;
  except
    LItem.Free;
    raise;
  end;
end;

procedure TfraPedidos.SaborSelecionado(
  Sender: TObject;
  const ASaborId: string;
  const ASelecionado: Boolean);
var
  LItem: TfraItemSabor;
  LIndice: Integer;
begin
  if not (Sender is TfraItemSabor) then
    Exit;

  LItem := TfraItemSabor(Sender);
  LIndice := FSaboresSelecionados.IndexOf(ASaborId);

  if ASelecionado then
  begin
    if LIndice < 0 then
      FSaboresSelecionados.Add(ASaborId);

    if FSaboresSelecionados.Count > 2 then
    begin
      FSaboresSelecionados.Delete(
        FSaboresSelecionados.IndexOf(ASaborId)
      );

      LItem.Selecionado := False;

      TfrmMensagem.Exibir(
        'Limite de Sabores',
        'Voc� pode selecionar no m�ximo 2 Sabores.',
        tmAtencao,
        False,
        'OK',
        ''
      );
    end;
  end
  else if LIndice >= 0 then
    FSaboresSelecionados.Delete(LIndice);

  lblLimiteSabores.Text :=
    Format(
      '%d de 2 Sabores selecionados',
      [FSaboresSelecionados.Count]
    );

  AtualizarValorItem;
end;

procedure TfraPedidos.LimparBordas;
var
  I: Integer;
begin
  for I := lytItensBordas.ChildrenCount - 1 downto 0 do
    lytItensBordas.Children[I].Free;

  lytItensBordas.Height := 0;
  FBordaSelecionadaId := '';
end;

procedure TfraPedidos.AdicionarBorda(
  const ABordaId: string;
  const ADescricao: string;
  const AValor: Currency);
var
  LItem: TfraItemBorda;
begin
  LItem := TfraItemBorda.Create(nil);
  try
    LItem.Name := '';
    LItem.Parent := lytItensBordas;
    LItem.Align := TAlignLayout.Top;
    LItem.Height := 42;

    LItem.Margins.Left := 0;
    LItem.Margins.Top := 0;
    LItem.Margins.Right := 0;
    LItem.Margins.Bottom := 4;

    LItem.Preencher(
      ABordaId,
      ADescricao,
      AValor
    );

    LItem.OnSelecionado := BordaSelecionada;

    lytItensBordas.Height :=
      lytItensBordas.Height +
      LItem.Height +
      LItem.Margins.Bottom;

  except
    LItem.Free;
    raise;
  end;
end;

procedure TfraPedidos.BordaSelecionada(
  Sender: TObject;
  const ABordaId: string);
var
  I: Integer;
  LItem: TfraItemBorda;
begin
  FBordaSelecionadaId := ABordaId;

  for I := 0 to lytItensBordas.ChildrenCount - 1 do
  begin
    if not (lytItensBordas.Children[I] is TfraItemBorda) then
      Continue;

    LItem := TfraItemBorda(
      lytItensBordas.Children[I]
    );

    LItem.Selecionado :=
      SameText(LItem.BordaId, ABordaId);
  end;

  AtualizarValorItem;
end;

procedure TfraPedidos.AtualizarVisibilidadeBordas;
var
  LMostrar: Boolean;
begin
  LMostrar := lytItensBordas.ChildrenCount > 0;

  if LMostrar then
  begin
    lytBordas.Visible := True;
    lytBordas.Height := 210;
  end
  else
  begin
    lytBordas.Visible := False;
    lytBordas.Height := 0;
  end;

  AtualizarPosicoesAdicionarItem;
end;

procedure TfraPedidos.LimparAdicionais;
var
  I: Integer;
begin
  for I := lytItensAdicionais.ChildrenCount - 1 downto 0 do
    lytItensAdicionais.Children[I].Free;

  lytItensAdicionais.Height := 0;
  FAdicionaisSelecionados.Clear;
end;

procedure TfraPedidos.AdicionarAdicional(
  const AAdicionalId: string;
  const ADescricao: string;
  const AValor: Currency);
var
  LItem: TfraItemAdicional;
begin
  LItem := TfraItemAdicional.Create(nil);
  try
    LItem.Name := '';
    LItem.Parent := lytItensAdicionais;
    LItem.Align := TAlignLayout.Top;
    LItem.Height := 42;
    LItem.Margins.Bottom := 4;

    LItem.Preencher(
      AAdicionalId,
      ADescricao,
      AValor
    );

    LItem.OnSelecionado := AdicionalSelecionado;

    lytItensAdicionais.Height :=
      lytItensAdicionais.Height +
      LItem.Height +
      LItem.Margins.Bottom;
  except
    LItem.Free;
    raise;
  end;
end;

procedure TfraPedidos.AdicionalSelecionado(
  Sender: TObject;
  const AAdicionalId: string;
  const ASelecionado: Boolean);
var
  LIndice: Integer;
begin
  LIndice :=
    FAdicionaisSelecionados.IndexOf(AAdicionalId);

  if ASelecionado then
  begin
    if LIndice < 0 then
      FAdicionaisSelecionados.Add(AAdicionalId);
  end
  else if LIndice >= 0 then
    FAdicionaisSelecionados.Delete(LIndice);

  AtualizarValorItem;
end;

procedure TfraPedidos.AtualizarQuantidadeItem;
begin
  lblQuantidade.Text := FQuantidadeItem.ToString;

  rctDiminuirQuantidade.Enabled :=
    FQuantidadeItem > 1;

  if rctDiminuirQuantidade.Enabled then
    lblMenos.TextSettings.FontColor := $FFF2F5F9
  else
    lblMenos.TextSettings.FontColor := $FF64758B;

  AtualizarValorItem;
end;

procedure TfraPedidos.PopupAcoesItemClick(
  Sender: TObject;
  const AIdentificador: string);
begin
  if not Assigned(FItemPedidoSelecionado) then
    Exit;

  if SameText(AIdentificador, 'DETALHES') then
  begin
    AbrirDetalhesPedido;
  end
  else if SameText(AIdentificador, 'STATUS') then
  begin
    AbrirDetalhesPedido;
    rctAlterarStatusDetalheClick(nil);
  end
  else if SameText(AIdentificador, 'IMPRIMIR') then
  begin
    rctImprimirDetalheClick(nil);
  end
  else if SameText(AIdentificador, 'CANCELAR') then
  begin
    rctCancelarDetalheClick(nil);
  end;
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

  TfrmMensagem.Exibir(
    'Imprimir pedido',
    'Pedido ' +
      FItemPedidoSelecionado.NumeroPedido +
      ' enviado para impress�o.',
    tmInformacao,
    False,
    'OK',
    ''
  );
end;

procedure TfraPedidos.rctCancelarDetalheClick(
  Sender: TObject);
var
  LPedidoId: string;
  LNumeroPedido: string;
  LErro: string;
begin
  if not Assigned(FItemPedidoSelecionado) then
    Exit;

  { Copia os dados antes de abrir a confirma��o.
    Assim n�o dependemos mais do cart�o durante a opera��o. }
  LPedidoId :=
    FItemPedidoSelecionado.PedidoId;

  LNumeroPedido :=
    FItemPedidoSelecionado.NumeroPedido;

  if LPedidoId.Trim.IsEmpty then
  begin
    TfrmMensagem.Exibir(
      'N�o foi poss�vel cancelar o pedido',
      'O pedido n�o possui um identificador v�lido.',
      tmErro,
      False,
      'OK',
      ''
    );

    Exit;
  end;

  tmrAtualizarPedidos.Enabled := False;

  try
    if not TfrmMensagem.Exibir(
      'Cancelar pedido',
      'Deseja realmente cancelar o pedido ' +
        LNumeroPedido + '?',
      tmConfirmacao,
      True,
      'Cancelar pedido',
      'Voltar'
    ) then
      Exit;

    if not AtualizarStatusPedidoAPI(
      LPedidoId,
      'Cancelado',
      LErro
    ) then
    begin
      TfrmMensagem.Exibir(
        'N�o foi poss�vel cancelar o pedido',
        LErro,
        tmErro,
        False,
        'OK',
        ''
      );

      Exit;
    end;

    if Assigned(FPopupAcoes) then
      FPopupAcoes.Fechar;

    if Assigned(FPopupStatus) then
      FPopupStatus.Fechar;

    rctOverlayDetalhes.Visible := False;
    FItemPedidoSelecionado := nil;

    CarregarPedidosAPI;
  finally
    tmrAtualizarPedidos.Enabled := True;
  end;
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

procedure TfraPedidos.rctSelecionarCategoriaClick(Sender: TObject);
var
  LPonto: TPointF;
begin
  if not Assigned(FPopupCategoria) then
    Exit;

  LPonto :=
    rctSelecionarCategoria.LocalToAbsolute(
      PointF(
        rctSelecionarCategoria.Width,
        rctSelecionarCategoria.Height
      )
    );

  LPonto :=
    rctOverlayAdicionarItem.AbsoluteToLocal(LPonto);

  FPopupCategoria.Abrir(
    LPonto.X - FPopupCategoria.Width,
    LPonto.Y + 4
  );
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

procedure TfraPedidos.rctNovoPedidoClick(Sender: TObject);
begin
  AbrirNovoPedido;
end;

procedure TfraPedidos.rctFecharNovoPedidoClick(Sender: TObject);
begin
  FecharNovoPedido;
end;

procedure TfraPedidos.rctCancelarNovoPedidoClick(Sender: TObject);
begin
  FecharNovoPedido;
end;

procedure TfraPedidos.btnNovoPedidoClick(Sender: TObject);
begin
  AbrirNovoPedido;
end;

procedure TfraPedidos.btnCancelarNovoPedidoClick(
  Sender: TObject);
begin
  FecharNovoPedido;
end;

procedure TfraPedidos.btnCriarPedidoClick(Sender: TObject);
begin
  if not ValidarNovoPedido then
    Exit;

  PrepararPedido;

  if not EnviarPedidoAPI then
    Exit;

  TfrmMensagem.Exibir(
    'Pedido Criado',
    'Pedido enviado com sucesso.',
    tmSucesso,
    False,
    'OK',
    ''
  );

  FecharNovoPedido;
end;

procedure TfraPedidos.rctEntregaDeliveryClick(
  Sender: TObject);
begin
  SelecionarTipoEntrega(tenDelivery);
end;

procedure TfraPedidos.rctEntregaRetiradaClick(
  Sender: TObject);
begin
  SelecionarTipoEntrega(tenRetirada);
end;

procedure TfraPedidos.btnAdicionarItemClick(Sender: TObject);
begin
  AbrirAdicionarItem;
end;

procedure TfraPedidos.rctFecharAdicionarItemClick(Sender: TObject);
begin
  FecharAdicionarItem;
end;

procedure TfraPedidos.SeletorMouseEnter(Sender: TObject);
begin
  if Sender is TRectangle then
  begin
    TRectangle(Sender).Fill.Color := $FF1C2E45;
    TRectangle(Sender).Stroke.Color := $FF3A506C;
  end;
end;

procedure TfraPedidos.SeletorMouseLeave(Sender: TObject);
begin
  if Sender is TRectangle then
  begin
    TRectangle(Sender).Fill.Color := $FF152439;
    TRectangle(Sender).Stroke.Color := $FF2A405B;
  end;
end;

procedure TfraPedidos.PopupCategoriaItemClick(
  Sender: TObject;
  const AIdentificador: string);
var
  LCategoria: TOpcaoCatalogoPedido;
begin
  FCategoriaSelecionada := AIdentificador;

  FProdutoSelecionado := '';
  FTamanhoSelecionado := '';
  FBordaSelecionadaId := '';
  FValorBaseItem := 0;
  FVariacoesProduto.Clear;
  FPopupTamanho.Limpar;
  LimparSabores;
  LimparBordas;
  LimparAdicionais;

  LCategoria := EncontrarOpcao(FCategoriasCatalogo, AIdentificador);
  if Assigned(LCategoria) then
    lblCategoriaSelecionada.Text := LCategoria.Nome
  else
    lblCategoriaSelecionada.Text := 'Categoria';

  lblCategoriaSelecionada.TextSettings.FontColor :=
    $FFF2F5F9;

  lblProdutoSelecionado.Text :=
    'Selecione o Produto';

  lblProdutoSelecionado.TextSettings.FontColor :=
    $FF8F9EB2;

  lblTamanhoSelecionado.Text :=
    'Selecione o Tamanho';

  lblTamanhoSelecionado.TextSettings.FontColor :=
    $FF8F9EB2;

  AtualizarPopupProduto;

  AtualizarVisibilidadeSabores;
  AtualizarVisibilidadeBordas;
  AtualizarVisibilidadeAdicionais;
  AtualizarValorItem;
  AtualizarPosicoesAdicionarItem;
end;

procedure TfraPedidos.PopupProdutoItemClick(
  Sender: TObject;
  const AIdentificador: string);
var
  LProduto: TOpcaoCatalogoPedido;
begin
  LProduto := EncontrarOpcao(FProdutosCatalogo, AIdentificador);
  if not Assigned(LProduto) then
    Exit;

  FProdutoSelecionado := AIdentificador;
  lblProdutoSelecionado.Text := LProduto.Nome;

  lblProdutoSelecionado.TextSettings.FontColor :=
    $FFF2F5F9;

  FTamanhoSelecionado := '';

  lblTamanhoSelecionado.Text :=
    'Selecione o Tamanho';

  lblTamanhoSelecionado.TextSettings.FontColor :=
    $FF8F9EB2;

  if not CarregarOpcoesProduto(AIdentificador) then
  begin
    FProdutoSelecionado := '';
    lblProdutoSelecionado.Text := 'Selecione o Produto';
    Exit;
  end;

  if FVariacoesProduto.Count = 1 then
    PopupTamanhoItemClick(nil, FVariacoesProduto[0].Id);
  AtualizarPosicoesAdicionarItem;
end;

procedure TfraPedidos.rctSelecionarProdutoClick(
  Sender: TObject);
var
  LPonto: TPointF;
begin
  if FCategoriaSelecionada.Trim.IsEmpty then
  begin
    TfrmMensagem.Exibir(
      'Selecione a Categoria',
      'Escolha uma categoria antes de selecionar o produto.',
      tmAtencao,
      False,
      'OK',
      ''
    );

    Exit;
  end;

  if not Assigned(FPopupProduto) then
    Exit;

  LPonto :=
    rctSelecionarProduto.LocalToAbsolute(
      PointF(
        rctSelecionarProduto.Width,
        rctSelecionarProduto.Height
      )
    );

  LPonto :=
    rctOverlayAdicionarItem.AbsoluteToLocal(LPonto);

  FPopupProduto.Abrir(
    LPonto.X - FPopupProduto.Width,
    LPonto.Y + 4
  );
end;

procedure TfraPedidos.rctSelecionarTamanhoClick(
  Sender: TObject);
var
  LPonto: TPointF;
begin
  if FProdutoSelecionado.Trim.IsEmpty then
  begin
    TfrmMensagem.Exibir(
      'Selecione o Produto',
      'Escolha um produto antes de selecionar o tamanho.',
      tmAtencao,
      False,
      'OK',
      ''
    );

    Exit;
  end;

  if not Assigned(FPopupTamanho) then
    Exit;

  LPonto :=
    rctSelecionarTamanho.LocalToAbsolute(
      PointF(
        rctSelecionarTamanho.Width,
        rctSelecionarTamanho.Height
      )
    );

  LPonto :=
    rctOverlayAdicionarItem.AbsoluteToLocal(LPonto);

  FPopupTamanho.Abrir(
    LPonto.X - FPopupTamanho.Width,
    LPonto.Y + 4
  );
end;

procedure TfraPedidos.PopupTamanhoItemClick(
  Sender: TObject;
  const AIdentificador: string);
var
  LVariacao: TOpcaoCatalogoPedido;
begin
  LVariacao := EncontrarOpcao(FVariacoesProduto, AIdentificador);
  if not Assigned(LVariacao) then
    Exit;

  FTamanhoSelecionado := AIdentificador;
  lblTamanhoSelecionado.Text := LVariacao.Nome;

  lblTamanhoSelecionado.TextSettings.FontColor :=
    $FFF2F5F9;

  DefinirValorBaseItem;
end;

procedure TfraPedidos.rctDiminuirQuantidadeClick(
  Sender: TObject);
begin
  if FQuantidadeItem <= 1 then
    Exit;

  Dec(FQuantidadeItem);
  AtualizarQuantidadeItem;
end;

procedure TfraPedidos.rctAumentarQuantidadeClick(
  Sender: TObject);
begin
  Inc(FQuantidadeItem);
  AtualizarQuantidadeItem;
end;

procedure TfraPedidos.AtualizarValorItem;
var
  LValorUnitario: Currency;
  LValorTotal: Currency;
begin
  LValorUnitario := ObterValorUnitarioItem;

  LValorTotal :=
    LValorUnitario *
    FQuantidadeItem;

  lblValorItem.Text :=
    FormatFloat(
      '"R$ " #,##0.00',
      LValorTotal
    );
end;

procedure TfraPedidos.DefinirValorBaseItem;
var
  LVariacao: TOpcaoCatalogoPedido;
  LProduto: TOpcaoCatalogoPedido;
begin
  FValorBaseItem := 0;
  LVariacao := EncontrarOpcao(FVariacoesProduto, FTamanhoSelecionado);
  if Assigned(LVariacao) then
    FValorBaseItem := LVariacao.Preco
  else
  begin
    LProduto := EncontrarOpcao(FProdutosCatalogo, FProdutoSelecionado);
    if Assigned(LProduto) then
      FValorBaseItem := LProduto.Preco;
  end;

  AtualizarValorItem;
end;

function TfraPedidos.ObterValorSabores: Currency;
var
  I: Integer;
  LItem: TfraItemSabor;
begin
  Result := 0;

  for I := 0 to lytItensSabores.ChildrenCount - 1 do
  begin
    if not (lytItensSabores.Children[I] is TfraItemSabor) then
      Continue;

    LItem := TfraItemSabor(
      lytItensSabores.Children[I]
    );

    if LItem.Selecionado then
      Result := Result + LItem.Valor;
  end;
end;

function TfraPedidos.ObterValorBorda: Currency;
var
  I: Integer;
  LItem: TfraItemBorda;
begin
  Result := 0;

  for I := 0 to lytItensBordas.ChildrenCount - 1 do
  begin
    if not (lytItensBordas.Children[I] is TfraItemBorda) then
      Continue;

    LItem := TfraItemBorda(
      lytItensBordas.Children[I]
    );

    if LItem.Selecionado then
      Exit(LItem.Valor);
  end;
end;

function TfraPedidos.ObterValorAdicionais: Currency;
var
  I: Integer;
  LItem: TfraItemAdicional;
begin
  Result := 0;

  for I := 0 to lytItensAdicionais.ChildrenCount - 1 do
  begin
    if not (
      lytItensAdicionais.Children[I] is TfraItemAdicional
    ) then
      Continue;

    LItem := TfraItemAdicional(
      lytItensAdicionais.Children[I]
    );

    if LItem.Selecionado then
      Result := Result + LItem.Valor;
  end;
end;

function TfraPedidos.ObterValorUnitarioItem: Currency;
begin
  Result :=
    FValorBaseItem +
    ObterValorSabores +
    ObterValorBorda +
    ObterValorAdicionais;
end;

procedure TfraPedidos.AtualizarPosicoesAdicionarItem;
const
  ESPACO = 14;
var
  LY: Single;
begin
  { Seletores: categoria, produto e tamanho }
  LY := lytSelecaoProduto.Position.Y +
        lytSelecaoProduto.Height +
        ESPACO;

  { Sabores }
  if lytSabores.Visible then
  begin
    lytSabores.Position.Y := LY;
    LY := LY + lytSabores.Height + ESPACO;
  end;

  { Bordas }
  if lytBordas.Visible then
  begin
    lytBordas.Position.Y := LY;
    LY := LY + lytBordas.Height + ESPACO;
  end;

  { Adicionais }
  if lytAdicionais.Visible then
  begin
    lytAdicionais.Position.Y := LY;
    LY := LY + lytAdicionais.Height + ESPACO;
  end;

  { Quantidade, observa��o e total }
  lytFinalizacaoItem.Position.Y := LY;

  { Altura total do conte�do rol�vel }
  lytConteudoAdicionarItem.Height :=
    lytFinalizacaoItem.Position.Y +
    lytFinalizacaoItem.Height +
    30;
end;

procedure TfraPedidos.CriarBotaoAdicionarAoPedido;
begin
  FBtnAdicionarAoPedido := TfraSensorButton.Create(Self);
  FBtnAdicionarAoPedido.Name := '';
  FBtnAdicionarAoPedido.Parent := lytRodapeAdicionarItem;
  FBtnAdicionarAoPedido.Align := TAlignLayout.Client;
  FBtnAdicionarAoPedido.Height := 42;

  FBtnAdicionarAoPedido.Texto := 'Adicionar ao Pedido';
  FBtnAdicionarAoPedido.Icone := sbiSalvar;
  FBtnAdicionarAoPedido.Estilo := sbsPrimary;
  FBtnAdicionarAoPedido.OnButtonClick :=
    btnAdicionarAoPedidoClick;
end;

procedure TfraPedidos.btnAdicionarAoPedidoClick(
  Sender: TObject);
var
  LItem: TItemPedidoNovo;
begin
  LItem := MontarItemPedido;

  if not Assigned(LItem) then
    Exit;

  FPedidoNovo.Itens.Add(LItem);
  AtualizarListaItensNovoPedido;
  AtualizarTotaisNovoPedido;

  TfrmMensagem.Exibir(
    'Item adicionado',
    Format(
      '%dx %s adicionado ao Pedido.',
      [
        LItem.Quantidade,
        LItem.ProdutoDescricao
      ]
    ),
    tmSucesso,
    False,
    'OK',
    ''
  );

  FecharAdicionarItem;
end;

function TfraPedidos.ValidarItemSelecionado: Boolean;
begin
  Result := False;

  if FCategoriaSelecionada.Trim.IsEmpty then
  begin
    TfrmMensagem.Exibir(
      'Categoria n�o selecionada',
      'Selecione uma Categoria.',
      tmAtencao,
      False,
      'OK',
      ''
    );
    Exit;
  end;

  if FProdutoSelecionado.Trim.IsEmpty then
  begin
    TfrmMensagem.Exibir(
      'Produto n�o selecionado',
      'Selecione um Produto.',
      tmAtencao,
      False,
      'OK',
      ''
    );
    Exit;
  end;

  if FTamanhoSelecionado.Trim.IsEmpty then
  begin
    TfrmMensagem.Exibir(
      'Tamanho n�o selecionado',
      'Selecione um Tamanho.',
      tmAtencao,
      False,
      'OK',
      ''
    );
    Exit;
  end;

  if (lytItensSabores.ChildrenCount > 0) and
     (FSaboresSelecionados.Count = 0) then
  begin
    TfrmMensagem.Exibir(
      'Sabor n�o selecionado',
      'Selecione pelo menos um Sabor.',
      tmAtencao,
      False,
      'OK',
      ''
    );
    Exit;
  end;

  Result := True;
end;

function TfraPedidos.MontarItemPedido: TItemPedidoNovo;
var
  I: Integer;
  LItem: TItemPedidoNovo;
  LSaborVisual: TfraItemSabor;
  LSabor: TSaborPedido;
  LBordaVisual: TfraItemBorda;
  LAdicionalVisual: TfraItemAdicional;
  LAdicional: TAdicionalPedido;
begin
  Result := nil;

  if not ValidarItemSelecionado then
    Exit;

  LItem := TItemPedidoNovo.Create;

  try
    LItem.Categoria := lblCategoriaSelecionada.Text;

    LItem.ProdutoId := FProdutoSelecionado;
    LItem.ProdutoDescricao := lblProdutoSelecionado.Text;

    LItem.TamanhoId := FTamanhoSelecionado;
    LItem.TamanhoDescricao := lblTamanhoSelecionado.Text;

    LItem.Quantidade := FQuantidadeItem;
    LItem.Observacao := memObservacaoItem.Text.Trim;

    LItem.ValorBase := FValorBaseItem;

    { Sabores }
    for I := 0 to lytItensSabores.ChildrenCount - 1 do
    begin
      if not (lytItensSabores.Children[I] is TfraItemSabor) then
        Continue;

      LSaborVisual :=
        TfraItemSabor(lytItensSabores.Children[I]);

      if not LSaborVisual.Selecionado then
        Continue;

      LSabor := TSaborPedido.Create;
      LSabor.Id := LSaborVisual.SaborId;
      LSabor.Descricao := LSaborVisual.Descricao;
      LSabor.Valor := LSaborVisual.Valor;

      LItem.Sabores.Add(LSabor);
    end;

    { Borda }
    for I := 0 to lytItensBordas.ChildrenCount - 1 do
    begin
      if not (lytItensBordas.Children[I] is TfraItemBorda) then
        Continue;

      LBordaVisual :=
        TfraItemBorda(lytItensBordas.Children[I]);

      if not LBordaVisual.Selecionado then
        Continue;

      LItem.BordaId := LBordaVisual.BordaId;
      LItem.BordaDescricao := LBordaVisual.Descricao;
      LItem.ValorBorda := LBordaVisual.Valor;

      Break;
    end;

    { Adicionais }
    for I := 0 to lytItensAdicionais.ChildrenCount - 1 do
    begin
      if not (
        lytItensAdicionais.Children[I] is TfraItemAdicional
      ) then
        Continue;

      LAdicionalVisual :=
        TfraItemAdicional(
          lytItensAdicionais.Children[I]
        );

      if not LAdicionalVisual.Selecionado then
        Continue;

      LAdicional := TAdicionalPedido.Create;
      LAdicional.Id := LAdicionalVisual.AdicionalId;
      LAdicional.Descricao := LAdicionalVisual.Descricao;
      LAdicional.Valor := LAdicionalVisual.Valor;
      LAdicional.Quantidade := 1;

      LItem.Adicionais.Add(LAdicional);
    end;

    Result := LItem;
  except
    LItem.Free;
    raise;
  end;
end;

procedure TfraPedidos.AtualizarListaItensNovoPedido;
var
  I: Integer;
  LItemVisual: TfraItemNovoPedido;
begin
  for I := lytListaItensNovoPedido.ChildrenCount - 1 downto 0 do
    lytListaItensNovoPedido.Children[I].Free;

  lytListaItensNovoPedido.Height := 0;

  lblListaVazia.Visible :=
    FPedidoNovo.Itens.Count = 0;

  if FPedidoNovo.Itens.Count = 0 then
    Exit;

  for I := 0 to FPedidoNovo.Itens.Count - 1 do
  begin
    LItemVisual := TfraItemNovoPedido.Create(nil);

    try
      LItemVisual.Name := '';
      LItemVisual.Parent := lytListaItensNovoPedido;
      LItemVisual.Align := TAlignLayout.Top;
      LItemVisual.Height := 88;
      LItemVisual.Margins.Bottom := 8;

      LItemVisual.Preencher(
        FPedidoNovo.Itens[I]
      );

      LItemVisual.OnExcluir := ItemNovoPedidoExcluir;

      lytListaItensNovoPedido.Height :=
        lytListaItensNovoPedido.Height +
        LItemVisual.Height +
        LItemVisual.Margins.Bottom;
    except
      LItemVisual.Free;
      raise;
    end;
  end;
end;

procedure TfraPedidos.ItemNovoPedidoExcluir(
  Sender: TObject;
  const AItem: TItemPedidoNovo);
begin
  if not Assigned(AItem) then
    Exit;

  if not TfrmMensagem.Exibir(
    'Excluir Item',
    'Deseja remover ' + AItem.ProdutoDescricao + ' do Pedido?',
    tmConfirmacao,
    True,
    'Excluir',
    'Voltar'
  ) then
    Exit;

  FPedidoNovo.Itens.Remove(AItem);

  AtualizarListaItensNovoPedido;
  AtualizarTotaisNovoPedido;
end;

procedure TfraPedidos.AtualizarVisibilidadeAdicionais;
var
  LMostrar: Boolean;
begin
  LMostrar := lytItensAdicionais.ChildrenCount > 0;

  if LMostrar then
  begin
    lytAdicionais.Visible := True;
    lytAdicionais.Height := 220;
  end
  else
  begin
    lytAdicionais.Visible := False;
    lytAdicionais.Height := 0;
  end;

  AtualizarPosicoesAdicionarItem;
end;

procedure TfraPedidos.AtualizarTotaisNovoPedido;
begin
  if not Assigned(FPedidoNovo) then
    Exit;

  lblSubtotalNovoPedidoValor.Text :=
    FormatFloat(
      '"R$ " #,##0.00',
      FPedidoNovo.SubTotal
    );

  lblTaxaNovoPedidoValor.Text :=
    FormatFloat(
      '"R$ " #,##0.00',
      FPedidoNovo.TaxaEntrega
    );

  lblTotalNovoPedidoValor.Text :=
    FormatFloat(
      '"R$ " #,##0.00',
      FPedidoNovo.Total
    );

  lytConteudoNovoPedido.Height := rctResumoNovoPedido.Position.Y + rctResumoNovoPedido.Height + 30;
end;

function TfraPedidos.ValidarNovoPedido: Boolean;
var
  LValido: Boolean;
begin
  LValido := True;

  if not FEditCliente.Validar then
    LValido := False;

  if not FEditTelefone.Validar then
    LValido := False;

  if FTipoEntregaNovoPedido = tenDelivery then
  begin
    if not FEditRua.Validar then
      LValido := False;

    if not FEditNumero.Validar then
      LValido := False;

    if not FEditBairro.Validar then
      LValido := False;
  end;

  if FPedidoNovo.Itens.Count = 0 then
  begin
    TfrmMensagem.Exibir(
      'Pedido sem Itens',
      'Adicione pelo menos um Item ao Pedido.',
      tmAtencao,
      False,
      'OK',
      ''
    );

    LValido := False;
  end;

  Result := LValido;
end;

procedure TfraPedidos.PrepararPedido;
begin
  FPedidoNovo.ClienteNome :=
    FEditCliente.Texto;

  FPedidoNovo.Telefone :=
    FEditTelefone.Texto;

  if FTipoEntregaNovoPedido = tenDelivery then
    FPedidoNovo.TipoEntrega := 'DELIVERY'
  else
    FPedidoNovo.TipoEntrega := 'RETIRADA';

  if FTipoEntregaNovoPedido = tenDelivery then
  begin
    FPedidoNovo.Endereco :=
      FEditRua.Texto + ', ' +
      FEditNumero.Texto +
      ' - ' +
      FEditBairro.Texto;

    if not FEditComplemento.Texto.Trim.IsEmpty then
      FPedidoNovo.Endereco :=
        FPedidoNovo.Endereco +
        ' (' +
        FEditComplemento.Texto +
        ')';
  end
  else
    FPedidoNovo.Endereco := '';

  FPedidoNovo.DataHora := Now;

  FPedidoNovo.Status := 'NOVO';
end;

procedure TfraPedidos.TestarPedidoMontado;
var
  S: string;
begin
  S :=
    'Cliente: ' + FPedidoNovo.ClienteNome + sLineBreak +
    'Telefone: ' + FPedidoNovo.Telefone + sLineBreak +
    'Entrega: ' + FPedidoNovo.TipoEntrega + sLineBreak +
    'Itens: ' + IntToStr(FPedidoNovo.Itens.Count) + sLineBreak +
    'Subtotal: ' +
    CurrToStrF(FPedidoNovo.SubTotal, ffCurrency, 2);

  TfrmMensagem.Exibir(
    'Pedido',
    S,
    tmInformacao,
    False,
    'OK',
    ''
  );
end;

procedure TfraPedidos.tmrAtualizarPedidosTimer(
  Sender: TObject);
begin
  if not Visible then
    Exit;

  if rctOverlayDetalhes.Visible then
    Exit;

  CarregarPedidosAPI;
end;

function TfraPedidos.PedidoParaJSON: TJSONObject;
var
  LJSON: TJSONObject;
  LItens: TJSONArray;
  LItemJSON: TJSONObject;
  LSabores: TJSONArray;
  LSaborJSON: TJSONObject;
  LAdicionais: TJSONArray;
  LAdicionalJSON: TJSONObject;

  LItem: TItemPedidoNovo;
  LSabor: TSaborPedido;
  LAdicional: TAdicionalPedido;
begin
  LJSON := TJSONObject.Create;

  LJSON.AddPair('empresaId', TSessaoAdmin.EmpresaId);

  if not FPedidoNovo.ClienteId.Trim.IsEmpty then
    LJSON.AddPair('clienteId', FPedidoNovo.ClienteId)
  else
    LJSON.AddPair('clienteId', TJSONNull.Create);

  LJSON.AddPair(
    'clienteNome',
    FPedidoNovo.ClienteNome
  );

  LJSON.AddPair(
    'clienteTelefone',
    FPedidoNovo.Telefone
  );

  if FPedidoNovo.TipoEntrega = 'DELIVERY' then
    LJSON.AddPair('tipoAtendimento', 'ENTREGA')
  else
    LJSON.AddPair('tipoAtendimento', 'RETIRADA');

  if not FPedidoNovo.Endereco.Trim.IsEmpty then
    LJSON.AddPair(
      'enderecoTexto',
      FPedidoNovo.Endereco
    )
  else
    LJSON.AddPair(
      'enderecoTexto',
      TJSONNull.Create
    );

  LJSON.AddPair(
    'observacoes',
    FPedidoNovo.Observacao
  );

  LJSON.AddPair(
    'subtotal',
    TJSONNumber.Create(FPedidoNovo.SubTotal)
  );

  LJSON.AddPair(
    'taxaEntrega',
    TJSONNumber.Create(FPedidoNovo.TaxaEntrega)
  );

  LJSON.AddPair(
    'desconto',
    TJSONNumber.Create(FPedidoNovo.Desconto)
  );

  LJSON.AddPair(
    'acrescimo',
    TJSONNumber.Create(0)
  );

  LJSON.AddPair(
    'valorTotal',
    TJSONNumber.Create(FPedidoNovo.Total)
  );

  LItens := TJSONArray.Create;

  for LItem in FPedidoNovo.Itens do
  begin
    LItemJSON := TJSONObject.Create;

{    if not LItem.ProdutoId.Trim.IsEmpty then
      LItemJSON.AddPair(
        'produtoId',
        LItem.ProdutoId
      )
    else
      LItemJSON.AddPair(
        'produtoId',
        TJSONNull.Create
      );}

    if not LItem.ProdutoId.Trim.IsEmpty then
      LItemJSON.AddPair('produtoId', LItem.ProdutoId)
    else
      LItemJSON.AddPair('produtoId', TJSONNull.Create);

    LItemJSON.AddPair(
      'produtoDescricao',
      LItem.ProdutoDescricao
    );

    LItemJSON.AddPair(
      'categoria',
      LItem.Categoria
    );

{    if not LItem.TamanhoId.Trim.IsEmpty then
      LItemJSON.AddPair(
        'tamanhoId',
        LItem.TamanhoId
      )
    else
      LItemJSON.AddPair(
        'tamanhoId',
        TJSONNull.Create
      );}

    if not LItem.TamanhoId.Trim.IsEmpty and
       not SameText(LItem.TamanhoId, 'SEM_VARIACAO') then
      LItemJSON.AddPair('tamanhoId', LItem.TamanhoId)
    else
      LItemJSON.AddPair('tamanhoId', TJSONNull.Create);

    LItemJSON.AddPair(
      'tamanhoDescricao',
      LItem.TamanhoDescricao
    );

{    if not LItem.BordaId.Trim.IsEmpty then
      LItemJSON.AddPair(
        'bordaId',
        LItem.BordaId
      )
    else
      LItemJSON.AddPair(
        'bordaId',
        TJSONNull.Create
      );}

    if not LItem.BordaId.Trim.IsEmpty then
      LItemJSON.AddPair('bordaId', LItem.BordaId)
    else
      LItemJSON.AddPair('bordaId', TJSONNull.Create);

    LItemJSON.AddPair(
      'bordaDescricao',
      LItem.BordaDescricao
    );

    LItemJSON.AddPair(
      'valorBorda',
      TJSONNumber.Create(LItem.ValorBorda)
    );

    LItemJSON.AddPair(
      'quantidade',
      TJSONNumber.Create(LItem.Quantidade)
    );

    LItemJSON.AddPair(
      'valorBase',
      TJSONNumber.Create(LItem.ValorBase)
    );

    LItemJSON.AddPair(
      'valorUnitario',
      TJSONNumber.Create(LItem.ValorUnitario)
    );

    LItemJSON.AddPair(
      'valorTotal',
      TJSONNumber.Create(LItem.ValorTotal)
    );

    LItemJSON.AddPair(
      'observacao',
      LItem.Observacao
    );

    LSabores := TJSONArray.Create;

    for LSabor in LItem.Sabores do
    begin
      LSaborJSON := TJSONObject.Create;

{      if not LSabor.Id.Trim.IsEmpty then
        LSaborJSON.AddPair(
          'id',
          LSabor.Id
        )
      else
        LSaborJSON.AddPair(
          'id',
          TJSONNull.Create
        );}

      if not LSabor.Id.Trim.IsEmpty then
        LSaborJSON.AddPair('id', LSabor.Id)
      else
        LSaborJSON.AddPair('id', TJSONNull.Create);

      LSaborJSON.AddPair(
        'descricao',
        LSabor.Descricao
      );

      LSaborJSON.AddPair(
        'valor',
        TJSONNumber.Create(LSabor.Valor)
      );

      LSabores.AddElement(LSaborJSON);
    end;

    LItemJSON.AddPair(
      'sabores',
      LSabores
    );

    LAdicionais := TJSONArray.Create;

    for LAdicional in LItem.Adicionais do
    begin
      LAdicionalJSON := TJSONObject.Create;

{      if not LAdicional.Id.Trim.IsEmpty then
        LAdicionalJSON.AddPair(
          'id',
          LAdicional.Id
        )
      else
        LAdicionalJSON.AddPair(
          'id',
          TJSONNull.Create
        );}

      if not LAdicional.Id.Trim.IsEmpty then
        LAdicionalJSON.AddPair('id', LAdicional.Id)
      else
        LAdicionalJSON.AddPair('id', TJSONNull.Create);

      LAdicionalJSON.AddPair(
        'descricao',
        LAdicional.Descricao
      );

      LAdicionalJSON.AddPair(
        'valor',
        TJSONNumber.Create(LAdicional.Valor)
      );

      LAdicionalJSON.AddPair(
        'quantidade',
        TJSONNumber.Create(LAdicional.Quantidade)
      );

      LAdicionais.AddElement(LAdicionalJSON);
    end;

    LItemJSON.AddPair(
      'adicionais',
      LAdicionais
    );

    LItens.AddElement(LItemJSON);
  end;

  LJSON.AddPair(
    'itens',
    LItens
  );

  Result := LJSON;
end;

function TfraPedidos.EnviarPedidoAPI: Boolean;
var
  LHTTP: TNetHTTPClient;
  LJSON: TJSONObject;
  LStream: TStringStream;
  LResposta: IHTTPResponse;
begin
  Result := False;

  LHTTP := TNetHTTPClient.Create(nil);
  TSessaoAdmin.ConfigurarCliente(LHTTP);
  LJSON := nil;
  LStream := nil;

  try
    try
      LJSON := PedidoParaJSON;

      LStream := TStringStream.Create(
        LJSON.ToJSON,
        TEncoding.UTF8
      );

      LHTTP.ContentType := 'application/json';
      LHTTP.Accept := 'application/json';

      LResposta := LHTTP.Post(
        TApiConfig.Url('/api/pedidos'),
        LStream
      );

      if LResposta.StatusCode = 201 then
      begin
        Result := True;
        Exit;
      end;

      TfrmMensagem.Exibir(
        'Erro ao Criar Pedido',
        'A API retornou: ' +
        IntToStr(LResposta.StatusCode) +
        sLineBreak +
        LResposta.ContentAsString(TEncoding.UTF8),
        tmErro,
        False,
        'OK',
        ''
      );

    except
      on E: Exception do
      begin
        TfrmMensagem.Exibir(
          'Erro de Comunica��o',
          E.Message,
          tmErro,
          False,
          'OK',
          ''
        );
      end;
    end;
  finally
    LStream.Free;
    LJSON.Free;
    LHTTP.Free;
  end;
end;

procedure TfraPedidos.CampoNovoPedidoRecebeuFoco(Sender: TObject);
var
  LCampo: TfraSensorEdit;
  LPonto: TPointF;
  LTopo: Single;
  LBase: Single;
  LViewportTopo: Single;
  LViewportBase: Single;
  LNovaPosicao: Single;
const
  MARGEM = 20;
begin
  if not (Sender is TfraSensorEdit) then
    Exit;

  LCampo := TfraSensorEdit(Sender);

  LPonto :=
    LCampo.LocalToAbsolute(
      PointF(0, 0)
    );

  LPonto :=
    lytConteudoNovoPedido.AbsoluteToLocal(
      LPonto
    );

  LTopo := LPonto.Y;
  LBase := LTopo + LCampo.Height;

  LViewportTopo :=
    vsbNovoPedido.ViewportPosition.Y;

  LViewportBase :=
    LViewportTopo +
    vsbNovoPedido.Height;

  LNovaPosicao := LViewportTopo;

  { Campo est� abaixo da �rea vis�vel }
  if LBase + MARGEM > LViewportBase then
    LNovaPosicao :=
      LBase -
      vsbNovoPedido.Height +
      MARGEM

  { Campo est� acima da �rea vis�vel }
  else if LTopo - MARGEM < LViewportTopo then
    LNovaPosicao :=
      LTopo - MARGEM;

  if LNovaPosicao < 0 then
    LNovaPosicao := 0;

  vsbNovoPedido.ViewportPosition :=
    PointF(
      0,
      LNovaPosicao
    );
end;

procedure TfraPedidos.CarregarPedidosAPI;
var
  LHTTP: TNetHTTPClient;
  LResposta: IHTTPResponse;
  LJSON: TJSONObject;
  LPedidos: TJSONArray;
  LPedido: TJSONObject;
  I: Integer;

  LNumero: string;
  LCliente: string;
  LTelefone: string;
  LTipo: string;
  LStatus: string;
  LHorario: string;
  LEndereco: string;
  LNumeroInt: Integer;
  LPedidoId: string;

  LDataHora: TDateTime;
  LTotal: Currency;
  LMaiorNumero: Integer;
  LMaiorCliente: string;
  LMaiorTotal: Currency;
begin
  LHTTP := TNetHTTPClient.Create(nil);
  TSessaoAdmin.ConfigurarCliente(LHTTP);
  LJSON := nil;

  try
    try
      LHTTP.Accept := 'application/json';

      LResposta := LHTTP.Get(
        TApiConfig.Url('/api/pedidos')
      );

      if LResposta.StatusCode <> 200 then
      begin
        TfrmMensagem.Exibir(
          'Erro ao Carregar Pedidos',
          'A API retornou: ' +
          IntToStr(LResposta.StatusCode),
          tmErro,
          False,
          'OK',
          ''
        );

        Exit;
      end;

      LJSON :=
        TJSONObject.ParseJSONValue(
          LResposta.ContentAsString(TEncoding.UTF8)
        ) as TJSONObject;

      if not Assigned(LJSON) then
        Exit;

      LPedidos :=
        LJSON.GetValue<TJSONArray>('pedidos');

      if not Assigned(LPedidos) then
        Exit;

      { Limpa os cards atuais }
      for I := lytItensPedidos.ChildrenCount - 1 downto 0 do
        lytItensPedidos.Children[I].Free;

      lytItensPedidos.Height := 0;

      LMaiorNumero := 0;
      LMaiorCliente := '';
      LMaiorTotal := 0;

      { Cria os cards retornados pela API }
      for I := 0 to LPedidos.Count - 1 do
      begin
        LPedido :=
          LPedidos.Items[I] as TJSONObject;

        LPedidoId := LPedido.GetValue<string>('id', '');

        { N�mero }
        LNumero := LPedido.GetValue<string>('numero', '');

        LNumeroInt := StrToIntDef(LNumero, 0);

        if not LNumero.IsEmpty then
          LNumero := '#' + LNumero;

        { Cliente }
        LCliente :=
          LPedido.GetValue<string>(
            'cliente_nome',
            ''
          );

        { Telefone }
        LTelefone :=
          LPedido.GetValue<string>(
            'cliente_telefone',
            ''
          );

        { Endere�o }
        LEndereco :=
          LPedido.GetValue<string>(
            'endereco_texto',
            ''
          );

        { Tipo de atendimento }
        LTipo :=
          LPedido.GetValue<string>(
            'tipo_atendimento',
            ''
          );

        if SameText(LTipo, 'ENTREGA') then
          LTipo := 'Delivery'
        else if SameText(LTipo, 'RETIRADA') then
          LTipo := 'Retirada';

        { Status }
        LStatus :=
          LPedido.GetValue<string>(
            'status',
            ''
          );

        if SameText(LStatus, 'RASCUNHO') or SameText(LStatus, 'NOVO') then
          LStatus := 'Novo'
        else if SameText(LStatus, 'CONFIRMADO') then
          LStatus := 'Confirmado'
        else if SameText(LStatus, 'EM_PREPARO') then
          LStatus := 'Em preparo'
        else if SameText(LStatus, 'PRONTO') then
          LStatus := 'Pronto'
        else if SameText(LStatus, 'SAIU_PARA_ENTREGA') then
          LStatus := 'Em entrega'
        else if SameText(LStatus, 'ENTREGUE') then
          LStatus := 'Finalizado'
        else if SameText(LStatus, 'CANCELADO') then
          LStatus := 'Cancelado';

        { Hor�rio }
        LHorario := '';

        if TryISO8601ToDate(
          LPedido.GetValue<string>(
            'criado_em',
            ''
          ),
          LDataHora,
          False
        ) then
          LHorario :=
            FormatDateTime(
              'hh:nn',
              LDataHora
            );

        { Total }
        LTotal :=
          StrToCurrDef(
            LPedido.GetValue<string>(
              'valor_total',
              '0'
            ),
            0,
            TFormatSettings.Invariant
          );

        if LNumeroInt > LMaiorNumero then
        begin
          LMaiorNumero := LNumeroInt;
          LMaiorCliente := LCliente;
          LMaiorTotal := LTotal;
        end;

        AdicionarPedido(
          LNumero,
          LCliente,
          LTelefone,
          LTipo,
          LStatus,
          LHorario,
          LEndereco,
          LTotal,
          LPedidoId
        );
      end;

      if FPrimeiraCargaPedidos then
      begin
        FUltimoNumeroPedido := LMaiorNumero;
        FPrimeiraCargaPedidos := False;
      end
      else if LMaiorNumero > FUltimoNumeroPedido then
      begin
        AlertarNovoPedido(LMaiorNumero, LMaiorCliente, LMaiorTotal);
        FUltimoNumeroPedido := LMaiorNumero;
      end;

    except
      on E: Exception do
      begin
        TfrmMensagem.Exibir(
          'Erro ao Carregar Pedidos',
          E.Message,
          tmErro,
          False,
          'OK',
          ''
        );
      end;
    end;
  finally
    LJSON.Free;
    LHTTP.Free;
  end;
end;

procedure TfraPedidos.AlertarNovoPedido(
  ANumero: Integer;
  const ACliente: string;
  const ATotal: Currency);
begin
  TAlertaNovoPedido.Exibir(ANumero, ACliente, ATotal);
end;

function TfraPedidos.StatusParaAPI(
  const AStatus: string): string;
begin
  if SameText(AStatus, 'Novo') then
    Exit('RASCUNHO');

  if SameText(AStatus, 'Confirmado') then
    Exit('CONFIRMADO');

  if SameText(AStatus, 'Em preparo') then
    Exit('EM_PREPARO');

  if SameText(AStatus, 'Pronto') then
    Exit('PRONTO');

  if SameText(AStatus, 'Em entrega') then
    Exit('SAIU_PARA_ENTREGA');

  if SameText(AStatus, 'Finalizado') then
    Exit('ENTREGUE');

  Result := UpperCase(AStatus);
end;

function TfraPedidos.AtualizarStatusPedidoAPI(
  const APedidoId: string;
  const AStatus: string;
  out AErro: string): Boolean;
var
  LHTTP: TNetHTTPClient;
  LResposta: IHTTPResponse;
  LJSON: TJSONObject;
  LStream: TStringStream;
  LURL: string;
begin
  Result := False;
  AErro := '';

  if APedidoId.Trim.IsEmpty then
  begin
    AErro := 'O pedido n�o possui um identificador v�lido.';
    Exit;
  end;

  LHTTP := TNetHTTPClient.Create(nil);
  TSessaoAdmin.ConfigurarCliente(LHTTP);
  LJSON := TJSONObject.Create;
  LStream := nil;

  try
    try
      LHTTP.Accept := 'application/json';
      LHTTP.ContentType := 'application/json';
      LHTTP.ConnectionTimeout := 5000;
      LHTTP.ResponseTimeout := 15000;

      LJSON.AddPair(
        'status',
        StatusParaAPI(AStatus)
      );

      LStream :=
        TStringStream.Create(
          LJSON.ToJSON,
          TEncoding.UTF8
        );

      LURL :=
        TApiConfig.Url('/api/pedidos/') +
        APedidoId +
        '/status';

      LResposta :=
        LHTTP.Patch(LURL, LStream);

      if LResposta.StatusCode <> 200 then
      begin
        AErro :=
          'A API retornou o c�digo ' +
          LResposta.StatusCode.ToString +
          '.' +
          sLineBreak +
          LResposta.ContentAsString(
            TEncoding.UTF8
          );

        Exit;
      end;

      Result := True;
    except
      on E: Exception do
        AErro :=
          'N�o foi poss�vel alterar o status.' +
          sLineBreak +
          E.Message;
    end;
  finally
    LResposta := nil;
    LStream.Free;
    LJSON.Free;
    LHTTP.Free;
  end;
end;

end.
