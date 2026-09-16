unit uPrincipal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Objects,
  FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls, FMX.TabControl,
  uFrameInicio, uCarrinhoModel, uFrameMontarPizza, uFrameCarrinho,
  uFrameFinalizarPedido, uPedidoModel, uPedidoService, uFrameHomeMobile,
  System.JSON, System.Net.URLClient, System.Net.HttpClient, System.Net.HttpClientComponent,
  uFrameAcompanharPedido, uPedidoLocal, uFrameSituacaoLoja, uFrameEntradaLoja,
  uFrameContaMobile, uFrameHistoricoPedidos, uHistoricoPedidoModel, uEmpresaApp,
  uApiConfig, uMensagemMobile, uFramePagamentoPix;

type
  TfrmPrincipal = class(TForm)
    lytSistema: TLayout;
    rctTopo: TRectangle;
    lblSaudacao: TLabel;
    lblEndereco: TLabel;
    rctNotificacoes: TRectangle;
    lblIconeNotificacao: TLabel;
    crlStatusOnline: TCircle;
    tcPrincipal: TTabControl;
    tabInicio: TTabItem;
    tabCardapio: TTabItem;
    tabPedidos: TTabItem;
    tabCarrinho: TTabItem;
    tabPerfil: TTabItem;
    rctMenuInferior: TRectangle;
    tabMontarPizza: TTabItem;
    tabFinalizarPedido: TTabItem;
    tabAcompanharPedido: TTabItem;
    tabSituacaoLoja: TTabItem;
    tabEntradaLoja: TTabItem;
    lytMenuMobile: TLayout;
    lytInicio: TLayout;
    lytCardapio: TLayout;
    lytPedidos: TLayout;
    lytConta: TLayout;
    lblIconeInicio: TLabel;
    lblInicio: TLabel;
    lblIconeCardapio: TLabel;
    lblCardapio: TLabel;
    lblIconePedidos: TLabel;
    lblPedidos: TLabel;
    lblIconeConta: TLabel;
    lblConta: TLabel;
    rctIndicadorInicio: TRectangle;
    rctIndicadorCardapio: TRectangle;
    rctIndicadorConta: TRectangle;
    rctIndicadorPedidos: TRectangle;
    rctResumoCarrinho: TRectangle;
    lblIconeCarrinho: TLabel;
    lblVerCarrinho: TLabel;
    lblSubCarrinho: TLabel;
    rctQtdCarrinho: TRectangle;
    lblQtdCarrinho: TLabel;
    tabConta: TTabItem;
    procedure lytMenuInicioClick(Sender: TObject);
    procedure lytMenuCardapioClick(Sender: TObject);
    procedure lytMenuPedidosClick(Sender: TObject);
    procedure lytMenuCarrinhoClick(Sender: TObject);
    procedure lytMenuPerfilClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure EntradaLojaClick(Sender: TObject);
    procedure rctResumoCarrinhoClick(Sender: TObject);
    procedure MenuInicioClick(Sender: TObject);
    procedure MenuCardapioClick(Sender: TObject);
    procedure MenuPedidosClick(Sender: TObject);
    procedure MenuContaClick(Sender: TObject);
  private
    FHomeMobile: TfraHomeMobile;
    FFraInicio: TfraInicio;
    FMontarPizza: TfraMontarPizza;
    FCarrinho: TfraCarrinho;
    FFraFinalizarPedido: TfraFinalizarPedido;
    FAcompanharPedido: TfraAcompanharPedido;
    FSituacaoLoja: TfraSituacaoLoja;
    FEntradaLoja: TfraEntradaLoja;
    FContaMobile: TfraContaMobile;
    FHistoricoPedidos: TfraHistoricoPedidos;
    FPagamentoPix: TfraPagamentoPix;
    FTabPagamentoPix: TTabItem;
    FPedidoPixId: string;
    FPedidoPixNumero: Integer;
    FVerificacaoEmAndamento: Boolean;
    FTokenVerificacao: Integer;
    FTemporizadorConexao: TTimer;

    FLojaAberta: Boolean;
    FMensagemLoja: string;
    FPermitirResumoCarrinho: Boolean;
    FAcompanhamentoVeioDoHistorico: Boolean;

    procedure SelecionarAba(const AIndice: Integer);
    procedure AtualizarMenu(const AIndice: Integer);
    procedure AbrirMontagemPizza;
    procedure FecharMontagemPizza(Sender: TObject);
    procedure PizzaAdicionada(Sender: TObject);
    procedure CarrinhoAlterado(Sender: TObject);
    procedure AtualizarContadorCarrinho;
    procedure ProdutoSelecionado(Sender: TObject; const AProdutoId: Integer);
    procedure AbrirCarrinho;
    procedure CarrinhoVoltar(Sender: TObject);
    procedure CarrinhoContinuarComprando(Sender: TObject);
    procedure CarrinhoFinalizarPedido(Sender: TObject);
    procedure AbrirFinalizacaoPedido;
    procedure FinalizacaoVoltar(Sender: TObject);
    procedure PedidoConfirmado(Sender: TObject; ADados: TDadosFinalizacaoPedido);
    procedure AbrirPagamentoPix(const APedidoId: string;
      const ANumeroPedido: Integer; const ACodigoPix, AQRCodeBase64: string;
      const AValor: Currency);
    procedure PagamentoPixContinuar(Sender: TObject);
    procedure PagamentoPixCancelado(Sender: TObject);
    procedure CriarFrames;
    procedure CriarNovaHome;
    procedure HomeProdutoSelecionado(Sender: TObject; const AProdutoId: string);
    procedure AbrirMontarProduto(const AProdutoId: string);
    procedure HomePizzaSelecionada(Sender: TObject; const AProdutoId: string; const AVariacaoId: string;
      const AVariacaoNome: string; const APreco: Currency);
    procedure PizzaAdicionadaAoCarrinho(Sender: TObject);
    procedure AbrirAcompanhamentoPedido(const APedidoId: string; const ANumeroPedido: Integer);
    procedure AcompanhamentoVoltarInicio(Sender: TObject);
    procedure VerificarSituacaoLoja;
    procedure TempoConexaoEsgotado(Sender: TObject);
    procedure SituacaoLojaTentarNovamente(Sender: TObject);
    procedure MostrarTelaSituacaoLoja;
    procedure MostrarHomeNormal;
    procedure HomeAbrirCarrinho(Sender: TObject);
    procedure PermitirResumoCarrinho(const APermitir: Boolean);
    procedure AtualizarVisualMenu(const AItem: Integer);
    procedure AbrirConta;
    procedure CarrinhoAdicionarMaisItens(Sender: TObject);
    procedure MontarPizzaVoltar(Sender: TObject);
    procedure InicializarAplicativo;
    procedure MostrarEntradaLoja;
    procedure AtualizarResumoCarrinho;
    procedure AbrirHistoricoPedidos;
    procedure HistoricoAcompanhar(Sender: TObject; APedido: TPedidoHistorico);
    procedure HistoricoRepetir(Sender: TObject; APedido: TPedidoHistorico);

