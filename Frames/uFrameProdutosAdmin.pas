unit uFrameProdutosAdmin;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.JSON,
  System.Net.URLClient, System.Net.HttpClient, System.Net.HttpClientComponent,
  System.NetEncoding, System.Generics.Collections,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Objects,
  FMX.Layouts, FMX.Controls.Presentation, FMX.Edit, FMX.Memo,
  uFrameSensorButton;

type
  TProdutoFiltro = (pfTodos, pfDisponiveis, pfIndisponiveis, pfInativos);

  TCategoriaProduto = class
  public
    Id, Nome: string;
  end;

  TProdutoAdmin = class
  public
    Id, CategoriaId, CategoriaNome, Tipo, Nome, Descricao: string;
    ImagemUrl, CodigoInterno: string;
    Preco, PrecoPromocional: Currency;
    TemPrecoPromocional, Disponivel, Destaque, Ativo: Boolean;
    Ordem: Integer;
  end;

  TfraProdutosAdmin = class(TFrame)
    rctFundo: TRectangle;
    lytPrincipal, lytCabecalho, lytConteudo: TLayout;
    lblTitulo, lblSubtitulo: TLabel;
  private
    FProdutos: TObjectList<TProdutoAdmin>;
    FCategorias: TObjectList<TCategoriaProduto>;
    FCarregado: Boolean;
    FSelecionado: Integer;
    FFiltro: TProdutoFiltro;
    FEditandoId, FCategoriaSelecionadaId, FTipo: string;
    FDisponivel, FDestaque: Boolean;
    FBarra, FFiltros, FListaConteudo, FCategoriasConteudo: TLayout;
    FBusca, FNome, FPreco, FPrecoPromocional, FCodigo, FOrdem,
      FImagemUrl: TEdit;
    FDescricao: TMemo;
    FLista, FCategoriasLista, FScrollEditor: TVertScrollBox;
    FEstado, FTituloEdicao: TLabel;
    FPainelEdicao: TRectangle;
    FTimerBusca: TTimer;
    FBtnNovo, FBtnBuscar, FBtnSalvar, FBtnCancelar, FBtnImagem: TfraSensorButton;
    FBtnTodos, FBtnDisponiveis, FBtnIndisponiveis,
      FBtnInativos: TfraSensorButton;
    FBtnTipo, FBtnDisponivel, FBtnDestaque: TfraSensorButton;
    procedure MontarTela;
    function CriarRotulo(const AParent: TFmxObject; const ATexto: string;
      const AX, AY, AWidth, AHeight: Single; const ACor: TAlphaColor;
      const ATamanho: Single): TLabel;
    function CriarBotao(const AParent: TFmxObject; const ATexto: string;
      const AWidth: Single; const AOnClick: TNotifyEvent): TfraSensorButton;
    function CriarFundoCampo(const AParent: TFmxObject; const AX, AY,
      AWidth, AHeight: Single): TRectangle;
    procedure ConfigurarBotaoIcone(const ABotao: TfraSensorButton;
      const AHint: string);
    function ProdutoSelecionado: TProdutoAdmin;
    function ProdutoVisivel(const AProduto: TProdutoAdmin): Boolean;
    function TextoParaValor(const ATexto: string; out AValor: Currency): Boolean;
    procedure PreencherLista;
    procedure PreencherCategoriasEditor;
    procedure AtualizarFiltros;
    procedure AtualizarOpcoesEditor;
    procedure AbrirEditor(const AProduto: TProdutoAdmin);
    procedure FecharEditor;
    procedure ExibirErroAPI(const ATitulo: string;
      const AResposta: IHTTPResponse);
    procedure NovoClick(Sender: TObject);
    procedure EditarClick(Sender: TObject);
    procedure AtivoClick(Sender: TObject);
    procedure DisponibilidadeClick(Sender: TObject);
    procedure SalvarClick(Sender: TObject);
    procedure CancelarClick(Sender: TObject);
    procedure BuscarClick(Sender: TObject);
    procedure BuscaChange(Sender: TObject);
    procedure BuscaKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure TimerBuscaTimer(Sender: TObject);
    procedure FiltroClick(Sender: TObject);
    procedure ProdutoClick(Sender: TObject);
    procedure CategoriaClick(Sender: TObject);
    procedure TipoClick(Sender: TObject);
    procedure DisponivelEditorClick(Sender: TObject);
    procedure DestaqueClick(Sender: TObject);
    procedure MemoApplyStyleLookup(Sender: TObject);
    procedure SelecionarImagemClick(Sender: TObject);
    procedure ExibirImagemUrl(const AUrl: string);
    function ImagemUrlAtual: string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure PrepararTela;
    procedure CarregarCardapio;
    procedure CarregarCategorias;
  end;

implementation

{$R *.fmx}

uses uMensagem, uImagemUpload, uSessaoAdmin, uNavegacaoCampos, uApiConfig;

function URL_CARDAPIO: string;
begin
  Result := TApiConfig.Url('/api/cardapio');
end;

constructor TfraProdutosAdmin.Create(AOwner: TComponent);
begin
  inherited;
  FProdutos := TObjectList<TProdutoAdmin>.Create(True);
  FCategorias := TObjectList<TCategoriaProduto>.Create(True);
  FSelecionado := -1; FFiltro := pfTodos;
  MontarTela;
end;

destructor TfraProdutosAdmin.Destroy;
begin
  FCategorias.Free; FProdutos.Free;
  inherited;
end;

function TfraProdutosAdmin.CriarRotulo(const AParent: TFmxObject;
  const ATexto: string; const AX, AY, AWidth, AHeight: Single;
  const ACor: TAlphaColor; const ATamanho: Single): TLabel;
begin
  Result := TLabel.Create(Self); Result.Parent := AParent;
  Result.Position.Point := PointF(AX, AY); Result.Width := AWidth;
  Result.Height := AHeight; Result.Text := ATexto; Result.StyledSettings := [];
  Result.TextSettings.Font.Family := 'Manrope';
  Result.TextSettings.Font.Size := ATamanho; Result.TextSettings.FontColor := ACor;
