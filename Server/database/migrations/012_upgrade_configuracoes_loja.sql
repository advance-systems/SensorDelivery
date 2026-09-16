ALTER TABLE loja_configuracao
    ADD COLUMN IF NOT EXISTS taxa_entrega NUMERIC(12,2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS pedido_minimo NUMERIC(12,2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS tempo_entrega_minutos INTEGER NOT NULL DEFAULT 45,
    ADD COLUMN IF NOT EXISTS aceitar_pedidos_automaticamente BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS imprimir_automaticamente BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS atualizado_em TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP;

INSERT INTO loja_configuracao (empresa_id, modo_funcionamento)
SELECT id, 'AUTOMATICO' FROM empresas
ON CONFLICT (empresa_id) DO NOTHING;

INSERT INTO loja_horarios
    (empresa_id, dia_semana, horario_abertura, horario_fechamento, fechado)
SELECT e.id, d.dia, '18:00'::time, '23:00'::time, FALSE
FROM empresas e CROSS JOIN generate_series(0, 6) AS d(dia)
ON CONFLICT (empresa_id, dia_semana) DO NOTHING;