procedure MontarCarrinhoDoHistorico(
  APedido: TPedidoHistorico
);

    function EnviarPedidoAPI(APedido: TPedido; out APedidoId: string;
      out ANumeroPedido: Integer; out APixCodigo,
      APixQRCodeBase64: string): Boolean;
  public
    { Public declarations }
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

{$R *.fmx}

procedure TfrmPrincipal.CriarNovaHome;
begin
  if Assigned(FHomeMobile) then
    Exit;

  FHomeMobile := TfraHomeMobile.Create(Self);
  FHomeMobile.Name := '';
  FHomeMobile.Parent := tabInicio;
  FHomeMobile.Align := TAlignLayout.Client;
  FHomeMobile.OnProdutoSelecionado := HomeProdutoSelecionado;
  FHomeMobile.Visible := True;
  if Assigned(FHomeMobile) then
  FHomeMobile.OnAbrirCarrinho := HomeAbrirCarrinho;
end;

procedure TfrmPrincipal.CriarFrames;
var
  LFilho: TFmxObject;
  LControle: TControl;
begin
  FFraInicio := TfraInicio.Create(tabInicio);
  FFraInicio.Parent := tabInicio;
  FFraInicio.Align := TAlignLayout.Client;
  FFraInicio.OnProdutoSelecionado := ProdutoSelecionado;

  FMontarPizza := TfraMontarPizza.Create(tabMontarPizza);
  FMontarPizza.Parent := tabMontarPizza;
  FMontarPizza.Align := TAlignLayout.Client;
  FMontarPizza.OnVoltar := MontarPizzaVoltar;
  FMontarPizza.OnAdicionado := PizzaAdicionada;

  if not Assigned(FCarrinho) then
  begin
    FCarrinho := TfraCarrinho.Create(tabCarrinho);
    FCarrinho.Parent := tabCarrinho;
    FCarrinho.Align := TAlignLayout.Client;
    FCarrinho.OnVoltar := CarrinhoVoltar;
    FCarrinho.OnContinuarComprando := CarrinhoContinuarComprando;
  end;
  FCarrinho.OnFinalizarPedido := CarrinhoFinalizarPedido;
  FCarrinho.OnAdicionarMaisItens := CarrinhoAdicionarMaisItens;

  FFraFinalizarPedido := TfraFinalizarPedido.Create(tabFinalizarPedido);
  FFraFinalizarPedido.Parent := tabFinalizarPedido;
  FFraFinalizarPedido.Align := TAlignLayout.Client;
  FFraFinalizarPedido.OnVoltar := FinalizacaoVoltar;
  FFraFinalizarPedido.OnPedidoConfirmado := PedidoConfirmado;
end;

procedure TfrmPrincipal.SelecionarAba(const AIndice: Integer);
begin
  if (AIndice < 0) or (AIndice >= tcPrincipal.TabCount) then
    Exit;

  tcPrincipal.TabIndex := AIndice;
  AtualizarMenu(AIndice);
end;

procedure TfrmPrincipal.AtualizarMenu(const AIndice: Integer);
const
  COR_ATIVA: TAlphaColor = $FF6C5CE7;
  COR_INATIVA: TAlphaColor = $FF9A9EAA;
begin
{  lblIconeInicio.TextSettings.FontColor := COR_INATIVA;
  lblMenuInicio.TextSettings.FontColor := COR_INATIVA;

  lblIconeCardapio.TextSettings.FontColor := COR_INATIVA;
  lblMenuCardapio.TextSettings.FontColor := COR_INATIVA;

  lblIconePedidos.TextSettings.FontColor := COR_INATIVA;
  lblMenuPedidos.TextSettings.FontColor := COR_INATIVA;

  lblIconeCarrinho.TextSettings.FontColor := COR_INATIVA;
  lblMenuCarrinho.TextSettings.FontColor := COR_INATIVA;

  lblIconePerfil.TextSettings.FontColor := COR_INATIVA;
  lblMenuPerfil.TextSettings.FontColor := COR_INATIVA;

  rctIndicadorInicio.Visible := False;
  rctIndicadorCardapio.Visible := False;
  rctIndicadorPedidos.Visible := False;
  rctIndicadorCarrinho.Visible := False;
  rctIndicadorPerfil.Visible := False;

  case AIndice of
    0:
      begin
        lblIconeInicio.TextSettings.FontColor := COR_ATIVA;
        lblMenuInicio.TextSettings.FontColor := COR_ATIVA;
        rctIndicadorInicio.Visible := True;
      end;

    1:
      begin
        lblIconeCardapio.TextSettings.FontColor := COR_ATIVA;
        lblMenuCardapio.TextSettings.FontColor := COR_ATIVA;
        rctIndicadorCardapio.Visible := True;
      end;

    2:
      begin
        lblIconePedidos.TextSettings.FontColor := COR_ATIVA;
        lblMenuPedidos.TextSettings.FontColor := COR_ATIVA;
        rctIndicadorPedidos.Visible := True;
      end;

    3:
      begin
        lblIconeCarrinho.TextSettings.FontColor := COR_ATIVA;
        lblMenuCarrinho.TextSettings.FontColor := COR_ATIVA;
        rctIndicadorCarrinho.Visible := True;
      end;

    4:
      begin
        lblIconePerfil.TextSettings.FontColor := COR_ATIVA;
        lblMenuPerfil.TextSettings.FontColor := COR_ATIVA;
        rctIndicadorPerfil.Visible := True;
      end;
  end;}
