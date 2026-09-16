unit uFrameUsuarios;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.JSON,
  System.Net.URLClient, System.Net.HttpClient, System.Net.HttpClientComponent,
  System.NetEncoding, System.Generics.Collections,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Objects,
  FMX.Layouts, FMX.Controls.Presentation, FMX.Edit, FMX.ListBox,
  uFrameSensorButton;

type
  TEmpresaUsuarioAdmin = class
  public
    Id, Nome: string;
    Principal: Boolean;
  end;

  TUsuarioAdmin = class
  public
    Id, Nome, Email, Tipo: string;
    Ativo: Boolean;
    Empresas: TObjectList<TEmpresaUsuarioAdmin>;
    constructor Create;
    destructor Destroy; override;
    function PossuiEmpresa(const AId: string): Boolean;
    function EmpresaPrincipal: string;
  end;

  TfraUsuarios = class(TFrame)
    rctFundo: TRectangle;
    lytPrincipal, lytCabecalho, lytConteudo: TLayout;
    lblTitulo, lblSubtitulo: TLabel;
  private
    FUsuarios: TObjectList<TUsuarioAdmin>;
    FEmpresas: TObjectList<TEmpresaUsuarioAdmin>;
    FChecksEmpresas: TObjectList<TCheckBox>;
    FBusca, FNome, FEmail, FSenha: TEdit;
    FTipo, FPrincipal: TComboBox;
    FLista, FEmpresasScroll, FEditorScroll: TVertScrollBox;
    FListaConteudo, FEditorConteudo: TLayout;
    FPainelEditor: TRectangle;
    FEstado, FTituloEditor: TLabel;
    FBtnNovo, FBtnBuscar, FBtnSalvar, FBtnCancelar: TfraSensorButton;
    FTimer: TTimer;
    FEditandoId: string;
    FCarregado: Boolean;
    procedure MontarTela;
    function Rotulo(const Parent: TFmxObject; const Texto: string;
      X, Y, W, H: Single; Cor: TAlphaColor; Tamanho: Single): TLabel;
    function Botao(const Parent: TFmxObject; const Texto: string; Largura: Single;
      Click: TNotifyEvent): TfraSensorButton;
    function Campo(const Parent: TFmxObject; const Titulo, Prompt: string;
      Y: Single): TEdit;
    procedure BotaoIcone(const B: TfraSensorButton; const Dica: string);
    procedure PrepararComboEscuro(const Combo: TComboBox;
      const Fundo: TRectangle);
    procedure ComboVisualChange(Sender: TObject);
    procedure AtualizarComboVisual(const Combo: TComboBox);
    procedure CarregarEmpresas;
    procedure CarregarUsuarios;
    procedure PreencherLista;
    procedure PreencherEmpresasEditor(const Usuario: TUsuarioAdmin);
    procedure AbrirEditor(const Usuario: TUsuarioAdmin);
    procedure FecharEditor;
    procedure NovoClick(Sender: TObject);
    procedure EditarClick(Sender: TObject);
    procedure SituacaoClick(Sender: TObject);
    procedure SalvarClick(Sender: TObject);
    procedure CancelarClick(Sender: TObject);
    procedure BuscarClick(Sender: TObject);
    procedure BuscaChange(Sender: TObject);
    procedure TimerBusca(Sender: TObject);
    procedure BuscaKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    function MensagemResposta(const Resposta: IHTTPResponse;
      const Padrao: string): string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure PrepararTela;
  end;

implementation

{$R *.fmx}

uses uMensagem, uSessaoAdmin, uNavegacaoCampos, uApiConfig;

function URL_USUARIOS: string;
begin
  Result := TApiConfig.Url('/api/usuarios');
end;

function URL_EMPRESAS: string;
begin
  Result := TApiConfig.Url('/api/empresas');
end;

constructor TUsuarioAdmin.Create;
begin
  inherited;
  Empresas := TObjectList<TEmpresaUsuarioAdmin>.Create(True);
end;

destructor TUsuarioAdmin.Destroy;
begin
  Empresas.Free;
  inherited;
end;