end;

function TfraProdutosAdmin.CriarBotao(const AParent: TFmxObject;
  const ATexto: string; const AWidth: Single;
  const AOnClick: TNotifyEvent): TfraSensorButton;
begin
  Result := TfraSensorButton.Create(Self); Result.Name := '';
  Result.Parent := AParent; Result.Align := TAlignLayout.Left;
  Result.Width := AWidth; Result.Margins.Right := 8; Result.Texto := ATexto;
  Result.Estilo := sbsSecondary; Result.OnButtonClick := AOnClick;
  Result.pthIcone.Margins.Left := 10; Result.pthIcone.Margins.Right := 6;
  Result.lblTexto.Margins.Right := 10;
end;

function TfraProdutosAdmin.CriarFundoCampo(const AParent: TFmxObject;
  const AX, AY, AWidth, AHeight: Single): TRectangle;
begin
  Result := TRectangle.Create(Self); Result.Parent := AParent;
  Result.Position.Point := PointF(AX, AY); Result.Width := AWidth;
  Result.Height := AHeight; Result.Fill.Color := $FF152439;
  Result.Stroke.Color := $FF2A405B; Result.XRadius := 6; Result.YRadius := 6;
end;

procedure TfraProdutosAdmin.ConfigurarBotaoIcone(
  const ABotao: TfraSensorButton; const AHint: string);
begin
  ABotao.Width := 38; ABotao.Height := 34; ABotao.Texto := '';
  ABotao.lblTexto.Visible := False; ABotao.pthIcone.Align := TAlignLayout.None;
  ABotao.pthIcone.Margins.Rect := RectF(0, 0, 0, 0);
  ABotao.pthIcone.Position.Point := PointF(
    (ABotao.Width - ABotao.pthIcone.Width) / 2,
    (ABotao.Height - ABotao.pthIcone.Height) / 2);
  ABotao.Hint := AHint; ABotao.ShowHint := True;
  ABotao.rctFundo.Hint := AHint; ABotao.rctFundo.ShowHint := True;
end;

procedure TfraProdutosAdmin.MontarTela;
var
  LBuscaFundo, LListaFundo, LCampo: TRectangle;
  LEditorConteudo: TLayout;
