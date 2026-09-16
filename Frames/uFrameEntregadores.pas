unit uFrameEntregadores;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.JSON,
  System.Net.URLClient, System.Net.HttpClient, System.Net.HttpClientComponent,
  System.NetEncoding, System.Generics.Collections,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Objects,
  FMX.Layouts, FMX.Controls.Presentation, FMX.Edit, uFrameSensorButton;

type
  TEntregadorFiltroStatus = (efsTodos, efsDisponiveis, efsOcupados, efsInativos);

  TEntregadorAdmin = class
  public
    Id, Nome, Telefone, Documento, Veiculo, Placa: string;
    Disponivel, Ativo: Boolean;
    EntregasEmAndamento: Integer;
  end;

  TfraEntregadores = class(TFrame)
    rctFundo: TRectangle;
    lytPrincipal, lytCabecalho, lytConteudo: TLayout;
    lblTitulo, lblSubtitulo: TLabel;
  private
    FEntregadores: TObjectList<TEntregadorAdmin>;
    FCarregado: Boolean;
    FEditandoId: string;
    FSelecionado: Integer;
    FFiltroStatus: TEntregadorFiltroStatus;
    FDisponivelEditor: Boolean;
    FBarra, FFiltros, FListaConteudo: TLayout;
    FBusca, FNome, FTelefone, FDocumento, FVeiculo, FPlaca: TEdit;
    FLista: TVertScrollBox;
    FEstado, FTituloEdicao: TLabel;
    FPainelEdicao: TRectangle;
    FTimerBusca: TTimer;
    FBtnNovo, FBtnBuscar, FBtnSalvar, FBtnCancelar,
      FBtnDisponibilidadeEditor: TfraSensorButton;
    FBtnTodos, FBtnDisponiveis, FBtnOcupados, FBtnInativos: TfraSensorButton;
    procedure MontarTela;
    function CriarRotulo(const AParent: TFmxObject; const ATexto: string;
      const AX, AY, AWidth, AHeight: Single; const ACor: TAlphaColor;
      const ATamanho: Single): TLabel;
    function CriarBotao(const AParent: TFmxObject; const ATexto: string;
      const AWidth: Single; const AOnClick: TNotifyEvent): TfraSensorButton;
    function CriarFundoCampo(const AParent: TFmxObject; const AX, AY,
      AWidth, AHeight: Single): TRectangle;
    function CriarCampo(const AParent: TFmxObject; const ALabel, APrompt: string;
      const AY: Single): TEdit;
    procedure ConfigurarBotaoIcone(const ABotao: TfraSensorButton;
      const AHint: string);
    function EntregadorSelecionado: TEntregadorAdmin;
    function EntregadorVisivel(const AEntregador: TEntregadorAdmin): Boolean;
    procedure PreencherLista;
    procedure AtualizarFiltros;
    procedure AtualizarDisponibilidadeEditor;
    procedure AbrirEditor(const AEntregador: TEntregadorAdmin);
    procedure FecharEditor;
    procedure ExibirErroAPI(const ATitulo: string; const AResposta: IHTTPResponse);
    procedure NovoClick(Sender: TObject);
    procedure EditarClick(Sender: TObject);
    procedure DisponibilidadeClick(Sender: TObject);
    procedure AtivoClick(Sender: TObject);
    procedure DisponibilidadeEditorClick(Sender: TObject);
    procedure SalvarClick(Sender: TObject);
    procedure CancelarClick(Sender: TObject);
    procedure BuscarClick(Sender: TObject);
    procedure BuscaChange(Sender: TObject);
    procedure BuscaKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure TimerBuscaTimer(Sender: TObject);
    procedure FiltroClick(Sender: TObject);
    procedure EntregadorClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure PrepararTela;
    procedure CarregarEntregadores;
  end;

implementation

{$R *.fmx}

uses uMensagem, uSessaoAdmin, uNavegacaoCampos, uApiConfig;

function URL_ENTREGADORES: string;
begin
  Result := TApiConfig.Url('/api/entregadores');
