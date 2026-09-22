-- Migration 027: Estrutura para integração oficial com o iFood
-- Permite armazenar credenciais OAuth do restaurante e controlar polling/eventos do iFood

-- 1. Campos de identificação de canal no pedido
ALTER TABLE pedidos
    ADD COLUMN IF NOT EXISTS canal_origem VARCHAR(30) NOT NULL DEFAULT 'CARDAPIO_WEB',
    ADD COLUMN IF NOT EXISTS ifood_order_id VARCHAR(100),
    ADD COLUMN IF NOT EXISTS ifood_order_code VARCHAR(20),
    ADD COLUMN IF NOT EXISTS ifood_payload JSONB;

CREATE INDEX IF NOT EXISTS idx_pedidos_ifood_order_id
    ON pedidos (ifood_order_id);

CREATE INDEX IF NOT EXISTS idx_pedidos_canal_origem
    ON pedidos (canal_origem);

-- 2. Tabela de configuração do iFood por empresa
CREATE TABLE IF NOT EXISTS ifood_configuracao (
    empresa_id UUID PRIMARY KEY REFERENCES empresas(id) ON DELETE CASCADE,
    ativo BOOLEAN NOT NULL DEFAULT FALSE,
    client_id VARCHAR(150),
    client_secret VARCHAR(150),
    merchant_id VARCHAR(150),
    authorization_code VARCHAR(150),
    authorization_code_verifier VARCHAR(150),
    access_token TEXT,
    refresh_token TEXT,
    token_expira_em TIMESTAMPTZ,
    auto_confirmar_pedidos BOOLEAN NOT NULL DEFAULT FALSE,
    polling_ativo BOOLEAN NOT NULL DEFAULT FALSE,
    ultimo_polling_em TIMESTAMPTZ,
    ultimo_erro TEXT,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tabela de log de eventos do iFood para idempotência
CREATE TABLE IF NOT EXISTS ifood_eventos_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    event_id VARCHAR(150) NOT NULL,
    order_id VARCHAR(100) NOT NULL,
    code VARCHAR(50) NOT NULL,
    full_code VARCHAR(50),
    created_at_ifood TIMESTAMPTZ,
    payload JSONB,
    processado BOOLEAN NOT NULL DEFAULT FALSE,
    erro TEXT,
    processado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_ifood_eventos_empresa_event UNIQUE (empresa_id, event_id)
);

CREATE INDEX IF NOT EXISTS idx_ifood_eventos_order_id
    ON ifood_eventos_log (order_id);

-- Inicializa configurações para empresas existentes
INSERT INTO ifood_configuracao (empresa_id)
SELECT id FROM empresas
ON CONFLICT (empresa_id) DO NOTHING;