end;

procedure TfrmPrincipal.AbrirMontagemPizza;
begin
  PermitirResumoCarrinho(False);
  FMontarPizza.PrepararTela;

  rctTopo.Visible := False;
  rctMenuInferior.Visible := False;

  tcPrincipal.ActiveTab := tabMontarPizza;
end;

procedure TfrmPrincipal.FecharMontagemPizza(
  Sender: TObject);
begin
  rctTopo.Visible := True;
  rctMenuInferior.Visible := True;

  tcPrincipal.ActiveTab := tabInicio;
  AtualizarMenu(0);
end;

procedure TfrmPrincipal.PizzaAdicionada(Sender: TObject);
begin
  AbrirCarrinho;
end;

procedure TfrmPrincipal.ProdutoSelecionado(Sender: TObject; const AProdutoId: Integer);
begin
  { Por enquanto todos os produtos de teste abrirão
    a montagem da pizza. Depois verificaremos o tipo
    retornado pela API. }

  AbrirMontagemPizza;
end;

procedure TfrmPrincipal.rctResumoCarrinhoClick(Sender: TObject);
begin
  AbrirCarrinho;
end;

procedure TfrmPrincipal.AtualizarContadorCarrinho;
var
  LQuantidade: Integer;
begin
  LQuantidade := TCarrinho.Instancia.QuantidadeProdutos;

//  lblQuantidadeCarrinho.Text := LQuantidade.ToString;
//  crlQuantidadeCarrinho.Visible := LQuantidade > 0;
end;

procedure TfrmPrincipal.CarrinhoAlterado(
  Sender: TObject);
begin
  AtualizarResumoCarrinho;
end;

procedure TfrmPrincipal.AbrirCarrinho;
begin
  if not Assigned(FCarrinho) then
  begin
    FCarrinho := TfraCarrinho.Create(Self);
    FCarrinho.Name := '';
    FCarrinho.Parent := tabCarrinho;
    FCarrinho.Align := TAlignLayout.Client;
  end;

  { Sempre associa, mesmo se o frame já existia }
  FCarrinho.OnVoltar :=
    CarrinhoVoltar;

  FCarrinho.OnContinuarComprando :=
    CarrinhoContinuarComprando;

  FCarrinho.OnFinalizarPedido :=
    CarrinhoFinalizarPedido;

  FCarrinho.OnAdicionarMaisItens :=
    CarrinhoAdicionarMaisItens;

  PermitirResumoCarrinho(False);

  tabCarrinho.Visible := True;

  FCarrinho.AtualizarCarrinho;

  tcPrincipal.ActiveTab := tabCarrinho;

  FCarrinho.Visible := True;
  FCarrinho.BringToFront;

  rctMenuInferior.Visible := False;
  PermitirResumoCarrinho(False);
end;

procedure TfrmPrincipal.CarrinhoVoltar(Sender: TObject);
begin
  MostrarHomeNormal;
end;

procedure TfrmPrincipal.CarrinhoContinuarComprando(Sender: TObject);
begin
  MostrarHomeNormal;
  AtualizarVisualMenu(1);
end;

procedure TfrmPrincipal.CarrinhoFinalizarPedido(Sender: TObject);
begin
  AbrirFinalizacaoPedido;
end;

procedure TfrmPrincipal.AbrirFinalizacaoPedido;
begin
  if TCarrinho.Instancia.QuantidadeItens = 0 then
  begin
    TMensagemMobile.Exibir('Seu carrinho está vazio.');
    Exit;
  end;

  if not Assigned(FFraFinalizarPedido) then
  begin
    FFraFinalizarPedido :=
      TfraFinalizarPedido.Create(Self);

    FFraFinalizarPedido.Name := '';
    FFraFinalizarPedido.Parent := tabFinalizarPedido;
    FFraFinalizarPedido.Align := TAlignLayout.Client;
  end;

  PermitirResumoCarrinho(False);

  { IMPORTANTE: deixe fora do IF }
  FFraFinalizarPedido.OnVoltar :=
    FinalizacaoVoltar;

  FFraFinalizarPedido.OnPedidoConfirmado :=
    PedidoConfirmado;

  rctTopo.Visible := False;
  rctMenuInferior.Visible := False;

  tabFinalizarPedido.Visible := True;

  FFraFinalizarPedido.TaxaEntrega := 8.00;
  FFraFinalizarPedido.PrepararTela;

  tcPrincipal.ActiveTab := tabFinalizarPedido;

  FFraFinalizarPedido.Visible := True;
  FFraFinalizarPedido.BringToFront;

  rctMenuInferior.Visible := False;
  PermitirResumoCarrinho(False);
end;

procedure TfrmPrincipal.FinalizacaoVoltar(
  Sender: TObject);
begin
  rctTopo.Visible := False;
  rctMenuInferior.Visible := False;
  PermitirResumoCarrinho(False);

  if Assigned(FCarrinho) then
    FCarrinho.AtualizarCarrinho;

  tcPrincipal.ActiveTab :=
    tabCarrinho;
end;

procedure TfrmPrincipal.PedidoConfirmado(
  Sender: TObject;
  ADados: TDadosFinalizacaoPedido);
var
  LPedido: TPedido;
  LPedidoId: string;
  LNumeroPedido: Integer;
  LPixCodigo: string;
  LPixQRCodeBase64: string;
begin
  LPedido := TPedido.Create;

  try
    LPedido.EmpresaId := TEmpresaApp.Id;

    LPedido.CarregarDadosFinalizacao(
      ADados
    );

    LPedido.CarregarDoCarrinho;

    if not EnviarPedidoAPI(
      LPedido,
      LPedidoId,
      LNumeroPedido,
      LPixCodigo,
      LPixQRCodeBase64
    ) then
      Exit;

    TPedidoLocal.Salvar(LPedidoId, LNumeroPedido);

    if Assigned(FFraFinalizarPedido) then
      FFraFinalizarPedido.SalvarDadosClienteLocal;

    TCarrinho.Instancia.Limpar;

    if SameText(ADados.FormaPagamento, 'PIX') and
       not LPixCodigo.IsEmpty and
       not LPixQRCodeBase64.IsEmpty then
      AbrirPagamentoPix(
        LPedidoId,
        LNumeroPedido,
        LPixCodigo,
        LPixQRCodeBase64,
        ADados.Total
      )
    else
      AbrirAcompanhamentoPedido(LPedidoId, LNumeroPedido);

