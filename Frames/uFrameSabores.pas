unit uFrameSabores;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.JSON,
  System.Net.URLClient, System.Net.HttpClient, System.Net.HttpClientComponent,
  System.NetEncoding, System.Generics.Collections,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Objects,
  FMX.Layouts, FMX.Controls.Presentation, FMX.Edit, FMX.Memo, FMX.ListBox,
  uFrameSensorButton;

type
  TSaborFiltroStatus = (sfsTodos, sfsAtivos, sfsInativos);

  TSaborAdmin = class
  public
    Id, Nome, Descricao: string;
    CategoriaIds: TList<string>;
    ValorAdicional: Currency;
    Ordem, QuantidadeProdutos: Integer;
    Ativo: Boolean;
    PrecosTamanho: TDictionary<string, Currency>;
    constructor Create;
    destructor Destroy; override;
  end;

  TTamanhoSaborAdmin = class
  public
    Id, Descricao, CategoriaId: string;
  end;

  TCategoriaSaborAdmin = class
  public
    Id, Nome: string;
  end;

  TfraSabores = class(TFrame)
    rctFundo: TRectangle;
    lytPrincipal, lytCabecalho, lytConteudo: TLayout;
    lblTitulo, lblSubtitulo: TLabel;
  private
    FSabores: TObjectList<TSaborAdmin>;
    FTamanhos: TObjectList<TTamanhoSaborAdmin>;
    FCategorias: TObjectList<TCategoriaSaborAdmin>;
    FCarregado: Boolean;
    FEditandoId: string;
    FSelecionado: Integer;
    FFiltroStatus: TSaborFiltroStatus;
    FModoBordas: Boolean;
    FBarra, FFiltros, FListaConteudo: TLayout;
    FBusca, FNome, FOrdem: TEdit;
    FCategoria: TComboBox;
    FDescricao, FValoresTamanho: TMemo;
    FLista: TVertScrollBox;
    FEstado, FTituloEdicao: TLabel;
    FPainelEdicao: TRectangle;
    FTimerBusca: TTimer;
    FBtnNovo, FBtnBuscar, FBtnSalvar, FBtnCancelar: TfraSensorButton;
    FBtnTodos, FBtnAtivos, FBtnInativos: TfraSensorButton;
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
    function SaborSelecionado: TSaborAdmin;
    function SaborVisivel(const ASabor: TSaborAdmin): Boolean;
    function TextoParaValor(const ATexto: string; out AValor: Currency): Boolean;
    procedure PreencherLista;
    procedure AtualizarFiltros;
    procedure AbrirEditor(const ASabor: TSaborAdmin);
    procedure FecharEditor;
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
    procedure SaborClick(Sender: TObject);
    procedure ModoClick(Sender: TObject);
    function URLDados: string;
    procedure MemoApplyStyleLookup(Sender: TObject);
    procedure CarregarTamanhos;
    procedure CarregarCategorias;
    procedure CategoriaChange(Sender: TObject);
    procedure PrepararComboEscuro(const Combo: TComboBox;
      const AFundo: TRectangle);
    procedure AtualizarComboVisual(const Combo: TComboBox);
    procedure PreencherValoresTamanho(const ASabor: TSaborAdmin);
    function CriarJSONPrecosTamanho(out AValorPadrao: Currency): TJSONArray;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure PrepararTela;
    procedure PrepararBordas;
    procedure CarregarSabores;
  end;

implementation

{$R *.fmx}

uses uMensagem, uSessaoAdmin, uNavegacaoCampos, uApiConfig;

constructor TSaborAdmin.Create;
begin
  inherited;
  PrecosTamanho := TDictionary<string, Currency>.Create;
  CategoriaIds := TList<string>.Create;
end;

destructor TSaborAdmin.Destroy;
begin
  CategoriaIds.Free;
  PrecosTamanho.Free;
  inherited;
end;

function URL_SABORES: string;
begin
  Result := TApiConfig.Url('/api/sabores');
end;

constructor TfraSabores.Create(AOwner: TComponent);
begin
  inherited;
  FSabores := TObjectList<TSaborAdmin>.Create(True);
  FTamanhos := TObjectList<TTamanhoSaborAdmin>.Create(True);
  FCategorias := TObjectList<TCategoriaSaborAdmin>.Create(True);
  FSelecionado := -1;
  FFiltroStatus := sfsTodos;
  FModoBordas := False;
  MontarTela;
end;

destructor TfraSabores.Destroy;
begin
  FTamanhos.Free;
  FCategorias.Free;
  FSabores.Free;
  inherited;
end;

function TfraSabores.CriarRotulo(const AParent: TFmxObject;
  const ATexto: string; const AX, AY, AWidth, AHeight: Single;
  const ACor: TAlphaColor; const ATamanho: Single): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := AParent;
  Result.Position.Point := PointF(AX, AY);
  Result.Width := AWidth; Result.Height := AHeight;
  Result.Text := ATexto; Result.StyledSettings := [];
  Result.TextSettings.Font.Family := 'Manrope';
  Result.TextSettings.Font.Size := ATamanho;
  Result.TextSettings.FontColor := ACor;
end;

function TfraSabores.CriarBotao(const AParent: TFmxObject;
  const ATexto: string; const AWidth: Single;
  const AOnClick: TNotifyEvent): TfraSensorButton;
