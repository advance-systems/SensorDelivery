unit uFrameConfiguracoes;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.JSON,
  System.Net.HttpClient, System.Net.HttpClientComponent,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Objects,
  FMX.Layouts, FMX.Controls.Presentation, FMX.Edit, FMX.Memo, FMX.ListBox,
  FMX.Pickers,
  uFrameSensorButton;

type
  TLojaHorario = class
  public
    Dia: Integer; Abertura, Fechamento: string; Fechado: Boolean;
  end;

  TfraConfiguracoes = class(TFrame)
    rctFundo: TRectangle;
    lytPrincipal, lytCabecalho, lytConteudo: TLayout;
    lblTitulo, lblSubtitulo: TLabel;
  private
    FCarregado: Boolean; FModo: string;
    FHorarios: array[0..6] of TLojaHorario;
    FScroll: TVertScrollBox; FConteudo: TLayout;
    FTaxa, FMinimo, FTempo, FPixChave, FPixNome, FPixCidade: TEdit;
    FMensagem: TMemo;
    FSomAlerta: TComboBox;
    FSomCampo, FSomMascara: TRectangle;
    FSomPopup: TPopup;
    FHoraAbre, FHoraFecha: array[0..6] of TEdit;
    FBtnDia: array[0..6] of TfraSensorButton;
    FBtnAutomatico, FBtnAberto, FBtnFechado, FBtnAceitar,
      FBtnImprimir, FBtnTestarSom, FBtnSalvar: TfraSensorButton;
    FAceitar, FImprimir: Boolean;
    function Rotulo(const P: TFmxObject; const T: string; X,Y,W,H:Single;
      Cor:TAlphaColor; Tam:Single):TLabel;
    function Botao(const P:TFmxObject;const T:string;W:Single;
      Click:TNotifyEvent):TfraSensorButton;
    function Campo(const P:TFmxObject;const Titulo,Prompt:string;
      X,Y,W:Single):TEdit;
    procedure MontarTela; procedure AtualizarOpcoes;
    procedure ModoClick(Sender:TObject); procedure DiaClick(Sender:TObject);
    procedure AceitarClick(Sender:TObject); procedure ImprimirClick(Sender:TObject);
    procedure SomAlertaChange(Sender:TObject); procedure TestarSomClick(Sender:TObject);
    procedure AbrirSomPopup(Sender:TObject); procedure SomPopupItemClick(Sender:TObject);
    procedure AtualizarSomVisual; procedure SelecionarSom(const ASom:string);
    function CodigoSomSelecionado:string;
    function TryLerMoeda(const ATexto:string;out AValor:Currency):Boolean;
    procedure SalvarClick(Sender:TObject); procedure MemoEstilo(Sender:TObject);
    procedure ExibirErro(const Titulo:string;const R:IHTTPResponse);
  public
    constructor Create(AOwner:TComponent); override;
    destructor Destroy; override;
    procedure PrepararTela; procedure CarregarConfiguracoes;
  end;

implementation

{$R *.fmx}
uses uMensagem, uSessaoAdmin, uNavegacaoCampos, uApiConfig, uAlertaNovoPedido;

function URL_CONFIG: string;
begin
  Result := TApiConfig.Url('/api/configuracoes');
end;

const
  DIAS:array[0..6] of string=('Domingo','Segunda-feira','Terça-feira',
    'Quarta-feira','Quinta-feira','Sexta-feira','Sábado');

constructor TfraConfiguracoes.Create(AOwner:TComponent);
var I:Integer;
begin inherited; for I:=0 to 6 do begin FHorarios[I]:=TLojaHorario.Create;
  FHorarios[I].Dia:=I; FHorarios[I].Abertura:='18:00';
  FHorarios[I].Fechamento:='23:00'; end; FModo:='AUTOMATICO'; MontarTela; end;
destructor TfraConfiguracoes.Destroy;
var I:Integer;
begin for I:=0 to 6 do FHorarios[I].Free; inherited; end;

function TfraConfiguracoes.Rotulo(const P:TFmxObject;const T:string;
  X,Y,W,H:Single;Cor:TAlphaColor;Tam:Single):TLabel;
