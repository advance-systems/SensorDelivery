CREATE TABLE IF NOT EXISTS bordas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nome VARCHAR(120) NOT NULL,
    valor NUMERIC(12,2) NOT NULL DEFAULT 0,
    ordem INTEGER NOT NULL DEFAULT 0,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_bordas_empresa ON bordas(empresa_id);
CREATE INDEX IF NOT EXISTS idx_bordas_empresa_ativo ON bordas(empresa_id, ativo);

CREATE TABLE IF NOT EXISTS produto_bordas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id UUID NOT NULL REFERENCES produtos(id) ON DELETE CASCADE,
    borda_id UUID NOT NULL REFERENCES bordas(id) ON DELETE CASCADE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    ordem INTEGER NOT NULL DEFAULT 0,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_produto_borda UNIQUE (produto_id, borda_id)
);

CREATE INDEX IF NOT EXISTS idx_produto_bordas_produto ON produto_bordas(produto_id);
CREATE INDEX IF NOT EXISTS idx_produto_bordas_borda ON produto_bordas(borda_id);

CREATE TABLE IF NOT EXISTS borda_produto_precos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    borda_id UUID NOT NULL REFERENCES bordas(id) ON DELETE CASCADE,
    produto_id UUID NOT NULL REFERENCES produtos(id) ON DELETE CASCADE,
    valor NUMERIC(12,2) NOT NULL CHECK (valor >= 0),
    criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_borda_produto_preco UNIQUE (borda_id, produto_id)
);

CREATE INDEX IF NOT EXISTS idx_borda_produto_precos_borda
    ON borda_produto_precos (borda_id);

CREATE INDEX IF NOT EXISTS idx_borda_produto_precos_produto
    ON borda_produto_precos (produto_id);

INSERT INTO borda_produto_precos (borda_id, produto_id, valor)
SELECT b.id, p.id, b.valor
FROM bordas b
JOIN produtos p ON p.empresa_id = b.empresa_id AND p.ativo = TRUE
JOIN categorias c ON c.id = p.categoria_id
WHERE LOWER(c.nome) = 'pizzas'
ON CONFLICT (borda_id, produto_id) DO NOTHING;

INSERT INTO produto_bordas (produto_id, borda_id, ativo, ordem)
SELECT bpp.produto_id, bpp.borda_id, TRUE, b.ordem
FROM borda_produto_precos bpp
JOIN bordas b ON b.id = bpp.borda_id
ON CONFLICT (produto_id, borda_id)
DO UPDATE SET ativo = TRUE, ordem = EXCLUDED.ordem;

DROP TRIGGER IF EXISTS trg_borda_produto_precos_atualizado_em
    ON borda_produto_precos;
CREATE TRIGGER trg_borda_produto_precos_atualizado_em
BEFORE UPDATE ON borda_produto_precos
FOR EACH ROW EXECUTE FUNCTION atualizar_atualizado_em();
