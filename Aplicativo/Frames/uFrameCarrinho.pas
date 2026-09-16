unit uFrameCarrinho;

interface

uses
  System.SysUtils,
  System.Classes,
  System.UITypes,
  System.Generics.Collections,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.StdCtrls,
  FMX.Objects,
  FMX.Layouts,
  FMX.Dialogs,
  uCarrinhoModel,
  uFrameItemCarrinho, FMX.Controls.Presentation, uMensagemMobile;

type
  TContinuarPedidoEvent = procedure(Sender: TObject) of object;

  TAdicionarMaisItensEvent = procedure(Sender: TObject) of object;

  TfraCarrinho = class(TFrame)
    rctFundo: TRectangle;
    rctTopo: TRectangle;
    rctVoltar: TRectangle;
    lblVoltar: TLabel;
    lblTitulo: TLabel;
    lblQuantidadeItens: TLabel;
    vsbItens: TVertScrollBox;
    lytListaItens: TLayout;
    lytCarrinhoVazio: TLayout;
    crlCarrinhoVazio: TCircle;
    lblIconeVazio: TLabel;
    lblTituloVazio: TLabel;
    lblDescricaoVazio: TLabel;
    rctVerCardapio: TRectangle;
    lblVerCardapio: TLabel;
    rctRodape: TRectangle;
    lblSubtotalTitulo: TLabel;
    lblSubtotal: TLabel;
    lblEntregaTitulo: TLabel;
    lblEntrega: TLabel;
    rctSeparador: TRectangle;
    lblTotalTitulo: TLabel;
    lblTotal: TLabel;
    rctFinalizar: TRectangle;
    lblFinalizar: TLabel;
    lytBotoes: TLayout;
    rctAdicionarMaisItens: TRectangle;
    lblAdicionarMaisItens: TLabel;

    procedure rctVoltarClick(Sender: TObject);
    procedure rctVerCardapioClick(Sender: TObject);
    procedure rctFinalizarClick(Sender: TObject);
    procedure FrameResize(Sender: TObject);
    procedure rctAdicionarMaisItensClick(Sender: TObject);
  private
    FFramesItens: TObjectList<TfraItemCarrinho>;
    FTaxaEntrega: Currency;

    FOnVoltar: TNotifyEvent;
    FOnContinuarComprando: TNotifyEvent;
    FOnFinalizarPedido: TNotifyEvent;
    FOnVoltarCardapio: TNotifyEvent;
    FOnAdicionarMaisItens: TAdicionarMaisItensEvent;
    FOnContinuarPedido: TContinuarPedidoEvent;

    procedure LimparFramesItens;
    procedure CriarFramesItens;
    procedure AtualizarResumo;
    procedure AtualizarEstadoVazio;

    procedure ItemRemover(
      Sender: TObject;
      AItem: TItemCarrinho
    );

    procedure ItemQuantidadeAlterada(
      Sender: TObject;
      AItem: TItemCarrinho
    );

    procedure AjustarLayout;
    procedure AtualizarAlturaLista;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure AtualizarCarrinho;

    property TaxaEntrega: Currency
      read FTaxaEntrega
      write FTaxaEntrega;

    property OnVoltar: TNotifyEvent
      read FOnVoltar
      write FOnVoltar;

    property OnContinuarComprando: TNotifyEvent
      read FOnContinuarComprando
      write FOnContinuarComprando;

    property OnFinalizarPedido: TNotifyEvent
      read FOnFinalizarPedido
      write FOnFinalizarPedido;

    property OnVoltarCardapio: TNotifyEvent
      read FOnVoltarCardapio
      write FOnVoltarCardapio;

    property OnAdicionarMaisItens: TAdicionarMaisItensEvent
      read FOnAdicionarMaisItens
      write FOnAdicionarMaisItens;

    property OnContinuarPedido: TContinuarPedidoEvent
      read FOnContinuarPedido
      write FOnContinuarPedido;
  end;

implementation

{$R *.fmx}

constructor TfraCarrinho.Create(AOwner: TComponent);
begin
  inherited;

  FTaxaEntrega := 8.00;

  FFramesItens :=
    TObjectList<TfraItemCarrinho>.Create(False);

  AtualizarCarrinho;
end;

destructor TfraCarrinho.Destroy;
begin
  LimparFramesItens;
  FFramesItens.Free;

  inherited;
end;

procedure TfraCarrinho.LimparFramesItens;
var
  I: Integer;
begin
  if not Assigned(FFramesItens) then
    Exit;

  for I := FFramesItens.Count - 1 downto 0 do
    FFramesItens[I].Free;

  FFramesItens.Clear;
  lytListaItens.Height := 0;
end;

procedure TfraCarrinho.CriarFramesItens;
var
  I: Integer;
  LFrame: TfraItemCarrinho;
  LItem: TItemCarrinho;