begin Result:=TLabel.Create(Self); Result.Parent:=P; Result.Position.Point:=PointF(X,Y);
  Result.Width:=W; Result.Height:=H; Result.Text:=T; Result.StyledSettings:=[];
  Result.TextSettings.Font.Family:='Manrope'; Result.TextSettings.Font.Size:=Tam;
  Result.TextSettings.FontColor:=Cor; end;
function TfraConfiguracoes.Botao(const P:TFmxObject;const T:string;W:Single;
  Click:TNotifyEvent):TfraSensorButton;
begin Result:=TfraSensorButton.Create(Self); Result.Name:=''; Result.Parent:=P;
  Result.Align:=TAlignLayout.None; Result.Width:=W; Result.Height:=38;
  Result.Texto:=T; Result.Estilo:=sbsSecondary; Result.OnButtonClick:=Click;
  Result.pthIcone.Margins.Left:=10; Result.pthIcone.Margins.Right:=6; end;
function TfraConfiguracoes.Campo(const P:TFmxObject;const Titulo,Prompt:string;
  X,Y,W:Single):TEdit;
var R:TRectangle;
begin Rotulo(P,Titulo,X,Y,W,20,$FF9CAABC,10); R:=TRectangle.Create(Self);
  R.Parent:=P; R.Position.Point:=PointF(X,Y+22); R.Width:=W; R.Height:=38;
  R.Fill.Color:=$FF152439; R.Stroke.Color:=$FF2A405B; R.XRadius:=6; R.YRadius:=6;
  Result:=TEdit.Create(Self); Result.Parent:=R; Result.Align:=TAlignLayout.Client;
  Result.Margins.Left:=10; Result.Margins.Right:=10; Result.StyleLookup:='transparentedit';
  Result.StyledSettings:=[]; Result.TextSettings.FontColor:=$FFF4F7FB;
  Result.TextPrompt:=Prompt; end;

