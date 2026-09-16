import { Router } from 'express';
import type { PoolClient } from 'pg';
import { database } from '../database/connection.js';
import { empresaIdAutenticada } from '../middleware/auth.middleware.js';

const router = Router();

type ComboItemEntrada = { produtoId: string; quantidade: number; ordem: number };

function dadosCombo(body: any, empresaId: string) {
    const itensBrutos = Array.isArray(body.itens) ? body.itens : [];
    const itens: ComboItemEntrada[] = itensBrutos.map((item: any, indice: number) => ({
        produtoId: String(item.produtoId ?? '').trim(),
        quantidade: Number(item.quantidade ?? 1),
        ordem: Number.isInteger(Number(item.ordem)) ? Number(item.ordem) : indice,
    }));
    return {
        empresaId,
        categoriaId: String(body.categoriaId ?? '').trim(),
        nome: String(body.nome ?? '').trim(),
        descricao: String(body.descricao ?? '').trim(),
        preco: Number(body.preco ?? 0),
        precoPromocional: body.precoPromocional === '' || body.precoPromocional == null
            ? null : Number(body.precoPromocional),
        codigoInterno: String(body.codigoInterno ?? '').trim(),
        ordem: Number(body.ordem ?? 0),
        disponivel: typeof body.disponivel === 'boolean' ? body.disponivel : true,
        destaque: typeof body.destaque === 'boolean' ? body.destaque : false,
        itens,
    };
}

function validarCombo(d: ReturnType<typeof dadosCombo>, exigeEmpresa: boolean): string | null {
    if (exigeEmpresa && !d.empresaId) return 'empresaId é obrigatório.';
    if (!d.categoriaId) return 'Categoria é obrigatória.';
    if (!d.nome) return 'Nome é obrigatório.';
    if (!Number.isFinite(d.preco) || d.preco < 0) return 'Preço inválido.';
    if (d.precoPromocional !== null &&
        (!Number.isFinite(d.precoPromocional) || d.precoPromocional < 0)) {
        return 'Preço promocional inválido.';
    }
    if (!Number.isInteger(d.ordem) || d.ordem < 0) return 'Ordem inválida.';
    if (d.itens.length === 0) return 'Adicione pelo menos um produto ao combo.';
    if (d.itens.some(item => !item.produtoId || !Number.isInteger(item.quantidade) || item.quantidade <= 0)) {
        return 'A composição do combo é inválida.';
    }
    if (new Set(d.itens.map(item => item.produtoId)).size !== d.itens.length) {
        return 'Um produto não pode aparecer mais de uma vez na composição.';
    }
    return null;
}

router.get('/categorias', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    if (!empresaId) return res.status(400).json({ erro: 'empresaId é obrigatório.' });
    try {
        const resultado = await database.query(
            `SELECT id, nome FROM categorias
             WHERE empresa_id = $1 AND ativo = TRUE ORDER BY ordem, nome`,
            [empresaId],
        );
        return res.status(200).json({ categorias: resultado.rows });
    } catch (error) {
        console.error('Erro ao listar categorias para combos:', error);
        return res.status(500).json({ erro: 'Não foi possível listar as categorias.' });
    }
});

router.get('/produtos', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    if (!empresaId) return res.status(400).json({ erro: 'empresaId é obrigatório.' });
    try {
        const resultado = await database.query(
            `SELECT p.id, p.nome, p.preco, c.nome AS categoria_nome
             FROM produtos p
             JOIN categorias c ON c.id = p.categoria_id
             WHERE p.empresa_id = $1 AND p.tipo = 'PRODUTO'
               AND p.ativo = TRUE AND p.disponivel = TRUE
             ORDER BY c.ordem, c.nome, p.ordem, p.nome`,
            [empresaId],
        );
        return res.status(200).json({ produtos: resultado.rows });
    } catch (error) {
        console.error('Erro ao listar produtos para combos:', error);
        return res.status(500).json({ erro: 'Não foi possível listar os produtos.' });
    }
});