function TUsuarioAdmin.PossuiEmpresa(const AId: string): Boolean;
var E: TEmpresaUsuarioAdmin;
begin
  Result := False;
  for E in Empresas do
    if SameText(E.Id, AId) then Exit(True);
end;

function TUsuarioAdmin.EmpresaPrincipal: string;
var E: TEmpresaUsuarioAdmin;
begin
  Result := '';
  for E in Empresas do
    if E.Principal then Exit(E.Id);
end;

constructor TfraUsuarios.Create(AOwner: TComponent);
begin
  inherited;
  FUsuarios := TObjectList<TUsuarioAdmin>.Create(True);
  FEmpresas := TObjectList<TEmpresaUsuarioAdmin>.Create(True);
  FChecksEmpresas := TObjectList<TCheckBox>.Create(False);
  MontarTela;
end;

destructor TfraUsuarios.Destroy;
begin
  FChecksEmpresas.Free;
  FEmpresas.Free;
  FUsuarios.Free;
  inherited;
end;

function TfraUsuarios.Rotulo(const Parent: TFmxObject; const Texto: string;
  X, Y, W, H: Single; Cor: TAlphaColor; Tamanho: Single): TLabel;
begin
  Result := TLabel.Create(Self); Result.Parent := Parent;
  Result.Position.Point := PointF(X, Y); Result.Width := W; Result.Height := H;
  Result.Text := Texto; Result.StyledSettings := [];
  Result.TextSettings.Font.Family := 'Manrope';
  Result.TextSettings.Font.Size := Tamanho; Result.TextSettings.FontColor := Cor;
end;

function TfraUsuarios.Botao(const Parent: TFmxObject; const Texto: string;
  Largura: Single; Click: TNotifyEvent): TfraSensorButton;
begin
  Result := TfraSensorButton.Create(Self); Result.Name := ''; Result.Parent := Parent;
  Result.Align := TAlignLayout.Left; Result.Width := Largura;
  Result.Margins.Right := 8; Result.Texto := Texto;
  Result.Estilo := sbsSecondary; Result.OnButtonClick := Click;
end;

function TfraUsuarios.Campo(const Parent: TFmxObject; const Titulo, Prompt: string;
  Y: Single): TEdit;
var Fundo: TRectangle;
begin
  Rotulo(Parent, Titulo, 20, Y, 340, 18, $FF9CAABC, 10);
  Fundo := TRectangle.Create(Self); Fundo.Parent := Parent;
  Fundo.Position.Point := PointF(20, Y + 20); Fundo.Width := 340; Fundo.Height := 38;
  Fundo.Fill.Color := $FF152439; Fundo.Stroke.Color := $FF2A405B;
  Fundo.XRadius := 6; Fundo.YRadius := 6;
  Result := TEdit.Create(Self); Result.Parent := Fundo; Result.Align := TAlignLayout.Client;
  Result.Margins.Left := 10; Result.Margins.Right := 10;
  Result.StyleLookup := 'transparentedit'; Result.StyledSettings := [];
  Result.TextSettings.FontColor := $FFF4F7FB; Result.TextPrompt := Prompt;
end;

procedure TfraUsuarios.BotaoIcone(const B: TfraSensorButton; const Dica: string);
begin
  B.Width := 38; B.Height := 34; B.Texto := ''; B.lblTexto.Visible := False;
  B.pthIcone.Align := TAlignLayout.None; B.pthIcone.Margins.Rect := RectF(0,0,0,0);
  B.pthIcone.Position.Point := PointF((B.Width-B.pthIcone.Width)/2,
    (B.Height-B.pthIcone.Height)/2);
  B.Hint := Dica; B.ShowHint := True; B.rctFundo.Hint := Dica;
  B.rctFundo.ShowHint := True;
end;

procedure TfraUsuarios.PrepararComboEscuro(const Combo: TComboBox;
  const Fundo: TRectangle);
var
  Mascara: TRectangle;
  Texto, Seta: TLabel;