procedure TfraConfiguracoes.MontarTela;
var CardOperacao,CardHorario,CardPix,R,ItemSom:TRectangle; Texto,Seta:TLabel; I:Integer; Y:Single;
begin
  FScroll:=TVertScrollBox.Create(Self); FScroll.Parent:=lytConteudo;
  FScroll.Align:=TAlignLayout.Client; FConteudo:=TLayout.Create(Self);
  FConteudo.Parent:=FScroll; FConteudo.Align:=TAlignLayout.Top; FConteudo.Height:=824;
  CardOperacao:=TRectangle.Create(Self); CardOperacao.Parent:=FConteudo;
  CardOperacao.Position.Point:=PointF(0,0); CardOperacao.Width:=500; CardOperacao.Height:=620;
  CardOperacao.Fill.Color:=$FF111E2E; CardOperacao.Stroke.Color:=$FF23364D;
  CardOperacao.XRadius:=10; CardOperacao.YRadius:=10;
  Rotulo(CardOperacao,'Operação da loja',20,16,460,30,$FFF4F7FB,16).TextSettings.Font.Style:=[TFontStyle.fsBold];
  Rotulo(CardOperacao,'Modo de funcionamento',20,58,460,20,$FF9CAABC,10);
  FBtnAutomatico:=Botao(CardOperacao,'Automático',130,ModoClick); FBtnAutomatico.Tag:=0;
  FBtnAutomatico.Position.Point:=PointF(20,82); FBtnAutomatico.Icone:=sbiConfiguracao;
  FBtnAberto:=Botao(CardOperacao,'Aberto',110,ModoClick); FBtnAberto.Tag:=1;
  FBtnAberto.Position.Point:=PointF(158,82); FBtnAberto.Icone:=sbiAtivar;
  FBtnFechado:=Botao(CardOperacao,'Fechado',118,ModoClick); FBtnFechado.Tag:=2;
  FBtnFechado.Position.Point:=PointF(276,82); FBtnFechado.Icone:=sbiCancelar;
  FTaxa:=Campo(CardOperacao,'Taxa de entrega','0,00',20,140,140);
  FTaxa.KeyboardType:=TVirtualKeyboardType.DecimalNumberPad;
  FMinimo:=Campo(CardOperacao,'Pedido mínimo','0,00',178,140,140);
  FMinimo.KeyboardType:=TVirtualKeyboardType.DecimalNumberPad;
  FTempo:=Campo(CardOperacao,'Tempo estimado (min)','45',336,140,144);
  FTempo.KeyboardType:=TVirtualKeyboardType.NumberPad;
  Rotulo(CardOperacao,'Mensagem de loja fechada',20,214,460,20,$FF9CAABC,10);
  R:=TRectangle.Create(Self); R.Parent:=CardOperacao; R.Position.Point:=PointF(20,238);
  R.Width:=460; R.Height:=100; R.Fill.Color:=$FF152439; R.Stroke.Color:=$FF2A405B;
  R.XRadius:=6; R.YRadius:=6; FMensagem:=TMemo.Create(Self); FMensagem.Parent:=R;
  FMensagem.Align:=TAlignLayout.Client; FMensagem.Margins.Rect:=RectF(8,4,8,4);
  FMensagem.StyledSettings:=[]; FMensagem.TextSettings.FontColor:=$FFF4F7FB;
  FMensagem.OnApplyStyleLookup:=MemoEstilo;
  FBtnAceitar:=Botao(CardOperacao,'Aceitar pedidos automaticamente',250,AceitarClick);
  FBtnAceitar.Position.Point:=PointF(20,360); FBtnAceitar.Icone:=sbiAtivar;
  FBtnImprimir:=Botao(CardOperacao,'Imprimir automaticamente',220,ImprimirClick);
  FBtnImprimir.Position.Point:=PointF(20,410); FBtnImprimir.Icone:=sbiRelatorio;
  Rotulo(CardOperacao,'Som do alerta de novo pedido',20,460,460,20,$FF9CAABC,10);
  FSomCampo:=TRectangle.Create(Self); FSomCampo.Parent:=CardOperacao;
  FSomCampo.Position.Point:=PointF(20,482);
  FSomCampo.Width:=290; FSomCampo.Height:=38; FSomCampo.Fill.Color:=$FF152439;
  FSomCampo.Stroke.Color:=$FF2A405B; FSomCampo.XRadius:=6; FSomCampo.YRadius:=6;
  FSomAlerta:=TComboBox.Create(Self); FSomAlerta.Parent:=FSomCampo;
  FSomAlerta.Align:=TAlignLayout.Client;
  FSomAlerta.Items.Add('Notificação do Windows'); FSomAlerta.Items.Add('Atenção');
  FSomAlerta.Items.Add('Aviso'); FSomAlerta.Items.Add('Alerta forte');
  FSomAlerta.Items.Add('Sem som'); FSomAlerta.ItemIndex:=0;
  FSomMascara:=TRectangle.Create(Self); FSomMascara.Parent:=FSomCampo;
  FSomMascara.Align:=TAlignLayout.Client;
  FSomMascara.Fill.Color:=$FF152439; FSomMascara.Stroke.Kind:=TBrushKind.None;
  FSomMascara.HitTest:=True; FSomMascara.Cursor:=crHandPoint;
  FSomMascara.OnClick:=AbrirSomPopup;
  Texto:=Rotulo(FSomMascara,'',12,0,240,38,$FFF4F7FB,11);
  Texto.TextSettings.VertAlign:=TTextAlign.Center; Texto.HitTest:=False;
  Seta:=Rotulo(FSomMascara,'⌄',256,0,24,38,$FF9CAABC,16);
  Seta.TextSettings.HorzAlign:=TTextAlign.Center; Seta.TextSettings.VertAlign:=TTextAlign.Center;
  Seta.HitTest:=False; FSomAlerta.TagObject:=Texto; FSomAlerta.OnChange:=SomAlertaChange;
  FSomMascara.BringToFront;
  FSomPopup:=TPopup.Create(Self); FSomPopup.Parent:=CardOperacao;
  FSomPopup.PlacementTarget:=FSomCampo; FSomPopup.Placement:=TPlacement.Bottom;
  FSomPopup.Width:=290; FSomPopup.Height:=190;
  R:=TRectangle.Create(Self); R.Parent:=FSomPopup; R.Align:=TAlignLayout.Client;
  R.Fill.Color:=$FF152439; R.Stroke.Color:=$FF2A405B;
  for I:=0 to FSomAlerta.Count-1 do begin
    ItemSom:=TRectangle.Create(Self); ItemSom.Parent:=R;
    ItemSom.Position.Point:=PointF(1,1+(I*37)); ItemSom.Width:=288; ItemSom.Height:=36;
    ItemSom.Fill.Color:=$FF152439; ItemSom.Stroke.Kind:=TBrushKind.None;
    ItemSom.Tag:=I; ItemSom.Cursor:=crHandPoint; ItemSom.OnClick:=SomPopupItemClick;
    Texto:=Rotulo(ItemSom,FSomAlerta.Items[I],10,0,268,36,$FFF4F7FB,11);
    Texto.TextSettings.VertAlign:=TTextAlign.Center; Texto.HitTest:=False;
  end;
  AtualizarSomVisual;
  FBtnTestarSom:=Botao(CardOperacao,'Testar som',154,TestarSomClick);
  FBtnTestarSom.Position.Point:=PointF(326,482); FBtnTestarSom.Icone:=sbiAtivar;
  FBtnSalvar:=Botao(CardOperacao,'Salvar configurações',190,SalvarClick);
  FBtnSalvar.Position.Point:=PointF(290,548); FBtnSalvar.Estilo:=sbsPrimary;
  FBtnSalvar.Icone:=sbiSalvar;

  CardHorario:=TRectangle.Create(Self); CardHorario.Parent:=FConteudo;
  CardHorario.Position.Point:=PointF(516,0); CardHorario.Width:=636; CardHorario.Height:=620;
  CardHorario.Anchors:=[TAnchorKind.akLeft,TAnchorKind.akTop,TAnchorKind.akRight];
  CardHorario.Fill.Color:=$FF111E2E; CardHorario.Stroke.Color:=$FF23364D;
  CardHorario.XRadius:=10; CardHorario.YRadius:=10;
  Rotulo(CardHorario,'Horários de funcionamento',20,16,596,30,$FFF4F7FB,16).TextSettings.Font.Style:=[TFontStyle.fsBold];
  Rotulo(CardHorario,'Dia',20,56,180,20,$FF8795A8,9);
  Rotulo(CardHorario,'Abertura',220,56,100,20,$FF8795A8,9);
  Rotulo(CardHorario,'Fechamento',340,56,100,20,$FF8795A8,9);
  Y:=80;
  for I:=0 to 6 do begin
    Rotulo(CardHorario,DIAS[I],20,Y,180,38,$FFF4F7FB,10);
    FHoraAbre[I]:=Campo(CardHorario,'','18:00',210,Y-22,110);
    FHoraFecha[I]:=Campo(CardHorario,'','23:00',330,Y-22,110);
    FBtnDia[I]:=Botao(CardHorario,'Aberto',120,DiaClick); FBtnDia[I].Tag:=I;
    FBtnDia[I].Position.Point:=PointF(464,Y); FBtnDia[I].Icone:=sbiAtivar; Y:=Y+68;
  end;

  CardPix:=TRectangle.Create(Self); CardPix.Parent:=FConteudo;
  CardPix.Position.Point:=PointF(0,636); CardPix.Width:=1152; CardPix.Height:=168;
  CardPix.Anchors:=[TAnchorKind.akLeft,TAnchorKind.akTop,TAnchorKind.akRight];
  CardPix.Fill.Color:=$FF111E2E; CardPix.Stroke.Color:=$FF23364D;
  CardPix.XRadius:=10; CardPix.YRadius:=10;
  Rotulo(CardPix,'Configuração PIX',20,16,1112,28,$FFF4F7FB,16).TextSettings.Font.Style:=[TFontStyle.fsBold];
  Rotulo(CardPix,'Dados usados para gerar o QR Code e o código PIX copia e cola no aplicativo.',20,43,1112,18,$FF8795A8,10);
  FPixChave:=Campo(CardPix,'Chave PIX','CPF, CNPJ, e-mail, telefone ou chave aleatória',20,72,430);
  FPixNome:=Campo(CardPix,'Nome do recebedor (máx. 25)','Nome que aparecerá no PIX',468,72,330);
  FPixCidade:=Campo(CardPix,'Cidade (máx. 15)','Cidade do recebedor',816,72,316);
  TNavegacaoCampos.Aplicar(Self, [FTaxa, FMinimo, FTempo, FMensagem, FSomAlerta,
    FPixChave, FPixNome, FPixCidade,
    FHoraAbre[0], FHoraFecha[0], FHoraAbre[1], FHoraFecha[1],
    FHoraAbre[2], FHoraFecha[2], FHoraAbre[3], FHoraFecha[3],
    FHoraAbre[4], FHoraFecha[4], FHoraAbre[5], FHoraFecha[5],
    FHoraAbre[6], FHoraFecha[6]]);
  AtualizarOpcoes;
