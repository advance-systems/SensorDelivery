unit uFrameCardapio;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.JSON, System.Net.URLClient, System.Net.HttpClient,
  System.Net.HttpClientComponent, System.NetEncoding,
  System.Generics.Collections,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs,
  FMX.StdCtrls, FMX.Objects, FMX.Layouts, FMX.Controls.Presentation,
  FMX.Edit, FMX.Memo, uFrameSensorButton;

type
  TCategoriaFiltroStatus = (cafsTodas, cafsAtivas, cafsInativas);

  TCategoriaAdmin = class
  public
    Id, Nome, Descricao, ImagemUrl: string;
    Ordem, QuantidadeProdutos: Integer;
    Ativo: Boolean;
  end;

  TfraCardapio = class(TFrame)
    rctFundo: TRectangle;
    lytPrincipal: TLayout;
    lytCabecalho: TLayout;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    lytConteudo: TLayout;
  private
    FCategorias: TObjectList<TCategoriaAdmin>;
    FCarregado: Boolean;
    FEditandoId: string;
    FSelecionado: Integer;
    FFiltroStatus: TCategoriaFiltroStatus;
    FBarra, FFiltros, FListaConteudo: TLayout;
    FBusca, FNome, FOrdem, FImagemUrl: TEdit;
    FDescricao: TMemo;
    FLista: TVertScrollBox;
    FEstado, FTituloEdicao: TLabel;
    FPainelEdicao: TRectangle;
    FTimerBusca: TTimer;
    FBtnNovo, FBtnBuscar, FBtnSalvar, FBtnCancelar, FBtnImagem: TfraSensorButton;
    FBtnTodas, FBtnAtivas, FBtnInativas: TfraSensorButton;
    procedure MontarTela;
    function CriarRotulo(const AParent: TFmxObject; const ATexto: string;
      const AX, AY, AWidth, AHeight: Single; const ACor: TAlphaColor;
      const ATamanho: Single): TLabel;
    function CriarBotao(const AParent: TFmxObject; const ATexto: string;
      const AWidth: Single; const AOnClick: TNotifyEvent): TfraSensorButton;
    procedure ConfigurarBotaoSomenteIcone(const ABotao: TfraSensorButton;
      const AHint: string);
    function CriarFundoCampo(const AParent: TFmxObject; const AX, AY,
      AWidth, AHeight: Single): TRectangle;
    function CategoriaSelecionada: TCategoriaAdmin;
    function CategoriaVisivel(const ACategoria: TCategoriaAdmin): Boolean;
    procedure PreencherLista;
    procedure AtualizarFiltros;
    procedure AbrirEditor(const ACategoria: TCategoriaAdmin);
    procedure FecharEditor;
    function MontarJSONCategoria: TJSONObject;
    procedure ExibirErroAPI(const ATitulo: string;
      const AResposta: IHTTPResponse);
    procedure NovoClick(Sender: TObject);
    procedure EditarClick(Sender: TObject);
    procedure AtivoClick(Sender: TObject);
    procedure SalvarClick(Sender: TObject);
    procedure CancelarClick(Sender: TObject);
    procedure BuscarClick(Sender: TObject);
    procedure BuscaChange(Sender: TObject);
    procedure BuscaKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure TimerBuscaTimer(Sender: TObject);
    procedure FiltroClick(Sender: TObject);
    procedure CategoriaClick(Sender: TObject);
    procedure MemoApplyStyleLookup(Sender: TObject);
    procedure SelecionarImagemClick(Sender: TObject);
    procedure ExibirImagemUrl(const AUrl: string);
    function ImagemUrlAtual: string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure PrepararTela;
    procedure CarregarCategorias;
  end;

implementation

{$R *.fmx}

uses uMensagem, uImagemUpload, uSessaoAdmin, uNavegacaoCampos, uApiConfig;

function URL_CATEGORIAS: string;
begin
  Result := TApiConfig.Url('/api/categorias');
end;

constructor TfraCardapio.Create(AOwner: TComponent);
begin
  inherited;
  FCategorias := TObjectList<TCategoriaAdmin>.Create(True);
  FCarregado := False;
  FEditandoId := '';
  FSelecionado := -1;
  FFiltroStatus := cafsTodas;
  MontarTela;
end;