{    tabInicio.Visible := True;
    tcPrincipal.ActiveTab := tabInicio;

    if Assigned(FHomeMobile) then
    begin
      FHomeMobile.Visible := True;
      FHomeMobile.BringToFront;
    end;}
  finally
    LPedido.Free;
  end;
end;

procedure TfrmPrincipal.AbrirPagamentoPix(const APedidoId: string;
  const ANumeroPedido: Integer; const ACodigoPix, AQRCodeBase64: string;
  const AValor: Currency);
begin
  if not Assigned(FTabPagamentoPix) then
  begin
    FTabPagamentoPix := TTabItem.Create(tcPrincipal);
    FTabPagamentoPix.Parent := tcPrincipal;
    FTabPagamentoPix.Text := 'Pagamento PIX';
  end;

  if not Assigned(FPagamentoPix) then
  begin
    FPagamentoPix := TfraPagamentoPix.Create(Self);
    FPagamentoPix.Name := '';
    FPagamentoPix.Parent := FTabPagamentoPix;
    FPagamentoPix.Align := TAlignLayout.Client;
    FPagamentoPix.OnContinuar := PagamentoPixContinuar;
    FPagamentoPix.OnCancelado := PagamentoPixCancelado;
  end;

  FPedidoPixId := APedidoId;
  FPedidoPixNumero := ANumeroPedido;
  FPagamentoPix.Exibir(
    APedidoId,
    ACodigoPix,
    AQRCodeBase64,
    AValor,
    ANumeroPedido
  );

  rctTopo.Visible := False;
  rctMenuInferior.Visible := False;
  PermitirResumoCarrinho(False);
  FTabPagamentoPix.Visible := True;
  tcPrincipal.ActiveTab := FTabPagamentoPix;
  FPagamentoPix.Visible := True;
  FPagamentoPix.BringToFront;
end;

procedure TfrmPrincipal.PagamentoPixContinuar(Sender: TObject);
begin
  AbrirAcompanhamentoPedido(FPedidoPixId, FPedidoPixNumero);
end;

procedure TfrmPrincipal.PagamentoPixCancelado(Sender: TObject);
begin
  TPedidoLocal.Limpar;
  if Assigned(FTabPagamentoPix) then
    FTabPagamentoPix.Visible := False;
  SelecionarAba(0);
end;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
  lytSistema.Visible := True;
  tcPrincipal.Visible := True;

  tabInicio.Visible := True;
  tcPrincipal.ActiveTab := tabInicio;

  {$IF DEFINED(MSWINDOWS)}
    ClientWidth := 390;
    ClientHeight := 720;
    Position := TFormPosition.ScreenCenter;
  {$ENDIF}

  CriarNovaHome;
  FHomeMobile.OnPizzaSelecionada := HomePizzaSelecionada;

  FHomeMobile.Visible := True;
  FHomeMobile.BringToFront;

  FPermitirResumoCarrinho := False;
  FVerificacaoEmAndamento := False;
  FTokenVerificacao := 0;

  FTemporizadorConexao := TTimer.Create(Self);
  FTemporizadorConexao.Interval := 8000;
  FTemporizadorConexao.Enabled := False;
  FTemporizadorConexao.OnTimer := TempoConexaoEsgotado;

  TCarrinho.Instancia.OnAlterado := CarrinhoAlterado;
  FAcompanhamentoVeioDoHistorico := False;

  AtualizarResumoCarrinho;

  try
    InicializarAplicativo;
  except
    on E: Exception do
    begin
      if not Assigned(FSituacaoLoja) then
      begin
        FSituacaoLoja := TfraSituacaoLoja.Create(Self);

        FSituacaoLoja.Name := '';
        FSituacaoLoja.Parent := tabSituacaoLoja;
        FSituacaoLoja.Align := TAlignLayout.Client;
        FSituacaoLoja.OnTentarNovamente := SituacaoLojaTentarNovamente;
      end;

      MostrarTelaSituacaoLoja;
      FSituacaoLoja.MostrarIndisponivel;
    end;
  end;

end;

procedure TfrmPrincipal.FormDestroy(Sender: TObject);
begin
  Inc(FTokenVerificacao);
  FVerificacaoEmAndamento := False;
  if Assigned(FTemporizadorConexao) then
    FTemporizadorConexao.Enabled := False;

  try
    TCarrinho.Instancia.OnAlterado := nil;
  except
    { não faz nada no encerramento }
  end;
end;

procedure TfrmPrincipal.lytMenuCardapioClick(Sender: TObject);
begin
  SelecionarAba(1);
end;

procedure TfrmPrincipal.lytMenuCarrinhoClick(Sender: TObject);
begin
  AbrirCarrinho;
end;

procedure TfrmPrincipal.lytMenuInicioClick(Sender: TObject);
begin
  SelecionarAba(0);
end;

procedure TfrmPrincipal.lytMenuPedidosClick(Sender: TObject);
begin
  SelecionarAba(2);
end;

procedure TfrmPrincipal.lytMenuPerfilClick(Sender: TObject);
begin
  SelecionarAba(4);
end;

procedure TfrmPrincipal.HomeProdutoSelecionado(
  Sender: TObject;
  const AProdutoId: string);
begin
  AbrirMontarProduto(AProdutoId);
end;

procedure TfrmPrincipal.AbrirMontarProduto(
  const AProdutoId: string);
