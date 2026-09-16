import { Router } from 'express';
import { database } from '../database/connection.js';
import { autenticarToken, type AuthenticatedRequest } from '../middleware/auth.middleware.js';
import { exigirPermissao } from '../middleware/permission.middleware.js';

const router = Router();
router.use(autenticarToken);

router.get('/', exigirPermissao('permissoes.visualizar'), async (_req, res) => {
    try {
        const resultado = await database.query(
            'SELECT codigo, nome, modulo, ordem FROM permissoes ORDER BY ordem, codigo',
        );
        return res.json({ permissoes: resultado.rows });
    } catch (error) {
        console.error('Erro ao listar permissões:', error);
        return res.status(500).json({ erro: 'Não foi possível listar as permissões.' });
    }
});

router.get('/usuario/:usuarioId', exigirPermissao('permissoes.visualizar'), async (req, res) => {
    const usuarioId = String(req.params.usuarioId ?? '').trim();
    const empresaId = String(req.query.empresaId ?? '').trim();
    const sessao = (req as AuthenticatedRequest).usuario!;
    if (!usuarioId || !empresaId) return res.status(400).json({ erro: 'Informe o usuário e a empresa.' });
    if (sessao.tipo !== 'ADMIN' && empresaId !== sessao.empresaId) {
        return res.status(403).json({ erro: 'Empresa fora do escopo do usuário.' });
    }
    try {
        const resultado = await database.query(
            `SELECT permissao_codigo AS codigo FROM usuario_permissoes
             WHERE usuario_id = $1 AND empresa_id = $2 ORDER BY permissao_codigo`,
            [usuarioId, empresaId],
        );
        return res.json({ permissoes: resultado.rows.map((item) => item.codigo) });
    } catch (error) {
        console.error('Erro ao carregar permissões:', error);
        return res.status(500).json({ erro: 'Não foi possível carregar as permissões.' });
    }
});

router.put('/usuario/:usuarioId', exigirPermissao('permissoes.alterar'), async (req, res) => {
    const usuarioId = String(req.params.usuarioId ?? '').trim();
    const empresaId = String(req.body?.empresaId ?? '').trim();
    const sessao = (req as AuthenticatedRequest).usuario!;
    const permissoes: string[] = Array.isArray(req.body?.permissoes)
        ? [...new Set<string>(req.body.permissoes.map((codigo: unknown) => String(codigo).trim()).filter(Boolean))]
        : [];
    if (!usuarioId || !empresaId) return res.status(400).json({ erro: 'Informe o usuário e a empresa.' });
    if (sessao.tipo !== 'ADMIN' && empresaId !== sessao.empresaId) {
        return res.status(403).json({ erro: 'Empresa fora do escopo do usuário.' });
    }
    const client = await database.connect();
    try {
        await client.query('BEGIN');
        const vinculo = await client.query(
            'SELECT 1 FROM usuario_empresas WHERE usuario_id = $1 AND empresa_id = $2',
            [usuarioId, empresaId],
        );
        if (!vinculo.rowCount) {
            await client.query('ROLLBACK');
            return res.status(400).json({ erro: 'O usuário não está vinculado a esta empresa.' });
        }
        await client.query(
            'DELETE FROM usuario_permissoes WHERE usuario_id = $1 AND empresa_id = $2',
            [usuarioId, empresaId],
        );
        for (const codigo of permissoes) {
            await client.query(
                `INSERT INTO usuario_permissoes (usuario_id, empresa_id, permissao_codigo)
                 SELECT $1, $2, codigo FROM permissoes WHERE codigo = $3`,
                [usuarioId, empresaId, codigo],
            );
        }
        await client.query('COMMIT');
        return res.json({ permissoes });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Erro ao salvar permissões:', error);
        return res.status(500).json({ erro: 'Não foi possível salvar as permissões.' });
    } finally { client.release(); }
});

export default router;
