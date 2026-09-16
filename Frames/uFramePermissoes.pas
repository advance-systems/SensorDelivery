unit uFramePermissoes;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.JSON,
  System.Net.URLClient, System.Net.HttpClient, System.Net.HttpClientComponent,
  System.NetEncoding, System.Generics.Collections, System.Math,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Objects,
  FMX.Layouts, FMX.Controls.Presentation, FMX.ListBox, uFrameSensorButton;

type
  TEmpresaPermissao = class
  public Id, Nome: string; end;

  TUsuarioPermissao = class
  public
    Id, Nome, Email, Tipo: string;
    Empresas: TObjectList<TEmpresaPermissao>;
    constructor Create;
    destructor Destroy; override;
  end;

  TPermissaoAdmin = class
  public Codigo, Nome, Modulo, Acao: string; end;

  TfraPermissoes = class(TFrame)
    rctFundo: TRectangle;
    lytPrincipal, lytCabecalho, lytConteudo: TLayout;
    lblTitulo, lblSubtitulo: TLabel;
  private
    FUsuarios: TObjectList<TUsuarioPermissao>;
    FPermissoes: TObjectList<TPermissaoAdmin>;
    FChecks: TObjectList<TCheckBox>;
    FUsuario, FEmpresa: TComboBox;
    FLista: TVertScrollBox;
    FListaConteudo: TLayout;
    FEstado: TLabel;
    FBtnTodas, FBtnNenhuma, FBtnSalvar: TfraSensorButton;
    FCarregado: Boolean;
    FAtualizandoChecks: Boolean;
    procedure MontarTela;
    function Rotulo(const Parent: TFmxObject; const Texto: string;
      X, Y, W, H: Single; Cor: TAlphaColor; Tamanho: Single): TLabel;
    function Botao(const Parent: TFmxObject; const Texto: string; Largura: Single;
      Click: TNotifyEvent): TfraSensorButton;
    function CriarCombo(const Parent: TFmxObject; const Titulo: string;
      X, Largura: Single): TComboBox;
    procedure AtualizarComboVisual(const Combo: TComboBox);
    function MensagemResposta(const R: IHTTPResponse; const Padrao: string): string;
    procedure CarregarUsuarios;
    procedure CarregarCatalogo;
    procedure MontarLista;
    procedure CarregarPermissoes;
    procedure UsuarioChange(Sender: TObject);
    procedure EmpresaChange(Sender: TObject);
    procedure TodasClick(Sender: TObject);
    procedure NenhumaClick(Sender: TObject);
    procedure SalvarClick(Sender: TObject);
    procedure PermissaoChange(Sender: TObject);
    function ColunaAcao(const Acao: string): Integer;
    function UsuarioAtual: TUsuarioPermissao;
    function EmpresaAtual: TEmpresaPermissao;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure PrepararTela;
  end;

implementation

{$R *.fmx}

uses uMensagem, uSessaoAdmin, uApiConfig;

function URL_USUARIOS: string;
begin
  Result := TApiConfig.Url('/api/usuarios');
end;

function URL_PERMISSOES: string;
begin
  Result := TApiConfig.Url('/api/permissoes');
end;

constructor TUsuarioPermissao.Create;
begin inherited; Empresas := TObjectList<TEmpresaPermissao>.Create(True); end;
destructor TUsuarioPermissao.Destroy;
begin Empresas.Free; inherited; end;

constructor TfraPermissoes.Create(AOwner: TComponent);
begin
  inherited;
  FUsuarios := TObjectList<TUsuarioPermissao>.Create(True);
  FPermissoes := TObjectList<TPermissaoAdmin>.Create(True);
  FChecks := TObjectList<TCheckBox>.Create(False);
  MontarTela;
end;

destructor TfraPermissoes.Destroy;
begin FChecks.Free; FPermissoes.Free; FUsuarios.Free; inherited; end;

function TfraPermissoes.Rotulo(const Parent: TFmxObject; const Texto: string;
  X, Y, W, H: Single; Cor: TAlphaColor; Tamanho: Single): TLabel;