begin
  FBarra := TLayout.Create(Self); FBarra.Parent := lytConteudo;
  FBarra.Align := TAlignLayout.Top; FBarra.Height := 44;
  FBarra.Margins.Bottom := 12;
  FBtnNovo := CriarBotao(FBarra, '+ Novo produto', 136, NovoClick);
  FBtnNovo.Align := TAlignLayout.Right; FBtnNovo.Estilo := sbsPrimary;
  FBtnNovo.Icone := sbiCardapio;
  FBtnBuscar := CriarBotao(FBarra, 'Buscar', 96, BuscarClick);
  FBtnBuscar.Align := TAlignLayout.Right; FBtnBuscar.Icone := sbiPesquisar;
  LBuscaFundo := CriarFundoCampo(FBarra, 0, 0, 100, 44);
  LBuscaFundo.Align := TAlignLayout.Client; LBuscaFundo.Margins.Right := 12;
  LBuscaFundo.XRadius := 8; LBuscaFundo.YRadius := 8;
  FBusca := TEdit.Create(Self); FBusca.Parent := LBuscaFundo;
  FBusca.Align := TAlignLayout.Client; FBusca.Margins.Left := 12;
  FBusca.Margins.Right := 12; FBusca.StyleLookup := 'transparentedit';
  FBusca.TextPrompt := 'Buscar produto, categoria ou código';
  FBusca.StyledSettings := []; FBusca.TextSettings.FontColor := $FFF4F7FB;
  FBusca.OnTyping := BuscaChange; FBusca.OnChangeTracking := BuscaChange;
  FBusca.OnKeyDown := BuscaKeyDown;
  FTimerBusca := TTimer.Create(Self); FTimerBusca.Interval := 400;
  FTimerBusca.Enabled := False; FTimerBusca.OnTimer := TimerBuscaTimer;

  FFiltros := TLayout.Create(Self); FFiltros.Parent := lytConteudo;
  FFiltros.Align := TAlignLayout.Top; FFiltros.Height := 42;
  FFiltros.Margins.Bottom := 10;
  CriarRotulo(FFiltros, 'Filtrar:', 2, 0, 62, 42, $FF8795A8, 10);
  FBtnTodos := CriarBotao(FFiltros, 'Todos', 94, FiltroClick);
  FBtnTodos.Align := TAlignLayout.None; FBtnTodos.Position.Point := PointF(68, 2);
  FBtnTodos.Height := 36; FBtnTodos.Icone := sbiRelatorio; FBtnTodos.Tag := Ord(pfTodos);
  FBtnDisponiveis := CriarBotao(FFiltros, 'Disponíveis', 126, FiltroClick);
  FBtnDisponiveis.Align := TAlignLayout.None;
  FBtnDisponiveis.Position.Point := PointF(170, 2); FBtnDisponiveis.Height := 36;
  FBtnDisponiveis.Icone := sbiAtivar; FBtnDisponiveis.Tag := Ord(pfDisponiveis);
  FBtnIndisponiveis := CriarBotao(FFiltros, 'Indisponíveis', 138, FiltroClick);
  FBtnIndisponiveis.Align := TAlignLayout.None;
  FBtnIndisponiveis.Position.Point := PointF(304, 2); FBtnIndisponiveis.Height := 36;
  FBtnIndisponiveis.Icone := sbiCancelar;
  FBtnIndisponiveis.Tag := Ord(pfIndisponiveis);
  FBtnInativos := CriarBotao(FFiltros, 'Inativos', 108, FiltroClick);
  FBtnInativos.Align := TAlignLayout.None;
  FBtnInativos.Position.Point := PointF(450, 2); FBtnInativos.Height := 36;
  FBtnInativos.Icone := sbiBloquear; FBtnInativos.Tag := Ord(pfInativos);
  AtualizarFiltros;

  FPainelEdicao := TRectangle.Create(Self); FPainelEdicao.Parent := lytConteudo;
  FPainelEdicao.Align := TAlignLayout.Right; FPainelEdicao.Width := 400;
  FPainelEdicao.Margins.Left := 14; FPainelEdicao.Fill.Color := $FF111E2E;
  FPainelEdicao.Stroke.Color := $FF2A405B;
  FPainelEdicao.XRadius := 10; FPainelEdicao.YRadius := 10;
  FPainelEdicao.Visible := False;
  FTituloEdicao := CriarRotulo(FPainelEdicao, 'Novo produto', 20, 14,
    360, 30, $FFF4F7FB, 16);
  FTituloEdicao.TextSettings.Font.Style := [TFontStyle.fsBold];
  FScrollEditor := TVertScrollBox.Create(Self); FScrollEditor.Parent := FPainelEdicao;
  FScrollEditor.Align := TAlignLayout.Client; FScrollEditor.Margins.Top := 50;
  FScrollEditor.Margins.Bottom := 8;
  LEditorConteudo := TLayout.Create(Self); LEditorConteudo.Parent := FScrollEditor;
  LEditorConteudo.Align := TAlignLayout.Top; LEditorConteudo.Height := 690;

  CriarRotulo(LEditorConteudo, 'Nome *', 20, 0, 360, 20, $FF9CAABC, 10);
  LCampo := CriarFundoCampo(LEditorConteudo, 20, 22, 360, 38);
  FNome := TEdit.Create(Self); FNome.Parent := LCampo; FNome.Align := TAlignLayout.Client;
  FNome.Margins.Left := 10; FNome.Margins.Right := 10;
  FNome.StyleLookup := 'transparentedit'; FNome.StyledSettings := [];
  FNome.TextSettings.FontColor := $FFF4F7FB; FNome.TextPrompt := 'Nome do produto';

  CriarRotulo(LEditorConteudo, 'Categoria *', 20, 68, 360, 20, $FF9CAABC, 10);
  LCampo := CriarFundoCampo(LEditorConteudo, 20, 90, 360, 92);
  FCategoriasLista := TVertScrollBox.Create(Self); FCategoriasLista.Parent := LCampo;
  FCategoriasLista.Align := TAlignLayout.Client; FCategoriasLista.Margins.Rect := RectF(4, 4, 4, 4);
  FCategoriasConteudo := TLayout.Create(Self); FCategoriasConteudo.Parent := FCategoriasLista;
  FCategoriasConteudo.Align := TAlignLayout.Top; FCategoriasConteudo.Height := 1;

  CriarRotulo(LEditorConteudo, 'Preço *', 20, 190, 170, 20, $FF9CAABC, 10);
  CriarRotulo(LEditorConteudo, 'Preço promocional', 210, 190, 170, 20, $FF9CAABC, 10);
  LCampo := CriarFundoCampo(LEditorConteudo, 20, 212, 170, 38);
  FPreco := TEdit.Create(Self); FPreco.Parent := LCampo; FPreco.Align := TAlignLayout.Client;
  FPreco.Margins.Left := 10; FPreco.Margins.Right := 10;
  FPreco.StyleLookup := 'transparentedit'; FPreco.StyledSettings := [];
  FPreco.TextSettings.FontColor := $FFF4F7FB;
  FPreco.KeyboardType := TVirtualKeyboardType.DecimalNumberPad;
  LCampo := CriarFundoCampo(LEditorConteudo, 210, 212, 170, 38);
  FPrecoPromocional := TEdit.Create(Self); FPrecoPromocional.Parent := LCampo;
  FPrecoPromocional.Align := TAlignLayout.Client;
  FPrecoPromocional.Margins.Left := 10; FPrecoPromocional.Margins.Right := 10;
  FPrecoPromocional.StyleLookup := 'transparentedit'; FPrecoPromocional.StyledSettings := [];
  FPrecoPromocional.TextSettings.FontColor := $FFF4F7FB;
  FPrecoPromocional.KeyboardType := TVirtualKeyboardType.DecimalNumberPad;

  CriarRotulo(LEditorConteudo, 'Código interno', 20, 258, 250, 20, $FF9CAABC, 10);
  CriarRotulo(LEditorConteudo, 'Ordem', 290, 258, 90, 20, $FF9CAABC, 10);
  LCampo := CriarFundoCampo(LEditorConteudo, 20, 280, 250, 38);
  FCodigo := TEdit.Create(Self); FCodigo.Parent := LCampo; FCodigo.Align := TAlignLayout.Client;
  FCodigo.Margins.Left := 10; FCodigo.Margins.Right := 10;
  FCodigo.StyleLookup := 'transparentedit'; FCodigo.StyledSettings := [];
  FCodigo.TextSettings.FontColor := $FFF4F7FB;
  LCampo := CriarFundoCampo(LEditorConteudo, 290, 280, 90, 38);
  FOrdem := TEdit.Create(Self); FOrdem.Parent := LCampo; FOrdem.Align := TAlignLayout.Client;
  FOrdem.Margins.Left := 10; FOrdem.Margins.Right := 10;
  FOrdem.StyleLookup := 'transparentedit'; FOrdem.StyledSettings := [];
  FOrdem.TextSettings.FontColor := $FFF4F7FB;
  FOrdem.KeyboardType := TVirtualKeyboardType.NumberPad;

  CriarRotulo(LEditorConteudo, 'Imagem', 20, 326, 360, 20, $FF9CAABC, 10);
  LCampo := CriarFundoCampo(LEditorConteudo, 20, 348, 360, 38);
  FImagemUrl := TEdit.Create(Self); FImagemUrl.Parent := LCampo;
  FImagemUrl.Align := TAlignLayout.Client; FImagemUrl.Margins.Left := 10;
  FImagemUrl.Margins.Right := 10; FImagemUrl.StyleLookup := 'transparentedit';
  FImagemUrl.StyledSettings := []; FImagemUrl.TextSettings.FontColor := $FFF4F7FB;
  FImagemUrl.TextPrompt := 'Selecione uma imagem do computador';
  FImagemUrl.ReadOnly := True; FImagemUrl.Margins.Right := 46;
  FImagemUrl.ShowHint := True;
  FBtnImagem := CriarBotao(LCampo, '', 38, SelecionarImagemClick);
  FBtnImagem.Align := TAlignLayout.Right; FBtnImagem.Margins.Right := 2;
  FBtnImagem.Height := 34; FBtnImagem.Icone := sbiPesquisar;
  ConfigurarBotaoIcone(FBtnImagem, 'Selecionar imagem');

  CriarRotulo(LEditorConteudo, 'Descrição', 20, 394, 360, 20, $FF9CAABC, 10);
  LCampo := CriarFundoCampo(LEditorConteudo, 20, 416, 360, 92);
  FDescricao := TMemo.Create(Self); FDescricao.Parent := LCampo;
  FDescricao.Align := TAlignLayout.Client; FDescricao.Margins.Left := 8;
  FDescricao.Margins.Right := 8; FDescricao.OnApplyStyleLookup := MemoApplyStyleLookup;
  FDescricao.StyledSettings := []; FDescricao.TextSettings.FontColor := $FFF4F7FB;
  FDescricao.WordWrap := True;
  TNavegacaoCampos.Aplicar(Self, [FNome, FPreco, FPrecoPromocional,
    FCodigo, FOrdem, FDescricao]);

  FBtnTipo := CriarBotao(LEditorConteudo, 'Produto', 110, TipoClick);
  FBtnTipo.Align := TAlignLayout.None; FBtnTipo.Position.Point := PointF(20, 522);
  FBtnTipo.Height := 38; FBtnTipo.Icone := sbiCardapio;
  FBtnDisponivel := CriarBotao(LEditorConteudo, 'Disponível', 126, DisponivelEditorClick);
  FBtnDisponivel.Align := TAlignLayout.None;
  FBtnDisponivel.Position.Point := PointF(138, 522); FBtnDisponivel.Height := 38;
  FBtnDisponivel.Icone := sbiAtivar;
  FBtnDestaque := CriarBotao(LEditorConteudo, 'Destaque', 108, DestaqueClick);
  FBtnDestaque.Align := TAlignLayout.None;
  FBtnDestaque.Position.Point := PointF(272, 522); FBtnDestaque.Height := 38;
  FBtnDestaque.Icone := sbiAtivar;
  FBtnCancelar := CriarBotao(LEditorConteudo, 'Cancelar', 104, CancelarClick);
  FBtnCancelar.Align := TAlignLayout.None;
  FBtnCancelar.Position.Point := PointF(20, 586); FBtnCancelar.Height := 40;
  FBtnCancelar.Icone := sbiCancelar;
  FBtnSalvar := CriarBotao(LEditorConteudo, 'Salvar', 112, SalvarClick);
  FBtnSalvar.Align := TAlignLayout.None;
  FBtnSalvar.Position.Point := PointF(268, 586); FBtnSalvar.Height := 40;
  FBtnSalvar.Icone := sbiSalvar;

  LListaFundo := TRectangle.Create(Self); LListaFundo.Parent := lytConteudo;
  LListaFundo.Align := TAlignLayout.Client; LListaFundo.Fill.Color := $FF111E2E;
  LListaFundo.Stroke.Color := $FF23364D; LListaFundo.XRadius := 10;
  LListaFundo.YRadius := 10;
  FEstado := CriarRotulo(LListaFundo, 'Carregando cardápio...', 20, 16,
    500, 24, $FF8795A8, 11);
  FLista := TVertScrollBox.Create(Self); FLista.Parent := LListaFundo;
  FLista.Align := TAlignLayout.Client; FLista.Margins.Top := 48;
  FLista.Margins.Left := 8; FLista.Margins.Right := 8; FLista.Margins.Bottom := 8;
  FListaConteudo := TLayout.Create(Self); FListaConteudo.Parent := FLista;
  FListaConteudo.Align := TAlignLayout.Top; FListaConteudo.Height := 1;
