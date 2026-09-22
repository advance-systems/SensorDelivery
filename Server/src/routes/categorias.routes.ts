import { Router } from 'express';
import { database } from '../database/connection.js';
import { empresaIdAutenticada } from '../middleware/auth.middleware.js';

const router = Router();

router.get('/', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const busca = String(req.query.busca ?? '').trim();

    if (!empresaId) {
        return res.status(400).json({ erro: 'empresaId é obrigatório.' });
    }

    try {
        const resultado = await database.query(
            `
            SELECT
                c.id,
                c.empresa_id,
                c.nome,
                c.descricao,
                c.imagem_url,
                c.ordem,
                c.ativo,
                COUNT(p.id)::integer AS quantidade_produtos
            FROM categorias c
            LEFT JOIN produtos p
              ON p.categoria_id = c.id
             AND p.ativo = TRUE
            WHERE c.empresa_id = $1
              AND (
                    $2 = ''
                    OR c.nome ILIKE '%' || $2 || '%'
                    OR COALESCE(c.descricao, '') ILIKE '%' || $2 || '%'
              )
            GROUP BY c.id
            ORDER BY c.ativo DESC, c.ordem, c.nome
            LIMIT 200
            `,
            [empresaId, busca],
        );

        return res.status(200).json({ categorias: resultado.rows });
    } catch (error) {
        console.error('Erro ao listar categorias:', error);
        return res.status(500).json({
            erro: 'Não foi possível listar as categorias.',
            detalhe: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});

router.post('/', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const nome = String(req.body.nome ?? '').trim();
    const descricao = String(req.body.descricao ?? '').trim();
    const imagemUrl = String(req.body.imagemUrl ?? '').trim();
    const ordem = Number(req.body.ordem ?? 0);

    if (!empresaId) return res.status(400).json({ erro: 'empresaId é obrigatório.' });
    if (!nome) return res.status(400).json({ erro: 'Nome é obrigatório.' });
    if (!Number.isInteger(ordem) || ordem < 0) {
        return res.status(400).json({ erro: 'Ordem deve ser um número inteiro maior ou igual a zero.' });
    }

    try {
        const resultado = await database.query(
            `
            INSERT INTO categorias (empresa_id, nome, descricao, imagem_url, ordem, ativo)
            VALUES ($1, $2, NULLIF($3, ''), NULLIF($4, ''), $5, TRUE)
            RETURNING id, empresa_id, nome, descricao, imagem_url, ordem, ativo,
                      criado_em, atualizado_em
            `,
            [empresaId, nome, descricao, imagemUrl, ordem],
        );
        return res.status(201).json({ categoria: resultado.rows[0] });
    } catch (error: any) {
        console.error('Erro ao cadastrar categoria:', error);
        if (error?.code === '23505') {
            return res.status(409).json({ erro: 'Já existe uma categoria com esse nome.' });
        }
        return res.status(500).json({
            erro: 'Não foi possível cadastrar a categoria.',
            detalhe: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});

router.put('/:id', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const categoriaId = String(req.params.id ?? '').trim();
    const nome = String(req.body.nome ?? '').trim();
    const descricao = String(req.body.descricao ?? '').trim();
    const imagemUrl = String(req.body.imagemUrl ?? '').trim();
    const ordem = Number(req.body.ordem ?? 0);

    if (!categoriaId) return res.status(400).json({ erro: 'Categoria inválida.' });
    if (!nome) return res.status(400).json({ erro: 'Nome é obrigatório.' });
    if (!Number.isInteger(ordem) || ordem < 0) {
        return res.status(400).json({ erro: 'Ordem deve ser um número inteiro maior ou igual a zero.' });
    }

    try {
        const resultado = await database.query(
            `
            UPDATE categorias
            SET nome = $2,
                descricao = NULLIF($3, ''),
                imagem_url = NULLIF($4, ''),
                ordem = $5,
                atualizado_em = CURRENT_TIMESTAMP
            WHERE id = $1 AND empresa_id = $6
            RETURNING id, empresa_id, nome, descricao, imagem_url, ordem, ativo,
                      criado_em, atualizado_em
            `,
            [categoriaId, nome, descricao, imagemUrl, ordem, empresaId],
        );
        if (resultado.rowCount === 0) {
            return res.status(404).json({ erro: 'Categoria não encontrada.' });
        }
        return res.status(200).json({ categoria: resultado.rows[0] });
    } catch (error: any) {
        console.error('Erro ao editar categoria:', error);
        if (error?.code === '23505') {
            return res.status(409).json({ erro: 'Já existe outra categoria com esse nome.' });
        }
        return res.status(500).json({
            erro: 'Não foi possível editar a categoria.',
            detalhe: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});

router.patch('/:id/situacao', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const categoriaId = String(req.params.id ?? '').trim();
    if (!categoriaId || typeof req.body.ativo !== 'boolean') {
        return res.status(400).json({ erro: 'Informe uma categoria e a situação.' });
    }

    try {
        const resultado = await database.query(
            `
            UPDATE categorias
            SET ativo = $2, atualizado_em = CURRENT_TIMESTAMP
            WHERE id = $1 AND empresa_id = $3
            RETURNING id, empresa_id, nome, descricao, imagem_url, ordem, ativo,
                      criado_em, atualizado_em
            `,
            [categoriaId, req.body.ativo, empresaId],
        );
        if (resultado.rowCount === 0) {
            return res.status(404).json({ erro: 'Categoria não encontrada.' });
        }
        return res.status(200).json({ categoria: resultado.rows[0] });
    } catch (error) {
        console.error('Erro ao alterar situação da categoria:', error);
        return res.status(500).json({
            erro: 'Não foi possível alterar a categoria.',
            detalhe: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});

router.delete('/:id', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const categoriaId = String(req.params.id ?? '').trim();

    if (!categoriaId || !empresaId) {
        return res.status(400).json({ erro: 'Informe o ID da categoria.' });
    }

    try {
        // Tenta exclusão física
        try {
            const resultado = await database.query(
                `DELETE FROM categorias WHERE id = $1 AND empresa_id = $2 RETURNING id`,
                [categoriaId, empresaId]
            );
            if (resultado.rowCount === 0) {
                return res.status(404).json({ erro: 'Categoria não encontrada.' });
            }
            return res.status(200).json({ sucesso: true, mensagem: 'Categoria excluída com sucesso.' });
        } catch (delError: any) {
            // Se houver produtos ou vínculos (FK), inativa a categoria para não quebrar integridade
            if (delError?.code === '23503') {
                await database.query(
                    `UPDATE categorias SET ativo = FALSE, atualizado_em = CURRENT_TIMESTAMP WHERE id = $1 AND empresa_id = $2`,
                    [categoriaId, empresaId]
                );
                return res.status(200).json({
                    sucesso: true,
                    mensagem: 'A categoria possui produtos vinculados e foi inativada/removida do cardápio.',
                });
            }
            throw delError;
        }
    } catch (error) {
        console.error('Erro ao excluir categoria:', error);
        return res.status(500).json({
            erro: 'Não foi possível excluir a categoria.',
            detalhe: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});

export default router;
