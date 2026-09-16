BEGIN;

CREATE TYPE status_conversa AS ENUM (
  'BOT',
  'AGUARDANDO_ATENDENTE',
  'ATENDIMENTO_HUMANO',
  'FINALIZADA',
  'BLOQUEADA'
);

CREATE TYPE tipo_mensagem AS ENUM (
  'TEXTO',
  'IMAGEM',
  'AUDIO',
  'VIDEO',
  'DOCUMENTO',
  'LOCALIZACAO',
  'CONTATO',
  'SISTEMA'
);

CREATE TYPE direcao_mensagem AS ENUM (
  'ENTRADA',
  'SAIDA'
);

CREATE TYPE status_mensagem AS ENUM (
  'PENDENTE',
  'ENVIADA',
  'ENTREGUE',
  'LIDA',
  'ERRO'
);

CREATE TYPE status_carrinho AS ENUM (
  'ABERTO',
  'CONVERTIDO',
  'ABANDONADO',
  'CANCELADO'
);

CREATE TYPE status_pedido AS ENUM (
  'RASCUNHO',
  'AGUARDANDO_CONFIRMACAO',
  'CONFIRMADO',
  'EM_PREPARO',
  'PRONTO',
  'SAIU_PARA_ENTREGA',
  'ENTREGUE',
  'CANCELADO'
);

CREATE TYPE tipo_atendimento AS ENUM (
  'ENTREGA',
  'RETIRADA',
  'CONSUMO_LOCAL'
);

CREATE TYPE forma_pagamento AS ENUM (
  'PIX',
  'DINHEIRO',
  'CARTAO_CREDITO',
  'CARTAO_DEBITO',
  'ONLINE',
  'OUTRO'
);

CREATE TYPE status_pagamento AS ENUM (
  'PENDENTE',
  'APROVADO',
  'RECUSADO',
  'CANCELADO',
  'ESTORNADO'
);

CREATE TYPE status_entrega AS ENUM (
  'AGUARDANDO',
  'EM_ROTA',
  'ENTREGUE',
  'CANCELADA'
);