begin
  Result:=TLabel.Create(Self); Result.Parent:=Parent;
  Result.Position.Point:=PointF(X,Y); Result.Width:=W; Result.Height:=H;
  Result.Text:=Texto; Result.StyledSettings:=[];
  Result.TextSettings.Font.Family:='Manrope'; Result.TextSettings.Font.Size:=Tamanho;
  Result.TextSettings.FontColor:=Cor;
end;

function TfraPermissoes.Botao(const Parent: TFmxObject; const Texto: string;
  Largura: Single; Click: TNotifyEvent): TfraSensorButton;
begin
  Result:=TfraSensorButton.Create(Self); Result.Name:=''; Result.Parent:=Parent;
  Result.Align:=TAlignLayout.Left; Result.Width:=Largura; Result.Margins.Right:=8;
  Result.Texto:=Texto; Result.Estilo:=sbsSecondary; Result.OnButtonClick:=Click;
end;

function TfraPermissoes.CriarCombo(const Parent: TFmxObject; const Titulo: string;
  X, Largura: Single): TComboBox;
var Fundo, Mascara: TRectangle; Texto, Seta: TLabel;
begin
  Rotulo(Parent,Titulo,X,0,Largura,18,$FF9CAABC,10);
  Fundo:=TRectangle.Create(Self); Fundo.Parent:=Parent;
  Fundo.Position.Point:=PointF(X,22); Fundo.Width:=Largura; Fundo.Height:=40;
  Fundo.Fill.Color:=$FF152439; Fundo.Stroke.Color:=$FF2A405B;
  Fundo.XRadius:=7; Fundo.YRadius:=7;
  Result:=TComboBox.Create(Self); Result.Parent:=Fundo; Result.Align:=TAlignLayout.Client;
  Mascara:=TRectangle.Create(Self); Mascara.Parent:=Fundo;
  Mascara.Align:=TAlignLayout.Client; Mascara.Fill.Color:=$FF152439;
  Mascara.Stroke.Kind:=TBrushKind.None; Mascara.HitTest:=False;
  Texto:=Rotulo(Mascara,'Selecione...',12,0,Largura-48,40,$FFF4F7FB,11);
  Texto.TextSettings.VertAlign:=TTextAlign.Center; Texto.HitTest:=False;
  Seta:=Rotulo(Mascara,'⌄',Largura-34,0,24,40,$FF9CAABC,16);
  Seta.TextSettings.HorzAlign:=TTextAlign.Center;
  Seta.TextSettings.VertAlign:=TTextAlign.Center; Seta.HitTest:=False;
  Seta.Anchors:=[TAnchorKind.akTop,TAnchorKind.akRight];
  Result.TagObject:=Texto; Mascara.BringToFront;
end;

procedure TfraPermissoes.AtualizarComboVisual(const Combo:TComboBox);
begin
  if not Assigned(Combo) or not (Combo.TagObject is TLabel) then Exit;
  if (Combo.ItemIndex>=0) and (Combo.ItemIndex<Combo.Count) then
    TLabel(Combo.TagObject).Text:=Combo.Items[Combo.ItemIndex]
  else TLabel(Combo.TagObject).Text:='Selecione...';
end;

