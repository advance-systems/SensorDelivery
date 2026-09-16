BEGIN;

INSERT INTO permissoes (codigo, nome, modulo, ordem) VALUES
    ('dashboard.visualizar', 'Acessar central de pedidos', 'Central de pedidos', 10),

    ('pedidos.visualizar', 'Acessar pedidos', 'Pedidos', 20),
    ('pedidos.alterar', 'Alterar pedidos', 'Pedidos', 22),

    ('clientes.visualizar', 'Acessar clientes', 'Clientes', 30),
    ('clientes.incluir', 'Incluir clientes', 'Clientes', 31),
    ('clientes.alterar', 'Alterar clientes', 'Clientes', 32),
    ('clientes.excluir', 'Excluir clientes', 'Clientes', 33),

    ('empresas.visualizar', 'Acessar empresas', 'Empresas', 40),
    ('empresas.incluir', 'Incluir empresas', 'Empresas', 41),
    ('empresas.alterar', 'Alterar empresas', 'Empresas', 42),
    ('empresas.excluir', 'Excluir empresas', 'Empresas', 43),

    ('usuarios.visualizar', 'Acessar usuários', 'Usuários', 50),
    ('usuarios.incluir', 'Incluir usuários', 'Usuários', 51),
    ('usuarios.alterar', 'Alterar usuários', 'Usuários', 52),
    ('usuarios.excluir', 'Excluir usuários', 'Usuários', 53),

    ('permissoes.visualizar', 'Acessar permissões', 'Permissões', 60),
    ('permissoes.alterar', 'Alterar permissões', 'Permissões', 62),

    ('cardapio.visualizar', 'Acessar cardápio', 'Cardápio', 70),
    ('cardapio.incluir', 'Incluir itens no cardápio', 'Cardápio', 71),
    ('cardapio.alterar', 'Alterar itens do cardápio', 'Cardápio', 72),
    ('cardapio.excluir', 'Excluir itens do cardápio', 'Cardápio', 73),

    ('categorias.visualizar', 'Acessar categorias', 'Categorias', 80),
    ('categorias.incluir', 'Incluir categorias', 'Categorias', 81),
    ('categorias.alterar', 'Alterar categorias', 'Categorias', 82),
    ('categorias.excluir', 'Excluir categorias', 'Categorias', 83),

    ('sabores.visualizar', 'Acessar sabores', 'Sabores', 90),
    ('sabores.incluir', 'Incluir sabores', 'Sabores', 91),
    ('sabores.alterar', 'Alterar sabores', 'Sabores', 92),
    ('sabores.excluir', 'Excluir sabores', 'Sabores', 93),

    ('combos.visualizar', 'Acessar combos', 'Combos', 100),
    ('combos.incluir', 'Incluir combos', 'Combos', 101),
    ('combos.alterar', 'Alterar combos', 'Combos', 102),
    ('combos.excluir', 'Excluir combos', 'Combos', 103),

    ('promocoes.visualizar', 'Acessar promoções', 'Promoções', 110),
    ('promocoes.incluir', 'Incluir promoções', 'Promoções', 111),
    ('promocoes.alterar', 'Alterar promoções', 'Promoções', 112),
    ('promocoes.excluir', 'Excluir promoções', 'Promoções', 113),

    ('entregadores.visualizar', 'Acessar entregadores', 'Entregadores', 120),
    ('entregadores.incluir', 'Incluir entregadores', 'Entregadores', 121),
    ('entregadores.alterar', 'Alterar entregadores', 'Entregadores', 122),
    ('entregadores.excluir', 'Excluir entregadores', 'Entregadores', 123),

    ('financeiro.visualizar', 'Acessar financeiro', 'Financeiro', 130),
    ('relatorios.visualizar', 'Acessar relatórios', 'Relatórios', 140),

    ('configuracoes.visualizar', 'Acessar configurações', 'Configurações', 150),
    ('configuracoes.alterar', 'Alterar configurações', 'Configurações', 152)
ON CONFLICT (codigo) DO UPDATE SET
    nome = EXCLUDED.nome,
    modulo = EXCLUDED.modulo,
    ordem = EXCLUDED.ordem;

-- Preserva os acessos antigos: quem podia editar continua podendo incluir,
-- alterar e excluir nas telas que oferecem essas ações.
INSERT INTO usuario_permissoes (usuario_id, empresa_id, permissao_codigo)
SELECT antiga.usuario_id,
       antiga.empresa_id,
       nova.codigo
FROM usuario_permissoes antiga
CROSS JOIN (VALUES ('incluir'), ('alterar'), ('excluir')) AS a(acao)
JOIN permissoes nova
  ON nova.codigo = split_part(antiga.permissao_codigo, '.', 1) || '.' || a.acao
WHERE antiga.permissao_codigo LIKE '%.editar'
ON CONFLICT DO NOTHING;

DELETE FROM permissoes WHERE codigo LIKE '%.editar';

COMMIT;