destructor TfraCardapio.Destroy;
begin
  FCategorias.Free;
  inherited;
end;

function TfraCardapio.CriarRotulo(const AParent: TFmxObject;
  const ATexto: string; const AX, AY, AWidth, AHeight: Single;
  const ACor: TAlphaColor; const ATamanho: Single): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := AParent;
  Result.Position.Point := PointF(AX, AY);
  Result.Width := AWidth;
  Result.Height := AHeight;
  Result.Text := ATexto;
  Result.StyledSettings := [];
  Result.TextSettings.Font.Family := 'Manrope';
  Result.TextSettings.Font.Size := ATamanho;
  Result.TextSettings.FontColor := ACor;
end;

function TfraCardapio.CriarBotao(const AParent: TFmxObject;
  const ATexto: string; const AWidth: Single;
  const AOnClick: TNotifyEvent): TfraSensorButton;
begin
  Result := TfraSensorButton.Create(Self);
  Result.Name := '';
  Result.Parent := AParent;
  Result.Align := TAlignLayout.Left;
  Result.Width := AWidth;
  Result.Margins.Right := 8;
  Result.Texto := ATexto;
  Result.Estilo := sbsSecondary;
  Result.OnButtonClick := AOnClick;
  Result.pthIcone.Margins.Left := 10;
  Result.pthIcone.Margins.Right := 6;
  Result.lblTexto.Margins.Right := 10;
end;

procedure TfraCardapio.ConfigurarBotaoSomenteIcone(
  const ABotao: TfraSensorButton; const AHint: string);
begin
  ABotao.Width := 38;
  ABotao.Height := 34;
  ABotao.Texto := '';
  ABotao.lblTexto.Visible := False;
  ABotao.pthIcone.Align := TAlignLayout.None;
  ABotao.pthIcone.Margins.Left := 0;
  ABotao.pthIcone.Margins.Top := 0;
  ABotao.pthIcone.Margins.Right := 0;
  ABotao.pthIcone.Margins.Bottom := 0;
  ABotao.pthIcone.Position.Point := PointF(
    (ABotao.Width - ABotao.pthIcone.Width) / 2,
    (ABotao.Height - ABotao.pthIcone.Height) / 2);
  ABotao.Hint := AHint;
  ABotao.ShowHint := True;
  ABotao.rctFundo.Hint := AHint;
  ABotao.rctFundo.ShowHint := True;
end;

function TfraCardapio.CriarFundoCampo(const AParent: TFmxObject;
  const AX, AY, AWidth, AHeight: Single): TRectangle;
begin
  Result := TRectangle.Create(Self);
  Result.Parent := AParent;
  Result.Position.Point := PointF(AX, AY);
  Result.Width := AWidth;
  Result.Height := AHeight;
  Result.Fill.Color := $FF152439;
  Result.Stroke.Color := $FF2A405B;
  Result.XRadius := 6;
  Result.YRadius := 6;
end;

procedure TfraCardapio.MontarTela;
var
  LBuscaFundo, LListaFundo, LCampo: TRectangle;
  LForm: TLayout;