procedure TfraPermissoes.MontarTela;
var Filtros, Barra: TLayout; Fundo: TRectangle;
begin
  Filtros:=TLayout.Create(Self); Filtros.Parent:=lytConteudo;
  Filtros.Align:=TAlignLayout.Top; Filtros.Height:=70; Filtros.Margins.Bottom:=12;
  FUsuario:=CriarCombo(Filtros,'Usuário',0,390); FUsuario.OnChange:=UsuarioChange;
  FEmpresa:=CriarCombo(Filtros,'Empresa',410,390); FEmpresa.OnChange:=EmpresaChange;

  Barra:=TLayout.Create(Self); Barra.Parent:=lytConteudo;
  Barra.Align:=TAlignLayout.Top; Barra.Height:=42; Barra.Margins.Bottom:=10;
  FBtnTodas:=Botao(Barra,'Marcar todas',126,TodasClick); FBtnTodas.Icone:=sbiAtivar;
  FBtnNenhuma:=Botao(Barra,'Limpar',116,NenhumaClick); FBtnNenhuma.Icone:=sbiCancelar;
  FBtnSalvar:=Botao(Barra,'Salvar permissões',160,SalvarClick);
  FBtnSalvar.Align:=TAlignLayout.Right; FBtnSalvar.Estilo:=sbsPrimary;
  FBtnSalvar.Icone:=sbiSalvar;

  Fundo:=TRectangle.Create(Self); Fundo.Parent:=lytConteudo;
  Fundo.Align:=TAlignLayout.Client; Fundo.Fill.Color:=$FF111E2E;
  Fundo.Stroke.Color:=$FF23364D; Fundo.XRadius:=10; Fundo.YRadius:=10;
  FEstado:=Rotulo(Fundo,'Selecione um usuário e uma empresa.',20,14,700,24,
    $FF8795A8,11);
  FLista:=TVertScrollBox.Create(Self); FLista.Parent:=Fundo;
  FLista.Align:=TAlignLayout.Client; FLista.Margins.Rect:=RectF(12,48,12,12);
  FListaConteudo:=TLayout.Create(Self); FListaConteudo.Parent:=FLista;
  FListaConteudo.Align:=TAlignLayout.Top; FListaConteudo.Height:=1;
end;

function TfraPermissoes.MensagemResposta(const R: IHTTPResponse;
  const Padrao: string): string;
var V:TJSONValue;
begin
  Result:=Padrao; V:=TJSONObject.ParseJSONValue(R.ContentAsString(TEncoding.UTF8));
  try if V is TJSONObject then Result:=TJSONObject(V).GetValue<string>('erro',Padrao);
  finally V.Free; end;
end;

procedure TfraPermissoes.CarregarUsuarios;
var H:TNetHTTPClient; R:IHTTPResponse; V,Item,EI:TJSONValue; A,EA:TJSONArray;
  J,EJ:TJSONObject; U:TUsuarioPermissao; E:TEmpresaPermissao;
begin
  H:=TNetHTTPClient.Create(nil); V:=nil;
  try TSessaoAdmin.ConfigurarCliente(H); R:=H.Get(URL_USUARIOS);
    if R.StatusCode<>200 then raise Exception.Create(MensagemResposta(R,'Não foi possível listar os usuários.'));
    V:=TJSONObject.ParseJSONValue(R.ContentAsString(TEncoding.UTF8));
    A:=TJSONObject(V).GetValue<TJSONArray>('usuarios'); FUsuarios.Clear; FUsuario.Clear;
    for Item in A do begin J:=Item as TJSONObject;
      if not J.GetValue<Boolean>('ativo',True) then Continue;
      U:=TUsuarioPermissao.Create; U.Id:=J.GetValue<string>('id','');
      U.Nome:=J.GetValue<string>('nome',''); U.Email:=J.GetValue<string>('email','');
      U.Tipo:=J.GetValue<string>('tipo',''); EA:=J.GetValue<TJSONArray>('empresas');
      if Assigned(EA) then for EI in EA do begin EJ:=EI as TJSONObject;
        E:=TEmpresaPermissao.Create; E.Id:=EJ.GetValue<string>('id','');
        E.Nome:=EJ.GetValue<string>('nome_fantasia',''); U.Empresas.Add(E); end;
      FUsuarios.Add(U); FUsuario.Items.Add(U.Nome+'  ('+U.Email+')');
    end;
    if FUsuario.Count>0 then FUsuario.ItemIndex:=0;
  finally V.Free; H.Free; end;
end;

procedure TfraPermissoes.CarregarCatalogo;
var H:TNetHTTPClient; R:IHTTPResponse; V,Item:TJSONValue; A:TJSONArray;
  J:TJSONObject; P:TPermissaoAdmin; Posicao:Integer;