begin
  Result := TfraSensorButton.Create(Self);
  Result.Name := ''; Result.Parent := AParent;
  Result.Align := TAlignLayout.Left; Result.Width := AWidth;
  Result.Margins.Right := 8; Result.Texto := ATexto;
  Result.Estilo := sbsSecondary; Result.OnButtonClick := AOnClick;
  Result.pthIcone.Margins.Left := 10;
  Result.pthIcone.Margins.Right := 6;
  Result.lblTexto.Margins.Right := 10;
end;

function TfraSabores.CriarFundoCampo(const AParent: TFmxObject;
  const AX, AY, AWidth, AHeight: Single): TRectangle;
begin
  Result := TRectangle.Create(Self);
  Result.Parent := AParent; Result.Position.Point := PointF(AX, AY);
  Result.Width := AWidth; Result.Height := AHeight;
  Result.Fill.Color := $FF152439; Result.Stroke.Color := $FF2A405B;
  Result.XRadius := 6; Result.YRadius := 6;
end;

procedure TfraSabores.ConfigurarBotaoIcone(const ABotao: TfraSensorButton;
  const AHint: string);
begin
  ABotao.Width := 38; ABotao.Height := 34; ABotao.Texto := '';
  ABotao.lblTexto.Visible := False;
  ABotao.pthIcone.Align := TAlignLayout.None;
  ABotao.pthIcone.Margins.Rect := RectF(0, 0, 0, 0);
  ABotao.pthIcone.Position.Point := PointF(
    (ABotao.Width - ABotao.pthIcone.Width) / 2,
    (ABotao.Height - ABotao.pthIcone.Height) / 2);
  ABotao.Hint := AHint; ABotao.ShowHint := True;
  ABotao.rctFundo.Hint := AHint; ABotao.rctFundo.ShowHint := True;
end;

procedure TfraSabores.MontarTela;
var
  LBuscaFundo, LListaFundo, LCampo: TRectangle;
  LForm: TVertScrollBox;
  LEspacoInferior: TLayout;