end;

procedure TfraProdutosAdmin.PrepararTela;
begin
  if not FCarregado then
  begin CarregarCategorias; CarregarCardapio; end;
end;

procedure TfraProdutosAdmin.CarregarCategorias;
var
  H: TNetHTTPClient; R: IHTTPResponse; V, Item: TJSONValue;
  A: TJSONArray; J: TJSONObject; C: TCategoriaProduto;
begin
  H := TNetHTTPClient.Create(nil); V := nil;
  TSessaoAdmin.ConfigurarCliente(H);
  try
    R := H.Get(URL_CARDAPIO + '/categorias?empresaId=' +
      TNetEncoding.URL.Encode(TSessaoAdmin.EmpresaId));
    if R.StatusCode <> 200 then begin ExibirErroAPI('Erro ao carregar categorias', R); Exit; end;
    V := TJSONObject.ParseJSONValue(R.ContentAsString(TEncoding.UTF8));
    A := TJSONObject(V).GetValue<TJSONArray>('categorias'); FCategorias.Clear;
    for Item in A do
    begin
      J := Item as TJSONObject; C := TCategoriaProduto.Create;
      C.Id := J.GetValue<string>('id', ''); C.Nome := J.GetValue<string>('nome', '');
      FCategorias.Add(C);
    end;
    PreencherCategoriasEditor;
  finally V.Free; H.Free; end;
end;

