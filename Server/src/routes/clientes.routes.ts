import { Router } from 'express';
import { database } from '../database/connection.js';
import { empresaIdAutenticada } from '../middleware/auth.middleware.js';

const router = Router();

router.get('/', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);

    const busca = String(
        req.query.busca ?? ''
    ).trim();

    if (!empresaId) {
        return res.status(400).json({
            erro: 'empresaId é obrigatório.',
        });
    }

    try {
        const resultado = await database.query(
            `
            SELECT
                c.id,
                c.empresa_id,
                c.nome,
                c.telefone,
                c.email,
                c.observacoes,
                c.bloqueado,
                c.ativo,
                c.criado_em,
                c.atualizado_em
            FROM clientes c
            WHERE c.empresa_id = $1
              AND (
                    $2 = ''
                    OR COALESCE(c.nome, '') ILIKE '%' || $2 || '%'
                    OR c.telefone ILIKE '%' || $2 || '%'
                    OR COALESCE(c.email, '') ILIKE '%' || $2 || '%'
              )
            ORDER BY
                c.ativo DESC,
                c.nome,
                c.telefone
            LIMIT 200
            `,
            [
                empresaId,
                busca,
            ]
        );

        return res.status(200).json({
            clientes: resultado.rows,
        });
    } catch (error) {
        console.error(
            'Erro ao listar clientes:',
            error
        );

        const mensagem =
            error instanceof Error
                ? error.message
                : 'Erro desconhecido';

        return res.status(500).json({
            erro: 'Não foi possível listar os clientes.',
            detalhe: mensagem,
        });
    }
});

router.post('/', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);

    const nome = String(
        req.body.nome ?? ''
    ).trim();

    const telefone = String(
        req.body.telefone ?? ''
    ).trim();

    const email = String(
        req.body.email ?? ''
    ).trim();

    const observacoes = String(
        req.body.observacoes ?? ''
    ).trim();

    if (!empresaId) {
        return res.status(400).json({
            erro: 'empresaId é obrigatório.',
        });
    }

    if (!nome) {
        return res.status(400).json({
            erro: 'Nome é obrigatório.',
        });
    }

    if (!telefone) {
        return res.status(400).json({
            erro: 'Telefone é obrigatório.',
        });
    }

    try {
        const resultado = await database.query(
            `
            INSERT INTO clientes (
                empresa_id,
                nome,
                telefone,
                email,
                observacoes,
                bloqueado,
                ativo
            )
            VALUES (
                $1,
                $2,
                $3,
                NULLIF($4, ''),
                NULLIF($5, ''),
                FALSE,
                TRUE
            )
            RETURNING
                id,
                empresa_id,
                nome,
                telefone,
                email,
                observacoes,
                bloqueado,
                ativo,
                criado_em,
                atualizado_em
            `,
            [
                empresaId,
                nome,
                telefone,
                email,
                observacoes,
            ]
        );

        return res.status(201).json({
            cliente: resultado.rows[0],
        });
    } catch (error: any) {
        console.error(
            'Erro ao cadastrar cliente:',
            error
        );

        if (error?.code === '23505') {
            return res.status(409).json({
                erro: 'Já existe um cliente com esse telefone.',
            });
        }

        return res.status(500).json({
            erro: 'Não foi possível cadastrar o cliente.',
            detalhe:
                error instanceof Error
                    ? error.message
                    : 'Erro desconhecido',
        });
    }
});

router.put('/:id', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const clienteId = String(
        req.params.id ?? ''
    ).trim();

    const nome = String(
        req.body.nome ?? ''
    ).trim();

    const telefone = String(
        req.body.telefone ?? ''
    ).trim();

    const email = String(
        req.body.email ?? ''
    ).trim();

    const observacoes = String(
        req.body.observacoes ?? ''
    ).trim();

    if (!clienteId) {
        return res.status(400).json({
            erro: 'Cliente inválido.',
        });
    }

    if (!nome) {
        return res.status(400).json({
            erro: 'Nome é obrigatório.',
        });
    }

    if (!telefone) {
        return res.status(400).json({
            erro: 'Telefone é obrigatório.',
        });
    }

    try {
        const resultado = await database.query(
            `
            UPDATE clientes
            SET
                nome = $2,
                telefone = $3,
                email = NULLIF($4, ''),
                observacoes = NULLIF($5, ''),
                atualizado_em = CURRENT_TIMESTAMP
            WHERE id = $1 AND empresa_id = $6
            RETURNING
                id,
                empresa_id,
                nome,
                telefone,
                email,
                observacoes,
                bloqueado,
                ativo,
                criado_em,
                atualizado_em
            `,
            [
                clienteId,
                nome,
                telefone,
                email,
                observacoes,
                empresaId,
            ]
        );

        if (resultado.rowCount === 0) {
            return res.status(404).json({
                erro: 'Cliente não encontrado.',
            });
        }

        return res.status(200).json({
            cliente: resultado.rows[0],
        });
    } catch (error: any) {
        console.error(
            'Erro ao editar cliente:',
            error
        );

        if (error?.code === '23505') {
            return res.status(409).json({
                erro: 'Já existe outro cliente com esse telefone.',
            });
        }

        return res.status(500).json({
            erro: 'Não foi possível editar o cliente.',
            detalhe:
                error instanceof Error
                    ? error.message
                    : 'Erro desconhecido',
        });
    }
});

router.patch('/:id/situacao', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const clienteId = String(
        req.params.id ?? ''
    ).trim();

    const possuiAtivo =
        typeof req.body.ativo === 'boolean';

    const possuiBloqueado =
        typeof req.body.bloqueado === 'boolean';

    if (!clienteId) {
        return res.status(400).json({
            erro: 'Cliente inválido.',
        });
    }

    if (!possuiAtivo && !possuiBloqueado) {
        return res.status(400).json({
            erro: 'Informe ativo ou bloqueado.',
        });
    }

    try {
        const resultado = await database.query(
            `
            UPDATE clientes
            SET
                ativo = CASE
                    WHEN $2::boolean IS NULL
                        THEN ativo
                    ELSE $2
                END,

                bloqueado = CASE
                    WHEN $3::boolean IS NULL
                        THEN bloqueado
                    ELSE $3
                END,

                atualizado_em = CURRENT_TIMESTAMP
            WHERE id = $1 AND empresa_id = $4
            RETURNING
                id,
                empresa_id,
                nome,
                telefone,
                email,
                observacoes,
                bloqueado,
                ativo,
                criado_em,
                atualizado_em
            `,
            [
                clienteId,
                possuiAtivo
                    ? req.body.ativo
                    : null,
                possuiBloqueado
                    ? req.body.bloqueado
                    : null,
                empresaId,
            ]
        );

        if (resultado.rowCount === 0) {
            return res.status(404).json({
                erro: 'Cliente não encontrado.',
            });
        }

        return res.status(200).json({
            cliente: resultado.rows[0],
        });
    } catch (error) {
        console.error(
            'Erro ao alterar situação do cliente:',
            error
        );

        return res.status(500).json({
            erro: 'Não foi possível alterar o cliente.',
            detalhe:
                error instanceof Error
                    ? error.message
                    : 'Erro desconhecido',
        });
    }
});

export default router;