begin
  FBarra := TLayout.Create(Self);
  FBarra.Parent := lytConteudo; FBarra.Align := TAlignLayout.Top;
  FBarra.Height := 44; FBarra.Margins.Bottom := 12;
  FBtnNovo := CriarBotao(FBarra, '+ Novo sabor', 126, NovoClick);
  FBtnNovo.Align := TAlignLayout.Right; FBtnNovo.Estilo := sbsPrimary;
  FBtnNovo.Icone := sbiSabor;
  FBtnBuscar := CriarBotao(FBarra, 'Buscar', 96, BuscarClick);
  FBtnBuscar.Align := TAlignLayout.Right; FBtnBuscar.Icone := sbiPesquisar;
  LBuscaFundo := CriarFundoCampo(FBarra, 0, 0, 100, 44);
  LBuscaFundo.Align := TAlignLayout.Client;
  LBuscaFundo.Margins.Right := 12;
  LBuscaFundo.XRadius := 8; LBuscaFundo.YRadius := 8;
  FBusca := TEdit.Create(Self);
  FBusca.Parent := LBuscaFundo; FBusca.Align := TAlignLayout.Client;
  FBusca.Margins.Left := 12; FBusca.Margins.Right := 12;
  FBusca.StyleLookup := 'transparentedit';
  FBusca.TextPrompt := 'Buscar sabor por nome ou descrição';
  FBusca.StyledSettings := []; FBusca.TextSettings.FontColor := $FFF4F7FB;
  FBusca.OnTyping := BuscaChange; FBusca.OnChangeTracking := BuscaChange;
  FBusca.OnKeyDown := BuscaKeyDown;
  FTimerBusca := TTimer.Create(Self);
  FTimerBusca.Interval := 400; FTimerBusca.Enabled := False;
  FTimerBusca.OnTimer := TimerBuscaTimer;

  FFiltros := TLayout.Create(Self);
  FFiltros.Parent := lytConteudo; FFiltros.Align := TAlignLayout.Top;
  FFiltros.Height := 42; FFiltros.Margins.Bottom := 10;
  CriarRotulo(FFiltros, 'Filtrar por status:', 2, 0, 112, 42, $FF8795A8, 10);
  FBtnTodos := CriarBotao(FFiltros, 'Todos', 94, FiltroClick);
  FBtnTodos.Align := TAlignLayout.None;
  FBtnTodos.Position.Point := PointF(118, 2); FBtnTodos.Height := 36;
  FBtnTodos.Icone := sbiRelatorio; FBtnTodos.Tag := Ord(sfsTodos);
  FBtnAtivos := CriarBotao(FFiltros, 'Ativos', 98, FiltroClick);
  FBtnAtivos.Align := TAlignLayout.None;
  FBtnAtivos.Position.Point := PointF(220, 2); FBtnAtivos.Height := 36;
  FBtnAtivos.Icone := sbiAtivar; FBtnAtivos.Tag := Ord(sfsAtivos);
  FBtnInativos := CriarBotao(FFiltros, 'Inativos', 108, FiltroClick);
  FBtnInativos.Align := TAlignLayout.None;
  FBtnInativos.Position.Point := PointF(326, 2); FBtnInativos.Height := 36;
  FBtnInativos.Icone := sbiCancelar; FBtnInativos.Tag := Ord(sfsInativos);
  AtualizarFiltros;

  FPainelEdicao := TRectangle.Create(Self);
  FPainelEdicao.Parent := lytConteudo;
  FPainelEdicao.Align := TAlignLayout.Right; FPainelEdicao.Width := 350;
  FPainelEdicao.Margins.Left := 14;
  FPainelEdicao.Fill.Color := $FF111E2E;
  FPainelEdicao.Stroke.Color := $FF2A405B;
  FPainelEdicao.XRadius := 10; FPainelEdicao.YRadius := 10;
  FPainelEdicao.Visible := False;
  FTituloEdicao := CriarRotulo(FPainelEdicao, 'Novo sabor', 20, 16,
    310, 30, $FFF4F7FB, 16);
  FTituloEdicao.TextSettings.Font.Style := [TFontStyle.fsBold];
  LForm := TVertScrollBox.Create(Self);
  LForm.Parent := FPainelEdicao; LForm.Align := TAlignLayout.Client;
  FTituloEdicao.Parent := LForm;

  CriarRotulo(LForm, 'Nome *', 20, 58, 310, 20, $FF9CAABC, 10);
  LCampo := CriarFundoCampo(LForm, 20, 80, 310, 38);
  FNome := TEdit.Create(Self); FNome.Parent := LCampo;
  FNome.Align := TAlignLayout.Client;
  FNome.Margins.Left := 10; FNome.Margins.Right := 10;
  FNome.StyleLookup := 'transparentedit'; FNome.StyledSettings := [];
  FNome.TextSettings.FontColor := $FFF4F7FB;
  FNome.TextPrompt := 'Ex.: Calabresa';
  CriarRotulo(LForm, 'Valores por categoria e produto *', 20, 126, 310, 18, $FF9CAABC, 10);
  LCampo := CriarFundoCampo(LForm, 20, 140, 310, 38);
  FCategoria := TComboBox.Create(Self); FCategoria.Parent := LCampo;
  FCategoria.Align := TAlignLayout.Client;
  PrepararComboEscuro(FCategoria, LCampo);
  FCategoria.OnChange := CategoriaChange;
  LCampo.Visible := False;
  LCampo := CriarFundoCampo(LForm, 20, 158, 310, 166);
  FValoresTamanho := TMemo.Create(Self); FValoresTamanho.Parent := LCampo;
  FValoresTamanho.Align := TAlignLayout.Client;
  FValoresTamanho.Margins.Left := 8; FValoresTamanho.Margins.Right := 8;
  FValoresTamanho.OnApplyStyleLookup := MemoApplyStyleLookup;
  FValoresTamanho.StyledSettings := [];
  FValoresTamanho.TextSettings.FontColor := $FFF4F7FB;
  FValoresTamanho.WordWrap := False;
  CriarRotulo(LForm, 'Ordem de exibição', 20, 334, 310, 18, $FF9CAABC, 10);
  LCampo := CriarFundoCampo(LForm, 20, 354, 310, 38);
  FOrdem := TEdit.Create(Self); FOrdem.Parent := LCampo;
  FOrdem.Align := TAlignLayout.Client;
  FOrdem.Margins.Left := 10; FOrdem.Margins.Right := 10;
  FOrdem.StyleLookup := 'transparentedit'; FOrdem.StyledSettings := [];
  FOrdem.TextSettings.FontColor := $FFF4F7FB;
  FOrdem.KeyboardType := TVirtualKeyboardType.NumberPad;
  CriarRotulo(LForm, 'Descrição', 20, 402, 310, 18, $FF9CAABC, 10);
  LCampo := CriarFundoCampo(LForm, 20, 422, 310, 80);
  FDescricao := TMemo.Create(Self); FDescricao.Parent := LCampo;
  FDescricao.Align := TAlignLayout.Client;
  FDescricao.Margins.Left := 8; FDescricao.Margins.Right := 8;
  FDescricao.OnApplyStyleLookup := MemoApplyStyleLookup;
  FDescricao.StyledSettings := []; FDescricao.TextSettings.FontColor := $FFF4F7FB;
  FDescricao.WordWrap := True;
  TNavegacaoCampos.Aplicar(Self, [FNome, FValoresTamanho, FOrdem, FDescricao]);
  FBtnSalvar := CriarBotao(LForm, 'Salvar', 112, SalvarClick);
  FBtnSalvar.Icone := sbiSalvar; FBtnSalvar.Align := TAlignLayout.None;
  FBtnSalvar.Position.Point := PointF(218, 516); FBtnSalvar.Height := 40;
  FBtnCancelar := CriarBotao(LForm, 'Cancelar', 122, CancelarClick);
  FBtnCancelar.Icone := sbiCancelar; FBtnCancelar.Align := TAlignLayout.None;
  FBtnCancelar.Position.Point := PointF(20, 516); FBtnCancelar.Height := 40;
  { Mantém uma margem visível abaixo dos botões no final da rolagem. }
  LEspacoInferior := TLayout.Create(Self);
  LEspacoInferior.Parent := LForm;
  LEspacoInferior.Position.Point := PointF(0, 566);
  LEspacoInferior.Width := 1;
  LEspacoInferior.Height := 20;
  LEspacoInferior.HitTest := False;

  LListaFundo := TRectangle.Create(Self);
  LListaFundo.Parent := lytConteudo; LListaFundo.Align := TAlignLayout.Client;
  LListaFundo.Fill.Color := $FF111E2E; LListaFundo.Stroke.Color := $FF23364D;
  LListaFundo.XRadius := 10; LListaFundo.YRadius := 10;
  FEstado := CriarRotulo(LListaFundo, 'Carregando sabores...', 20, 16,
    500, 24, $FF8795A8, 11);
  FLista := TVertScrollBox.Create(Self); FLista.Parent := LListaFundo;
  FLista.Align := TAlignLayout.Client;
  FLista.Margins.Top := 48; FLista.Margins.Left := 8;
  FLista.Margins.Right := 8; FLista.Margins.Bottom := 8;
  FListaConteudo := TLayout.Create(Self); FListaConteudo.Parent := FLista;
  FListaConteudo.Align := TAlignLayout.Top; FListaConteudo.Height := 1;