procedure TfraProdutosAdmin.CarregarCardapio;
var
  H: TNetHTTPClient; R: IHTTPResponse; V, Item, Promo: TJSONValue;
  A: TJSONArray; J: TJSONObject; P: TProdutoAdmin; URL: string;
begin
  FEstado.Text := 'Carregando cardápio...'; FLista.Enabled := False;
  H := TNetHTTPClient.Create(nil); V := nil;
  TSessaoAdmin.ConfigurarCliente(H);
  try
    try
      URL := URL_CARDAPIO + '?empresaId=' + TNetEncoding.URL.Encode(TSessaoAdmin.EmpresaId);
      if not FBusca.Text.Trim.IsEmpty then
        URL := URL + '&busca=' + TNetEncoding.URL.Encode(FBusca.Text.Trim);
      R := H.Get(URL);
      if R.StatusCode <> 200 then begin ExibirErroAPI('Erro ao carregar cardápio', R); Exit; end;
      V := TJSONObject.ParseJSONValue(R.ContentAsString(TEncoding.UTF8));
      A := TJSONObject(V).GetValue<TJSONArray>('produtos'); FProdutos.Clear;
      for Item in A do
      begin
        J := Item as TJSONObject; P := TProdutoAdmin.Create;
        P.Id := J.GetValue<string>('id', ''); P.CategoriaId := J.GetValue<string>('categoria_id', '');
        P.CategoriaNome := J.GetValue<string>('categoria_nome', '');
        P.Tipo := J.GetValue<string>('tipo', 'PRODUTO'); P.Nome := J.GetValue<string>('nome', '');
        P.Descricao := J.GetValue<string>('descricao', '');
        P.Preco := StrToCurrDef(J.GetValue<string>('preco', '0'), 0, TFormatSettings.Invariant);
        Promo := J.GetValue('preco_promocional');
        P.TemPrecoPromocional := Assigned(Promo) and not (Promo is TJSONNull);
        if P.TemPrecoPromocional then
          P.PrecoPromocional := StrToCurrDef(Promo.Value, 0, TFormatSettings.Invariant);
        P.ImagemUrl := J.GetValue<string>('imagem_url', '');
        P.CodigoInterno := J.GetValue<string>('codigo_interno', '');
        P.Disponivel := J.GetValue<Boolean>('disponivel', True);
        P.Destaque := J.GetValue<Boolean>('destaque', False);
        P.Ordem := J.GetValue<Integer>('ordem', 0); P.Ativo := J.GetValue<Boolean>('ativo', True);
        FProdutos.Add(P);
      end;
      FCarregado := True; PreencherLista;
    except on E: Exception do
      begin FEstado.Text := 'API indisponível. Tente novamente.';
        TfrmMensagem.Exibir('Erro de comunicação', E.Message, tmErro); end;
    end;
  finally V.Free; H.Free; FLista.Enabled := True; end;
end;

procedure TfraProdutosAdmin.PreencherCategoriasEditor;
var I: Integer; C: TCategoriaProduto; R: TRectangle; L: TLabel;
begin
  while FCategoriasConteudo.ChildrenCount > 0 do FCategoriasConteudo.Children[0].Free;
  FCategoriasConteudo.Height := FCategorias.Count * 36;
  for I := 0 to FCategorias.Count - 1 do
  begin
    C := FCategorias[I]; R := TRectangle.Create(Self); R.Parent := FCategoriasConteudo;
    R.Position.Point := PointF(2, I * 36 + 1); R.Width := FCategoriasConteudo.Width - 4;
    R.Height := 33; R.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akRight];
    R.Fill.Color := $FF192A40; R.Stroke.Color := $FF2A405B; R.XRadius := 5;
    R.YRadius := 5; R.Tag := I; R.OnClick := CategoriaClick;
    if C.Id = FCategoriaSelecionadaId then
    begin
      R.Fill.Color := $FF2B2351;
      R.Stroke.Color := $FF8C63FF;
    end;
    L := CriarRotulo(R, C.Nome, 10, 0, 300, 33, $FFD5DCE6, 10); L.HitTest := False;
  end;
end;

function TfraProdutosAdmin.ProdutoVisivel(const AProduto: TProdutoAdmin): Boolean;
begin
  case FFiltro of
    pfDisponiveis: Result := AProduto.Ativo and AProduto.Disponivel;
    pfIndisponiveis: Result := AProduto.Ativo and not AProduto.Disponivel;
    pfInativos: Result := not AProduto.Ativo;
  else Result := True; end;
end;

procedure TfraProdutosAdmin.PreencherLista;
var
  P: TProdutoAdmin; Card: TRectangle; Texto, Acoes: TLayout;
  Nome, Detalhe, Status: TLabel; Editar, Ativo, Disponivel: TfraSensorButton;
  Resumo, StatusTexto, PrecoTexto: string; I, Posicao, Exibidos: Integer;