begin
  lblTitulo.Text := 'Categorias';
  lblSubtitulo.Text := 'Organize as categorias exibidas no cardápio.';

  FBarra := TLayout.Create(Self);
  FBarra.Parent := lytConteudo;
  FBarra.Align := TAlignLayout.Top;
  FBarra.Height := 44;
  FBarra.Margins.Bottom := 12;
  FBtnNovo := CriarBotao(FBarra, '+ Nova categoria', 142, NovoClick);
  FBtnNovo.Align := TAlignLayout.Right;
  FBtnNovo.Estilo := sbsPrimary;
  FBtnNovo.Icone := sbiPizza;
  FBtnBuscar := CriarBotao(FBarra, 'Buscar', 96, BuscarClick);
  FBtnBuscar.Align := TAlignLayout.Right;
  FBtnBuscar.Icone := sbiPesquisar;
  LBuscaFundo := CriarFundoCampo(FBarra, 0, 0, 100, 44);
  LBuscaFundo.Align := TAlignLayout.Client;
  LBuscaFundo.Margins.Right := 12;
  LBuscaFundo.XRadius := 8; LBuscaFundo.YRadius := 8;
  FBusca := TEdit.Create(Self);
  FBusca.Parent := LBuscaFundo;
  FBusca.Align := TAlignLayout.Client;
  FBusca.Margins.Left := 12; FBusca.Margins.Right := 12;
  FBusca.StyleLookup := 'transparentedit';
  FBusca.TextPrompt := 'Buscar categoria por nome ou descrição';
  FBusca.StyledSettings := [];
  FBusca.TextSettings.Font.Family := 'Manrope';
  FBusca.TextSettings.FontColor := $FFF4F7FB;
  FBusca.OnTyping := BuscaChange;
  FBusca.OnChangeTracking := BuscaChange;
  FBusca.OnKeyDown := BuscaKeyDown;
  FTimerBusca := TTimer.Create(Self);
  FTimerBusca.Interval := 400;
  FTimerBusca.Enabled := False;
  FTimerBusca.OnTimer := TimerBuscaTimer;

  FFiltros := TLayout.Create(Self);
  FFiltros.Parent := lytConteudo;
  FFiltros.Align := TAlignLayout.Top;
  FFiltros.Height := 42;
  FFiltros.Margins.Bottom := 10;
  CriarRotulo(FFiltros, 'Filtrar por status:', 2, 0, 112, 42,
    $FF8795A8, 10);
  FBtnTodas := CriarBotao(FFiltros, 'Todas', 94, FiltroClick);
  FBtnTodas.Align := TAlignLayout.None;
  FBtnTodas.Position.Point := PointF(118, 2);
  FBtnTodas.Height := 36; FBtnTodas.Icone := sbiRelatorio;
  FBtnTodas.Tag := Ord(cafsTodas);
  FBtnAtivas := CriarBotao(FFiltros, 'Ativas', 98, FiltroClick);
  FBtnAtivas.Align := TAlignLayout.None;
  FBtnAtivas.Position.Point := PointF(220, 2);
  FBtnAtivas.Height := 36; FBtnAtivas.Icone := sbiAtivar;
  FBtnAtivas.Tag := Ord(cafsAtivas);
  FBtnInativas := CriarBotao(FFiltros, 'Inativas', 108, FiltroClick);
  FBtnInativas.Align := TAlignLayout.None;
  FBtnInativas.Position.Point := PointF(326, 2);
  FBtnInativas.Height := 36; FBtnInativas.Icone := sbiCancelar;
  FBtnInativas.Tag := Ord(cafsInativas);
  AtualizarFiltros;

  FPainelEdicao := TRectangle.Create(Self);
  FPainelEdicao.Parent := lytConteudo;
  FPainelEdicao.Align := TAlignLayout.Right;
  FPainelEdicao.Width := 350;
  FPainelEdicao.Margins.Left := 14;
  FPainelEdicao.Fill.Color := $FF111E2E;
  FPainelEdicao.Stroke.Color := $FF2A405B;
  FPainelEdicao.XRadius := 10; FPainelEdicao.YRadius := 10;
  FPainelEdicao.Visible := False;
  FTituloEdicao := CriarRotulo(FPainelEdicao, 'Nova categoria', 20, 16,
    310, 30, $FFF4F7FB, 16);
  FTituloEdicao.TextSettings.Font.Style := [TFontStyle.fsBold];
  LForm := TLayout.Create(Self);
  LForm.Parent := FPainelEdicao;
  LForm.Align := TAlignLayout.Client;

  CriarRotulo(LForm, 'Nome *', 20, 58, 310, 20, $FF9CAABC, 10);
  LCampo := CriarFundoCampo(LForm, 20, 80, 310, 38);
  FNome := TEdit.Create(Self);
  FNome.Parent := LCampo; FNome.Align := TAlignLayout.Client;
  FNome.Margins.Left := 10; FNome.Margins.Right := 10;
  FNome.StyleLookup := 'transparentedit'; FNome.StyledSettings := [];
  FNome.TextSettings.FontColor := $FFF4F7FB;
  FNome.TextPrompt := 'Ex.: Pizzas';

  CriarRotulo(LForm, 'Ordem de exibição', 20, 128, 310, 20, $FF9CAABC, 10);
  LCampo := CriarFundoCampo(LForm, 20, 150, 310, 38);
  FOrdem := TEdit.Create(Self);
  FOrdem.Parent := LCampo; FOrdem.Align := TAlignLayout.Client;
  FOrdem.Margins.Left := 10; FOrdem.Margins.Right := 10;
  FOrdem.StyleLookup := 'transparentedit'; FOrdem.StyledSettings := [];
  FOrdem.TextSettings.FontColor := $FFF4F7FB;
  FOrdem.KeyboardType := TVirtualKeyboardType.NumberPad;

  CriarRotulo(LForm, 'Imagem', 20, 198, 310, 20, $FF9CAABC, 10);
  LCampo := CriarFundoCampo(LForm, 20, 220, 310, 38);
  FImagemUrl := TEdit.Create(Self);
  FImagemUrl.Parent := LCampo; FImagemUrl.Align := TAlignLayout.Client;
  FImagemUrl.Margins.Left := 10; FImagemUrl.Margins.Right := 10;
  FImagemUrl.StyleLookup := 'transparentedit'; FImagemUrl.StyledSettings := [];
  FImagemUrl.TextSettings.FontColor := $FFF4F7FB;
  FImagemUrl.TextPrompt := 'Selecione uma imagem do computador';
  FImagemUrl.ReadOnly := True; FImagemUrl.Margins.Right := 46;
  FImagemUrl.ShowHint := True;
  FBtnImagem := CriarBotao(LCampo, '', 38, SelecionarImagemClick);
  FBtnImagem.Align := TAlignLayout.Right; FBtnImagem.Margins.Right := 2;
  FBtnImagem.Height := 34; FBtnImagem.Icone := sbiPesquisar;
  ConfigurarBotaoSomenteIcone(FBtnImagem, 'Selecionar imagem');

  CriarRotulo(LForm, 'Descrição', 20, 268, 310, 20, $FF9CAABC, 10);
  LCampo := CriarFundoCampo(LForm, 20, 290, 310, 100);
  FDescricao := TMemo.Create(Self);
  FDescricao.Parent := LCampo; FDescricao.Align := TAlignLayout.Client;
  FDescricao.Margins.Left := 8; FDescricao.Margins.Right := 8;
  FDescricao.OnApplyStyleLookup := MemoApplyStyleLookup;
  FDescricao.StyledSettings := [];
  FDescricao.TextSettings.FontColor := $FFF4F7FB;
  FDescricao.WordWrap := True;
  TNavegacaoCampos.Aplicar(Self, [FNome, FOrdem, FDescricao]);
  FBtnSalvar := CriarBotao(LForm, 'Salvar', 112, SalvarClick);
  FBtnSalvar.Icone := sbiSalvar; FBtnSalvar.Align := TAlignLayout.None;
  FBtnSalvar.Position.Point := PointF(218, 410); FBtnSalvar.Height := 40;
  FBtnCancelar := CriarBotao(LForm, 'Cancelar', 98, CancelarClick);
  FBtnCancelar.Icone := sbiCancelar; FBtnCancelar.Align := TAlignLayout.None;
  FBtnCancelar.Position.Point := PointF(20, 410); FBtnCancelar.Height := 40;

  LListaFundo := TRectangle.Create(Self);
  LListaFundo.Parent := lytConteudo;
  LListaFundo.Align := TAlignLayout.Client;
  LListaFundo.Fill.Color := $FF111E2E;
  LListaFundo.Stroke.Color := $FF23364D;
  LListaFundo.XRadius := 10; LListaFundo.YRadius := 10;
  FEstado := CriarRotulo(LListaFundo, 'Carregando categorias...', 20, 16,
    500, 24, $FF8795A8, 11);
  FLista := TVertScrollBox.Create(Self);
  FLista.Parent := LListaFundo;
  FLista.Align := TAlignLayout.Client;
  FLista.Margins.Top := 48; FLista.Margins.Left := 8;
  FLista.Margins.Right := 8; FLista.Margins.Bottom := 8;
  FLista.ShowScrollBars := True;
  FListaConteudo := TLayout.Create(Self);
  FListaConteudo.Parent := FLista;
  FListaConteudo.Align := TAlignLayout.Top;
  FListaConteudo.Height := 1;
