unit uFrameCombos;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.JSON,
  System.Net.URLClient, System.Net.HttpClient, System.Net.HttpClientComponent,
  System.NetEncoding, System.Generics.Collections, System.Math,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Objects,
  FMX.Layouts, FMX.Controls.Presentation, FMX.Edit, FMX.Memo,
  uFrameSensorButton;

type
  TComboFiltro = (cfTodos, cfDisponiveis, cfIndisponiveis, cfInativos);

  TCategoriaCombo = class
  public
    Id, Nome: string;
  end;

  TProdutoComboOpcao = class
  public
    Id, Nome, CategoriaNome: string;
    Preco: Currency;
  end;

  TComboItemAdmin = class
  public
    ProdutoId, ProdutoNome: string;
    Quantidade, Ordem: Integer;
  end;

  TComboAdmin = class
  public
    Id, CategoriaId, CategoriaNome, Nome, Descricao, CodigoInterno: string;
    Preco, PrecoPromocional: Currency;
    TemPrecoPromocional, Disponivel, Destaque, Ativo: Boolean;
    Ordem, QuantidadeItens: Integer;
    Itens: TObjectList<TComboItemAdmin>;
    constructor Create;
    destructor Destroy; override;
  end;

  TfraCombos = class(TFrame)
    rctFundo: TRectangle;
    lytPrincipal, lytCabecalho, lytConteudo: TLayout;
    lblTitulo, lblSubtitulo: TLabel;
  private
    FCombos: TObjectList<TComboAdmin>;
    FCategorias: TObjectList<TCategoriaCombo>;
    FProdutos: TObjectList<TProdutoComboOpcao>;
    FItensEditor: TObjectList<TComboItemAdmin>;
    FCarregado: Boolean;
    FSelecionado: Integer;
    FFiltro: TComboFiltro;
    FEditandoId, FCategoriaSelecionadaId: string;
    FDisponivel, FDestaque: Boolean;
    FBarra, FFiltros, FListaConteudo, FCategoriasConteudo,
      FItensConteudo, FProdutosConteudo: TLayout;
    FBusca, FNome, FPreco, FPrecoPromocional, FCodigo, FOrdem: TEdit;
    FDescricao: TMemo;
    FLista, FScrollEditor, FCategoriasLista, FItensLista,
      FProdutosLista: TVertScrollBox;
    FEstado, FTituloEdicao: TLabel;
    FPainelEdicao: TRectangle;
    FTimerBusca: TTimer;
    FBtnNovo, FBtnBuscar, FBtnSalvar, FBtnCancelar: TfraSensorButton;
    FBtnTodos, FBtnDisponiveis, FBtnIndisponiveis,
      FBtnInativos: TfraSensorButton;
    FBtnDisponivel, FBtnDestaque: TfraSensorButton;
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
    function ComboSelecionado: TComboAdmin;
    function ComboVisivel(const ACombo: TComboAdmin): Boolean;
    function TextoParaValor(const ATexto: string; out AValor: Currency): Boolean;
    function ResumoItens(const ACombo: TComboAdmin): string;
    function ItemEditorPorProduto(const AProdutoId: string): TComboItemAdmin;
    procedure PreencherLista;
    procedure PreencherCategoriasEditor;
    procedure PreencherComposicaoEditor;
    procedure PreencherProdutosEditor;
    procedure AtualizarFiltros;
    procedure AtualizarOpcoesEditor;
    procedure AbrirEditor(const ACombo: TComboAdmin);
    procedure FecharEditor;
    procedure ExibirErroAPI(const ATitulo: string; const AResposta: IHTTPResponse);
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
    procedure ComboClick(Sender: TObject);
    procedure CategoriaClick(Sender: TObject);
    procedure ProdutoOpcaoClick(Sender: TObject);
    procedure RemoverItemClick(Sender: TObject);
    procedure DisponivelEditorClick(Sender: TObject);
    procedure DestaqueClick(Sender: TObject);
    procedure MemoApplyStyleLookup(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure PrepararTela;
    procedure CarregarCombos;
    procedure CarregarOpcoes;
  end;

implementation

{$R *.fmx}

uses uMensagem, uSessaoAdmin, uNavegacaoCampos, uApiConfig;

function URL_COMBOS: string;
begin
  Result := TApiConfig.Url('/api/combos');
end;

constructor TComboAdmin.Create;
begin
  inherited;
  Itens := TObjectList<TComboItemAdmin>.Create(True);
end;

destructor TComboAdmin.Destroy;
begin
  Itens.Free;
  inherited;
end;

constructor TfraCombos.Create(AOwner: TComponent);
begin
  inherited;
  FCombos := TObjectList<TComboAdmin>.Create(True);
  FCategorias := TObjectList<TCategoriaCombo>.Create(True);
  FProdutos := TObjectList<TProdutoComboOpcao>.Create(True);
  FItensEditor := TObjectList<TComboItemAdmin>.Create(True);
  FSelecionado := -1;
  FFiltro := cfTodos;
  MontarTela;
end;

destructor TfraCombos.Destroy;
begin
  FItensEditor.Free;
  FProdutos.Free;
  FCategorias.Free;
  FCombos.Free;
  inherited;
end;

function TfraCombos.CriarRotulo(const AParent: TFmxObject;
  const ATexto: string; const AX, AY, AWidth, AHeight: Single;
  const ACor: TAlphaColor; const ATamanho: Single): TLabel;
begin
  Result := TLabel.Create(Self); Result.Parent := AParent;
  Result.Position.Point := PointF(AX, AY); Result.Width := AWidth;
  Result.Height := AHeight; Result.Text := ATexto; Result.StyledSettings := [];
  Result.TextSettings.Font.Family := 'Manrope';
  Result.TextSettings.Font.Size := ATamanho;
  Result.TextSettings.FontColor := ACor;
end;

function TfraCombos.CriarBotao(const AParent: TFmxObject;
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

function TfraCombos.CriarFundoCampo(const AParent: TFmxObject;
  const AX, AY, AWidth, AHeight: Single): TRectangle;
begin
  Result := TRectangle.Create(Self); Result.Parent := AParent;
  Result.Position.Point := PointF(AX, AY); Result.Width := AWidth;
  Result.Height := AHeight; Result.Fill.Color := $FF152439;
  Result.Stroke.Color := $FF2A405B; Result.XRadius := 6; Result.YRadius := 6;
end;

procedure TfraCombos.ConfigurarBotaoIcone(const ABotao: TfraSensorButton;
  const AHint: string);
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

procedure TfraCombos.MontarTela;
var
  LBuscaFundo, LListaFundo, LCampo: TRectangle;
  LEditor: TLayout;
begin
  FBarra := TLayout.Create(Self); FBarra.Parent := lytConteudo;
  FBarra.Align := TAlignLayout.Top; FBarra.Height := 44;
  FBarra.Margins.Bottom := 12;
  FBtnNovo := CriarBotao(FBarra, '+ Novo combo', 132, NovoClick);
  FBtnNovo.Align := TAlignLayout.Right; FBtnNovo.Estilo := sbsPrimary;
  FBtnNovo.Icone := sbiCombo;
  FBtnBuscar := CriarBotao(FBarra, 'Buscar', 96, BuscarClick);
  FBtnBuscar.Align := TAlignLayout.Right; FBtnBuscar.Icone := sbiPesquisar;
  LBuscaFundo := CriarFundoCampo(FBarra, 0, 0, 100, 44);
  LBuscaFundo.Align := TAlignLayout.Client; LBuscaFundo.Margins.Right := 12;
  LBuscaFundo.XRadius := 8; LBuscaFundo.YRadius := 8;
  FBusca := TEdit.Create(Self); FBusca.Parent := LBuscaFundo;
  FBusca.Align := TAlignLayout.Client; FBusca.Margins.Left := 12;
  FBusca.Margins.Right := 12; FBusca.StyleLookup := 'transparentedit';
  FBusca.TextPrompt := 'Buscar combo, categoria ou código';
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
  FBtnTodos.Height := 36; FBtnTodos.Icone := sbiRelatorio;
  FBtnTodos.Tag := Ord(cfTodos);
  FBtnDisponiveis := CriarBotao(FFiltros, 'Disponíveis', 126, FiltroClick);
  FBtnDisponiveis.Align := TAlignLayout.None;
  FBtnDisponiveis.Position.Point := PointF(170, 2); FBtnDisponiveis.Height := 36;
  FBtnDisponiveis.Icone := sbiAtivar; FBtnDisponiveis.Tag := Ord(cfDisponiveis);
  FBtnIndisponiveis := CriarBotao(FFiltros, 'Indisponíveis', 138, FiltroClick);
  FBtnIndisponiveis.Align := TAlignLayout.None;
  FBtnIndisponiveis.Position.Point := PointF(304, 2);
  FBtnIndisponiveis.Height := 36; FBtnIndisponiveis.Icone := sbiCancelar;
  FBtnIndisponiveis.Tag := Ord(cfIndisponiveis);
  FBtnInativos := CriarBotao(FFiltros, 'Inativos', 108, FiltroClick);
  FBtnInativos.Align := TAlignLayout.None;
  FBtnInativos.Position.Point := PointF(450, 2); FBtnInativos.Height := 36;
  FBtnInativos.Icone := sbiBloquear; FBtnInativos.Tag := Ord(cfInativos);
  AtualizarFiltros;

  FPainelEdicao := TRectangle.Create(Self); FPainelEdicao.Parent := lytConteudo;
  FPainelEdicao.Align := TAlignLayout.Right; FPainelEdicao.Width := 440;
  FPainelEdicao.Margins.Left := 14; FPainelEdicao.Fill.Color := $FF111E2E;
  FPainelEdicao.Stroke.Color := $FF2A405B;
  FPainelEdicao.XRadius := 10; FPainelEdicao.YRadius := 10;
  FPainelEdicao.Visible := False;
  FTituloEdicao := CriarRotulo(FPainelEdicao, 'Novo combo', 20, 14,
    400, 30, $FFF4F7FB, 16);
  FTituloEdicao.TextSettings.Font.Style := [TFontStyle.fsBold];
  FScrollEditor := TVertScrollBox.Create(Self); FScrollEditor.Parent := FPainelEdicao;
  FScrollEditor.Align := TAlignLayout.Client; FScrollEditor.Margins.Top := 50;
  FScrollEditor.Margins.Bottom := 8;
  LEditor := TLayout.Create(Self); LEditor.Parent := FScrollEditor;
  LEditor.Align := TAlignLayout.Top; LEditor.Height := 920;

  CriarRotulo(LEditor, 'Nome *', 20, 0, 400, 20, $FF9CAABC, 10);
  LCampo := CriarFundoCampo(LEditor, 20, 22, 400, 38);
  FNome := TEdit.Create(Self); FNome.Parent := LCampo; FNome.Align := TAlignLayout.Client;
  FNome.Margins.Left := 10; FNome.Margins.Right := 10;
  FNome.StyleLookup := 'transparentedit'; FNome.StyledSettings := [];
  FNome.TextSettings.FontColor := $FFF4F7FB; FNome.TextPrompt := 'Nome do combo';
  CriarRotulo(LEditor, 'Categoria *', 20, 68, 400, 20, $FF9CAABC, 10);
  LCampo := CriarFundoCampo(LEditor, 20, 90, 400, 90);
  FCategoriasLista := TVertScrollBox.Create(Self); FCategoriasLista.Parent := LCampo;
  FCategoriasLista.Align := TAlignLayout.Client;
  FCategoriasLista.Margins.Rect := RectF(4, 4, 4, 4);
  FCategoriasConteudo := TLayout.Create(Self);
  FCategoriasConteudo.Parent := FCategoriasLista;
  FCategoriasConteudo.Align := TAlignLayout.Top;

  CriarRotulo(LEditor, 'Preço *', 20, 188, 190, 20, $FF9CAABC, 10);
  CriarRotulo(LEditor, 'Preço promocional', 230, 188, 190, 20, $FF9CAABC, 10);
  LCampo := CriarFundoCampo(LEditor, 20, 210, 190, 38);
  FPreco := TEdit.Create(Self); FPreco.Parent := LCampo; FPreco.Align := TAlignLayout.Client;
  FPreco.Margins.Left := 10; FPreco.Margins.Right := 10;
  FPreco.StyleLookup := 'transparentedit'; FPreco.StyledSettings := [];
  FPreco.TextSettings.FontColor := $FFF4F7FB;
  FPreco.KeyboardType := TVirtualKeyboardType.DecimalNumberPad;
  LCampo := CriarFundoCampo(LEditor, 230, 210, 190, 38);
  FPrecoPromocional := TEdit.Create(Self); FPrecoPromocional.Parent := LCampo;
  FPrecoPromocional.Align := TAlignLayout.Client;
  FPrecoPromocional.Margins.Left := 10; FPrecoPromocional.Margins.Right := 10;
  FPrecoPromocional.StyleLookup := 'transparentedit';
  FPrecoPromocional.StyledSettings := [];
  FPrecoPromocional.TextSettings.FontColor := $FFF4F7FB;
  FPrecoPromocional.KeyboardType := TVirtualKeyboardType.DecimalNumberPad;

  CriarRotulo(LEditor, 'Código interno', 20, 256, 280, 20, $FF9CAABC, 10);
  CriarRotulo(LEditor, 'Ordem', 320, 256, 100, 20, $FF9CAABC, 10);
  LCampo := CriarFundoCampo(LEditor, 20, 278, 280, 38);
  FCodigo := TEdit.Create(Self); FCodigo.Parent := LCampo;
  FCodigo.Align := TAlignLayout.Client; FCodigo.Margins.Left := 10;
  FCodigo.Margins.Right := 10; FCodigo.StyleLookup := 'transparentedit';
  FCodigo.StyledSettings := []; FCodigo.TextSettings.FontColor := $FFF4F7FB;
  LCampo := CriarFundoCampo(LEditor, 320, 278, 100, 38);
  FOrdem := TEdit.Create(Self); FOrdem.Parent := LCampo;
  FOrdem.Align := TAlignLayout.Client; FOrdem.Margins.Left := 10;
  FOrdem.Margins.Right := 10; FOrdem.StyleLookup := 'transparentedit';
  FOrdem.StyledSettings := []; FOrdem.TextSettings.FontColor := $FFF4F7FB;
  FOrdem.KeyboardType := TVirtualKeyboardType.NumberPad;

  CriarRotulo(LEditor, 'Descrição', 20, 324, 400, 20, $FF9CAABC, 10);
  LCampo := CriarFundoCampo(LEditor, 20, 346, 400, 76);
  FDescricao := TMemo.Create(Self); FDescricao.Parent := LCampo;
  FDescricao.Align := TAlignLayout.Client; FDescricao.Margins.Left := 8;
  FDescricao.Margins.Right := 8; FDescricao.OnApplyStyleLookup := MemoApplyStyleLookup;
  FDescricao.StyledSettings := []; FDescricao.TextSettings.FontColor := $FFF4F7FB;
  TNavegacaoCampos.Aplicar(Self, [FNome, FPreco, FPrecoPromocional,
    FCodigo, FOrdem, FDescricao]);

  CriarRotulo(LEditor, 'Composição do combo', 20, 430, 400, 20, $FFF4F7FB, 11);
  LCampo := CriarFundoCampo(LEditor, 20, 452, 400, 110);
  FItensLista := TVertScrollBox.Create(Self); FItensLista.Parent := LCampo;
  FItensLista.Align := TAlignLayout.Client; FItensLista.Margins.Rect := RectF(4, 4, 4, 4);
  FItensConteudo := TLayout.Create(Self); FItensConteudo.Parent := FItensLista;
  FItensConteudo.Align := TAlignLayout.Top;
  CriarRotulo(LEditor, 'Produtos disponíveis — clique para adicionar', 20, 570,
    400, 20, $FF9CAABC, 10);
  LCampo := CriarFundoCampo(LEditor, 20, 592, 400, 170);
  FProdutosLista := TVertScrollBox.Create(Self); FProdutosLista.Parent := LCampo;
  FProdutosLista.Align := TAlignLayout.Client;
  FProdutosLista.Margins.Rect := RectF(4, 4, 4, 4);
  FProdutosConteudo := TLayout.Create(Self); FProdutosConteudo.Parent := FProdutosLista;
  FProdutosConteudo.Align := TAlignLayout.Top;

  FBtnDisponivel := CriarBotao(LEditor, 'Disponível', 126, DisponivelEditorClick);
  FBtnDisponivel.Align := TAlignLayout.None;
  FBtnDisponivel.Position.Point := PointF(20, 778); FBtnDisponivel.Height := 38;
  FBtnDisponivel.Icone := sbiAtivar;
  FBtnDestaque := CriarBotao(LEditor, 'Destaque', 112, DestaqueClick);
  FBtnDestaque.Align := TAlignLayout.None;
  FBtnDestaque.Position.Point := PointF(154, 778); FBtnDestaque.Height := 38;
  FBtnDestaque.Icone := sbiAtivar;
  FBtnCancelar := CriarBotao(LEditor, 'Cancelar', 104, CancelarClick);
  FBtnCancelar.Align := TAlignLayout.None;
  FBtnCancelar.Position.Point := PointF(20, 838); FBtnCancelar.Height := 40;
  FBtnCancelar.Icone := sbiCancelar;
  FBtnSalvar := CriarBotao(LEditor, 'Salvar', 112, SalvarClick);
  FBtnSalvar.Align := TAlignLayout.None;
  FBtnSalvar.Position.Point := PointF(308, 838); FBtnSalvar.Height := 40;
  FBtnSalvar.Icone := sbiSalvar;

  LListaFundo := TRectangle.Create(Self); LListaFundo.Parent := lytConteudo;
  LListaFundo.Align := TAlignLayout.Client; LListaFundo.Fill.Color := $FF111E2E;
  LListaFundo.Stroke.Color := $FF23364D;
  LListaFundo.XRadius := 10; LListaFundo.YRadius := 10;
  FEstado := CriarRotulo(LListaFundo, 'Carregando combos...', 20, 16,
    500, 24, $FF8795A8, 11);
  FLista := TVertScrollBox.Create(Self); FLista.Parent := LListaFundo;
  FLista.Align := TAlignLayout.Client; FLista.Margins.Top := 48;
  FLista.Margins.Left := 8; FLista.Margins.Right := 8;
  FLista.Margins.Bottom := 8;
  FListaConteudo := TLayout.Create(Self); FListaConteudo.Parent := FLista;
  FListaConteudo.Align := TAlignLayout.Top; FListaConteudo.Height := 1;
end;

procedure TfraCombos.PrepararTela;
begin
  if not FCarregado then
  begin CarregarOpcoes; CarregarCombos; end;
end;

procedure TfraCombos.CarregarOpcoes;
var
  H: TNetHTTPClient; R: IHTTPResponse; V, Item: TJSONValue;
  A: TJSONArray; J: TJSONObject; C: TCategoriaCombo; P: TProdutoComboOpcao;
begin
  H := TNetHTTPClient.Create(nil); V := nil;
  TSessaoAdmin.ConfigurarCliente(H);
  try
    try
      R := H.Get(URL_COMBOS + '/categorias?empresaId=' +
        TNetEncoding.URL.Encode(TSessaoAdmin.EmpresaId));
      if R.StatusCode <> 200 then begin ExibirErroAPI('Erro ao carregar categorias', R); Exit; end;
      V := TJSONObject.ParseJSONValue(R.ContentAsString(TEncoding.UTF8));
      A := TJSONObject(V).GetValue<TJSONArray>('categorias'); FCategorias.Clear;
      for Item in A do
      begin
        J := Item as TJSONObject; C := TCategoriaCombo.Create;
        C.Id := J.GetValue<string>('id', ''); C.Nome := J.GetValue<string>('nome', '');
        FCategorias.Add(C);
      end;
      FreeAndNil(V);
      R := H.Get(URL_COMBOS + '/produtos?empresaId=' +
        TNetEncoding.URL.Encode(TSessaoAdmin.EmpresaId));
      if R.StatusCode <> 200 then begin ExibirErroAPI('Erro ao carregar produtos', R); Exit; end;
      V := TJSONObject.ParseJSONValue(R.ContentAsString(TEncoding.UTF8));
      A := TJSONObject(V).GetValue<TJSONArray>('produtos'); FProdutos.Clear;
      for Item in A do
      begin
        J := Item as TJSONObject; P := TProdutoComboOpcao.Create;
        P.Id := J.GetValue<string>('id', ''); P.Nome := J.GetValue<string>('nome', '');
        P.CategoriaNome := J.GetValue<string>('categoria_nome', '');
        P.Preco := StrToCurrDef(J.GetValue<string>('preco', '0'), 0,
          TFormatSettings.Invariant); FProdutos.Add(P);
      end;
      PreencherCategoriasEditor; PreencherProdutosEditor;
    except on E: Exception do
      TfrmMensagem.Exibir('Erro de comunicação', E.Message, tmErro); end;
  finally V.Free; H.Free; end;
end;

procedure TfraCombos.CarregarCombos;
var
  H: TNetHTTPClient; R: IHTTPResponse; V, Item, ItemCombo, Promo: TJSONValue;
  A, AItens: TJSONArray; J, JItem: TJSONObject; C: TComboAdmin;
  CI: TComboItemAdmin; URL: string;
begin
  FEstado.Text := 'Carregando combos...'; FLista.Enabled := False;
  H := TNetHTTPClient.Create(nil); V := nil;
  TSessaoAdmin.ConfigurarCliente(H);
  try
    try
      URL := URL_COMBOS + '?empresaId=' + TNetEncoding.URL.Encode(TSessaoAdmin.EmpresaId);
      if not FBusca.Text.Trim.IsEmpty then
        URL := URL + '&busca=' + TNetEncoding.URL.Encode(FBusca.Text.Trim);
      R := H.Get(URL);
      if R.StatusCode <> 200 then
      begin ExibirErroAPI('Erro ao carregar combos', R); Exit; end;
      V := TJSONObject.ParseJSONValue(R.ContentAsString(TEncoding.UTF8));
      A := TJSONObject(V).GetValue<TJSONArray>('combos'); FCombos.Clear;
      for Item in A do
      begin
        J := Item as TJSONObject; C := TComboAdmin.Create;
        C.Id := J.GetValue<string>('id', '');
        C.CategoriaId := J.GetValue<string>('categoria_id', '');
        C.CategoriaNome := J.GetValue<string>('categoria_nome', '');
        C.Nome := J.GetValue<string>('nome', '');
        C.Descricao := J.GetValue<string>('descricao', '');
        C.CodigoInterno := J.GetValue<string>('codigo_interno', '');
        C.Preco := StrToCurrDef(J.GetValue<string>('preco', '0'), 0,
          TFormatSettings.Invariant);
        Promo := J.GetValue('preco_promocional');
        C.TemPrecoPromocional := Assigned(Promo) and not (Promo is TJSONNull);
        if C.TemPrecoPromocional then
          C.PrecoPromocional := StrToCurrDef(Promo.Value, 0, TFormatSettings.Invariant);
        C.Disponivel := J.GetValue<Boolean>('disponivel', True);
        C.Destaque := J.GetValue<Boolean>('destaque', False);
        C.Ativo := J.GetValue<Boolean>('ativo', True);
        C.Ordem := J.GetValue<Integer>('ordem', 0);
        C.QuantidadeItens := J.GetValue<Integer>('quantidade_itens', 0);
        if J.GetValue('itens') is TJSONArray then
        begin
          AItens := J.GetValue<TJSONArray>('itens');
          for ItemCombo in AItens do
          begin
            JItem := ItemCombo as TJSONObject; CI := TComboItemAdmin.Create;
            CI.ProdutoId := JItem.GetValue<string>('produto_id', '');
            CI.ProdutoNome := JItem.GetValue<string>('produto_nome', '');
            CI.Quantidade := JItem.GetValue<Integer>('quantidade', 1);
            CI.Ordem := JItem.GetValue<Integer>('ordem', 0); C.Itens.Add(CI);
          end;
        end;
        FCombos.Add(C);
      end;
      FCarregado := True; PreencherLista;
    except on E: Exception do
      begin FEstado.Text := 'API indisponível. Tente novamente.';
        TfrmMensagem.Exibir('Erro de comunicação', E.Message, tmErro); end;
    end;
  finally V.Free; H.Free; FLista.Enabled := True; end;
end;

function TfraCombos.ComboVisivel(const ACombo: TComboAdmin): Boolean;
begin
  case FFiltro of
    cfDisponiveis: Result := ACombo.Ativo and ACombo.Disponivel;
    cfIndisponiveis: Result := ACombo.Ativo and not ACombo.Disponivel;
    cfInativos: Result := not ACombo.Ativo;
  else Result := True;
  end;
end;

function TfraCombos.ResumoItens(const ACombo: TComboAdmin): string;
var I: Integer;
begin
  Result := '';
  for I := 0 to ACombo.Itens.Count - 1 do
  begin
    if not Result.IsEmpty then Result := Result + ', ';
    Result := Result + IntToStr(ACombo.Itens[I].Quantidade) + 'x ' +
      ACombo.Itens[I].ProdutoNome;
    if Length(Result) > 90 then begin Result := Copy(Result, 1, 87) + '...'; Break; end;
  end;
  if Result.IsEmpty then Result := 'Composição ainda não definida';
end;

procedure TfraCombos.PreencherLista;
var
  C: TComboAdmin; Card: TRectangle; Texto, Acoes: TLayout;
  Nome, Detalhe, Status: TLabel; Editar, Disponivel, Ativo: TfraSensorButton;
  Resumo, StatusTexto: string; StatusCor: TAlphaColor;
  I, Posicao, Exibidos: Integer;
begin
  while FListaConteudo.ChildrenCount > 0 do FListaConteudo.Children[0].Free;
  FSelecionado := -1; Exibidos := 0;
  for C in FCombos do if ComboVisivel(C) then Inc(Exibidos);
  FListaConteudo.Height := Exibidos * 72; Posicao := 0;
  for I := 0 to FCombos.Count - 1 do
  begin
    C := FCombos[I]; if not ComboVisivel(C) then Continue;
    if not C.Ativo then begin StatusTexto := 'INATIVO'; StatusCor := $FFFFB454; end
    else if C.Disponivel then begin StatusTexto := 'DISPONÍVEL'; StatusCor := $FF45D483; end
    else begin StatusTexto := 'INDISPONÍVEL'; StatusCor := $FFFF6B78; end;
    Resumo := C.CategoriaNome + '  •  ' + ResumoItens(C) + '  •  ' +
      FormatCurr('R$ #,##0.00', C.Preco);
    Card := TRectangle.Create(Self); Card.Parent := FListaConteudo;
    Card.Position.Point := PointF(4, Posicao * 72 + 2);
    Card.Width := FListaConteudo.Width - 8; Card.Height := 66;
    Card.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akRight];
    Card.Fill.Color := $FF152439; Card.Stroke.Color := $FF23364D;
    Card.XRadius := 7; Card.YRadius := 7; Card.Tag := I; Card.OnClick := ComboClick;
    Acoes := TLayout.Create(Self); Acoes.Parent := Card;
    Acoes.Align := TAlignLayout.Right; Acoes.Width := 252;
    Editar := CriarBotao(Acoes, '', 38, EditarClick); Editar.Align := TAlignLayout.None;
    Editar.Position.Point := PointF(0, 16); Editar.Icone := sbiEditar; Editar.Tag := I;
    ConfigurarBotaoIcone(Editar, 'Editar combo');
    Disponivel := CriarBotao(Acoes, '', 38, DisponibilidadeClick);
    Disponivel.Align := TAlignLayout.None; Disponivel.Position.Point := PointF(46, 16);
    Disponivel.Tag := I;
    if C.Disponivel then begin Disponivel.Icone := sbiCancelar;
      ConfigurarBotaoIcone(Disponivel, 'Marcar como indisponível'); end
    else begin Disponivel.Icone := sbiAtivar;
      ConfigurarBotaoIcone(Disponivel, 'Marcar como disponível'); end;
    Ativo := CriarBotao(Acoes, '', 38, AtivoClick); Ativo.Align := TAlignLayout.None;
    Ativo.Position.Point := PointF(92, 16); Ativo.Tag := I;
    if C.Ativo then begin Ativo.Icone := sbiBloquear;
      ConfigurarBotaoIcone(Ativo, 'Desativar combo'); end
    else begin Ativo.Icone := sbiAtivar;
      ConfigurarBotaoIcone(Ativo, 'Ativar combo'); end;
    Status := CriarRotulo(Acoes, StatusTexto, 136, 0, 104, 66, StatusCor, 9);
    Status.TextSettings.HorzAlign := TTextAlign.Trailing; Status.HitTest := False;
    Texto := TLayout.Create(Self); Texto.Parent := Card; Texto.Align := TAlignLayout.Client;
    Texto.Margins.Left := 14; Texto.Margins.Right := 12; Texto.HitTest := False;
    Nome := CriarRotulo(Texto, C.Nome, 0, 6, 500, 24, $FFF4F7FB, 11);
    Nome.Align := TAlignLayout.Top; Nome.HitTest := False;
    Nome.TextSettings.Font.Style := [TFontStyle.fsBold];
    Detalhe := CriarRotulo(Texto, Resumo, 0, 34, 800, 22, $FF8795A8, 9);
    Detalhe.Align := TAlignLayout.Bottom; Detalhe.Margins.Bottom := 6;
    Detalhe.HitTest := False; Inc(Posicao);
  end;
  if Exibidos = 0 then FEstado.Text := 'Nenhum combo encontrado neste filtro.'
  else FEstado.Text := Format('%d combo(s) encontrado(s)', [Exibidos]);
end;

procedure TfraCombos.AtualizarFiltros;
begin
  FBtnTodos.Estilo := sbsSecondary; FBtnDisponiveis.Estilo := sbsSecondary;
  FBtnIndisponiveis.Estilo := sbsSecondary; FBtnInativos.Estilo := sbsSecondary;
  case FFiltro of
    cfTodos: FBtnTodos.Estilo := sbsPrimary;
    cfDisponiveis: FBtnDisponiveis.Estilo := sbsPrimary;
    cfIndisponiveis: FBtnIndisponiveis.Estilo := sbsPrimary;
    cfInativos: FBtnInativos.Estilo := sbsPrimary;
  end;
end;

procedure TfraCombos.FiltroClick(Sender: TObject);
begin
  if Sender is TfraSensorButton then
  begin FFiltro := TComboFiltro(TfraSensorButton(Sender).Tag);
    AtualizarFiltros; PreencherLista; end;
end;

function TfraCombos.ComboSelecionado: TComboAdmin;
begin
  Result := nil;
  if (FSelecionado >= 0) and (FSelecionado < FCombos.Count) then
    Result := FCombos[FSelecionado];
end;

procedure TfraCombos.ComboClick(Sender: TObject);
begin
  if Sender is TRectangle then FSelecionado := TRectangle(Sender).Tag;
end;

procedure TfraCombos.PreencherCategoriasEditor;
var I: Integer; R: TRectangle; L: TLabel;
begin
  while FCategoriasConteudo.ChildrenCount > 0 do FCategoriasConteudo.Children[0].Free;
  FCategoriasConteudo.Height := FCategorias.Count * 32;
  for I := 0 to FCategorias.Count - 1 do
  begin
    R := TRectangle.Create(Self); R.Parent := FCategoriasConteudo;
    R.Position.Point := PointF(2, I * 32 + 1); R.Width := FCategoriasConteudo.Width - 4;
    R.Height := 29; R.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akRight];
    if FCategorias[I].Id = FCategoriaSelecionadaId then
    begin R.Fill.Color := $FF2B2351; R.Stroke.Color := $FF8C63FF; end
    else begin R.Fill.Color := $FF18283C; R.Stroke.Kind := TBrushKind.None; end;
    R.XRadius := 5; R.YRadius := 5; R.Tag := I; R.OnClick := CategoriaClick;
    L := CriarRotulo(R, FCategorias[I].Nome, 10, 0, 300, 29, $FFF4F7FB, 10);
    L.HitTest := False;
  end;
