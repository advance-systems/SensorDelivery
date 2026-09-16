-- A tabela pedidos já foi criada em migration anterior.
-- Esta migration fica reservada para ajustes complementares.

CREATE INDEX IF NOT EXISTS idx_pedidos_telefone
    ON pedidos (cliente_telefone);