end;

procedure TfraCardapio.PrepararTela;
begin
  if not FCarregado then CarregarCategorias;
end;

procedure TfraCardapio.CarregarCategorias;
var
  LHTTP: TNetHTTPClient;
  LResposta: IHTTPResponse;
  LValor, LItem: TJSONValue;
  LArray: TJSONArray;
  LJSON: TJSONObject;
  LCategoria: TCategoriaAdmin;
  LURL: string;
begin
  FEstado.Text := 'Carregando categorias...';
  FLista.Enabled := False;
  LHTTP := TNetHTTPClient.Create(nil);
  TSessaoAdmin.ConfigurarCliente(LHTTP);
  LValor := nil;
  try
    try
      LHTTP.Accept := 'application/json';
      LURL := URL_CATEGORIAS + '?empresaId=' + TNetEncoding.URL.Encode(TSessaoAdmin.EmpresaId);
      if not FBusca.Text.Trim.IsEmpty then
        LURL := LURL + '&busca=' + TNetEncoding.URL.Encode(FBusca.Text.Trim);
      LResposta := LHTTP.Get(LURL);
      if LResposta.StatusCode <> 200 then
      begin
        ExibirErroAPI('Erro ao carregar categorias', LResposta);
        FEstado.Text := 'Não foi possível carregar as categorias.';
        Exit;
      end;
      LValor := TJSONObject.ParseJSONValue(LResposta.ContentAsString(TEncoding.UTF8));
      if not (LValor is TJSONObject) then
        raise Exception.Create('Resposta inválida recebida da API.');
      LArray := TJSONObject(LValor).GetValue<TJSONArray>('categorias');
      FCategorias.Clear;
      for LItem in LArray do
      begin
        LJSON := LItem as TJSONObject;
        LCategoria := TCategoriaAdmin.Create;
        LCategoria.Id := LJSON.GetValue<string>('id', '');
        LCategoria.Nome := LJSON.GetValue<string>('nome', '');
        LCategoria.Descricao := LJSON.GetValue<string>('descricao', '');
        LCategoria.ImagemUrl := LJSON.GetValue<string>('imagem_url', '');
        LCategoria.Ordem := LJSON.GetValue<Integer>('ordem', 0);
        LCategoria.QuantidadeProdutos :=
          LJSON.GetValue<Integer>('quantidade_produtos', 0);
        LCategoria.Ativo := LJSON.GetValue<Boolean>('ativo', True);
        FCategorias.Add(LCategoria);
      end;
      FCarregado := True;
      PreencherLista;
    except
      on E: Exception do
      begin
        FEstado.Text := 'API indisponível. Tente novamente.';
        TfrmMensagem.Exibir('Erro de comunicação', E.Message, tmErro);
      end;
    end;
  finally
    LValor.Free; LHTTP.Free; FLista.Enabled := True;
  end;
