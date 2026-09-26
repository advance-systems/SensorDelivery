import { Router } from 'express';
import { database } from '../database/connection.js';

const router = Router();

async function empresaPublica(req: { query: Record<string, unknown> }): Promise<string> {
    const direct = String(req.query.empresaId ?? '').trim();
    if (direct) return direct;
    try {
        const first = await database.query('SELECT id FROM empresas WHERE ativo = TRUE ORDER BY id ASC LIMIT 1');
        return first.rows.length > 0 ? String(first.rows[0].id) : '';
    } catch {
        return '';
    }
}

async function produtoDaEmpresa(produtoId: string, empresaId: string): Promise<boolean> {
    const resultado = await database.query(
        'SELECT 1 FROM produtos WHERE id = $1 AND empresa_id = $2 AND ativo = TRUE',
        [produtoId, empresaId],
    );
    return Boolean(resultado.rowCount);
}

router.get('/', async (req, res) => {
    const empresaId = await empresaPublica(req);
    const categoriaId = String(req.query.categoriaId ?? '').trim();
    if (!empresaId) return res.status(400).json({ erro: 'empresaId é obrigatório.' });
    try {
        const resultado = await database.query(
            `
            SELECT
                p.id,
                p.categoria_id,
                c.nome AS categoria_nome,
                p.tipo,
                p.nome,
                p.descricao,
                p.preco,
                p.preco_promocional,
                p.imagem_url,
                p.codigo_interno,
                p.disponivel,
                p.destaque,
                p.ordem
            FROM produtos p
            LEFT JOIN categorias c ON c.id = p.categoria_id
            WHERE p.empresa_id = $1
              AND p.ativo = true
              AND p.disponivel = true
              AND ($2 = '' OR $2 = 'all' OR p.categoria_id::text = $2)
            ORDER BY
                p.destaque DESC,
                c.ordem ASC,
                p.ordem ASC,
                p.nome ASC
            `,
            [empresaId, categoriaId],
        );

        return res.status(200).json({
            produtos: resultado.rows,
        });

    } catch (error) {
        console.error('Erro ao listar produtos:', error);

        const mensagem =
            error instanceof Error
                ? error.message
                : 'Erro desconhecido';

        return res.status(500).json({
            erro: 'Não foi possível listar os produtos.',
            detalhe: mensagem,
        });
    }
});

router.get('/categorias/lista', async (req, res) => {
    const empresaId = await empresaPublica(req);
    if (!empresaId) return res.status(400).json({ erro: 'empresaId é obrigatório.' });
    try {
        const resultado = await database.query(
            `SELECT c.id, c.nome, c.imagem_url, c.ordem
             FROM categorias c
             WHERE c.empresa_id = $1
               AND c.ativo = TRUE
             ORDER BY c.ordem, c.nome`,
            [empresaId],
        );
        return res.status(200).json({ categorias: resultado.rows });
    } catch (error) {
        console.error('Erro ao listar categorias dos produtos:', error);
        return res.status(500).json({ erro: 'Não foi possível listar as categorias.' });
    }
});

router.get('/:id', async (req, res) => {
    const produtoId = String(req.params.id ?? '').trim();
    const empresaId = await empresaPublica(req);

    if (!produtoId || !empresaId) {
        return res.status(400).json({
            erro: 'Produto inválido.',
        });
    }

    try {
        const resultado = await database.query(
            `
            SELECT
                p.id,
                p.categoria_id,
                p.tipo,
                p.nome,
                p.descricao,
                p.preco,
                p.preco_promocional,
                p.imagem_url,
                p.codigo_interno,
                p.disponivel,
                p.destaque,
                p.ordem
            FROM produtos p
            WHERE p.id = $1 AND p.empresa_id = $2
              AND p.ativo = true
            LIMIT 1
            `,
            [produtoId, empresaId]
        );

        if (resultado.rowCount === 0) {
            return res.status(404).json({
                erro: 'Produto não encontrado.',
            });
        }

        return res.status(200).json({
            produto: resultado.rows[0],
        });

    } catch (error) {
        console.error('Erro ao consultar produto:', error);

        const mensagem =
            error instanceof Error
                ? error.message
                : 'Erro desconhecido';

        return res.status(500).json({
            erro: 'Não foi possível consultar o produto.',
            detalhe: mensagem,
        });
    }
});

