
-- ============================================================================
-- SENSOR DELIVERY
-- Banco de dados completo - PostgreSQL
-- Versão consolidada: 2026-07
--
-- Observações:
-- 1) Este script foi pensado para Delphi FMX, Delphi VCL, API Node.js/Express
--    e integração com WhatsApp.
-- 2) O modelo é multiempresa: as tabelas operacionais possuem empresa_id.
-- 3) Execute em um banco vazio ou revise os DROP/ALTER conforme seu ambiente.
-- ============================================================================

BEGIN;

-- ============================================================================
-- EXTENSÕES
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================================
-- FUNÇÕES GERAIS
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_set_atualizado_em()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.atualizado_em := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

CREATE SEQUENCE IF NOT EXISTS seq_numero_pedido START 1;

CREATE OR REPLACE FUNCTION fn_gerar_numero_pedido()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_seq BIGINT;
BEGIN
    v_seq := nextval('seq_numero_pedido');

    RETURN TO_CHAR(CURRENT_DATE, 'YYYYMMDD')
           || '-'
           || LPAD(v_seq::TEXT, 8, '0');
END;
$$;

-- ============================================================================
-- 1. EMPRESAS, USUÁRIOS, PERFIS E PERMISSÕES
-- ============================================================================

CREATE TABLE IF NOT EXISTS empresas (
    id                  BIGSERIAL PRIMARY KEY,
    uuid                UUID NOT NULL DEFAULT gen_random_uuid(),
    razao_social        VARCHAR(180) NOT NULL,
    nome_fantasia       VARCHAR(180) NOT NULL,
    cnpj                VARCHAR(18),
    inscricao_estadual  VARCHAR(30),
    telefone            VARCHAR(30),
    whatsapp            VARCHAR(30),
    email               VARCHAR(180),
    cep                 VARCHAR(10),
    logradouro          VARCHAR(180),
    numero              VARCHAR(20),
    complemento         VARCHAR(100),
    bairro              VARCHAR(100),
    cidade              VARCHAR(100),
    uf                  CHAR(2),
    latitude            NUMERIC(10, 7),
    longitude           NUMERIC(10, 7),
    logo_url            TEXT,
    cor_primaria        VARCHAR(20) DEFAULT '#6C5CE7',
    cor_secundaria      VARCHAR(20) DEFAULT '#F1EFFE',
    ativo               BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_empresas_uuid UNIQUE (uuid),
    CONSTRAINT uq_empresas_cnpj UNIQUE (cnpj)
);

CREATE TABLE IF NOT EXISTS perfis (
    id              BIGSERIAL PRIMARY KEY,
    empresa_id      BIGINT NOT NULL,
    nome            VARCHAR(80) NOT NULL,
    descricao       VARCHAR(250),
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_perfis_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT uq_perfis_empresa_nome UNIQUE (empresa_id, nome)
);

CREATE TABLE IF NOT EXISTS permissoes (
    id          BIGSERIAL PRIMARY KEY,
    chave       VARCHAR(120) NOT NULL,
    descricao   VARCHAR(250) NOT NULL,
    modulo      VARCHAR(80) NOT NULL,
    CONSTRAINT uq_permissoes_chave UNIQUE (chave)
);