begin
  if not Assigned(FMontarPizza) then
  begin
    FMontarPizza := TfraMontarPizza.Create(Self);
    FMontarPizza.Name := '';
    FMontarPizza.Parent := tabMontarPizza;
    FMontarPizza.Align := TAlignLayout.Client;
  end;

  FMontarPizza.OnVoltar := MontarPizzaVoltar;
  FMontarPizza.OnAdicionado := PizzaAdicionadaAoCarrinho;

  FMontarPizza.CarregarProduto(AProdutoId);

  tcPrincipal.ActiveTab := tabMontarPizza;

  FMontarPizza.Visible := True;
  FMontarPizza.BringToFront;

  rctMenuInferior.Visible := False;
  PermitirResumoCarrinho(False);
end;

procedure TfrmPrincipal.HomePizzaSelecionada(
  Sender: TObject;
  const AProdutoId: string;
  const AVariacaoId: string;
  const AVariacaoNome: string;
  const APreco: Currency);
begin
  if not Assigned(FMontarPizza) then
  begin
    FMontarPizza := TfraMontarPizza.Create(Self);
    FMontarPizza.Name := '';
    FMontarPizza.Parent := tabMontarPizza;
    FMontarPizza.Align := TAlignLayout.Client;
  end;

  FMontarPizza.OnVoltar := MontarPizzaVoltar;
  FMontarPizza.OnAdicionado := PizzaAdicionadaAoCarrinho;

  rctTopo.Visible := False;
  rctMenuInferior.Visible := False;

  FMontarPizza.CarregarPizza(
    AProdutoId,
    AVariacaoId,
    AVariacaoNome,
    APreco
  );

  tcPrincipal.ActiveTab := tabMontarPizza;

  FMontarPizza.Visible := True;
  FMontarPizza.BringToFront;
end;

procedure TfrmPrincipal.PizzaAdicionadaAoCarrinho(Sender: TObject);
begin
  AbrirCarrinho;
end;

function TfrmPrincipal.EnviarPedidoAPI(
  APedido: TPedido;
  out APedidoId: string;
  out ANumeroPedido: Integer;
  out APixCodigo: string;
  out APixQRCodeBase64: string
): Boolean;
var
  LHTTP: TNetHTTPClient;
  LStream: TStringStream;
  LResposta: IHTTPResponse;
  LJSONTexto: string;
  LJSONResposta: TJSONValue;
  LJSONErro: TJSONValue;
  LPedidoJSON: TJSONObject;
  LPixJSON: TJSONObject;
  LMensagemErro: string;
begin
  Result := False;

  APedidoId := '';
  ANumeroPedido := 0;
  APixCodigo := '';
  APixQRCodeBase64 := '';

  if not Assigned(APedido) then
    Exit;

  LHTTP := TNetHTTPClient.Create(nil);

  try
    LHTTP.ContentType := 'application/json';
    LHTTP.Accept := 'application/json';
    LHTTP.ConnectionTimeout := 5000;
    LHTTP.ResponseTimeout := 15000;

    LJSONTexto := APedido.ToJSONString;

    LStream :=
      TStringStream.Create(
        LJSONTexto,
        TEncoding.UTF8
      );

    try
      LResposta :=
        LHTTP.Post(
          TApiConfig.Url('/api/pedidos'),
          LStream
        );

      if not (LResposta.StatusCode in [200, 201]) then
      begin
        LMensagemErro := 'Não foi possível criar o pedido.';
        LJSONErro := TJSONObject.ParseJSONValue(
          LResposta.ContentAsString(TEncoding.UTF8)
        );
        try
          if LJSONErro is TJSONObject then
            LMensagemErro := TJSONObject(LJSONErro).GetValue<string>(
              'erro', LMensagemErro
            );
        finally
          LJSONErro.Free;
        end;
        TMensagemMobile.Exibir(
          LMensagemErro,
          tmErro
        );

        Exit;
      end;

      LJSONResposta := TJSONObject.ParseJSONValue(
        LResposta.ContentAsString(TEncoding.UTF8)
      );

      try
        if LJSONResposta is TJSONObject then
        begin
          LPedidoJSON := nil;
          if TJSONObject(LJSONResposta).GetValue('pedido') is TJSONObject then
            LPedidoJSON := TJSONObject(
              TJSONObject(LJSONResposta).GetValue('pedido')
            );

          if Assigned(LPedidoJSON) then
          begin
            APedidoId := LPedidoJSON.GetValue<string>('id', '');
            ANumeroPedido := LPedidoJSON.GetValue<Integer>('numero', 0);
          end;

          LPixJSON := nil;
          if TJSONObject(LJSONResposta).GetValue('pix') is TJSONObject then
            LPixJSON := TJSONObject(
              TJSONObject(LJSONResposta).GetValue('pix')
            );
          if Assigned(LPixJSON) then
          begin
            APixCodigo := LPixJSON.GetValue<string>('copiaCola', '');
            APixQRCodeBase64 := LPixJSON.GetValue<string>('qrCodeBase64', '');
          end;
        end;
      finally
        LJSONResposta.Free;
      end;

      Result := True;

    finally
      LStream.Free;
    end;

  except
    on E: Exception do
    begin
      TMensagemMobile.Exibir(
        'Erro de comunicação com a API.' +
        sLineBreak +
        sLineBreak +
        E.Message,
        tmErro
      );
    end;
  end;

  LHTTP.Free;
end;

procedure TfrmPrincipal.AbrirAcompanhamentoPedido(
  const APedidoId: string;
  const ANumeroPedido: Integer);
begin
  if not Assigned(FAcompanharPedido) then
  begin
    FAcompanharPedido :=
      TfraAcompanharPedido.Create(Self);

    FAcompanharPedido.Name := '';
    FAcompanharPedido.Parent := tabAcompanharPedido;

    FAcompanharPedido.Align := TAlignLayout.Client;

    FAcompanharPedido.OnVoltarInicio :=
      AcompanhamentoVoltarInicio;
  end;

  PermitirResumoCarrinho(False);

  tabAcompanharPedido.Visible := True;

  FAcompanharPedido.AbrirPedido(APedidoId, ANumeroPedido);

  tcPrincipal.ActiveTab := tabAcompanharPedido;

  FAcompanharPedido.Visible := True;
  FAcompanharPedido.BringToFront;

  rctMenuInferior.Visible := False;
  PermitirResumoCarrinho(False);
  FAcompanharPedido.lblInicio.Text := 'Voltar para o início';