begin
  Mascara := TRectangle.Create(Self);
  Mascara.Parent := Fundo;
  Mascara.Align := TAlignLayout.Client;
  Mascara.Fill.Color := $FF152439;
  Mascara.Stroke.Kind := TBrushKind.None;
  Mascara.HitTest := False;
  Texto := Rotulo(Mascara, '', 12, 0, Fundo.Width - 48, Fundo.Height,
    $FFF4F7FB, 11);
  Texto.TextSettings.VertAlign := TTextAlign.Center;
  Texto.HitTest := False;
  Seta := Rotulo(Mascara, '⌄', Fundo.Width - 34, 0, 24, Fundo.Height,
    $FF9CAABC, 16);
  Seta.TextSettings.HorzAlign := TTextAlign.Center;
  Seta.TextSettings.VertAlign := TTextAlign.Center;
  Seta.Anchors := [TAnchorKind.akTop, TAnchorKind.akRight];
  Seta.HitTest := False;
  Combo.TagObject := Texto;
  Combo.OnChange := ComboVisualChange;
  Mascara.BringToFront;
end;

procedure TfraUsuarios.AtualizarComboVisual(const Combo: TComboBox);
begin
  if not Assigned(Combo) or not (Combo.TagObject is TLabel) then Exit;
  if (Combo.ItemIndex >= 0) and (Combo.ItemIndex < Combo.Count) then
    TLabel(Combo.TagObject).Text := Combo.Items[Combo.ItemIndex]
  else
    TLabel(Combo.TagObject).Text := 'Selecione...';
end;

procedure TfraUsuarios.ComboVisualChange(Sender: TObject);
begin
  if Sender is TComboBox then AtualizarComboVisual(TComboBox(Sender));
end;

procedure TfraUsuarios.MontarTela;
var
  Barra: TLayout;
  ListaFundo, AreaTipo, AreaPrincipal: TRectangle;