end;

procedure TfraSabores.PrepararTela;
begin
  if FCategorias.Count = 0 then CarregarCategorias;
  if FModoBordas then
    ModoClick(nil)
  else if not FCarregado then
    CarregarSabores;
end;

procedure TfraSabores.PrepararBordas;
begin
  if FCategorias.Count = 0 then CarregarCategorias;
  if not FModoBordas then
    ModoClick(nil)
  else
    CarregarSabores;
end;

procedure TfraSabores.PrepararComboEscuro(const Combo: TComboBox;
  const AFundo: TRectangle);
var Mascara: TRectangle; Texto, Seta: TLabel;
begin
  Mascara:=TRectangle.Create(Self); Mascara.Parent:=AFundo;
  Mascara.Align:=TAlignLayout.Client; Mascara.Fill.Color:=$FF152439;
  Mascara.Stroke.Kind:=TBrushKind.None; Mascara.HitTest:=False;
  Texto:=CriarRotulo(Mascara,'Selecione...',12,0,AFundo.Width-48,
    AFundo.Height,$FFF4F7FB,11); Texto.TextSettings.VertAlign:=TTextAlign.Center;
  Texto.HitTest:=False;
  Seta:=CriarRotulo(Mascara,Char($2304),AFundo.Width-34,0,24,
    AFundo.Height,$FF9CAABC,16); Seta.TextSettings.HorzAlign:=TTextAlign.Center;
  Seta.TextSettings.VertAlign:=TTextAlign.Center; Seta.HitTest:=False;
  Seta.Anchors:=[TAnchorKind.akTop,TAnchorKind.akRight];
  Combo.TagObject:=Texto; Mascara.BringToFront;
end;

procedure TfraSabores.AtualizarComboVisual(const Combo: TComboBox);
begin
  if not Assigned(Combo) or not (Combo.TagObject is TLabel) then Exit;
  if (Combo.ItemIndex>=0) and (Combo.ItemIndex<Combo.Count) then
    TLabel(Combo.TagObject).Text:=Combo.Items[Combo.ItemIndex]
  else TLabel(Combo.TagObject).Text:='Selecione...';
end;

procedure TfraSabores.CarregarCategorias;
var H:TNetHTTPClient; R:IHTTPResponse; V,Item:TJSONValue; A:TJSONArray;
  C:TCategoriaSaborAdmin;
begin
  H:=TNetHTTPClient.Create(nil); V:=nil; TSessaoAdmin.ConfigurarCliente(H);
  try
    R:=H.Get(URL_SABORES+'/categorias'); if R.StatusCode<>200 then Exit;
    V:=TJSONObject.ParseJSONValue(R.ContentAsString(TEncoding.UTF8));
    A:=TJSONObject(V).GetValue<TJSONArray>('categorias');
    FCategorias.Clear; FCategoria.Items.Clear;
    for Item in A do begin C:=TCategoriaSaborAdmin.Create;
      C.Id:=Item.GetValue<string>('id',''); C.Nome:=Item.GetValue<string>('nome','');
      FCategorias.Add(C); FCategoria.Items.Add(C.Nome); end;
    if FCategorias.Count>0 then FCategoria.ItemIndex:=0;
    AtualizarComboVisual(FCategoria);
  finally V.Free; H.Free; end;
end;

procedure TfraSabores.CategoriaChange(Sender: TObject);
begin
  AtualizarComboVisual(FCategoria);
  PreencherValoresTamanho(SaborSelecionado);
end;

procedure TfraSabores.CarregarTamanhos;
var
  LHTTP: TNetHTTPClient;
  LResposta: IHTTPResponse;
  LValor, LItem: TJSONValue;
  LArray: TJSONArray;
  LTamanho: TTamanhoSaborAdmin;
begin
  FTamanhos.Clear;
  LHTTP := TNetHTTPClient.Create(nil);
  TSessaoAdmin.ConfigurarCliente(LHTTP);
  LValor := nil;
  try
    if FModoBordas then
      LResposta := LHTTP.Get(TApiConfig.Url('/api/sabores/bordas/produtos'))
    else
      LResposta := LHTTP.Get(URL_SABORES + '/tamanhos');
    if LResposta.StatusCode <> 200 then Exit;
    LValor := TJSONObject.ParseJSONValue(
      LResposta.ContentAsString(TEncoding.UTF8));
    if not (LValor is TJSONObject) then Exit;
    LArray := TJSONObject(LValor).GetValue<TJSONArray>('tamanhos');
    if not Assigned(LArray) then Exit;
    for LItem in LArray do
      if LItem is TJSONObject then
      begin
        LTamanho := TTamanhoSaborAdmin.Create;
        LTamanho.Id := TJSONObject(LItem).GetValue<string>('id', '');
        LTamanho.CategoriaId := TJSONObject(LItem).GetValue<string>('categoria_id', '');
        LTamanho.Descricao := TJSONObject(LItem).GetValue<string>(
          'descricao', TJSONObject(LItem).GetValue<string>('nome', ''));
        if not LTamanho.Id.IsEmpty then FTamanhos.Add(LTamanho)
        else LTamanho.Free;
      end;
  finally
    LValor.Free;
    LHTTP.Free;
  end;
end;

