unit uPrincipalAdmin;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit,
  uFramePedidoKanban, System.Math, uFrameCentralPedidos, uFrameCardapio,
  uFrameClientes, uFrameConfiguracoes, uFrameEntregadores, uFrameFinanceiro,
  uFramePedidos, uFramePromocoes, uFrameRelatorios, uFrameSabores,
  uFrameProdutosAdmin, uFrameCombos, uFrameEmpresas, uFrameUsuarios,
  uFramePermissoes, uFramePopupMenu, uFrameNovidades, uFrameAdicionais;

type
  TMenuAdmin = (
    maCentralPedidos,
    maPedidos,
    maClientes,
    maEmpresas,
    maUsuarios,
    maPermissoes,
    maCardapio,
    maCategorias,
    maSabores,
    maBordas,
    maAdicionais,
    maCombos,
    maPromocoes,
    maEntregadores,
    maFinanceiro,
    maRelatorios,
    maConfiguracoes,
    maNovidades
  );

  TfrmPrincipalAdmin = class(TForm)
    rctFundo: TRectangle;
    lytMenuLateral: TLayout;
    rctMenuLateral: TRectangle;
    lytLogo: TLayout;
    imgLogoIcone: TImage;
    vsbMenu: TVertScrollBox;
    lytItensMenu: TLayout;
    rctSair: TRectangle;
    lytConteudo: TLayout;
    lytTopo: TLayout;
    rctPesquisa: TRectangle;
    edtPesquisa: TEdit;
    lblIconePesquisa: TLabel;
    lytAcoesTopo: TLayout;
    rctNotificacoes: TRectangle;
    lblNotificacoes: TLabel;
    rctConfiguracoes: TRectangle;
    lblConfiguracoes: TLabel;
    rctUsuario: TRectangle;
    lytUsuarioConteudo: TLayout;
    crcUsuario: TCircle;
    lblUsuarioNome: TLabel;
    lblUsuarioPerfil: TLabel;
    lblAvatar: TLabel;
    pthUsuarioSeta: TPath;
    lytContainerPagina: TLayout;
    rctMenuCentralPedidos: TRectangle;
    rctIndicadorCentralPedidos: TRectangle;
    pthMenuCentralPedidos: TPath;
    lblMenuCentralPedidos: TLabel;
    rctMenuPedidos: TRectangle;
    rctIndicadorPedidos: TRectangle;
    pthMenuPedidos: TPath;
    lblMenuPedidos: TLabel;
    rctMenuClientes: TRectangle;
    rctIndicadorClientes: TRectangle;
    pthMenuClientes: TPath;
    lblMenuClientes: TLabel;
    rctMenuEmpresas: TRectangle;
    rctIndicadorEmpresas: TRectangle;
    pthMenuEmpresas: TPath;
    lblMenuEmpresas: TLabel;
    rctMenuProdutos: TRectangle;
    rctIndicadorProdutos: TRectangle;
    pthMenuProdutos: TPath;
    lblMenuProdutos: TLabel;
    rctMenuCardapio: TRectangle;
    rctIndicadorCardapio: TRectangle;
    pthMenuCardapio: TPath;
    lblMenuCardapio: TLabel;
    rctMenuSabores: TRectangle;
    rctIndicadorSabores: TRectangle;
    pthMenuSabores: TPath;
    lblMenuSabores: TLabel;
    rctMenuCombos: TRectangle;
    rctIndicadorCombos: TRectangle;
    pthMenuCombos: TPath;
    lblMenuCombos: TLabel;
    rctMenuPromocoes: TRectangle;
    rctIndicadorPromocoes: TRectangle;
    pthMenuPromocoes: TPath;
    lblMenuPromocoes: TLabel;
    rctMenuConfiguracoes: TRectangle;
    rctIndicadorConfiguracoes: TRectangle;
    pthMenuConfiguracoes: TPath;
    lblMenuConfiguracoes: TLabel;
    rctMenuRelatorios: TRectangle;
    rctIndicadorRelatorios: TRectangle;
    pthMenuRelatorios: TPath;
    lblMenuRelatorios: TLabel;
    rctMenuFinanceiro: TRectangle;
    rctIndicadorFinanceiro: TRectangle;
    pthMenuFinanceiro: TPath;
    lblMenuFinanceiro: TLabel;
    rctMenuEntregadores: TRectangle;
    rctIndicadorEntregadores: TRectangle;
    pthMenuEntregadores: TPath;
    lblMenuEntregadores: TLabel;
    lblSair: TLabel;
    pthSair: TPath;
    lytPaginaCentralPedidos: TLayout;
    lytPaginaPedidos: TLayout;
    lytPaginaClientes: TLayout;
    lytPaginaCardapio: TLayout;
    lytPaginaPromocoes: TLayout;
    lytPaginaEntregadores: TLayout;
    lytPaginaFinanceiro: TLayout;
    lytPaginaRelatorios: TLayout;
    lytPaginaConfiguracoes: TLayout;
    procedure rctUsuarioClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure rctTrilhoHorizontalMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure rctIndicadorHorizontalMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure rctIndicadorHorizontalMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure rctIndicadorHorizontalMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure rctSairMouseEnter(Sender: TObject);
    procedure rctSairMouseLeave(Sender: TObject);
    procedure rctSairClick(Sender: TObject);
    procedure rctMenuCentralPedidosClick(Sender: TObject);
    procedure rctMenuPedidosClick(Sender: TObject);
    procedure rctMenuClientesClick(Sender: TObject);
    procedure rctMenuEmpresasClick(Sender: TObject);
    procedure rctMenuCardapioClick(Sender: TObject);
    procedure rctMenuProdutosClick(Sender: TObject);
    procedure rctMenuSaboresClick(Sender: TObject);
    procedure rctMenuCombosClick(Sender: TObject);
    procedure rctMenuPromocoesClick(Sender: TObject);
    procedure rctMenuEntregadoresClick(Sender: TObject);
    procedure rctMenuFinanceiroClick(Sender: TObject);
    procedure rctMenuRelatoriosClick(Sender: TObject);
    procedure rctMenuConfiguracoesClick(Sender: TObject);
    procedure rctMenuPedidosMouseEnter(Sender: TObject);
    procedure rctMenuPedidosMouseLeave(Sender: TObject);
    procedure rctMenuClientesMouseEnter(Sender: TObject);
    procedure rctMenuClientesMouseLeave(Sender: TObject);
    procedure rctMenuEmpresasMouseEnter(Sender: TObject);
    procedure rctMenuEmpresasMouseLeave(Sender: TObject);
    procedure rctMenuCardapioMouseEnter(Sender: TObject);
    procedure rctMenuCardapioMouseLeave(Sender: TObject);
    procedure rctMenuProdutosMouseEnter(Sender: TObject);
    procedure rctMenuProdutosMouseLeave(Sender: TObject);
    procedure rctMenuSaboresMouseEnter(Sender: TObject);
    procedure rctMenuSaboresMouseLeave(Sender: TObject);
    procedure rctMenuCombosMouseEnter(Sender: TObject);
    procedure rctMenuCombosMouseLeave(Sender: TObject);
    procedure rctMenuPromocoesMouseEnter(Sender: TObject);
    procedure rctMenuPromocoesMouseLeave(Sender: TObject);
    procedure rctMenuEntregadoresMouseEnter(Sender: TObject);
    procedure rctMenuEntregadoresMouseLeave(Sender: TObject);
    procedure rctMenuFinanceiroMouseEnter(Sender: TObject);
    procedure rctMenuFinanceiroMouseLeave(Sender: TObject);
    procedure rctMenuRelatoriosMouseEnter(Sender: TObject);
    procedure rctMenuRelatoriosMouseLeave(Sender: TObject);
    procedure rctMenuConfiguracoesMouseEnter(Sender: TObject);
    procedure rctMenuConfiguracoesMouseLeave(Sender: TObject);
    procedure rctMenuCentralPedidosMouseEnter(Sender: TObject);
    procedure rctMenuCentralPedidosMouseLeave(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FArrastandoBarra: Boolean;
    FMouseInicialAbsoluto: Single;
    FIndicadorInicialX: Single;
    FMenuSelecionado: TMenuAdmin;
    FFrameAtual: TFrame;
    FCentralPedidos: TfraCentralPedidos;
    FPedidos: TfraPedidos;
    FClientes: TfraClientes;
    FEmpresas: TfraEmpresas;
    FUsuarios: TfraUsuarios;
    FPermissoes: TfraPermissoes;
    FCardapio: TfraCardapio;
    FProdutos: TfraProdutosAdmin;
    FSabores: TfraSabores;
    FAdicionais: TfraAdicionais;
    FCombos: TfraCombos;
    FPromocoes: TfraPromocoes;
    FEntregadores: TfraEntregadores;
    FFinanceiro: TfraFinanceiro;
    FRelatorios: TfraRelatorios;
    FConfiguracoes: TfraConfiguracoes;
    FNovidades: TfraNovidades;
    FMenuUsuarios, FMenuPermissoes, FMenuBordas, FMenuAdicionais,
      FMenuNovidades: TRectangle;
    FIndicadorUsuarios, FIndicadorPermissoes, FIndicadorBordas, FIndicadorAdicionais,
      FIndicadorNovidades: TRectangle;
    FIconeUsuarios, FIconePermissoes, FIconeBordas, FIconeAdicionais, FIconeNovidades: TPath;
    FLabelUsuarios, FLabelPermissoes, FLabelBordas, FLabelAdicionais, FLabelNovidades: TLabel;
    FPopupEmpresas: TfraPopupMenu;
    FTimerCarregamento: TTimer;
    FTimerEntrada: TTimer;
    FMenuPendenteCarregamento: TMenuAdmin;

    procedure SelecionarMenu(const AMenu: TMenuAdmin);
    procedure ConfigurarItemMenu(const ARectangle: TRectangle; const APath: TPath; const ALabel: TLabel; const ASelecionado: Boolean);
    procedure ConfigurarIndicadorMenu(const ARectangle: TRectangle; const ASelecionado: Boolean);
    procedure AplicarHoverMenu(const ARectangle: TRectangle; const APath: TPath; const ALabel: TLabel; const AMenu: TMenuAdmin; const AEntrou: Boolean);
    procedure CriarFrames;
    procedure OcultarFrames;
    procedure MostrarFrame(const AFrame: TFrame);
    procedure ExibirFrame(const AMenu: TMenuAdmin);
    procedure PrepararFrame(const AFrame: TFrame);
    procedure ConfigurarIcones;
    procedure CriarMenusSeguranca;
    procedure CriarMenuDinamico(const Texto: string; const Menu: TMenuAdmin;
      out Fundo, Indicador: TRectangle; out Icone: TPath; out Rotulo: TLabel);
    procedure MenuDinamicoClick(Sender: TObject);
    procedure MenuDinamicoMouseEnter(Sender: TObject);
    procedure MenuDinamicoMouseLeave(Sender: TObject);
    procedure AplicarPermissoesMenu;
    function MenuPermitido(const AMenu: TMenuAdmin): Boolean;
    procedure CriarSeletorEmpresas;
    procedure EmpresaSelecionada(Sender: TObject; const AIdentificador: string);
    procedure RecriarFrames;
    procedure SelecionarPrimeiroMenuPermitido;
    procedure GarantirFrameCriado(const AMenu: TMenuAdmin);
    procedure AgendarCarregamento(const AMenu: TMenuAdmin);
    procedure CarregarTelaPendente(Sender: TObject);
    procedure CarregarTelaInicial(Sender: TObject);
  public
    { Public declarations }
  end;

var
  frmPrincipalAdmin: TfrmPrincipalAdmin;

implementation

{$R *.fmx}

uses uMensagem, uSensorIcons, uSessaoAdmin, uVersaoSistema,
  uCursorCamposAdmin;

procedure TfrmPrincipalAdmin.FormCreate(Sender: TObject);
var
  RotuloVersao: TLabel;
begin
  FFrameAtual := nil;

  CriarMenusSeguranca;
  CriarSeletorEmpresas;
  ConfigurarIcones;
  CriarFrames;

  RotuloVersao := TLabel.Create(Self);
  RotuloVersao.Parent := lytLogo;
  RotuloVersao.Align := TAlignLayout.Bottom;
  RotuloVersao.Height := 20;
  RotuloVersao.Margins.Bottom := 5;
  RotuloVersao.Text := VERSAO_SISTEMA_TEXTO;
  RotuloVersao.StyledSettings := [];
  RotuloVersao.TextSettings.HorzAlign := TTextAlign.Center;
  RotuloVersao.TextSettings.Font.Family := 'Manrope';
  RotuloVersao.TextSettings.Font.Size := 9;
  RotuloVersao.TextSettings.FontColor := $FF66768B;
  RotuloVersao.HitTest := False;

  FTimerCarregamento := TTimer.Create(Self);
  FTimerCarregamento.Enabled := False;
  FTimerCarregamento.Interval := 40;
  FTimerCarregamento.OnTimer := CarregarTelaPendente;

  { Permite que a janela principal seja exibida antes da criação da primeira
    tela, que é mais pesada. }
  FTimerEntrada := TTimer.Create(Self);
  FTimerEntrada.Enabled := False;
  FTimerEntrada.Interval := 100;
  FTimerEntrada.OnTimer := CarregarTelaInicial;

  lblUsuarioNome.Text := TSessaoAdmin.UsuarioNome;
  lblUsuarioPerfil.Text := TSessaoAdmin.UsuarioTipo + '  •  ' +
    TSessaoAdmin.EmpresaNome;
  AplicarPermissoesMenu;

//  rctIndicadorHorizontal.BringToFront;

{  TThread.ForceQueue(nil,
  procedure
    begin
      AtualizarBarraHorizontal;
    end
  );}

  FTimerEntrada.Enabled := True;
end;

procedure TfrmPrincipalAdmin.FormDestroy(Sender: TObject);
begin
  if Assigned(FTimerCarregamento) then
    FTimerCarregamento.Enabled := False;
  if Assigned(FTimerEntrada) then
    FTimerEntrada.Enabled := False;
  FFrameAtual := nil;
  FCentralPedidos := nil;
end;

procedure TfrmPrincipalAdmin.CarregarTelaInicial(Sender: TObject);
begin
  FTimerEntrada.Enabled := False;
  SelecionarPrimeiroMenuPermitido;
end;

procedure TfrmPrincipalAdmin.rctUsuarioClick(Sender: TObject);
begin
  if Assigned(FPopupEmpresas) then
  begin
    if FPopupEmpresas.Visible then
      FPopupEmpresas.Fechar
    else
      FPopupEmpresas.Abrir(lytConteudo.Width - FPopupEmpresas.Width - 18, 92);
  end;

  if pthUsuarioSeta.RotationAngle = 0 then
    pthUsuarioSeta.RotationAngle := 180
  else
    pthUsuarioSeta.RotationAngle := 0;
end;

procedure TfrmPrincipalAdmin.rctIndicadorHorizontalMouseDown(
  Sender: TObject;
  Button: TMouseButton;
  Shift: TShiftState;
  X, Y: Single);
var
  LPontoAbsoluto: TPointF;
begin
{  if Button <> TMouseButton.mbLeft then
    Exit;

  FArrastandoBarra := True;

  LPontoAbsoluto :=
    rctIndicadorHorizontal.LocalToAbsolute(
      PointF(X, Y)
    );

  FMouseInicialAbsoluto := LPontoAbsoluto.X;

  FIndicadorInicialX :=
    rctIndicadorHorizontal.Position.X;}
end;

procedure TfrmPrincipalAdmin.rctIndicadorHorizontalMouseMove(
  Sender: TObject;
  Shift: TShiftState;
  X, Y: Single);
var
  LPontoAbsoluto: TPointF;
  LDeslocamento: Single;
  LNovaPosicao: Single;
begin
{  if not FArrastandoBarra then
    Exit;

  if not (ssLeft in Shift) then
  begin
    FArrastandoBarra := False;
    Exit;
  end;

  LPontoAbsoluto :=
    rctIndicadorHorizontal.LocalToAbsolute(
      PointF(X, Y)
    );

  LDeslocamento :=
    LPontoAbsoluto.X -
    FMouseInicialAbsoluto;

  LNovaPosicao :=
    FIndicadorInicialX +
    LDeslocamento;

  AplicarPosicaoIndicador(LNovaPosicao);}
end;

procedure TfrmPrincipalAdmin.rctIndicadorHorizontalMouseUp(
  Sender: TObject;
  Button: TMouseButton;
  Shift: TShiftState;
  X, Y: Single);
begin
  FArrastandoBarra := False;
end;

procedure TfrmPrincipalAdmin.rctMenuCardapioClick(Sender: TObject);
begin
  SelecionarMenu(maCategorias);
end;

procedure TfrmPrincipalAdmin.rctMenuProdutosClick(Sender: TObject);
begin
  SelecionarMenu(maCardapio);
end;

procedure TfrmPrincipalAdmin.rctMenuSaboresClick(Sender: TObject);
begin
  SelecionarMenu(maSabores);
end;

procedure TfrmPrincipalAdmin.rctMenuCombosClick(Sender: TObject);
begin
  SelecionarMenu(maCombos);
end;

procedure TfrmPrincipalAdmin.rctMenuCardapioMouseEnter(Sender: TObject);
begin
  AplicarHoverMenu(rctMenuCardapio, pthMenuCardapio, lblMenuCardapio, maCategorias, True);
end;

procedure TfrmPrincipalAdmin.rctMenuCardapioMouseLeave(Sender: TObject);
begin
  AplicarHoverMenu(rctMenuCardapio, pthMenuCardapio, lblMenuCardapio, maCategorias, False);
end;

procedure TfrmPrincipalAdmin.rctMenuProdutosMouseEnter(Sender: TObject);
begin
  AplicarHoverMenu(rctMenuProdutos, pthMenuProdutos, lblMenuProdutos, maCardapio, True);
end;

procedure TfrmPrincipalAdmin.rctMenuProdutosMouseLeave(Sender: TObject);
begin
  AplicarHoverMenu(rctMenuProdutos, pthMenuProdutos, lblMenuProdutos, maCardapio, False);
end;

procedure TfrmPrincipalAdmin.rctMenuSaboresMouseEnter(Sender: TObject);
begin
  AplicarHoverMenu(rctMenuSabores, pthMenuSabores, lblMenuSabores, maSabores, True);
end;

procedure TfrmPrincipalAdmin.rctMenuSaboresMouseLeave(Sender: TObject);
begin
  AplicarHoverMenu(rctMenuSabores, pthMenuSabores, lblMenuSabores, maSabores, False);
end;

procedure TfrmPrincipalAdmin.rctMenuCombosMouseEnter(Sender: TObject);
begin
  AplicarHoverMenu(rctMenuCombos, pthMenuCombos, lblMenuCombos, maCombos, True);
end;

procedure TfrmPrincipalAdmin.rctMenuCombosMouseLeave(Sender: TObject);
begin
  AplicarHoverMenu(rctMenuCombos, pthMenuCombos, lblMenuCombos, maCombos, False);
end;

procedure TfrmPrincipalAdmin.rctMenuCentralPedidosClick(Sender: TObject);
begin
  SelecionarMenu(maCentralPedidos);
end;

procedure TfrmPrincipalAdmin.rctMenuCentralPedidosMouseEnter(Sender: TObject);
begin
  AplicarHoverMenu(rctMenuCentralPedidos, pthMenuCentralPedidos, lblMenuCentralPedidos, maCentralPedidos, True);
end;

procedure TfrmPrincipalAdmin.rctMenuCentralPedidosMouseLeave(Sender: TObject);
begin
  AplicarHoverMenu(rctMenuCentralPedidos, pthMenuCentralPedidos, lblMenuCentralPedidos, maCentralPedidos, False);
end;

procedure TfrmPrincipalAdmin.rctMenuClientesClick(Sender: TObject);
begin
  SelecionarMenu(maClientes);
end;

procedure TfrmPrincipalAdmin.rctMenuEmpresasClick(Sender: TObject);
begin SelecionarMenu(maEmpresas); end;

procedure TfrmPrincipalAdmin.rctMenuEmpresasMouseEnter(Sender: TObject);
begin AplicarHoverMenu(rctMenuEmpresas,pthMenuEmpresas,lblMenuEmpresas,maEmpresas,True); end;

procedure TfrmPrincipalAdmin.rctMenuEmpresasMouseLeave(Sender: TObject);
begin AplicarHoverMenu(rctMenuEmpresas,pthMenuEmpresas,lblMenuEmpresas,maEmpresas,False); end;

procedure TfrmPrincipalAdmin.rctMenuClientesMouseEnter(Sender: TObject);
begin
  AplicarHoverMenu(rctMenuClientes, pthMenuClientes, lblMenuClientes, maClientes, True);
end;

procedure TfrmPrincipalAdmin.rctMenuClientesMouseLeave(Sender: TObject);
begin
  AplicarHoverMenu(rctMenuClientes, pthMenuClientes, lblMenuClientes, maClientes, False);
end;

procedure TfrmPrincipalAdmin.rctMenuConfiguracoesClick(Sender: TObject);
begin
  SelecionarMenu(maConfiguracoes);
end;

procedure TfrmPrincipalAdmin.rctMenuConfiguracoesMouseEnter(Sender: TObject);
begin
  AplicarHoverMenu(rctMenuConfiguracoes, pthMenuConfiguracoes, lblMenuConfiguracoes, maConfiguracoes, True);
end;

procedure TfrmPrincipalAdmin.rctMenuConfiguracoesMouseLeave(Sender: TObject);
begin
  AplicarHoverMenu(rctMenuConfiguracoes, pthMenuConfiguracoes, lblMenuConfiguracoes, maConfiguracoes, False);
end;

procedure TfrmPrincipalAdmin.rctMenuEntregadoresClick(Sender: TObject);
begin
  SelecionarMenu(maEntregadores);
end;

procedure TfrmPrincipalAdmin.rctMenuEntregadoresMouseEnter(Sender: TObject);
begin
  AplicarHoverMenu(rctMenuEntregadores, pthMenuEntregadores, lblMenuEntregadores, maEntregadores, True);
end;

procedure TfrmPrincipalAdmin.rctMenuEntregadoresMouseLeave(Sender: TObject);
begin
  AplicarHoverMenu(rctMenuEntregadores, pthMenuEntregadores, lblMenuEntregadores, maEntregadores, False);
end;

procedure TfrmPrincipalAdmin.rctMenuFinanceiroClick(Sender: TObject);
begin
  SelecionarMenu(maFinanceiro);
end;

procedure TfrmPrincipalAdmin.rctMenuFinanceiroMouseEnter(Sender: TObject);
begin
  AplicarHoverMenu(rctMenuFinanceiro, pthMenuFinanceiro, lblMenuFinanceiro, maFinanceiro, True);
end;

procedure TfrmPrincipalAdmin.rctMenuFinanceiroMouseLeave(Sender: TObject);
begin
  AplicarHoverMenu(rctMenuFinanceiro, pthMenuFinanceiro, lblMenuFinanceiro, maFinanceiro, False);
end;

procedure TfrmPrincipalAdmin.rctMenuPedidosClick(Sender: TObject);
begin
  SelecionarMenu(maPedidos);
end;

procedure TfrmPrincipalAdmin.rctMenuPedidosMouseEnter(Sender: TObject);
begin
   AplicarHoverMenu(rctMenuPedidos, pthMenuPedidos, lblMenuPedidos, maPedidos, True);
end;

procedure TfrmPrincipalAdmin.rctMenuPedidosMouseLeave(Sender: TObject);
begin
  AplicarHoverMenu(rctMenuPedidos, pthMenuPedidos, lblMenuPedidos, maPedidos, False);
end;

procedure TfrmPrincipalAdmin.rctMenuPromocoesClick(Sender: TObject);
begin
  SelecionarMenu(maPromocoes);
end;

procedure TfrmPrincipalAdmin.rctMenuPromocoesMouseEnter(Sender: TObject);
begin
  AplicarHoverMenu(rctMenuPromocoes, pthMenuPromocoes, lblMenuPromocoes, maPromocoes, True);
end;

procedure TfrmPrincipalAdmin.rctMenuPromocoesMouseLeave(Sender: TObject);
begin
  AplicarHoverMenu(rctMenuPromocoes, pthMenuPromocoes, lblMenuPromocoes, maPromocoes, False);
end;

procedure TfrmPrincipalAdmin.rctMenuRelatoriosClick(Sender: TObject);
begin
  SelecionarMenu(maRelatorios);
end;

procedure TfrmPrincipalAdmin.rctMenuRelatoriosMouseEnter(Sender: TObject);
begin
  AplicarHoverMenu(rctMenuRelatorios, pthMenuRelatorios, lblMenuRelatorios, maRelatorios, True);
end;

procedure TfrmPrincipalAdmin.rctMenuRelatoriosMouseLeave(Sender: TObject);
begin
  AplicarHoverMenu(rctMenuRelatorios, pthMenuRelatorios, lblMenuRelatorios, maRelatorios, False);
end;

procedure TfrmPrincipalAdmin.rctSairClick(Sender: TObject);
begin
  if not TfrmMensagem.Exibir(
    'Sair do sistema',
    'Deseja realmente encerrar o painel administrativo?',
    tmConfirmacao,
    True,
    'Sair',
    'Cancelar'
  ) then
    Exit;

  TSessaoAdmin.Encerrar;
  Close;
end;

procedure TfrmPrincipalAdmin.rctSairMouseEnter(Sender: TObject);
begin
  rctSair.Fill.Color := $28FF5A65;
  rctSair.Stroke.Color := $66FF5A65;

  pthSair.Fill.Color := $FFFF7A83;
  lblSair.TextSettings.FontColor := $FFFF7A83;
end;

procedure TfrmPrincipalAdmin.rctSairMouseLeave(Sender: TObject);
begin
  rctSair.Fill.Color := $141F2A3A;
  rctSair.Stroke.Color := $3346576D;

  pthSair.Fill.Color := $FFFF5A65;
  lblSair.TextSettings.FontColor := $FFFF6B75;
end;

procedure TfrmPrincipalAdmin.ConfigurarItemMenu(const ARectangle: TRectangle; const APath: TPath; const ALabel: TLabel; const ASelecionado: Boolean);
begin
  if not Assigned(ARectangle) then
    Exit;

  if ASelecionado then
  begin
    ARectangle.Fill.Color := $2A9B6CFF;

    if Assigned(APath) then
      APath.Fill.Color := $FFB996FF;

    if Assigned(ALabel) then
    begin
      ALabel.TextSettings.FontColor := $FFCAB5FF;
      ALabel.TextSettings.Font.Style := [TFontStyle.fsBold];
    end;
  end
  else
  begin
    ARectangle.Fill.Color := $00000000;

    if Assigned(APath) then
      APath.Fill.Color := $FF9CAABC;

    if Assigned(ALabel) then
    begin
      ALabel.TextSettings.FontColor := $FFD5DCE6;
      ALabel.TextSettings.Font.Style := [];
    end;
  end;
end;

procedure TfrmPrincipalAdmin.ConfigurarIcones;
begin
  TSensorIcon.Pedido(pthMenuPedidos, $FF9CAABC);
  TSensorIcon.Usuario(pthMenuClientes, $FF9CAABC);
  TSensorIcon.Empresa(pthMenuEmpresas, $FF9CAABC);
  TSensorIcon.Cardapio(pthMenuProdutos, $FF9CAABC);
  TSensorIcon.Pizza(pthMenuCardapio, $FF9CAABC);
  TSensorIcon.Sabor(pthMenuSabores, $FF9CAABC);
  TSensorIcon.Pizza(FIconeBordas, $FF9CAABC);
  TSensorIcon.Combo(FIconeAdicionais, $FF9CAABC);
  TSensorIcon.Combo(pthMenuCombos, $FF9CAABC);
  TSensorIcon.Entrega(pthMenuEntregadores, $FF9CAABC);
  TSensorIcon.Dinheiro(pthMenuFinanceiro, $FF9CAABC);
  TSensorIcon.Relatorio(pthMenuRelatorios, $FF9CAABC);
  TSensorIcon.Configuracao(pthMenuConfiguracoes, $FF9CAABC);
  TSensorIcon.Usuario(FIconeUsuarios, $FF9CAABC);
  TSensorIcon.Configuracao(FIconePermissoes, $FF9CAABC);
  TSensorIcon.Informacao(FIconeNovidades, $FF9CAABC);
  TSensorIcon.Sair(pthSair, $FFFF5A65);
end;

procedure TfrmPrincipalAdmin.CriarSeletorEmpresas;
var
  Empresa: TEmpresaSessao;
  Texto: string;
begin
  FPopupEmpresas := TfraPopupMenu.Create(Self);
  FPopupEmpresas.Name := '';
  FPopupEmpresas.Parent := lytConteudo;
  FPopupEmpresas.Width := 260;
  FPopupEmpresas.Anchors := [TAnchorKind.akTop, TAnchorKind.akRight];
  FPopupEmpresas.OnItemClick := EmpresaSelecionada;
  FPopupEmpresas.Limpar;
  for Empresa in TSessaoAdmin.Empresas do
  begin
    Texto := Empresa.NomeFantasia;
    if SameText(Empresa.Id, TSessaoAdmin.EmpresaId) then
      Texto := '✓  ' + Texto;
    FPopupEmpresas.AdicionarItem(Empresa.Id, Texto);
  end;
end;

procedure TfrmPrincipalAdmin.EmpresaSelecionada(Sender: TObject;
  const AIdentificador: string);
var
  Erro: string;
begin
  if SameText(AIdentificador, TSessaoAdmin.EmpresaId) then
    Exit;
  if not TSessaoAdmin.SelecionarEmpresa(AIdentificador, Erro) then
  begin
    TfrmMensagem.Exibir('Erro ao trocar empresa', Erro, tmErro);
    Exit;
  end;
  lblUsuarioPerfil.Text := TSessaoAdmin.UsuarioTipo + '  •  ' +
    TSessaoAdmin.EmpresaNome;
  FreeAndNil(FPopupEmpresas);
  CriarSeletorEmpresas;
  AplicarPermissoesMenu;
  RecriarFrames;
  SelecionarPrimeiroMenuPermitido;
end;

procedure TfrmPrincipalAdmin.RecriarFrames;
begin
  FFrameAtual := nil;
  FreeAndNil(FCentralPedidos);
  FreeAndNil(FPedidos);
  FreeAndNil(FClientes);
  FreeAndNil(FEmpresas);
  FreeAndNil(FUsuarios);
  FreeAndNil(FPermissoes);
  FreeAndNil(FCardapio);
  FreeAndNil(FProdutos);
  FreeAndNil(FSabores);
  FreeAndNil(FAdicionais);
  FreeAndNil(FCombos);
  FreeAndNil(FPromocoes);
  FreeAndNil(FEntregadores);
  FreeAndNil(FFinanceiro);
  FreeAndNil(FRelatorios);
  FreeAndNil(FConfiguracoes);
  FreeAndNil(FNovidades);
  CriarFrames;
end;

procedure TfrmPrincipalAdmin.SelecionarPrimeiroMenuPermitido;
begin
  if MenuPermitido(maCentralPedidos) then SelecionarMenu(maCentralPedidos)
  else if MenuPermitido(maPedidos) then SelecionarMenu(maPedidos)
  else if MenuPermitido(maClientes) then SelecionarMenu(maClientes)
  else if MenuPermitido(maEmpresas) then SelecionarMenu(maEmpresas)
  else if MenuPermitido(maUsuarios) then SelecionarMenu(maUsuarios)
  else if MenuPermitido(maPermissoes) then SelecionarMenu(maPermissoes)
  else if MenuPermitido(maCardapio) then SelecionarMenu(maCardapio)
  else if MenuPermitido(maCategorias) then SelecionarMenu(maCategorias)
  else if MenuPermitido(maSabores) then SelecionarMenu(maSabores)
  else if MenuPermitido(maBordas) then SelecionarMenu(maBordas)
  else if MenuPermitido(maAdicionais) then SelecionarMenu(maAdicionais)
  else if MenuPermitido(maCombos) then SelecionarMenu(maCombos)
  else if MenuPermitido(maPromocoes) then SelecionarMenu(maPromocoes)
  else if MenuPermitido(maEntregadores) then SelecionarMenu(maEntregadores)
  else if MenuPermitido(maFinanceiro) then SelecionarMenu(maFinanceiro)
  else if MenuPermitido(maRelatorios) then SelecionarMenu(maRelatorios)
  else if MenuPermitido(maConfiguracoes) then SelecionarMenu(maConfiguracoes)
  else
    TfrmMensagem.Exibir(
      'Acesso ainda não configurado',
      'Este usuário não possui telas liberadas para a empresa selecionada. ' +
      'Solicite ao administrador que configure suas permissões.',
      tmAtencao
    );
end;

procedure TfrmPrincipalAdmin.CriarMenuDinamico(const Texto: string;
  const Menu: TMenuAdmin; out Fundo, Indicador: TRectangle;
  out Icone: TPath; out Rotulo: TLabel);
begin
  Fundo := TRectangle.Create(Self);
  Fundo.Parent := lytItensMenu;
  Fundo.Align := TAlignLayout.Top;
  Fundo.Height := 46;
  Fundo.Margins.Left := 12;
  Fundo.Margins.Right := 12;
  Fundo.Margins.Bottom := 5;
  Fundo.Fill.Color := $00000000;
  Fundo.Stroke.Kind := TBrushKind.None;
  Fundo.XRadius := 8;
  Fundo.YRadius := 8;
  Fundo.Cursor := crHandPoint;
  Fundo.Tag := Ord(Menu);
  Fundo.OnClick := MenuDinamicoClick;
  Fundo.OnMouseEnter := MenuDinamicoMouseEnter;
  Fundo.OnMouseLeave := MenuDinamicoMouseLeave;

  Indicador := TRectangle.Create(Self);
  Indicador.Parent := Fundo;
  Indicador.Align := TAlignLayout.Left;
  Indicador.Width := 3;
  Indicador.Margins.Top := 8;
  Indicador.Margins.Bottom := 8;
  Indicador.Fill.Color := $FF9B6CFF;
  Indicador.Stroke.Kind := TBrushKind.None;
  Indicador.Visible := False;
  Indicador.HitTest := False;

  Icone := TPath.Create(Self);
  Icone.Parent := Fundo;
  Icone.Position.Point := PointF(16, 12);
  Icone.Width := 22;
  Icone.Height := 22;
  Icone.HitTest := False;

  Rotulo := TLabel.Create(Self);
  Rotulo.Parent := Fundo;
  Rotulo.Position.Point := PointF(50, 0);
  Rotulo.Width := 136;
  Rotulo.Height := 46;
  Rotulo.Text := Texto;
  Rotulo.StyledSettings := [];
  Rotulo.TextSettings.Font.Family := 'Manrope';
  Rotulo.TextSettings.Font.Size := 11;
  Rotulo.TextSettings.FontColor := $FFD5DCE6;
  Rotulo.HitTest := False;
end;

procedure TfrmPrincipalAdmin.CriarMenusSeguranca;
begin
  CriarMenuDinamico('Usuários', maUsuarios, FMenuUsuarios,
    FIndicadorUsuarios, FIconeUsuarios, FLabelUsuarios);
  CriarMenuDinamico('Permissões', maPermissoes, FMenuPermissoes,
    FIndicadorPermissoes, FIconePermissoes, FLabelPermissoes);
  CriarMenuDinamico('Bordas', maBordas, FMenuBordas,
    FIndicadorBordas, FIconeBordas, FLabelBordas);
  CriarMenuDinamico('Adicionais', maAdicionais, FMenuAdicionais,
    FIndicadorAdicionais, FIconeAdicionais, FLabelAdicionais);
  CriarMenuDinamico('Novidades', maNovidades, FMenuNovidades,
    FIndicadorNovidades, FIconeNovidades, FLabelNovidades);
  { No FireMonkey, controles com Align=Top são ordenados pela posição
    vertical. Posiciona Bordas no intervalo entre Sabores e Combos e força
    um novo cálculo do alinhamento. }
  FMenuBordas.Align := TAlignLayout.None;
  FMenuBordas.Position.Y :=
    (rctMenuSabores.Position.Y + rctMenuCombos.Position.Y) / 2;
  FMenuBordas.Align := TAlignLayout.Top;
  FMenuAdicionais.Align := TAlignLayout.None;
  FMenuAdicionais.Position.Y :=
    (FMenuBordas.Position.Y + rctMenuCombos.Position.Y) / 2;
  FMenuAdicionais.Align := TAlignLayout.Top;
  lytItensMenu.Height := lytItensMenu.Height + 255;
end;

procedure TfrmPrincipalAdmin.MenuDinamicoClick(Sender: TObject);
begin
  SelecionarMenu(TMenuAdmin(TComponent(Sender).Tag));
end;

procedure TfrmPrincipalAdmin.MenuDinamicoMouseEnter(Sender: TObject);
var Menu: TMenuAdmin;
begin
  Menu := TMenuAdmin(TComponent(Sender).Tag);
  case Menu of
    maUsuarios: AplicarHoverMenu(FMenuUsuarios,FIconeUsuarios,FLabelUsuarios,Menu,True);
    maPermissoes: AplicarHoverMenu(FMenuPermissoes,FIconePermissoes,FLabelPermissoes,Menu,True);
    maBordas: AplicarHoverMenu(FMenuBordas,FIconeBordas,FLabelBordas,Menu,True);
    maAdicionais: AplicarHoverMenu(FMenuAdicionais,FIconeAdicionais,FLabelAdicionais,Menu,True);
    maNovidades: AplicarHoverMenu(FMenuNovidades,FIconeNovidades,FLabelNovidades,Menu,True);
  end;
end;

procedure TfrmPrincipalAdmin.MenuDinamicoMouseLeave(Sender: TObject);
var Menu: TMenuAdmin;
begin
  Menu := TMenuAdmin(TComponent(Sender).Tag);
  case Menu of
    maUsuarios: AplicarHoverMenu(FMenuUsuarios,FIconeUsuarios,FLabelUsuarios,Menu,False);
    maPermissoes: AplicarHoverMenu(FMenuPermissoes,FIconePermissoes,FLabelPermissoes,Menu,False);
    maBordas: AplicarHoverMenu(FMenuBordas,FIconeBordas,FLabelBordas,Menu,False);
    maAdicionais: AplicarHoverMenu(FMenuAdicionais,FIconeAdicionais,FLabelAdicionais,Menu,False);
    maNovidades: AplicarHoverMenu(FMenuNovidades,FIconeNovidades,FLabelNovidades,Menu,False);
  end;
end;

function TfrmPrincipalAdmin.MenuPermitido(const AMenu: TMenuAdmin): Boolean;
begin
  case AMenu of
    maCentralPedidos: Result := TSessaoAdmin.Pode('dashboard.visualizar');
    maPedidos: Result := TSessaoAdmin.Pode('pedidos.visualizar');
    maClientes: Result := TSessaoAdmin.Pode('clientes.visualizar');
    maEmpresas: Result := TSessaoAdmin.Pode('empresas.visualizar');
    maUsuarios: Result := TSessaoAdmin.Pode('usuarios.visualizar');
    maPermissoes: Result := TSessaoAdmin.Pode('permissoes.visualizar');
    maCardapio: Result := TSessaoAdmin.Pode('cardapio.visualizar');
    maCategorias: Result := TSessaoAdmin.Pode('categorias.visualizar');
    maSabores: Result := TSessaoAdmin.Pode('sabores.visualizar');
    maBordas: Result := TSessaoAdmin.Pode('sabores.visualizar');
    maAdicionais: Result := TSessaoAdmin.Pode('cardapio.visualizar');
    maCombos: Result := TSessaoAdmin.Pode('combos.visualizar');
    maPromocoes: Result := TSessaoAdmin.Pode('promocoes.visualizar');
    maEntregadores: Result := TSessaoAdmin.Pode('entregadores.visualizar');
    maFinanceiro: Result := TSessaoAdmin.Pode('financeiro.visualizar');
    maRelatorios: Result := TSessaoAdmin.Pode('relatorios.visualizar');
    maConfiguracoes: Result := TSessaoAdmin.Pode('configuracoes.visualizar');
    maNovidades: Result := True;
  else
    Result := False;
  end;
end;

procedure TfrmPrincipalAdmin.AplicarPermissoesMenu;
begin
  rctMenuCentralPedidos.Visible := MenuPermitido(maCentralPedidos);
  rctMenuPedidos.Visible := MenuPermitido(maPedidos);
  rctMenuClientes.Visible := MenuPermitido(maClientes);
  rctMenuEmpresas.Visible := MenuPermitido(maEmpresas);
  FMenuUsuarios.Visible := MenuPermitido(maUsuarios);
  FMenuPermissoes.Visible := MenuPermitido(maPermissoes);
  rctMenuProdutos.Visible := MenuPermitido(maCardapio);
  rctMenuCardapio.Visible := MenuPermitido(maCategorias);
  rctMenuSabores.Visible := MenuPermitido(maSabores);
  FMenuBordas.Visible := MenuPermitido(maBordas);
  FMenuAdicionais.Visible := MenuPermitido(maAdicionais);
  rctMenuCombos.Visible := MenuPermitido(maCombos);
  rctMenuPromocoes.Visible := MenuPermitido(maPromocoes);
  rctMenuEntregadores.Visible := MenuPermitido(maEntregadores);
  rctMenuFinanceiro.Visible := MenuPermitido(maFinanceiro);
  rctMenuRelatorios.Visible := MenuPermitido(maRelatorios);
  rctMenuConfiguracoes.Visible := MenuPermitido(maConfiguracoes);
  FMenuNovidades.Visible := True;
end;

procedure TfrmPrincipalAdmin.ConfigurarIndicadorMenu(
  const ARectangle: TRectangle;
  const ASelecionado: Boolean);
begin
  if not Assigned(ARectangle) then
    Exit;

  ARectangle.Visible := ASelecionado;
end;

procedure TfrmPrincipalAdmin.SelecionarMenu(const AMenu: TMenuAdmin);
begin
  if not MenuPermitido(AMenu) then
    Exit;

  FMenuSelecionado := AMenu;

  ConfigurarItemMenu(rctMenuCentralPedidos, pthMenuCentralPedidos, lblMenuCentralPedidos, AMenu = maCentralPedidos);
  ConfigurarIndicadorMenu(rctIndicadorCentralPedidos, AMenu = maCentralPedidos);
  ConfigurarItemMenu(rctMenuPedidos, pthMenuPedidos, lblMenuPedidos, AMenu = maPedidos);
  ConfigurarIndicadorMenu(rctIndicadorPedidos, AMenu = maPedidos);
  ConfigurarItemMenu(rctMenuClientes, pthMenuClientes, lblMenuClientes, AMenu = maClientes);
  ConfigurarIndicadorMenu(rctIndicadorClientes, AMenu = maClientes);
  ConfigurarItemMenu(rctMenuEmpresas, pthMenuEmpresas, lblMenuEmpresas, AMenu = maEmpresas);
  ConfigurarIndicadorMenu(rctIndicadorEmpresas, AMenu = maEmpresas);
  ConfigurarItemMenu(FMenuUsuarios, FIconeUsuarios, FLabelUsuarios, AMenu = maUsuarios);
  ConfigurarIndicadorMenu(FIndicadorUsuarios, AMenu = maUsuarios);
  ConfigurarItemMenu(FMenuPermissoes, FIconePermissoes, FLabelPermissoes, AMenu = maPermissoes);
  ConfigurarIndicadorMenu(FIndicadorPermissoes, AMenu = maPermissoes);
  ConfigurarItemMenu(rctMenuProdutos, pthMenuProdutos, lblMenuProdutos, AMenu = maCardapio);
  ConfigurarIndicadorMenu(rctIndicadorProdutos, AMenu = maCardapio);
  ConfigurarItemMenu(rctMenuCardapio, pthMenuCardapio, lblMenuCardapio, AMenu = maCategorias);
  ConfigurarIndicadorMenu(rctIndicadorCardapio, AMenu = maCategorias);
  ConfigurarItemMenu(rctMenuSabores, pthMenuSabores, lblMenuSabores, AMenu = maSabores);
  ConfigurarIndicadorMenu(rctIndicadorSabores, AMenu = maSabores);
  ConfigurarItemMenu(FMenuBordas, FIconeBordas, FLabelBordas, AMenu = maBordas);
  ConfigurarIndicadorMenu(FIndicadorBordas, AMenu = maBordas);
  ConfigurarItemMenu(FMenuAdicionais, FIconeAdicionais, FLabelAdicionais, AMenu = maAdicionais);
  ConfigurarIndicadorMenu(FIndicadorAdicionais, AMenu = maAdicionais);
  ConfigurarItemMenu(rctMenuCombos, pthMenuCombos, lblMenuCombos, AMenu = maCombos);
  ConfigurarIndicadorMenu(rctIndicadorCombos, AMenu = maCombos);
  ConfigurarItemMenu(rctMenuPromocoes, pthMenuPromocoes, lblMenuPromocoes, AMenu = maPromocoes);
  ConfigurarIndicadorMenu(rctIndicadorPromocoes, AMenu = maPromocoes);
  ConfigurarItemMenu(rctMenuEntregadores, pthMenuEntregadores, lblMenuEntregadores, AMenu = maEntregadores);
  ConfigurarIndicadorMenu(rctIndicadorEntregadores, AMenu = maEntregadores);
  ConfigurarItemMenu(rctMenuFinanceiro, pthMenuFinanceiro, lblMenuFinanceiro, AMenu = maFinanceiro);
  ConfigurarIndicadorMenu(rctIndicadorFinanceiro, AMenu = maFinanceiro);
  ConfigurarItemMenu(rctMenuRelatorios, pthMenuRelatorios, lblMenuRelatorios, AMenu = maRelatorios);
  ConfigurarIndicadorMenu(rctIndicadorRelatorios, AMenu = maRelatorios);
  ConfigurarItemMenu(rctMenuConfiguracoes, pthMenuConfiguracoes, lblMenuConfiguracoes, AMenu = maConfiguracoes);
  ConfigurarIndicadorMenu(rctIndicadorConfiguracoes, AMenu = maConfiguracoes);
  ConfigurarItemMenu(FMenuNovidades, FIconeNovidades, FLabelNovidades, AMenu = maNovidades);
  ConfigurarIndicadorMenu(FIndicadorNovidades, AMenu = maNovidades);

  ExibirFrame(AMenu);
end;

procedure TfrmPrincipalAdmin.AplicarHoverMenu(
  const ARectangle: TRectangle;
  const APath: TPath;
  const ALabel: TLabel;
  const AMenu: TMenuAdmin;
  const AEntrou: Boolean);
begin
  if not Assigned(ARectangle) then
    Exit;

  if FMenuSelecionado = AMenu then
    Exit;

  if AEntrou then
  begin
    ARectangle.Fill.Color := $FF18273A;

    if Assigned(APath) then
      APath.Fill.Color := $FFB6C1D0;

    if Assigned(ALabel) then
      ALabel.TextSettings.FontColor := $FFFFFFFF;
  end
  else
  begin
    ARectangle.Fill.Color := $00000000;

    if Assigned(APath) then
      APath.Fill.Color := $FF9CAABC;

    if Assigned(ALabel) then
      ALabel.TextSettings.FontColor := $FFD5DCE6;
  end;
end;

procedure TfrmPrincipalAdmin.CriarFrames;
begin
  { Os frames são criados sob demanda para não bloquear a entrada no painel. }
end;

procedure TfrmPrincipalAdmin.GarantirFrameCriado(const AMenu: TMenuAdmin);
begin
  case AMenu of
    maCentralPedidos:
      if not Assigned(FCentralPedidos) then
      begin
        FCentralPedidos := TfraCentralPedidos.Create(Self);
        PrepararFrame(FCentralPedidos);
      end;
    maPedidos:
      if not Assigned(FPedidos) then
      begin
        FPedidos := TfraPedidos.Create(Self);
        PrepararFrame(FPedidos);
      end;
    maClientes:
      if not Assigned(FClientes) then
      begin
        FClientes := TfraClientes.Create(Self);
        PrepararFrame(FClientes);
      end;
    maEmpresas:
      if not Assigned(FEmpresas) then
      begin
        FEmpresas := TfraEmpresas.Create(Self);
        PrepararFrame(FEmpresas);
      end;
    maUsuarios:
      if not Assigned(FUsuarios) then
      begin
        FUsuarios := TfraUsuarios.Create(Self);
        PrepararFrame(FUsuarios);
      end;
    maPermissoes:
      if not Assigned(FPermissoes) then
      begin
        FPermissoes := TfraPermissoes.Create(Self);
        PrepararFrame(FPermissoes);
      end;
    maCardapio:
      if not Assigned(FProdutos) then
      begin
        FProdutos := TfraProdutosAdmin.Create(Self);
        PrepararFrame(FProdutos);
      end;
    maCategorias:
      if not Assigned(FCardapio) then
      begin
        FCardapio := TfraCardapio.Create(Self);
        PrepararFrame(FCardapio);
      end;
    maSabores, maBordas:
      if not Assigned(FSabores) then
      begin
        FSabores := TfraSabores.Create(Self);
        PrepararFrame(FSabores);
      end;
    maAdicionais:
      if not Assigned(FAdicionais) then
      begin
        FAdicionais := TfraAdicionais.Create(Self);
        PrepararFrame(FAdicionais);
      end;
    maCombos:
      if not Assigned(FCombos) then
      begin
        FCombos := TfraCombos.Create(Self);
        PrepararFrame(FCombos);
      end;
    maPromocoes:
      if not Assigned(FPromocoes) then
      begin
        FPromocoes := TfraPromocoes.Create(Self);
        PrepararFrame(FPromocoes);
      end;
    maEntregadores:
      if not Assigned(FEntregadores) then
      begin
        FEntregadores := TfraEntregadores.Create(Self);
        PrepararFrame(FEntregadores);
      end;
    maFinanceiro:
      if not Assigned(FFinanceiro) then
      begin
        FFinanceiro := TfraFinanceiro.Create(Self);
        PrepararFrame(FFinanceiro);
      end;
    maRelatorios:
      if not Assigned(FRelatorios) then
      begin
        FRelatorios := TfraRelatorios.Create(Self);
        PrepararFrame(FRelatorios);
      end;
    maConfiguracoes:
      if not Assigned(FConfiguracoes) then
      begin
        FConfiguracoes := TfraConfiguracoes.Create(Self);
        PrepararFrame(FConfiguracoes);
      end;
    maNovidades:
      if not Assigned(FNovidades) then
      begin
        FNovidades := TfraNovidades.Create(Self);
        PrepararFrame(FNovidades);
      end;
  end;
end;

procedure TfrmPrincipalAdmin.AgendarCarregamento(const AMenu: TMenuAdmin);
begin
  FMenuPendenteCarregamento := AMenu;
  FTimerCarregamento.Enabled := False;
  FTimerCarregamento.Enabled := True;
end;

procedure TfrmPrincipalAdmin.CarregarTelaPendente(Sender: TObject);
begin
  FTimerCarregamento.Enabled := False;
  if FMenuPendenteCarregamento <> FMenuSelecionado then
    Exit;

  case FMenuPendenteCarregamento of
    maCentralPedidos:
      if Assigned(FCentralPedidos) then FCentralPedidos.PrepararTela;
    maPedidos:
      if Assigned(FPedidos) then FPedidos.PrepararTela;
    maClientes:
      if Assigned(FClientes) then FClientes.PrepararTela;
    maEmpresas:
      if Assigned(FEmpresas) then FEmpresas.PrepararTela;
    maUsuarios:
      if Assigned(FUsuarios) then FUsuarios.PrepararTela;
    maPermissoes:
      if Assigned(FPermissoes) then FPermissoes.PrepararTela;
    maCardapio:
      if Assigned(FProdutos) then FProdutos.PrepararTela;
    maCategorias:
      if Assigned(FCardapio) then FCardapio.PrepararTela;
    maSabores:
      if Assigned(FSabores) then FSabores.PrepararTela;
    maBordas:
      if Assigned(FSabores) then FSabores.PrepararBordas;
    maAdicionais:
      if Assigned(FAdicionais) then FAdicionais.PrepararTela;
    maCombos:
      if Assigned(FCombos) then FCombos.PrepararTela;
    maEntregadores:
      if Assigned(FEntregadores) then FEntregadores.PrepararTela;
    maConfiguracoes:
      if Assigned(FConfiguracoes) then FConfiguracoes.PrepararTela;
  end;
end;

procedure TfrmPrincipalAdmin.OcultarFrames;
begin
  if Assigned(FCentralPedidos) then
    FCentralPedidos.Visible := False;
end;

procedure TfrmPrincipalAdmin.ExibirFrame(
  const AMenu: TMenuAdmin);
begin
  GarantirFrameCriado(AMenu);

  case AMenu of
    maCentralPedidos:
    begin
      MostrarFrame(FCentralPedidos);
      AgendarCarregamento(AMenu);
    end;

    maPedidos:
    begin
      MostrarFrame(FPedidos);
      AgendarCarregamento(AMenu);
    end;

    maClientes:
    begin
      MostrarFrame(FClientes);
      AgendarCarregamento(AMenu);
    end;

    maEmpresas:
    begin
      MostrarFrame(FEmpresas);
      AgendarCarregamento(AMenu);
    end;

    maUsuarios:
    begin
      MostrarFrame(FUsuarios);
      AgendarCarregamento(AMenu);
    end;

    maPermissoes:
    begin
      MostrarFrame(FPermissoes);
      AgendarCarregamento(AMenu);
    end;

    maCardapio:
    begin
      MostrarFrame(FProdutos);
      AgendarCarregamento(AMenu);
    end;

    maCategorias:
    begin
      MostrarFrame(FCardapio);
      AgendarCarregamento(AMenu);
    end;

    maSabores:
    begin
      MostrarFrame(FSabores);
      AgendarCarregamento(AMenu);
    end;

    maBordas:
    begin
      MostrarFrame(FSabores);
      AgendarCarregamento(AMenu);
    end;

    maAdicionais:
    begin
      MostrarFrame(FAdicionais);
      AgendarCarregamento(AMenu);
    end;

    maCombos:
    begin
      MostrarFrame(FCombos);
      AgendarCarregamento(AMenu);
    end;

    maPromocoes:
      MostrarFrame(FPromocoes);

    maEntregadores:
      begin
        MostrarFrame(FEntregadores);
        AgendarCarregamento(AMenu);
      end;

    maFinanceiro:
      MostrarFrame(FFinanceiro);

    maRelatorios:
      MostrarFrame(FRelatorios);

    maConfiguracoes:
      begin
        MostrarFrame(FConfiguracoes);
        AgendarCarregamento(AMenu);
      end;
    maNovidades:
      MostrarFrame(FNovidades);
  end;
end;

procedure TfrmPrincipalAdmin.MostrarFrame(
  const AFrame: TFrame);
begin
  if not Assigned(AFrame) then
    Exit;

  if FFrameAtual = AFrame then
    Exit;

  if Assigned(FFrameAtual) then
    FFrameAtual.Visible := False;

  FFrameAtual := AFrame;

  FFrameAtual.Visible := True;
  FFrameAtual.BringToFront;
end;

procedure TfrmPrincipalAdmin.PrepararFrame(
  const AFrame: TFrame);
begin
  if not Assigned(AFrame) then
    Exit;

  AFrame.Parent := lytContainerPagina;
  AFrame.Align := TAlignLayout.Client;
  AFrame.Visible := False;
  TCursorCamposAdmin.Aplicar(AFrame, AFrame);
end;

procedure TfrmPrincipalAdmin.rctTrilhoHorizontalMouseDown(
  Sender: TObject;
  Button: TMouseButton;
  Shift: TShiftState;
  X, Y: Single);
var
  LNovaPosicao: Single;
begin
{  if Button <> TMouseButton.mbLeft then
    Exit;

  // Centraliza o indicador no ponto clicado
  LNovaPosicao :=
    X - (rctIndicadorHorizontal.Width / 2);

  AplicarPosicaoIndicador(LNovaPosicao);}
end;

end.
