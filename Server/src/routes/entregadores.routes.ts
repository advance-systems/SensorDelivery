import { Router } from 'express';
import { database } from '../database/connection.js';
import { empresaIdAutenticada } from '../middleware/auth.middleware.js';

const router = Router();

router.get('/', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const busca = String(req.query.busca ?? '').trim();
    if (!empresaId) return res.status(400).json({ erro: 'empresaId é obrigatório.' });

    try {
        const resultado = await database.query(
            `SELECT e.id, e.empresa_id, e.usuario_id, e.nome, e.telefone,
                    e.documento, e.veiculo, e.placa, e.disponivel, e.ativo,
                    COUNT(en.id) FILTER (
                        WHERE en.status::text NOT IN ('ENTREGUE', 'CANCELADA')
                    )::integer AS entregas_em_andamento
             FROM entregadores e
             LEFT JOIN entregas en ON en.entregador_id = e.usuario_id
             WHERE e.empresa_id = $1
               AND ($2 = '' OR e.nome ILIKE '%' || $2 || '%'
                    OR e.telefone ILIKE '%' || $2 || '%'
                    OR COALESCE(e.documento, '') ILIKE '%' || $2 || '%'
                    OR COALESCE(e.veiculo, '') ILIKE '%' || $2 || '%'
                    OR COALESCE(e.placa, '') ILIKE '%' || $2 || '%')
             GROUP BY e.id
             ORDER BY e.ativo DESC, e.disponivel DESC, e.nome
             LIMIT 200`,
            [empresaId, busca],
        );
        return res.status(200).json({ entregadores: resultado.rows });
    } catch (error) {
        console.error('Erro ao listar entregadores:', error);
        return res.status(500).json({
            erro: 'Não foi possível listar os entregadores.',
            detalhe: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});

router.post('/', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const nome = String(req.body.nome ?? '').trim();
    const telefone = String(req.body.telefone ?? '').trim();
    const documento = String(req.body.documento ?? '').trim();
    const veiculo = String(req.body.veiculo ?? '').trim();
    const placa = String(req.body.placa ?? '').trim().toUpperCase();
    const disponivel = typeof req.body.disponivel === 'boolean' ? req.body.disponivel : true;

    if (!empresaId) return res.status(400).json({ erro: 'empresaId é obrigatório.' });
    if (!nome) return res.status(400).json({ erro: 'Nome é obrigatório.' });
    if (!telefone) return res.status(400).json({ erro: 'Telefone é obrigatório.' });

    try {
        const resultado = await database.query(
            `INSERT INTO entregadores
                (empresa_id, nome, telefone, documento, veiculo, placa, disponivel, ativo)
             VALUES ($1, $2, $3, NULLIF($4, ''), NULLIF($5, ''), NULLIF($6, ''), $7, TRUE)
             RETURNING id, empresa_id, usuario_id, nome, telefone, documento,
                       veiculo, placa, disponivel, ativo, criado_em, atualizado_em`,
            [empresaId, nome, telefone, documento, veiculo, placa, disponivel],
        );
        return res.status(201).json({ entregador: resultado.rows[0] });
    } catch (error: any) {
        console.error('Erro ao cadastrar entregador:', error);
        if (error?.code === '23505') {
            return res.status(409).json({ erro: 'Já existe um entregador com esse telefone ou documento.' });
        }
        return res.status(500).json({
            erro: 'Não foi possível cadastrar o entregador.',
            detalhe: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});

router.put('/:id', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const id = String(req.params.id ?? '').trim();
    const nome = String(req.body.nome ?? '').trim();
    const telefone = String(req.body.telefone ?? '').trim();
    const documento = String(req.body.documento ?? '').trim();
    const veiculo = String(req.body.veiculo ?? '').trim();
    const placa = String(req.body.placa ?? '').trim().toUpperCase();
    const disponivel = typeof req.body.disponivel === 'boolean' ? req.body.disponivel : true;
    if (!id) return res.status(400).json({ erro: 'Entregador inválido.' });
    if (!nome) return res.status(400).json({ erro: 'Nome é obrigatório.' });
    if (!telefone) return res.status(400).json({ erro: 'Telefone é obrigatório.' });

    try {
        const resultado = await database.query(
            `UPDATE entregadores
             SET nome = $2, telefone = $3, documento = NULLIF($4, ''),
                 veiculo = NULLIF($5, ''), placa = NULLIF($6, ''),
                 disponivel = $7,
                 atualizado_em = CURRENT_TIMESTAMP
             WHERE id = $1 AND empresa_id = $8
             RETURNING id, empresa_id, usuario_id, nome, telefone, documento,
                       veiculo, placa, disponivel, ativo, criado_em, atualizado_em`,
            [id, nome, telefone, documento, veiculo, placa, disponivel, empresaId],
        );
        if (resultado.rowCount === 0) {
            return res.status(404).json({ erro: 'Entregador não encontrado.' });
        }
        return res.status(200).json({ entregador: resultado.rows[0] });
    } catch (error: any) {
        console.error('Erro ao editar entregador:', error);
        if (error?.code === '23505') {
            return res.status(409).json({ erro: 'Já existe outro entregador com esse telefone ou documento.' });
        }
        return res.status(500).json({
            erro: 'Não foi possível editar o entregador.',
            detalhe: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});

router.patch('/:id/situacao', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const id = String(req.params.id ?? '').trim();
    const possuiAtivo = typeof req.body.ativo === 'boolean';
    const possuiDisponivel = typeof req.body.disponivel === 'boolean';
    if (!id || (!possuiAtivo && !possuiDisponivel)) {
        return res.status(400).json({ erro: 'Informe o entregador e a situação.' });
    }

    try {
        const resultado = await database.query(
            `UPDATE entregadores
             SET ativo = COALESCE($2::boolean, ativo),
                 disponivel = CASE
                     WHEN $2::boolean = FALSE THEN FALSE
                     ELSE COALESCE($3::boolean, disponivel)
                 END,
                 atualizado_em = CURRENT_TIMESTAMP
             WHERE id = $1 AND empresa_id = $4
             RETURNING id, empresa_id, usuario_id, nome, telefone, documento,
                       veiculo, placa, disponivel, ativo, criado_em, atualizado_em`,
            [id, possuiAtivo ? req.body.ativo : null,
                possuiDisponivel ? req.body.disponivel : null, empresaId],
        );
        if (resultado.rowCount === 0) {
            return res.status(404).json({ erro: 'Entregador não encontrado.' });
        }
        return res.status(200).json({ entregador: resultado.rows[0] });
    } catch (error) {
        console.error('Erro ao alterar situação do entregador:', error);
        return res.status(500).json({
            erro: 'Não foi possível alterar o entregador.',
            detalhe: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});

export default router;