procedure TfraSabores.CarregarSabores;
var
  LHTTP: TNetHTTPClient; LResposta: IHTTPResponse;
  LValor, LItem, LPrecoItem, LCategoriaItem: TJSONValue;
  LArray, LPrecos, LCategorias: TJSONArray;
  LJSON: TJSONObject;
  LSabor: TSaborAdmin; LURL: string;
  LVariacaoId: string; LPreco: Currency;
begin
  FEstado.Text := 'Carregando sabores...'; FLista.Enabled := False;
  { Produtos e categorias mudam com pouca frequência. Evita uma segunda
    chamada HTTP em toda busca e em cada retorno à tela. }
  if FTamanhos.Count = 0 then
    CarregarTamanhos;
  LHTTP := TNetHTTPClient.Create(nil); TSessaoAdmin.ConfigurarCliente(LHTTP); LValor := nil;
  try
    try
      LHTTP.Accept := 'application/json';
      LURL := URLDados + '?empresaId=' + TNetEncoding.URL.Encode(TSessaoAdmin.EmpresaId);
      if not FBusca.Text.Trim.IsEmpty then
        LURL := LURL + '&busca=' + TNetEncoding.URL.Encode(FBusca.Text.Trim);
      LResposta := LHTTP.Get(LURL);
      if LResposta.StatusCode <> 200 then
      begin
        ExibirErroAPI('Erro ao carregar sabores', LResposta);
        FEstado.Text := 'Não foi possível carregar os sabores.'; Exit;
      end;
      LValor := TJSONObject.ParseJSONValue(LResposta.ContentAsString(TEncoding.UTF8));
      if not (LValor is TJSONObject) then
        raise Exception.Create('Resposta inválida recebida da API.');
      LArray := TJSONObject(LValor).GetValue<TJSONArray>('sabores');
      FSabores.Clear;
      for LItem in LArray do
      begin
        LJSON := LItem as TJSONObject; LSabor := TSaborAdmin.Create;
        LSabor.Id := LJSON.GetValue<string>('id', '');
        LSabor.Nome := LJSON.GetValue<string>('nome', '');
        LSabor.Descricao := LJSON.GetValue<string>('descricao', '');
        LCategorias := LJSON.GetValue<TJSONArray>('categoria_ids');
        if Assigned(LCategorias) then
          for LCategoriaItem in LCategorias do
            LSabor.CategoriaIds.Add(LCategoriaItem.Value);
        LSabor.ValorAdicional := StrToCurrDef(
          LJSON.GetValue<string>('valor_adicional', '0'), 0, TFormatSettings.Invariant);
        LPrecos := LJSON.GetValue<TJSONArray>('precos_tamanho');
        if Assigned(LPrecos) then
          for LPrecoItem in LPrecos do
            if LPrecoItem is TJSONObject then
            begin
              LVariacaoId := TJSONObject(LPrecoItem).GetValue<string>(
                'produto_id', '');
              LPreco := StrToCurrDef(
                TJSONObject(LPrecoItem).GetValue<string>('valor', '0'),
                0, TFormatSettings.Invariant);
              if not LVariacaoId.IsEmpty then
                LSabor.PrecosTamanho.AddOrSetValue(LVariacaoId, LPreco);
            end;
        LSabor.Ordem := LJSON.GetValue<Integer>('ordem', 0);
        LSabor.QuantidadeProdutos := LJSON.GetValue<Integer>('quantidade_produtos', 0);
        LSabor.Ativo := LJSON.GetValue<Boolean>('ativo', True);
        FSabores.Add(LSabor);
      end;
      FCarregado := True; PreencherLista;
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

function TfraSabores.SaborVisivel(const ASabor: TSaborAdmin): Boolean;
begin
  case FFiltroStatus of
    sfsAtivos: Result := ASabor.Ativo;
    sfsInativos: Result := not ASabor.Ativo;
  else Result := True;
  end;
end;

procedure TfraSabores.PreencherLista;
var
  LSabor: TSaborAdmin; LCard: TRectangle; LTexto, LAcoes: TLayout;
  LNome, LDetalhe, LStatus: TLabel; LEditar, LAtivo: TfraSensorButton;
  LResumo, LStatusTexto: string; I, LPosicao, LExibidos: Integer;