end;

procedure TfraCombos.CategoriaClick(Sender: TObject);
begin
  if Sender is TRectangle then
  begin FCategoriaSelecionadaId := FCategorias[TRectangle(Sender).Tag].Id;
    PreencherCategoriasEditor; end;
end;

function TfraCombos.ItemEditorPorProduto(const AProdutoId: string): TComboItemAdmin;
var Item: TComboItemAdmin;
begin
  Result := nil;
  for Item in FItensEditor do if SameText(Item.ProdutoId, AProdutoId) then Exit(Item);
end;

procedure TfraCombos.PreencherComposicaoEditor;
var I: Integer; R: TRectangle; L: TLabel; B: TfraSensorButton;
begin
  while FItensConteudo.ChildrenCount > 0 do FItensConteudo.Children[0].Free;
  FItensConteudo.Height := Max(1, FItensEditor.Count * 36);
  for I := 0 to FItensEditor.Count - 1 do
  begin
    R := TRectangle.Create(Self); R.Parent := FItensConteudo;
    R.Position.Point := PointF(2, I * 36 + 1); R.Width := FItensConteudo.Width - 4;
    R.Height := 33; R.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akRight];
    R.Fill.Color := $FF18283C; R.Stroke.Kind := TBrushKind.None;
    R.XRadius := 5; R.YRadius := 5;
    L := CriarRotulo(R, Format('%dx  %s', [FItensEditor[I].Quantidade,
      FItensEditor[I].ProdutoNome]), 10, 0, 310, 33, $FFF4F7FB, 10);
    L.HitTest := False;
    B := CriarBotao(R, '', 34, RemoverItemClick); B.Align := TAlignLayout.Right;
    B.Margins.Rect := RectF(2, 2, 2, 2); B.Icone := sbiCancelar; B.Tag := I;
    ConfigurarBotaoIcone(B, 'Remover produto do combo');
    B.Width := 34; B.Height := 29;
    B.pthIcone.Position.Point := PointF((B.Width - B.pthIcone.Width) / 2,
      (B.Height - B.pthIcone.Height) / 2);
  end;
