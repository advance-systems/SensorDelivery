program SensorDelivery;

uses
  System.StartUpCopy,
  System.UITypes,
  FMX.Forms,
  uPrincipalAdmin in 'uPrincipalAdmin.pas' {frmPrincipalAdmin},
  uFramePedidoKanban in 'Frames\uFramePedidoKanban.pas' {fraPedidoKanban: TFrame},
  uMensagem in 'Utils\uMensagem.pas' {frmMensagem},
  uSensorIcons in 'Utils\uSensorIcons.pas',
  uImagemUpload in 'Utils\uImagemUpload.pas',
  uApiConfig in 'Utils\uApiConfig.pas',
  uSessaoAdmin in 'Utils\uSessaoAdmin.pas',
  uAlertaNovoPedido in 'Utils\uAlertaNovoPedido.pas',
  uNavegacaoCampos in 'Utils\uNavegacaoCampos.pas',
  uCursorCamposAdmin in 'Utils\uCursorCamposAdmin.pas',
  uVersaoSistema in 'Utils\uVersaoSistema.pas',
  uLogin in 'uLogin.pas' {frmLogin},
  uFrameCentralPedidos in 'Frames\uFrameCentralPedidos.pas' {fraCentralPedidos: TFrame},
  uFramePedidos in 'Frames\uFramePedidos.pas' {fraPedidos: TFrame},
  uFrameClientes in 'Frames\uFrameClientes.pas' {fraClientes: TFrame},
  uFrameFiltro in 'Frames\uFrameFiltro.pas' {fraFiltro: TFrame},
  uFrameItemPedido in 'Frames\uFrameItemPedido.pas' {fraItemPedido: TFrame},
  uFrameItemProduto in 'Frames\uFrameItemProduto.pas' {fraItemProduto: TFrame},
  uFrameCardapio in 'Frames\uFrameCardapio.pas' {fraCardapio: TFrame},
  uFrameSabores in 'Frames\uFrameSabores.pas' {fraSabores: TFrame},
  uFrameAdicionais in 'Frames\uFrameAdicionais.pas',
  uFrameProdutosAdmin in 'Frames\uFrameProdutosAdmin.pas' {fraProdutosAdmin: TFrame},
  uFrameCombos in 'Frames\uFrameCombos.pas' {fraCombos: TFrame},
  uFrameEmpresas in 'Frames\uFrameEmpresas.pas' {fraEmpresas: TFrame},
  uFrameUsuarios in 'Frames\uFrameUsuarios.pas' {fraUsuarios: TFrame},
  uFramePermissoes in 'Frames\uFramePermissoes.pas' {fraPermissoes: TFrame},
  uFrameConfiguracoes in 'Frames\uFrameConfiguracoes.pas' {fraConfiguracoes: TFrame},
  uFrameEntregadores in 'Frames\uFrameEntregadores.pas' {fraEntregadores: TFrame},
  uFrameFinanceiro in 'Frames\uFrameFinanceiro.pas' {fraFinanceiro: TFrame},
  uFramePromocoes in 'Frames\uFramePromocoes.pas' {fraPromocoes: TFrame},
  uFrameRelatorios in 'Frames\uFrameRelatorios.pas' {fraRelatorios: TFrame},
  uFramePopupMenu in 'Frames\uFramePopupMenu.pas' {fraPopupMenu: TFrame},
  uFrameSensorButton in 'Frames\uFrameSensorButton.pas' {fraSensorButton: TFrame},
  uFrameSensorEdit in 'Frames\uFrameSensorEdit.pas' {fraSensorEdit: TFrame},
  uFrameItemSabor in 'Frames\uFrameItemSabor.pas' {fraItemSabor: TFrame},
  uFrameItemBorda in 'Frames\uFrameItemBorda.pas' {fraItemBorda: TFrame},
  uFrameItemAdicional in 'Frames\uFrameItemAdicional.pas' {fraItemAdicional: TFrame},
  uPedidoNovo in 'uPedidoNovo.pas',
  uFrameItemNovoPedido in 'Frames\uFrameItemNovoPedido.pas' {fraItemNovoPedido: TFrame},
  uFrameNovidades in 'Frames\uFrameNovidades.pas';

{$R *.res}

var
  Login: TfrmLogin;

begin
  Application.Initialize;
  Login := TfrmLogin.Create(nil);
  try
    if Login.ShowModal = mrOk then
    begin
      Application.CreateForm(TfrmPrincipalAdmin, frmPrincipalAdmin);
      Application.Run;
    end;
  finally
    Login.Free;
  end;
end.
