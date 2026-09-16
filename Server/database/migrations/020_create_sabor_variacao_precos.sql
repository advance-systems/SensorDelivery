CREATE TABLE IF NOT EXISTS sabor_variacao_precos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sabor_id UUID NOT NULL REFERENCES sabores(id) ON DELETE CASCADE,
    variacao_id UUID NOT NULL REFERENCES produto_variacoes(id) ON DELETE CASCADE,
    valor NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (valor >= 0),
    criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_sabor_variacao_preco UNIQUE (sabor_id, variacao_id)
);

CREATE INDEX IF NOT EXISTS idx_sabor_variacao_precos_sabor
    ON sabor_variacao_precos (sabor_id);

CREATE INDEX IF NOT EXISTS idx_sabor_variacao_precos_variacao
    ON sabor_variacao_precos (variacao_id);

-- Preserva o valor atual como preço inicial para cada tamanho dos produtos
-- aos quais o sabor já está vinculado.
INSERT INTO sabor_variacao_precos (sabor_id, variacao_id, valor)
SELECT DISTINCT s.id, pv.id, s.valor_adicional
FROM sabores s
JOIN produto_sabores ps
  ON ps.sabor_id = s.id
 AND ps.ativo = TRUE
JOIN produto_variacoes pv
  ON pv.produto_id = ps.produto_id
 AND pv.ativo = TRUE
ON CONFLICT (sabor_id, variacao_id) DO NOTHING;

DROP TRIGGER IF EXISTS trg_sabor_variacao_precos_atualizado_em
    ON sabor_variacao_precos;

CREATE TRIGGER trg_sabor_variacao_precos_atualizado_em
BEFORE UPDATE ON sabor_variacao_precos
FOR EACH ROW EXECUTE FUNCTION atualizar_atualizado_em();
