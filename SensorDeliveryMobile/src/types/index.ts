export interface Empresa {
  id: string;
  nome: string;
  telefone?: string;
  endereco?: string;
  cidade?: string;
  uf?: string;
  logoUrl?: string;
  ativo?: boolean;
}

export interface HorarioDia {
  dia_semana: number;
  horario_abertura: string;
  horario_fechamento: string;
  fechado: boolean;
}

export interface LojaStatus {
  aberta: boolean;
  status?: string;
  motivo?: string;
  mensagem?: string;
  horarioFuncionamento?: string;
  mensagemFechado?: string;
  tempoEntregaMin?: number;
  tempoEntregaMax?: number;
  taxaEntregaPadrao?: number;
  hoje?: HorarioDia;
  horarios?: HorarioDia[];
}

export interface Categoria {
  id: string;
  nome: string;
  iconeUrl?: string;
  ordem?: number;
}

export interface TamanhoPizza {
  id: string;
  nome: string;
  sigla: string;
  descricao?: string;
  fatias?: number;
  maxSabores: number;
  precoBase: number;
}

export interface SaborPizza {
  id: string;
  nome: string;
  descricao?: string;
  precoAdicional?: number;
  categoriaSabor?: 'Tradicional' | 'Especial' | 'Doce' | string;
  imagemUrl?: string;
}

export interface BordaPizza {
  id: string;
  nome: string;
  descricao?: string;
  preco: number;
}

export interface Produto {
  id: string;
  empresaId: string;
  categoriaId?: string;
  categoriaNome?: string;
  nome: string;
  descricao?: string;
  preco: number;
  imagemUrl?: string;
  ativo: boolean;
  tipo?: 'PIZZA' | 'GERAL' | 'BEBIDA' | 'SOBREMESA';
  destaque?: boolean;
}

export interface ItemCarrinho {
  id: string; // uuid único do item no carrinho
  produtoId: string;
  nome: string;
  precoUnitario: number;
  quantidade: number;
  observacao?: string;
  tipo?: 'PIZZA' | 'GERAL';
  tamanho?: TamanhoPizza;
  sabores?: SaborPizza[];
  borda?: BordaPizza;
  imagemUrl?: string;
}

export interface ClienteEndereco {
  nome: string;
  telefone: string;
  cep?: string;
  logradouro: string;
  numero: string;
  complemento?: string;
  bairro: string;
  cidade: string;
  uf: string;
  referencia?: string;
}

export type TipoEntrega = 'DELIVERY' | 'RETIRADA';
export type FormaPagamento = 'PIX' | 'DINHEIRO' | 'CARTAO_CREDITO' | 'CARTAO_DEBITO' | 'CARTAO_ENTREGA';

export interface PedidoPayload {
  empresaId: string;
  cliente: {
    nome: string;
    telefone: string;
    cpf?: string;
  };
  tipoEntrega: TipoEntrega;
  enderecoEntrega?: ClienteEndereco;
  itens: {
    produtoId: string;
    nome: string;
    quantidade: number;
    precoUnitario: number;
    observacao?: string;
    tamanhoId?: string;
    saboresIds?: string[];
    bordaId?: string;
  }[];
  formaPagamento: FormaPagamento;
  trocoPara?: number;
  observacaoGeral?: string;
  subtotal: number;
  taxaEntrega: number;
  desconto?: number;
  total: number;
}

export type StatusPedido = 'RASCUNHO' | 'NOVO' | 'CONFIRMADO' | 'EM_PREPARO' | 'PRONTO' | 'SAIU_ENTREGA' | 'ENTREGUE' | 'FINALIZADO' | 'CANCELADO';

export interface PedidoResponse {
  id: string;
  numero: number;
  status: StatusPedido;
  total: number;
  subtotal: number;
  taxaEntrega: number;
  tipoEntrega: TipoEntrega;
  formaPagamento: FormaPagamento;
  criadoEm: string;
  pix?: {
    copiaCola: string;
    qrCodeBase64: string;
    chave?: string;
    expiracaoEm?: string;
  };
}
