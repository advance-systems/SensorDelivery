import { Router } from 'express';
import { database } from '../database/connection.js';
import { autenticarToken, type AuthenticatedRequest } from '../middleware/auth.middleware.js';
import { exigirPermissao } from '../middleware/permission.middleware.js';

const router = Router();
const TIPOS = ['ADMIN', 'GERENTE', 'ATENDENTE', 'COZINHA', 'ENTREGADOR'];

router.use(autenticarToken);

router.get('/', exigirPermissao('usuarios.visualizar'), async (req, res) => {
    const busca = String(req.query.busca ?? '').trim();
    const sessao = (req as AuthenticatedRequest).usuario!;
    try {
        const resultado = await database.query(
            `SELECT u.id, u.nome, u.email, u.tipo::TEXT AS tipo, u.ativo,
                    u.ultimo_acesso, u.criado_em,
                    COALESCE(json_agg(json_build_object(
                        'id', e.id, 'nome_fantasia', e.nome_fantasia,
                        'principal', ue.principal
                    ) ORDER BY ue.principal DESC, e.nome_fantasia)
                    FILTER (WHERE e.id IS NOT NULL), '[]') AS empresas
             FROM usuarios u
             LEFT JOIN usuario_empresas ue ON ue.usuario_id = u.id
             LEFT JOIN empresas e ON e.id = ue.empresa_id
             WHERE ($1 = '' OR u.nome ILIKE '%' || $1 || '%'
                OR u.email ILIKE '%' || $1 || '%')
               AND ($2 = 'ADMIN' OR EXISTS (
                    SELECT 1 FROM usuario_empresas escopo
                    WHERE escopo.usuario_id = u.id AND escopo.empresa_id = $3
               ))
             GROUP BY u.id
             ORDER BY u.ativo DESC, u.nome
             LIMIT 200`,
            [busca, sessao.tipo, sessao.empresaId],
        );
        return res.json({ usuarios: resultado.rows });
    } catch (error) {
        console.error('Erro ao listar usuários:', error);
        return res.status(500).json({ erro: 'Não foi possível listar os usuários.' });
    }
});

function dadosUsuario(body: any) {
    const empresas: string[] = Array.isArray(body.empresas)
        ? [...new Set<string>(body.empresas.map((id: unknown) => String(id).trim()).filter(Boolean))]
        : [];
    return {
        nome: String(body.nome ?? '').trim(),
        email: String(body.email ?? '').trim().toLowerCase(),
        senha: String(body.senha ?? ''),
        tipo: String(body.tipo ?? 'ATENDENTE').trim().toUpperCase(),
        empresas,
        principalEmpresaId: String(body.principalEmpresaId ?? '').trim(),
    };
}

function validarDados(d: ReturnType<typeof dadosUsuario>, criando: boolean): string | null {
    if (!d.nome) return 'Nome é obrigatório.';
    if (!d.email) return 'E-mail é obrigatório.';
    if ((criando || d.senha) && d.senha.length < 6) return 'A senha deve possuir ao menos 6 caracteres.';
    if (!TIPOS.includes(d.tipo)) return 'Perfil de usuário inválido.';
    if (!d.empresas.length) return 'Selecione ao menos uma empresa.';
    if (!d.empresas.includes(d.principalEmpresaId)) return 'Selecione a empresa principal.';
    return null;
}

router.post('/', exigirPermissao('usuarios.incluir'), async (req, res) => {
    const d = dadosUsuario(req.body);
    const sessao = (req as AuthenticatedRequest).usuario!;
    const erro = validarDados(d, true);
    if (erro) return res.status(400).json({ erro });
    if (sessao.tipo !== 'ADMIN' &&
        (d.empresas.length !== 1 || d.empresas[0] !== sessao.empresaId)) {
        return res.status(403).json({ erro: 'Você só pode vincular usuários à empresa ativa.' });
    }
    const client = await database.connect();
    try {
        await client.query('BEGIN');
        const usuario = await client.query(
            `INSERT INTO usuarios (nome, email, senha_hash, tipo, ativo)
             VALUES ($1, $2, crypt($3, gen_salt('bf', 12)), $4::tipo_usuario, TRUE)
             RETURNING id, nome, email, tipo::TEXT AS tipo, ativo`,
            [d.nome, d.email, d.senha, d.tipo],
        );
        for (const empresaId of d.empresas) {
            await client.query(
                `INSERT INTO usuario_empresas (usuario_id, empresa_id, principal)
                 VALUES ($1::uuid, $2::uuid, $2::uuid = $3::uuid)`,
                [usuario.rows[0].id, empresaId, d.principalEmpresaId],
            );
        }
        await client.query('COMMIT');
        return res.status(201).json({ usuario: usuario.rows[0] });
    } catch (error: any) {
        await client.query('ROLLBACK');
        console.error('Erro ao cadastrar usuário:', error);
        if (error?.code === '23505') return res.status(409).json({ erro: 'Já existe um usuário com este e-mail.' });
        return res.status(500).json({ erro: 'Não foi possível cadastrar o usuário.' });
    } finally { client.release(); }
});