begin
  Barra := TLayout.Create(Self); Barra.Parent := lytConteudo;
  Barra.Align := TAlignLayout.Top; Barra.Height := 44; Barra.Margins.Bottom := 12;
  FBtnNovo := Botao(Barra, '+ Novo usuário', 142, NovoClick);
  FBtnNovo.Align := TAlignLayout.Right; FBtnNovo.Estilo := sbsPrimary;
  FBtnNovo.Icone := sbiUsuario;
  FBtnBuscar := Botao(Barra, 'Buscar', 112, BuscarClick);
  FBtnBuscar.Align := TAlignLayout.Right; FBtnBuscar.Icone := sbiPesquisar;
  ListaFundo := TRectangle.Create(Self); ListaFundo.Parent := Barra;
  ListaFundo.Align := TAlignLayout.Client; ListaFundo.Margins.Right := 12;
  ListaFundo.Fill.Color := $FF152439; ListaFundo.Stroke.Color := $FF2A405B;
  ListaFundo.XRadius := 8; ListaFundo.YRadius := 8;
  FBusca := TEdit.Create(Self); FBusca.Parent := ListaFundo;
  FBusca.Align := TAlignLayout.Client; FBusca.Margins.Left := 12;
  FBusca.Margins.Right := 12; FBusca.StyleLookup := 'transparentedit';
  FBusca.StyledSettings := []; FBusca.TextSettings.FontColor := $FFF4F7FB;
  FBusca.TextPrompt := 'Buscar por nome ou e-mail';
  FBusca.OnTyping := BuscaChange; FBusca.OnChangeTracking := BuscaChange;
  FBusca.OnKeyDown := BuscaKeyDown;
  FTimer := TTimer.Create(Self); FTimer.Interval := 400;
  FTimer.Enabled := False; FTimer.OnTimer := TimerBusca;

  FPainelEditor := TRectangle.Create(Self); FPainelEditor.Parent := lytConteudo;
  FPainelEditor.Align := TAlignLayout.Right; FPainelEditor.Width := 390;
  FPainelEditor.Margins.Left := 14; FPainelEditor.Fill.Color := $FF111E2E;
  FPainelEditor.Stroke.Color := $FF2A405B; FPainelEditor.XRadius := 10;
  FPainelEditor.YRadius := 10; FPainelEditor.Visible := False;
  FTituloEditor := Rotulo(FPainelEditor, 'Novo usuário', 20, 14, 350, 30,
    $FFF4F7FB, 16); FTituloEditor.TextSettings.Font.Style := [TFontStyle.fsBold];
  FEditorScroll := TVertScrollBox.Create(Self); FEditorScroll.Parent := FPainelEditor;
  FEditorScroll.Align := TAlignLayout.Client; FEditorScroll.Margins.Top := 50;
  FEditorConteudo := TLayout.Create(Self); FEditorConteudo.Parent := FEditorScroll;
  FEditorConteudo.Align := TAlignLayout.Top; FEditorConteudo.Height := 690;

  FNome := Campo(FEditorConteudo, 'Nome *', 'Nome do usuário', 0);
  FEmail := Campo(FEditorConteudo, 'E-mail *', 'usuario@exemplo.com', 66);
  FEmail.KeyboardType := TVirtualKeyboardType.EmailAddress;
  FSenha := Campo(FEditorConteudo, 'Senha', 'Mínimo de 6 caracteres', 132);
  FSenha.Password := True;
  Rotulo(FEditorConteudo, 'Perfil *', 20, 198, 340, 18, $FF9CAABC, 10);
  AreaTipo := TRectangle.Create(Self); AreaTipo.Parent := FEditorConteudo;
  AreaTipo.Position.Point := PointF(20,218); AreaTipo.Width := 340; AreaTipo.Height := 38;
  AreaTipo.Fill.Color := $FF152439; AreaTipo.Stroke.Color := $FF2A405B;
  AreaTipo.XRadius := 6; AreaTipo.YRadius := 6;
  FTipo := TComboBox.Create(Self); FTipo.Parent := AreaTipo;
  FTipo.Align := TAlignLayout.Client; FTipo.Items.Add('Administrador');
  FTipo.Items.Add('Gerente'); FTipo.Items.Add('Atendente');
  FTipo.Items.Add('Cozinha'); FTipo.Items.Add('Entregador'); FTipo.ItemIndex := 2;
  PrepararComboEscuro(FTipo, AreaTipo); AtualizarComboVisual(FTipo);

  Rotulo(FEditorConteudo, 'Empresas permitidas *', 20, 270, 340, 18,
    $FF9CAABC, 10);
  AreaPrincipal := TRectangle.Create(Self); AreaPrincipal.Parent := FEditorConteudo;
  AreaPrincipal.Position.Point := PointF(20,290); AreaPrincipal.Width := 340;
  AreaPrincipal.Height := 126; AreaPrincipal.Fill.Color := $FF152439;
  AreaPrincipal.Stroke.Color := $FF2A405B; AreaPrincipal.XRadius := 6;
  AreaPrincipal.YRadius := 6;
  FEmpresasScroll := TVertScrollBox.Create(Self); FEmpresasScroll.Parent := AreaPrincipal;
  FEmpresasScroll.Align := TAlignLayout.Client; FEmpresasScroll.Margins.Rect := RectF(8,6,8,6);

  Rotulo(FEditorConteudo, 'Empresa principal *', 20, 430, 340, 18,
    $FF9CAABC, 10);
  AreaPrincipal := TRectangle.Create(Self); AreaPrincipal.Parent := FEditorConteudo;
  AreaPrincipal.Position.Point := PointF(20,450); AreaPrincipal.Width := 340;
  AreaPrincipal.Height := 38; AreaPrincipal.Fill.Color := $FF152439;
  AreaPrincipal.Stroke.Color := $FF2A405B; AreaPrincipal.XRadius := 6;
  AreaPrincipal.YRadius := 6;
  FPrincipal := TComboBox.Create(Self); FPrincipal.Parent := AreaPrincipal;
  FPrincipal.Align := TAlignLayout.Client;
  PrepararComboEscuro(FPrincipal, AreaPrincipal);
  TNavegacaoCampos.Aplicar(Self, [FNome, FEmail, FSenha, FTipo, FPrincipal]);

  FBtnCancelar := Botao(FEditorConteudo, 'Cancelar', 108, CancelarClick);
  FBtnCancelar.Align := TAlignLayout.None;
  FBtnCancelar.Position.Point := PointF(20, 526); FBtnCancelar.Height := 40;
  FBtnCancelar.Icone := sbiCancelar;
  FBtnSalvar := Botao(FEditorConteudo, 'Salvar', 112, SalvarClick);
  FBtnSalvar.Align := TAlignLayout.None;
  FBtnSalvar.Position.Point := PointF(248, 526); FBtnSalvar.Height := 40;
  FBtnSalvar.Icone := sbiSalvar;

  ListaFundo := TRectangle.Create(Self); ListaFundo.Parent := lytConteudo;
  ListaFundo.Align := TAlignLayout.Client; ListaFundo.Fill.Color := $FF111E2E;
  ListaFundo.Stroke.Color := $FF23364D; ListaFundo.XRadius := 10;
  ListaFundo.YRadius := 10;
  FEstado := Rotulo(ListaFundo, 'Carregando usuários...', 20, 16, 600, 24,
    $FF8795A8, 11);
  FLista := TVertScrollBox.Create(Self); FLista.Parent := ListaFundo;
  FLista.Align := TAlignLayout.Client; FLista.Margins.Rect := RectF(8,48,8,8);
  FListaConteudo := TLayout.Create(Self); FListaConteudo.Parent := FLista;
  FListaConteudo.Align := TAlignLayout.Top; FListaConteudo.Height := 1;