end;

procedure TfrmPrincipal.AcompanhamentoVoltarInicio(
  Sender: TObject);
begin
  if FAcompanhamentoVeioDoHistorico then
  begin
    FAcompanhamentoVeioDoHistorico := False;
    AbrirHistoricoPedidos;
    Exit;
  end;

  MostrarHomeNormal;
end;

procedure TfrmPrincipal.CarrinhoAdicionarMaisItens(
  Sender: TObject);
begin
  MostrarHomeNormal;
  AtualizarVisualMenu(1);
end;

procedure TfrmPrincipal.MontarPizzaVoltar(Sender: TObject);
begin
  MostrarHomeNormal;
end;

procedure TfrmPrincipal.VerificarSituacaoLoja;
var
  LToken: Integer;
begin
  if not Assigned(FSituacaoLoja) then
  begin
    FSituacaoLoja :=
      TfraSituacaoLoja.Create(Self);

    FSituacaoLoja.Name := '';
    FSituacaoLoja.Parent := tabSituacaoLoja;
    FSituacaoLoja.Align := TAlignLayout.Client;

    FSituacaoLoja.OnTentarNovamente :=
      SituacaoLojaTentarNovamente;
  end;

  if FVerificacaoEmAndamento then
    Exit;

  MostrarTelaSituacaoLoja;
  FSituacaoLoja.MostrarVerificando;

  FVerificacaoEmAndamento := True;
  Inc(FTokenVerificacao);
  LToken := FTokenVerificacao;
  FTemporizadorConexao.Enabled := True;

  TThread.CreateAnonymousThread(
    procedure
    var
      LHTTP: TNetHTTPClient;
      LResposta: IHTTPResponse;
      LJSON: TJSONObject;
      LHoje: TJSONObject;
      LHojeValor: TJSONValue;
      LDisponivel: Boolean;
      LAberta: Boolean;
      LMensagem: string;
      LAbertura: string;
      LFechamento: string;
      LHorarioTexto: string;
      LEmpresaId: string;
      LEmpresaNome: string;
      LLogoUrl: string;
      LErroConexao: string;
      LTentativa: Integer;
    begin
      LHTTP := nil;
      LJSON := nil;
      LDisponivel := False;
      LAberta := False;
      LMensagem := 'No momento não estamos recebendo pedidos.';
      LHorarioTexto := '';
      LEmpresaNome := '';
      LLogoUrl := '';
      LErroConexao := '';

      try
        try
          LEmpresaId := TEmpresaApp.Id;
          LEmpresaNome := TEmpresaApp.Nome;
          LLogoUrl := TEmpresaApp.LogoUrl;

          for LTentativa := 1 to 3 do
          begin
            FreeAndNil(LHTTP);
            FreeAndNil(LJSON);
            try
            begin
              LHTTP := TNetHTTPClient.Create(nil);
              LHTTP.Accept := 'application/json';
              LHTTP.ConnectionTimeout := 4000;
              LHTTP.ResponseTimeout := 7000;

              LResposta := LHTTP.Get(
                TApiConfig.Url('/api/loja/status') +
                '?empresaId=' + LEmpresaId
              );

              if LResposta.StatusCode = 200 then
              begin
                LJSON := TJSONObject.ParseJSONValue(
                  LResposta.ContentAsString(TEncoding.UTF8)
                ) as TJSONObject;

                if Assigned(LJSON) then
                begin
                  LAberta := LJSON.GetValue<Boolean>('aberta', False);
                  LMensagem := LJSON.GetValue<string>(
                    'mensagem',
                    'No momento não estamos recebendo pedidos.'
                  );

                  LHojeValor := LJSON.GetValue('hoje');
                  if LHojeValor is TJSONObject then
                  begin
                    LHoje := TJSONObject(LHojeValor);
                    LAbertura := LHoje.GetValue<string>('horario_abertura', '');
                    LFechamento := LHoje.GetValue<string>('horario_fechamento', '');

                    if (LAbertura <> '') and (LFechamento <> '') then
                      LHorarioTexto :=
                        Copy(LAbertura, 1, 5) + ' às ' +
                        Copy(LFechamento, 1, 5);
                  end;

                  LDisponivel := True;
                  LErroConexao := '';
                  Break;
                end;
              end;
              LErroConexao := Format('HTTP %d: %s', [
                LResposta.StatusCode,
                LResposta.ContentAsString(TEncoding.UTF8)
              ]);
            end;
            except
              on E: Exception do
                LErroConexao := E.ClassName + ': ' + E.Message;
            end;

            if LTentativa < 3 then
              TThread.Sleep(600);
          end;
        except
          on E: Exception do
            LErroConexao := E.ClassName + ': ' + E.Message;
        end;
      finally
        LJSON.Free;
        LHTTP.Free;
      end;

      TThread.Queue(nil,
        procedure
        begin
          if (frmPrincipal <> Self) or
             (LToken <> FTokenVerificacao) then
            Exit;

          FTemporizadorConexao.Enabled := False;
          FVerificacaoEmAndamento := False;

          if not LDisponivel then
          begin
            MostrarTelaSituacaoLoja;
            FSituacaoLoja.MostrarIndisponivel(
              LErroConexao + sLineBreak + 'URL: ' + TApiConfig.BaseUrl
            );
            Exit;
          end;

          FLojaAberta := LAberta;
          FMensagemLoja := LMensagem;

          MostrarEntradaLoja;
          FEntradaLoja.ConfigurarLoja(
            LEmpresaNome,
            'Bombinhas - SC',
            LAberta,
            LHorarioTexto,
            LLogoUrl
          );
        end
      );
    end
  ).Start;
end;

procedure TfrmPrincipal.TempoConexaoEsgotado(Sender: TObject);
begin
  FTemporizadorConexao.Enabled := False;

  if not FVerificacaoEmAndamento then
    Exit;

  FVerificacaoEmAndamento := False;
  Inc(FTokenVerificacao);

  MostrarTelaSituacaoLoja;
  FSituacaoLoja.MostrarIndisponivel(
    'Tempo de conexão esgotado.' + sLineBreak +
    'URL: ' + TApiConfig.BaseUrl
  );