CREATE TABLE IF NOT EXISTS perfil_permissoes (
    perfil_id      BIGINT NOT NULL,
    permissao_id   BIGINT NOT NULL,
    criado_em      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (perfil_id, permissao_id),
    CONSTRAINT fk_perfil_permissoes_perfil
        FOREIGN KEY (perfil_id) REFERENCES perfis(id) ON DELETE CASCADE,
    CONSTRAINT fk_perfil_permissoes_permissao
        FOREIGN KEY (permissao_id) REFERENCES permissoes(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS usuarios (
    id              BIGSERIAL PRIMARY KEY,
    empresa_id      BIGINT NOT NULL,
    perfil_id       BIGINT,
    nome            VARCHAR(150) NOT NULL,
    email           VARCHAR(180) NOT NULL,
    senha_hash      TEXT NOT NULL,
    telefone        VARCHAR(30),
    administrador   BOOLEAN NOT NULL DEFAULT FALSE,
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    ultimo_login_em TIMESTAMP,
    criado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuarios_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT fk_usuarios_perfil
        FOREIGN KEY (perfil_id) REFERENCES perfis(id) ON DELETE SET NULL,
    CONSTRAINT uq_usuarios_empresa_email UNIQUE (empresa_id, email)
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
    id              BIGSERIAL PRIMARY KEY,
    usuario_id      BIGINT NOT NULL,
    token_hash      TEXT NOT NULL,
    expira_em       TIMESTAMP NOT NULL,
    revogado_em     TIMESTAMP,
    criado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_refresh_tokens_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT uq_refresh_tokens_hash UNIQUE (token_hash)
);

CREATE TABLE IF NOT EXISTS configuracoes (
    id              BIGSERIAL PRIMARY KEY,
    empresa_id      BIGINT NOT NULL,
    chave           VARCHAR(120) NOT NULL,
    valor           TEXT,
    tipo            VARCHAR(30) NOT NULL DEFAULT 'STRING',
    descricao       VARCHAR(250),
    criado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_configuracoes_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT uq_configuracoes_empresa_chave UNIQUE (empresa_id, chave),
    CONSTRAINT ck_configuracoes_tipo
        CHECK (tipo IN ('STRING', 'INTEGER', 'DECIMAL', 'BOOLEAN', 'JSON'))
);

-- ============================================================================
-- 2. FORMAS DE PAGAMENTO, BAIRROS E TAXAS DE ENTREGA
-- ============================================================================

CREATE TABLE IF NOT EXISTS formas_pagamento (
    id                      BIGSERIAL PRIMARY KEY,
    empresa_id              BIGINT NOT NULL,
    descricao               VARCHAR(80) NOT NULL,
    tipo                    VARCHAR(30) NOT NULL,
    permite_troco           BOOLEAN NOT NULL DEFAULT FALSE,
    pagamento_na_entrega    BOOLEAN NOT NULL DEFAULT TRUE,
    ordem                   INTEGER NOT NULL DEFAULT 0,
    ativo                   BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_formas_pagamento_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT uq_formas_pagamento_empresa_descricao
        UNIQUE (empresa_id, descricao),
    CONSTRAINT ck_formas_pagamento_tipo
        CHECK (tipo IN ('DINHEIRO', 'PIX', 'CREDITO', 'DEBITO', 'ONLINE', 'OUTRO'))
);

CREATE TABLE IF NOT EXISTS bairros (
    id              BIGSERIAL PRIMARY KEY,
    empresa_id      BIGINT NOT NULL,
    nome            VARCHAR(120) NOT NULL,
    cidade          VARCHAR(120),
    uf              CHAR(2),
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_bairros_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT uq_bairros_empresa_nome UNIQUE (empresa_id, nome)
);

CREATE TABLE IF NOT EXISTS taxas_entrega (
    id                  BIGSERIAL PRIMARY KEY,
    empresa_id          BIGINT NOT NULL,
    bairro_id           BIGINT,
    descricao           VARCHAR(120) NOT NULL,
    valor               NUMERIC(12, 2) NOT NULL DEFAULT 0,
    pedido_minimo       NUMERIC(12, 2) NOT NULL DEFAULT 0,
    prazo_minimo_min    INTEGER,
    prazo_maximo_min    INTEGER,
    ativo               BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_taxas_entrega_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT fk_taxas_entrega_bairro
        FOREIGN KEY (bairro_id) REFERENCES bairros(id) ON DELETE SET NULL,
    CONSTRAINT ck_taxas_entrega_valor CHECK (valor >= 0),
    CONSTRAINT ck_taxas_entrega_pedido_minimo CHECK (pedido_minimo >= 0)
);

-- ============================================================================
-- 3. CARDÁPIO
-- ============================================================================

CREATE TABLE IF NOT EXISTS categorias (
    id              BIGSERIAL PRIMARY KEY,
    empresa_id      BIGINT NOT NULL,
    nome            VARCHAR(120) NOT NULL,
    descricao       VARCHAR(250),
    imagem_url      TEXT,
    ordem           INTEGER NOT NULL DEFAULT 0,
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_categorias_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT uq_categorias_empresa_nome UNIQUE (empresa_id, nome)
);

CREATE TABLE IF NOT EXISTS produtos (
    id                      BIGSERIAL PRIMARY KEY,
    empresa_id              BIGINT NOT NULL,
    categoria_id            BIGINT,
    codigo                  VARCHAR(40),
    descricao               VARCHAR(180) NOT NULL,
    descricao_detalhada     TEXT,
    tipo                    VARCHAR(30) NOT NULL DEFAULT 'NORMAL',
    preco                   NUMERIC(12, 2) NOT NULL DEFAULT 0,
    destaque                BOOLEAN NOT NULL DEFAULT FALSE,
    disponivel              BOOLEAN NOT NULL DEFAULT TRUE,
    permite_observacao      BOOLEAN NOT NULL DEFAULT TRUE,
    controla_estoque        BOOLEAN NOT NULL DEFAULT FALSE,
    estoque_atual           NUMERIC(14, 3) NOT NULL DEFAULT 0,
    ordem                   INTEGER NOT NULL DEFAULT 0,
    ativo                   BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_produtos_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT fk_produtos_categoria
        FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE SET NULL,
    CONSTRAINT uq_produtos_empresa_codigo UNIQUE (empresa_id, codigo),
    CONSTRAINT ck_produtos_tipo
        CHECK (tipo IN ('NORMAL', 'PIZZA', 'BEBIDA', 'COMBO', 'ADICIONAL')),
    CONSTRAINT ck_produtos_preco CHECK (preco >= 0)
);

CREATE TABLE IF NOT EXISTS produto_imagens (
    id              BIGSERIAL PRIMARY KEY,
    produto_id      BIGINT NOT NULL,
    url             TEXT NOT NULL,
    principal       BOOLEAN NOT NULL DEFAULT FALSE,
    ordem           INTEGER NOT NULL DEFAULT 0,
    criado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_produto_imagens_produto
        FOREIGN KEY (produto_id) REFERENCES produtos(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS pizza_tamanhos (
    id                  BIGSERIAL PRIMARY KEY,
    empresa_id          BIGINT NOT NULL,
    descricao           VARCHAR(80) NOT NULL,
    sigla               VARCHAR(10),
    quantidade_fatias   INTEGER,
    limite_sabores      INTEGER NOT NULL DEFAULT 1,
    ordem               INTEGER NOT NULL DEFAULT 0,
    ativo               BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pizza_tamanhos_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT uq_pizza_tamanhos_empresa_descricao
        UNIQUE (empresa_id, descricao),
    CONSTRAINT ck_pizza_tamanhos_limite_sabores CHECK (limite_sabores >= 1)
);

CREATE TABLE IF NOT EXISTS pizza_tamanho_precos (
    id              BIGSERIAL PRIMARY KEY,
    empresa_id      BIGINT NOT NULL,
    produto_id      BIGINT NOT NULL,
    tamanho_id      BIGINT NOT NULL,
    valor_base      NUMERIC(12, 2) NOT NULL DEFAULT 0,
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pizza_tamanho_precos_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT fk_pizza_tamanho_precos_produto
        FOREIGN KEY (produto_id) REFERENCES produtos(id) ON DELETE CASCADE,
    CONSTRAINT fk_pizza_tamanho_precos_tamanho
        FOREIGN KEY (tamanho_id) REFERENCES pizza_tamanhos(id) ON DELETE CASCADE,
    CONSTRAINT uq_pizza_tamanho_precos UNIQUE (produto_id, tamanho_id),
    CONSTRAINT ck_pizza_tamanho_precos_valor CHECK (valor_base >= 0)
);

CREATE TABLE IF NOT EXISTS pizza_sabores (
    id              BIGSERIAL PRIMARY KEY,
    empresa_id      BIGINT NOT NULL,
    produto_id      BIGINT,
    descricao       VARCHAR(150) NOT NULL,
    descricao_curta VARCHAR(80),
    imagem_url      TEXT,
    ordem           INTEGER NOT NULL DEFAULT 0,
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pizza_sabores_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT fk_pizza_sabores_produto
        FOREIGN KEY (produto_id) REFERENCES produtos(id) ON DELETE SET NULL,
    CONSTRAINT uq_pizza_sabores_empresa_descricao
        UNIQUE (empresa_id, descricao)
);

CREATE TABLE IF NOT EXISTS pizza_sabor_precos (
    id              BIGSERIAL PRIMARY KEY,
    empresa_id      BIGINT NOT NULL,
    sabor_id        BIGINT NOT NULL,
    tamanho_id      BIGINT NOT NULL,
    valor           NUMERIC(12, 2) NOT NULL DEFAULT 0,
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pizza_sabor_precos_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT fk_pizza_sabor_precos_sabor
        FOREIGN KEY (sabor_id) REFERENCES pizza_sabores(id) ON DELETE CASCADE,
    CONSTRAINT fk_pizza_sabor_precos_tamanho
        FOREIGN KEY (tamanho_id) REFERENCES pizza_tamanhos(id) ON DELETE CASCADE,
    CONSTRAINT uq_pizza_sabor_precos UNIQUE (sabor_id, tamanho_id),
    CONSTRAINT ck_pizza_sabor_precos_valor CHECK (valor >= 0)
);

CREATE TABLE IF NOT EXISTS pizza_bordas (
    id              BIGSERIAL PRIMARY KEY,
    empresa_id      BIGINT NOT NULL,
    descricao       VARCHAR(120) NOT NULL,
    ordem           INTEGER NOT NULL DEFAULT 0,
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pizza_bordas_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT uq_pizza_bordas_empresa_descricao
        UNIQUE (empresa_id, descricao)
);

CREATE TABLE IF NOT EXISTS pizza_borda_precos (
    id              BIGSERIAL PRIMARY KEY,
    empresa_id      BIGINT NOT NULL,
    borda_id        BIGINT NOT NULL,
    tamanho_id      BIGINT NOT NULL,
    valor           NUMERIC(12, 2) NOT NULL DEFAULT 0,
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pizza_borda_precos_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT fk_pizza_borda_precos_borda
        FOREIGN KEY (borda_id) REFERENCES pizza_bordas(id) ON DELETE CASCADE,
    CONSTRAINT fk_pizza_borda_precos_tamanho
        FOREIGN KEY (tamanho_id) REFERENCES pizza_tamanhos(id) ON DELETE CASCADE,
    CONSTRAINT uq_pizza_borda_precos UNIQUE (borda_id, tamanho_id),
    CONSTRAINT ck_pizza_borda_precos_valor CHECK (valor >= 0)
);

CREATE TABLE IF NOT EXISTS adicionais (
    id              BIGSERIAL PRIMARY KEY,
    empresa_id      BIGINT NOT NULL,
    descricao       VARCHAR(120) NOT NULL,
    categoria       VARCHAR(80),
    ordem           INTEGER NOT NULL DEFAULT 0,
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_adicionais_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT uq_adicionais_empresa_descricao
        UNIQUE (empresa_id, descricao)
);

CREATE TABLE IF NOT EXISTS adicional_precos (
    id              BIGSERIAL PRIMARY KEY,
    empresa_id      BIGINT NOT NULL,
    adicional_id    BIGINT NOT NULL,
    produto_id      BIGINT,
    tamanho_id      BIGINT,
    valor           NUMERIC(12, 2) NOT NULL DEFAULT 0,
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_adicional_precos_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT fk_adicional_precos_adicional
        FOREIGN KEY (adicional_id) REFERENCES adicionais(id) ON DELETE CASCADE,
    CONSTRAINT fk_adicional_precos_produto
        FOREIGN KEY (produto_id) REFERENCES produtos(id) ON DELETE CASCADE,
    CONSTRAINT fk_adicional_precos_tamanho
        FOREIGN KEY (tamanho_id) REFERENCES pizza_tamanhos(id) ON DELETE CASCADE,
    CONSTRAINT ck_adicional_precos_valor CHECK (valor >= 0)
);

-- ============================================================================
-- 4. CLIENTES
-- ============================================================================

CREATE TABLE IF NOT EXISTS clientes (
    id                  BIGSERIAL PRIMARY KEY,
    empresa_id          BIGINT NOT NULL,
    nome                VARCHAR(160) NOT NULL,
    telefone            VARCHAR(30) NOT NULL,
    whatsapp            VARCHAR(30),
    email               VARCHAR(180),
    cpf                 VARCHAR(14),
    data_nascimento     DATE,
    observacao          TEXT,
    bloqueado           BOOLEAN NOT NULL DEFAULT FALSE,
    ativo               BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_clientes_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT uq_clientes_empresa_telefone UNIQUE (empresa_id, telefone)
);

CREATE TABLE IF NOT EXISTS cliente_enderecos (
    id              BIGSERIAL PRIMARY KEY,
    cliente_id      BIGINT NOT NULL,
    apelido         VARCHAR(60),
    cep             VARCHAR(10),
    logradouro      VARCHAR(180) NOT NULL,
    numero          VARCHAR(20) NOT NULL,
    complemento     VARCHAR(100),
    bairro          VARCHAR(100) NOT NULL,
    cidade          VARCHAR(100),
    uf              CHAR(2),
    referencia      VARCHAR(250),
    latitude        NUMERIC(10, 7),
    longitude       NUMERIC(10, 7),
    principal       BOOLEAN NOT NULL DEFAULT FALSE,
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cliente_enderecos_cliente
        FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE
);

-- ============================================================================
-- 5. CUPONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS cupons (
    id                  BIGSERIAL PRIMARY KEY,
    empresa_id          BIGINT NOT NULL,
    codigo              VARCHAR(50) NOT NULL,
    descricao           VARCHAR(180),
    tipo_desconto       VARCHAR(20) NOT NULL,
    valor_desconto      NUMERIC(12, 2) NOT NULL DEFAULT 0,
    valor_minimo        NUMERIC(12, 2) NOT NULL DEFAULT 0,
    limite_uso_total    INTEGER,
    limite_uso_cliente  INTEGER,
    inicio_em           TIMESTAMP,
    fim_em              TIMESTAMP,
    somente_primeiro    BOOLEAN NOT NULL DEFAULT FALSE,
    ativo               BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cupons_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT uq_cupons_empresa_codigo UNIQUE (empresa_id, codigo),
    CONSTRAINT ck_cupons_tipo
        CHECK (tipo_desconto IN ('VALOR', 'PERCENTUAL', 'FRETE')),
    CONSTRAINT ck_cupons_valor CHECK (valor_desconto >= 0)
);

-- ============================================================================
-- 6. PEDIDOS
-- ============================================================================

CREATE TABLE IF NOT EXISTS pedidos (
    id                      BIGSERIAL PRIMARY KEY,
    empresa_id              BIGINT NOT NULL,
    cliente_id              BIGINT,
    endereco_id             BIGINT,
    cupom_id                BIGINT,

    numero_pedido           VARCHAR(30) NOT NULL DEFAULT fn_gerar_numero_pedido(),

    origem                  VARCHAR(30) NOT NULL DEFAULT 'APP',
    status                  VARCHAR(30) NOT NULL DEFAULT 'PENDENTE',
    tipo_recebimento        VARCHAR(20) NOT NULL,

    cliente_nome            VARCHAR(160) NOT NULL,
    cliente_telefone        VARCHAR(30) NOT NULL,

    cep                     VARCHAR(10),
    logradouro              VARCHAR(180),
    numero                  VARCHAR(20),
    complemento             VARCHAR(100),
    bairro                  VARCHAR(100),
    cidade                  VARCHAR(100),
    uf                      CHAR(2),
    referencia              VARCHAR(250),

    observacao              TEXT,

    subtotal                NUMERIC(12, 2) NOT NULL DEFAULT 0,
    desconto                NUMERIC(12, 2) NOT NULL DEFAULT 0,
    taxa_entrega            NUMERIC(12, 2) NOT NULL DEFAULT 0,
    acrescimo               NUMERIC(12, 2) NOT NULL DEFAULT 0,
    total                   NUMERIC(12, 2) NOT NULL DEFAULT 0,

    previsao_minutos        INTEGER,
    confirmado_em           TIMESTAMP,
    preparado_em            TIMESTAMP,
    saiu_entrega_em         TIMESTAMP,
    entregue_em             TIMESTAMP,
    cancelado_em            TIMESTAMP,

    motivo_cancelamento     TEXT,

    criado_em               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_pedidos_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT fk_pedidos_cliente
        FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE SET NULL,
    CONSTRAINT fk_pedidos_endereco
        FOREIGN KEY (endereco_id) REFERENCES cliente_enderecos(id) ON DELETE SET NULL,
    CONSTRAINT fk_pedidos_cupom
        FOREIGN KEY (cupom_id) REFERENCES cupons(id) ON DELETE SET NULL,
    CONSTRAINT uq_pedidos_empresa_numero UNIQUE (empresa_id, numero_pedido),
    CONSTRAINT ck_pedidos_origem
        CHECK (origem IN ('APP', 'BALCAO', 'WHATSAPP', 'TELEFONE', 'SITE', 'ADMIN')),
    CONSTRAINT ck_pedidos_status
        CHECK (status IN (
            'PENDENTE',
            'CONFIRMADO',
            'EM_PREPARO',
            'PRONTO',
            'SAIU_ENTREGA',
            'ENTREGUE',
            'CANCELADO'
        )),
    CONSTRAINT ck_pedidos_tipo_recebimento
        CHECK (tipo_recebimento IN ('ENTREGA', 'RETIRADA')),
    CONSTRAINT ck_pedidos_valores
        CHECK (
            subtotal >= 0
            AND desconto >= 0
            AND taxa_entrega >= 0
            AND acrescimo >= 0
            AND total >= 0
        )
);

CREATE TABLE IF NOT EXISTS pedido_itens (
    id                      BIGSERIAL PRIMARY KEY,
    pedido_id               BIGINT NOT NULL,
    produto_id              BIGINT,
    identificador           VARCHAR(100),

    produto_descricao       VARCHAR(180) NOT NULL,
    tipo_produto            VARCHAR(30) NOT NULL DEFAULT 'NORMAL',

    tamanho_id              BIGINT,
    tamanho_descricao       VARCHAR(80),
    valor_base              NUMERIC(12, 2) NOT NULL DEFAULT 0,

    borda_id                BIGINT,
    borda_descricao         VARCHAR(120),
    valor_borda             NUMERIC(12, 2) NOT NULL DEFAULT 0,

    quantidade              INTEGER NOT NULL DEFAULT 1,
    observacao              TEXT,

    valor_unitario          NUMERIC(12, 2) NOT NULL DEFAULT 0,
    valor_total             NUMERIC(12, 2) NOT NULL DEFAULT 0,

    criado_em               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_pedido_itens_pedido
        FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
    CONSTRAINT fk_pedido_itens_produto
        FOREIGN KEY (produto_id) REFERENCES produtos(id) ON DELETE SET NULL,
    CONSTRAINT fk_pedido_itens_tamanho
        FOREIGN KEY (tamanho_id) REFERENCES pizza_tamanhos(id) ON DELETE SET NULL,
    CONSTRAINT fk_pedido_itens_borda
        FOREIGN KEY (borda_id) REFERENCES pizza_bordas(id) ON DELETE SET NULL,
    CONSTRAINT ck_pedido_itens_quantidade CHECK (quantidade > 0),
    CONSTRAINT ck_pedido_itens_valores
        CHECK (valor_base >= 0 AND valor_borda >= 0 AND valor_unitario >= 0 AND valor_total >= 0)
);

CREATE TABLE IF NOT EXISTS pedido_item_sabores (
    id                  BIGSERIAL PRIMARY KEY,
    pedido_item_id      BIGINT NOT NULL,
    sabor_id            BIGINT,
    descricao           VARCHAR(150) NOT NULL,
    valor               NUMERIC(12, 2) NOT NULL DEFAULT 0,
    criado_em           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pedido_item_sabores_item
        FOREIGN KEY (pedido_item_id) REFERENCES pedido_itens(id) ON DELETE CASCADE,
    CONSTRAINT fk_pedido_item_sabores_sabor
        FOREIGN KEY (sabor_id) REFERENCES pizza_sabores(id) ON DELETE SET NULL,
    CONSTRAINT ck_pedido_item_sabores_valor CHECK (valor >= 0)
);

CREATE TABLE IF NOT EXISTS pedido_item_adicionais (
    id                  BIGSERIAL PRIMARY KEY,
    pedido_item_id      BIGINT NOT NULL,
    adicional_id        BIGINT,
    descricao           VARCHAR(150) NOT NULL,
    quantidade          INTEGER NOT NULL DEFAULT 1,
    valor_unitario      NUMERIC(12, 2) NOT NULL DEFAULT 0,
    valor_total         NUMERIC(12, 2) NOT NULL DEFAULT 0,
    criado_em           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pedido_item_adicionais_item
        FOREIGN KEY (pedido_item_id) REFERENCES pedido_itens(id) ON DELETE CASCADE,
    CONSTRAINT fk_pedido_item_adicionais_adicional
        FOREIGN KEY (adicional_id) REFERENCES adicionais(id) ON DELETE SET NULL,
    CONSTRAINT ck_pedido_item_adicionais_quantidade CHECK (quantidade > 0)
);

CREATE TABLE IF NOT EXISTS pedido_pagamentos (
    id                  BIGSERIAL PRIMARY KEY,
    pedido_id           BIGINT NOT NULL,
    forma_pagamento_id  BIGINT,
    forma_descricao     VARCHAR(80) NOT NULL,
    valor               NUMERIC(12, 2) NOT NULL,
    troco_para          NUMERIC(12, 2) NOT NULL DEFAULT 0,
    troco               NUMERIC(12, 2) NOT NULL DEFAULT 0,
    status              VARCHAR(30) NOT NULL DEFAULT 'PENDENTE',
    transacao_id        VARCHAR(180),
    pago_em             TIMESTAMP,
    criado_em           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pedido_pagamentos_pedido
        FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
    CONSTRAINT fk_pedido_pagamentos_forma
        FOREIGN KEY (forma_pagamento_id) REFERENCES formas_pagamento(id) ON DELETE SET NULL,
    CONSTRAINT ck_pedido_pagamentos_status
        CHECK (status IN ('PENDENTE', 'APROVADO', 'RECUSADO', 'CANCELADO', 'ESTORNADO')),
    CONSTRAINT ck_pedido_pagamentos_valores
        CHECK (valor >= 0 AND troco_para >= 0 AND troco >= 0)
);

CREATE TABLE IF NOT EXISTS pedido_status_historico (
    id              BIGSERIAL PRIMARY KEY,
    pedido_id       BIGINT NOT NULL,
    usuario_id      BIGINT,
    status_anterior VARCHAR(30),
    status_novo     VARCHAR(30) NOT NULL,
    observacao      TEXT,
    criado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pedido_status_historico_pedido
        FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
    CONSTRAINT fk_pedido_status_historico_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
);

-- ============================================================================
-- 7. CAIXA E MOVIMENTAÇÃO FINANCEIRA
-- ============================================================================

CREATE TABLE IF NOT EXISTS caixas (
    id                  BIGSERIAL PRIMARY KEY,
    empresa_id          BIGINT NOT NULL,
    usuario_abertura_id BIGINT,
    usuario_fechamento_id BIGINT,
    aberto_em           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fechado_em          TIMESTAMP,
    valor_abertura      NUMERIC(12, 2) NOT NULL DEFAULT 0,
    valor_fechamento    NUMERIC(12, 2),
    status              VARCHAR(20) NOT NULL DEFAULT 'ABERTO',
    observacao          TEXT,
    criado_em           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_caixas_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT fk_caixas_usuario_abertura
        FOREIGN KEY (usuario_abertura_id) REFERENCES usuarios(id) ON DELETE SET NULL,
    CONSTRAINT fk_caixas_usuario_fechamento
        FOREIGN KEY (usuario_fechamento_id) REFERENCES usuarios(id) ON DELETE SET NULL,
    CONSTRAINT ck_caixas_status CHECK (status IN ('ABERTO', 'FECHADO'))
);

CREATE TABLE IF NOT EXISTS movimentos_caixa (
    id                  BIGSERIAL PRIMARY KEY,
    caixa_id            BIGINT NOT NULL,
    pedido_id           BIGINT,
    usuario_id          BIGINT,
    tipo                VARCHAR(20) NOT NULL,
    categoria           VARCHAR(60),
    descricao           VARCHAR(250) NOT NULL,
    valor               NUMERIC(12, 2) NOT NULL,
    criado_em           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_movimentos_caixa_caixa
        FOREIGN KEY (caixa_id) REFERENCES caixas(id) ON DELETE CASCADE,
    CONSTRAINT fk_movimentos_caixa_pedido
        FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE SET NULL,
    CONSTRAINT fk_movimentos_caixa_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
    CONSTRAINT ck_movimentos_caixa_tipo CHECK (tipo IN ('ENTRADA', 'SAIDA')),
    CONSTRAINT ck_movimentos_caixa_valor CHECK (valor > 0)
);

-- ============================================================================
-- 8. LOGÍSTICA
-- ============================================================================

CREATE TABLE IF NOT EXISTS entregadores (
    id              BIGSERIAL PRIMARY KEY,
    empresa_id      BIGINT NOT NULL,
    nome            VARCHAR(160) NOT NULL,
    telefone        VARCHAR(30),
    documento       VARCHAR(30),
    veiculo         VARCHAR(80),
    placa           VARCHAR(12),
    disponivel      BOOLEAN NOT NULL DEFAULT TRUE,
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_entregadores_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS entregas (
    id                  BIGSERIAL PRIMARY KEY,
    pedido_id           BIGINT NOT NULL,
    entregador_id       BIGINT,
    status              VARCHAR(30) NOT NULL DEFAULT 'AGUARDANDO',
    aceito_em           TIMESTAMP,
    saiu_em             TIMESTAMP,
    entregue_em         TIMESTAMP,
    latitude_atual      NUMERIC(10, 7),
    longitude_atual     NUMERIC(10, 7),
    observacao          TEXT,
    criado_em           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_entregas_pedido
        FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
    CONSTRAINT fk_entregas_entregador
        FOREIGN KEY (entregador_id) REFERENCES entregadores(id) ON DELETE SET NULL,
    CONSTRAINT uq_entregas_pedido UNIQUE (pedido_id),
    CONSTRAINT ck_entregas_status
        CHECK (status IN ('AGUARDANDO', 'ATRIBUIDA', 'ACEITA', 'EM_ROTA', 'ENTREGUE', 'CANCELADA'))
);

-- ============================================================================
-- 9. WHATSAPP
-- ============================================================================

CREATE TABLE IF NOT EXISTS whatsapp_conversas (
    id                      BIGSERIAL PRIMARY KEY,
    empresa_id              BIGINT NOT NULL,
    cliente_id              BIGINT,
    telefone                VARCHAR(30) NOT NULL,
    nome_contato            VARCHAR(160),
    status                  VARCHAR(30) NOT NULL DEFAULT 'ABERTA',
    ultima_mensagem_em      TIMESTAMP,
    atendente_usuario_id    BIGINT,
    criado_em               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_whatsapp_conversas_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT fk_whatsapp_conversas_cliente
        FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE SET NULL,
    CONSTRAINT fk_whatsapp_conversas_atendente
        FOREIGN KEY (atendente_usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
    CONSTRAINT ck_whatsapp_conversas_status
        CHECK (status IN ('ABERTA', 'AGUARDANDO', 'EM_ATENDIMENTO', 'FINALIZADA', 'BLOQUEADA'))
);

CREATE TABLE IF NOT EXISTS whatsapp_mensagens (
    id                  BIGSERIAL PRIMARY KEY,
    conversa_id         BIGINT NOT NULL,
    message_id          VARCHAR(180),
    direcao             VARCHAR(20) NOT NULL,
    tipo                VARCHAR(30) NOT NULL DEFAULT 'TEXTO',
    conteudo            TEXT,
    midia_url           TEXT,
    status              VARCHAR(30) NOT NULL DEFAULT 'RECEBIDA',
    enviado_em          TIMESTAMP,
    recebido_em         TIMESTAMP,
    criado_em           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_whatsapp_mensagens_conversa
        FOREIGN KEY (conversa_id) REFERENCES whatsapp_conversas(id) ON DELETE CASCADE,
    CONSTRAINT uq_whatsapp_mensagens_message_id UNIQUE (message_id),
    CONSTRAINT ck_whatsapp_mensagens_direcao
        CHECK (direcao IN ('ENTRADA', 'SAIDA')),
    CONSTRAINT ck_whatsapp_mensagens_tipo
        CHECK (tipo IN ('TEXTO', 'IMAGEM', 'AUDIO', 'VIDEO', 'DOCUMENTO', 'LOCALIZACAO', 'CONTATO')),
    CONSTRAINT ck_whatsapp_mensagens_status
        CHECK (status IN ('PENDENTE', 'ENVIADA', 'ENTREGUE', 'LIDA', 'RECEBIDA', 'ERRO'))
);

CREATE TABLE IF NOT EXISTS whatsapp_fila_envio (
    id                  BIGSERIAL PRIMARY KEY,
    empresa_id          BIGINT NOT NULL,
    conversa_id         BIGINT,
    telefone            VARCHAR(30) NOT NULL,
    tipo                VARCHAR(30) NOT NULL DEFAULT 'TEXTO',
    conteudo            TEXT,
    midia_url           TEXT,
    tentativas          INTEGER NOT NULL DEFAULT 0,
    max_tentativas      INTEGER NOT NULL DEFAULT 5,
    status              VARCHAR(30) NOT NULL DEFAULT 'PENDENTE',
    proxima_tentativa_em TIMESTAMP,
    erro_ultimo         TEXT,
    criado_em           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_whatsapp_fila_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT fk_whatsapp_fila_conversa
        FOREIGN KEY (conversa_id) REFERENCES whatsapp_conversas(id) ON DELETE CASCADE,
    CONSTRAINT ck_whatsapp_fila_status
        CHECK (status IN ('PENDENTE', 'PROCESSANDO', 'ENVIADA', 'ERRO', 'CANCELADA'))
);

CREATE TABLE IF NOT EXISTS respostas_automaticas (
    id                  BIGSERIAL PRIMARY KEY,
    empresa_id          BIGINT NOT NULL,
    nome                VARCHAR(120) NOT NULL,
    palavras_chave      TEXT,
    resposta            TEXT NOT NULL,
    prioridade          INTEGER NOT NULL DEFAULT 0,
    ativo               BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_respostas_automaticas_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE
);

-- ============================================================================
-- 10. NOTIFICAÇÕES E AUDITORIA
-- ============================================================================

CREATE TABLE IF NOT EXISTS notificacoes (
    id              BIGSERIAL PRIMARY KEY,
    empresa_id      BIGINT NOT NULL,
    usuario_id      BIGINT,
    titulo          VARCHAR(160) NOT NULL,
    mensagem        TEXT NOT NULL,
    tipo            VARCHAR(40) NOT NULL DEFAULT 'INFO',
    lida            BOOLEAN NOT NULL DEFAULT FALSE,
    link_acao       TEXT,
    criado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    lida_em         TIMESTAMP,
    CONSTRAINT fk_notificacoes_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT fk_notificacoes_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT ck_notificacoes_tipo
        CHECK (tipo IN ('INFO', 'SUCESSO', 'ALERTA', 'ERRO', 'PEDIDO'))
);

CREATE TABLE IF NOT EXISTS logs_auditoria (
    id              BIGSERIAL PRIMARY KEY,
    empresa_id      BIGINT,
    usuario_id      BIGINT,
    entidade        VARCHAR(100) NOT NULL,
    entidade_id     BIGINT,
    acao            VARCHAR(40) NOT NULL,
    dados_anteriores JSONB,
    dados_novos     JSONB,
    ip              VARCHAR(60),
    user_agent      TEXT,
    criado_em       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_logs_auditoria_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE SET NULL,
    CONSTRAINT fk_logs_auditoria_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
);

-- ============================================================================
-- ÍNDICES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_usuarios_empresa ON usuarios(empresa_id);
CREATE INDEX IF NOT EXISTS idx_produtos_empresa_categoria ON produtos(empresa_id, categoria_id);
CREATE INDEX IF NOT EXISTS idx_produtos_disponivel ON produtos(empresa_id, disponivel, ativo);
CREATE INDEX IF NOT EXISTS idx_clientes_empresa_nome ON clientes(empresa_id, nome);
CREATE INDEX IF NOT EXISTS idx_clientes_empresa_telefone ON clientes(empresa_id, telefone);
CREATE INDEX IF NOT EXISTS idx_pedidos_empresa_status ON pedidos(empresa_id, status);
CREATE INDEX IF NOT EXISTS idx_pedidos_empresa_criado_em ON pedidos(empresa_id, criado_em DESC);
CREATE INDEX IF NOT EXISTS idx_pedido_itens_pedido_id ON pedido_itens(pedido_id);
CREATE INDEX IF NOT EXISTS idx_pedido_item_sabores_item_id ON pedido_item_sabores(pedido_item_id);
CREATE INDEX IF NOT EXISTS idx_pedido_item_adicionais_item_id ON pedido_item_adicionais(pedido_item_id);
CREATE INDEX IF NOT EXISTS idx_pedido_pagamentos_pedido_id ON pedido_pagamentos(pedido_id);
CREATE INDEX IF NOT EXISTS idx_pedido_status_historico_pedido_id ON pedido_status_historico(pedido_id);
CREATE INDEX IF NOT EXISTS idx_movimentos_caixa_caixa_id ON movimentos_caixa(caixa_id);
CREATE INDEX IF NOT EXISTS idx_entregas_status ON entregas(status);
CREATE INDEX IF NOT EXISTS idx_whatsapp_conversas_empresa_telefone ON whatsapp_conversas(empresa_id, telefone);
CREATE INDEX IF NOT EXISTS idx_whatsapp_mensagens_conversa ON whatsapp_mensagens(conversa_id, criado_em);
CREATE INDEX IF NOT EXISTS idx_whatsapp_fila_status ON whatsapp_fila_envio(status, proxima_tentativa_em);
CREATE INDEX IF NOT EXISTS idx_notificacoes_usuario_lida ON notificacoes(usuario_id, lida);
CREATE INDEX IF NOT EXISTS idx_logs_auditoria_entidade ON logs_auditoria(entidade, entidade_id);

-- ============================================================================
-- TRIGGERS DE atualizado_em
-- ============================================================================

DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'empresas',
        'perfis',
        'usuarios',
        'configuracoes',
        'formas_pagamento',
        'bairros',
        'taxas_entrega',
        'categorias',
        'produtos',
        'pizza_tamanhos',
        'pizza_tamanho_precos',
        'pizza_sabores',
        'pizza_sabor_precos',
        'pizza_bordas',
        'pizza_borda_precos',
        'adicionais',
        'adicional_precos',
        'clientes',
        'cliente_enderecos',
        'cupons',
        'pedidos',
        'pedido_pagamentos',
        'caixas',
        'entregadores',
        'entregas',
        'whatsapp_conversas',
        'whatsapp_fila_envio',
        'respostas_automaticas'
    ]
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trg_%I_atualizado_em ON %I', t, t);
        EXECUTE format(
            'CREATE TRIGGER trg_%I_atualizado_em
             BEFORE UPDATE ON %I
             FOR EACH ROW
             EXECUTE FUNCTION fn_set_atualizado_em()',
            t,
            t
        );
    END LOOP;
END;
$$;

-- ============================================================================
-- TRIGGER DE HISTÓRICO DE STATUS DO PEDIDO
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_registrar_status_pedido()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO pedido_status_historico (
            pedido_id,
            status_anterior,
            status_novo,
            observacao
        )
        VALUES (
            NEW.id,
            NULL,
            NEW.status,
            'Pedido criado'
        );

        RETURN NEW;
    END IF;

    IF NEW.status IS DISTINCT FROM OLD.status THEN
        INSERT INTO pedido_status_historico (
            pedido_id,
            status_anterior,
            status_novo
        )
        VALUES (
            NEW.id,
            OLD.status,
            NEW.status
        );

        IF NEW.status = 'CONFIRMADO' AND NEW.confirmado_em IS NULL THEN
            NEW.confirmado_em := CURRENT_TIMESTAMP;
        ELSIF NEW.status = 'EM_PREPARO' AND NEW.preparado_em IS NULL THEN
            NEW.preparado_em := CURRENT_TIMESTAMP;
        ELSIF NEW.status = 'SAIU_ENTREGA' AND NEW.saiu_entrega_em IS NULL THEN
            NEW.saiu_entrega_em := CURRENT_TIMESTAMP;
        ELSIF NEW.status = 'ENTREGUE' AND NEW.entregue_em IS NULL THEN
            NEW.entregue_em := CURRENT_TIMESTAMP;
        ELSIF NEW.status = 'CANCELADO' AND NEW.cancelado_em IS NULL THEN
            NEW.cancelado_em := CURRENT_TIMESTAMP;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_pedidos_status_historico ON pedidos;

CREATE TRIGGER trg_pedidos_status_historico
BEFORE INSERT OR UPDATE OF status
ON pedidos
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_status_pedido();

-- ============================================================================
-- VIEWS
-- ============================================================================

CREATE OR REPLACE VIEW vw_pedidos_resumo AS
SELECT
    p.id,
    p.empresa_id,
    p.numero_pedido,
    p.origem,
    p.status,
    p.tipo_recebimento,
    p.cliente_nome,
    p.cliente_telefone,
    p.subtotal,
    p.desconto,
    p.taxa_entrega,
    p.acrescimo,
    p.total,
    p.criado_em,
    COUNT(pi.id) AS quantidade_itens
FROM pedidos p
LEFT JOIN pedido_itens pi ON pi.pedido_id = p.id
GROUP BY
    p.id,
    p.empresa_id,
    p.numero_pedido,
    p.origem,
    p.status,
    p.tipo_recebimento,
    p.cliente_nome,
    p.cliente_telefone,
    p.subtotal,
    p.desconto,
    p.taxa_entrega,
    p.acrescimo,
    p.total,
    p.criado_em;

CREATE OR REPLACE VIEW vw_dashboard_diario AS
SELECT
    empresa_id,
    CURRENT_DATE AS data_referencia,
    COUNT(*) FILTER (
        WHERE criado_em::DATE = CURRENT_DATE
    ) AS pedidos_hoje,
    COUNT(*) FILTER (
        WHERE criado_em::DATE = CURRENT_DATE
          AND status NOT IN ('CANCELADO')
    ) AS pedidos_validos_hoje,
    COALESCE(SUM(total) FILTER (
        WHERE criado_em::DATE = CURRENT_DATE
          AND status NOT IN ('CANCELADO')
    ), 0) AS faturamento_hoje,
    COUNT(*) FILTER (
        WHERE status IN ('PENDENTE', 'CONFIRMADO')
    ) AS aguardando,
    COUNT(*) FILTER (
        WHERE status = 'EM_PREPARO'
    ) AS em_preparo,
    COUNT(*) FILTER (
        WHERE status = 'SAIU_ENTREGA'
    ) AS em_entrega
FROM pedidos
GROUP BY empresa_id;

CREATE OR REPLACE VIEW vw_cardapio_produtos AS
SELECT
    p.id,
    p.empresa_id,
    p.categoria_id,
    c.nome AS categoria,
    p.codigo,
    p.descricao,
    p.descricao_detalhada,
    p.tipo,
    p.preco,
    p.destaque,
    p.disponivel,
    p.ordem,
    (
        SELECT pi.url
        FROM produto_imagens pi
        WHERE pi.produto_id = p.id
        ORDER BY pi.principal DESC, pi.ordem, pi.id
        LIMIT 1
    ) AS imagem_url
FROM produtos p
LEFT JOIN categorias c ON c.id = p.categoria_id
WHERE p.ativo = TRUE
  AND p.disponivel = TRUE;

-- ============================================================================
-- DADOS INICIAIS
-- ============================================================================

INSERT INTO permissoes (chave, descricao, modulo)
VALUES
    ('dashboard.visualizar', 'Visualizar dashboard', 'Dashboard'),
    ('pedidos.visualizar', 'Visualizar pedidos', 'Pedidos'),
    ('pedidos.criar', 'Criar pedidos', 'Pedidos'),
    ('pedidos.alterar_status', 'Alterar status de pedidos', 'Pedidos'),
    ('pedidos.cancelar', 'Cancelar pedidos', 'Pedidos'),
    ('cardapio.visualizar', 'Visualizar cardápio', 'Cardápio'),
    ('cardapio.editar', 'Editar cardápio', 'Cardápio'),
    ('clientes.visualizar', 'Visualizar clientes', 'Clientes'),
    ('clientes.editar', 'Editar clientes', 'Clientes'),
    ('caixa.visualizar', 'Visualizar caixa', 'Caixa'),
    ('caixa.movimentar', 'Movimentar caixa', 'Caixa'),
    ('configuracoes.editar', 'Editar configurações', 'Configurações')
ON CONFLICT (chave) DO NOTHING;

-- Empresa de demonstração.
INSERT INTO empresas (
    razao_social,
    nome_fantasia,
    telefone,
    whatsapp,
    email,
    cidade,
    uf
)
SELECT
    'Sensor Delivery Demonstração LTDA',
    'Sensor Delivery',
    '(48) 0000-0000',
    '(48) 99999-9999',
    'contato@sensordelivery.local',
    'Bombinhas',
    'SC'
WHERE NOT EXISTS (
    SELECT 1
    FROM empresas
    WHERE nome_fantasia = 'Sensor Delivery'
);

-- Perfil administrador.
INSERT INTO perfis (empresa_id, nome, descricao)
SELECT
    e.id,
    'Administrador',
    'Acesso completo ao sistema'
FROM empresas e
WHERE e.nome_fantasia = 'Sensor Delivery'
  AND NOT EXISTS (
      SELECT 1
      FROM perfis p
      WHERE p.empresa_id = e.id
        AND p.nome = 'Administrador'
  );

-- Vincula todas as permissões ao perfil administrador.
INSERT INTO perfil_permissoes (perfil_id, permissao_id)
SELECT
    p.id,
    pe.id
FROM perfis p
JOIN empresas e ON e.id = p.empresa_id
CROSS JOIN permissoes pe
WHERE e.nome_fantasia = 'Sensor Delivery'
  AND p.nome = 'Administrador'
ON CONFLICT DO NOTHING;

-- Formas de pagamento iniciais.
INSERT INTO formas_pagamento (
    empresa_id,
    descricao,
    tipo,
    permite_troco,
    pagamento_na_entrega,
    ordem
)
SELECT e.id, x.descricao, x.tipo, x.permite_troco, x.pagamento_na_entrega, x.ordem
FROM empresas e
CROSS JOIN (
    VALUES
        ('Dinheiro', 'DINHEIRO', TRUE, TRUE, 1),
        ('Pix', 'PIX', FALSE, FALSE, 2),
        ('Cartão de crédito na entrega', 'CREDITO', FALSE, TRUE, 3),
        ('Cartão de débito na entrega', 'DEBITO', FALSE, TRUE, 4)
) AS x(descricao, tipo, permite_troco, pagamento_na_entrega, ordem)
WHERE e.nome_fantasia = 'Sensor Delivery'
ON CONFLICT (empresa_id, descricao) DO NOTHING;

-- Categorias iniciais.
INSERT INTO categorias (empresa_id, nome, descricao, ordem)
SELECT e.id, x.nome, x.descricao, x.ordem
FROM empresas e
CROSS JOIN (
    VALUES
        ('Pizzas', 'Pizzas tradicionais e especiais', 1),
        ('Bebidas', 'Refrigerantes, sucos e águas', 2),
        ('Combos', 'Combinações promocionais', 3),
        ('Sobremesas', 'Sobremesas e doces', 4)
) AS x(nome, descricao, ordem)
WHERE e.nome_fantasia = 'Sensor Delivery'
ON CONFLICT (empresa_id, nome) DO NOTHING;

-- Tamanhos de pizza.
INSERT INTO pizza_tamanhos (
    empresa_id,
    descricao,
    sigla,
    quantidade_fatias,
    limite_sabores,
    ordem
)
SELECT e.id, x.descricao, x.sigla, x.fatias, x.limite, x.ordem
FROM empresas e
CROSS JOIN (
    VALUES
        ('Pequena', 'P', 4, 1, 1),
        ('Média', 'M', 6, 2, 2),
        ('Grande', 'G', 8, 3, 3),
        ('Família', 'F', 12, 4, 4)
) AS x(descricao, sigla, fatias, limite, ordem)
WHERE e.nome_fantasia = 'Sensor Delivery'
ON CONFLICT (empresa_id, descricao) DO NOTHING;

-- Bordas iniciais.
INSERT INTO pizza_bordas (empresa_id, descricao, ordem)
SELECT e.id, x.descricao, x.ordem
FROM empresas e
CROSS JOIN (
    VALUES
        ('Sem borda', 1),
        ('Catupiry', 2),
        ('Cheddar', 3),
        ('Chocolate', 4)
) AS x(descricao, ordem)
WHERE e.nome_fantasia = 'Sensor Delivery'
ON CONFLICT (empresa_id, descricao) DO NOTHING;

-- Configurações iniciais.
INSERT INTO configuracoes (
    empresa_id,
    chave,
    valor,
    tipo,
    descricao
)
SELECT e.id, x.chave, x.valor, x.tipo, x.descricao
FROM empresas e
CROSS JOIN (
    VALUES
        ('PEDIDO_TAXA_ENTREGA_PADRAO', '8.00', 'DECIMAL', 'Taxa padrão de entrega'),
        ('PEDIDO_PRAZO_MINIMO', '30', 'INTEGER', 'Prazo mínimo em minutos'),
        ('PEDIDO_PRAZO_MAXIMO', '60', 'INTEGER', 'Prazo máximo em minutos'),
        ('LOJA_ABERTA', 'true', 'BOOLEAN', 'Indica se a loja está aberta'),
        ('ACEITA_ENTREGA', 'true', 'BOOLEAN', 'Permite pedidos para entrega'),
        ('ACEITA_RETIRADA', 'true', 'BOOLEAN', 'Permite pedidos para retirada')
) AS x(chave, valor, tipo, descricao)
WHERE e.nome_fantasia = 'Sensor Delivery'
ON CONFLICT (empresa_id, chave) DO NOTHING;

COMMIT;

-- ============================================================================
-- CONSULTAS DE CONFERÊNCIA
-- ============================================================================

-- SELECT * FROM empresas;
-- SELECT * FROM formas_pagamento;
-- SELECT * FROM categorias;
-- SELECT * FROM pizza_tamanhos;
-- SELECT * FROM vw_dashboard_diario;
-- SELECT * FROM vw_cardapio_produtos;
-- SELECT * FROM vw_pedidos_resumo ORDER BY criado_em DESC;
