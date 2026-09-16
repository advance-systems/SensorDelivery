unit uPedidoNovo;

interface

uses
  System.Generics.Collections,
  System.SysUtils;

type
  TSaborPedido = class
  public
    Id: string;
    Descricao: string;
    Valor: Currency;
  end;

  TAdicionalPedido = class
  public
    Id: string;
    Descricao: string;
    Valor: Currency;
    Quantidade: Integer;
  end;

  TItemPedidoNovo = class
  private
    FSabores: TObjectList<TSaborPedido>;
    FAdicionais: TObjectList<TAdicionalPedido>;
  public
    ProdutoId: string;
    ProdutoDescricao: string;

    Categoria: string;

    TamanhoId: string;
    TamanhoDescricao: string;

    BordaId: string;
    BordaDescricao: string;
    ValorBorda: Currency;

    Quantidade: Integer;

    Observacao: string;

    ValorBase: Currency;

    constructor Create;
    destructor Destroy; override;

    property Sabores: TObjectList<TSaborPedido>
      read FSabores;

    property Adicionais: TObjectList<TAdicionalPedido>
      read FAdicionais;

    function ValorSabores: Currency;
    function ValorAdicionais: Currency;
    function ValorUnitario: Currency;
    function ValorTotal: Currency;
  end;

  TPedidoNovo = class
  private
    FItens: TObjectList<TItemPedidoNovo>;
  public
    ClienteId: string;
    ClienteNome: string;
    Telefone: string;
    TipoEntrega: string;
    Endereco: string;
    TaxaEntrega: Currency;
    Desconto: Currency;
    NumeroPedido: Integer;
    Observacao: string;
    Status: string;
    DataHora: TDateTime;

    constructor Create;
    destructor Destroy; override;

    property Itens: TObjectList<TItemPedidoNovo>
      read FItens;

    function SubTotal: Currency;
    function Total: Currency;
  end;

implementation

constructor TItemPedidoNovo.Create;
begin
  inherited;

  FSabores := TObjectList<TSaborPedido>.Create(True);
  FAdicionais := TObjectList<TAdicionalPedido>.Create(True);
end;

destructor TItemPedidoNovo.Destroy;
begin
  FSabores.Free;
  FAdicionais.Free;

  inherited;
end;

function TItemPedidoNovo.ValorSabores: Currency;
var
  LSabor: TSaborPedido;
begin
  Result := 0;

  for LSabor in FSabores do
    Result := Result + LSabor.Valor;
end;

function TItemPedidoNovo.ValorAdicionais: Currency;
var
  LAdicional: TAdicionalPedido;
begin
  Result := 0;

  for LAdicional in FAdicionais do
    Result := Result + (LAdicional.Valor * LAdicional.Quantidade);
end;

function TItemPedidoNovo.ValorUnitario: Currency;
begin
  Result :=
      ValorBase
    + ValorBorda
    + ValorSabores
    + ValorAdicionais;
end;

function TItemPedidoNovo.ValorTotal: Currency;
begin
  Result :=
    ValorUnitario *
    Quantidade;
end;

constructor TPedidoNovo.Create;
begin
  inherited;

  FItens := TObjectList<TItemPedidoNovo>.Create(True);
end;

destructor TPedidoNovo.Destroy;
begin
  FItens.Free;
  inherited;
end;

function TPedidoNovo.SubTotal: Currency;
var
  LItem: TItemPedidoNovo;
begin
  Result := 0;

  for LItem in FItens do
    Result := Result + LItem.ValorTotal;
end;

function TPedidoNovo.Total: Currency;
begin
  Result :=
      SubTotal
    + TaxaEntrega
    - Desconto;
end;

end.