end;

procedure TfrmPrincipal.MostrarTelaSituacaoLoja;
begin
  rctTopo.Visible := False;
  rctMenuInferior.Visible := False;

  tabSituacaoLoja.Visible := True;
  tcPrincipal.ActiveTab := tabSituacaoLoja;

  FSituacaoLoja.Visible := True;
  FSituacaoLoja.BringToFront;
end;

procedure TfrmPrincipal.MostrarHomeNormal;
begin
  rctTopo.Visible := False;
  rctMenuInferior.Visible := False;

  tabInicio.Visible := True;
  tcPrincipal.ActiveTab := tabInicio;

  if not Assigned(FHomeMobile) then
    CriarNovaHome;

  if Assigned(FHomeMobile) then
  begin
    FHomeMobile.Visible := True;
    FHomeMobile.BringToFront;
  end;

  if Assigned(FSituacaoLoja) then
    FSituacaoLoja.Visible := False;

  AtualizarResumoCarrinho;

  rctMenuInferior.Visible := True;
  PermitirResumoCarrinho(True);
  AtualizarVisualMenu(0);

  { Deixa a nova tela ser desenhada antes de iniciar as consultas do
    cardápio. Assim o toque responde imediatamente. }
  TThread.ForceQueue(nil,
    procedure
    begin
      if Assigned(FHomeMobile) and not (csDestroying in ComponentState) then
      begin
        FHomeMobile.CarregarCardapio;
        FHomeMobile.AtualizarCarrinho;
      end;
    end
  );
end;

procedure TfrmPrincipal.SituacaoLojaTentarNovamente(
  Sender: TObject);
begin
  VerificarSituacaoLoja;
end;

procedure TfrmPrincipal.InicializarAplicativo;
begin
  VerificarSituacaoLoja;
end;

procedure TfrmPrincipal.HomeAbrirCarrinho(
  Sender: TObject);
begin
  AbrirCarrinho;
end;

procedure TfrmPrincipal.MostrarEntradaLoja;
begin
  rctTopo.Visible := False;
  rctMenuInferior.Visible := False;

  if not Assigned(FEntradaLoja) then
  begin
    FEntradaLoja :=
      TfraEntradaLoja.Create(Self);

    FEntradaLoja.Name := '';
    FEntradaLoja.Parent := tabEntradaLoja;
    FEntradaLoja.Align := TAlignLayout.Client;

    FEntradaLoja.OnEntrarLoja :=
      EntradaLojaClick;
  end;

  tabEntradaLoja.Visible := True;
  tcPrincipal.ActiveTab := tabEntradaLoja;

  FEntradaLoja.Visible := True;
  FEntradaLoja.BringToFront;

  if Assigned(FHomeMobile) then
    FHomeMobile.PreCarregarCardapio;
end;

procedure TfrmPrincipal.EntradaLojaClick(
  Sender: TObject);
begin
  if FLojaAberta then
  begin
    if Assigned(FEntradaLoja) then
      FEntradaLoja.Visible := False;

    MostrarHomeNormal;
  end
  else
  begin
    VerificarSituacaoLoja;
  end;
end;

procedure TfrmPrincipal.AtualizarResumoCarrinho;
var
  LQuantidade: Integer;
begin
  LQuantidade :=
    TCarrinho.Instancia.QuantidadeItens;

  rctResumoCarrinho.Visible :=
    FPermitirResumoCarrinho and
    (LQuantidade > 0);

  if LQuantidade = 1 then
    lblQtdCarrinho.Text :=
      '1 item  ›'
  else if LQuantidade > 1 then
    lblQtdCarrinho.Text :=
      LQuantidade.ToString + ' itens  ›'
  else
    lblQtdCarrinho.Text := '';
end;

procedure TfrmPrincipal.PermitirResumoCarrinho(
  const APermitir: Boolean);
begin
  FPermitirResumoCarrinho := APermitir;

  AtualizarResumoCarrinho;
end;

procedure TfrmPrincipal.MenuInicioClick(
  Sender: TObject);
begin
  MostrarHomeNormal;

  rctMenuInferior.Visible := True;
  PermitirResumoCarrinho(True);

  AtualizarVisualMenu(0);
end;

procedure TfrmPrincipal.MenuCardapioClick(
  Sender: TObject);
begin
  MostrarHomeNormal;

  rctMenuInferior.Visible := True;
  PermitirResumoCarrinho(True);

  AtualizarVisualMenu(1);
end;

procedure TfrmPrincipal.AbrirHistoricoPedidos;
begin
  if not Assigned(FHistoricoPedidos) then
  begin
    FHistoricoPedidos :=
      TfraHistoricoPedidos.Create(tabPedidos);

    FHistoricoPedidos.Parent := tabPedidos;
    FHistoricoPedidos.Align := TAlignLayout.Client;
    FHistoricoPedidos.OnAcompanhar := HistoricoAcompanhar;
    FHistoricoPedidos.OnRepetir := HistoricoRepetir;
  end;

  tabPedidos.Visible := True;

  PermitirResumoCarrinho(False);
  rctMenuInferior.Visible := True;

  tcPrincipal.ActiveTab := tabPedidos;
  AtualizarVisualMenu(2);

  FHistoricoPedidos.Visible := True;
  FHistoricoPedidos.BringToFront;
  FHistoricoPedidos.CarregarPedidos;
end;

procedure TfrmPrincipal.MenuPedidosClick(
  Sender: TObject);
begin
  AbrirHistoricoPedidos;
end;

procedure TfrmPrincipal.MenuContaClick(
  Sender: TObject);
begin
  AbrirConta;
end;

procedure TfrmPrincipal.AtualizarVisualMenu(
  const AItem: Integer);
