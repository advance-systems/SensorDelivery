unit uCarrinhoModel;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  TSaborCarrinho = class
  public
    Id: String;
    Descricao: string;
    Valor: Currency;
  end;

  TItemCarrinho = class
  private
    FSabores: TObjectList<TSaborCarrinho>;
  public
    Identificador: string;

    ProdutoId: String;
    ProdutoDescricao: string;

    TamanhoId: String;
    TamanhoDescricao: string;
    ValorBase: Currency;

    BordaId: String;
    BordaDescricao: string;
    ValorBorda: Currency;

    Quantidade: Integer;
    Observacao: string;

    constructor Create;
    destructor Destroy; override;

    property Sabores: TObjectList<TSaborCarrinho>
      read FSabores;

    function ValorSabores: Currency;
    function ValorUnitario: Currency;
    function ValorTotal: Currency;
  end;

  TCarrinho = class
  private
    FItens: TObjectList<TItemCarrinho>;
    FOnAlterado: TNotifyEvent;

    procedure NotificarAlteracao;

    class var FInstancia: TCarrinho;
  public
    constructor CreateInterno;
    destructor Destroy; override;

    class function Instancia: TCarrinho;
    class procedure Liberar;

    procedure Adicionar(const AItem: TItemCarrinho);
    procedure Remover(AItem: TItemCarrinho);
    procedure Limpar;
    procedure Atualizar;

    function QuantidadeItens: Integer;
    function QuantidadeProdutos: Integer;
    function ValorTotal: Currency;

    property Itens: TObjectList<TItemCarrinho>
      read FItens;

    property OnAlterado: TNotifyEvent
      read FOnAlterado
      write FOnAlterado;
  end;

implementation

{ TItemCarrinho }

constructor TItemCarrinho.Create;
begin
  inherited;

  FSabores := TObjectList<TSaborCarrinho>.Create(True);
  Identificador := TGUID.NewGuid.ToString;
  Quantidade := 1;
end;

destructor TItemCarrinho.Destroy;
begin
  FSabores.Free;
  inherited;
end;

function TItemCarrinho.ValorSabores: Currency;
var
  LSabor: TSaborCarrinho;
begin
  Result := 0;

  for LSabor in FSabores do
    if LSabor.Valor > Result then
      Result := LSabor.Valor;
end;

function TItemCarrinho.ValorUnitario: Currency;
var
  LValorSabor: Currency;
begin
  LValorSabor := ValorSabores;
  { Quando o produto possui preço, o sabor representa um adicional.
    Quando o produto não possui preço, o sabor define o preço base. }
  if ValorBase > 0 then
    Result := ValorBase + LValorSabor
  else
    Result := LValorSabor;
  Result := Result + ValorBorda;
end;

function TItemCarrinho.ValorTotal: Currency;
begin
  Result := ValorUnitario * Quantidade;
end;

{ TCarrinho }

constructor TCarrinho.CreateInterno;
begin
  inherited Create;
  FItens := TObjectList<TItemCarrinho>.Create(True);
end;

destructor TCarrinho.Destroy;
begin
  FItens.Free;
  inherited;
end;

class function TCarrinho.Instancia: TCarrinho;
begin
  if not Assigned(FInstancia) then
    FInstancia := TCarrinho.CreateInterno;

  Result := FInstancia;
end;

class procedure TCarrinho.Liberar;
begin
  FreeAndNil(FInstancia);
end;

procedure TCarrinho.NotificarAlteracao;
begin
  if Assigned(FOnAlterado) then
    FOnAlterado(Self);
end;

procedure TCarrinho.Adicionar(const AItem: TItemCarrinho);
begin
  if not Assigned(AItem) then
    Exit;

  FItens.Add(AItem);
  NotificarAlteracao;
end;

procedure TCarrinho.Remover(
  AItem: TItemCarrinho);
begin
  if not Assigned(AItem) then
    Exit;

  FItens.Remove(AItem);

  NotificarAlteracao;
end;

procedure TCarrinho.Limpar;
begin
  FItens.Clear;
  NotificarAlteracao;
end;

function TCarrinho.QuantidadeItens: Integer;
begin
  Result := FItens.Count;
end;

function TCarrinho.QuantidadeProdutos: Integer;
var
  LItem: TItemCarrinho;
begin
  Result := 0;

  for LItem in FItens do
    Result := Result + LItem.Quantidade;
end;

function TCarrinho.ValorTotal: Currency;
var
  LItem: TItemCarrinho;
begin
  Result := 0;

  for LItem in FItens do
    Result := Result + LItem.ValorTotal;
end;

procedure TCarrinho.Atualizar;
begin
  NotificarAlteracao;
end;

initialization

finalization
  TCarrinho.Liberar;

end.
