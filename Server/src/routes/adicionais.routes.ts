import { Router } from 'express';
import { database } from '../database/connection.js';
import { empresaIdAutenticada } from '../middleware/auth.middleware.js';

const router = Router();

router.get('/produtos', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    try {
        const resultado = await database.query(
            `SELECT p.id, p.nome, p.categoria_id, c.nome AS categoria_nome
               FROM produtos p
               JOIN categorias c ON c.id = p.categoria_id
              WHERE p.empresa_id = $1 AND p.ativo = TRUE AND p.tipo = 'PRODUTO'
              ORDER BY c.ordem, c.nome, p.ordem, p.nome`,
            [empresaId],
        );
        return res.json({ produtos: resultado.rows });
    } catch (error) {
        console.error('Erro ao listar produtos para adicionais:', error);
        return res.status(500).json({ erro: 'Não foi possível listar os produtos.' });
    }
});

router.get('/categorias', async (req,res) => {
    const empresaId=empresaIdAutenticada(req);
    const resultado=await database.query(
      `SELECT id,nome FROM categorias WHERE empresa_id=$1 AND ativo=TRUE ORDER BY ordem,nome`,[empresaId]);
    return res.json({categorias:resultado.rows});
});

router.get('/', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const produtoId = String(req.query.produtoId ?? '').trim();
    const busca = String(req.query.busca ?? '').trim();
    try {
        const resultado = await database.query(
            `SELECT a.id, a.produto_id, p.categoria_id, c.nome AS categoria_nome,
                    p.nome AS produto_nome, a.nome, a.preco,
                    a.limite, a.obrigatorio, a.ordem, a.ativo
               FROM produto_adicionais a
               JOIN produtos p ON p.id = a.produto_id
               JOIN categorias c ON c.id = p.categoria_id
              WHERE p.empresa_id = $1
                AND ($2::uuid IS NULL OR a.produto_id = $2::uuid)
                AND ($3 = '' OR a.nome ILIKE '%' || $3 || '%' OR p.nome ILIKE '%' || $3 || '%')
              ORDER BY p.nome, a.ordem, a.nome`,
            [empresaId, produtoId || null, busca],
        );
        return res.json({ adicionais: resultado.rows });
    } catch (error) {
        console.error('Erro ao listar adicionais:', error);
        return res.status(500).json({ erro: 'Não foi possível listar os adicionais.' });
    }
});

router.post('/', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const produtoId = String(req.body.produtoId ?? '').trim();
    const nome = String(req.body.nome ?? '').trim();
    const preco = Number(req.body.preco ?? 0);
    const limite = Number(req.body.limite ?? 1);
    const obrigatorio = Boolean(req.body.obrigatorio ?? false);
    const ordem = Number(req.body.ordem ?? 0);
    if (!produtoId || !nome) return res.status(400).json({ erro: 'Informe o produto e o nome.' });
    if (!Number.isFinite(preco) || preco < 0) return res.status(400).json({ erro: 'Preço inválido.' });
    if (!Number.isInteger(limite) || limite < 1) return res.status(400).json({ erro: 'O limite deve ser maior que zero.' });
    try {
        const resultado = await database.query(
            `INSERT INTO produto_adicionais(produto_id,nome,preco,limite,obrigatorio,ordem,ativo)
             SELECT p.id,$3,$4,$5,$6,$7,TRUE FROM produtos p
              WHERE p.id=$2 AND p.empresa_id=$1
             RETURNING *`,
            [empresaId, produtoId, nome, preco, limite, obrigatorio, ordem],
        );
        if (!resultado.rowCount) return res.status(404).json({ erro: 'Produto não encontrado.' });
        await database.query(
          `INSERT INTO categoria_adicionais(categoria_id,adicional_id)
           SELECT p.categoria_id,$1 FROM produtos p WHERE p.id=$2
           ON CONFLICT DO NOTHING`,[resultado.rows[0].id,produtoId]);
        return res.status(201).json({ adicional: resultado.rows[0] });
    } catch (error: unknown) {
        if ((error as { code?: string }).code === '23505') return res.status(409).json({ erro: 'Este adicional já existe para o produto.' });
        console.error('Erro ao cadastrar adicional:', error);
        return res.status(500).json({ erro: 'Não foi possível cadastrar o adicional.' });
    }
});

router.put('/:id', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const id = String(req.params.id ?? '').trim();
    const produtoId = String(req.body.produtoId ?? '').trim();
    const nome = String(req.body.nome ?? '').trim();
    const preco = Number(req.body.preco ?? 0);
    const limite = Number(req.body.limite ?? 1);
    const obrigatorio = Boolean(req.body.obrigatorio ?? false);
    const ordem = Number(req.body.ordem ?? 0);
    if (!id || !produtoId || !nome) return res.status(400).json({ erro: 'Informe o produto e o nome.' });
    if (!Number.isFinite(preco) || preco < 0 || !Number.isInteger(limite) || limite < 1)
        return res.status(400).json({ erro: 'Preço ou limite inválido.' });
    try {
        const resultado = await database.query(
            `UPDATE produto_adicionais a
                SET produto_id=$3,nome=$4,preco=$5,limite=$6,obrigatorio=$7,ordem=$8
               FROM produtos atual, produtos novo
              WHERE a.id=$2 AND atual.id=a.produto_id AND atual.empresa_id=$1
                AND novo.id=$3 AND novo.empresa_id=$1
             RETURNING a.*`,
            [empresaId, id, produtoId, nome, preco, limite, obrigatorio, ordem],
        );
        if (!resultado.rowCount) return res.status(404).json({ erro: 'Adicional não encontrado.' });
        await database.query('DELETE FROM categoria_adicionais WHERE adicional_id=$1',[id]);
        await database.query(
          `INSERT INTO categoria_adicionais(categoria_id,adicional_id)
           SELECT p.categoria_id,$1 FROM produtos p WHERE p.id=$2`,[id,produtoId]);
        return res.json({ adicional: resultado.rows[0] });
    } catch (error: unknown) {
        if ((error as { code?: string }).code === '23505') return res.status(409).json({ erro: 'Este adicional já existe para o produto.' });
        console.error('Erro ao alterar adicional:', error);
        return res.status(500).json({ erro: 'Não foi possível alterar o adicional.' });
    }
});

router.patch('/:id/situacao', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const id = String(req.params.id ?? '').trim();
    if (!id || typeof req.body.ativo !== 'boolean') return res.status(400).json({ erro: 'Situação inválida.' });
    try {
        const resultado = await database.query(
            `UPDATE produto_adicionais a SET ativo=$3
               FROM produtos p
              WHERE a.id=$2 AND p.id=a.produto_id AND p.empresa_id=$1
             RETURNING a.*`,
            [empresaId, id, req.body.ativo],
        );
        if (!resultado.rowCount) return res.status(404).json({ erro: 'Adicional não encontrado.' });
        return res.json({ adicional: resultado.rows[0] });
    } catch (error) {
        console.error('Erro ao alterar situação do adicional:', error);
        return res.status(500).json({ erro: 'Não foi possível alterar o adicional.' });
    }
});

export default router;