end;

function TfraCardapio.CategoriaVisivel(
  const ACategoria: TCategoriaAdmin): Boolean;
begin
  case FFiltroStatus of
    cafsAtivas: Result := ACategoria.Ativo;
    cafsInativas: Result := not ACategoria.Ativo;
  else
    Result := True;
  end;
end;

procedure TfraCardapio.PreencherLista;
var
  LCategoria: TCategoriaAdmin;
  LCard: TRectangle;
  LTexto, LAcoes: TLayout;
  LNome, LDetalhe, LStatus: TLabel;
  LEditar, LAtivo: TfraSensorButton;
  LResumo, LStatusTexto: string;
  I, LPosicao, LExibidas: Integer;
begin
  while FListaConteudo.ChildrenCount > 0 do
    FListaConteudo.Children[0].Free;
  FSelecionado := -1;
  LExibidas := 0;
  for LCategoria in FCategorias do
    if CategoriaVisivel(LCategoria) then Inc(LExibidas);
  FListaConteudo.Height := LExibidas * 66;
  LPosicao := 0;
  for I := 0 to FCategorias.Count - 1 do
  begin
    LCategoria := FCategorias[I];
    if not CategoriaVisivel(LCategoria) then Continue;
    if LCategoria.Ativo then LStatusTexto := 'ATIVA' else LStatusTexto := 'INATIVA';
    LResumo := LCategoria.Descricao;
    if LResumo.IsEmpty then LResumo := 'Sem descrição';
    LResumo := LResumo + Format('  •  %d produto(s)  •  Ordem %d',
      [LCategoria.QuantidadeProdutos, LCategoria.Ordem]);

    LCard := TRectangle.Create(Self);
    LCard.Parent := FListaConteudo;
    LCard.Position.Point := PointF(4, LPosicao * 66 + 2);
    LCard.Width := FListaConteudo.Width - 8;
    LCard.Height := 60;
    LCard.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akRight];
    LCard.Fill.Color := $FF152439; LCard.Stroke.Color := $FF23364D;
    LCard.XRadius := 7; LCard.YRadius := 7;
    LCard.Tag := I; LCard.OnClick := CategoriaClick;

    LAcoes := TLayout.Create(Self);
    LAcoes.Parent := LCard; LAcoes.Align := TAlignLayout.Right;
    LAcoes.Width := 164;
    LEditar := CriarBotao(LAcoes, '', 38, EditarClick);
    LEditar.Align := TAlignLayout.None;
    LEditar.Position.Point := PointF(0, 13);
    LEditar.Icone := sbiEditar; LEditar.Tag := I;
    ConfigurarBotaoSomenteIcone(LEditar, 'Editar categoria');
    LAtivo := CriarBotao(LAcoes, '', 38, AtivoClick);
    LAtivo.Align := TAlignLayout.None;
    LAtivo.Position.Point := PointF(46, 13); LAtivo.Tag := I;
    if LCategoria.Ativo then
    begin
      LAtivo.Icone := sbiCancelar;
      ConfigurarBotaoSomenteIcone(LAtivo, 'Desativar categoria');
    end
    else
    begin
      LAtivo.Icone := sbiAtivar;
      ConfigurarBotaoSomenteIcone(LAtivo, 'Ativar categoria');
    end;
    LStatus := CriarRotulo(LAcoes, LStatusTexto, 92, 0, 60, 60,
      $FF45D483, 9);
    LStatus.TextSettings.HorzAlign := TTextAlign.Trailing;
    LStatus.HitTest := False;
    if not LCategoria.Ativo then
      LStatus.TextSettings.FontColor := $FFFFB454;

    LTexto := TLayout.Create(Self);
    LTexto.Parent := LCard; LTexto.Align := TAlignLayout.Client;
    LTexto.Margins.Left := 14; LTexto.Margins.Right := 12;
    LTexto.HitTest := False;
    LNome := CriarRotulo(LTexto, LCategoria.Nome, 0, 5, 600, 24,
      $FFF4F7FB, 11);
    LNome.Align := TAlignLayout.Top; LNome.HitTest := False;
    LNome.TextSettings.Font.Style := [TFontStyle.fsBold];
    LDetalhe := CriarRotulo(LTexto, LResumo, 0, 30, 800, 22,
      $FF8795A8, 9);
    LDetalhe.Align := TAlignLayout.Bottom;
    LDetalhe.Margins.Bottom := 5; LDetalhe.HitTest := False;
    Inc(LPosicao);
  end;
  if LExibidas = 0 then FEstado.Text := 'Nenhuma categoria encontrada neste filtro.'
  else if LExibidas = FCategorias.Count then
    FEstado.Text := Format('%d categoria(s) encontrada(s)', [LExibidas])
  else
    FEstado.Text := Format('%d de %d categoria(s)', [LExibidas, FCategorias.Count]);