end;

procedure TfraConfiguracoes.AtualizarOpcoes;
var I:Integer;
begin
  FBtnAutomatico.Estilo:=sbsSecondary; FBtnAberto.Estilo:=sbsSecondary;
  FBtnFechado.Estilo:=sbsSecondary;
  if FModo='ABERTO' then FBtnAberto.Estilo:=sbsPrimary
  else if FModo='FECHADO' then FBtnFechado.Estilo:=sbsPrimary
  else FBtnAutomatico.Estilo:=sbsPrimary;
  if FAceitar then FBtnAceitar.Estilo:=sbsPrimary else FBtnAceitar.Estilo:=sbsSecondary;
  if FImprimir then FBtnImprimir.Estilo:=sbsPrimary else FBtnImprimir.Estilo:=sbsSecondary;
  for I:=0 to 6 do begin
    if FHorarios[I].Fechado then begin FBtnDia[I].Texto:='Fechado';
      FBtnDia[I].Icone:=sbiCancelar; FBtnDia[I].Estilo:=sbsSecondary; end
    else begin FBtnDia[I].Texto:='Aberto'; FBtnDia[I].Icone:=sbiAtivar;
      FBtnDia[I].Estilo:=sbsPrimary; end;
    FHoraAbre[I].Enabled:=not FHorarios[I].Fechado;
    FHoraFecha[I].Enabled:=not FHorarios[I].Fechado;
  end;