end;

procedure TfraCombos.PreencherProdutosEditor;
var I: Integer; R: TRectangle; L, D: TLabel; Item: TComboItemAdmin;
begin
  while FProdutosConteudo.ChildrenCount > 0 do FProdutosConteudo.Children[0].Free;
  FProdutosConteudo.Height := Max(1, FProdutos.Count * 44);
  for I := 0 to FProdutos.Count - 1 do
  begin
    Item := ItemEditorPorProduto(FProdutos[I].Id);
    R := TRectangle.Create(Self); R.Parent := FProdutosConteudo;
    R.Position.Point := PointF(2, I * 44 + 1); R.Width := FProdutosConteudo.Width - 4;
    R.Height := 41; R.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akRight];
    if Assigned(Item) then begin R.Fill.Color := $FF2B2351; R.Stroke.Color := $FF8C63FF; end
    else begin R.Fill.Color := $FF18283C; R.Stroke.Kind := TBrushKind.None; end;
    R.XRadius := 5; R.YRadius := 5; R.Tag := I; R.OnClick := ProdutoOpcaoClick;
    L := CriarRotulo(R, FProdutos[I].Nome, 10, 2, 260, 20, $FFF4F7FB, 10);
    L.HitTest := False;
    D := CriarRotulo(R, FProdutos[I].CategoriaNome + '  •  ' +
      FormatCurr('R$ #,##0.00', FProdutos[I].Preco), 10, 20, 300, 18, $FF8795A8, 8);
    D.HitTest := False;
    if Assigned(Item) then
    begin
      D := CriarRotulo(R, 'x' + IntToStr(Item.Quantidade), 330, 0, 48, 41,
        $FF45D483, 10); D.TextSettings.HorzAlign := TTextAlign.Trailing;
      D.HitTest := False;
    end;
  end;