end;

procedure TfraCardapio.AtualizarFiltros;
begin
  FBtnTodas.Estilo := sbsSecondary;
  FBtnAtivas.Estilo := sbsSecondary;
  FBtnInativas.Estilo := sbsSecondary;
  case FFiltroStatus of
    cafsTodas: FBtnTodas.Estilo := sbsPrimary;
    cafsAtivas: FBtnAtivas.Estilo := sbsPrimary;
    cafsInativas: FBtnInativas.Estilo := sbsPrimary;
  end;
end;

procedure TfraCardapio.FiltroClick(Sender: TObject);
begin
  if not (Sender is TfraSensorButton) then Exit;
  FFiltroStatus := TCategoriaFiltroStatus(TfraSensorButton(Sender).Tag);
  AtualizarFiltros;
  PreencherLista;
end;

function TfraCardapio.CategoriaSelecionada: TCategoriaAdmin;
begin
  Result := nil;
  if (FSelecionado >= 0) and (FSelecionado < FCategorias.Count) then
    Result := FCategorias[FSelecionado];
end;

procedure TfraCardapio.CategoriaClick(Sender: TObject);
var
  I: Integer;
  LCard: TRectangle;
begin
  if not (Sender is TRectangle) then Exit;
  FSelecionado := TRectangle(Sender).Tag;
  for I := 0 to FListaConteudo.ChildrenCount - 1 do
    if FListaConteudo.Children[I] is TRectangle then
    begin
      LCard := TRectangle(FListaConteudo.Children[I]);
      if LCard.Tag = FSelecionado then
      begin
        LCard.Fill.Color := $FF2B2351;
        LCard.Stroke.Color := $FF8C63FF;
      end
      else
      begin
        LCard.Fill.Color := $FF152439;
        LCard.Stroke.Color := $FF23364D;
      end;
    end;