router.put('/:id', exigirPermissao('usuarios.alterar'), async (req, res) => {
    const id = String(req.params.id ?? '').trim();
    const d = dadosUsuario(req.body);
    const sessao = (req as AuthenticatedRequest).usuario!;
    const erro = validarDados(d, false);
    if (!id) return res.status(400).json({ erro: 'Usuário inválido.' });
    if (erro) return res.status(400).json({ erro });
    if (sessao.tipo !== 'ADMIN' &&
        (d.empresas.length !== 1 || d.empresas[0] !== sessao.empresaId)) {
        return res.status(403).json({ erro: 'Você só pode vincular usuários à empresa ativa.' });
    }
    const client = await database.connect();
    try {
        await client.query('BEGIN');
        const usuario = await client.query(
            `UPDATE usuarios SET nome = $2, email = $3, tipo = $4::tipo_usuario,
                 senha_hash = CASE WHEN $5 = '' THEN senha_hash ELSE crypt($5, gen_salt('bf', 12)) END,
                 atualizado_em = CURRENT_TIMESTAMP
             WHERE id = $1 RETURNING id, nome, email, tipo::TEXT AS tipo, ativo`,
            [id, d.nome, d.email, d.tipo, d.senha],
        );
        if (!usuario.rowCount) {
            await client.query('ROLLBACK');
            return res.status(404).json({ erro: 'Usuário não encontrado.' });
        }
        await client.query(
            'UPDATE usuario_empresas SET principal = FALSE WHERE usuario_id = $1',
            [id],
        );
        for (const empresaId of d.empresas) {
            await client.query(
                `INSERT INTO usuario_empresas (usuario_id, empresa_id, principal)
                 VALUES ($1::uuid, $2::uuid, $2::uuid = $3::uuid)
                 ON CONFLICT (usuario_id, empresa_id)
                 DO UPDATE SET principal = EXCLUDED.principal`,
                [id, empresaId, d.principalEmpresaId],
            );
        }
        await client.query(
            `DELETE FROM usuario_empresas
             WHERE usuario_id = $1 AND NOT (empresa_id = ANY($2::uuid[]))`,
            [id, d.empresas],
        );
        await client.query('COMMIT');
        return res.json({ usuario: usuario.rows[0] });
    } catch (error: any) {
        await client.query('ROLLBACK');
        console.error('Erro ao editar usuário:', error);
        if (error?.code === '23505') return res.status(409).json({ erro: 'Já existe um usuário com este e-mail.' });
        return res.status(500).json({ erro: 'Não foi possível editar o usuário.' });
    } finally { client.release(); }
});

router.patch('/:id/situacao', exigirPermissao('usuarios.excluir'), async (req, res) => {
    const id = String(req.params.id ?? '').trim();
    const sessao = (req as AuthenticatedRequest).usuario!;
    if (!id || typeof req.body?.ativo !== 'boolean') {
        return res.status(400).json({ erro: 'Informe o usuário e a situação.' });
    }
    if (id === sessao.usuarioId && req.body.ativo === false) {
        return res.status(400).json({ erro: 'Você não pode desativar o próprio usuário.' });
    }
    try {
        const resultado = await database.query(
            `UPDATE usuarios SET ativo = $2, atualizado_em = CURRENT_TIMESTAMP
             WHERE id = $1 RETURNING id, ativo`,
            [id, req.body.ativo],
        );
        if (!resultado.rowCount) return res.status(404).json({ erro: 'Usuário não encontrado.' });
        return res.json({ usuario: resultado.rows[0] });
    } catch (error) {
        console.error('Erro ao alterar usuário:', error);
        return res.status(500).json({ erro: 'Não foi possível alterar o usuário.' });
    }
});

export default router;
