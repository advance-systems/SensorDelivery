CREATE TABLE IF NOT EXISTS pedido_item_sabores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_item_id UUID NOT NULL,
    sabor_id UUID,
    sabor_descricao VARCHAR(150) NOT NULL,
    valor NUMERIC(12, 2) NOT NULL DEFAULT 0,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_pedido_item_sabores_item
        FOREIGN KEY (pedido_item_id)
        REFERENCES pedido_itens(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_pedido_item_sabores_sabor
        FOREIGN KEY (sabor_id)
        REFERENCES sabores(id)
        ON DELETE SET NULL,

    CONSTRAINT chk_pedido_item_sabores_valor
        CHECK (valor >= 0)
);

CREATE INDEX IF NOT EXISTS idx_pedido_item_sabores_item
    ON pedido_item_sabores (pedido_item_id);