end;

procedure TfraConfiguracoes.PrepararTela; begin if not FCarregado then CarregarConfiguracoes; end;
procedure TfraConfiguracoes.CarregarConfiguracoes;
var H:TNetHTTPClient;R:IHTTPResponse;V,Item:TJSONValue;J,C:TJSONObject;A:TJSONArray;I:Integer;
begin H:=TNetHTTPClient.Create(nil); TSessaoAdmin.ConfigurarCliente(H); V:=nil; try try R:=H.Get(URL_CONFIG+'?empresaId='+TSessaoAdmin.EmpresaId);
  if R.StatusCode<>200 then begin ExibirErro('Erro ao carregar configurações',R);Exit;end;
  V:=TJSONObject.ParseJSONValue(R.ContentAsString(TEncoding.UTF8)); J:=V as TJSONObject;
  C:=J.GetValue<TJSONObject>('configuracao'); FModo:=C.GetValue<string>('modo_funcionamento','AUTOMATICO');
  FTaxa.Text:=C.GetValue<string>('taxa_entrega','0'); FMinimo.Text:=C.GetValue<string>('pedido_minimo','0');
  FTempo.Text:=IntToStr(C.GetValue<Integer>('tempo_entrega_minutos',45));
  FMensagem.Text:=C.GetValue<string>('mensagem_fechada','');
  FPixChave.Text:=C.GetValue<string>('pix_chave','');
  FPixNome.Text:=C.GetValue<string>('pix_nome_recebedor','');
  FPixCidade.Text:=C.GetValue<string>('pix_cidade_recebedor','');
  SelecionarSom(C.GetValue<string>('som_alerta_pedido','NOTIFICACAO'));
  TAlertaNovoPedido.DefinirSom(CodigoSomSelecionado);
  FAceitar:=C.GetValue<Boolean>('aceitar_pedidos_automaticamente',False);
  FImprimir:=C.GetValue<Boolean>('imprimir_automaticamente',False);
  A:=J.GetValue<TJSONArray>('horarios'); for Item in A do begin C:=Item as TJSONObject;
    I:=C.GetValue<Integer>('dia_semana',0); if (I>=0)and(I<=6) then begin
      FHorarios[I].Abertura:=Copy(C.GetValue<string>('horario_abertura','18:00'),1,5);
      FHorarios[I].Fechamento:=Copy(C.GetValue<string>('horario_fechamento','23:00'),1,5);
      FHorarios[I].Fechado:=C.GetValue<Boolean>('fechado',False);
      FHoraAbre[I].Text:=FHorarios[I].Abertura; FHoraFecha[I].Text:=FHorarios[I].Fechamento; end; end;
  FCarregado:=True; AtualizarOpcoes;
  except on E:Exception do TfrmMensagem.Exibir('Erro de comunicação',E.Message,tmErro);end;
  finally V.Free;H.Free;end;end;

