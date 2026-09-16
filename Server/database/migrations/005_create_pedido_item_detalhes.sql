CREATE TABLE IF NOT EXISTS pedido_itens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    pedido_id UUID NOT NULL,

    produto_id UUID,
    produto_descricao VARCHAR(150) NOT NULL,

    categoria VARCHAR(50),

    tamanho_id UUID,
    tamanho_descricao VARCHAR(80),

    quantidade INTEGER NOT NULL DEFAULT 1,

    valor_base NUMERIC(12, 2) NOT NULL DEFAULT 0,
    valor_unitario NUMERIC(12, 2) NOT NULL DEFAULT 0,
    valor_total NUMERIC(12, 2) NOT NULL DEFAULT 0,

    observacao TEXT,

    criado_em TIMESTAMP WITH TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_pedido_itens_pedido
        FOREIGN KEY (pedido_id)
        REFERENCES pedidos(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_pedido_itens_quantidade
        CHECK (quantidade > 0),

    CONSTRAINT chk_pedido_itens_valores
        CHECK (
            valor_base >= 0
            AND valor_unitario >= 0
            AND valor_total >= 0
        )
);

CREATE INDEX IF NOT EXISTS idx_pedido_itens_pedido
    ON pedido_itens (pedido_id);

CREATE INDEX IF NOT EXISTS idx_pedido_itens_produto
    ON pedido_itens (produto_id);