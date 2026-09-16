unit uFrameClientes;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.JSON, System.Net.URLClient, System.Net.HttpClient,
  System.Net.HttpClientComponent,
  System.NetEncoding, System.Generics.Collections,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs,
  FMX.StdCtrls, FMX.Objects, FMX.Layouts, FMX.Controls.Presentation,
  FMX.Edit, FMX.Memo, FMX.ListBox, uFrameSensorButton;

type
  TClienteFiltroStatus = (cfsTodos, cfsAtivos, cfsInativos, cfsBloqueados);

  TClienteAdmin = class
  public
    Id, Nome, Telefone, Email, Observacoes: string;
    Ativo, Bloqueado: Boolean;
  end;

  TfraClientes = class(TFrame)
    rctFundo: TRectangle;
    lytPrincipal: TLayout;
    lytCabecalho: TLayout;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    lytConteudo: TLayout;
  private
    FClientes: TObjectList<TClienteAdmin>;
    FCarregado: Boolean;
    FEditandoId: string;
    FBarra: TLayout;
    FFiltros: TLayout;
    FBusca: TEdit;
    FLista: TVertScrollBox;
    FListaConteudo: TLayout;
    FSelecionado: Integer;
    FEstado: TLabel;
    FBtnNovo, FBtnAtualizar: TfraSensorButton;
    FBtnFiltroTodos, FBtnFiltroAtivos, FBtnFiltroInativos,
      FBtnFiltroBloqueados: TfraSensorButton;
    FTimerBusca: TTimer;
    FFiltroStatus: TClienteFiltroStatus;
    FPainelEdicao: TRectangle;
    FTituloEdicao: TLabel;
    FNome, FTelefone, FEmail: TEdit;
    FObservacoes: TMemo;
    FBtnSalvar, FBtnCancelar: TfraSensorButton;
    procedure MontarTela;
    function CriarBotao(const AParent: TFmxObject; const ATexto: string;
      const AWidth: Single; const AOnClick: TNotifyEvent): TfraSensorButton;
    procedure ConfigurarBotaoSomenteIcone(const ABotao: TfraSensorButton;
      const AHint: string);
    function CriarRotulo(const AParent: TFmxObject; const ATexto: string;
      const AX, AY, AWidth, AHeight: Single; const ACor: TAlphaColor;
      const ATamanho: Single): TLabel;
    function ClienteSelecionado: TClienteAdmin;
    procedure AtualizarAcoes;
    procedure AtualizarFiltros;
    function ClienteVisivel(const ACliente: TClienteAdmin): Boolean;
    procedure PreencherLista;
    procedure AbrirEditor(const ACliente: TClienteAdmin);
    procedure FecharEditor;
    procedure ExibirErroAPI(const ATitulo: string; const AResposta: IHTTPResponse);
    function MontarJSONCliente: TJSONObject;
    procedure BuscarClick(Sender: TObject);
    procedure BuscaChange(Sender: TObject);
    procedure TimerBuscaTimer(Sender: TObject);
    procedure FiltroClick(Sender: TObject);
    procedure MemoApplyStyleLookup(Sender: TObject);
    procedure BuscaKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure ClienteClick(Sender: TObject);
    procedure NovoClick(Sender: TObject);
    procedure EditarClick(Sender: TObject);
    procedure AtivoClick(Sender: TObject);
    procedure BloqueadoClick(Sender: TObject);
    procedure SalvarClick(Sender: TObject);
    procedure CancelarClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure PrepararTela;
    procedure CarregarClientes;
  end;

implementation

{$R *.fmx}

uses uMensagem, uSessaoAdmin, uNavegacaoCampos, uApiConfig;

function URL_CLIENTES: string;
begin
  Result := TApiConfig.Url('/api/clientes');
end;

constructor TfraClientes.Create(AOwner: TComponent);
begin
  inherited;
  FClientes := TObjectList<TClienteAdmin>.Create(True);
  FCarregado := False;
  FEditandoId := '';
  FSelecionado := -1;
  FFiltroStatus := cfsTodos;
  MontarTela;
end;