end;

function TfraUsuarios.MensagemResposta(const Resposta: IHTTPResponse;
  const Padrao: string): string;
var Valor: TJSONValue;
begin
  Result := Padrao;
  Valor := TJSONObject.ParseJSONValue(Resposta.ContentAsString(TEncoding.UTF8));
  try
    if Valor is TJSONObject then
      Result := TJSONObject(Valor).GetValue<string>('erro', Padrao);
  finally Valor.Free; end;
end;

procedure TfraUsuarios.CarregarEmpresas;
var HTTP: TNetHTTPClient; R: IHTTPResponse; V, Item: TJSONValue;
  A: TJSONArray; J: TJSONObject; E: TEmpresaUsuarioAdmin;
begin
  HTTP := TNetHTTPClient.Create(nil); V := nil;
  try
    TSessaoAdmin.ConfigurarCliente(HTTP); R := HTTP.Get(URL_EMPRESAS);
    if R.StatusCode <> 200 then
      raise Exception.Create(MensagemResposta(R, 'Não foi possível listar as empresas.'));
    V := TJSONObject.ParseJSONValue(R.ContentAsString(TEncoding.UTF8));
    A := TJSONObject(V).GetValue<TJSONArray>('empresas'); FEmpresas.Clear;
    for Item in A do begin J := Item as TJSONObject;
      if not J.GetValue<Boolean>('ativo', True) then Continue;
      E := TEmpresaUsuarioAdmin.Create; E.Id := J.GetValue<string>('id', '');
      E.Nome := J.GetValue<string>('nome_fantasia', ''); FEmpresas.Add(E);
    end;
  finally V.Free; HTTP.Free; end;
end;

procedure TfraUsuarios.CarregarUsuarios;
var HTTP: TNetHTTPClient; R: IHTTPResponse; V, Item, EI: TJSONValue;
  A, EA: TJSONArray; J, EJ: TJSONObject; U: TUsuarioAdmin;
  E: TEmpresaUsuarioAdmin; URL: string;
begin
  FEstado.Text := 'Carregando usuários...'; HTTP := TNetHTTPClient.Create(nil); V := nil;
  try
    try
      URL := URL_USUARIOS;
      if not FBusca.Text.Trim.IsEmpty then
        URL := URL + '?busca=' + TNetEncoding.URL.Encode(FBusca.Text.Trim);
      TSessaoAdmin.ConfigurarCliente(HTTP); R := HTTP.Get(URL);
      if R.StatusCode <> 200 then
        raise Exception.Create(MensagemResposta(R, 'Não foi possível listar os usuários.'));
      V := TJSONObject.ParseJSONValue(R.ContentAsString(TEncoding.UTF8));
      A := TJSONObject(V).GetValue<TJSONArray>('usuarios'); FUsuarios.Clear;
      for Item in A do begin J := Item as TJSONObject; U := TUsuarioAdmin.Create;
        U.Id := J.GetValue<string>('id', ''); U.Nome := J.GetValue<string>('nome', '');
        U.Email := J.GetValue<string>('email', ''); U.Tipo := J.GetValue<string>('tipo', '');
        U.Ativo := J.GetValue<Boolean>('ativo', True);
        EA := J.GetValue<TJSONArray>('empresas');
        if Assigned(EA) then for EI in EA do begin EJ := EI as TJSONObject;
          E := TEmpresaUsuarioAdmin.Create; E.Id := EJ.GetValue<string>('id', '');
          E.Nome := EJ.GetValue<string>('nome_fantasia', '');
          E.Principal := EJ.GetValue<Boolean>('principal', False); U.Empresas.Add(E); end;
        FUsuarios.Add(U);
      end;
      FCarregado := True; PreencherLista;
    except on X: Exception do TfrmMensagem.Exibir('Erro ao carregar usuários', X.Message, tmErro); end;
  finally V.Free; HTTP.Free; end;
