ALTER TABLE empresas
    ADD COLUMN IF NOT EXISTS pix_provedor VARCHAR(20) NOT NULL DEFAULT 'ASAAS';

ALTER TABLE empresas
    DROP CONSTRAINT IF EXISTS ck_empresas_pix_provedor;

ALTER TABLE empresas
    ADD CONSTRAINT ck_empresas_pix_provedor
    CHECK (pix_provedor IN ('ASAAS', 'SICREDI'));

CREATE TABLE IF NOT EXISTS pix_webhook_eventos (
    provedor VARCHAR(20) NOT NULL,
    evento_id VARCHAR(150) NOT NULL,
    payload JSONB NOT NULL,
    processado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (provedor, evento_id)
);