end;

procedure TfraCombos.ProdutoOpcaoClick(Sender: TObject);
var P: TProdutoComboOpcao; Item: TComboItemAdmin;
begin
  if not (Sender is TRectangle) then Exit;
  P := FProdutos[TRectangle(Sender).Tag]; Item := ItemEditorPorProduto(P.Id);
  if Assigned(Item) then Inc(Item.Quantidade)
  else
  begin
    Item := TComboItemAdmin.Create; Item.ProdutoId := P.Id;
    Item.ProdutoNome := P.Nome; Item.Quantidade := 1;
    Item.Ordem := FItensEditor.Count; FItensEditor.Add(Item);
  end;
  PreencherComposicaoEditor; PreencherProdutosEditor;
end;

procedure TfraCombos.RemoverItemClick(Sender: TObject);
begin
  if Sender is TfraSensorButton then
  begin FItensEditor.Delete(TfraSensorButton(Sender).Tag);
    PreencherComposicaoEditor; PreencherProdutosEditor; end;
end;

procedure TfraCombos.NovoClick(Sender: TObject); begin AbrirEditor(nil); end;
procedure TfraCombos.EditarClick(Sender: TObject);
begin
  if Sender is TfraSensorButton then FSelecionado := TfraSensorButton(Sender).Tag;
  AbrirEditor(ComboSelecionado);