router.get('/:id/opcoes', async (req, res) => {
    const produtoId = String(req.params.id ?? '').trim();
    const empresaId = await empresaPublica(req);

    if (!produtoId || !empresaId) {
        return res.status(400).json({
            erro: 'Produto inválido.',
        });
    }

    try {
        if (!await produtoDaEmpresa(produtoId, empresaId)) {
            return res.status(404).json({ erro: 'Produto não encontrado.' });
        }
        const variacoes = await database.query(
            `
            SELECT
                id,
                nome,
                preco,
                ordem
            FROM produto_variacoes
            WHERE produto_id = $1
              AND ativo = true
              AND disponivel = true
            ORDER BY ordem, nome
            `,
            [produtoId]
        );

        const adicionais = await database.query(
            `
            SELECT
                id,
                nome,
                preco,
                limite,
                obrigatorio,
                ordem
            FROM produto_adicionais
            WHERE produto_id = $1
              AND ativo = true
            ORDER BY ordem, nome
            `,
            [produtoId]
        );

        const sabores = await database.query(
            `
            SELECT
                s.id,
                s.nome,
                s.descricao,
                COALESCE(spp.valor, s.valor_adicional) AS valor_adicional,
                ps.ordem,
                '[]'::jsonb AS precos_tamanho
            FROM produto_sabores ps
            JOIN sabores s
              ON s.id = ps.sabor_id
            LEFT JOIN sabor_produto_precos spp
              ON spp.sabor_id = s.id AND spp.produto_id = ps.produto_id
            WHERE ps.produto_id = $1
              AND ps.ativo = true
              AND s.ativo = true
            ORDER BY ps.ordem, s.nome
            `,
            [produtoId]
        );

        const bordas = await database.query(
            `
      SELECT
        b.id,
        b.nome,
        COALESCE(bpp.valor, b.valor) AS valor,
        pb.ordem
    FROM produto_bordas pb
    JOIN bordas b
      ON b.id = pb.borda_id
    LEFT JOIN borda_produto_precos bpp
      ON bpp.borda_id = b.id AND bpp.produto_id = pb.produto_id
    WHERE pb.produto_id = $1
      AND pb.ativo = true
      AND b.ativo = true
    ORDER BY pb.ordem, b.nome
    `,
            [produtoId]
        );

        const produtoRes = await database.query(
            'SELECT id, nome, preco, preco_promocional FROM produtos WHERE id = $1',
            [produtoId]
        );
        const precoPadrao = produtoRes.rows.length > 0
            ? Number(produtoRes.rows[0].preco_promocional && Number(produtoRes.rows[0].preco_promocional) > 0 ? produtoRes.rows[0].preco_promocional : produtoRes.rows[0].preco || 0)
            : 0;

        return res.status(200).json({
            variacoes: (variacoes.rows && variacoes.rows.length > 0) ? variacoes.rows : [{ id: produtoId, nome: 'Tamanho Padrão', preco: precoPadrao, max_sabores: 2 }],
            sabores: sabores.rows,
            bordas: bordas.rows,
            adicionais: adicionais.rows,
        });

    } catch (error) {
        console.error(
            'Erro ao carregar opções do produto:',
            error
        );

        const mensagem =
            error instanceof Error
                ? error.message
                : 'Erro desconhecido';

        return res.status(500).json({
            erro: 'Não foi possível carregar as opções do produto.',
            detalhe: mensagem,
        });
    }
});

router.get('/:id/variacoes', async (req, res) => {
    const produtoId = String(req.params.id ?? '').trim();
    const empresaId = await empresaPublica(req);

    if (!produtoId || !empresaId) {
        return res.status(400).json({
            erro: 'Produto inválido.',
        });
    }

    try {
        if (!await produtoDaEmpresa(produtoId, empresaId)) {
            return res.status(404).json({ erro: 'Produto não encontrado.' });
        }
        const resultado = await database.query(
            `
            SELECT
                v.id,
                v.produto_id,
                v.nome,
                v.preco,
                v.ordem
            FROM produto_variacoes v
            WHERE v.produto_id = $1
              AND v.ativo = true
              AND v.disponivel = true
            ORDER BY v.ordem, v.nome
            `,
            [produtoId]
        );

        return res.status(200).json({
            variacoes: resultado.rows,
        });
    } catch (error) {
        console.error('Erro ao listar variações:', error);

        const mensagem =
            error instanceof Error
                ? error.message
                : 'Erro desconhecido';

        return res.status(500).json({
            erro: 'Não foi possível listar as variações.',
            detalhe: mensagem,
        });
    }
});

export default router;
