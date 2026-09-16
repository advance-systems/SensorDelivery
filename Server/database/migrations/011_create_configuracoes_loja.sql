CREATE TABLE IF NOT EXISTS loja_configuracao (
    empresa_id UUID PRIMARY KEY REFERENCES empresas(id) ON DELETE CASCADE,
    modo_funcionamento VARCHAR(12) NOT NULL DEFAULT 'AUTOMATICO',
    mensagem_fechada TEXT,
    taxa_entrega NUMERIC(12,2) NOT NULL DEFAULT 0,
    pedido_minimo NUMERIC(12,2) NOT NULL DEFAULT 0,
    tempo_entrega_minutos INTEGER NOT NULL DEFAULT 45,
    aceitar_pedidos_automaticamente BOOLEAN NOT NULL DEFAULT FALSE,
    imprimir_automaticamente BOOLEAN NOT NULL DEFAULT FALSE,
    atualizado_em TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_loja_modo CHECK (modo_funcionamento IN ('AUTOMATICO','ABERTO','FECHADO')),
    CONSTRAINT ck_loja_valores CHECK (taxa_entrega >= 0 AND pedido_minimo >= 0 AND tempo_entrega_minutos > 0)
);

CREATE TABLE IF NOT EXISTS loja_horarios (
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    dia_semana INTEGER NOT NULL,
    horario_abertura TIME NOT NULL DEFAULT '18:00',
    horario_fechamento TIME NOT NULL DEFAULT '23:00',
    fechado BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (empresa_id, dia_semana),
    CONSTRAINT ck_loja_horario_dia CHECK (dia_semana BETWEEN 0 AND 6)
);

INSERT INTO loja_configuracao (empresa_id)
SELECT id FROM empresas ON CONFLICT (empresa_id) DO NOTHING;

INSERT INTO loja_horarios (empresa_id, dia_semana)
SELECT e.id, d.dia FROM empresas e CROSS JOIN generate_series(0, 6) AS d(dia)
ON CONFLICT (empresa_id, dia_semana) DO NOTHING;