end;

procedure TfraCombos.AbrirEditor(const ACombo: TComboAdmin);
var Origem, Copia: TComboItemAdmin;
begin
  FItensEditor.Clear;
  if Assigned(ACombo) then
  begin
    FEditandoId := ACombo.Id; FTituloEdicao.Text := 'Editar combo';
    FNome.Text := ACombo.Nome; FCategoriaSelecionadaId := ACombo.CategoriaId;
    FPreco.Text := FormatCurr('0.00', ACombo.Preco);
    if ACombo.TemPrecoPromocional then
      FPrecoPromocional.Text := FormatCurr('0.00', ACombo.PrecoPromocional)
    else FPrecoPromocional.Text := '';
    FCodigo.Text := ACombo.CodigoInterno; FOrdem.Text := IntToStr(ACombo.Ordem);
    FDescricao.Text := ACombo.Descricao; FDisponivel := ACombo.Disponivel;
    FDestaque := ACombo.Destaque;
    for Origem in ACombo.Itens do
    begin
      Copia := TComboItemAdmin.Create; Copia.ProdutoId := Origem.ProdutoId;
      Copia.ProdutoNome := Origem.ProdutoNome; Copia.Quantidade := Origem.Quantidade;
      Copia.Ordem := Origem.Ordem; FItensEditor.Add(Copia);
    end;
  end
  else
  begin
    FEditandoId := ''; FTituloEdicao.Text := 'Novo combo'; FNome.Text := '';
    if FCategorias.Count > 0 then FCategoriaSelecionadaId := FCategorias[0].Id
    else FCategoriaSelecionadaId := '';
    FPreco.Text := '0,00'; FPrecoPromocional.Text := ''; FCodigo.Text := '';
    FOrdem.Text := IntToStr(FCombos.Count + 1); FDescricao.Text := '';
    FDisponivel := True; FDestaque := False;
  end;
  PreencherCategoriasEditor; PreencherComposicaoEditor;
  PreencherProdutosEditor; AtualizarOpcoesEditor;
  FPainelEdicao.Visible := True; FPainelEdicao.BringToFront; FNome.SetFocus;