router.get('/', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const busca = String(req.query.busca ?? '').trim();
    if (!empresaId) return res.status(400).json({ erro: 'empresaId é obrigatório.' });
    try {
        const resultado = await database.query(
            `SELECT p.id, p.empresa_id, p.categoria_id, c.nome AS categoria_nome,
                    p.nome, p.descricao, p.preco, p.preco_promocional,
                    p.codigo_interno, p.disponivel, p.destaque, p.ordem, p.ativo,
                    COALESCE(SUM(ci.quantidade), 0)::integer AS quantidade_itens,
                    COALESCE(
                        json_agg(json_build_object(
                            'produto_id', item.id,
                            'produto_nome', item.nome,
                            'quantidade', ci.quantidade,
                            'ordem', ci.ordem
                        ) ORDER BY ci.ordem) FILTER (WHERE ci.id IS NOT NULL),
                        '[]'::json
                    ) AS itens
             FROM produtos p
             JOIN categorias c ON c.id = p.categoria_id
             LEFT JOIN combo_itens ci ON ci.combo_id = p.id
             LEFT JOIN produtos item ON item.id = ci.produto_id
             WHERE p.empresa_id = $1 AND p.tipo = 'COMBO'
               AND ($2 = '' OR p.nome ILIKE '%' || $2 || '%'
                    OR COALESCE(p.descricao, '') ILIKE '%' || $2 || '%'
                    OR COALESCE(p.codigo_interno, '') ILIKE '%' || $2 || '%'
                    OR c.nome ILIKE '%' || $2 || '%')
             GROUP BY p.id, c.id
             ORDER BY p.ativo DESC, p.disponivel DESC, c.ordem, p.ordem, p.nome
             LIMIT 200`,
            [empresaId, busca],
        );
        return res.status(200).json({ combos: resultado.rows });
    } catch (error) {
        console.error('Erro ao listar combos:', error);
        return res.status(500).json({
            erro: 'Não foi possível listar os combos.',
            detalhe: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});

async function validarProdutosDaEmpresa(
    client: PoolClient,
    empresaId: string,
    itens: ComboItemEntrada[],
) {
    const ids = itens.map(item => item.produtoId);
    const resultado = await client.query(
        `SELECT COUNT(*)::integer AS total FROM produtos
         WHERE empresa_id = $1 AND tipo = 'PRODUTO' AND id = ANY($2::uuid[])`,
        [empresaId, ids],
    );
    return Number(resultado.rows[0]?.total ?? 0) === ids.length;
}

async function inserirItens(
    client: PoolClient,
    comboId: string,
    itens: ComboItemEntrada[],
) {
    for (const item of itens) {
        await client.query(
            `INSERT INTO combo_itens (combo_id, produto_id, quantidade, ordem)
             VALUES ($1, $2, $3, $4)`,
            [comboId, item.produtoId, item.quantidade, item.ordem],
        );
    }
}

router.post('/', async (req, res) => {
    const d = dadosCombo(req.body, empresaIdAutenticada(req));
    const erro = validarCombo(d, true);
    if (erro) return res.status(400).json({ erro });
    const client = await database.connect();
    try {
        await client.query('BEGIN');
        if (!await validarProdutosDaEmpresa(client, d.empresaId, d.itens)) {
            await client.query('ROLLBACK');
            return res.status(400).json({ erro: 'Há produtos inválidos na composição.' });
        }
        const categoria = await client.query(
            'SELECT 1 FROM categorias WHERE id = $1 AND empresa_id = $2',
            [d.categoriaId, d.empresaId],
        );
        if (!categoria.rowCount) {
            await client.query('ROLLBACK');
            return res.status(400).json({ erro: 'Categoria inválida para a empresa ativa.' });
        }
        const resultado = await client.query(
            `INSERT INTO produtos
                (empresa_id, categoria_id, tipo, nome, descricao, preco,
                 preco_promocional, codigo_interno, disponivel, destaque, ordem, ativo)
             VALUES ($1, $2, 'COMBO', $3, NULLIF($4, ''), $5, $6,
                     NULLIF($7, ''), $8, $9, $10, TRUE)
             RETURNING *`,
            [d.empresaId, d.categoriaId, d.nome, d.descricao, d.preco,
             d.precoPromocional, d.codigoInterno, d.disponivel, d.destaque, d.ordem],
        );
        await inserirItens(client, resultado.rows[0].id, d.itens);
        await client.query('COMMIT');
        return res.status(201).json({ combo: resultado.rows[0] });
    } catch (error: any) {
        await client.query('ROLLBACK');
        console.error('Erro ao cadastrar combo:', error);
        if (error?.code === '23505') {
            return res.status(409).json({ erro: 'Já existe um item com esses dados no combo ou o código está em uso.' });
        }
        if (error?.code === '23503') return res.status(400).json({ erro: 'Categoria ou produto inválido.' });
        return res.status(500).json({ erro: 'Não foi possível cadastrar o combo.' });
    } finally {
        client.release();
    }
});

router.put('/:id', async (req, res) => {
    const comboId = String(req.params.id ?? '').trim();
    const d = dadosCombo(req.body, empresaIdAutenticada(req));
    const erro = validarCombo(d, false);
    if (!comboId) return res.status(400).json({ erro: 'Combo inválido.' });
    if (erro) return res.status(400).json({ erro });
    const client = await database.connect();
    try {
        await client.query('BEGIN');
        const atual = await client.query(
            `SELECT empresa_id FROM produtos
             WHERE id = $1 AND empresa_id = $2 AND tipo = 'COMBO'`,
            [comboId, d.empresaId],
        );
        if (atual.rowCount === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ erro: 'Combo não encontrado.' });
        }
        const empresaId = String(atual.rows[0].empresa_id);
        if (!await validarProdutosDaEmpresa(client, empresaId, d.itens)) {
            await client.query('ROLLBACK');
            return res.status(400).json({ erro: 'Há produtos inválidos na composição.' });
        }
        const categoria = await client.query(
            'SELECT 1 FROM categorias WHERE id = $1 AND empresa_id = $2',
            [d.categoriaId, empresaId],
        );
        if (!categoria.rowCount) {
            await client.query('ROLLBACK');
            return res.status(400).json({ erro: 'Categoria inválida para a empresa ativa.' });
        }
        const resultado = await client.query(
            `UPDATE produtos SET categoria_id = $2, nome = $3,
                 descricao = NULLIF($4, ''), preco = $5, preco_promocional = $6,
                 codigo_interno = NULLIF($7, ''), disponivel = $8,
                 destaque = $9, ordem = $10, atualizado_em = CURRENT_TIMESTAMP
             WHERE id = $1 AND empresa_id = $11 AND tipo = 'COMBO' RETURNING *`,
            [comboId, d.categoriaId, d.nome, d.descricao, d.preco,
             d.precoPromocional, d.codigoInterno, d.disponivel, d.destaque, d.ordem,
             empresaId],
        );
        await client.query('DELETE FROM combo_itens WHERE combo_id = $1', [comboId]);
        await inserirItens(client, comboId, d.itens);
        await client.query('COMMIT');
        return res.status(200).json({ combo: resultado.rows[0] });
    } catch (error: any) {
        await client.query('ROLLBACK');
        console.error('Erro ao editar combo:', error);
        if (error?.code === '23505') return res.status(409).json({ erro: 'Código interno já utilizado.' });
        if (error?.code === '23503') return res.status(400).json({ erro: 'Categoria ou produto inválido.' });
        return res.status(500).json({ erro: 'Não foi possível editar o combo.' });
    } finally {
        client.release();
    }
});