end;

constructor TfraEntregadores.Create(AOwner: TComponent);
begin
  inherited;
  FEntregadores := TObjectList<TEntregadorAdmin>.Create(True);
  FSelecionado := -1;
  FFiltroStatus := efsTodos;
  MontarTela;
end;

destructor TfraEntregadores.Destroy;
begin
  FEntregadores.Free;
  inherited;
end;

function TfraEntregadores.CriarRotulo(const AParent: TFmxObject;
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

function TfraEntregadores.CriarBotao(const AParent: TFmxObject;
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

function TfraEntregadores.CriarFundoCampo(const AParent: TFmxObject;
  const AX, AY, AWidth, AHeight: Single): TRectangle;
begin
  Result := TRectangle.Create(Self); Result.Parent := AParent;
  Result.Position.Point := PointF(AX, AY); Result.Width := AWidth;
  Result.Height := AHeight; Result.Fill.Color := $FF152439;
  Result.Stroke.Color := $FF2A405B; Result.XRadius := 6; Result.YRadius := 6;
end;

function TfraEntregadores.CriarCampo(const AParent: TFmxObject;
  const ALabel, APrompt: string; const AY: Single): TEdit;
var LFundo: TRectangle;
begin
  CriarRotulo(AParent, ALabel, 20, AY, 310, 18, $FF9CAABC, 10);
  LFundo := CriarFundoCampo(AParent, 20, AY + 20, 310, 36);
  Result := TEdit.Create(Self); Result.Parent := LFundo;
  Result.Align := TAlignLayout.Client; Result.Margins.Left := 10;
  Result.Margins.Right := 10; Result.StyleLookup := 'transparentedit';
  Result.StyledSettings := []; Result.TextSettings.FontColor := $FFF4F7FB;
  Result.TextPrompt := APrompt;
end;

procedure TfraEntregadores.ConfigurarBotaoIcone(
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

procedure TfraEntregadores.MontarTela;
var LBuscaFundo, LListaFundo: TRectangle; LForm: TLayout;
begin
  FBarra := TLayout.Create(Self); FBarra.Parent := lytConteudo;
  FBarra.Align := TAlignLayout.Top; FBarra.Height := 44;
  FBarra.Margins.Bottom := 12;
  FBtnNovo := CriarBotao(FBarra, '+ Novo entregador', 154, NovoClick);
  FBtnNovo.Align := TAlignLayout.Right; FBtnNovo.Estilo := sbsPrimary;
  FBtnNovo.Icone := sbiEntrega;
  FBtnBuscar := CriarBotao(FBarra, 'Buscar', 96, BuscarClick);
  FBtnBuscar.Align := TAlignLayout.Right; FBtnBuscar.Icone := sbiPesquisar;
  LBuscaFundo := CriarFundoCampo(FBarra, 0, 0, 100, 44);
  LBuscaFundo.Align := TAlignLayout.Client; LBuscaFundo.Margins.Right := 12;
  LBuscaFundo.XRadius := 8; LBuscaFundo.YRadius := 8;
  FBusca := TEdit.Create(Self); FBusca.Parent := LBuscaFundo;
  FBusca.Align := TAlignLayout.Client; FBusca.Margins.Left := 12;
  FBusca.Margins.Right := 12; FBusca.StyleLookup := 'transparentedit';
  FBusca.TextPrompt := 'Buscar por nome, telefone, documento, veículo ou placa';
  FBusca.StyledSettings := []; FBusca.TextSettings.FontColor := $FFF4F7FB;
  FBusca.OnTyping := BuscaChange; FBusca.OnChangeTracking := BuscaChange;
  FBusca.OnKeyDown := BuscaKeyDown;
  FTimerBusca := TTimer.Create(Self); FTimerBusca.Interval := 400;
  FTimerBusca.Enabled := False; FTimerBusca.OnTimer := TimerBuscaTimer;

  FFiltros := TLayout.Create(Self); FFiltros.Parent := lytConteudo;
  FFiltros.Align := TAlignLayout.Top; FFiltros.Height := 42;
  FFiltros.Margins.Bottom := 10;
  CriarRotulo(FFiltros, 'Filtrar por status:', 2, 0, 112, 42, $FF8795A8, 10);
  FBtnTodos := CriarBotao(FFiltros, 'Todos', 94, FiltroClick);
  FBtnTodos.Align := TAlignLayout.None; FBtnTodos.Position.Point := PointF(118, 2);
  FBtnTodos.Height := 36; FBtnTodos.Icone := sbiRelatorio;
  FBtnTodos.Tag := Ord(efsTodos);
  FBtnDisponiveis := CriarBotao(FFiltros, 'Disponíveis', 126, FiltroClick);
  FBtnDisponiveis.Align := TAlignLayout.None;
  FBtnDisponiveis.Position.Point := PointF(220, 2); FBtnDisponiveis.Height := 36;
  FBtnDisponiveis.Icone := sbiAtivar; FBtnDisponiveis.Tag := Ord(efsDisponiveis);
  FBtnOcupados := CriarBotao(FFiltros, 'Ocupados', 112, FiltroClick);
  FBtnOcupados.Align := TAlignLayout.None;
  FBtnOcupados.Position.Point := PointF(354, 2); FBtnOcupados.Height := 36;
  FBtnOcupados.Icone := sbiEntrega; FBtnOcupados.Tag := Ord(efsOcupados);
  FBtnInativos := CriarBotao(FFiltros, 'Inativos', 108, FiltroClick);
  FBtnInativos.Align := TAlignLayout.None;
  FBtnInativos.Position.Point := PointF(474, 2); FBtnInativos.Height := 36;
  FBtnInativos.Icone := sbiCancelar; FBtnInativos.Tag := Ord(efsInativos);
  AtualizarFiltros;

  FPainelEdicao := TRectangle.Create(Self); FPainelEdicao.Parent := lytConteudo;
  FPainelEdicao.Align := TAlignLayout.Right; FPainelEdicao.Width := 350;
  FPainelEdicao.Margins.Left := 14; FPainelEdicao.Fill.Color := $FF111E2E;
  FPainelEdicao.Stroke.Color := $FF2A405B;
  FPainelEdicao.XRadius := 10; FPainelEdicao.YRadius := 10;
  FPainelEdicao.Visible := False;
  FTituloEdicao := CriarRotulo(FPainelEdicao, 'Novo entregador', 20, 14,
    310, 30, $FFF4F7FB, 16);
  FTituloEdicao.TextSettings.Font.Style := [TFontStyle.fsBold];
  LForm := TLayout.Create(Self); LForm.Parent := FPainelEdicao;
  LForm.Align := TAlignLayout.Client;
  FNome := CriarCampo(LForm, 'Nome *', 'Nome do entregador', 48);
  FTelefone := CriarCampo(LForm, 'Telefone *', '(00) 00000-0000', 106);
  FTelefone.KeyboardType := TVirtualKeyboardType.PhonePad;
  FDocumento := CriarCampo(LForm, 'Documento', 'CPF ou documento', 164);
  FVeiculo := CriarCampo(LForm, 'Veículo', 'Ex.: Moto Honda CG', 222);
  FPlaca := CriarCampo(LForm, 'Placa', 'ABC1D23', 280);
  FPlaca.CharCase := TEditCharCase.ecUpperCase;
  TNavegacaoCampos.Aplicar(Self, [FNome, FTelefone, FDocumento,
    FVeiculo, FPlaca]);
  FBtnDisponibilidadeEditor := CriarBotao(LForm, 'Disponível', 142,
    DisponibilidadeEditorClick);
  FBtnDisponibilidadeEditor.Align := TAlignLayout.None;
  FBtnDisponibilidadeEditor.Position.Point := PointF(20, 348);
  FBtnDisponibilidadeEditor.Height := 38;
  FBtnSalvar := CriarBotao(LForm, 'Salvar', 112, SalvarClick);
  FBtnSalvar.Icone := sbiSalvar; FBtnSalvar.Align := TAlignLayout.None;
  FBtnSalvar.Position.Point := PointF(218, 400); FBtnSalvar.Height := 40;
  FBtnCancelar := CriarBotao(LForm, 'Cancelar', 104, CancelarClick);
  FBtnCancelar.Icone := sbiCancelar; FBtnCancelar.Align := TAlignLayout.None;
  FBtnCancelar.Position.Point := PointF(20, 400); FBtnCancelar.Height := 40;

  LListaFundo := TRectangle.Create(Self); LListaFundo.Parent := lytConteudo;
  LListaFundo.Align := TAlignLayout.Client; LListaFundo.Fill.Color := $FF111E2E;
  LListaFundo.Stroke.Color := $FF23364D;
  LListaFundo.XRadius := 10; LListaFundo.YRadius := 10;
  FEstado := CriarRotulo(LListaFundo, 'Carregando entregadores...', 20, 16,
    500, 24, $FF8795A8, 11);
  FLista := TVertScrollBox.Create(Self); FLista.Parent := LListaFundo;
  FLista.Align := TAlignLayout.Client; FLista.Margins.Top := 48;
  FLista.Margins.Left := 8; FLista.Margins.Right := 8;
  FLista.Margins.Bottom := 8;
  FListaConteudo := TLayout.Create(Self); FListaConteudo.Parent := FLista;
  FListaConteudo.Align := TAlignLayout.Top; FListaConteudo.Height := 1;
end;

procedure TfraEntregadores.PrepararTela;
begin
  if not FCarregado then CarregarEntregadores;
end;

procedure TfraEntregadores.CarregarEntregadores;
var
  LHTTP: TNetHTTPClient; LResposta: IHTTPResponse;
  LValor, LItem: TJSONValue; LArray: TJSONArray; LJSON: TJSONObject;
  LEntregador: TEntregadorAdmin; LURL: string;
begin
  FEstado.Text := 'Carregando entregadores...'; FLista.Enabled := False;
  LHTTP := TNetHTTPClient.Create(nil); TSessaoAdmin.ConfigurarCliente(LHTTP); LValor := nil;
  try
    try
      LHTTP.Accept := 'application/json';
      LURL := URL_ENTREGADORES + '?empresaId=' + TNetEncoding.URL.Encode(TSessaoAdmin.EmpresaId);
      if not FBusca.Text.Trim.IsEmpty then
        LURL := LURL + '&busca=' + TNetEncoding.URL.Encode(FBusca.Text.Trim);
      LResposta := LHTTP.Get(LURL);
      if LResposta.StatusCode <> 200 then
      begin
        ExibirErroAPI('Erro ao carregar entregadores', LResposta);
        FEstado.Text := 'Não foi possível carregar os entregadores.'; Exit;
      end;
      LValor := TJSONObject.ParseJSONValue(LResposta.ContentAsString(TEncoding.UTF8));
      if not (LValor is TJSONObject) then
        raise Exception.Create('Resposta inválida recebida da API.');
      LArray := TJSONObject(LValor).GetValue<TJSONArray>('entregadores');
      FEntregadores.Clear;
      for LItem in LArray do
      begin
        LJSON := LItem as TJSONObject; LEntregador := TEntregadorAdmin.Create;
        LEntregador.Id := LJSON.GetValue<string>('id', '');
        LEntregador.Nome := LJSON.GetValue<string>('nome', '');
        LEntregador.Telefone := LJSON.GetValue<string>('telefone', '');
        LEntregador.Documento := LJSON.GetValue<string>('documento', '');
        LEntregador.Veiculo := LJSON.GetValue<string>('veiculo', '');
        LEntregador.Placa := LJSON.GetValue<string>('placa', '');
        LEntregador.Disponivel := LJSON.GetValue<Boolean>('disponivel', True);
        LEntregador.Ativo := LJSON.GetValue<Boolean>('ativo', True);
        LEntregador.EntregasEmAndamento :=
          LJSON.GetValue<Integer>('entregas_em_andamento', 0);
        FEntregadores.Add(LEntregador);
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

function TfraEntregadores.EntregadorVisivel(
  const AEntregador: TEntregadorAdmin): Boolean;
begin
  case FFiltroStatus of
    efsDisponiveis: Result := AEntregador.Ativo and AEntregador.Disponivel;
    efsOcupados: Result := AEntregador.Ativo and not AEntregador.Disponivel;
    efsInativos: Result := not AEntregador.Ativo;
  else Result := True;
  end;
end;

procedure TfraEntregadores.PreencherLista;
var
  LEntregador: TEntregadorAdmin; LCard: TRectangle;
  LTexto, LAcoes: TLayout; LNome, LDetalhe, LStatus: TLabel;
  LEditar, LDisponivel, LAtivo: TfraSensorButton;
  LResumo, LStatusTexto, LVeiculo: string;
  I, LPosicao, LExibidos: Integer; LStatusCor: TAlphaColor;
begin
  while FListaConteudo.ChildrenCount > 0 do FListaConteudo.Children[0].Free;
  FSelecionado := -1; LExibidos := 0;
  for LEntregador in FEntregadores do
    if EntregadorVisivel(LEntregador) then Inc(LExibidos);
  FListaConteudo.Height := LExibidos * 68; LPosicao := 0;
  for I := 0 to FEntregadores.Count - 1 do
  begin
    LEntregador := FEntregadores[I];
    if not EntregadorVisivel(LEntregador) then Continue;
    if not LEntregador.Ativo then
    begin LStatusTexto := 'INATIVO'; LStatusCor := $FFFFB454; end
    else if LEntregador.Disponivel then
    begin LStatusTexto := 'DISPONÍVEL'; LStatusCor := $FF45D483; end
    else
    begin LStatusTexto := 'OCUPADO'; LStatusCor := $FF43A5FF; end;
    LVeiculo := LEntregador.Veiculo;
    if LVeiculo.IsEmpty then LVeiculo := 'Veículo não informado';
    if not LEntregador.Placa.IsEmpty then
      LVeiculo := LVeiculo + ' (' + LEntregador.Placa + ')';
    LResumo := LEntregador.Telefone + '  •  ' + LVeiculo +
      Format('  •  %d entrega(s) em andamento', [LEntregador.EntregasEmAndamento]);
    LCard := TRectangle.Create(Self); LCard.Parent := FListaConteudo;
    LCard.Position.Point := PointF(4, LPosicao * 68 + 2);
    LCard.Width := FListaConteudo.Width - 8; LCard.Height := 62;
    LCard.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akRight];
    LCard.Fill.Color := $FF152439; LCard.Stroke.Color := $FF23364D;
    LCard.XRadius := 7; LCard.YRadius := 7; LCard.Tag := I;
    LCard.OnClick := EntregadorClick;
    LAcoes := TLayout.Create(Self); LAcoes.Parent := LCard;
    LAcoes.Align := TAlignLayout.Right; LAcoes.Width := 244;
    LEditar := CriarBotao(LAcoes, '', 38, EditarClick);
    LEditar.Align := TAlignLayout.None; LEditar.Position.Point := PointF(0, 14);
    LEditar.Icone := sbiEditar; LEditar.Tag := I;
    ConfigurarBotaoIcone(LEditar, 'Editar entregador');
    LDisponivel := CriarBotao(LAcoes, '', 38, DisponibilidadeClick);
    LDisponivel.Align := TAlignLayout.None;
    LDisponivel.Position.Point := PointF(46, 14); LDisponivel.Tag := I;
    if LEntregador.Disponivel then
    begin
      LDisponivel.Icone := sbiEntrega;
      ConfigurarBotaoIcone(LDisponivel, 'Marcar como ocupado');
    end
    else
    begin
      LDisponivel.Icone := sbiAtivar;
      ConfigurarBotaoIcone(LDisponivel, 'Marcar como disponível');
    end;
    LAtivo := CriarBotao(LAcoes, '', 38, AtivoClick);
    LAtivo.Align := TAlignLayout.None; LAtivo.Position.Point := PointF(92, 14);
    LAtivo.Tag := I;
    if LEntregador.Ativo then
    begin LAtivo.Icone := sbiBloquear;
      ConfigurarBotaoIcone(LAtivo, 'Desativar entregador'); end
    else
    begin LAtivo.Icone := sbiAtivar;
      ConfigurarBotaoIcone(LAtivo, 'Ativar entregador'); end;
    LStatus := CriarRotulo(LAcoes, LStatusTexto, 136, 0, 96, 62,
      LStatusCor, 9);
    LStatus.TextSettings.HorzAlign := TTextAlign.Trailing; LStatus.HitTest := False;
    LTexto := TLayout.Create(Self); LTexto.Parent := LCard;
    LTexto.Align := TAlignLayout.Client; LTexto.Margins.Left := 14;
    LTexto.Margins.Right := 12; LTexto.HitTest := False;
    LNome := CriarRotulo(LTexto, LEntregador.Nome, 0, 5, 600, 24,
      $FFF4F7FB, 11);
    LNome.Align := TAlignLayout.Top; LNome.HitTest := False;
    LNome.TextSettings.Font.Style := [TFontStyle.fsBold];
    LDetalhe := CriarRotulo(LTexto, LResumo, 0, 31, 800, 22, $FF8795A8, 9);
    LDetalhe.Align := TAlignLayout.Bottom; LDetalhe.Margins.Bottom := 5;
    LDetalhe.HitTest := False; Inc(LPosicao);
  end;
  if LExibidos = 0 then FEstado.Text := 'Nenhum entregador encontrado neste filtro.'
  else if LExibidos = FEntregadores.Count then
    FEstado.Text := Format('%d entregador(es) encontrado(s)', [LExibidos])
  else FEstado.Text := Format('%d de %d entregador(es)',
    [LExibidos, FEntregadores.Count]);
end;

procedure TfraEntregadores.AtualizarFiltros;
begin
  FBtnTodos.Estilo := sbsSecondary; FBtnDisponiveis.Estilo := sbsSecondary;
  FBtnOcupados.Estilo := sbsSecondary; FBtnInativos.Estilo := sbsSecondary;
  case FFiltroStatus of
    efsTodos: FBtnTodos.Estilo := sbsPrimary;
    efsDisponiveis: FBtnDisponiveis.Estilo := sbsPrimary;
    efsOcupados: FBtnOcupados.Estilo := sbsPrimary;
    efsInativos: FBtnInativos.Estilo := sbsPrimary;
  end;
end;

procedure TfraEntregadores.FiltroClick(Sender: TObject);
begin
  if Sender is TfraSensorButton then
  begin
    FFiltroStatus := TEntregadorFiltroStatus(TfraSensorButton(Sender).Tag);
    AtualizarFiltros; PreencherLista;
  end;
end;

function TfraEntregadores.EntregadorSelecionado: TEntregadorAdmin;
begin
  Result := nil;
  if (FSelecionado >= 0) and (FSelecionado < FEntregadores.Count) then
    Result := FEntregadores[FSelecionado];
end;

procedure TfraEntregadores.EntregadorClick(Sender: TObject);
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

procedure TfraEntregadores.NovoClick(Sender: TObject);
begin AbrirEditor(nil); end;

procedure TfraEntregadores.EditarClick(Sender: TObject);
begin
  if Sender is TfraSensorButton then FSelecionado := TfraSensorButton(Sender).Tag;
  AbrirEditor(EntregadorSelecionado);
end;

procedure TfraEntregadores.AbrirEditor(const AEntregador: TEntregadorAdmin);
begin
  if Assigned(AEntregador) then
  begin
    FEditandoId := AEntregador.Id; FTituloEdicao.Text := 'Editar entregador';
    FNome.Text := AEntregador.Nome; FTelefone.Text := AEntregador.Telefone;
    FDocumento.Text := AEntregador.Documento; FVeiculo.Text := AEntregador.Veiculo;
    FPlaca.Text := AEntregador.Placa; FDisponivelEditor := AEntregador.Disponivel;
  end
  else
  begin
    FEditandoId := ''; FTituloEdicao.Text := 'Novo entregador'; FNome.Text := '';
    FTelefone.Text := ''; FDocumento.Text := ''; FVeiculo.Text := '';
    FPlaca.Text := ''; FDisponivelEditor := True;
  end;
  AtualizarDisponibilidadeEditor; FPainelEdicao.Visible := True;
  FPainelEdicao.BringToFront; FNome.SetFocus;
end;

procedure TfraEntregadores.FecharEditor;
begin FPainelEdicao.Visible := False; FEditandoId := ''; end;
procedure TfraEntregadores.CancelarClick(Sender: TObject);
begin FecharEditor; end;

procedure TfraEntregadores.AtualizarDisponibilidadeEditor;
begin
  if FDisponivelEditor then
  begin
    FBtnDisponibilidadeEditor.Texto := 'Disponível';
    FBtnDisponibilidadeEditor.Icone := sbiAtivar;
    FBtnDisponibilidadeEditor.Estilo := sbsPrimary;
  end
  else
  begin
    FBtnDisponibilidadeEditor.Texto := 'Ocupado';
    FBtnDisponibilidadeEditor.Icone := sbiEntrega;
    FBtnDisponibilidadeEditor.Estilo := sbsSecondary;
  end;
end;

procedure TfraEntregadores.DisponibilidadeEditorClick(Sender: TObject);
begin
  FDisponivelEditor := not FDisponivelEditor;
  AtualizarDisponibilidadeEditor;
end;

procedure TfraEntregadores.SalvarClick(Sender: TObject);
var
  LHTTP: TNetHTTPClient; LJSON: TJSONObject; LStream: TStringStream;
  LResposta: IHTTPResponse;
begin
  if FNome.Text.Trim.IsEmpty then
  begin
    TfrmMensagem.Exibir('Campo obrigatório', 'Informe o nome do entregador.', tmAtencao);
    FNome.SetFocus; Exit;
  end;
  if FTelefone.Text.Trim.IsEmpty then
  begin
    TfrmMensagem.Exibir('Campo obrigatório', 'Informe o telefone do entregador.', tmAtencao);
    FTelefone.SetFocus; Exit;
  end;
  LJSON := TJSONObject.Create;
  if FEditandoId.IsEmpty then LJSON.AddPair('empresaId', TSessaoAdmin.EmpresaId);
  LJSON.AddPair('nome', FNome.Text.Trim);
  LJSON.AddPair('telefone', FTelefone.Text.Trim);
  LJSON.AddPair('documento', FDocumento.Text.Trim);
  LJSON.AddPair('veiculo', FVeiculo.Text.Trim);
  LJSON.AddPair('placa', FPlaca.Text.Trim.ToUpper);
  LJSON.AddPair('disponivel', TJSONBool.Create(FDisponivelEditor));
  LHTTP := TNetHTTPClient.Create(nil);
  TSessaoAdmin.ConfigurarCliente(LHTTP);
  LStream := TStringStream.Create(LJSON.ToJSON, TEncoding.UTF8);
  try
    try
      LHTTP.ContentType := 'application/json'; LHTTP.Accept := 'application/json';
      if FEditandoId.IsEmpty then LResposta := LHTTP.Post(URL_ENTREGADORES, LStream)
      else LResposta := LHTTP.Put(URL_ENTREGADORES + '/' + FEditandoId, LStream);
      if not (LResposta.StatusCode in [200, 201]) then
      begin ExibirErroAPI('Não foi possível salvar o entregador', LResposta); Exit; end;
      FecharEditor; CarregarEntregadores;
      TfrmMensagem.Exibir('Entregador salvo', 'Os dados foram salvos com sucesso.', tmSucesso);
    except on E: Exception do
      TfrmMensagem.Exibir('Erro de comunicação', E.Message, tmErro); end;
  finally LStream.Free; LHTTP.Free; LJSON.Free; end;
end;

procedure TfraEntregadores.DisponibilidadeClick(Sender: TObject);
var
  LEntregador: TEntregadorAdmin; LHTTP: TNetHTTPClient;
  LJSON: TJSONObject; LStream: TStringStream; LResposta: IHTTPResponse;
begin
  if Sender is TfraSensorButton then FSelecionado := TfraSensorButton(Sender).Tag;
  LEntregador := EntregadorSelecionado; if not Assigned(LEntregador) then Exit;
  if not LEntregador.Ativo then
  begin
    TfrmMensagem.Exibir('Entregador inativo',
      'Ative o entregador antes de alterar sua disponibilidade.', tmAtencao); Exit;
  end;
  LJSON := TJSONObject.Create;
  LJSON.AddPair('disponivel', TJSONBool.Create(not LEntregador.Disponivel));
  LHTTP := TNetHTTPClient.Create(nil);
  TSessaoAdmin.ConfigurarCliente(LHTTP);
  LStream := TStringStream.Create(LJSON.ToJSON, TEncoding.UTF8);
  try
    try
      LHTTP.ContentType := 'application/json'; LHTTP.Accept := 'application/json';
      LResposta := LHTTP.Patch(URL_ENTREGADORES + '/' + LEntregador.Id +
        '/situacao', LStream);
      if LResposta.StatusCode <> 200 then
      begin ExibirErroAPI('Não foi possível alterar a disponibilidade', LResposta); Exit; end;
      CarregarEntregadores;
    except on E: Exception do
      TfrmMensagem.Exibir('Erro de comunicação', E.Message, tmErro); end;
  finally LStream.Free; LHTTP.Free; LJSON.Free; end;
end;

procedure TfraEntregadores.AtivoClick(Sender: TObject);
var
  LEntregador: TEntregadorAdmin; LHTTP: TNetHTTPClient;
  LJSON: TJSONObject; LStream: TStringStream; LResposta: IHTTPResponse;
begin
  if Sender is TfraSensorButton then FSelecionado := TfraSensorButton(Sender).Tag;
  LEntregador := EntregadorSelecionado; if not Assigned(LEntregador) then Exit;
  LJSON := TJSONObject.Create;
  LJSON.AddPair('ativo', TJSONBool.Create(not LEntregador.Ativo));
  LHTTP := TNetHTTPClient.Create(nil);
  TSessaoAdmin.ConfigurarCliente(LHTTP);
  LStream := TStringStream.Create(LJSON.ToJSON, TEncoding.UTF8);
  try
    try
      LHTTP.ContentType := 'application/json'; LHTTP.Accept := 'application/json';
      LResposta := LHTTP.Patch(URL_ENTREGADORES + '/' + LEntregador.Id +
        '/situacao', LStream);
      if LResposta.StatusCode <> 200 then
      begin ExibirErroAPI('Não foi possível alterar o entregador', LResposta); Exit; end;
      CarregarEntregadores;
    except on E: Exception do
      TfrmMensagem.Exibir('Erro de comunicação', E.Message, tmErro); end;
  finally LStream.Free; LHTTP.Free; LJSON.Free; end;
end;

procedure TfraEntregadores.BuscarClick(Sender: TObject);
begin FTimerBusca.Enabled := False; CarregarEntregadores; end;
procedure TfraEntregadores.BuscaChange(Sender: TObject);
begin FTimerBusca.Enabled := False; FTimerBusca.Enabled := True; end;
procedure TfraEntregadores.TimerBuscaTimer(Sender: TObject);
begin FTimerBusca.Enabled := False; CarregarEntregadores; end;

procedure TfraEntregadores.BuscaKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin Key := 0; KeyChar := #0; FTimerBusca.Enabled := False;
    CarregarEntregadores; end;
end;

procedure TfraEntregadores.ExibirErroAPI(const ATitulo: string;
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