begin
  H:=TNetHTTPClient.Create(nil); V:=nil;
  try TSessaoAdmin.ConfigurarCliente(H); R:=H.Get(URL_PERMISSOES);
    if R.StatusCode<>200 then raise Exception.Create(MensagemResposta(R,'Não foi possível listar as permissões.'));
    V:=TJSONObject.ParseJSONValue(R.ContentAsString(TEncoding.UTF8));
    A:=TJSONObject(V).GetValue<TJSONArray>('permissoes'); FPermissoes.Clear;
    for Item in A do begin J:=Item as TJSONObject; P:=TPermissaoAdmin.Create;
      P.Codigo:=J.GetValue<string>('codigo',''); P.Nome:=J.GetValue<string>('nome','');
      P.Modulo:=J.GetValue<string>('modulo','');
      Posicao:=LastDelimiter('.',P.Codigo);
      if Posicao>0 then P.Acao:=Copy(P.Codigo,Posicao+1,MaxInt) else P.Acao:='';
      FPermissoes.Add(P); end;
    MontarLista;
  finally V.Free; H.Free; end;
end;

function TfraPermissoes.ColunaAcao(const Acao:string):Integer;
begin
  if SameText(Acao,'visualizar') then Result:=0
  else if SameText(Acao,'incluir') then Result:=1
  else if SameText(Acao,'alterar') or SameText(Acao,'editar') then Result:=2
  else if SameText(Acao,'excluir') then Result:=3
  else Result:=-1;
end;

procedure TfraPermissoes.MontarLista;
var I,Y,Coluna:Integer; P:TPermissaoAdmin; C:TCheckBox; Modulo:string;
  T:TLabel; Linha, Cabecalho:TRectangle; W,NomeW,ColW:Single;
const TITULOS:array[0..3] of string=('Acessar','Incluir','Alterar','Excluir');
begin
  while FListaConteudo.ChildrenCount>0 do FListaConteudo.Children[0].Free;
  FChecks.Clear; Y:=0; Modulo:=''; Linha:=nil;
  W:=Max(820,FLista.Width-28); ColW:=105; NomeW:=W-(ColW*4);

  Cabecalho:=TRectangle.Create(Self); Cabecalho.Parent:=FListaConteudo;
  Cabecalho.Position.Point:=PointF(4,Y); Cabecalho.Width:=W; Cabecalho.Height:=36;
  Cabecalho.Fill.Color:=$FF17263A; Cabecalho.Stroke.Kind:=TBrushKind.None;
  Cabecalho.XRadius:=6; Cabecalho.YRadius:=6;
  T:=Rotulo(Cabecalho,'Tela / módulo',14,0,NomeW-18,36,$FF9CAABC,10);
  T.TextSettings.VertAlign:=TTextAlign.Center;
  for Coluna:=0 to 3 do begin
    T:=Rotulo(Cabecalho,TITULOS[Coluna],NomeW+(Coluna*ColW),0,ColW,36,$FF9CAABC,10);
    T.TextSettings.HorzAlign:=TTextAlign.Center;
    T.TextSettings.VertAlign:=TTextAlign.Center;
  end;
  Inc(Y,42);

  for I:=0 to FPermissoes.Count-1 do begin P:=FPermissoes[I];
    if not SameText(Modulo,P.Modulo) then begin Modulo:=P.Modulo;
      Linha:=TRectangle.Create(Self); Linha.Parent:=FListaConteudo;
      Linha.Position.Point:=PointF(4,Y); Linha.Width:=W; Linha.Height:=46;
      Linha.Fill.Color:=$FF152439; Linha.Stroke.Color:=$FF2A405B;
      Linha.XRadius:=7; Linha.YRadius:=7;
      T:=Rotulo(Linha,Modulo,14,0,NomeW-18,46,$FFF4F7FB,11);
      T.TextSettings.Font.Style:=[TFontStyle.fsBold];
      T.TextSettings.VertAlign:=TTextAlign.Center;
      Inc(Y,52);
    end;
    Coluna:=ColunaAcao(P.Acao);
    if Coluna<0 then Continue;
    C:=TCheckBox.Create(Self); C.Parent:=FListaConteudo;
    C.Parent:=Linha; C.Position.Point:=PointF(
      NomeW+(Coluna*ColW)+((ColW-26)/2),10);
    C.Width:=26; C.Height:=26; C.Text:=''; C.Tag:=I;
    C.OnChange:=PermissaoChange; FChecks.Add(C);
  end;
  FListaConteudo.Height:=Y+8;