procedure TfraConfiguracoes.ModoClick(Sender:TObject);
begin case TfraSensorButton(Sender).Tag of 1:FModo:='ABERTO';2:FModo:='FECHADO';else FModo:='AUTOMATICO';end;AtualizarOpcoes;end;
procedure TfraConfiguracoes.DiaClick(Sender:TObject);
var I:Integer;begin I:=TfraSensorButton(Sender).Tag;FHorarios[I].Fechado:=not FHorarios[I].Fechado;AtualizarOpcoes;end;
procedure TfraConfiguracoes.AceitarClick(Sender:TObject);begin FAceitar:=not FAceitar;AtualizarOpcoes;end;
procedure TfraConfiguracoes.ImprimirClick(Sender:TObject);begin FImprimir:=not FImprimir;AtualizarOpcoes;end;

function TfraConfiguracoes.CodigoSomSelecionado:string;
begin
  case FSomAlerta.ItemIndex of
    1:Result:='EXCLAMACAO';
    2:Result:='ASTERISCO';
    3:Result:='ERRO';
    4:Result:='SEM_SOM';
  else Result:='NOTIFICACAO'; end;
end;

procedure TfraConfiguracoes.AtualizarSomVisual;
begin
  if Assigned(FSomAlerta) and (FSomAlerta.TagObject is TLabel) then
    if (FSomAlerta.ItemIndex>=0) and (FSomAlerta.ItemIndex<FSomAlerta.Count) then
      TLabel(FSomAlerta.TagObject).Text:=FSomAlerta.Items[FSomAlerta.ItemIndex]
    else TLabel(FSomAlerta.TagObject).Text:='Selecione...';
end;

procedure TfraConfiguracoes.SomAlertaChange(Sender:TObject);
begin AtualizarSomVisual; end;

procedure TfraConfiguracoes.AbrirSomPopup(Sender:TObject);
begin
  if Assigned(FSomPopup) then FSomPopup.IsOpen:=True;
end;

procedure TfraConfiguracoes.SomPopupItemClick(Sender:TObject);
begin
  if not (Sender is TRectangle) then Exit;
  FSomAlerta.ItemIndex:=TRectangle(Sender).Tag;
  AtualizarSomVisual;
  FSomPopup.IsOpen:=False;
end;

procedure TfraConfiguracoes.SelecionarSom(const ASom:string);
begin
  if SameText(ASom,'EXCLAMACAO') then FSomAlerta.ItemIndex:=1
  else if SameText(ASom,'ASTERISCO') then FSomAlerta.ItemIndex:=2
  else if SameText(ASom,'ERRO') then FSomAlerta.ItemIndex:=3
  else if SameText(ASom,'SEM_SOM') then FSomAlerta.ItemIndex:=4
  else FSomAlerta.ItemIndex:=0;
  AtualizarSomVisual;
end;

procedure TfraConfiguracoes.TestarSomClick(Sender:TObject);
begin TAlertaNovoPedido.TestarSom(CodigoSomSelecionado); end;

function TfraConfiguracoes.TryLerMoeda(const ATexto:string;
  out AValor:Currency):Boolean;
