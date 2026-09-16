CREATE TABLE IF NOT EXISTS entregadores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id UUID NOT NULL,
    usuario_id UUID,
    nome VARCHAR(120) NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    documento VARCHAR(30),
    veiculo VARCHAR(80),
    placa VARCHAR(12),
    disponivel BOOLEAN NOT NULL DEFAULT TRUE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_entregadores_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,

    CONSTRAINT fk_entregadores_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,

    CONSTRAINT uq_entregadores_usuario UNIQUE (usuario_id),
    CONSTRAINT uq_entregadores_empresa_telefone UNIQUE (empresa_id, telefone)
);

CREATE INDEX IF NOT EXISTS idx_entregadores_empresa_situacao
    ON entregadores (empresa_id, ativo, disponivel);

CREATE UNIQUE INDEX IF NOT EXISTS uq_entregadores_empresa_documento
    ON entregadores (empresa_id, documento)
    WHERE documento IS NOT NULL;

