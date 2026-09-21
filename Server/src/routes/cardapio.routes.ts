import { Router } from 'express';
import { database } from '../database/connection.js';
import { empresaIdAutenticada } from '../middleware/auth.middleware.js';

const router = Router();

router.get('/categorias', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    if (!empresaId) return res.status(400).json({ erro: 'empresaId é obrigatório.' });
    try {
        const resultado = await database.query(
            `SELECT id, nome FROM categorias
             WHERE empresa_id = $1 AND ativo = TRUE
             ORDER BY ordem, nome`,
            [empresaId],
        );
        return res.status(200).json({ categorias: resultado.rows });
    } catch (error) {
        console.error('Erro ao listar categorias do cardápio:', error);
        return res.status(500).json({ erro: 'Não foi possível listar as categorias.' });
    }
});

router.get('/', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const busca = String(req.query.busca ?? '').trim();
    if (!empresaId) return res.status(400).json({ erro: 'empresaId é obrigatório.' });
    try {
        const resultado = await database.query(
            `SELECT p.id, p.empresa_id, p.categoria_id, c.nome AS categoria_nome,
                    p.tipo, p.nome, p.descricao, p.preco, p.preco_promocional,
                    p.imagem_url, p.codigo_interno, p.disponivel, p.destaque,
                    p.ordem, p.ativo
             FROM produtos p
             JOIN categorias c ON c.id = p.categoria_id
             WHERE p.empresa_id = $1
               AND ($2 = '' OR p.nome ILIKE '%' || $2 || '%'
                    OR COALESCE(p.descricao, '') ILIKE '%' || $2 || '%'
                    OR COALESCE(p.codigo_interno, '') ILIKE '%' || $2 || '%'
                    OR c.nome ILIKE '%' || $2 || '%')
             ORDER BY p.ativo DESC, p.disponivel DESC, c.ordem, p.ordem, p.nome
             LIMIT 300`,
            [empresaId, busca],
        );
        return res.status(200).json({ produtos: resultado.rows });
    } catch (error) {
        console.error('Erro ao listar cardápio administrativo:', error);
        return res.status(500).json({
            erro: 'Não foi possível listar o cardápio.',
            detalhe: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});

function dadosProduto(body: any, empresaId: string) {
    return {
        empresaId,
        categoriaId: String(body.categoriaId ?? '').trim(),
        tipo: String(body.tipo ?? 'PRODUTO').trim().toUpperCase(),
        nome: String(body.nome ?? '').trim(),
        descricao: String(body.descricao ?? '').trim(),
        preco: Number(body.preco ?? 0),
        precoPromocional: body.precoPromocional === '' || body.precoPromocional == null
            ? null : Number(body.precoPromocional),
        imagemUrl: String(body.imagemUrl ?? '').trim(),
        codigoInterno: String(body.codigoInterno ?? '').trim(),
        ordem: Number(body.ordem ?? 0),
        disponivel: typeof body.disponivel === 'boolean' ? body.disponivel : true,
        destaque: typeof body.destaque === 'boolean' ? body.destaque : false,
    };
}

function validarProduto(dados: ReturnType<typeof dadosProduto>, exigeEmpresa: boolean): string | null {
    if (exigeEmpresa && !dados.empresaId) return 'empresaId é obrigatório.';
    if (!dados.categoriaId) return 'Categoria é obrigatória.';
    if (!dados.nome) return 'Nome é obrigatório.';
    if (!['PRODUTO', 'COMBO'].includes(dados.tipo)) return 'Tipo de produto inválido.';
    if (!Number.isFinite(dados.preco) || dados.preco < 0) return 'Preço inválido.';
    if (dados.precoPromocional !== null &&
        (!Number.isFinite(dados.precoPromocional) || dados.precoPromocional < 0)) {
        return 'Preço promocional inválido.';
    }
    if (!Number.isInteger(dados.ordem) || dados.ordem < 0) return 'Ordem inválida.';
    return null;
}

router.post('/', async (req, res) => {
    const d = dadosProduto(req.body, empresaIdAutenticada(req));
    const erro = validarProduto(d, true);
    if (erro) return res.status(400).json({ erro });
    try {
        const categoria = await database.query(
            'SELECT 1 FROM categorias WHERE id = $1 AND empresa_id = $2',
            [d.categoriaId, d.empresaId],
        );
        if (!categoria.rowCount) return res.status(400).json({ erro: 'Categoria inválida para a empresa ativa.' });
        const resultado = await database.query(
            `INSERT INTO produtos
                (empresa_id, categoria_id, tipo, nome, descricao, preco,
                 preco_promocional, imagem_url, codigo_interno, disponivel,
                 destaque, ordem, ativo)
             VALUES ($1, $2, $3::tipo_produto, $4, NULLIF($5, ''), $6, $7,
                     NULLIF($8, ''), NULLIF($9, ''), $10, $11, $12, TRUE)
             RETURNING *`,
            [d.empresaId, d.categoriaId, d.tipo, d.nome, d.descricao, d.preco,
             d.precoPromocional, d.imagemUrl, d.codigoInterno, d.disponivel,
             d.destaque, d.ordem],
        );
        return res.status(201).json({ produto: resultado.rows[0] });
    } catch (error: any) {
        console.error('Erro ao cadastrar produto:', error);
        if (error?.code === '23505') {
            return res.status(409).json({ erro: 'Já existe um produto com esse código interno.' });
        }
        if (error?.code === '23503') {
            return res.status(400).json({ erro: 'Categoria inválida.' });
        }
        return res.status(500).json({ erro: 'Não foi possível cadastrar o produto.' });
    }
});

router.put('/:id', async (req, res) => {
    const produtoId = String(req.params.id ?? '').trim();
    const d = dadosProduto(req.body, empresaIdAutenticada(req));
    const erro = validarProduto(d, false);
    if (!produtoId) return res.status(400).json({ erro: 'Produto inválido.' });
    if (erro) return res.status(400).json({ erro });
    try {
        const categoria = await database.query(
            'SELECT 1 FROM categorias WHERE id = $1 AND empresa_id = $2',
            [d.categoriaId, d.empresaId],
        );
        if (!categoria.rowCount) return res.status(400).json({ erro: 'Categoria inválida para a empresa ativa.' });
        const resultado = await database.query(
            `UPDATE produtos
             SET categoria_id = $2, tipo = $3::tipo_produto, nome = $4,
                 descricao = NULLIF($5, ''), preco = $6, preco_promocional = $7,
                 imagem_url = NULLIF($8, ''), codigo_interno = NULLIF($9, ''),
                 disponivel = $10, destaque = $11, ordem = $12,
                 atualizado_em = CURRENT_TIMESTAMP
             WHERE id = $1 AND empresa_id = $13 RETURNING *`,
            [produtoId, d.categoriaId, d.tipo, d.nome, d.descricao, d.preco,
             d.precoPromocional, d.imagemUrl, d.codigoInterno, d.disponivel,
             d.destaque, d.ordem, d.empresaId],
        );
        if (resultado.rowCount === 0) return res.status(404).json({ erro: 'Produto não encontrado.' });
        return res.status(200).json({ produto: resultado.rows[0] });
    } catch (error: any) {
        console.error('Erro ao editar produto:', error);
        if (error?.code === '23505') return res.status(409).json({ erro: 'Já existe outro produto com esse código interno.' });
        if (error?.code === '23503') return res.status(400).json({ erro: 'Categoria inválida.' });
        return res.status(500).json({ erro: 'Não foi possível editar o produto.' });
    }
});

router.patch('/:id/situacao', async (req, res) => {
    const produtoId = String(req.params.id ?? '').trim();
    const empresaId = empresaIdAutenticada(req);
    const possuiAtivo = typeof req.body.ativo === 'boolean';
    const possuiDisponivel = typeof req.body.disponivel === 'boolean';
    const possuiDestaque = typeof req.body.destaque === 'boolean';
    if (!produtoId || (!possuiAtivo && !possuiDisponivel && !possuiDestaque)) {
        return res.status(400).json({ erro: 'Informe o produto e a situação.' });
    }
    try {
        const resultado = await database.query(
            `UPDATE produtos
             SET ativo = COALESCE($2::boolean, ativo),
                 disponivel = COALESCE($3::boolean, disponivel),
                 destaque = COALESCE($4::boolean, destaque),
                 atualizado_em = CURRENT_TIMESTAMP
             WHERE id = $1 AND empresa_id = $5 RETURNING *`,
            [produtoId, possuiAtivo ? req.body.ativo : null,
             possuiDisponivel ? req.body.disponivel : null,
             possuiDestaque ? req.body.destaque : null, empresaId],
        );
        if (resultado.rowCount === 0) return res.status(404).json({ erro: 'Produto não encontrado.' });
        return res.status(200).json({ produto: resultado.rows[0] });
    } catch (error) {
        console.error('Erro ao alterar situação do produto:', error);
        return res.status(500).json({ erro: 'Não foi possível alterar o produto.' });
    }
});

router.delete('/:id', async (req, res) => {
    const produtoId = String(req.params.id ?? '').trim();
    const empresaId = empresaIdAutenticada(req);
    if (!produtoId || !empresaId) {
        return res.status(400).json({ erro: 'Informe o ID do produto.' });
    }
    try {
        // Tenta exclusão física primeiro; se falhar por integridade (pedidos vinculados), faz exclusão lógica
        try {
            const resultado = await database.query(
                `DELETE FROM produtos WHERE id = $1 AND empresa_id = $2 RETURNING id`,
                [produtoId, empresaId]
            );
            if (resultado.rowCount === 0) {
                return res.status(404).json({ erro: 'Produto não encontrado.' });
            }
            return res.status(200).json({ sucesso: true, mensagem: 'Produto excluído com sucesso.' });
        } catch (delError: any) {
            // Se houver restrição de FK (pedidos, adicionais, etc), inativa o produto
            if (delError?.code === '23503') {
                await database.query(
                    `UPDATE produtos
                     SET ativo = FALSE, disponivel = FALSE, atualizado_em = CURRENT_TIMESTAMP
                     WHERE id = $1 AND empresa_id = $2`,
                    [produtoId, empresaId]
                );
                return res.status(200).json({
                    sucesso: true,
                    mensagem: 'Produto possui histórico de pedidos e foi inativado/removido do cardápio.',
                });
            }
            throw delError;
        }
    } catch (error) {
        console.error('Erro ao excluir produto:', error);
        return res.status(500).json({ erro: 'Não foi possível excluir o produto.' });
    }
});

export default router;