end;

procedure TfraUsuarios.PreencherLista;
var U: TUsuarioAdmin; C: TRectangle; Acoes: TLayout; B1, B2: TfraSensorButton;
  I: Integer; Status, EmpresasTexto: string; Cor: TAlphaColor;
begin
  while FListaConteudo.ChildrenCount > 0 do FListaConteudo.Children[0].Free;
  FListaConteudo.Height := FUsuarios.Count * 70;
  for I := 0 to FUsuarios.Count - 1 do begin U := FUsuarios[I];
    if U.Ativo then begin Status := 'ATIVO'; Cor := $FF45D483; end
    else begin Status := 'INATIVO'; Cor := $FFFFB454; end;
    if U.Empresas.Count = 1 then EmpresasTexto := '1 empresa'
    else EmpresasTexto := U.Empresas.Count.ToString + ' empresas';
    C := TRectangle.Create(Self); C.Parent := FListaConteudo;
    C.Position.Point := PointF(4, I*70+2); C.Width := FListaConteudo.Width-8;
    C.Height := 64; C.Anchors := [TAnchorKind.akLeft,TAnchorKind.akTop,TAnchorKind.akRight];
    C.Fill.Color := $FF152439; C.Stroke.Color := $FF23364D; C.XRadius := 7; C.YRadius := 7;
    Rotulo(C, U.Nome, 14, 8, 440, 22, $FFF4F7FB, 11).TextSettings.Font.Style := [TFontStyle.fsBold];
    Rotulo(C, U.Email + '  •  ' + U.Tipo + '  •  ' + EmpresasTexto,
      14, 34, 600, 18, $FF8795A8, 9);
    Rotulo(C, Status, C.Width-58, 22, 52, 18, Cor, 8).Anchors := [TAnchorKind.akTop,TAnchorKind.akRight];
    Acoes := TLayout.Create(Self); Acoes.Parent := C; Acoes.Align := TAlignLayout.Right;
    Acoes.Width := 150;
    B1 := Botao(Acoes, '', 38, EditarClick); B1.Align := TAlignLayout.None;
    B1.Position.Point := PointF(0,15); B1.Icone := sbiEditar; B1.Tag := I;
    BotaoIcone(B1, 'Editar usuário');
    B2 := Botao(Acoes, '', 38, SituacaoClick); B2.Align := TAlignLayout.None;
    B2.Position.Point := PointF(46,15); B2.Tag := I;
    if U.Ativo then begin B2.Icone := sbiBloquear; BotaoIcone(B2,'Desativar usuário'); end
    else begin B2.Icone := sbiAtivar; BotaoIcone(B2,'Ativar usuário'); end;
  end;
  FEstado.Text := FUsuarios.Count.ToString + ' usuário(s) encontrado(s)';
end;