begin
  lblIconeInicio.TextSettings.FontColor :=
    $FF747986;
  lblInicio.TextSettings.FontColor :=
    $FF747986;

  lblIconeCardapio.TextSettings.FontColor :=
    $FF747986;
  lblCardapio.TextSettings.FontColor :=
    $FF747986;

  lblIconePedidos.TextSettings.FontColor :=
    $FF747986;
  lblPedidos.TextSettings.FontColor :=
    $FF747986;

  lblIconeConta.TextSettings.FontColor :=
    $FF747986;
  lblConta.TextSettings.FontColor :=
    $FF747986;

  rctIndicadorInicio.Visible := False;
  rctIndicadorCardapio.Visible := False;
  rctIndicadorPedidos.Visible := False;
  rctIndicadorConta.Visible := False;

  case AItem of
    0:
      begin
        lblIconeInicio.TextSettings.FontColor :=
          $FFFF4B0A;
        lblInicio.TextSettings.FontColor :=
          $FFFF4B0A;

        rctIndicadorInicio.Visible := True;
      end;

    1:
      begin
        lblIconeCardapio.TextSettings.FontColor :=
          $FFFF4B0A;
        lblCardapio.TextSettings.FontColor :=
          $FFFF4B0A;

        rctIndicadorCardapio.Visible := True;
      end;

    2:
      begin
        lblIconePedidos.TextSettings.FontColor :=
          $FFFF4B0A;
        lblPedidos.TextSettings.FontColor :=
          $FFFF4B0A;

        rctIndicadorPedidos.Visible := True;
      end;

    3:
      begin
        lblIconeConta.TextSettings.FontColor :=
          $FFFF4B0A;
        lblConta.TextSettings.FontColor :=
          $FFFF4B0A;

        rctIndicadorConta.Visible := True;
      end;
  end;
end;

procedure TfrmPrincipal.AbrirConta;
begin
  if not Assigned(FContaMobile) then
  begin
    FContaMobile :=
      TfraContaMobile.Create(Self);

    FContaMobile.Name := '';
    FContaMobile.Parent := tabConta;
    FContaMobile.Align := TAlignLayout.Client;
  end;

  PermitirResumoCarrinho(False);

  rctMenuInferior.Visible := True;

  tabConta.Visible := True;

  tcPrincipal.ActiveTab :=
    tabConta;

  FContaMobile.PrepararTela;

  FContaMobile.Visible := True;
  FContaMobile.BringToFront;

  AtualizarVisualMenu(3);
end;

procedure TfrmPrincipal.HistoricoAcompanhar(
  Sender: TObject;
  APedido: TPedidoHistorico);
begin
  if not Assigned(APedido) then
    Exit;

  FAcompanhamentoVeioDoHistorico := True;

  AbrirAcompanhamentoPedido(
    APedido.Id,
    APedido.Numero
  );

  FAcompanharPedido.lblInicio.Text :=
    'Voltar para pedidos';
end;

procedure TfrmPrincipal.HistoricoRepetir(
  Sender: TObject;
  APedido: TPedidoHistorico);
begin
  if not Assigned(APedido) then
    Exit;

  if TCarrinho.Instancia.QuantidadeItens > 0 then
  begin
    TMensagemMobile.Confirmar(
      'Seu carrinho já possui itens.' +
      sLineBreak +
      sLineBreak +
      'Deseja substituí-los por este pedido?',
      procedure(const AConfirmado: Boolean)
      begin
        if AConfirmado then
          MontarCarrinhoDoHistorico(APedido);
      end,
      'Substituir carrinho?',
      'Substituir',
      'Manter atual'
    );
    Exit;
  end;

  MontarCarrinhoDoHistorico(APedido);
end;

procedure TfrmPrincipal.MontarCarrinhoDoHistorico(
  APedido: TPedidoHistorico);
var
  LItemHistorico: TItemHistoricoPedido;
  LSaborHistorico: TSaborHistoricoPedido;

  LItemCarrinho: TItemCarrinho;
  LSaborCarrinho: TSaborCarrinho;

  LValorSabores: Currency;
begin
  if not Assigned(APedido) then
    Exit;

  TCarrinho.Instancia.Limpar;

  for LItemHistorico in APedido.Itens do
  begin
    LItemCarrinho := TItemCarrinho.Create;

    try
      LItemCarrinho.ProdutoId :=
        LItemHistorico.ProdutoId;

      LItemCarrinho.ProdutoDescricao :=
        LItemHistorico.ProdutoDescricao;

      LItemCarrinho.TamanhoId :=
        LItemHistorico.TamanhoId;

      LItemCarrinho.TamanhoDescricao :=
        LItemHistorico.TamanhoDescricao;

      LItemCarrinho.BordaId :=
        LItemHistorico.BordaId;

      LItemCarrinho.BordaDescricao :=
        LItemHistorico.BordaDescricao;

      LItemCarrinho.ValorBorda :=
        LItemHistorico.ValorBorda;

      LItemCarrinho.Quantidade :=
        LItemHistorico.Quantidade;

      if LItemCarrinho.Quantidade <= 0 then
        LItemCarrinho.Quantidade := 1;

      LItemCarrinho.Observacao :=
        LItemHistorico.Observacao;

      LValorSabores := 0;

      for LSaborHistorico in
        LItemHistorico.Sabores do
      begin
        LSaborCarrinho := TSaborCarrinho.Create;

        LSaborCarrinho.Id :=
          LSaborHistorico.Id;

        LSaborCarrinho.Descricao :=
          LSaborHistorico.Descricao;

        LSaborCarrinho.Valor :=
          LSaborHistorico.Valor;

        { Em produtos com mais de um sabor, somente o sabor de maior valor
          participa do cálculo do item. }
        if LSaborCarrinho.Valor > LValorSabores then
          LValorSabores := LSaborCarrinho.Valor;

        LItemCarrinho.Sabores.Add(
          LSaborCarrinho
        );
      end;

      { O valor histórico unitário contém:
        base + sabores + borda. }
      LItemCarrinho.ValorBase :=
        LItemHistorico.ValorUnitario -
        LValorSabores -
        LItemHistorico.ValorBorda;

      if LItemCarrinho.ValorBase < 0 then
        LItemCarrinho.ValorBase := 0;

      TCarrinho.Instancia.Adicionar(
        LItemCarrinho
      );

      LItemCarrinho := nil;
    finally
      LItemCarrinho.Free;
    end;
  end;

  AtualizarResumoCarrinho;
  AbrirCarrinho;
end;

end.