destructor TfraClientes.Destroy;
begin
  FClientes.Free;
  inherited;
end;

function TfraClientes.CriarRotulo(const AParent: TFmxObject;
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

function TfraClientes.CriarBotao(const AParent: TFmxObject;
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

procedure TfraClientes.ConfigurarBotaoSomenteIcone(
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
    (ABotao.Height - ABotao.pthIcone.Height) / 2
  );
  ABotao.Hint := AHint;
  ABotao.ShowHint := True;
  ABotao.rctFundo.Hint := AHint;
  ABotao.rctFundo.ShowHint := True;
end;

procedure TfraClientes.MontarTela;
var
  LListaFundo: TRectangle;
  LForm: TLayout;
  LBuscaFundo, LCampo: TRectangle;
begin
  FBarra := TLayout.Create(Self);
  FBarra.Parent := lytConteudo;
  FBarra.Align := TAlignLayout.Top;
  FBarra.Height := 44;
  FBarra.Margins.Bottom := 12;

  FBtnNovo := CriarBotao(FBarra, '+ Novo cliente', 126, NovoClick);
  FBtnNovo.Align := TAlignLayout.Right;
  FBtnNovo.Estilo := sbsPrimary;
  FBtnNovo.Icone := sbiUsuario;
  FBtnAtualizar := CriarBotao(FBarra, 'Buscar', 82, BuscarClick);
  FBtnAtualizar.Align := TAlignLayout.Right;
  FBtnAtualizar.Width := 96;
  FBtnAtualizar.Icone := sbiPesquisar;

  LBuscaFundo := TRectangle.Create(Self);
  LBuscaFundo.Parent := FBarra;
  LBuscaFundo.Align := TAlignLayout.Client;
  LBuscaFundo.Margins.Right := 12;
  LBuscaFundo.Fill.Color := $FF121F30;
  LBuscaFundo.Stroke.Color := $FF2A405B;
  LBuscaFundo.XRadius := 8;
  LBuscaFundo.YRadius := 8;
  FBusca := TEdit.Create(Self);
  FBusca.Parent := LBuscaFundo;
  FBusca.Align := TAlignLayout.Client;
  FBusca.Margins.Left := 12;
  FBusca.Margins.Right := 12;
  FBusca.StyleLookup := 'transparentedit';
  FBusca.TextPrompt := 'Buscar por nome, telefone ou e-mail';
  FBusca.StyledSettings := [];
  FBusca.TextSettings.Font.Family := 'Manrope';
  FBusca.TextSettings.FontColor := $FFF4F7FB;
  FBusca.OnKeyDown := BuscaKeyDown;
  FBusca.OnTyping := BuscaChange;
  FBusca.OnChangeTracking := BuscaChange;

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
  FBtnFiltroTodos := CriarBotao(FFiltros, 'Todos', 94, FiltroClick);
  FBtnFiltroTodos.Align := TAlignLayout.None;
  FBtnFiltroTodos.Position.Point := PointF(118, 2);
  FBtnFiltroTodos.Height := 36;
  FBtnFiltroTodos.Icone := sbiRelatorio;
  FBtnFiltroTodos.Tag := Ord(cfsTodos);
  FBtnFiltroAtivos := CriarBotao(FFiltros, 'Ativos', 98, FiltroClick);
  FBtnFiltroAtivos.Align := TAlignLayout.None;
  FBtnFiltroAtivos.Position.Point := PointF(220, 2);
  FBtnFiltroAtivos.Height := 36;
  FBtnFiltroAtivos.Icone := sbiAtivar;
  FBtnFiltroAtivos.Tag := Ord(cfsAtivos);
  FBtnFiltroInativos := CriarBotao(FFiltros, 'Inativos', 108, FiltroClick);
  FBtnFiltroInativos.Align := TAlignLayout.None;
  FBtnFiltroInativos.Position.Point := PointF(326, 2);
  FBtnFiltroInativos.Height := 36;
  FBtnFiltroInativos.Icone := sbiCancelar;
  FBtnFiltroInativos.Tag := Ord(cfsInativos);
  FBtnFiltroBloqueados := CriarBotao(FFiltros, 'Bloqueados', 126, FiltroClick);
  FBtnFiltroBloqueados.Align := TAlignLayout.None;
  FBtnFiltroBloqueados.Position.Point := PointF(442, 2);
  FBtnFiltroBloqueados.Height := 36;
  FBtnFiltroBloqueados.Icone := sbiBloquear;
  FBtnFiltroBloqueados.Tag := Ord(cfsBloqueados);
  AtualizarFiltros;

  FPainelEdicao := TRectangle.Create(Self);
  FPainelEdicao.Parent := lytConteudo;
  FPainelEdicao.Align := TAlignLayout.Right;
  FPainelEdicao.Width := 350;
  FPainelEdicao.Margins.Left := 14;
  FPainelEdicao.Fill.Color := $FF111E2E;
  FPainelEdicao.Stroke.Color := $FF2A405B;
  FPainelEdicao.XRadius := 10;
  FPainelEdicao.YRadius := 10;
  FPainelEdicao.Visible := False;
  FTituloEdicao := CriarRotulo(FPainelEdicao, 'Novo cliente', 20, 16, 310,
    30, $FFF4F7FB, 16);
  FTituloEdicao.TextSettings.Font.Style := [TFontStyle.fsBold];

  LForm := TLayout.Create(Self);
  LForm.Parent := FPainelEdicao;
  LForm.Align := TAlignLayout.Client;
  CriarRotulo(LForm, 'Nome *', 20, 58, 310, 20, $FF9CAABC, 10);
  LCampo := TRectangle.Create(Self);
  LCampo.Parent := LForm; LCampo.Position.Point := PointF(20, 80);
  LCampo.Width := 310; LCampo.Height := 38;
  LCampo.Fill.Color := $FF152439; LCampo.Stroke.Color := $FF2A405B;
  LCampo.XRadius := 6; LCampo.YRadius := 6;
  FNome := TEdit.Create(Self);
  FNome.Parent := LCampo; FNome.Align := TAlignLayout.Client;
  FNome.Margins.Left := 10; FNome.Margins.Right := 10;
  FNome.StyleLookup := 'transparentedit';
  FNome.StyledSettings := []; FNome.TextSettings.FontColor := $FFF4F7FB;
  FNome.TextPrompt := 'Nome do cliente';
  CriarRotulo(LForm, 'Telefone *', 20, 128, 310, 20, $FF9CAABC, 10);
  LCampo := TRectangle.Create(Self);
  LCampo.Parent := LForm; LCampo.Position.Point := PointF(20, 150);
  LCampo.Width := 310; LCampo.Height := 38;
  LCampo.Fill.Color := $FF152439; LCampo.Stroke.Color := $FF2A405B;
  LCampo.XRadius := 6; LCampo.YRadius := 6;
  FTelefone := TEdit.Create(Self);
  FTelefone.Parent := LCampo; FTelefone.Align := TAlignLayout.Client;
  FTelefone.Margins.Left := 10; FTelefone.Margins.Right := 10;
  FTelefone.StyleLookup := 'transparentedit';
  FTelefone.StyledSettings := []; FTelefone.TextSettings.FontColor := $FFF4F7FB;
  FTelefone.TextPrompt := '(00) 00000-0000';
  FTelefone.KeyboardType := TVirtualKeyboardType.PhonePad;
  CriarRotulo(LForm, 'E-mail', 20, 198, 310, 20, $FF9CAABC, 10);
  LCampo := TRectangle.Create(Self);
  LCampo.Parent := LForm; LCampo.Position.Point := PointF(20, 220);
  LCampo.Width := 310; LCampo.Height := 38;
  LCampo.Fill.Color := $FF152439; LCampo.Stroke.Color := $FF2A405B;
  LCampo.XRadius := 6; LCampo.YRadius := 6;
  FEmail := TEdit.Create(Self);
  FEmail.Parent := LCampo; FEmail.Align := TAlignLayout.Client;
  FEmail.Margins.Left := 10; FEmail.Margins.Right := 10;
  FEmail.StyleLookup := 'transparentedit';
  FEmail.StyledSettings := []; FEmail.TextSettings.FontColor := $FFF4F7FB;
  FEmail.TextPrompt := 'cliente@exemplo.com';
  FEmail.KeyboardType := TVirtualKeyboardType.EmailAddress;
  CriarRotulo(LForm, 'Observações', 20, 268, 310, 20, $FF9CAABC, 10);
  LCampo := TRectangle.Create(Self);
  LCampo.Parent := LForm; LCampo.Position.Point := PointF(20, 290);
  LCampo.Width := 310; LCampo.Height := 100;
  LCampo.Fill.Color := $FF152439; LCampo.Stroke.Color := $FF2A405B;
  LCampo.XRadius := 6; LCampo.YRadius := 6;
  FObservacoes := TMemo.Create(Self);
  FObservacoes.Parent := LCampo; FObservacoes.Align := TAlignLayout.Client;
  FObservacoes.Margins.Left := 8; FObservacoes.Margins.Right := 8;
  FObservacoes.OnApplyStyleLookup := MemoApplyStyleLookup;
  FObservacoes.StyledSettings := [];
  FObservacoes.TextSettings.FontColor := $FFF4F7FB;
  TNavegacaoCampos.Aplicar(Self, [FNome, FTelefone, FEmail, FObservacoes]);
  FBtnSalvar := CriarBotao(LForm, 'Salvar', 112, SalvarClick);
  FBtnSalvar.Icone := sbiSalvar;
  FBtnSalvar.Align := TAlignLayout.None;
  FBtnSalvar.Position.Point := PointF(218, 410); FBtnSalvar.Height := 40;
  FBtnCancelar := CriarBotao(LForm, 'Cancelar', 98, CancelarClick);
  FBtnCancelar.Icone := sbiCancelar;
  FBtnCancelar.Align := TAlignLayout.None;
  FBtnCancelar.Position.Point := PointF(20, 410); FBtnCancelar.Height := 40;

  LListaFundo := TRectangle.Create(Self);
  LListaFundo.Parent := lytConteudo;
  LListaFundo.Align := TAlignLayout.Client;
  LListaFundo.Fill.Color := $FF111E2E;
  LListaFundo.Stroke.Color := $FF23364D;
  LListaFundo.XRadius := 10; LListaFundo.YRadius := 10;
  FEstado := CriarRotulo(LListaFundo, 'Carregando clientes...', 20, 16,
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
  AtualizarAcoes;
end;

procedure TfraClientes.PrepararTela;
begin
  if not FCarregado then CarregarClientes;
end;

procedure TfraClientes.CarregarClientes;
var
  LHTTP: TNetHTTPClient;
  LResposta: IHTTPResponse;
  LValor, LItem: TJSONValue;
  LArray: TJSONArray;
  LJSON: TJSONObject;
  LCliente: TClienteAdmin;
  LURL: string;
begin
  FEstado.Text := 'Carregando clientes...';
  FLista.Enabled := False;
  LHTTP := TNetHTTPClient.Create(nil);
  TSessaoAdmin.ConfigurarCliente(LHTTP);
  LValor := nil;
  try
    try
      LHTTP.Accept := 'application/json';
      LURL := URL_CLIENTES + '?empresaId=' + TNetEncoding.URL.Encode(TSessaoAdmin.EmpresaId);
      if not FBusca.Text.Trim.IsEmpty then
        LURL := LURL + '&busca=' + TNetEncoding.URL.Encode(FBusca.Text.Trim);
      LResposta := LHTTP.Get(LURL);
      if LResposta.StatusCode <> 200 then
      begin
        ExibirErroAPI('Erro ao carregar clientes', LResposta);
        FEstado.Text := 'Não foi possível carregar os clientes.';
        Exit;
      end;
      LValor := TJSONObject.ParseJSONValue(LResposta.ContentAsString(TEncoding.UTF8));
      if not (LValor is TJSONObject) then
        raise Exception.Create('Resposta inválida recebida da API.');
      LArray := TJSONObject(LValor).GetValue<TJSONArray>('clientes');
      FClientes.Clear;
      for LItem in LArray do
      begin
        LJSON := LItem as TJSONObject;
        LCliente := TClienteAdmin.Create;
        LCliente.Id := LJSON.GetValue<string>('id', '');
        LCliente.Nome := LJSON.GetValue<string>('nome', '');
        LCliente.Telefone := LJSON.GetValue<string>('telefone', '');
        LCliente.Email := LJSON.GetValue<string>('email', '');
        LCliente.Observacoes := LJSON.GetValue<string>('observacoes', '');
        LCliente.Ativo := LJSON.GetValue<Boolean>('ativo', True);
        LCliente.Bloqueado := LJSON.GetValue<Boolean>('bloqueado', False);
        FClientes.Add(LCliente);
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

procedure TfraClientes.PreencherLista;
var
  LCliente: TClienteAdmin;
  LCard: TRectangle;
  LTexto, LAcoes: TLayout;
  LNome, LContatoLabel, LStatusLabel: TLabel;
  LBtnEditar, LBtnAtivo, LBtnBloquear: TfraSensorButton;
  LStatus, LContato: string;
  I, LPosicao, LExibidos: Integer;
begin
  while FListaConteudo.ChildrenCount > 0 do
    FListaConteudo.Children[0].Free;
  FSelecionado := -1;
  LExibidos := 0;
  for LCliente in FClientes do
    if ClienteVisivel(LCliente) then Inc(LExibidos);
  FListaConteudo.Height := LExibidos * 66;
  LPosicao := 0;
  for I := 0 to FClientes.Count - 1 do
  begin
    LCliente := FClientes[I];
    if not ClienteVisivel(LCliente) then Continue;
    if not LCliente.Ativo then LStatus := 'INATIVO'
    else if LCliente.Bloqueado then LStatus := 'BLOQUEADO'
    else LStatus := 'ATIVO';
    LContato := LCliente.Telefone;
    if not LCliente.Email.IsEmpty then LContato := LContato + '  •  ' + LCliente.Email;

    LCard := TRectangle.Create(Self);
    LCard.Parent := FListaConteudo;
    LCard.Position.Point := PointF(4, LPosicao * 66 + 2);
    LCard.Width := FListaConteudo.Width - 8;
    LCard.Height := 60;
    LCard.Anchors := [TAnchorKind.akLeft, TAnchorKind.akTop, TAnchorKind.akRight];
    LCard.Fill.Color := $FF152439;
    LCard.Stroke.Color := $FF23364D;
    LCard.XRadius := 7; LCard.YRadius := 7;
    LCard.Tag := I;
    LCard.OnClick := ClienteClick;

    LAcoes := TLayout.Create(Self);
    LAcoes.Parent := LCard;
    LAcoes.Align := TAlignLayout.Right;
    LAcoes.Width := 210;

    LBtnEditar := CriarBotao(LAcoes, '', 38, EditarClick);
    LBtnEditar.Align := TAlignLayout.None;
    LBtnEditar.Position.Point := PointF(0, 13);
    LBtnEditar.Icone := sbiEditar;
    LBtnEditar.Tag := I;
    ConfigurarBotaoSomenteIcone(LBtnEditar, 'Editar cliente');

    LBtnAtivo := CriarBotao(LAcoes, '', 38, AtivoClick);
    LBtnAtivo.Align := TAlignLayout.None;
    LBtnAtivo.Position.Point := PointF(46, 13);
    LBtnAtivo.Tag := I;
    if LCliente.Ativo then
    begin
      LBtnAtivo.Icone := sbiCancelar;
      ConfigurarBotaoSomenteIcone(LBtnAtivo, 'Desativar cliente');
    end
    else
    begin
      LBtnAtivo.Icone := sbiAtivar;
      ConfigurarBotaoSomenteIcone(LBtnAtivo, 'Ativar cliente');
    end;

    LBtnBloquear := CriarBotao(LAcoes, '', 38, BloqueadoClick);
    LBtnBloquear.Align := TAlignLayout.None;
    LBtnBloquear.Position.Point := PointF(92, 13);
    LBtnBloquear.Tag := I;
    if LCliente.Bloqueado then
    begin
      LBtnBloquear.Icone := sbiAtivar;
      ConfigurarBotaoSomenteIcone(LBtnBloquear, 'Desbloquear cliente');
    end
    else
    begin
      LBtnBloquear.Icone := sbiBloquear;
      ConfigurarBotaoSomenteIcone(LBtnBloquear, 'Bloquear cliente');
    end;

    LStatusLabel := CriarRotulo(LAcoes, LStatus, 138, 0, 58, 60,
      $FF45D483, 9);
    LStatusLabel.TextSettings.HorzAlign := TTextAlign.Trailing;
    LStatusLabel.HitTest := False;

    LTexto := TLayout.Create(Self);
    LTexto.Parent := LCard;
    LTexto.Align := TAlignLayout.Client;
    LTexto.Margins.Left := 14;
    LTexto.Margins.Right := 12;
    LTexto.HitTest := False;
    LNome := CriarRotulo(LTexto, LCliente.Nome, 0, 5, 600,
      24, $FFF4F7FB, 11);
    LNome.Align := TAlignLayout.Top;
    LNome.HitTest := False;
    LNome.TextSettings.Font.Style := [TFontStyle.fsBold];
    LContatoLabel := CriarRotulo(LTexto, LContato, 0, 30, 800,
      22, $FF8795A8, 9);
    LContatoLabel.Align := TAlignLayout.Bottom;
    LContatoLabel.Margins.Bottom := 5;
    LContatoLabel.HitTest := False;
    if LStatus = 'ATIVO' then
      LStatusLabel.TextSettings.FontColor := $FF45D483
    else if LStatus = 'BLOQUEADO' then
      LStatusLabel.TextSettings.FontColor := $FFFF6B75
    else
      LStatusLabel.TextSettings.FontColor := $FFFFB454;
    Inc(LPosicao);
  end;
  if LExibidos = 0 then FEstado.Text := 'Nenhum cliente encontrado neste filtro.'
  else if LExibidos = FClientes.Count then
    FEstado.Text := Format('%d cliente(s) encontrado(s)', [LExibidos])
  else
    FEstado.Text := Format('%d de %d cliente(s)', [LExibidos, FClientes.Count]);
  AtualizarAcoes;
end;

function TfraClientes.ClienteVisivel(const ACliente: TClienteAdmin): Boolean;
begin
  case FFiltroStatus of
    cfsAtivos:
      Result := ACliente.Ativo and not ACliente.Bloqueado;
    cfsInativos:
      Result := not ACliente.Ativo;
    cfsBloqueados:
      Result := ACliente.Bloqueado;
  else
    Result := True;
  end;
end;

procedure TfraClientes.AtualizarFiltros;
begin
  FBtnFiltroTodos.Estilo := sbsSecondary;
  FBtnFiltroAtivos.Estilo := sbsSecondary;
  FBtnFiltroInativos.Estilo := sbsSecondary;
  FBtnFiltroBloqueados.Estilo := sbsSecondary;
  case FFiltroStatus of
    cfsTodos: FBtnFiltroTodos.Estilo := sbsPrimary;
    cfsAtivos: FBtnFiltroAtivos.Estilo := sbsPrimary;
    cfsInativos: FBtnFiltroInativos.Estilo := sbsPrimary;
    cfsBloqueados: FBtnFiltroBloqueados.Estilo := sbsPrimary;
  end;
end;

procedure TfraClientes.FiltroClick(Sender: TObject);
begin
  if not (Sender is TfraSensorButton) then Exit;
  FFiltroStatus := TClienteFiltroStatus(TfraSensorButton(Sender).Tag);
  AtualizarFiltros;
  PreencherLista;
end;

function TfraClientes.ClienteSelecionado: TClienteAdmin;
begin
  Result := nil;
  if (FSelecionado >= 0) and (FSelecionado < FClientes.Count) then
    Result := FClientes[FSelecionado];
end;

procedure TfraClientes.AtualizarAcoes;
begin
  { As ações pertencem a cada linha e são atualizadas ao recarregar a lista. }
end;

procedure TfraClientes.ClienteClick(Sender: TObject);
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
  AtualizarAcoes;
end;
procedure TfraClientes.BuscarClick(Sender: TObject);
begin
  FTimerBusca.Enabled := False;
  CarregarClientes;
end;
procedure TfraClientes.NovoClick(Sender: TObject); begin AbrirEditor(nil); end;
procedure TfraClientes.EditarClick(Sender: TObject);
begin
  if Sender is TfraSensorButton then
    FSelecionado := TfraSensorButton(Sender).Tag;
  AbrirEditor(ClienteSelecionado);
end;

procedure TfraClientes.BuscaKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    Key := 0;
    KeyChar := #0;
    FTimerBusca.Enabled := False;
    CarregarClientes;
  end;
end;

procedure TfraClientes.BuscaChange(Sender: TObject);
begin
  FTimerBusca.Enabled := False;
  FTimerBusca.Enabled := True;
end;

procedure TfraClientes.TimerBuscaTimer(Sender: TObject);
begin
  FTimerBusca.Enabled := False;
  CarregarClientes;
end;

procedure TfraClientes.MemoApplyStyleLookup(Sender: TObject);
var
  LFundoMemo: TControl;
begin
  if FObservacoes.FindStyleResource<TControl>('background', LFundoMemo) then
  begin
    LFundoMemo.Opacity := 0;
    LFundoMemo.HitTest := False;
  end;
end;

procedure TfraClientes.AbrirEditor(const ACliente: TClienteAdmin);
begin
  if Assigned(ACliente) then
  begin
    FEditandoId := ACliente.Id; FTituloEdicao.Text := 'Editar cliente';
    FNome.Text := ACliente.Nome; FTelefone.Text := ACliente.Telefone;
    FEmail.Text := ACliente.Email; FObservacoes.Text := ACliente.Observacoes;
  end
  else
  begin
    FEditandoId := ''; FTituloEdicao.Text := 'Novo cliente';
    FNome.Text := ''; FTelefone.Text := ''; FEmail.Text := ''; FObservacoes.Text := '';
  end;
  FPainelEdicao.Visible := True; FPainelEdicao.BringToFront; FNome.SetFocus;
end;

procedure TfraClientes.FecharEditor;
begin FPainelEdicao.Visible := False; FEditandoId := ''; end;
procedure TfraClientes.CancelarClick(Sender: TObject); begin FecharEditor; end;

function TfraClientes.MontarJSONCliente: TJSONObject;
begin
  Result := TJSONObject.Create;
  if FEditandoId.IsEmpty then Result.AddPair('empresaId', TSessaoAdmin.EmpresaId);
  Result.AddPair('nome', FNome.Text.Trim);
  Result.AddPair('telefone', FTelefone.Text.Trim);
  Result.AddPair('email', FEmail.Text.Trim);
  Result.AddPair('observacoes', FObservacoes.Text.Trim);
end;

procedure TfraClientes.SalvarClick(Sender: TObject);
var
  LHTTP: TNetHTTPClient; LJSON: TJSONObject; LStream: TStringStream;
  LResposta: IHTTPResponse;
begin
  if FNome.Text.Trim.IsEmpty then begin
    TfrmMensagem.Exibir('Campo obrigatório', 'Informe o nome do cliente.', tmAtencao);
    FNome.SetFocus; Exit; end;
  if FTelefone.Text.Trim.IsEmpty then begin
    TfrmMensagem.Exibir('Campo obrigatório', 'Informe o telefone do cliente.', tmAtencao);
    FTelefone.SetFocus; Exit; end;
  LHTTP := TNetHTTPClient.Create(nil); TSessaoAdmin.ConfigurarCliente(LHTTP); LJSON := MontarJSONCliente;
  LStream := TStringStream.Create(LJSON.ToJSON, TEncoding.UTF8);
  try
    try
      LHTTP.ContentType := 'application/json'; LHTTP.Accept := 'application/json';
      if FEditandoId.IsEmpty then LResposta := LHTTP.Post(URL_CLIENTES, LStream)
      else LResposta := LHTTP.Put(URL_CLIENTES + '/' + FEditandoId, LStream);
      if not (LResposta.StatusCode in [200, 201]) then begin
        ExibirErroAPI('Não foi possível salvar o cliente', LResposta); Exit; end;
      FecharEditor; CarregarClientes;
      TfrmMensagem.Exibir('Cliente salvo', 'Os dados foram salvos com sucesso.', tmSucesso);
    except on E: Exception do TfrmMensagem.Exibir('Erro de comunicação', E.Message, tmErro); end;
  finally LStream.Free; LJSON.Free; LHTTP.Free; end;
end;

procedure TfraClientes.AtivoClick(Sender: TObject);
var LCliente: TClienteAdmin; LHTTP: TNetHTTPClient; LJSON: TJSONObject;
  LStream: TStringStream; LResposta: IHTTPResponse;
begin
  if Sender is TfraSensorButton then
    FSelecionado := TfraSensorButton(Sender).Tag;
  LCliente := ClienteSelecionado; if not Assigned(LCliente) then Exit;
  LHTTP := TNetHTTPClient.Create(nil); TSessaoAdmin.ConfigurarCliente(LHTTP); LJSON := TJSONObject.Create;
  LJSON.AddPair('ativo', TJSONBool.Create(not LCliente.Ativo));
  LStream := TStringStream.Create(LJSON.ToJSON, TEncoding.UTF8);
  try try
    LHTTP.ContentType := 'application/json'; LHTTP.Accept := 'application/json';
    LResposta := LHTTP.Patch(URL_CLIENTES + '/' + LCliente.Id + '/situacao', LStream);
    if LResposta.StatusCode <> 200 then begin ExibirErroAPI('Não foi possível alterar o cliente', LResposta); Exit; end;
    CarregarClientes;
  except on E: Exception do TfrmMensagem.Exibir('Erro de comunicação', E.Message, tmErro); end;
  finally LStream.Free; LJSON.Free; LHTTP.Free; end;
end;

procedure TfraClientes.BloqueadoClick(Sender: TObject);
var LCliente: TClienteAdmin; LHTTP: TNetHTTPClient; LJSON: TJSONObject;
  LStream: TStringStream; LResposta: IHTTPResponse;
begin
  if Sender is TfraSensorButton then
    FSelecionado := TfraSensorButton(Sender).Tag;
  LCliente := ClienteSelecionado; if not Assigned(LCliente) then Exit;
  LHTTP := TNetHTTPClient.Create(nil); TSessaoAdmin.ConfigurarCliente(LHTTP); LJSON := TJSONObject.Create;
  LJSON.AddPair('bloqueado', TJSONBool.Create(not LCliente.Bloqueado));
  LStream := TStringStream.Create(LJSON.ToJSON, TEncoding.UTF8);
  try try
    LHTTP.ContentType := 'application/json'; LHTTP.Accept := 'application/json';
    LResposta := LHTTP.Patch(URL_CLIENTES + '/' + LCliente.Id + '/situacao', LStream);
    if LResposta.StatusCode <> 200 then begin ExibirErroAPI('Não foi possível alterar o cliente', LResposta); Exit; end;
    CarregarClientes;
  except on E: Exception do TfrmMensagem.Exibir('Erro de comunicação', E.Message, tmErro); end;
  finally LStream.Free; LJSON.Free; LHTTP.Free; end;
end;

procedure TfraClientes.ExibirErroAPI(const ATitulo: string; const AResposta: IHTTPResponse);
var LValor: TJSONValue; LMensagem: string;
begin
  LMensagem := 'A API retornou o código ' + IntToStr(AResposta.StatusCode) + '.';
  LValor := TJSONObject.ParseJSONValue(AResposta.ContentAsString(TEncoding.UTF8));
  try if LValor is TJSONObject then
    LMensagem := TJSONObject(LValor).GetValue<string>('erro', LMensagem);
  finally LValor.Free; end;
  TfrmMensagem.Exibir(ATitulo, LMensagem, tmErro);
end;

end.