procedure TfraUsuarios.PreencherEmpresasEditor(const Usuario: TUsuarioAdmin);
var I: Integer; Check: TCheckBox; E: TEmpresaUsuarioAdmin; PrincipalId: string;
begin
  while FEmpresasScroll.Content.ChildrenCount > 0 do
    FEmpresasScroll.Content.Children[0].Free;
  FChecksEmpresas.Clear; FPrincipal.Clear; PrincipalId := '';
  if Assigned(Usuario) then PrincipalId := Usuario.EmpresaPrincipal;
  for I := 0 to FEmpresas.Count - 1 do begin E := FEmpresas[I];
    Check := TCheckBox.Create(Self); Check.Parent := FEmpresasScroll;
    Check.Align := TAlignLayout.Top; Check.Height := 30; Check.Text := E.Nome;
    Check.StyledSettings := [];
    Check.TextSettings.Font.Family := 'Manrope';
    Check.TextSettings.Font.Size := 10;
    Check.TextSettings.FontColor := $FFF4F7FB;
    Check.IsChecked := Assigned(Usuario) and Usuario.PossuiEmpresa(E.Id);
    if not Assigned(Usuario) and SameText(E.Id, TSessaoAdmin.EmpresaId) then Check.IsChecked := True;
    FChecksEmpresas.Add(Check); FPrincipal.Items.Add(E.Nome);
    if SameText(E.Id, PrincipalId) then FPrincipal.ItemIndex := I;
    if not Assigned(Usuario) and SameText(E.Id, TSessaoAdmin.EmpresaId) then FPrincipal.ItemIndex := I;
  end;
  if (FPrincipal.ItemIndex < 0) and (FPrincipal.Count > 0) then FPrincipal.ItemIndex := 0;
  AtualizarComboVisual(FPrincipal);
end;

procedure TfraUsuarios.AbrirEditor(const Usuario: TUsuarioAdmin);
begin
  FPainelEditor.Visible := True;
  if Assigned(Usuario) then begin FEditandoId := Usuario.Id;
    FTituloEditor.Text := 'Editar usuário'; FNome.Text := Usuario.Nome;
    FEmail.Text := Usuario.Email; FSenha.Text := '';
    if SameText(Usuario.Tipo,'ADMIN') then FTipo.ItemIndex := 0
    else if SameText(Usuario.Tipo,'GERENTE') then FTipo.ItemIndex := 1
    else if SameText(Usuario.Tipo,'ATENDENTE') then FTipo.ItemIndex := 2
    else if SameText(Usuario.Tipo,'COZINHA') then FTipo.ItemIndex := 3
    else FTipo.ItemIndex := 4;
  end else begin FEditandoId := ''; FTituloEditor.Text := 'Novo usuário';
    FNome.Text := ''; FEmail.Text := ''; FSenha.Text := ''; FTipo.ItemIndex := 2; end;
  AtualizarComboVisual(FTipo);
  PreencherEmpresasEditor(Usuario); FNome.SetFocus;
end;

procedure TfraUsuarios.FecharEditor;
begin FPainelEditor.Visible := False; FEditandoId := ''; end;
procedure TfraUsuarios.NovoClick(Sender: TObject); begin AbrirEditor(nil); end;
procedure TfraUsuarios.EditarClick(Sender: TObject);
var I: Integer;
begin I := TComponent(Sender).Tag; if (I>=0) and (I<FUsuarios.Count) then AbrirEditor(FUsuarios[I]); end;
procedure TfraUsuarios.CancelarClick(Sender: TObject); begin FecharEditor; end;
procedure TfraUsuarios.BuscarClick(Sender: TObject); begin CarregarUsuarios; end;
procedure TfraUsuarios.BuscaChange(Sender: TObject);
begin FTimer.Enabled := False; FTimer.Enabled := True; end;
procedure TfraUsuarios.TimerBusca(Sender: TObject);
begin FTimer.Enabled := False; CarregarUsuarios; end;
procedure TfraUsuarios.BuscaKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin if Key=vkReturn then begin Key:=0; CarregarUsuarios; end; end;

procedure TfraUsuarios.SalvarClick(Sender: TObject);
const TIPOS: array[0..4] of string = ('ADMIN','GERENTE','ATENDENTE','COZINHA','ENTREGADOR');
var J: TJSONObject; A: TJSONArray; I, Selecionadas: Integer;
  HTTP: TNetHTTPClient; S: TStringStream; R: IHTTPResponse; URL: string;
