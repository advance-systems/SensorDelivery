CREATE TABLE IF NOT EXISTS sabor_produto_precos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sabor_id UUID NOT NULL REFERENCES sabores(id) ON DELETE CASCADE,
    produto_id UUID NOT NULL REFERENCES produtos(id) ON DELETE CASCADE,
    valor NUMERIC(12,2) NOT NULL CHECK (valor >= 0),
    criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_sabor_produto_preco UNIQUE (sabor_id, produto_id)
);

CREATE INDEX IF NOT EXISTS idx_sabor_produto_precos_sabor
    ON sabor_produto_precos (sabor_id);

CREATE INDEX IF NOT EXISTS idx_sabor_produto_precos_produto
    ON sabor_produto_precos (produto_id);

INSERT INTO sabor_produto_precos (sabor_id, produto_id, valor)
SELECT s.id, p.id, s.valor_adicional
FROM sabores s
JOIN produtos p ON p.empresa_id = s.empresa_id AND p.ativo = TRUE
JOIN categorias c ON c.id = p.categoria_id
WHERE LOWER(c.nome) = 'pizzas'
ON CONFLICT (sabor_id, produto_id) DO NOTHING;

INSERT INTO produto_sabores (produto_id, sabor_id, ativo, ordem)
SELECT spp.produto_id, spp.sabor_id, TRUE, s.ordem
FROM sabor_produto_precos spp
JOIN sabores s ON s.id = spp.sabor_id
ON CONFLICT (produto_id, sabor_id)
DO UPDATE SET ativo = TRUE, ordem = EXCLUDED.ordem;

DROP TRIGGER IF EXISTS trg_sabor_produto_precos_atualizado_em
    ON sabor_produto_precos;
CREATE TRIGGER trg_sabor_produto_precos_atualizado_em
BEFORE UPDATE ON sabor_produto_precos
FOR EACH ROW EXECUTE FUNCTION atualizar_atualizado_em();
