ALTER TABLE loja_configuracao
    ADD COLUMN IF NOT EXISTS som_alerta_pedido VARCHAR(20) NOT NULL DEFAULT 'NOTIFICACAO';

ALTER TABLE loja_configuracao
    DROP CONSTRAINT IF EXISTS ck_loja_som_alerta_pedido;

ALTER TABLE loja_configuracao
    ADD CONSTRAINT ck_loja_som_alerta_pedido
    CHECK (som_alerta_pedido IN
        ('NOTIFICACAO', 'EXCLAMACAO', 'ASTERISCO', 'ERRO', 'SEM_SOM'));