begin
  if FNome.Text.Trim.IsEmpty then begin TfrmMensagem.Exibir('Dados obrigatórios','Informe o nome.',tmAtencao); Exit; end;
  if FEmail.Text.Trim.IsEmpty then begin TfrmMensagem.Exibir('Dados obrigatórios','Informe o e-mail.',tmAtencao); Exit; end;
  if FEditandoId.IsEmpty and (FSenha.Text.Length < 6) then begin
    TfrmMensagem.Exibir('Senha inválida','A senha deve possuir ao menos 6 caracteres.',tmAtencao); Exit; end;
  Selecionadas := 0; for I := 0 to FChecksEmpresas.Count-1 do if FChecksEmpresas[I].IsChecked then Inc(Selecionadas);
  if Selecionadas=0 then begin TfrmMensagem.Exibir('Empresa obrigatória','Selecione ao menos uma empresa.',tmAtencao); Exit; end;
  if (FPrincipal.ItemIndex<0) or not FChecksEmpresas[FPrincipal.ItemIndex].IsChecked then begin
    TfrmMensagem.Exibir('Empresa principal','A empresa principal também deve estar marcada.',tmAtencao); Exit; end;

  J := TJSONObject.Create; HTTP := TNetHTTPClient.Create(nil);
  try
    J.AddPair('nome',FNome.Text.Trim); J.AddPair('email',FEmail.Text.Trim);
    J.AddPair('senha',FSenha.Text); J.AddPair('tipo',TIPOS[FTipo.ItemIndex]);
    A := TJSONArray.Create; for I := 0 to FChecksEmpresas.Count-1 do
      if FChecksEmpresas[I].IsChecked then A.Add(FEmpresas[I].Id);
    J.AddPair('empresas',A); J.AddPair('principalEmpresaId',FEmpresas[FPrincipal.ItemIndex].Id);
    S := TStringStream.Create(J.ToJSON,TEncoding.UTF8);
    try
      HTTP.ContentType := 'application/json'; TSessaoAdmin.ConfigurarCliente(HTTP);
      if FEditandoId.IsEmpty then R := HTTP.Post(URL_USUARIOS,S)
      else begin URL := URL_USUARIOS+'/'+FEditandoId; R := HTTP.Put(URL,S); end;
    finally S.Free; end;
    if not (R.StatusCode in [200,201]) then begin
      TfrmMensagem.Exibir('Erro ao salvar usuário',MensagemResposta(R,'Não foi possível salvar o usuário.'),tmErro); Exit; end;
    FecharEditor; CarregarUsuarios;
  except on X:Exception do TfrmMensagem.Exibir('Erro de comunicação',X.Message,tmErro); end;
  HTTP.Free; J.Free;
end;

procedure TfraUsuarios.SituacaoClick(Sender: TObject);
var I: Integer; U: TUsuarioAdmin; J: TJSONObject; HTTP: TNetHTTPClient;
  S: TStringStream; R: IHTTPResponse;
begin
  I := TComponent(Sender).Tag; if (I<0) or (I>=FUsuarios.Count) then Exit; U:=FUsuarios[I];
  if SameText(U.Id,TSessaoAdmin.UsuarioId) and U.Ativo then begin
    TfrmMensagem.Exibir('Operação não permitida','Você não pode desativar o próprio usuário.',tmAtencao); Exit; end;
  J:=TJSONObject.Create; HTTP:=TNetHTTPClient.Create(nil);
  try J.AddPair('ativo',TJSONBool.Create(not U.Ativo));
    S:=TStringStream.Create(J.ToJSON,TEncoding.UTF8);
    try HTTP.ContentType:='application/json'; TSessaoAdmin.ConfigurarCliente(HTTP);
      R:=HTTP.Patch(URL_USUARIOS+'/'+U.Id+'/situacao',S); finally S.Free; end;
    if R.StatusCode<>200 then TfrmMensagem.Exibir('Erro ao alterar usuário',MensagemResposta(R,'Não foi possível alterar o usuário.'),tmErro)
    else CarregarUsuarios;
  except on X:Exception do TfrmMensagem.Exibir('Erro de comunicação',X.Message,tmErro); end;
  HTTP.Free; J.Free;
end;

procedure TfraUsuarios.PrepararTela;
begin
  if not FCarregado then begin
    try CarregarEmpresas; CarregarUsuarios;
    except on X:Exception do TfrmMensagem.Exibir('Erro ao abrir usuários',X.Message,tmErro); end;
  end;
end;

end.