end;

procedure TfraPermissoes.PermissaoChange(Sender:TObject);
var I,J:Integer; Acao,Modulo:string;
begin
  if FAtualizandoChecks or not (Sender is TCheckBox) then Exit;
  I:=TCheckBox(Sender).Tag;
  if (I<0) or (I>=FPermissoes.Count) then Exit;
  Acao:=FPermissoes[I].Acao; Modulo:=FPermissoes[I].Modulo;
  FAtualizandoChecks:=True;
  try
    if SameText(Acao,'visualizar') and not TCheckBox(Sender).IsChecked then begin
      for J:=0 to FChecks.Count-1 do
        if SameText(FPermissoes[J].Modulo,Modulo) then FChecks[J].IsChecked:=False;
    end else if not SameText(Acao,'visualizar') and TCheckBox(Sender).IsChecked then begin
      for J:=0 to FChecks.Count-1 do
        if SameText(FPermissoes[J].Modulo,Modulo)
          and SameText(FPermissoes[J].Acao,'visualizar') then begin
          FChecks[J].IsChecked:=True; Break;
        end;
    end;
  finally FAtualizandoChecks:=False; end;
end;

function TfraPermissoes.UsuarioAtual:TUsuarioPermissao;
begin Result:=nil; if (FUsuario.ItemIndex>=0) and (FUsuario.ItemIndex<FUsuarios.Count) then Result:=FUsuarios[FUsuario.ItemIndex]; end;
function TfraPermissoes.EmpresaAtual:TEmpresaPermissao;
var U:TUsuarioPermissao;
begin Result:=nil; U:=UsuarioAtual; if Assigned(U) and (FEmpresa.ItemIndex>=0)
  and (FEmpresa.ItemIndex<U.Empresas.Count) then Result:=U.Empresas[FEmpresa.ItemIndex]; end;

procedure TfraPermissoes.UsuarioChange(Sender:TObject);
var U:TUsuarioPermissao; E:TEmpresaPermissao;
begin
  AtualizarComboVisual(FUsuario);
  FEmpresa.OnChange:=nil; FEmpresa.Clear; U:=UsuarioAtual;
  if Assigned(U) then for E in U.Empresas do FEmpresa.Items.Add(E.Nome);
  if FEmpresa.Count>0 then FEmpresa.ItemIndex:=0;
  FEmpresa.OnChange:=EmpresaChange; AtualizarComboVisual(FEmpresa); CarregarPermissoes;
end;

procedure TfraPermissoes.EmpresaChange(Sender:TObject);
begin AtualizarComboVisual(FEmpresa); CarregarPermissoes; end;

procedure TfraPermissoes.CarregarPermissoes;
var U:TUsuarioPermissao; E:TEmpresaPermissao; H:TNetHTTPClient; R:IHTTPResponse;
  V,Item:TJSONValue; A:TJSONArray; Selecionadas:TStringList; I:Integer;
  PodeAlterar:Boolean;