begin
  while FListaConteudo.ChildrenCount > 0 do FListaConteudo.Children[0].Free;
  FSelecionado := -1; Exibidos := 0;
  for P in FProdutos do if ProdutoVisivel(P) then Inc(Exibidos);
  FListaConteudo.Height := Exibidos * 72; Posicao := 0;
  for I := 0 to FProdutos.Count - 1 do
  begin
    P := FProdutos[I]; if not ProdutoVisivel(P) then Continue;
    if not P.Ativo then StatusTexto := 'INATIVO'
    else if not P.Disponivel then StatusTexto := 'INDISP.' else StatusTexto := 'ATIVO';
    PrecoTexto := FormatCurr('R$ #,##0.00', P.Preco);
    if P.TemPrecoPromocional then PrecoTexto := PrecoTexto + ' → ' +
      FormatCurr('R$ #,##0.00', P.PrecoPromocional);
    Resumo := P.CategoriaNome + '  •  ' + PrecoTexto;
    if not P.CodigoInterno.IsEmpty then Resumo := Resumo + '  •  Cód. ' + P.CodigoInterno;
    if P.Destaque then Resumo := Resumo + '  •  DESTAQUE';
    Card := TRectangle.Create(Self); Card.Parent := FListaConteudo;
    Card.Position.Point := PointF(4, Posicao * 72 + 2);
    Card.Width := FListaConteudo.Width - 8; Card.Height := 66;
    Card.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akRight];
    Card.Fill.Color := $FF152439; Card.Stroke.Color := $FF23364D;
    Card.XRadius := 7; Card.YRadius := 7; Card.Tag := I; Card.OnClick := ProdutoClick;
    Acoes := TLayout.Create(Self); Acoes.Parent := Card;
    Acoes.Align := TAlignLayout.Right; Acoes.Width := 210;
    Editar := CriarBotao(Acoes, '', 38, EditarClick); Editar.Align := TAlignLayout.None;
    Editar.Position.Point := PointF(0, 16); Editar.Icone := sbiEditar; Editar.Tag := I;
    ConfigurarBotaoIcone(Editar, 'Editar produto');
    Ativo := CriarBotao(Acoes, '', 38, AtivoClick); Ativo.Align := TAlignLayout.None;
    Ativo.Position.Point := PointF(46, 16); Ativo.Tag := I;
    if P.Ativo then begin Ativo.Icone := sbiCancelar; ConfigurarBotaoIcone(Ativo, 'Desativar produto'); end
    else begin Ativo.Icone := sbiAtivar; ConfigurarBotaoIcone(Ativo, 'Ativar produto'); end;
    Disponivel := CriarBotao(Acoes, '', 38, DisponibilidadeClick);
    Disponivel.Align := TAlignLayout.None; Disponivel.Position.Point := PointF(92, 16);
    Disponivel.Tag := I;
    if P.Disponivel then begin Disponivel.Icone := sbiBloquear; ConfigurarBotaoIcone(Disponivel, 'Marcar indisponível'); end
    else begin Disponivel.Icone := sbiAtivar; ConfigurarBotaoIcone(Disponivel, 'Marcar disponível'); end;
    Status := CriarRotulo(Acoes, StatusTexto, 138, 0, 60, 66, $FF45D483, 8);
    Status.TextSettings.HorzAlign := TTextAlign.Trailing; Status.HitTest := False;
    if not P.Ativo then Status.TextSettings.FontColor := $FFFFB454
    else if not P.Disponivel then Status.TextSettings.FontColor := $FFFF6B75;
    Texto := TLayout.Create(Self); Texto.Parent := Card; Texto.Align := TAlignLayout.Client;
    Texto.Margins.Left := 14; Texto.Margins.Right := 12; Texto.HitTest := False;
    Nome := CriarRotulo(Texto, P.Nome, 0, 7, 600, 24, $FFF4F7FB, 11);
    Nome.Align := TAlignLayout.Top; Nome.HitTest := False;
    Nome.TextSettings.Font.Style := [TFontStyle.fsBold];
    Detalhe := CriarRotulo(Texto, Resumo, 0, 34, 800, 22, $FF8795A8, 9);
    Detalhe.Align := TAlignLayout.Bottom; Detalhe.Margins.Bottom := 7;
    Detalhe.HitTest := False; Inc(Posicao);
  end;
  if Exibidos = 0 then FEstado.Text := 'Nenhum produto encontrado neste filtro.'
  else if Exibidos = FProdutos.Count then
    FEstado.Text := Format('%d produto(s) encontrado(s)', [Exibidos])
  else FEstado.Text := Format('%d de %d produto(s)', [Exibidos, FProdutos.Count]);
end;

procedure TfraProdutosAdmin.AtualizarFiltros;
begin
  FBtnTodos.Estilo := sbsSecondary; FBtnDisponiveis.Estilo := sbsSecondary;
  FBtnIndisponiveis.Estilo := sbsSecondary; FBtnInativos.Estilo := sbsSecondary;
  case FFiltro of
    pfTodos: FBtnTodos.Estilo := sbsPrimary;
    pfDisponiveis: FBtnDisponiveis.Estilo := sbsPrimary;
    pfIndisponiveis: FBtnIndisponiveis.Estilo := sbsPrimary;
    pfInativos: FBtnInativos.Estilo := sbsPrimary;
  end;
end;

procedure TfraProdutosAdmin.FiltroClick(Sender: TObject);
begin
  if Sender is TfraSensorButton then
  begin FFiltro := TProdutoFiltro(TfraSensorButton(Sender).Tag);
    AtualizarFiltros; PreencherLista; end;
end;

function TfraProdutosAdmin.ProdutoSelecionado: TProdutoAdmin;
begin
  Result := nil;
  if (FSelecionado >= 0) and (FSelecionado < FProdutos.Count) then
    Result := FProdutos[FSelecionado];
end;

procedure TfraProdutosAdmin.ProdutoClick(Sender: TObject);
var I: Integer; Card: TRectangle;
begin
  if not (Sender is TRectangle) then Exit;
  FSelecionado := TRectangle(Sender).Tag;
  for I := 0 to FListaConteudo.ChildrenCount - 1 do
    if FListaConteudo.Children[I] is TRectangle then
    begin Card := TRectangle(FListaConteudo.Children[I]);
      if Card.Tag = FSelecionado then begin Card.Fill.Color := $FF2B2351; Card.Stroke.Color := $FF8C63FF; end
      else begin Card.Fill.Color := $FF152439; Card.Stroke.Color := $FF23364D; end; end;
end;

procedure TfraProdutosAdmin.NovoClick(Sender: TObject); begin AbrirEditor(nil); end;
procedure TfraProdutosAdmin.EditarClick(Sender: TObject);
begin if Sender is TfraSensorButton then FSelecionado := TfraSensorButton(Sender).Tag;
  AbrirEditor(ProdutoSelecionado); end;