end;

procedure TfraCombos.FecharEditor;
begin FPainelEdicao.Visible := False; FEditandoId := ''; end;
procedure TfraCombos.CancelarClick(Sender: TObject); begin FecharEditor; end;

procedure TfraCombos.AtualizarOpcoesEditor;
begin
  if FDisponivel then begin FBtnDisponivel.Texto := 'Disponível';
    FBtnDisponivel.Icone := sbiAtivar; FBtnDisponivel.Estilo := sbsPrimary; end
  else begin FBtnDisponivel.Texto := 'Indisponível';
    FBtnDisponivel.Icone := sbiCancelar; FBtnDisponivel.Estilo := sbsSecondary; end;
  if FDestaque then begin FBtnDestaque.Texto := 'Destaque';
    FBtnDestaque.Estilo := sbsPrimary; end
  else begin FBtnDestaque.Texto := 'Sem destaque';
    FBtnDestaque.Estilo := sbsSecondary; end;
end;

procedure TfraCombos.DisponivelEditorClick(Sender: TObject);
begin FDisponivel := not FDisponivel; AtualizarOpcoesEditor; end;
procedure TfraCombos.DestaqueClick(Sender: TObject);
begin FDestaque := not FDestaque; AtualizarOpcoesEditor; end;

function TfraCombos.TextoParaValor(const ATexto: string;
  out AValor: Currency): Boolean;
