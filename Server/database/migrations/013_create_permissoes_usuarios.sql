BEGIN;

CREATE TABLE IF NOT EXISTS permissoes (
    codigo VARCHAR(80) PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    modulo VARCHAR(60) NOT NULL,
    ordem INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS usuario_permissoes (
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    permissao_codigo VARCHAR(80) NOT NULL REFERENCES permissoes(codigo) ON DELETE CASCADE,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (usuario_id, empresa_id, permissao_codigo),
    FOREIGN KEY (usuario_id, empresa_id)
        REFERENCES usuario_empresas(usuario_id, empresa_id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_usuario_permissoes_empresa
    ON usuario_permissoes(empresa_id, usuario_id);

INSERT INTO permissoes (codigo, nome, modulo, ordem) VALUES
    ('dashboard.visualizar', 'Visualizar central de pedidos', 'Central de pedidos', 10),
    ('pedidos.visualizar', 'Visualizar pedidos', 'Pedidos', 20),
    ('pedidos.editar', 'Alterar pedidos', 'Pedidos', 21),
    ('clientes.visualizar', 'Visualizar clientes', 'Clientes', 30),
    ('clientes.editar', 'Cadastrar e alterar clientes', 'Clientes', 31),
    ('empresas.visualizar', 'Visualizar empresas', 'Empresas', 40),
    ('empresas.editar', 'Cadastrar e alterar empresas', 'Empresas', 41),
    ('usuarios.visualizar', 'Visualizar usuários', 'Usuários', 50),
    ('usuarios.editar', 'Cadastrar e alterar usuários', 'Usuários', 51),
    ('permissoes.visualizar', 'Visualizar permissões', 'Permissões', 60),
    ('permissoes.editar', 'Alterar permissões', 'Permissões', 61),
    ('cardapio.visualizar', 'Visualizar cardápio', 'Cardápio', 70),
    ('cardapio.editar', 'Alterar cardápio', 'Cardápio', 71),
    ('categorias.visualizar', 'Visualizar categorias', 'Categorias', 80),
    ('categorias.editar', 'Alterar categorias', 'Categorias', 81),
    ('sabores.visualizar', 'Visualizar sabores', 'Sabores', 90),
    ('sabores.editar', 'Alterar sabores', 'Sabores', 91),
    ('combos.visualizar', 'Visualizar combos', 'Combos', 100),
    ('combos.editar', 'Alterar combos', 'Combos', 101),
    ('promocoes.visualizar', 'Visualizar promoções', 'Promoções', 110),
    ('promocoes.editar', 'Alterar promoções', 'Promoções', 111),
    ('entregadores.visualizar', 'Visualizar entregadores', 'Entregadores', 120),
    ('entregadores.editar', 'Alterar entregadores', 'Entregadores', 121),
    ('financeiro.visualizar', 'Visualizar financeiro', 'Financeiro', 130),
    ('relatorios.visualizar', 'Visualizar relatórios', 'Relatórios', 140),
    ('configuracoes.visualizar', 'Visualizar configurações', 'Configurações', 150),
    ('configuracoes.editar', 'Alterar configurações', 'Configurações', 151)
ON CONFLICT (codigo) DO UPDATE SET
    nome = EXCLUDED.nome,
    modulo = EXCLUDED.modulo,
    ordem = EXCLUDED.ordem;

COMMIT;