procedure TfraProdutosAdmin.AbrirEditor(const AProduto: TProdutoAdmin);
begin
  if Assigned(AProduto) then
  begin
    FEditandoId := AProduto.Id; FTituloEdicao.Text := 'Editar produto';
    FNome.Text := AProduto.Nome; FCategoriaSelecionadaId := AProduto.CategoriaId;
    FPreco.Text := FormatCurr('0.00', AProduto.Preco);
    if AProduto.TemPrecoPromocional then FPrecoPromocional.Text := FormatCurr('0.00', AProduto.PrecoPromocional)
    else FPrecoPromocional.Text := '';
    FCodigo.Text := AProduto.CodigoInterno; FOrdem.Text := IntToStr(AProduto.Ordem);
    ExibirImagemUrl(AProduto.ImagemUrl); FDescricao.Text := AProduto.Descricao;
    FTipo := AProduto.Tipo; FDisponivel := AProduto.Disponivel; FDestaque := AProduto.Destaque;
  end
  else
  begin
    FEditandoId := ''; FTituloEdicao.Text := 'Novo produto'; FNome.Text := '';
    if FCategorias.Count > 0 then FCategoriaSelecionadaId := FCategorias[0].Id else FCategoriaSelecionadaId := '';
    FPreco.Text := '0,00'; FPrecoPromocional.Text := ''; FCodigo.Text := '';
    FOrdem.Text := IntToStr(FProdutos.Count + 1); ExibirImagemUrl('');
    FDescricao.Text := ''; FTipo := 'PRODUTO'; FDisponivel := True; FDestaque := False;
  end;
  PreencherCategoriasEditor; AtualizarOpcoesEditor;
  FPainelEdicao.Visible := True; FPainelEdicao.BringToFront;
  FScrollEditor.ViewportPosition := PointF(0, 0); FNome.SetFocus;
end;

procedure TfraProdutosAdmin.FecharEditor;
begin FPainelEdicao.Visible := False; FEditandoId := ''; end;
procedure TfraProdutosAdmin.CancelarClick(Sender: TObject); begin FecharEditor; end;

procedure TfraProdutosAdmin.CategoriaClick(Sender: TObject);
begin
  if Sender is TRectangle then
  begin FCategoriaSelecionadaId := FCategorias[TRectangle(Sender).Tag].Id;
    PreencherCategoriasEditor; end;
end;

procedure TfraProdutosAdmin.TipoClick(Sender: TObject);
begin if FTipo = 'PRODUTO' then FTipo := 'COMBO' else FTipo := 'PRODUTO'; AtualizarOpcoesEditor; end;
procedure TfraProdutosAdmin.DisponivelEditorClick(Sender: TObject);
begin FDisponivel := not FDisponivel; AtualizarOpcoesEditor; end;
procedure TfraProdutosAdmin.DestaqueClick(Sender: TObject);
begin FDestaque := not FDestaque; AtualizarOpcoesEditor; end;

procedure TfraProdutosAdmin.AtualizarOpcoesEditor;
begin
  if FTipo = 'COMBO' then FBtnTipo.Texto := 'Combo' else FBtnTipo.Texto := 'Produto';
  if FDisponivel then begin FBtnDisponivel.Texto := 'Disponível'; FBtnDisponivel.Estilo := sbsPrimary; end
  else begin FBtnDisponivel.Texto := 'Indisponível'; FBtnDisponivel.Estilo := sbsSecondary; end;
  if FDestaque then begin FBtnDestaque.Texto := 'Destaque'; FBtnDestaque.Estilo := sbsPrimary; end
  else begin FBtnDestaque.Texto := 'Normal'; FBtnDestaque.Estilo := sbsSecondary; end;
end;

function TfraProdutosAdmin.TextoParaValor(const ATexto: string; out AValor: Currency): Boolean;
begin Result := TryStrToCurr(ATexto.Trim, AValor);
  if not Result then Result := TryStrToCurr(ATexto.Trim, AValor, TFormatSettings.Invariant); end;

procedure TfraProdutosAdmin.SalvarClick(Sender: TObject);
var Preco, Promo: Currency; Ordem: Integer; H: TNetHTTPClient;
  J: TJSONObject; S: TStringStream; R: IHTTPResponse;
begin
  if FNome.Text.Trim.IsEmpty then begin TfrmMensagem.Exibir('Campo obrigatório', 'Informe o nome do produto.', tmAtencao); Exit; end;
  if FCategoriaSelecionadaId.IsEmpty then begin TfrmMensagem.Exibir('Campo obrigatório', 'Selecione uma categoria.', tmAtencao); Exit; end;
  if not TextoParaValor(FPreco.Text, Preco) or (Preco < 0) then begin TfrmMensagem.Exibir('Preço inválido', 'Informe um preço maior ou igual a zero.', tmAtencao); Exit; end;
  if not FPrecoPromocional.Text.Trim.IsEmpty then
    if not TextoParaValor(FPrecoPromocional.Text, Promo) or (Promo < 0) then begin TfrmMensagem.Exibir('Preço inválido', 'Confira o preço promocional.', tmAtencao); Exit; end;
  if not TryStrToInt(FOrdem.Text.Trim, Ordem) or (Ordem < 0) then begin TfrmMensagem.Exibir('Ordem inválida', 'Informe uma ordem válida.', tmAtencao); Exit; end;
  J := TJSONObject.Create;
  if FEditandoId.IsEmpty then J.AddPair('empresaId', TSessaoAdmin.EmpresaId);
  J.AddPair('categoriaId', FCategoriaSelecionadaId); J.AddPair('tipo', FTipo);
  J.AddPair('nome', FNome.Text.Trim); J.AddPair('descricao', FDescricao.Text.Trim);
  J.AddPair('preco', TJSONNumber.Create(Double(Preco)));
  if FPrecoPromocional.Text.Trim.IsEmpty then J.AddPair('precoPromocional', '')
  else J.AddPair('precoPromocional', TJSONNumber.Create(Double(Promo)));
  J.AddPair('imagemUrl', ImagemUrlAtual); J.AddPair('codigoInterno', FCodigo.Text.Trim);
  J.AddPair('ordem', TJSONNumber.Create(Ordem)); J.AddPair('disponivel', TJSONBool.Create(FDisponivel));
  J.AddPair('destaque', TJSONBool.Create(FDestaque));
  H := TNetHTTPClient.Create(nil); TSessaoAdmin.ConfigurarCliente(H); S := TStringStream.Create(J.ToJSON, TEncoding.UTF8);
  try try
    H.ContentType := 'application/json'; H.Accept := 'application/json';
    if FEditandoId.IsEmpty then R := H.Post(URL_CARDAPIO, S)
    else R := H.Put(URL_CARDAPIO + '/' + FEditandoId, S);
    if not (R.StatusCode in [200, 201]) then begin ExibirErroAPI('Não foi possível salvar o produto', R); Exit; end;
    FecharEditor; CarregarCardapio;
    TfrmMensagem.Exibir('Produto salvo', 'Os dados foram salvos com sucesso.', tmSucesso);
  except on E: Exception do TfrmMensagem.Exibir('Erro de comunicação', E.Message, tmErro); end;
  finally S.Free; H.Free; J.Free; end;
