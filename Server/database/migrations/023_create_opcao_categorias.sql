CREATE TABLE IF NOT EXISTS categoria_sabores (
    categoria_id UUID NOT NULL REFERENCES categorias(id) ON DELETE CASCADE,
    sabor_id UUID NOT NULL REFERENCES sabores(id) ON DELETE CASCADE,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (categoria_id, sabor_id)
);

CREATE TABLE IF NOT EXISTS categoria_bordas (
    categoria_id UUID NOT NULL REFERENCES categorias(id) ON DELETE CASCADE,
    borda_id UUID NOT NULL REFERENCES bordas(id) ON DELETE CASCADE,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (categoria_id, borda_id)
);

CREATE TABLE IF NOT EXISTS categoria_adicionais (
    categoria_id UUID NOT NULL REFERENCES categorias(id) ON DELETE CASCADE,
    adicional_id UUID NOT NULL REFERENCES produto_adicionais(id) ON DELETE CASCADE,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (categoria_id, adicional_id)
);

CREATE INDEX IF NOT EXISTS idx_categoria_sabores_sabor ON categoria_sabores(sabor_id);
CREATE INDEX IF NOT EXISTS idx_categoria_bordas_borda ON categoria_bordas(borda_id);
CREATE INDEX IF NOT EXISTS idx_categoria_adicionais_adicional ON categoria_adicionais(adicional_id);

INSERT INTO categoria_sabores(categoria_id, sabor_id)
SELECT DISTINCT p.categoria_id, ps.sabor_id
FROM produto_sabores ps JOIN produtos p ON p.id = ps.produto_id
ON CONFLICT DO NOTHING;

INSERT INTO categoria_bordas(categoria_id, borda_id)
SELECT DISTINCT p.categoria_id, pb.borda_id
FROM produto_bordas pb JOIN produtos p ON p.id = pb.produto_id
ON CONFLICT DO NOTHING;

INSERT INTO categoria_adicionais(categoria_id, adicional_id)
SELECT p.categoria_id, a.id
FROM produto_adicionais a JOIN produtos p ON p.id = a.produto_id
ON CONFLICT DO NOTHING;