var
  LTexto: string;
  LFormato: TFormatSettings;
begin
  LTexto:=ATexto.Trim;
  Result:=TryStrToCurr(LTexto,AValor);
  if Result then Exit;
  Result:=TryStrToCurr(LTexto,AValor,TFormatSettings.Invariant);
  if Result then Exit;
  LFormato:=TFormatSettings.Create;
  LTexto:=LTexto.Replace('.',LFormato.DecimalSeparator)
    .Replace(',',LFormato.DecimalSeparator);
  Result:=TryStrToCurr(LTexto,AValor,LFormato);
end;

procedure TfraConfiguracoes.SalvarClick(Sender:TObject);
var H:TNetHTTPClient;J,HI:TJSONObject;A:TJSONArray;S:TStringStream;R:IHTTPResponse;I,Tempo:Integer;Taxa,Minimo:Currency;
begin if not TryLerMoeda(FTaxa.Text,Taxa) or not TryLerMoeda(FMinimo.Text,Minimo) or
  not TryStrToInt(FTempo.Text,Tempo) or (Taxa<0)or(Minimo<0)or(Tempo<=0) then begin
    TfrmMensagem.Exibir('Valores inválidos','Revise taxa, pedido mínimo e tempo.',tmAtencao);Exit;end;
  J:=TJSONObject.Create;J.AddPair('empresaId',TSessaoAdmin.EmpresaId);J.AddPair('modoFuncionamento',FModo);
  J.AddPair('mensagemFechada',FMensagem.Text.Trim);J.AddPair('taxaEntrega',TJSONNumber.Create(Double(Taxa)));
  J.AddPair('pedidoMinimo',TJSONNumber.Create(Double(Minimo)));J.AddPair('tempoEntregaMinutos',TJSONNumber.Create(Tempo));
  J.AddPair('aceitarPedidosAutomaticamente',TJSONBool.Create(FAceitar));J.AddPair('imprimirAutomaticamente',TJSONBool.Create(FImprimir));
  J.AddPair('somAlertaPedido',CodigoSomSelecionado);
  J.AddPair('pixChave',FPixChave.Text.Trim); J.AddPair('pixNomeRecebedor',FPixNome.Text.Trim);
  J.AddPair('pixCidadeRecebedor',FPixCidade.Text.Trim);
  A:=TJSONArray.Create;for I:=0 to 6 do begin HI:=TJSONObject.Create;HI.AddPair('diaSemana',TJSONNumber.Create(I));
    HI.AddPair('horarioAbertura',FHoraAbre[I].Text.Trim);HI.AddPair('horarioFechamento',FHoraFecha[I].Text.Trim);
    HI.AddPair('fechado',TJSONBool.Create(FHorarios[I].Fechado));A.AddElement(HI);end;J.AddPair('horarios',A);
  H:=TNetHTTPClient.Create(nil); TSessaoAdmin.ConfigurarCliente(H); S:=TStringStream.Create(J.ToJSON,TEncoding.UTF8);try H.ContentType:='application/json';
    R:=H.Put(URL_CONFIG,S);if R.StatusCode<>200 then ExibirErro('Erro ao salvar configurações',R)
    else begin TAlertaNovoPedido.DefinirSom(CodigoSomSelecionado);
      TfrmMensagem.Exibir('Configurações salvas','As preferências foram atualizadas.',tmSucesso); end;
  finally S.Free;H.Free;J.Free;end;end;

procedure TfraConfiguracoes.MemoEstilo(Sender:TObject);var C:TControl;
begin if FMensagem.FindStyleResource<TControl>('background',C)then begin C.Opacity:=0;C.HitTest:=False;end;end;
procedure TfraConfiguracoes.ExibirErro(const Titulo:string;const R:IHTTPResponse);
var V:TJSONValue;M:string;begin M:='A API retornou '+IntToStr(R.StatusCode)+'.';
  V:=TJSONObject.ParseJSONValue(R.ContentAsString(TEncoding.UTF8));try if V is TJSONObject then
    M:=TJSONObject(V).GetValue<string>('erro',M);finally V.Free;end;TfrmMensagem.Exibir(Titulo,M,tmErro);end;
end.