begin
  FLista.BeginUpdate;
  FListaConteudo.BeginUpdate;
  try
    while FListaConteudo.ChildrenCount > 0 do FListaConteudo.Children[0].Free;
    FSelecionado := -1; LExibidos := 0;
    for LSabor in FSabores do if SaborVisivel(LSabor) then Inc(LExibidos);
    FListaConteudo.Height := LExibidos * 66; LPosicao := 0;
    for I := 0 to FSabores.Count - 1 do
    begin
      LSabor := FSabores[I]; if not SaborVisivel(LSabor) then Continue;
      if LSabor.Ativo then LStatusTexto := 'ATIVO' else LStatusTexto := 'INATIVO';
      LResumo := LSabor.Descricao; if LResumo.IsEmpty then LResumo := 'Sem descrição';
      LResumo := LResumo + '  •  ' + FormatCurr('R$ #,##0.00', LSabor.ValorAdicional) +
        Format('  •  %d produto(s)  •  Ordem %d', [LSabor.QuantidadeProdutos, LSabor.Ordem]);
      LCard := TRectangle.Create(Self); LCard.Parent := FListaConteudo;
      LCard.Position.Point := PointF(4, LPosicao * 66 + 2);
      LCard.Width := FListaConteudo.Width - 8; LCard.Height := 60;
      LCard.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akRight];
      LCard.Fill.Color := $FF152439; LCard.Stroke.Color := $FF23364D;
      LCard.XRadius := 7; LCard.YRadius := 7; LCard.Tag := I; LCard.OnClick := SaborClick;
      LAcoes := TLayout.Create(Self); LAcoes.Parent := LCard; LAcoes.Align := TAlignLayout.Right; LAcoes.Width := 164;
      LEditar := CriarBotao(LAcoes, '', 38, EditarClick); LEditar.Align := TAlignLayout.None;
      LEditar.Position.Point := PointF(0, 13); LEditar.Icone := sbiEditar; LEditar.Tag := I;
      ConfigurarBotaoIcone(LEditar, 'Editar sabor');
      LAtivo := CriarBotao(LAcoes, '', 38, AtivoClick); LAtivo.Align := TAlignLayout.None;
      LAtivo.Position.Point := PointF(46, 13); LAtivo.Tag := I;
      if LSabor.Ativo then begin LAtivo.Icone := sbiCancelar; ConfigurarBotaoIcone(LAtivo, 'Desativar sabor'); end
      else begin LAtivo.Icone := sbiAtivar; ConfigurarBotaoIcone(LAtivo, 'Ativar sabor'); end;
      LStatus := CriarRotulo(LAcoes, LStatusTexto, 92, 0, 60, 60, $FF45D483, 9);
      LStatus.TextSettings.HorzAlign := TTextAlign.Trailing; LStatus.HitTest := False;
      if not LSabor.Ativo then LStatus.TextSettings.FontColor := $FFFFB454;
      LTexto := TLayout.Create(Self); LTexto.Parent := LCard; LTexto.Align := TAlignLayout.Client;
      LTexto.Margins.Left := 14; LTexto.Margins.Right := 12; LTexto.HitTest := False;
      LNome := CriarRotulo(LTexto, LSabor.Nome, 0, 5, 600, 24, $FFF4F7FB, 11);
      LNome.Align := TAlignLayout.Top; LNome.HitTest := False; LNome.TextSettings.Font.Style := [TFontStyle.fsBold];
      LDetalhe := CriarRotulo(LTexto, LResumo, 0, 30, 800, 22, $FF8795A8, 9);
      LDetalhe.Align := TAlignLayout.Bottom; LDetalhe.Margins.Bottom := 5; LDetalhe.HitTest := False;
      Inc(LPosicao);
    end;
  finally
    FListaConteudo.EndUpdate;
    FLista.EndUpdate;
  end;
  if LExibidos = 0 then FEstado.Text := 'Nenhum sabor encontrado neste filtro.'
  else if LExibidos = FSabores.Count then
    FEstado.Text := Format('%d sabor(es) encontrado(s)', [LExibidos])
  else FEstado.Text := Format('%d de %d sabor(es)', [LExibidos, FSabores.Count]);
end;

procedure TfraSabores.AtualizarFiltros;
begin
  FBtnTodos.Estilo := sbsSecondary; FBtnAtivos.Estilo := sbsSecondary;
  FBtnInativos.Estilo := sbsSecondary;
  case FFiltroStatus of
    sfsTodos: FBtnTodos.Estilo := sbsPrimary;
    sfsAtivos: FBtnAtivos.Estilo := sbsPrimary;
    sfsInativos: FBtnInativos.Estilo := sbsPrimary;
  end;
end;

procedure TfraSabores.FiltroClick(Sender: TObject);
begin
  if Sender is TfraSensorButton then
  begin
    FFiltroStatus := TSaborFiltroStatus(TfraSensorButton(Sender).Tag);
    AtualizarFiltros; PreencherLista;
  end;
end;

function TfraSabores.SaborSelecionado: TSaborAdmin;
begin
  Result := nil;
  if (FSelecionado >= 0) and (FSelecionado < FSabores.Count) then
    Result := FSabores[FSelecionado];
end;

procedure TfraSabores.SaborClick(Sender: TObject);
var I: Integer; LCard: TRectangle;
begin
  if not (Sender is TRectangle) then Exit;
  FSelecionado := TRectangle(Sender).Tag;
  for I := 0 to FListaConteudo.ChildrenCount - 1 do
    if FListaConteudo.Children[I] is TRectangle then
    begin
      LCard := TRectangle(FListaConteudo.Children[I]);
      if LCard.Tag = FSelecionado then
      begin LCard.Fill.Color := $FF2B2351; LCard.Stroke.Color := $FF8C63FF; end
      else
      begin LCard.Fill.Color := $FF152439; LCard.Stroke.Color := $FF23364D; end;
    end;
end;

procedure TfraSabores.NovoClick(Sender: TObject); begin AbrirEditor(nil); end;

function TfraSabores.URLDados: string;
begin
  if FModoBordas then Result := TApiConfig.Url('/api/sabores/bordas')
  else Result := URL_SABORES;
end;

procedure TfraSabores.ModoClick(Sender: TObject);
begin
  FModoBordas := not FModoBordas;
  if FModoBordas then
  begin
    lblTitulo.Text := 'Bordas';
    lblSubtitulo.Text := 'Gerencie as bordas e os valores por tamanho.';
    FBtnNovo.Texto := '+ Nova borda';
    FBusca.TextPrompt := 'Buscar borda por nome';
  end
  else
  begin
    lblTitulo.Text := 'Sabores';
    lblSubtitulo.Text := 'Gerencie os sabores e os valores por tamanho.';
    FBtnNovo.Texto := '+ Novo sabor';
    FBusca.TextPrompt := 'Buscar sabor por nome ou descrição';
  end;
  FBusca.Text := ''; FSelecionado := -1; FecharEditor; CarregarSabores;
