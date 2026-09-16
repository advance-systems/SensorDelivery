export interface PedidoCliente {
    nome: string;
    telefone: string;
}

export interface PedidoEndereco {
    cep?: string;
    logradouro?: string;
    numero?: string;
    complemento?: string;
    bairro?: string;
    cidade?: string;
    uf?: string;
    referencia?: string;
}

export interface PedidoPagamento {
    forma: string;
    troco_para?: number;
}

export interface PedidoValores {
    subtotal: number;
    desconto?: number;
    taxa_entrega: number;
    acrescimo?: number;
    total: number;
}

export interface PedidoSabor {
    id?: number;
    descricao: string;
    valor: number;
}

export interface PedidoItem {
    identificador?: string;

    produto_id?: number;
    produto_descricao: string;

    tamanho_id?: number;
    tamanho_descricao?: string;
    valor_base: number;

    borda_id?: number | null;
    borda_descricao?: string;
    valor_borda: number;

    quantidade: number;
    observacao?: string;

    valor_unitario: number;
    valor_total: number;

    sabores: PedidoSabor[];
}

export interface CriarPedidoBody {
    empresa_id?: number;

    cliente: PedidoCliente;

    tipo_recebimento: 'ENTREGA' | 'RETIRADA';

    endereco?: PedidoEndereco;

    pagamento: PedidoPagamento;

    observacao?: string;

    valores: PedidoValores;

    itens: PedidoItem[];
}