CREATE TABLE IF NOT EXISTS combo_itens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    combo_id UUID NOT NULL,
    produto_id UUID NOT NULL,
    quantidade INTEGER NOT NULL DEFAULT 1,
    ordem INTEGER NOT NULL DEFAULT 0,
    criado_em TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_combo_itens_combo
        FOREIGN KEY (combo_id) REFERENCES produtos(id) ON DELETE CASCADE,

    CONSTRAINT fk_combo_itens_produto
        FOREIGN KEY (produto_id) REFERENCES produtos(id) ON DELETE RESTRICT,

    CONSTRAINT uq_combo_item UNIQUE (combo_id, produto_id),
    CONSTRAINT ck_combo_item_quantidade CHECK (quantidade > 0),
    CONSTRAINT ck_combo_item_distinto CHECK (combo_id <> produto_id)
);

CREATE INDEX IF NOT EXISTS idx_combo_itens_combo
    ON combo_itens (combo_id, ordem);