end;
procedure TfraSabores.EditarClick(Sender: TObject);
begin
  if Sender is TfraSensorButton then FSelecionado := TfraSensorButton(Sender).Tag;
  AbrirEditor(SaborSelecionado);
end;

procedure TfraSabores.PreencherValoresTamanho(const ASabor: TSaborAdmin);
var
  LTamanho: TTamanhoSaborAdmin;
  LValor: Currency;
  LCategoriaId, LCategoriaNome: string;
  I: Integer;
begin
  FValoresTamanho.Lines.BeginUpdate;
  try
    FValoresTamanho.Lines.Clear;
    LCategoriaId := '';
    for LTamanho in FTamanhos do
    begin
      if not SameText(LCategoriaId, LTamanho.CategoriaId) then
      begin
        LCategoriaId := LTamanho.CategoriaId;
        LCategoriaNome := 'Categoria';
        for I := 0 to FCategorias.Count - 1 do
          if SameText(FCategorias[I].Id, LCategoriaId) then
          begin
            LCategoriaNome := FCategorias[I].Nome;
            Break;
          end;
        if FValoresTamanho.Lines.Count > 0 then
          FValoresTamanho.Lines.Add('');
        FValoresTamanho.Lines.Add('[' + LCategoriaNome + ']');
      end;
      if Assigned(ASabor) and
         ASabor.PrecosTamanho.TryGetValue(LTamanho.Id, LValor) then
        FValoresTamanho.Lines.Add(
          LTamanho.Descricao + '=' + FormatCurr('0.00', LValor))
      else
        FValoresTamanho.Lines.Add(LTamanho.Descricao + '=');
    end;
  finally
    FValoresTamanho.Lines.EndUpdate;
  end;
end;

function TfraSabores.CriarJSONPrecosTamanho(
  out AValorPadrao: Currency): TJSONArray;
var
  LTamanho: TTamanhoSaborAdmin;
  LLinhas: TStringList;
  LTexto: string;
  LValor: Currency;
  LItem: TJSONObject;
begin
  Result := TJSONArray.Create;
  AValorPadrao := 0;
  LLinhas := TStringList.Create;
  try
    LLinhas.Assign(FValoresTamanho.Lines);
    LLinhas.NameValueSeparator := '=';
    for LTamanho in FTamanhos do
    begin
      LTexto := LLinhas.Values[LTamanho.Descricao].Trim;
      { Linha vazia significa que este sabor não pertence ao produto. }
      if LTexto.IsEmpty then
        Continue;
      if not TextoParaValor(LTexto, LValor) or (LValor < 0) then
      begin
        Result.Free;
        Result := nil;
        Exit;
      end;
      if Result.Count = 0 then AValorPadrao := LValor;
      LItem := TJSONObject.Create;
      LItem.AddPair('produtoId', LTamanho.Id);
      LItem.AddPair('valor', TJSONNumber.Create(Double(LValor)));
      Result.AddElement(LItem);
    end;
    if Result.Count = 0 then
    begin
      Result.Free;
      Result := nil;
    end;
  finally
    LLinhas.Free;
  end;
end;

procedure TfraSabores.AbrirEditor(const ASabor: TSaborAdmin);
var I: Integer;
begin
  if Assigned(ASabor) then
  begin
    FEditandoId := ASabor.Id;
    if FModoBordas then FTituloEdicao.Text := 'Editar borda'
    else FTituloEdicao.Text := 'Editar sabor';
    FNome.Text := ASabor.Nome;
    if ASabor.CategoriaIds.Count > 0 then
      for I := 0 to FCategorias.Count - 1 do
        if SameText(FCategorias[I].Id, ASabor.CategoriaIds[0]) then
        begin FCategoria.ItemIndex := I; Break; end;
    AtualizarComboVisual(FCategoria);
    FOrdem.Text := IntToStr(ASabor.Ordem); FDescricao.Text := ASabor.Descricao;
    PreencherValoresTamanho(ASabor);
  end
  else
  begin
    FEditandoId := '';
    if FModoBordas then FTituloEdicao.Text := 'Nova borda'
    else FTituloEdicao.Text := 'Novo sabor';
    FNome.Text := '';
    FOrdem.Text := IntToStr(FSabores.Count + 1);
    FDescricao.Text := '';
    PreencherValoresTamanho(nil);
  end;
  FPainelEdicao.Visible := True; FPainelEdicao.BringToFront; FNome.SetFocus;
end;

procedure TfraSabores.FecharEditor;
begin FPainelEdicao.Visible := False; FEditandoId := ''; end;
procedure TfraSabores.CancelarClick(Sender: TObject); begin FecharEditor; end;

function TfraSabores.TextoParaValor(const ATexto: string;
  out AValor: Currency): Boolean;
begin
  Result := TryStrToCurr(ATexto.Trim, AValor);
  if not Result then
    Result := TryStrToCurr(ATexto.Trim, AValor, TFormatSettings.Invariant);
end;

procedure TfraSabores.SalvarClick(Sender: TObject);
var
  LValor: Currency; LOrdem: Integer; LHTTP: TNetHTTPClient;
  LJSON: TJSONObject; LPrecos: TJSONArray;
  LStream: TStringStream; LResposta: IHTTPResponse;
