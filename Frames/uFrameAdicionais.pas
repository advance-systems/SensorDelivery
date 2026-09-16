unit uFrameAdicionais;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.JSON,
  System.Net.URLClient, System.Net.HttpClient, System.Net.HttpClientComponent,
  System.NetEncoding, System.Generics.Collections,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Objects, FMX.Layouts,
  FMX.Controls.Presentation, FMX.Edit, FMX.ListBox, uFrameSensorButton;

type
  TCategoriaAdicional = class
  public Id, Nome: string; end;
  TProdutoAdicional = class
  public Id, Nome, Categoria, CategoriaId: string; end;
  TAdicionalAdmin = class
  public
    Id, ProdutoId, ProdutoNome, CategoriaId, Nome: string;
    Preco: Currency; Limite, Ordem: Integer; Obrigatorio, Ativo: Boolean;
  end;

  TfraAdicionais = class(TFrame)
  private
    FProdutos: TObjectList<TProdutoAdicional>;
    FCategorias: TObjectList<TCategoriaAdicional>;
    FProdutosFiltrados: TList<TProdutoAdicional>;
    FAdicionais: TObjectList<TAdicionalAdmin>;
    FCarregado: Boolean;
    FEditandoId: string;
    FListaConteudo: TLayout;
    FLista: TVertScrollBox;
    FEstado, FTituloEdicao: TLabel;
    FBusca, FNome, FPreco, FLimite, FOrdem: TEdit;
    FCategoria, FProduto: TComboBox;
    FObrigatorio: Boolean;
    FBtnObrigatorio: TfraSensorButton;
    FPainel: TRectangle;
    FTimer: TTimer;
    function Rotulo(AParent: TFmxObject; const Texto: string; X,Y,W,H,Tam: Single; Cor: TAlphaColor): TLabel;
    function Fundo(AParent: TFmxObject; X,Y,W,H: Single): TRectangle;
    function Botao(AParent: TFmxObject; const Texto: string; W: Single; Evento: TNotifyEvent): TfraSensorButton;
    procedure CarregarProdutos;
    procedure CarregarCategorias;
    procedure PreencherProdutosDaCategoria;
    procedure CarregarAdicionais;
    procedure PreencherLista;
    procedure AbrirEditor(AAdicional: TAdicionalAdmin);
    procedure NovoClick(Sender: TObject);
    procedure EditarClick(Sender: TObject);
    procedure SituacaoClick(Sender: TObject);
    procedure ObrigatorioClick(Sender: TObject);
    procedure SalvarClick(Sender: TObject);
    procedure CancelarClick(Sender: TObject);
    procedure BuscaChange(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure PrepararComboEscuro(const Combo: TComboBox;
      const AFundo: TRectangle);
    procedure AtualizarComboVisual(const Combo: TComboBox);
    procedure ComboVisualChange(Sender: TObject);
    procedure CategoriaChange(Sender: TObject);
    procedure ExibirErro(const Titulo: string; Resposta: IHTTPResponse);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure PrepararTela;
  end;

implementation

{$R *.fmx}

uses uSessaoAdmin, uApiConfig, uMensagem, uNavegacaoCampos;

function TfraAdicionais.Rotulo(AParent: TFmxObject; const Texto: string;
  X,Y,W,H,Tam: Single; Cor: TAlphaColor): TLabel;
begin
  Result:=TLabel.Create(Self); Result.Parent:=AParent; Result.Position.Point:=PointF(X,Y);
  Result.Width:=W; Result.Height:=H; Result.Text:=Texto; Result.StyledSettings:=[];
  Result.TextSettings.Font.Family:='Manrope'; Result.TextSettings.Font.Size:=Tam;
  Result.TextSettings.FontColor:=Cor;
end;

function TfraAdicionais.Fundo(AParent: TFmxObject; X,Y,W,H: Single): TRectangle;
begin
  Result:=TRectangle.Create(Self); Result.Parent:=AParent; Result.Position.Point:=PointF(X,Y);
  Result.Width:=W; Result.Height:=H; Result.Fill.Color:=$FF152439;
  Result.Stroke.Color:=$FF2A405B; Result.XRadius:=7; Result.YRadius:=7;
end;

function TfraAdicionais.Botao(AParent: TFmxObject; const Texto: string;
  W: Single; Evento: TNotifyEvent): TfraSensorButton;
begin
  Result:=TfraSensorButton.Create(Self); Result.Name:=''; Result.Parent:=AParent;
  Result.Width:=W; Result.Height:=38; Result.Texto:=Texto; Result.Estilo:=sbsSecondary;
  Result.OnButtonClick:=Evento;
end;

constructor TfraAdicionais.Create(AOwner: TComponent);
var Root, Cab, Conteudo, Barra, ListaFundo, Form: TLayout; Campo, R: TRectangle;
  B: TfraSensorButton;
begin
  inherited;
  FProdutos:=TObjectList<TProdutoAdicional>.Create(True);
  FCategorias:=TObjectList<TCategoriaAdicional>.Create(True);
  FProdutosFiltrados:=TList<TProdutoAdicional>.Create;
  FAdicionais:=TObjectList<TAdicionalAdmin>.Create(True);
  Align:=TAlignLayout.Client;
  R:=TRectangle.Create(Self); R.Parent:=Self; R.Align:=TAlignLayout.Client;
  R.Fill.Color:=$FF0B1422; R.Stroke.Kind:=TBrushKind.None;
  Root:=TLayout.Create(Self); Root.Parent:=R; Root.Align:=TAlignLayout.Client;
  Root.Padding.Rect:=RectF(24,20,24,20);
  Cab:=TLayout.Create(Self); Cab.Parent:=Root; Cab.Align:=TAlignLayout.Top; Cab.Height:=74;
  Rotulo(Cab,'Adicionais',0,0,500,36,24,$FFF4F7FB).TextSettings.Font.Style:=[TFontStyle.fsBold];
  Rotulo(Cab,'Cadastre os adicionais disponíveis para cada produto.',0,38,700,24,11,$FF8795A8);
  Conteudo:=TLayout.Create(Self); Conteudo.Parent:=Root; Conteudo.Align:=TAlignLayout.Client;
  Barra:=TLayout.Create(Self); Barra.Parent:=Conteudo; Barra.Align:=TAlignLayout.Top; Barra.Height:=56;
  B:=Botao(Barra,'+ Novo adicional',150,NovoClick); B.Align:=TAlignLayout.Right; B.Estilo:=sbsPrimary; B.Icone:=sbiCardapio;
  Campo:=Fundo(Barra,0,0,100,44); Campo.Align:=TAlignLayout.Client; Campo.Margins.Right:=12;
  FBusca:=TEdit.Create(Self); FBusca.Parent:=Campo; FBusca.Align:=TAlignLayout.Client;
  FBusca.Margins.Rect:=RectF(12,0,12,0); FBusca.StyleLookup:='transparentedit';
  FBusca.StyledSettings:=[]; FBusca.TextSettings.FontColor:=$FFF4F7FB;
  FBusca.TextPrompt:='Buscar adicional ou produto'; FBusca.OnTyping:=BuscaChange;
  FTimer:=TTimer.Create(Self); FTimer.Interval:=400; FTimer.Enabled:=False; FTimer.OnTimer:=TimerTimer;
  FPainel:=TRectangle.Create(Self); FPainel.Parent:=Conteudo; FPainel.Align:=TAlignLayout.Right;
  FPainel.Width:=370; FPainel.Margins.Left:=14; FPainel.Fill.Color:=$FF111E2E;
  FPainel.Stroke.Color:=$FF2A405B; FPainel.XRadius:=10; FPainel.YRadius:=10; FPainel.Visible:=False;
  FTituloEdicao:=Rotulo(FPainel,'Novo adicional',20,16,330,30,16,$FFF4F7FB);
  FTituloEdicao.TextSettings.Font.Style:=[TFontStyle.fsBold];
  Form:=TLayout.Create(Self); Form.Parent:=FPainel; Form.Align:=TAlignLayout.Client;
  Rotulo(Form,'Categoria *',20,58,330,20,10,$FF9CAABC);
  R:=Fundo(Form,20,80,330,40);
  FCategoria:=TComboBox.Create(Self); FCategoria.Parent:=R;
  FCategoria.Align:=TAlignLayout.Client;
  PrepararComboEscuro(FCategoria,R);
  FCategoria.OnChange:=CategoriaChange;
  Rotulo(Form,'Produto *',20,128,330,20,10,$FF9CAABC);
  R:=Fundo(Form,20,150,330,40);
  FProduto:=TComboBox.Create(Self); FProduto.Parent:=R;
  FProduto.Align:=TAlignLayout.Client;
  PrepararComboEscuro(FProduto,R);
  Rotulo(Form,'Nome *',20,200,330,20,10,$FF9CAABC); R:=Fundo(Form,20,222,330,38);
  FNome:=TEdit.Create(Self); FNome.Parent:=R; FNome.Align:=TAlignLayout.Client; FNome.Margins.Rect:=RectF(10,0,10,0);
  FNome.StyleLookup:='transparentedit'; FNome.StyledSettings:=[]; FNome.TextSettings.FontColor:=$FFF4F7FB;
  Rotulo(Form,'Pre'+Char($00E7)+'o *',20,272,150,20,10,$FF9CAABC); Rotulo(Form,'Limite *',200,272,150,20,10,$FF9CAABC);
  R:=Fundo(Form,20,294,150,38); FPreco:=TEdit.Create(Self); FPreco.Parent:=R; FPreco.Align:=TAlignLayout.Client;
  FPreco.Margins.Rect:=RectF(10,0,10,0); FPreco.StyleLookup:='transparentedit'; FPreco.StyledSettings:=[]; FPreco.TextSettings.FontColor:=$FFF4F7FB;
  R:=Fundo(Form,200,294,150,38); FLimite:=TEdit.Create(Self); FLimite.Parent:=R; FLimite.Align:=TAlignLayout.Client;
  FLimite.Margins.Rect:=RectF(10,0,10,0); FLimite.StyleLookup:='transparentedit'; FLimite.StyledSettings:=[]; FLimite.TextSettings.FontColor:=$FFF4F7FB;
  Rotulo(Form,'Ordem',20,344,150,20,10,$FF9CAABC); R:=Fundo(Form,20,366,150,38);
  FOrdem:=TEdit.Create(Self); FOrdem.Parent:=R; FOrdem.Align:=TAlignLayout.Client; FOrdem.Margins.Rect:=RectF(10,0,10,0);
  FOrdem.StyleLookup:='transparentedit'; FOrdem.StyledSettings:=[]; FOrdem.TextSettings.FontColor:=$FFF4F7FB;
  FBtnObrigatorio:=Botao(Form,'Opcional',150,ObrigatorioClick); FBtnObrigatorio.Position.Point:=PointF(200,366); FBtnObrigatorio.Icone:=sbiCancelar;
  B:=Botao(Form,'Cancelar',128,CancelarClick); B.Position.Point:=PointF(20,440); B.Icone:=sbiCancelar;
  B:=Botao(Form,'Salvar',112,SalvarClick); B.Position.Point:=PointF(238,440); B.Icone:=sbiSalvar;
  TNavegacaoCampos.Aplicar(Self,[FNome,FPreco,FLimite,FOrdem]);
  ListaFundo:=TLayout.Create(Self); ListaFundo.Parent:=Conteudo; ListaFundo.Align:=TAlignLayout.Client;
  R:=TRectangle.Create(Self); R.Parent:=ListaFundo; R.Align:=TAlignLayout.Client; R.Fill.Color:=$FF111E2E; R.Stroke.Color:=$FF23364D; R.XRadius:=10; R.YRadius:=10;
  FEstado:=Rotulo(R,'Carregando adicionais...',20,14,600,26,11,$FF8795A8);
  FLista:=TVertScrollBox.Create(Self); FLista.Parent:=R; FLista.Align:=TAlignLayout.Client; FLista.Margins.Rect:=RectF(8,48,8,8);
  FListaConteudo:=TLayout.Create(Self); FListaConteudo.Parent:=FLista; FListaConteudo.Align:=TAlignLayout.Top; FListaConteudo.Height:=1;
end;

destructor TfraAdicionais.Destroy;
begin FProdutosFiltrados.Free; FCategorias.Free; FAdicionais.Free; FProdutos.Free; inherited; end;

procedure TfraAdicionais.PrepararTela;
begin if not FCarregado then begin CarregarCategorias; CarregarProdutos; CarregarAdicionais; end; end;

procedure TfraAdicionais.PrepararComboEscuro(const Combo: TComboBox;
  const AFundo: TRectangle);
var
  Mascara: TRectangle;
  Texto, Seta: TLabel;
begin
  Mascara := TRectangle.Create(Self);
  Mascara.Parent := AFundo;
  Mascara.Align := TAlignLayout.Client;
  Mascara.Fill.Color := $FF152439;
  Mascara.Stroke.Kind := TBrushKind.None;
  Mascara.HitTest := False;
  Texto := Rotulo(Mascara, 'Selecione...', 12, 0,
    AFundo.Width - 48, AFundo.Height, 11, $FFF4F7FB);
  Texto.TextSettings.VertAlign := TTextAlign.Center;
  Texto.HitTest := False;
  Seta := Rotulo(Mascara, Char($2304), AFundo.Width - 34, 0,
    24, AFundo.Height, 16, $FF9CAABC);
  Seta.TextSettings.HorzAlign := TTextAlign.Center;
  Seta.TextSettings.VertAlign := TTextAlign.Center;
  Seta.Anchors := [TAnchorKind.akTop, TAnchorKind.akRight];
  Seta.HitTest := False;
  Combo.TagObject := Texto;
  Combo.OnChange := ComboVisualChange;
  Mascara.BringToFront;
end;

procedure TfraAdicionais.AtualizarComboVisual(const Combo: TComboBox);
begin
  if not Assigned(Combo) or not (Combo.TagObject is TLabel) then Exit;
  if (Combo.ItemIndex >= 0) and (Combo.ItemIndex < Combo.Count) then
    TLabel(Combo.TagObject).Text := Combo.Items[Combo.ItemIndex]
  else
    TLabel(Combo.TagObject).Text := 'Selecione...';
end;

procedure TfraAdicionais.ComboVisualChange(Sender: TObject);
begin
  if Sender is TComboBox then
    AtualizarComboVisual(TComboBox(Sender));
end;

procedure TfraAdicionais.CategoriaChange(Sender: TObject);
begin
  AtualizarComboVisual(FCategoria);
  PreencherProdutosDaCategoria;
end;

procedure TfraAdicionais.CarregarCategorias;
var H:TNetHTTPClient; Resp:IHTTPResponse; V,Item:TJSONValue; A:TJSONArray; C:TCategoriaAdicional;
begin
  H:=TNetHTTPClient.Create(nil); V:=nil; TSessaoAdmin.ConfigurarCliente(H);
  try
    Resp:=H.Get(TApiConfig.Url('/api/adicionais/categorias'));
    if Resp.StatusCode<>200 then begin ExibirErro('Erro ao carregar categorias',Resp); Exit; end;
    V:=TJSONObject.ParseJSONValue(Resp.ContentAsString(TEncoding.UTF8));
    A:=TJSONObject(V).GetValue<TJSONArray>('categorias'); FCategorias.Clear; FCategoria.Items.Clear;
    for Item in A do begin C:=TCategoriaAdicional.Create; C.Id:=Item.GetValue<string>('id','');
      C.Nome:=Item.GetValue<string>('nome',''); FCategorias.Add(C); FCategoria.Items.Add(C.Nome); end;
    if FCategorias.Count>0 then FCategoria.ItemIndex:=0;
    AtualizarComboVisual(FCategoria);
  finally V.Free; H.Free; end;
end;

procedure TfraAdicionais.PreencherProdutosDaCategoria;
var P:TProdutoAdicional; CategoriaId:string;
begin
  FProdutosFiltrados.Clear; FProduto.Items.Clear; CategoriaId:='';
  if (FCategoria.ItemIndex>=0) and (FCategoria.ItemIndex<FCategorias.Count) then
    CategoriaId:=FCategorias[FCategoria.ItemIndex].Id;
  for P in FProdutos do if SameText(P.CategoriaId,CategoriaId) then begin
    FProdutosFiltrados.Add(P); FProduto.Items.Add(P.Nome); end;
  if FProdutosFiltrados.Count>0 then FProduto.ItemIndex:=0 else FProduto.ItemIndex:=-1;
  AtualizarComboVisual(FProduto);
end;

procedure TfraAdicionais.CarregarProdutos;
var H:TNetHTTPClient; Resp:IHTTPResponse; V,Item:TJSONValue; A:TJSONArray; P:TProdutoAdicional;
begin
  H:=TNetHTTPClient.Create(nil); V:=nil; TSessaoAdmin.ConfigurarCliente(H);
  try
    Resp:=H.Get(TApiConfig.Url('/api/adicionais/produtos'));
    if Resp.StatusCode<>200 then begin ExibirErro('Erro ao carregar produtos',Resp); Exit; end;
    V:=TJSONObject.ParseJSONValue(Resp.ContentAsString(TEncoding.UTF8)); A:=TJSONObject(V).GetValue<TJSONArray>('produtos');
    FProdutos.Clear;
    for Item in A do begin P:=TProdutoAdicional.Create; P.Id:=Item.GetValue<string>('id',''); P.Nome:=Item.GetValue<string>('nome','');
      P.Categoria:=Item.GetValue<string>('categoria_nome',''); P.CategoriaId:=Item.GetValue<string>('categoria_id',''); FProdutos.Add(P); end;
    PreencherProdutosDaCategoria;
  finally V.Free; H.Free; end;
end;

procedure TfraAdicionais.CarregarAdicionais;
var H:TNetHTTPClient; Resp:IHTTPResponse; V,Item:TJSONValue; A:TJSONArray; D:TAdicionalAdmin; U:string;
begin
  FEstado.Text:='Carregando adicionais...'; H:=TNetHTTPClient.Create(nil); V:=nil; TSessaoAdmin.ConfigurarCliente(H);
  try
    U:=TApiConfig.Url('/api/adicionais'); if not FBusca.Text.Trim.IsEmpty then U:=U+'?busca='+TNetEncoding.URL.Encode(FBusca.Text.Trim);
    Resp:=H.Get(U); if Resp.StatusCode<>200 then begin ExibirErro('Erro ao carregar adicionais',Resp); Exit; end;
    V:=TJSONObject.ParseJSONValue(Resp.ContentAsString(TEncoding.UTF8)); A:=TJSONObject(V).GetValue<TJSONArray>('adicionais'); FAdicionais.Clear;
    for Item in A do begin D:=TAdicionalAdmin.Create; D.Id:=Item.GetValue<string>('id',''); D.ProdutoId:=Item.GetValue<string>('produto_id','');
      D.CategoriaId:=Item.GetValue<string>('categoria_id','');
      D.ProdutoNome:=Item.GetValue<string>('produto_nome',''); D.Nome:=Item.GetValue<string>('nome','');
      D.Preco:=StrToCurrDef(Item.GetValue<string>('preco','0'),0,TFormatSettings.Invariant); D.Limite:=Item.GetValue<Integer>('limite',1);
      D.Ordem:=Item.GetValue<Integer>('ordem',0); D.Obrigatorio:=Item.GetValue<Boolean>('obrigatorio',False); D.Ativo:=Item.GetValue<Boolean>('ativo',True); FAdicionais.Add(D); end;
    FCarregado:=True; PreencherLista;
  finally V.Free; H.Free; end;
end;

procedure TfraAdicionais.PreencherLista;
var I:Integer; D:TAdicionalAdmin; C:TRectangle; L:TLabel; B:TfraSensorButton;
  LStatus: string; LCorStatus: TAlphaColor;
begin
  while FListaConteudo.ChildrenCount>0 do FListaConteudo.Children[0].Free;
  FListaConteudo.Height:=FAdicionais.Count*68;
  for I:=0 to FAdicionais.Count-1 do begin D:=FAdicionais[I]; C:=TRectangle.Create(Self); C.Parent:=FListaConteudo;
    C.Position.Point:=PointF(4,I*68+2); C.Width:=FListaConteudo.Width-8; C.Height:=62; C.Anchors:=[TAnchorKind.akLeft,TAnchorKind.akTop,TAnchorKind.akRight];
    C.Fill.Color:=$FF152439; C.Stroke.Color:=$FF23364D; C.XRadius:=7; C.YRadius:=7;
    L:=Rotulo(C,D.Nome,14,5,500,24,11,$FFF4F7FB); L.TextSettings.Font.Style:=[TFontStyle.fsBold];
    Rotulo(C,D.ProdutoNome+'  •  '+FormatCurr('R$ #,##0.00',D.Preco)+'  •  Limite '+D.Limite.ToString,14,32,650,20,9,$FF8795A8);
    B:=Botao(C,'',38,EditarClick); B.Position.Point:=PointF(C.Width-142,13); B.Anchors:=[TAnchorKind.akTop,TAnchorKind.akRight]; B.Tag:=I; B.Icone:=sbiEditar;
    B:=Botao(C,'',38,SituacaoClick); B.Position.Point:=PointF(C.Width-96,13); B.Anchors:=[TAnchorKind.akTop,TAnchorKind.akRight]; B.Tag:=I;
    if D.Ativo then B.Icone:=sbiCancelar else B.Icone:=sbiAtivar;
    if D.Ativo then begin LStatus:='ATIVO'; LCorStatus:=$FF45D483; end
    else begin LStatus:='INATIVO'; LCorStatus:=$FFFFB454; end;
    Rotulo(C,LStatus,C.Width-52,0,44,62,8,LCorStatus).Anchors:=[TAnchorKind.akTop,TAnchorKind.akRight];
  end;
  FEstado.Text:=Format('%d adicional(is) encontrado(s)',[FAdicionais.Count]);
end;

procedure TfraAdicionais.AbrirEditor(AAdicional:TAdicionalAdmin);
var I:Integer;
begin
  if Assigned(AAdicional) then begin FEditandoId:=AAdicional.Id; FTituloEdicao.Text:='Editar adicional'; FNome.Text:=AAdicional.Nome;
    FPreco.Text:=FormatCurr('0.00',AAdicional.Preco); FLimite.Text:=AAdicional.Limite.ToString; FOrdem.Text:=AAdicional.Ordem.ToString; FObrigatorio:=not AAdicional.Obrigatorio;
    for I:=0 to FCategorias.Count-1 do if SameText(FCategorias[I].Id,AAdicional.CategoriaId) then begin FCategoria.ItemIndex:=I; Break; end;
    AtualizarComboVisual(FCategoria); PreencherProdutosDaCategoria;
    for I:=0 to FProdutosFiltrados.Count-1 do if SameText(FProdutosFiltrados[I].Id,AAdicional.ProdutoId) then begin FProduto.ItemIndex:=I; Break; end;
  end else begin FEditandoId:=''; FTituloEdicao.Text:='Novo adicional'; FNome.Text:=''; FPreco.Text:='0,00'; FLimite.Text:='1'; FOrdem.Text:=(FAdicionais.Count+1).ToString; FObrigatorio:=True; if FProdutos.Count>0 then FProduto.ItemIndex:=0; end;
  AtualizarComboVisual(FProduto);
  ObrigatorioClick(nil); FPainel.Visible:=True; FNome.SetFocus;
end;

procedure TfraAdicionais.NovoClick(Sender:TObject); begin AbrirEditor(nil); end;
procedure TfraAdicionais.EditarClick(Sender:TObject); begin if Sender is TfraSensorButton then AbrirEditor(FAdicionais[TfraSensorButton(Sender).Tag]); end;
procedure TfraAdicionais.CancelarClick(Sender:TObject); begin FPainel.Visible:=False; end;
procedure TfraAdicionais.ObrigatorioClick(Sender:TObject);
begin FObrigatorio:=not FObrigatorio; if FObrigatorio then begin FBtnObrigatorio.Texto:='Obrigat'+Char($00F3)+'rio'; FBtnObrigatorio.Icone:=sbiAtivar; FBtnObrigatorio.Estilo:=sbsPrimary; end else begin FBtnObrigatorio.Texto:='Opcional'; FBtnObrigatorio.Icone:=sbiCancelar; FBtnObrigatorio.Estilo:=sbsSecondary; end; end;

procedure TfraAdicionais.SalvarClick(Sender:TObject);
var Preco:Currency; Limite,Ordem:Integer; J:TJSONObject; H:TNetHTTPClient; S:TStringStream; Resp:IHTTPResponse;
begin
  if (FCategoria.ItemIndex<0) or (FProduto.ItemIndex<0) or FNome.Text.Trim.IsEmpty then begin TfrmMensagem.Exibir('Campos obrigatórios','Informe a categoria, o produto e o nome.',tmAtencao); Exit; end;
  if not TryStrToCurr(FPreco.Text,Preco) then Preco:=StrToCurrDef(FPreco.Text, -1,TFormatSettings.Invariant);
  if (Preco<0) or not TryStrToInt(FLimite.Text,Limite) or (Limite<1) or not TryStrToInt(FOrdem.Text,Ordem) then begin TfrmMensagem.Exibir('Valores inválidos','Confira preço, limite e ordem.',tmAtencao); Exit; end;
  J:=TJSONObject.Create; J.AddPair('produtoId',FProdutosFiltrados[FProduto.ItemIndex].Id); J.AddPair('categoriaId',FCategorias[FCategoria.ItemIndex].Id); J.AddPair('nome',FNome.Text.Trim); J.AddPair('preco',TJSONNumber.Create(Double(Preco)));
  J.AddPair('limite',TJSONNumber.Create(Limite)); J.AddPair('obrigatorio',TJSONBool.Create(FObrigatorio)); J.AddPair('ordem',TJSONNumber.Create(Ordem));
  H:=TNetHTTPClient.Create(nil); TSessaoAdmin.ConfigurarCliente(H); S:=TStringStream.Create(J.ToJSON,TEncoding.UTF8);
  try H.ContentType:='application/json'; if FEditandoId.IsEmpty then Resp:=H.Post(TApiConfig.Url('/api/adicionais'),S) else Resp:=H.Put(TApiConfig.Url('/api/adicionais/')+FEditandoId,S);
    if not (Resp.StatusCode in [200,201]) then begin ExibirErro('Erro ao salvar adicional',Resp); Exit; end; FPainel.Visible:=False; CarregarAdicionais;
  finally S.Free; H.Free; J.Free; end;
end;

procedure TfraAdicionais.SituacaoClick(Sender:TObject);
var D:TAdicionalAdmin; J:TJSONObject; H:TNetHTTPClient; S:TStringStream; Resp:IHTTPResponse;
begin
  if not (Sender is TfraSensorButton) then Exit; D:=FAdicionais[TfraSensorButton(Sender).Tag]; J:=TJSONObject.Create; J.AddPair('ativo',TJSONBool.Create(not D.Ativo));
  H:=TNetHTTPClient.Create(nil); TSessaoAdmin.ConfigurarCliente(H); S:=TStringStream.Create(J.ToJSON,TEncoding.UTF8);
  try H.ContentType:='application/json'; Resp:=H.Patch(TApiConfig.Url('/api/adicionais/')+D.Id+'/situacao',S); if Resp.StatusCode<>200 then ExibirErro('Erro ao alterar adicional',Resp) else CarregarAdicionais;
  finally S.Free; H.Free; J.Free; end;
end;

procedure TfraAdicionais.BuscaChange(Sender:TObject); begin FTimer.Enabled:=False; FTimer.Enabled:=True; end;
procedure TfraAdicionais.TimerTimer(Sender:TObject); begin FTimer.Enabled:=False; CarregarAdicionais; end;
procedure TfraAdicionais.ExibirErro(const Titulo:string; Resposta:IHTTPResponse);
var V:TJSONValue; M:string;
begin M:='A API retornou '+Resposta.StatusCode.ToString+'.'; V:=TJSONObject.ParseJSONValue(Resposta.ContentAsString(TEncoding.UTF8)); try if V is TJSONObject then M:=TJSONObject(V).GetValue<string>('erro',M); finally V.Free; end; TfrmMensagem.Exibir(Titulo,M,tmErro); end;

end.
