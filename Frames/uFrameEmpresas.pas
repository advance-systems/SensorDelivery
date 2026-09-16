unit uFrameEmpresas;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.JSON,
  System.Net.URLClient, System.Net.HttpClient, System.Net.HttpClientComponent,
  System.NetEncoding, System.Generics.Collections,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Objects,
  FMX.Layouts, FMX.Controls.Presentation, FMX.Edit, FMX.ListBox,
  uFrameSensorButton;

type
  TEmpresaFiltro = (efTodas, efAtivas, efInativas);
  TEmpresaAdmin = class
  public
    Id, RazaoSocial, NomeFantasia, LogoUrl, Telefone, Email, Timezone,
      PixProvedor: string;
    Ativo: Boolean;
  end;

  TfraEmpresas = class(TFrame)
    rctFundo: TRectangle;
    lytPrincipal, lytCabecalho, lytConteudo: TLayout;
    lblTitulo, lblSubtitulo: TLabel;
  private
    FEmpresas: TObjectList<TEmpresaAdmin>;
    FCarregado: Boolean; FSelecionado: Integer; FFiltro: TEmpresaFiltro;
    FEditandoId: string;
    FBarra, FFiltros, FListaConteudo: TLayout;
    FBusca, FRazaoSocial, FNomeFantasia, FLogoUrl, FTelefone,
    FEmail, FTimezone: TEdit;
    FPixProvedor: TComboBox;
    FLista, FScrollEditor: TVertScrollBox;
    FEstado, FTituloEdicao: TLabel; FPainelEdicao: TRectangle;
    FTimerBusca: TTimer;
    FBtnNovo, FBtnBuscar, FBtnSalvar, FBtnCancelar, FBtnLogo,
      FBtnTodas, FBtnAtivas, FBtnInativas: TfraSensorButton;
    procedure MontarTela;
    function Rotulo(const P: TFmxObject; const T: string; X, Y, W, H: Single;
      Cor: TAlphaColor; Tam: Single): TLabel;
    function Botao(const P: TFmxObject; const T: string; W: Single;
      Click: TNotifyEvent): TfraSensorButton;
    function Campo(const P: TFmxObject; const Titulo, Prompt: string;
      Y: Single): TEdit;
    procedure BotaoIcone(const B: TfraSensorButton; const Hint: string);
    function Selecionada: TEmpresaAdmin;
    function Visivel(const E: TEmpresaAdmin): Boolean;
    procedure PreencherLista; procedure AtualizarFiltros;
    procedure AbrirEditor(const E: TEmpresaAdmin); procedure FecharEditor;
    procedure ExibirErro(const Titulo: string; const R: IHTTPResponse);
    procedure NovoClick(Sender: TObject); procedure EditarClick(Sender: TObject);
    procedure AtivoClick(Sender: TObject); procedure SalvarClick(Sender: TObject);
    procedure CancelarClick(Sender: TObject); procedure BuscarClick(Sender: TObject);
    procedure BuscaChange(Sender: TObject); procedure TimerBusca(Sender: TObject);
    procedure FiltroClick(Sender: TObject);
    procedure SelecionarLogoClick(Sender: TObject);
    procedure BuscaKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure PixProvedorChange(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure PrepararTela; procedure CarregarEmpresas;
  end;

implementation

{$R *.fmx}
uses uMensagem, uImagemUpload, uSessaoAdmin, uNavegacaoCampos, uApiConfig;

function URL_EMPRESAS: string;
begin
  Result := TApiConfig.Url('/api/empresas');
end;

constructor TfraEmpresas.Create(AOwner: TComponent);
begin inherited; FEmpresas := TObjectList<TEmpresaAdmin>.Create(True);
  FSelecionado := -1; FFiltro := efTodas; MontarTela; end;
destructor TfraEmpresas.Destroy;
begin FEmpresas.Free; inherited; end;

function TfraEmpresas.Rotulo(const P: TFmxObject; const T: string;
  X, Y, W, H: Single; Cor: TAlphaColor; Tam: Single): TLabel;
begin Result := TLabel.Create(Self); Result.Parent := P;
  Result.Position.Point := PointF(X,Y); Result.Width := W; Result.Height := H;
  Result.Text := T; Result.StyledSettings := [];
  Result.TextSettings.Font.Family := 'Manrope'; Result.TextSettings.Font.Size := Tam;
  Result.TextSettings.FontColor := Cor; end;

function TfraEmpresas.Botao(const P: TFmxObject; const T: string; W: Single;
  Click: TNotifyEvent): TfraSensorButton;
begin Result := TfraSensorButton.Create(Self); Result.Name := ''; Result.Parent := P;
  Result.Align := TAlignLayout.Left; Result.Width := W; Result.Margins.Right := 8;
  Result.Texto := T; Result.Estilo := sbsSecondary; Result.OnButtonClick := Click;
  Result.pthIcone.Margins.Left := 10; Result.pthIcone.Margins.Right := 6; end;

function TfraEmpresas.Campo(const P: TFmxObject; const Titulo, Prompt: string;
  Y: Single): TEdit;
var R: TRectangle;
begin Rotulo(P, Titulo, 20, Y, 340, 18, $FF9CAABC, 10);
  R := TRectangle.Create(Self); R.Parent := P; R.Position.Point := PointF(20,Y+20);
  R.Width := 340; R.Height := 38; R.Fill.Color := $FF152439;
  R.Stroke.Color := $FF2A405B; R.XRadius := 6; R.YRadius := 6;
  Result := TEdit.Create(Self); Result.Parent := R; Result.Align := TAlignLayout.Client;
  Result.Margins.Left := 10; Result.Margins.Right := 10;
  Result.StyleLookup := 'transparentedit'; Result.StyledSettings := [];
  Result.TextSettings.FontColor := $FFF4F7FB; Result.TextPrompt := Prompt; end;

procedure TfraEmpresas.BotaoIcone(const B: TfraSensorButton; const Hint: string);
begin B.Width := 38; B.Height := 34; B.Texto := ''; B.lblTexto.Visible := False;
  B.pthIcone.Align := TAlignLayout.None; B.pthIcone.Margins.Rect := RectF(0,0,0,0);
  B.pthIcone.Position.Point := PointF((B.Width-B.pthIcone.Width)/2,
    (B.Height-B.pthIcone.Height)/2); B.Hint := Hint; B.ShowHint := True;
  B.rctFundo.Hint := Hint; B.rctFundo.ShowHint := True; end;

procedure TfraEmpresas.MontarTela;
var R, ListaFundo, Mascara: TRectangle; Editor: TLayout; Texto, Seta: TLabel;
begin
  FBarra := TLayout.Create(Self); FBarra.Parent := lytConteudo;
  FBarra.Align := TAlignLayout.Top; FBarra.Height := 44; FBarra.Margins.Bottom := 12;
  FBtnNovo := Botao(FBarra, '+ Nova empresa', 140, NovoClick);
  FBtnNovo.Align := TAlignLayout.Right; FBtnNovo.Estilo := sbsPrimary;
  FBtnNovo.Icone := sbiEmpresa;
  FBtnBuscar := Botao(FBarra, 'Buscar', 96, BuscarClick);
  FBtnBuscar.Align := TAlignLayout.Right; FBtnBuscar.Icone := sbiPesquisar;
  R := TRectangle.Create(Self); R.Parent := FBarra; R.Align := TAlignLayout.Client;
  R.Margins.Right := 12; R.Fill.Color := $FF152439; R.Stroke.Color := $FF2A405B;
  R.XRadius := 8; R.YRadius := 8;
  FBusca := TEdit.Create(Self); FBusca.Parent := R; FBusca.Align := TAlignLayout.Client;
  FBusca.Margins.Left := 12; FBusca.Margins.Right := 12;
  FBusca.StyleLookup := 'transparentedit'; FBusca.StyledSettings := [];
  FBusca.TextSettings.FontColor := $FFF4F7FB;
  FBusca.TextPrompt := 'Buscar por nome, telefone ou e-mail';
  FBusca.OnTyping := BuscaChange; FBusca.OnChangeTracking := BuscaChange;
  FBusca.OnKeyDown := BuscaKeyDown;
  FTimerBusca := TTimer.Create(Self); FTimerBusca.Interval := 400;
  FTimerBusca.Enabled := False; FTimerBusca.OnTimer := TimerBusca;
  FFiltros := TLayout.Create(Self); FFiltros.Parent := lytConteudo;
  FFiltros.Align := TAlignLayout.Top; FFiltros.Height := 42; FFiltros.Margins.Bottom := 10;
  Rotulo(FFiltros,'Filtrar por status:',2,0,112,42,$FF8795A8,10);
  FBtnTodas := Botao(FFiltros,'Todas',94,FiltroClick); FBtnTodas.Align := TAlignLayout.None;
  FBtnTodas.Position.Point := PointF(118,2); FBtnTodas.Height := 36;
  FBtnTodas.Icone := sbiRelatorio; FBtnTodas.Tag := Ord(efTodas);
  FBtnAtivas := Botao(FFiltros,'Ativas',98,FiltroClick); FBtnAtivas.Align := TAlignLayout.None;
  FBtnAtivas.Position.Point := PointF(220,2); FBtnAtivas.Height := 36;
  FBtnAtivas.Icone := sbiAtivar; FBtnAtivas.Tag := Ord(efAtivas);
  FBtnInativas := Botao(FFiltros,'Inativas',108,FiltroClick); FBtnInativas.Align := TAlignLayout.None;
  FBtnInativas.Position.Point := PointF(326,2); FBtnInativas.Height := 36;
  FBtnInativas.Icone := sbiCancelar; FBtnInativas.Tag := Ord(efInativas); AtualizarFiltros;
  FPainelEdicao := TRectangle.Create(Self); FPainelEdicao.Parent := lytConteudo;
  FPainelEdicao.Align := TAlignLayout.Right; FPainelEdicao.Width := 380;
  FPainelEdicao.Margins.Left := 14; FPainelEdicao.Fill.Color := $FF111E2E;
  FPainelEdicao.Stroke.Color := $FF2A405B; FPainelEdicao.XRadius := 10;
  FPainelEdicao.YRadius := 10; FPainelEdicao.Visible := False;
  FTituloEdicao := Rotulo(FPainelEdicao,'Nova empresa',20,14,340,30,$FFF4F7FB,16);
  FTituloEdicao.TextSettings.Font.Style := [TFontStyle.fsBold];
  FScrollEditor := TVertScrollBox.Create(Self); FScrollEditor.Parent := FPainelEdicao;
  FScrollEditor.Align := TAlignLayout.Client; FScrollEditor.Margins.Top := 50;
  Editor := TLayout.Create(Self); Editor.Parent := FScrollEditor;
  Editor.Align := TAlignLayout.Top; Editor.Height := 590;
  FRazaoSocial := Campo(Editor,'Razão social *','Razão social',0);
  FNomeFantasia := Campo(Editor,'Nome fantasia *','Nome da empresa',66);
  FLogoUrl := Campo(Editor,'Logotipo','Selecione uma imagem do computador',132);
  FLogoUrl.ReadOnly := True; FLogoUrl.Margins.Right := 112;
  FBtnLogo := Botao(FLogoUrl.Parent,'Selecionar',104,SelecionarLogoClick);
  FBtnLogo.Align := TAlignLayout.Right; FBtnLogo.Margins.Right := 2;
  FBtnLogo.Height := 34; FBtnLogo.Icone := sbiPesquisar;
  FTelefone := Campo(Editor,'Telefone','(00) 0000-0000',198);
  FEmail := Campo(Editor,'E-mail','empresa@exemplo.com',264);
  FEmail.KeyboardType := TVirtualKeyboardType.EmailAddress;
  FTimezone := Campo(Editor,'Fuso horário','America/Sao_Paulo',330);
  Rotulo(Editor,'Banco de recebimento PIX *',20,396,340,18,$FF9CAABC,10);
  R:=TRectangle.Create(Self); R.Parent:=Editor; R.Position.Point:=PointF(20,416);
  R.Width:=340; R.Height:=38; R.Fill.Color:=$FF152439; R.Stroke.Color:=$FF2A405B;
  R.XRadius:=6; R.YRadius:=6;
  FPixProvedor:=TComboBox.Create(Self); FPixProvedor.Parent:=R;
  FPixProvedor.Align:=TAlignLayout.Client; FPixProvedor.Items.Add('Asaas');
  FPixProvedor.Items.Add('Sicredi'); FPixProvedor.ItemIndex:=0;
  Mascara:=TRectangle.Create(Self); Mascara.Parent:=R; Mascara.Align:=TAlignLayout.Client;
  Mascara.Fill.Color:=$FF152439; Mascara.Stroke.Kind:=TBrushKind.None;
  Mascara.HitTest:=False;
  Texto:=Rotulo(Mascara,'Asaas',12,0,286,38,$FFF4F7FB,11);
  Texto.TextSettings.VertAlign:=TTextAlign.Center; Texto.HitTest:=False;
  Seta:=Rotulo(Mascara,'⌄',306,0,24,38,$FF9CAABC,16);
  Seta.TextSettings.HorzAlign:=TTextAlign.Center;
  Seta.TextSettings.VertAlign:=TTextAlign.Center; Seta.HitTest:=False;
  FPixProvedor.TagObject:=Texto; FPixProvedor.OnChange:=PixProvedorChange;
  Mascara.BringToFront;
  TNavegacaoCampos.Aplicar(Self, [FRazaoSocial, FNomeFantasia,
    FTelefone, FEmail, FTimezone]);
  FBtnCancelar := Botao(Editor,'Cancelar',104,CancelarClick);
  FBtnCancelar.Align := TAlignLayout.None; FBtnCancelar.Position.Point := PointF(20,486);
  FBtnCancelar.Height := 40; FBtnCancelar.Icone := sbiCancelar;
  FBtnSalvar := Botao(Editor,'Salvar',112,SalvarClick); FBtnSalvar.Align := TAlignLayout.None;
  FBtnSalvar.Position.Point := PointF(248,486); FBtnSalvar.Height := 40;
  FBtnSalvar.Icone := sbiSalvar;
  ListaFundo := TRectangle.Create(Self); ListaFundo.Parent := lytConteudo;
  ListaFundo.Align := TAlignLayout.Client; ListaFundo.Fill.Color := $FF111E2E;
  ListaFundo.Stroke.Color := $FF23364D; ListaFundo.XRadius := 10; ListaFundo.YRadius := 10;
  FEstado := Rotulo(ListaFundo,'Carregando empresas...',20,16,500,24,$FF8795A8,11);
  FLista := TVertScrollBox.Create(Self); FLista.Parent := ListaFundo;
  FLista.Align := TAlignLayout.Client; FLista.Margins.Rect := RectF(8,48,8,8);
  FListaConteudo := TLayout.Create(Self); FListaConteudo.Parent := FLista;
  FListaConteudo.Align := TAlignLayout.Top; FListaConteudo.Height := 1;
end;

procedure TfraEmpresas.PrepararTela; begin if not FCarregado then CarregarEmpresas; end;
procedure TfraEmpresas.CarregarEmpresas;
var H:TNetHTTPClient; R:IHTTPResponse; V,Item:TJSONValue; A:TJSONArray;
  J:TJSONObject; E:TEmpresaAdmin; URL:string;
begin FEstado.Text := 'Carregando empresas...'; H := TNetHTTPClient.Create(nil); TSessaoAdmin.ConfigurarCliente(H); V := nil;
  try try URL := URL_EMPRESAS; if not FBusca.Text.Trim.IsEmpty then
    URL := URL + '?busca=' + TNetEncoding.URL.Encode(FBusca.Text.Trim);
    R := H.Get(URL); if R.StatusCode<>200 then begin ExibirErro('Erro ao carregar empresas',R); Exit; end;
    V := TJSONObject.ParseJSONValue(R.ContentAsString(TEncoding.UTF8));
    A := TJSONObject(V).GetValue<TJSONArray>('empresas'); FEmpresas.Clear;
    for Item in A do begin J := Item as TJSONObject; E := TEmpresaAdmin.Create;
      E.Id := J.GetValue<string>('id',''); E.RazaoSocial := J.GetValue<string>('razao_social','');
      E.NomeFantasia := J.GetValue<string>('nome_fantasia','');
      E.LogoUrl := J.GetValue<string>('logo_url',''); E.Telefone := J.GetValue<string>('telefone','');
      E.Email := J.GetValue<string>('email',''); E.Timezone := J.GetValue<string>('timezone','');
      E.PixProvedor := J.GetValue<string>('pix_provedor','ASAAS');
      E.Ativo := J.GetValue<Boolean>('ativo',True); FEmpresas.Add(E); end;
    FCarregado := True; PreencherLista;
  except on X:Exception do TfrmMensagem.Exibir('Erro de comunicação',X.Message,tmErro); end;
  finally V.Free; H.Free; end; end;

function TfraEmpresas.Visivel(const E: TEmpresaAdmin): Boolean;
begin case FFiltro of efAtivas:Result:=E.Ativo; efInativas:Result:=not E.Ativo;
  else Result:=True; end; end;
procedure TfraEmpresas.PreencherLista;
var E:TEmpresaAdmin; C:TRectangle; T,A:TLayout; N,D,S:TLabel;
  B1,B2:TfraSensorButton; I,P,Q:Integer; ST:string; Cor:TAlphaColor;
begin while FListaConteudo.ChildrenCount>0 do FListaConteudo.Children[0].Free;
  Q:=0; for E in FEmpresas do if Visivel(E) then Inc(Q); FListaConteudo.Height:=Q*68; P:=0;
  for I:=0 to FEmpresas.Count-1 do begin E:=FEmpresas[I]; if not Visivel(E) then Continue;
    if E.Ativo then begin ST:='ATIVA'; Cor:=$FF45D483; end else begin ST:='INATIVA'; Cor:=$FFFFB454; end;
    C:=TRectangle.Create(Self); C.Parent:=FListaConteudo; C.Position.Point:=PointF(4,P*68+2);
    C.Width:=FListaConteudo.Width-8; C.Height:=62; C.Anchors:=[TAnchorKind.akLeft,TAnchorKind.akTop,TAnchorKind.akRight];
    C.Fill.Color:=$FF152439; C.Stroke.Color:=$FF23364D; C.XRadius:=7; C.YRadius:=7;
    A:=TLayout.Create(Self); A.Parent:=C; A.Align:=TAlignLayout.Right; A.Width:=190;
    B1:=Botao(A,'',38,EditarClick); B1.Align:=TAlignLayout.None; B1.Position.Point:=PointF(0,14);
    B1.Icone:=sbiEditar; B1.Tag:=I; BotaoIcone(B1,'Editar empresa');
    B2:=Botao(A,'',38,AtivoClick); B2.Align:=TAlignLayout.None; B2.Position.Point:=PointF(46,14); B2.Tag:=I;
    if E.Ativo then begin B2.Icone:=sbiBloquear; BotaoIcone(B2,'Desativar empresa'); end
    else begin B2.Icone:=sbiAtivar; BotaoIcone(B2,'Ativar empresa'); end;
    S:=Rotulo(A,ST,92,0,86,62,Cor,9); S.TextSettings.HorzAlign:=TTextAlign.Trailing;
    T:=TLayout.Create(Self); T.Parent:=C; T.Align:=TAlignLayout.Client; T.Margins.Left:=14; T.HitTest:=False;
    N:=Rotulo(T,E.NomeFantasia,0,5,600,24,$FFF4F7FB,11); N.Align:=TAlignLayout.Top;
    N.TextSettings.Font.Style:=[TFontStyle.fsBold];
    D:=Rotulo(T,E.RazaoSocial+'  •  '+E.Telefone+'  •  '+E.Email+
      '  •  PIX: '+E.PixProvedor,0,31,800,22,$FF8795A8,9);
    D.Align:=TAlignLayout.Bottom; D.Margins.Bottom:=5; Inc(P); end;
  FEstado.Text:=Format('%d empresa(s) encontrada(s)',[Q]); end;

procedure TfraEmpresas.AtualizarFiltros;
begin FBtnTodas.Estilo:=sbsSecondary; FBtnAtivas.Estilo:=sbsSecondary; FBtnInativas.Estilo:=sbsSecondary;
  case FFiltro of efTodas:FBtnTodas.Estilo:=sbsPrimary; efAtivas:FBtnAtivas.Estilo:=sbsPrimary;
    efInativas:FBtnInativas.Estilo:=sbsPrimary; end; end;
procedure TfraEmpresas.FiltroClick(Sender:TObject);
begin FFiltro:=TEmpresaFiltro(TfraSensorButton(Sender).Tag); AtualizarFiltros; PreencherLista; end;
function TfraEmpresas.Selecionada:TEmpresaAdmin;
begin Result:=nil; if (FSelecionado>=0) and (FSelecionado<FEmpresas.Count) then Result:=FEmpresas[FSelecionado]; end;
procedure TfraEmpresas.NovoClick(Sender:TObject); begin AbrirEditor(nil); end;
procedure TfraEmpresas.EditarClick(Sender:TObject);
begin FSelecionado:=TfraSensorButton(Sender).Tag; AbrirEditor(Selecionada); end;
procedure TfraEmpresas.AbrirEditor(const E:TEmpresaAdmin);
begin if Assigned(E) then begin FEditandoId:=E.Id; FTituloEdicao.Text:='Editar empresa';
    FRazaoSocial.Text:=E.RazaoSocial; FNomeFantasia.Text:=E.NomeFantasia;
    FLogoUrl.Text:=E.LogoUrl; FTelefone.Text:=E.Telefone; FEmail.Text:=E.Email;
    FTimezone.Text:=E.Timezone;
    if SameText(E.PixProvedor,'SICREDI') then FPixProvedor.ItemIndex:=1
    else FPixProvedor.ItemIndex:=0; PixProvedorChange(nil); end
  else begin FEditandoId:=''; FTituloEdicao.Text:='Nova empresa';
    FRazaoSocial.Text:=''; FNomeFantasia.Text:=''; FLogoUrl.Text:=''; FTelefone.Text:='';
    FEmail.Text:=''; FTimezone.Text:='America/Sao_Paulo';
    FPixProvedor.ItemIndex:=0; PixProvedorChange(nil); end;
  FPainelEdicao.Visible:=True; FPainelEdicao.BringToFront; FRazaoSocial.SetFocus; end;
procedure TfraEmpresas.FecharEditor; begin FPainelEdicao.Visible:=False; FEditandoId:=''; end;
procedure TfraEmpresas.CancelarClick(Sender:TObject); begin FecharEditor; end;

procedure TfraEmpresas.SalvarClick(Sender:TObject);
var H:TNetHTTPClient; J:TJSONObject; S:TStringStream; R:IHTTPResponse;
begin if FRazaoSocial.Text.Trim.IsEmpty or FNomeFantasia.Text.Trim.IsEmpty then
  begin TfrmMensagem.Exibir('Campos obrigatórios','Informe a razão social e o nome fantasia.',tmAtencao); Exit; end;
  J:=TJSONObject.Create; J.AddPair('razaoSocial',FRazaoSocial.Text.Trim);
  J.AddPair('nomeFantasia',FNomeFantasia.Text.Trim); J.AddPair('logoUrl',FLogoUrl.Text.Trim);
  J.AddPair('telefone',FTelefone.Text.Trim); J.AddPair('email',FEmail.Text.Trim);
  J.AddPair('timezone',FTimezone.Text.Trim);
  if FPixProvedor.ItemIndex=1 then J.AddPair('pixProvedor','SICREDI')
  else J.AddPair('pixProvedor','ASAAS');
  H:=TNetHTTPClient.Create(nil); TSessaoAdmin.ConfigurarCliente(H);
  S:=TStringStream.Create(J.ToJSON,TEncoding.UTF8);
  try H.ContentType:='application/json'; if FEditandoId.IsEmpty then R:=H.Post(URL_EMPRESAS,S)
    else R:=H.Put(URL_EMPRESAS+'/'+FEditandoId,S);
    if not (R.StatusCode in [200,201]) then begin ExibirErro('Não foi possível salvar a empresa',R); Exit; end;
    FecharEditor; CarregarEmpresas; TfrmMensagem.Exibir('Empresa salva','Dados salvos com sucesso.',tmSucesso);
  finally S.Free; H.Free; J.Free; end; end;
procedure TfraEmpresas.AtivoClick(Sender:TObject);
var E:TEmpresaAdmin; H:TNetHTTPClient; J:TJSONObject; S:TStringStream; R:IHTTPResponse;
begin FSelecionado:=TfraSensorButton(Sender).Tag; E:=Selecionada; if not Assigned(E) then Exit;
  J:=TJSONObject.Create; J.AddPair('ativo',TJSONBool.Create(not E.Ativo)); H:=TNetHTTPClient.Create(nil); TSessaoAdmin.ConfigurarCliente(H);
  S:=TStringStream.Create(J.ToJSON,TEncoding.UTF8); try H.ContentType:='application/json';
    R:=H.Patch(URL_EMPRESAS+'/'+E.Id+'/situacao',S); if R.StatusCode<>200 then ExibirErro('Erro ao alterar empresa',R)
    else CarregarEmpresas; finally S.Free; H.Free; J.Free; end; end;
procedure TfraEmpresas.BuscarClick(Sender:TObject); begin FTimerBusca.Enabled:=False; CarregarEmpresas; end;
procedure TfraEmpresas.BuscaChange(Sender:TObject); begin FTimerBusca.Enabled:=False; FTimerBusca.Enabled:=True; end;
procedure TfraEmpresas.TimerBusca(Sender:TObject); begin FTimerBusca.Enabled:=False; CarregarEmpresas; end;
procedure TfraEmpresas.BuscaKeyDown(Sender:TObject;var Key:Word;var KeyChar:Char;Shift:TShiftState);
begin if Key=vkReturn then begin Key:=0; KeyChar:=#0; BuscarClick(nil); end; end;
procedure TfraEmpresas.PixProvedorChange(Sender:TObject);
begin
  if not (FPixProvedor.TagObject is TLabel) then Exit;
  if (FPixProvedor.ItemIndex>=0) and (FPixProvedor.ItemIndex<FPixProvedor.Count) then
    TLabel(FPixProvedor.TagObject).Text:=FPixProvedor.Items[FPixProvedor.ItemIndex]
  else TLabel(FPixProvedor.TagObject).Text:='Selecione...';
end;
procedure TfraEmpresas.SelecionarLogoClick(Sender:TObject);
var URL:string;
begin try if TImagemUpload.SelecionarEEnviar(Self,URL) then FLogoUrl.Text:=URL;
  except on E:Exception do TfrmMensagem.Exibir('Erro ao enviar imagem',E.Message,tmErro); end; end;
procedure TfraEmpresas.ExibirErro(const Titulo:string;const R:IHTTPResponse);
var V:TJSONValue; M:string;
begin M:='A API retornou '+IntToStr(R.StatusCode)+'.'; V:=TJSONObject.ParseJSONValue(R.ContentAsString(TEncoding.UTF8));
  try if V is TJSONObject then M:=TJSONObject(V).GetValue<string>('erro',M); finally V.Free; end;
  TfrmMensagem.Exibir(Titulo,M,tmErro); end;
end.