begin
  U:=UsuarioAtual; E:=EmpresaAtual; if not Assigned(U) or not Assigned(E) then Exit;
  if SameText(U.Tipo,'ADMIN') then begin
    FAtualizandoChecks:=True;
    try for I:=0 to FChecks.Count-1 do begin
      FChecks[I].IsChecked:=True; FChecks[I].Enabled:=False;
    end;
    finally FAtualizandoChecks:=False; end;
    FBtnSalvar.Enabled:=False; FBtnTodas.Enabled:=False; FBtnNenhuma.Enabled:=False;
    FEstado.Text:='Administradores possuem acesso total automaticamente.'; Exit; end;
  PodeAlterar:=TSessaoAdmin.Pode('permissoes.alterar');
  FBtnSalvar.Enabled:=PodeAlterar; FBtnTodas.Enabled:=PodeAlterar;
  FBtnNenhuma.Enabled:=PodeAlterar;
  for I:=0 to FChecks.Count-1 do FChecks[I].Enabled:=PodeAlterar;
  H:=TNetHTTPClient.Create(nil); V:=nil; Selecionadas:=TStringList.Create;
  try TSessaoAdmin.ConfigurarCliente(H);
    R:=H.Get(URL_PERMISSOES+'/usuario/'+U.Id+'?empresaId='+TNetEncoding.URL.Encode(E.Id));
    if R.StatusCode<>200 then raise Exception.Create(MensagemResposta(R,'Não foi possível carregar as permissões.'));
    V:=TJSONObject.ParseJSONValue(R.ContentAsString(TEncoding.UTF8));
    A:=TJSONObject(V).GetValue<TJSONArray>('permissoes');
    for Item in A do Selecionadas.Add(Item.Value);
    FAtualizandoChecks:=True;
    try for I:=0 to FChecks.Count-1 do
      FChecks[I].IsChecked:=Selecionadas.IndexOf(FPermissoes[I].Codigo)>=0;
    finally FAtualizandoChecks:=False; end;
    FEstado.Text:='Permissões de '+U.Nome+' em '+E.Nome;
    if not PodeAlterar then FEstado.Text:=FEstado.Text+' (somente consulta)';
  except on X:Exception do TfrmMensagem.Exibir('Erro ao carregar permissões',X.Message,tmErro); end;
  Selecionadas.Free; V.Free; H.Free;
end;

procedure TfraPermissoes.TodasClick(Sender:TObject);
var I:Integer; begin FAtualizandoChecks:=True; try
  for I:=0 to FChecks.Count-1 do FChecks[I].IsChecked:=True;
  finally FAtualizandoChecks:=False; end; end;
procedure TfraPermissoes.NenhumaClick(Sender:TObject);
var I:Integer; begin FAtualizandoChecks:=True; try
  for I:=0 to FChecks.Count-1 do FChecks[I].IsChecked:=False;
  finally FAtualizandoChecks:=False; end; end;

procedure TfraPermissoes.SalvarClick(Sender:TObject);
var U:TUsuarioPermissao; E:TEmpresaPermissao; J:TJSONObject; A:TJSONArray;
  I:Integer; H:TNetHTTPClient; S:TStringStream; R:IHTTPResponse;
begin
  U:=UsuarioAtual; E:=EmpresaAtual; if not Assigned(U) or not Assigned(E) then Exit;
  J:=TJSONObject.Create; H:=TNetHTTPClient.Create(nil);
  try J.AddPair('empresaId',E.Id); A:=TJSONArray.Create;
    for I:=0 to FChecks.Count-1 do if FChecks[I].IsChecked then A.Add(FPermissoes[I].Codigo);
    J.AddPair('permissoes',A); S:=TStringStream.Create(J.ToJSON,TEncoding.UTF8);
    try H.ContentType:='application/json'; TSessaoAdmin.ConfigurarCliente(H);
      R:=H.Put(URL_PERMISSOES+'/usuario/'+U.Id,S); finally S.Free; end;
    if R.StatusCode<>200 then TfrmMensagem.Exibir('Erro ao salvar permissões',MensagemResposta(R,'Não foi possível salvar as permissões.'),tmErro)
    else TfrmMensagem.Exibir('Permissões salvas',
      'Os acessos foram atualizados. O usuário deve entrar novamente para aplicá-los.',tmSucesso);
  except on X:Exception do TfrmMensagem.Exibir('Erro de comunicação',X.Message,tmErro); end;
  H.Free; J.Free;
end;

procedure TfraPermissoes.PrepararTela;
begin
  if FCarregado then Exit;
  try CarregarCatalogo; CarregarUsuarios; FCarregado:=True;
  except on X:Exception do TfrmMensagem.Exibir('Erro ao abrir permissões',X.Message,tmErro); end;
end;

end.