end;

procedure TfraCardapio.NovoClick(Sender: TObject);
begin
  AbrirEditor(nil);
end;

procedure TfraCardapio.EditarClick(Sender: TObject);
begin
  if Sender is TfraSensorButton then
    FSelecionado := TfraSensorButton(Sender).Tag;
  AbrirEditor(CategoriaSelecionada);
end;

procedure TfraCardapio.AbrirEditor(const ACategoria: TCategoriaAdmin);
begin
  if Assigned(ACategoria) then
  begin
    FEditandoId := ACategoria.Id;
    FTituloEdicao.Text := 'Editar categoria';
    FNome.Text := ACategoria.Nome;
    FOrdem.Text := IntToStr(ACategoria.Ordem);
    ExibirImagemUrl(ACategoria.ImagemUrl);
    FDescricao.Text := ACategoria.Descricao;
  end
  else
  begin
    FEditandoId := '';
    FTituloEdicao.Text := 'Nova categoria';
    FNome.Text := '';
    FOrdem.Text := IntToStr(FCategorias.Count + 1);
    ExibirImagemUrl('');
    FDescricao.Text := '';
  end;
  FPainelEdicao.Visible := True;
  FPainelEdicao.BringToFront;
  FNome.SetFocus;
end;

procedure TfraCardapio.FecharEditor;
begin
  FPainelEdicao.Visible := False;
  FEditandoId := '';
end;

procedure TfraCardapio.CancelarClick(Sender: TObject);
begin
  FecharEditor;
end;

function TfraCardapio.MontarJSONCategoria: TJSONObject;
begin
  Result := TJSONObject.Create;
  if FEditandoId.IsEmpty then Result.AddPair('empresaId', TSessaoAdmin.EmpresaId);
  Result.AddPair('nome', FNome.Text.Trim);
  Result.AddPair('descricao', FDescricao.Text.Trim);
  Result.AddPair('imagemUrl', ImagemUrlAtual);
  Result.AddPair('ordem', TJSONNumber.Create(StrToIntDef(FOrdem.Text.Trim, 0)));
end;

procedure TfraCardapio.SalvarClick(Sender: TObject);
var
  LHTTP: TNetHTTPClient;
  LJSON: TJSONObject;
  LStream: TStringStream;
  LResposta: IHTTPResponse;
  LOrdem: Integer;
begin
  if FNome.Text.Trim.IsEmpty then
  begin
    TfrmMensagem.Exibir('Campo obrigatório', 'Informe o nome da categoria.', tmAtencao);
    FNome.SetFocus; Exit;
  end;
  if not TryStrToInt(FOrdem.Text.Trim, LOrdem) or (LOrdem < 0) then
  begin
    TfrmMensagem.Exibir('Ordem inválida',
      'Informe um número inteiro maior ou igual a zero.', tmAtencao);
    FOrdem.SetFocus; Exit;
  end;
  LHTTP := TNetHTTPClient.Create(nil);
  TSessaoAdmin.ConfigurarCliente(LHTTP);
  LJSON := MontarJSONCategoria;
  LStream := TStringStream.Create(LJSON.ToJSON, TEncoding.UTF8);
  try
    try
      LHTTP.ContentType := 'application/json'; LHTTP.Accept := 'application/json';
      if FEditandoId.IsEmpty then
        LResposta := LHTTP.Post(URL_CATEGORIAS, LStream)
      else
        LResposta := LHTTP.Put(URL_CATEGORIAS + '/' + FEditandoId, LStream);
      if not (LResposta.StatusCode in [200, 201]) then
      begin
        ExibirErroAPI('Não foi possível salvar a categoria', LResposta);
        Exit;
      end;
      FecharEditor;
      CarregarCategorias;
      TfrmMensagem.Exibir('Categoria salva',
        'Os dados foram salvos com sucesso.', tmSucesso);
    except
      on E: Exception do
        TfrmMensagem.Exibir('Erro de comunicação', E.Message, tmErro);
    end;
  finally
    LStream.Free; LJSON.Free; LHTTP.Free;
  end;
