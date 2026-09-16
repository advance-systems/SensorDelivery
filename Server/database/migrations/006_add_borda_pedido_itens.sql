ALTER TABLE pedido_itens
ADD COLUMN IF NOT EXISTS borda_id UUID;

ALTER TABLE pedido_itens
ADD COLUMN IF NOT EXISTS borda_descricao VARCHAR(150);

ALTER TABLE pedido_itens
ADD COLUMN IF NOT EXISTS valor_borda NUMERIC(12, 2)
    NOT NULL DEFAULT 0;

ALTER TABLE pedido_itens
DROP CONSTRAINT IF EXISTS chk_pedido_itens_valor_borda;

ALTER TABLE pedido_itens
ADD CONSTRAINT chk_pedido_itens_valor_borda
    CHECK (valor_borda >= 0);

CREATE INDEX IF NOT EXISTS idx_pedido_itens_borda
    ON pedido_itens (borda_id);