begin
  Result := TryStrToCurr(ATexto.Trim, AValor);
  if not Result then Result := TryStrToCurr(ATexto.Trim, AValor,
    TFormatSettings.Invariant);
end;

procedure TfraCombos.SalvarClick(Sender: TObject);
var
  Preco, Promo: Currency; Ordem, I: Integer; H: TNetHTTPClient;
  J, JItem: TJSONObject; A: TJSONArray; S: TStringStream; R: IHTTPResponse;
begin
  if FNome.Text.Trim.IsEmpty then
  begin TfrmMensagem.Exibir('Campo obrigatório', 'Informe o nome do combo.', tmAtencao); Exit; end;
  if FCategoriaSelecionadaId.IsEmpty then
  begin TfrmMensagem.Exibir('Campo obrigatório', 'Selecione a categoria.', tmAtencao); Exit; end;
  if not TextoParaValor(FPreco.Text, Preco) or (Preco < 0) then
  begin TfrmMensagem.Exibir('Preço inválido', 'Informe um preço válido.', tmAtencao); Exit; end;
  if not FPrecoPromocional.Text.Trim.IsEmpty then
    if not TextoParaValor(FPrecoPromocional.Text, Promo) or (Promo < 0) then
    begin TfrmMensagem.Exibir('Preço inválido', 'Informe um preço promocional válido.', tmAtencao); Exit; end;
  if not TryStrToInt(FOrdem.Text.Trim, Ordem) or (Ordem < 0) then
  begin TfrmMensagem.Exibir('Ordem inválida', 'Informe uma ordem válida.', tmAtencao); Exit; end;
  if FItensEditor.Count = 0 then
  begin TfrmMensagem.Exibir('Composição obrigatória',
    'Adicione pelo menos um produto ao combo.', tmAtencao); Exit; end;
  J := TJSONObject.Create;
  if FEditandoId.IsEmpty then J.AddPair('empresaId', TSessaoAdmin.EmpresaId);
  J.AddPair('categoriaId', FCategoriaSelecionadaId);
  J.AddPair('nome', FNome.Text.Trim); J.AddPair('descricao', FDescricao.Text.Trim);
  J.AddPair('preco', TJSONNumber.Create(Double(Preco)));
  if FPrecoPromocional.Text.Trim.IsEmpty then J.AddPair('precoPromocional', TJSONNull.Create)
  else J.AddPair('precoPromocional', TJSONNumber.Create(Double(Promo)));
  J.AddPair('codigoInterno', FCodigo.Text.Trim);
  J.AddPair('ordem', TJSONNumber.Create(Ordem));
  J.AddPair('disponivel', TJSONBool.Create(FDisponivel));
  J.AddPair('destaque', TJSONBool.Create(FDestaque));
  A := TJSONArray.Create;
  for I := 0 to FItensEditor.Count - 1 do
  begin
    JItem := TJSONObject.Create; JItem.AddPair('produtoId', FItensEditor[I].ProdutoId);
    JItem.AddPair('quantidade', TJSONNumber.Create(FItensEditor[I].Quantidade));
    JItem.AddPair('ordem', TJSONNumber.Create(I)); A.AddElement(JItem);
  end;
  J.AddPair('itens', A); H := TNetHTTPClient.Create(nil); TSessaoAdmin.ConfigurarCliente(H);
  S := TStringStream.Create(J.ToJSON, TEncoding.UTF8);
  try
    try
      H.ContentType := 'application/json'; H.Accept := 'application/json';
      if FEditandoId.IsEmpty then R := H.Post(URL_COMBOS, S)
      else R := H.Put(URL_COMBOS + '/' + FEditandoId, S);
      if not (R.StatusCode in [200, 201]) then
      begin ExibirErroAPI('Não foi possível salvar o combo', R); Exit; end;
      FecharEditor; CarregarCombos;
      TfrmMensagem.Exibir('Combo salvo', 'Os dados foram salvos com sucesso.', tmSucesso);
    except on E: Exception do TfrmMensagem.Exibir('Erro de comunicação', E.Message, tmErro); end;
  finally S.Free; H.Free; J.Free; end;
