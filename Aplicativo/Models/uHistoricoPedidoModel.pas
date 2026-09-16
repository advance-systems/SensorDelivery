unit uHistoricoPedidoModel;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  TSaborHistoricoPedido = class
  public
    Id: string;
    Descricao: string;
    Valor: Currency;
  end;

  TItemHistoricoPedido = class
  private
    FSabores:
      TObjectList<TSaborHistoricoPedido>;
  public
    Id: string;
    ProdutoId: string;
    ProdutoDescricao: string;

    TamanhoId: string;
    TamanhoDescricao: string;

    Quantidade: Integer;

    ValorUnitario: Currency;
    ValorTotal: Currency;

    Observacao: string;

    BordaId: string;
    BordaDescricao: string;
    ValorBorda: Currency;

    constructor Create;
    destructor Destroy; override;

    property Sabores:
      TObjectList<TSaborHistoricoPedido>
      read FSabores;
  end;

  TPedidoHistorico = class
  private
    FItens:
      TObjectList<TItemHistoricoPedido>;
  public
    Id: string;
    Numero: Integer;
    Status: string;
    TipoAtendimento: string;

    Subtotal: Currency;
    TaxaEntrega: Currency;
    Desconto: Currency;
    Acrescimo: Currency;
    ValorTotal: Currency;

    Observacao: string;
    CriadoEm: string;

    constructor Create;
    destructor Destroy; override;

    function EstaFinalizado: Boolean;
    function EstaEmAndamento: Boolean;
    function StatusDescricao: string;

    property Itens:
      TObjectList<TItemHistoricoPedido>
      read FItens;
  end;

implementation

constructor TItemHistoricoPedido.Create;
begin
  inherited;

  FSabores :=
    TObjectList<TSaborHistoricoPedido>.Create(
      True
    );
end;

destructor TItemHistoricoPedido.Destroy;
begin
  FSabores.Free;
  inherited;
end;

constructor TPedidoHistorico.Create;
begin
  inherited;

  FItens :=
    TObjectList<TItemHistoricoPedido>.Create(
      True
    );
end;

destructor TPedidoHistorico.Destroy;
begin
  FItens.Free;
  inherited;
end;

function TPedidoHistorico.EstaFinalizado:
  Boolean;
begin
  Result :=
    SameText(Status, 'FINALIZADO') or
    SameText(Status, 'ENTREGUE');
end;

function TPedidoHistorico.EstaEmAndamento:
  Boolean;
begin
  Result :=
    not EstaFinalizado and
    not SameText(Status, 'CANCELADO');
end;

function TPedidoHistorico.StatusDescricao:
  string;
begin
  if SameText(Status, 'RASCUNHO') or
     SameText(Status, 'NOVO') then
    Exit('Pedido recebido');

  if SameText(Status, 'CONFIRMADO') then
    Exit('Pedido confirmado');

  if SameText(Status, 'EM_PREPARO') then
    Exit('Em preparo');

  if SameText(Status, 'PRONTO') then
    Exit('Pronto');

  if SameText(Status, 'EM_ENTREGA') or
     SameText(Status, 'SAIU_ENTREGA') or
     SameText(Status, 'SAIU_PARA_ENTREGA') then
    Exit('Saiu para entrega');

  if EstaFinalizado then
    Exit('Finalizado');

  if SameText(Status, 'CANCELADO') then
    Exit('Cancelado');

  Result := Status;
end;

end.