router.patch('/:id/situacao', async (req, res) => {
    const comboId = String(req.params.id ?? '').trim();
    const empresaId = empresaIdAutenticada(req);
    const possuiAtivo = typeof req.body.ativo === 'boolean';
    const possuiDisponivel = typeof req.body.disponivel === 'boolean';
    if (!comboId || (!possuiAtivo && !possuiDisponivel)) {
        return res.status(400).json({ erro: 'Informe o combo e a situação.' });
    }
    try {
        const resultado = await database.query(
            `UPDATE produtos SET ativo = COALESCE($2::boolean, ativo),
                 disponivel = COALESCE($3::boolean, disponivel),
                 atualizado_em = CURRENT_TIMESTAMP
             WHERE id = $1 AND empresa_id = $4 AND tipo = 'COMBO' RETURNING *`,
            [comboId, possuiAtivo ? req.body.ativo : null,
             possuiDisponivel ? req.body.disponivel : null, empresaId],
        );
        if (resultado.rowCount === 0) return res.status(404).json({ erro: 'Combo não encontrado.' });
        return res.status(200).json({ combo: resultado.rows[0] });
    } catch (error) {
        console.error('Erro ao alterar combo:', error);
        return res.status(500).json({ erro: 'Não foi possível alterar o combo.' });
    }
});

export default router;