end;

procedure TfraCardapio.AtivoClick(Sender: TObject);
var
  LCategoria: TCategoriaAdmin;
  LHTTP: TNetHTTPClient;
  LJSON: TJSONObject;
  LStream: TStringStream;
  LResposta: IHTTPResponse;
begin
  if Sender is TfraSensorButton then
    FSelecionado := TfraSensorButton(Sender).Tag;
  LCategoria := CategoriaSelecionada;
  if not Assigned(LCategoria) then Exit;
  LHTTP := TNetHTTPClient.Create(nil);
  TSessaoAdmin.ConfigurarCliente(LHTTP);
  LJSON := TJSONObject.Create;
  LJSON.AddPair('ativo', TJSONBool.Create(not LCategoria.Ativo));
  LStream := TStringStream.Create(LJSON.ToJSON, TEncoding.UTF8);
  try
    try
      LHTTP.ContentType := 'application/json'; LHTTP.Accept := 'application/json';
      LResposta := LHTTP.Patch(URL_CATEGORIAS + '/' + LCategoria.Id +
        '/situacao', LStream);
      if LResposta.StatusCode <> 200 then
      begin
        ExibirErroAPI('Não foi possível alterar a categoria', LResposta);
        Exit;
      end;
      CarregarCategorias;
    except
      on E: Exception do
        TfrmMensagem.Exibir('Erro de comunicação', E.Message, tmErro);
    end;
  finally
    LStream.Free; LJSON.Free; LHTTP.Free;
  end;
end;

procedure TfraCardapio.BuscarClick(Sender: TObject);
begin
  FTimerBusca.Enabled := False;
  CarregarCategorias;
end;

procedure TfraCardapio.BuscaChange(Sender: TObject);
begin
  FTimerBusca.Enabled := False;
  FTimerBusca.Enabled := True;
end;

procedure TfraCardapio.BuscaKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    Key := 0; KeyChar := #0;
    FTimerBusca.Enabled := False;
    CarregarCategorias;
  end;
end;

procedure TfraCardapio.TimerBuscaTimer(Sender: TObject);
begin
  FTimerBusca.Enabled := False;
  CarregarCategorias;
end;

procedure TfraCardapio.MemoApplyStyleLookup(Sender: TObject);
var
  LFundoMemo: TControl;
begin
  if FDescricao.FindStyleResource<TControl>('background', LFundoMemo) then
  begin
    LFundoMemo.Opacity := 0;
    LFundoMemo.HitTest := False;
  end;
end;

procedure TfraCardapio.SelecionarImagemClick(Sender: TObject);
var LURL: string;
begin
  try
    if TImagemUpload.SelecionarEEnviar(Self, LURL) then ExibirImagemUrl(LURL);
  except on E: Exception do
    TfrmMensagem.Exibir('Erro ao enviar imagem', E.Message, tmErro); end;
end;

procedure TfraCardapio.ExibirImagemUrl(const AUrl: string);
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

function TfraCardapio.ImagemUrlAtual: string;
begin
  Result := FImagemUrl.TagString.Trim;
end;

procedure TfraCardapio.ExibirErroAPI(const ATitulo: string;
  const AResposta: IHTTPResponse);
var
  LValor: TJSONValue;
  LMensagem: string;
begin
  LMensagem := 'A API retornou o código ' + IntToStr(AResposta.StatusCode) + '.';
  LValor := TJSONObject.ParseJSONValue(AResposta.ContentAsString(TEncoding.UTF8));
  try
    if LValor is TJSONObject then
      LMensagem := TJSONObject(LValor).GetValue<string>('erro', LMensagem);
  finally
    LValor.Free;
  end;
  TfrmMensagem.Exibir(ATitulo, LMensagem, tmErro);
end;

end.
