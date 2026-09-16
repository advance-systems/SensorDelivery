ALTER TYPE status_pedido
    ADD VALUE IF NOT EXISTS 'AGUARDANDO_PAGAMENTO' BEFORE 'RASCUNHO';

CREATE TABLE IF NOT EXISTS asaas_webhook_eventos (
    evento_id VARCHAR(150) PRIMARY KEY,
    tipo VARCHAR(100) NOT NULL,
    payload JSONB NOT NULL,
    processado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_pagamentos_transacao_id
    ON pagamentos (transacao_id)
    WHERE transacao_id IS NOT NULL;