end;

procedure TfraProdutosAdmin.AtivoClick(Sender: TObject);
var P: TProdutoAdmin; H: TNetHTTPClient; J: TJSONObject; S: TStringStream; R: IHTTPResponse;
begin
  if Sender is TfraSensorButton then FSelecionado := TfraSensorButton(Sender).Tag;
  P := ProdutoSelecionado; if not Assigned(P) then Exit;
  J := TJSONObject.Create; J.AddPair('ativo', TJSONBool.Create(not P.Ativo));
  H := TNetHTTPClient.Create(nil); TSessaoAdmin.ConfigurarCliente(H); S := TStringStream.Create(J.ToJSON, TEncoding.UTF8);
  try H.ContentType := 'application/json'; R := H.Patch(URL_CARDAPIO + '/' + P.Id + '/situacao', S);
    if R.StatusCode <> 200 then ExibirErroAPI('Não foi possível alterar o produto', R) else CarregarCardapio;
  finally S.Free; H.Free; J.Free; end;
end;

procedure TfraProdutosAdmin.DisponibilidadeClick(Sender: TObject);
var P: TProdutoAdmin; H: TNetHTTPClient; J: TJSONObject; S: TStringStream; R: IHTTPResponse;
begin
  if Sender is TfraSensorButton then FSelecionado := TfraSensorButton(Sender).Tag;
  P := ProdutoSelecionado; if not Assigned(P) then Exit;
  J := TJSONObject.Create; J.AddPair('disponivel', TJSONBool.Create(not P.Disponivel));
  H := TNetHTTPClient.Create(nil); TSessaoAdmin.ConfigurarCliente(H); S := TStringStream.Create(J.ToJSON, TEncoding.UTF8);
  try H.ContentType := 'application/json'; R := H.Patch(URL_CARDAPIO + '/' + P.Id + '/situacao', S);
    if R.StatusCode <> 200 then ExibirErroAPI('Não foi possível alterar a disponibilidade', R) else CarregarCardapio;
  finally S.Free; H.Free; J.Free; end;
end;

procedure TfraProdutosAdmin.BuscarClick(Sender: TObject); begin FTimerBusca.Enabled := False; CarregarCardapio; end;
procedure TfraProdutosAdmin.BuscaChange(Sender: TObject); begin FTimerBusca.Enabled := False; FTimerBusca.Enabled := True; end;
procedure TfraProdutosAdmin.TimerBuscaTimer(Sender: TObject); begin FTimerBusca.Enabled := False; CarregarCardapio; end;
procedure TfraProdutosAdmin.BuscaKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin if Key = vkReturn then begin Key := 0; KeyChar := #0; FTimerBusca.Enabled := False; CarregarCardapio; end; end;

procedure TfraProdutosAdmin.MemoApplyStyleLookup(Sender: TObject);
var Fundo: TControl;
begin if FDescricao.FindStyleResource<TControl>('background', Fundo) then begin Fundo.Opacity := 0; Fundo.HitTest := False; end; end;

procedure TfraProdutosAdmin.ExibirErroAPI(const ATitulo: string; const AResposta: IHTTPResponse);
var V: TJSONValue; M: string;
begin
  M := 'A API retornou o código ' + IntToStr(AResposta.StatusCode) + '.';
  V := TJSONObject.ParseJSONValue(AResposta.ContentAsString(TEncoding.UTF8));
  try if V is TJSONObject then M := TJSONObject(V).GetValue<string>('erro', M); finally V.Free; end;
  TfrmMensagem.Exibir(ATitulo, M, tmErro);
end;

procedure TfraProdutosAdmin.SelecionarImagemClick(Sender: TObject);
var LURL: string;
begin
  try
    if TImagemUpload.SelecionarEEnviar(Self, LURL) then ExibirImagemUrl(LURL);
  except on E: Exception do
    TfrmMensagem.Exibir('Erro ao enviar imagem', E.Message, tmErro); end;
end;

procedure TfraProdutosAdmin.ExibirImagemUrl(const AUrl: string);
var
  LPosicao: Integer;
begin
  FImagemUrl.TagString := AUrl.Trim;
  FImagemUrl.Hint := FImagemUrl.TagString;
  LPosicao := LastDelimiter('/\', FImagemUrl.TagString);
  if LPosicao > 0 then
    FImagemUrl.Text := Copy(FImagemUrl.TagString, LPosicao + 1, MaxInt)
  else
    FImagemUrl.Text := FImagemUrl.TagString;
end;

function TfraProdutosAdmin.ImagemUrlAtual: string;
begin
  Result := FImagemUrl.TagString.Trim;
end;

end.
