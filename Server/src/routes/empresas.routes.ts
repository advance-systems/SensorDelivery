import { Router } from 'express';
import { database } from '../database/connection.js';
import type { AuthenticatedRequest } from '../middleware/auth.middleware.js';

const router = Router();

router.get('/', async (req, res) => {
    const busca = String(req.query.busca ?? '').trim();
    const sessao = (req as AuthenticatedRequest).usuario!;
    try {
        const resultado = await database.query(
            `SELECT id, razao_social, nome_fantasia, logo_url, telefone,
                    pix_provedor,
                    email, timezone, ativo, criado_em, atualizado_em
             FROM empresas e
             WHERE ($1 = '' OR razao_social ILIKE '%' || $1 || '%'
                OR nome_fantasia ILIKE '%' || $1 || '%'
                OR COALESCE(logo_url, '') ILIKE '%' || $1 || '%'
                OR COALESCE(telefone, '') ILIKE '%' || $1 || '%'
                OR COALESCE(email, '') ILIKE '%' || $1 || '%')
               AND ($2 = 'ADMIN' OR EXISTS (
                    SELECT 1 FROM usuario_empresas ue
                    WHERE ue.usuario_id = $3 AND ue.empresa_id = e.id
               ))
             ORDER BY ativo DESC, nome_fantasia, razao_social LIMIT 200`,
            [busca, sessao.tipo, sessao.usuarioId],
        );
        return res.status(200).json({ empresas: resultado.rows });
    } catch (error) {
        console.error('Erro ao listar empresas:', error);
        return res.status(500).json({ erro: 'Não foi possível listar as empresas.' });
    }
});

function dadosEmpresa(body: any) {
    return {
        razaoSocial: String(body.razaoSocial ?? '').trim(),
        nomeFantasia: String(body.nomeFantasia ?? '').trim(),
        logoUrl: String(body.logoUrl ?? '').trim(),
        telefone: String(body.telefone ?? '').trim(),
        email: String(body.email ?? '').trim(),
        timezone: String(body.timezone ?? 'America/Sao_Paulo').trim(),
        pixProvedor: String(body.pixProvedor ?? 'ASAAS').trim().toUpperCase(),
    };
}

router.post('/', async (req, res) => {
    const d = dadosEmpresa(req.body);
    if (!d.razaoSocial) return res.status(400).json({ erro: 'Razão social é obrigatória.' });
    if (!d.nomeFantasia) return res.status(400).json({ erro: 'Nome fantasia é obrigatório.' });
    if (!['ASAAS', 'SICREDI'].includes(d.pixProvedor)) {
        return res.status(400).json({ erro: 'Banco de recebimento PIX inválido.' });
    }
    try {
        const resultado = await database.query(
            `INSERT INTO empresas
                (razao_social, nome_fantasia, logo_url, telefone, email, timezone,
                 pix_provedor, ativo)
             VALUES ($1, $2, NULLIF($3, ''), NULLIF($4, ''), NULLIF($5, ''),
                     $6, $7, TRUE)
             RETURNING *`,
            [d.razaoSocial, d.nomeFantasia, d.logoUrl, d.telefone, d.email,
             d.timezone, d.pixProvedor],
        );
        return res.status(201).json({ empresa: resultado.rows[0] });
    } catch (error: any) {
        console.error('Erro ao cadastrar empresa:', error);
        return res.status(500).json({ erro: 'Não foi possível cadastrar a empresa.' });
    }
});

router.put('/:id', async (req, res) => {
    const id = String(req.params.id ?? '').trim();
    const d = dadosEmpresa(req.body);
    if (!id) return res.status(400).json({ erro: 'Empresa inválida.' });
    if (!d.razaoSocial) return res.status(400).json({ erro: 'Razão social é obrigatória.' });
    if (!d.nomeFantasia) return res.status(400).json({ erro: 'Nome fantasia é obrigatório.' });
    if (!['ASAAS', 'SICREDI'].includes(d.pixProvedor)) {
        return res.status(400).json({ erro: 'Banco de recebimento PIX inválido.' });
    }
    try {
        const resultado = await database.query(
            `UPDATE empresas SET razao_social = $2, nome_fantasia = $3,
                 logo_url = NULLIF($4, ''), telefone = NULLIF($5, ''),
                 email = NULLIF($6, ''), timezone = $7,
                 pix_provedor = $8,
                 atualizado_em = CURRENT_TIMESTAMP
             WHERE id = $1 RETURNING *`,
            [id, d.razaoSocial, d.nomeFantasia, d.logoUrl, d.telefone, d.email,
             d.timezone, d.pixProvedor],
        );
        if (resultado.rowCount === 0) return res.status(404).json({ erro: 'Empresa não encontrada.' });
        return res.status(200).json({ empresa: resultado.rows[0] });
    } catch (error: any) {
        console.error('Erro ao editar empresa:', error);
        return res.status(500).json({ erro: 'Não foi possível editar a empresa.' });
    }
});

router.patch('/:id/situacao', async (req, res) => {
    const id = String(req.params.id ?? '').trim();
    if (!id || typeof req.body.ativo !== 'boolean') {
        return res.status(400).json({ erro: 'Informe a empresa e a situação.' });
    }
    try {
        const resultado = await database.query(
            `UPDATE empresas SET ativo = $2, atualizado_em = CURRENT_TIMESTAMP
             WHERE id = $1 RETURNING *`, [id, req.body.ativo],
        );
        if (resultado.rowCount === 0) return res.status(404).json({ erro: 'Empresa não encontrada.' });
        return res.status(200).json({ empresa: resultado.rows[0] });
    } catch (error) {
        console.error('Erro ao alterar empresa:', error);
        return res.status(500).json({ erro: 'Não foi possível alterar a empresa.' });
    }
});

export default router;