CREATE TABLE conversas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL,
  cliente_id UUID NOT NULL,
  whatsapp_sessao_id UUID NOT NULL,
  atendente_id UUID,
  status status_conversa NOT NULL DEFAULT 'BOT',
  ultima_mensagem TEXT,
  ultima_mensagem_em TIMESTAMPTZ,
  mensagens_nao_lidas INTEGER NOT NULL DEFAULT 0,
  iniciado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  finalizado_em TIMESTAMPTZ,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_conversas_empresa
    FOREIGN KEY (empresa_id)
    REFERENCES empresas(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_conversas_cliente
    FOREIGN KEY (cliente_id)
    REFERENCES clientes(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_conversas_whatsapp
    FOREIGN KEY (whatsapp_sessao_id)
    REFERENCES whatsapp_sessoes(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_conversas_atendente
    FOREIGN KEY (atendente_id)
    REFERENCES usuarios(id)
    ON DELETE SET NULL,

  CONSTRAINT ck_conversas_mensagens_nao_lidas
    CHECK (mensagens_nao_lidas >= 0)
);

CREATE INDEX idx_conversas_empresa_status
  ON conversas (empresa_id, status);

CREATE INDEX idx_conversas_cliente
  ON conversas (cliente_id);

CREATE INDEX idx_conversas_ultima_mensagem
  ON conversas (empresa_id, ultima_mensagem_em DESC);

CREATE TABLE mensagens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversa_id UUID NOT NULL,
  whatsapp_message_id VARCHAR(150),
  direcao direcao_mensagem NOT NULL,
  tipo tipo_mensagem NOT NULL DEFAULT 'TEXTO',
  status status_mensagem NOT NULL DEFAULT 'PENDENTE',
  conteudo TEXT,
  arquivo_url TEXT,
  mime_type VARCHAR(100),
  payload JSONB,
  enviada_em TIMESTAMPTZ,
  entregue_em TIMESTAMPTZ,
  lida_em TIMESTAMPTZ,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_mensagens_conversa
    FOREIGN KEY (conversa_id)
    REFERENCES conversas(id)
    ON DELETE CASCADE,

  CONSTRAINT uq_mensagens_whatsapp_id
    UNIQUE (whatsapp_message_id)
);

CREATE INDEX idx_mensagens_conversa_criado
  ON mensagens (conversa_id, criado_em);

CREATE INDEX idx_mensagens_status
  ON mensagens (status);

CREATE INDEX idx_mensagens_payload
  ON mensagens USING GIN (payload);

CREATE TABLE carrinhos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL,
  cliente_id UUID NOT NULL,
  conversa_id UUID,
  status status_carrinho NOT NULL DEFAULT 'ABERTO',
  subtotal NUMERIC(12,2) NOT NULL DEFAULT 0,
  desconto NUMERIC(12,2) NOT NULL DEFAULT 0,
  taxa_entrega NUMERIC(12,2) NOT NULL DEFAULT 0,
  valor_total NUMERIC(12,2) NOT NULL DEFAULT 0,
  observacoes TEXT,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  convertido_em TIMESTAMPTZ,

  CONSTRAINT fk_carrinhos_empresa
    FOREIGN KEY (empresa_id)
    REFERENCES empresas(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_carrinhos_cliente
    FOREIGN KEY (cliente_id)
    REFERENCES clientes(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_carrinhos_conversa
    FOREIGN KEY (conversa_id)
    REFERENCES conversas(id)
    ON DELETE SET NULL,

  CONSTRAINT ck_carrinhos_valores
    CHECK (
      subtotal >= 0
      AND desconto >= 0
      AND taxa_entrega >= 0
      AND valor_total >= 0
    )
);

CREATE INDEX idx_carrinhos_empresa_status
  ON carrinhos (empresa_id, status);

CREATE INDEX idx_carrinhos_cliente
  ON carrinhos (cliente_id);

CREATE TABLE carrinho_itens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  carrinho_id UUID NOT NULL,
  produto_id UUID NOT NULL,
  variacao_id UUID,
  produto_nome VARCHAR(150) NOT NULL,
  variacao_nome VARCHAR(100),
  quantidade NUMERIC(10,3) NOT NULL DEFAULT 1,
  valor_unitario NUMERIC(12,2) NOT NULL,
  valor_adicionais NUMERIC(12,2) NOT NULL DEFAULT 0,
  valor_total NUMERIC(12,2) NOT NULL,
  observacoes TEXT,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_carrinho_itens_carrinho
    FOREIGN KEY (carrinho_id)
    REFERENCES carrinhos(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_carrinho_itens_produto
    FOREIGN KEY (produto_id)
    REFERENCES produtos(id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_carrinho_itens_variacao
    FOREIGN KEY (variacao_id)
    REFERENCES produto_variacoes(id)
    ON DELETE SET NULL,

  CONSTRAINT ck_carrinho_itens_quantidade
    CHECK (quantidade > 0),

  CONSTRAINT ck_carrinho_itens_valores
    CHECK (
      valor_unitario >= 0
      AND valor_adicionais >= 0
      AND valor_total >= 0
    )
);

CREATE INDEX idx_carrinho_itens_carrinho
  ON carrinho_itens (carrinho_id);

CREATE TABLE carrinho_item_adicionais (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  carrinho_item_id UUID NOT NULL,
  adicional_id UUID,
  adicional_nome VARCHAR(100) NOT NULL,
  quantidade INTEGER NOT NULL DEFAULT 1,
  valor_unitario NUMERIC(12,2) NOT NULL,
  valor_total NUMERIC(12,2) NOT NULL,

  CONSTRAINT fk_carrinho_item_adicionais_item
    FOREIGN KEY (carrinho_item_id)
    REFERENCES carrinho_itens(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_carrinho_item_adicionais_adicional
    FOREIGN KEY (adicional_id)
    REFERENCES produto_adicionais(id)
    ON DELETE SET NULL,

  CONSTRAINT ck_carrinho_item_adicionais_quantidade
    CHECK (quantidade > 0),

  CONSTRAINT ck_carrinho_item_adicionais_valores
    CHECK (
      valor_unitario >= 0
      AND valor_total >= 0
    )
);

CREATE TABLE pedidos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL,
  cliente_id UUID NOT NULL,
  conversa_id UUID,
  carrinho_id UUID,
  endereco_id UUID,
  atendente_id UUID,
  numero BIGSERIAL NOT NULL,
  status status_pedido NOT NULL DEFAULT 'RASCUNHO',
  tipo_atendimento tipo_atendimento NOT NULL DEFAULT 'ENTREGA',
  cliente_nome VARCHAR(120) NOT NULL,
  cliente_telefone VARCHAR(20) NOT NULL,
  endereco_texto TEXT,
  subtotal NUMERIC(12,2) NOT NULL DEFAULT 0,
  desconto NUMERIC(12,2) NOT NULL DEFAULT 0,
  acrescimo NUMERIC(12,2) NOT NULL DEFAULT 0,
  taxa_entrega NUMERIC(12,2) NOT NULL DEFAULT 0,
  valor_total NUMERIC(12,2) NOT NULL DEFAULT 0,
  troco_para NUMERIC(12,2),
  observacoes TEXT,
  confirmado_em TIMESTAMPTZ,
  preparo_iniciado_em TIMESTAMPTZ,
  pronto_em TIMESTAMPTZ,
  saiu_entrega_em TIMESTAMPTZ,
  entregue_em TIMESTAMPTZ,
  cancelado_em TIMESTAMPTZ,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_pedidos_empresa
    FOREIGN KEY (empresa_id)
    REFERENCES empresas(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_pedidos_cliente
    FOREIGN KEY (cliente_id)
    REFERENCES clientes(id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_pedidos_conversa
    FOREIGN KEY (conversa_id)
    REFERENCES conversas(id)
    ON DELETE SET NULL,

  CONSTRAINT fk_pedidos_carrinho
    FOREIGN KEY (carrinho_id)
    REFERENCES carrinhos(id)
    ON DELETE SET NULL,

  CONSTRAINT fk_pedidos_endereco
    FOREIGN KEY (endereco_id)
    REFERENCES enderecos(id)
    ON DELETE SET NULL,

  CONSTRAINT fk_pedidos_atendente
    FOREIGN KEY (atendente_id)
    REFERENCES usuarios(id)
    ON DELETE SET NULL,

  CONSTRAINT uq_pedidos_empresa_numero
    UNIQUE (empresa_id, numero),

  CONSTRAINT ck_pedidos_valores
    CHECK (
      subtotal >= 0
      AND desconto >= 0
      AND acrescimo >= 0
      AND taxa_entrega >= 0
      AND valor_total >= 0
      AND (troco_para IS NULL OR troco_para >= 0)
    )
);

CREATE INDEX idx_pedidos_empresa_status
  ON pedidos (empresa_id, status);

CREATE INDEX idx_pedidos_empresa_criado
  ON pedidos (empresa_id, criado_em DESC);

CREATE INDEX idx_pedidos_cliente
  ON pedidos (cliente_id);

CREATE TABLE pedido_itens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pedido_id UUID NOT NULL,
  produto_id UUID,
  variacao_id UUID,
  produto_nome VARCHAR(150) NOT NULL,
  variacao_nome VARCHAR(100),
  quantidade NUMERIC(10,3) NOT NULL DEFAULT 1,
  valor_unitario NUMERIC(12,2) NOT NULL,
  valor_adicionais NUMERIC(12,2) NOT NULL DEFAULT 0,
  valor_total NUMERIC(12,2) NOT NULL,
  observacoes TEXT,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_pedido_itens_pedido
    FOREIGN KEY (pedido_id)
    REFERENCES pedidos(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_pedido_itens_produto
    FOREIGN KEY (produto_id)
    REFERENCES produtos(id)
    ON DELETE SET NULL,

  CONSTRAINT fk_pedido_itens_variacao
    FOREIGN KEY (variacao_id)
    REFERENCES produto_variacoes(id)
    ON DELETE SET NULL,

  CONSTRAINT ck_pedido_itens_quantidade
    CHECK (quantidade > 0),

  CONSTRAINT ck_pedido_itens_valores
    CHECK (
      valor_unitario >= 0
      AND valor_adicionais >= 0
      AND valor_total >= 0
    )
);

CREATE INDEX idx_pedido_itens_pedido
  ON pedido_itens (pedido_id);

CREATE TABLE pedido_item_adicionais (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pedido_item_id UUID NOT NULL,
  adicional_id UUID,
  adicional_nome VARCHAR(100) NOT NULL,
  quantidade INTEGER NOT NULL DEFAULT 1,
  valor_unitario NUMERIC(12,2) NOT NULL,
  valor_total NUMERIC(12,2) NOT NULL,

  CONSTRAINT fk_pedido_item_adicionais_item
    FOREIGN KEY (pedido_item_id)
    REFERENCES pedido_itens(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_pedido_item_adicionais_adicional
    FOREIGN KEY (adicional_id)
    REFERENCES produto_adicionais(id)
    ON DELETE SET NULL,

  CONSTRAINT ck_pedido_item_adicionais_quantidade
    CHECK (quantidade > 0),

  CONSTRAINT ck_pedido_item_adicionais_valores
    CHECK (
      valor_unitario >= 0
      AND valor_total >= 0
    )
);

CREATE TABLE pagamentos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pedido_id UUID NOT NULL,
  forma forma_pagamento NOT NULL,
  status status_pagamento NOT NULL DEFAULT 'PENDENTE',
  valor NUMERIC(12,2) NOT NULL,
  transacao_id VARCHAR(150),
  dados JSONB,
  pago_em TIMESTAMPTZ,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_pagamentos_pedido
    FOREIGN KEY (pedido_id)
    REFERENCES pedidos(id)
    ON DELETE CASCADE,

  CONSTRAINT ck_pagamentos_valor
    CHECK (valor > 0)
);

CREATE INDEX idx_pagamentos_pedido
  ON pagamentos (pedido_id);

CREATE INDEX idx_pagamentos_status
  ON pagamentos (status);

CREATE TABLE entregas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pedido_id UUID NOT NULL,
  entregador_id UUID,
  status status_entrega NOT NULL DEFAULT 'AGUARDANDO',
  nome_entregador VARCHAR(120),
  telefone_entregador VARCHAR(20),
  endereco_saida TEXT,
  endereco_destino TEXT NOT NULL,
  distancia_km NUMERIC(10,3),
  previsao_entrega_em TIMESTAMPTZ,
  saiu_em TIMESTAMPTZ,
  entregue_em TIMESTAMPTZ,
  observacoes TEXT,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_entregas_pedido
    FOREIGN KEY (pedido_id)
    REFERENCES pedidos(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_entregas_entregador
    FOREIGN KEY (entregador_id)
    REFERENCES usuarios(id)
    ON DELETE SET NULL,

  CONSTRAINT uq_entregas_pedido
    UNIQUE (pedido_id),

  CONSTRAINT ck_entregas_distancia
    CHECK (
      distancia_km IS NULL
      OR distancia_km >= 0
    )
);

CREATE INDEX idx_entregas_status
  ON entregas (status);

CREATE TABLE pedido_historicos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pedido_id UUID NOT NULL,
  usuario_id UUID,
  status_anterior status_pedido,
  status_novo status_pedido NOT NULL,
  observacao TEXT,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_pedido_historicos_pedido
    FOREIGN KEY (pedido_id)
    REFERENCES pedidos(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_pedido_historicos_usuario
    FOREIGN KEY (usuario_id)
    REFERENCES usuarios(id)
    ON DELETE SET NULL
);

CREATE INDEX idx_pedido_historicos_pedido
  ON pedido_historicos (pedido_id, criado_em);

CREATE OR REPLACE FUNCTION atualizar_data_modificacao()
RETURNS TRIGGER AS $$
BEGIN
  NEW.atualizado_em = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_conversas_atualizado_em
BEFORE UPDATE ON conversas
FOR EACH ROW
EXECUTE FUNCTION atualizar_data_modificacao();

CREATE TRIGGER trg_carrinhos_atualizado_em
BEFORE UPDATE ON carrinhos
FOR EACH ROW
EXECUTE FUNCTION atualizar_data_modificacao();

CREATE TRIGGER trg_pedidos_atualizado_em
BEFORE UPDATE ON pedidos
FOR EACH ROW
EXECUTE FUNCTION atualizar_data_modificacao();

CREATE TRIGGER trg_pagamentos_atualizado_em
BEFORE UPDATE ON pagamentos
FOR EACH ROW
EXECUTE FUNCTION atualizar_data_modificacao();

CREATE TRIGGER trg_entregas_atualizado_em
BEFORE UPDATE ON entregas
FOR EACH ROW
EXECUTE FUNCTION atualizar_data_modificacao();

COMMIT;