begin
  if FNome.Text.Trim.IsEmpty then
  begin TfrmMensagem.Exibir('Campo obrigatório', 'Informe o nome do sabor.', tmAtencao); FNome.SetFocus; Exit; end;
  if FTamanhos.Count = 0 then
  begin TfrmMensagem.Exibir('Produtos e tamanhos não encontrados',
    'Cadastre o produto e suas variações de tamanho antes dos preços dos sabores.',
    tmAtencao); Exit; end;
  LPrecos := CriarJSONPrecosTamanho(LValor);
  if not Assigned(LPrecos) then
  begin TfrmMensagem.Exibir('Produto não selecionado',
    'Informe o valor somente nos produtos que utilizarão este sabor.',
    tmAtencao); FValoresTamanho.SetFocus; Exit; end;
  if not TryStrToInt(FOrdem.Text.Trim, LOrdem) or (LOrdem < 0) then
  begin LPrecos.Free; TfrmMensagem.Exibir('Ordem inválida', 'Informe um número inteiro maior ou igual a zero.', tmAtencao); FOrdem.SetFocus; Exit; end;
  LJSON := TJSONObject.Create;
  if FEditandoId.IsEmpty then LJSON.AddPair('empresaId', TSessaoAdmin.EmpresaId);
  LJSON.AddPair('nome', FNome.Text.Trim);
  { O formulário envia a grade completa. A API substitui todas as associações
    pelas categorias identificadas nos produtos que receberam valor. }
  LJSON.AddPair('substituirCategorias', TJSONBool.Create(True));
  LJSON.AddPair('descricao', FDescricao.Text.Trim);
  LJSON.AddPair('valorAdicional', TJSONNumber.Create(Double(LValor)));
  LJSON.AddPair('precosTamanho', LPrecos);
  LJSON.AddPair('ordem', TJSONNumber.Create(LOrdem));
  LHTTP := TNetHTTPClient.Create(nil);
  TSessaoAdmin.ConfigurarCliente(LHTTP);
  LStream := TStringStream.Create(LJSON.ToJSON, TEncoding.UTF8);
  try
    try
      LHTTP.ContentType := 'application/json'; LHTTP.Accept := 'application/json';
      if FEditandoId.IsEmpty then LResposta := LHTTP.Post(URLDados, LStream)
      else LResposta := LHTTP.Put(URLDados + '/' + FEditandoId, LStream);
      if not (LResposta.StatusCode in [200, 201]) then
      begin ExibirErroAPI('Não foi possível salvar o sabor', LResposta); Exit; end;
      FecharEditor; CarregarSabores;
      TfrmMensagem.Exibir('Sabor salvo', 'Os dados foram salvos com sucesso.', tmSucesso);
    except on E: Exception do TfrmMensagem.Exibir('Erro de comunicação', E.Message, tmErro); end;
  finally LStream.Free; LHTTP.Free; LJSON.Free; end;
end;

procedure TfraSabores.AtivoClick(Sender: TObject);
var LSabor: TSaborAdmin; LHTTP: TNetHTTPClient; LJSON: TJSONObject;
  LStream: TStringStream; LResposta: IHTTPResponse;
begin
  if Sender is TfraSensorButton then FSelecionado := TfraSensorButton(Sender).Tag;
  LSabor := SaborSelecionado; if not Assigned(LSabor) then Exit;
  LJSON := TJSONObject.Create;
  LJSON.AddPair('ativo', TJSONBool.Create(not LSabor.Ativo));
  LHTTP := TNetHTTPClient.Create(nil);
  TSessaoAdmin.ConfigurarCliente(LHTTP);
  LStream := TStringStream.Create(LJSON.ToJSON, TEncoding.UTF8);
  try
    try
      LHTTP.ContentType := 'application/json'; LHTTP.Accept := 'application/json';
      LResposta := LHTTP.Patch(URLDados + '/' + LSabor.Id + '/situacao', LStream);
      if LResposta.StatusCode <> 200 then
      begin ExibirErroAPI('Não foi possível alterar o sabor', LResposta); Exit; end;
      CarregarSabores;
    except on E: Exception do TfrmMensagem.Exibir('Erro de comunicação', E.Message, tmErro); end;
  finally LStream.Free; LHTTP.Free; LJSON.Free; end;
end;

procedure TfraSabores.BuscarClick(Sender: TObject);
begin FTimerBusca.Enabled := False; CarregarSabores; end;
procedure TfraSabores.BuscaChange(Sender: TObject);
begin FTimerBusca.Enabled := False; FTimerBusca.Enabled := True; end;
procedure TfraSabores.TimerBuscaTimer(Sender: TObject);
begin FTimerBusca.Enabled := False; CarregarSabores; end;
procedure TfraSabores.BuscaKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin Key := 0; KeyChar := #0; FTimerBusca.Enabled := False; CarregarSabores; end;
end;

procedure TfraSabores.MemoApplyStyleLookup(Sender: TObject);
var LFundo, LMemo: TControl;
begin
  if not (Sender is TMemo) then Exit;
  LMemo := TControl(Sender);
  LFundo := LMemo.FindStyleResource('background') as TControl;
  if Assigned(LFundo) then
  begin LFundo.Opacity := 0; LFundo.HitTest := False; end;
end;

procedure TfraSabores.ExibirErroAPI(const ATitulo: string;
  const AResposta: IHTTPResponse);
var LValor: TJSONValue; LMensagem: string;
begin
  LMensagem := 'A API retornou o código ' + IntToStr(AResposta.StatusCode) + '.';
  LValor := TJSONObject.ParseJSONValue(AResposta.ContentAsString(TEncoding.UTF8));
  try
    if LValor is TJSONObject then
      LMensagem := TJSONObject(LValor).GetValue<string>('erro', LMensagem);
  finally LValor.Free; end;
  TfrmMensagem.Exibir(ATitulo, LMensagem, tmErro);
end;

end.