end;

procedure TfraCombos.DisponibilidadeClick(Sender: TObject);
var C: TComboAdmin; H: TNetHTTPClient; J: TJSONObject;
  S: TStringStream; R: IHTTPResponse;
begin
  if Sender is TfraSensorButton then FSelecionado := TfraSensorButton(Sender).Tag;
  C := ComboSelecionado; if not Assigned(C) then Exit;
  J := TJSONObject.Create; J.AddPair('disponivel', TJSONBool.Create(not C.Disponivel));
  H := TNetHTTPClient.Create(nil); TSessaoAdmin.ConfigurarCliente(H); S := TStringStream.Create(J.ToJSON, TEncoding.UTF8);
  try
    H.ContentType := 'application/json'; R := H.Patch(URL_COMBOS + '/' + C.Id + '/situacao', S);
    if R.StatusCode <> 200 then ExibirErroAPI('Não foi possível alterar o combo', R)
    else CarregarCombos;
  finally S.Free; H.Free; J.Free; end;
end;

procedure TfraCombos.AtivoClick(Sender: TObject);
var C: TComboAdmin; H: TNetHTTPClient; J: TJSONObject;
  S: TStringStream; R: IHTTPResponse;
begin
  if Sender is TfraSensorButton then FSelecionado := TfraSensorButton(Sender).Tag;
  C := ComboSelecionado; if not Assigned(C) then Exit;
  J := TJSONObject.Create; J.AddPair('ativo', TJSONBool.Create(not C.Ativo));
  H := TNetHTTPClient.Create(nil); TSessaoAdmin.ConfigurarCliente(H); S := TStringStream.Create(J.ToJSON, TEncoding.UTF8);
  try
    H.ContentType := 'application/json'; R := H.Patch(URL_COMBOS + '/' + C.Id + '/situacao', S);
    if R.StatusCode <> 200 then ExibirErroAPI('Não foi possível alterar o combo', R)
    else CarregarCombos;
  finally S.Free; H.Free; J.Free; end;
end;

procedure TfraCombos.BuscarClick(Sender: TObject);
begin FTimerBusca.Enabled := False; CarregarCombos; end;
procedure TfraCombos.BuscaChange(Sender: TObject);
begin FTimerBusca.Enabled := False; FTimerBusca.Enabled := True; end;
procedure TfraCombos.TimerBuscaTimer(Sender: TObject);
begin FTimerBusca.Enabled := False; CarregarCombos; end;
procedure TfraCombos.BuscaKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then begin Key := 0; KeyChar := #0;
    FTimerBusca.Enabled := False; CarregarCombos; end;
end;

procedure TfraCombos.MemoApplyStyleLookup(Sender: TObject);
var Fundo: TControl;
begin
  if FDescricao.FindStyleResource<TControl>('background', Fundo) then
  begin Fundo.Opacity := 0; Fundo.HitTest := False; end;
end;

procedure TfraCombos.ExibirErroAPI(const ATitulo: string;
  const AResposta: IHTTPResponse);
var V: TJSONValue; M: string;
begin
  M := 'A API retornou o código ' + IntToStr(AResposta.StatusCode) + '.';
  V := TJSONObject.ParseJSONValue(AResposta.ContentAsString(TEncoding.UTF8));
  try if V is TJSONObject then M := TJSONObject(V).GetValue<string>('erro', M);
  finally V.Free; end;
  TfrmMensagem.Exibir(ATitulo, M, tmErro);
end;

end.