begin
  LimparFramesItens;

  for I := 0 to TCarrinho.Instancia.Itens.Count - 1 do
  begin
    LItem := TCarrinho.Instancia.Itens[I];

    LFrame :=
      TfraItemCarrinho.Create(
        lytListaItens
      );

    LFrame.Name := '';

    LFrame.Parent :=
      lytListaItens;

    LFrame.Align :=
      TAlignLayout.Top;

    LFrame.Margins.Bottom := 10;

    LFrame.CarregarItem(LItem);

    LFrame.OnRemover :=
      ItemRemover;

    LFrame.OnQuantidadeAlterada :=
      ItemQuantidadeAlterada;

    FFramesItens.Add(LFrame);
  end;

  AtualizarAlturaLista;
end;

procedure TfraCarrinho.AtualizarAlturaLista;
const
  ESPACO = 10;
var
  I: Integer;
  LAltura: Single;
begin
  LAltura := 0;

  for I := 0 to FFramesItens.Count - 1 do
  begin
    LAltura :=
      LAltura +
      FFramesItens[I].Height;

    if I < FFramesItens.Count - 1 then
      LAltura := LAltura + ESPACO;
  end;

  lytListaItens.Height := LAltura;
end;

procedure TfraCarrinho.AtualizarResumo;
var
  LSubtotal: Currency;
  LEntrega: Currency;
  LTotal: Currency;
  LQuantidade: Integer;
begin
  LSubtotal := TCarrinho.Instancia.ValorTotal;
  LQuantidade := TCarrinho.Instancia.QuantidadeProdutos;

  if LQuantidade > 0 then
    LEntrega := FTaxaEntrega
  else
    LEntrega := 0;

  LTotal := LSubtotal + LEntrega;

  lblSubtotal.Text :=
    FormatFloat('R$ #,##0.00', LSubtotal);

  lblEntrega.Text :=
    FormatFloat('R$ #,##0.00', LEntrega);

  lblTotal.Text :=
    FormatFloat('R$ #,##0.00', LTotal);

  case LQuantidade of
    0:
      lblQuantidadeItens.Text :=
        'Seu carrinho está vazio';

    1:
      lblQuantidadeItens.Text :=
        '1 produto no carrinho';
  else
    lblQuantidadeItens.Text :=
      Format(
        '%d produtos no carrinho',
        [LQuantidade]
      );
  end;
end;

procedure TfraCarrinho.AtualizarEstadoVazio;
var
  LVazio: Boolean;
begin
  LVazio := TCarrinho.Instancia.QuantidadeItens = 0;

  lytCarrinhoVazio.Visible := LVazio;
  lytListaItens.Visible := not LVazio;
  rctRodape.Visible := not LVazio;
end;

procedure TfraCarrinho.AtualizarCarrinho;
begin
  CriarFramesItens;
  AtualizarResumo;
  AtualizarEstadoVazio;
  AjustarLayout;
end;

procedure TfraCarrinho.ItemRemover(
  Sender: TObject;
  AItem: TItemCarrinho);
begin
  if not Assigned(AItem) then
    Exit;

  TCarrinho.Instancia.Remover(AItem);

  { Atualiza depois que o evento de clique terminar,
    evitando destruir o próprio frame durante o clique. }
  TThread.ForceQueue(
    nil,
    procedure
    begin
      if not (
        csDestroying in ComponentState
      ) then
        AtualizarCarrinho;
    end
  );
end;

procedure TfraCarrinho.ItemQuantidadeAlterada(
  Sender: TObject;
  AItem: TItemCarrinho);
begin
  if not Assigned(AItem) then
    Exit;

  AtualizarResumo;

  TCarrinho.Instancia.Atualizar;
end;

procedure TfraCarrinho.rctVoltarClick(Sender: TObject);
begin
  if Assigned(FOnVoltar) then
    FOnVoltar(Self);
end;

procedure TfraCarrinho.rctVerCardapioClick(Sender: TObject);
begin
  if Assigned(FOnContinuarComprando) then
    FOnContinuarComprando(Self);
end;

procedure TfraCarrinho.rctAdicionarMaisItensClick(Sender: TObject);
begin
  if Assigned(FOnAdicionarMaisItens) then
    FOnAdicionarMaisItens(Self);
end;

procedure TfraCarrinho.rctFinalizarClick(Sender: TObject);
begin
  if TCarrinho.Instancia.QuantidadeItens = 0 then
  begin
    TMensagemMobile.Exibir('Seu carrinho está vazio.');
    Exit;
  end;

  if Assigned(FOnFinalizarPedido) then
    FOnFinalizarPedido(Self);
end;

procedure TfraCarrinho.AjustarLayout;
begin
  rctFinalizar.Width := rctRodape.Width - 36;
  rctSeparador.Width := rctRodape.Width - 36;

  lblSubtotal.Width := rctRodape.Width - 218;
  lblEntrega.Width := rctRodape.Width - 218;
  lblTotal.Width := rctRodape.Width - 198;

  lblTitulo.Width := rctTopo.Width - 90;
  lblQuantidadeItens.Width := rctTopo.Width - 90;
end;

procedure TfraCarrinho.FrameResize(Sender: TObject);
begin
  AjustarLayout;
end;

end.
