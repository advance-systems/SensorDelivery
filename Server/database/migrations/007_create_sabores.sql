CREATE TABLE IF NOT EXISTS sabores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    empresa_id UUID NOT NULL,

    nome VARCHAR(120) NOT NULL,

    descricao TEXT,

    valor_adicional NUMERIC(12,2) NOT NULL DEFAULT 0,

    ativo BOOLEAN NOT NULL DEFAULT TRUE,

    ordem INTEGER NOT NULL DEFAULT 0,

    criado_em TIMESTAMP WITH TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    atualizado_em TIMESTAMP WITH TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_sabores_empresa
        FOREIGN KEY (empresa_id)
        REFERENCES empresas(id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sabores_empresa
    ON sabores (empresa_id);

CREATE INDEX IF NOT EXISTS idx_sabores_empresa_ativo
    ON sabores (empresa_id, ativo);


CREATE TABLE IF NOT EXISTS produto_sabores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    produto_id UUID NOT NULL,

    sabor_id UUID NOT NULL,

    ativo BOOLEAN NOT NULL DEFAULT TRUE,

    ordem INTEGER NOT NULL DEFAULT 0,

    criado_em TIMESTAMP WITH TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_produto_sabores_produto
        FOREIGN KEY (produto_id)
        REFERENCES produtos(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_produto_sabores_sabor
        FOREIGN KEY (sabor_id)
        REFERENCES sabores(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_produto_sabor
        UNIQUE (produto_id, sabor_id)
);

CREATE INDEX IF NOT EXISTS idx_produto_sabores_produto
    ON produto_sabores (produto_id);