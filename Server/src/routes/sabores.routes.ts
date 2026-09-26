import { Router } from 'express';
import type { PoolClient } from 'pg';
import { database } from '../database/connection.js';
import { empresaIdAutenticada } from '../middleware/auth.middleware.js';

const router = Router();

type PrecoTamanho = { produtoId: string; valor: number };

function lerCategoriaIds(body: Record<string, unknown>): string[] {
    const valores = Array.isArray(body.categoriaIds)
        ? body.categoriaIds
        : [body.categoriaId];
    return [...new Set(valores.map((id) => String(id ?? '').trim()).filter(Boolean))];
}

async function salvarCategorias(client: PoolClient, tabela: 'categoria_sabores' | 'categoria_bordas',
    coluna: 'sabor_id' | 'borda_id', opcaoId: string, empresaId: string,
    categoriaIds: string[], precos: PrecoTamanho[]): Promise<void> {
    let ids = categoriaIds;
    if (!ids.length && precos.length) {
        const categorias = await client.query(
            `SELECT DISTINCT categoria_id FROM produtos
              WHERE empresa_id=$1 AND id = ANY($2::uuid[])`,
            [empresaId, precos.map((p) => p.produtoId)],
        );
        ids = categorias.rows.map((r) => String(r.categoria_id));
    }
    for (const categoriaId of ids) {
        const resultado = await client.query(
            `INSERT INTO ${tabela}(categoria_id,${coluna})
             SELECT c.id,$2 FROM categorias c WHERE c.id=$1 AND c.empresa_id=$3
             ON CONFLICT DO NOTHING`, [categoriaId, opcaoId, empresaId]);
        if (!resultado.rowCount) throw new Error('Categoria inválida para a empresa selecionada.');
    }
}

function lerPrecosTamanho(body: Record<string, unknown>): PrecoTamanho[] | null {
    if (!Array.isArray(body.precosTamanho)) return null;

    const unicos = new Map<string, number>();
    for (const item of body.precosTamanho) {
        if (!item || typeof item !== 'object') {
            throw new Error('Preço por tamanho inválido.');
        }
        const dados = item as Record<string, unknown>;
        const produtoId = String(dados.produtoId ?? dados.variacaoId ?? '').trim();
        const valor = Number(dados.valor ?? 0);
        if (!produtoId || !Number.isFinite(valor) || valor < 0) {
            throw new Error('Informe valores válidos para todos os tamanhos.');
        }
        unicos.set(produtoId, valor);
    }
    return [...unicos].map(([produtoId, valor]) => ({ produtoId, valor }));
}

async function substituirPrecosTamanho(
    client: PoolClient,
    saborId: string,
    empresaId: string,
    precos: PrecoTamanho[],
    categoriaId = '',
): Promise<void> {
    if (categoriaId) {
        await client.query(
            `DELETE FROM sabor_produto_precos spp USING produtos p
              WHERE spp.sabor_id=$1 AND p.id=spp.produto_id
                AND p.empresa_id=$2 AND p.categoria_id=$3`,
            [saborId, empresaId, categoriaId]);
        await client.query(
            `DELETE FROM produto_sabores ps USING produtos p
              WHERE ps.sabor_id=$1 AND p.id=ps.produto_id
                AND p.empresa_id=$2 AND p.categoria_id=$3`,
            [saborId, empresaId, categoriaId]);
    } else {
        await client.query('DELETE FROM sabor_produto_precos WHERE sabor_id = $1', [saborId]);
        await client.query('DELETE FROM produto_sabores WHERE sabor_id = $1', [saborId]);
    }
    for (const preco of precos) {
        const resultado = await client.query(
            `INSERT INTO sabor_produto_precos (sabor_id, produto_id, valor)
             SELECT $1, p.id, $3
             FROM produtos p
             WHERE p.id = $2 AND p.empresa_id = $4
             ON CONFLICT (sabor_id, produto_id)
             DO UPDATE SET valor = EXCLUDED.valor,
                           atualizado_em = CURRENT_TIMESTAMP`,
            [saborId, preco.produtoId, preco.valor, empresaId],
        );
        if (resultado.rowCount === 0) {
            throw new Error('Um dos tamanhos informados não pertence à empresa selecionada.');
        }
        await client.query(
            `INSERT INTO produto_sabores (produto_id, sabor_id, ativo, ordem)
             SELECT $1, $2, TRUE, s.ordem FROM sabores s WHERE s.id = $2
             ON CONFLICT (produto_id, sabor_id)
             DO UPDATE SET ativo = TRUE, ordem = EXCLUDED.ordem`,
            [preco.produtoId, saborId],
        );
    }
}

router.get('/', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const busca = String(req.query.busca ?? '').trim();
    if (!empresaId) return res.status(400).json({ erro: 'empresaId é obrigatório.' });

    try {
        const resultado = await database.query(
            `
            SELECT s.id, s.empresa_id, s.nome, s.descricao,
                   s.valor_adicional, s.ordem, s.ativo,
                   COALESCE((SELECT jsonb_agg(cs.categoria_id)
                     FROM categoria_sabores cs WHERE cs.sabor_id=s.id),'[]'::jsonb) AS categoria_ids,
                   (SELECT COUNT(*)::integer
                      FROM produto_sabores ps
                     WHERE ps.sabor_id = s.id AND ps.ativo = TRUE)
                       AS quantidade_produtos,
                   COALESCE((
                     SELECT jsonb_agg(jsonb_build_object(
                       'produto_id', p.id,
                       'produto_nome', p.nome,
                       'valor', spp.valor
                     ) ORDER BY p.ordem, p.nome)
                     FROM sabor_produto_precos spp
                     JOIN produtos p ON p.id = spp.produto_id
                     WHERE spp.sabor_id = s.id
                       AND p.empresa_id = s.empresa_id
                   ), '[]'::jsonb) AS precos_tamanho
            FROM sabores s
            WHERE s.empresa_id = $1
              AND ($2 = '' OR s.nome ILIKE '%' || $2 || '%'
                   OR COALESCE(s.descricao, '') ILIKE '%' || $2 || '%')
            ORDER BY s.ativo DESC, s.ordem, s.nome
            LIMIT 200
            `,
            [empresaId, busca],
        );
        return res.status(200).json({ sabores: resultado.rows });
    } catch (error) {
        console.error('Erro ao listar sabores:', error);
        return res.status(500).json({
            erro: 'Não foi possível listar os sabores.',
            detalhe: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});

router.get('/tamanhos', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    if (!empresaId) return res.status(400).json({ erro: 'empresaId é obrigatório.' });

    try {
        const resultado = await database.query(
            `SELECT p.id, p.nome, p.ordem, c.id AS categoria_id,
                    p.id AS produto_id, p.nome AS produto_nome,
                    c.nome || ' - ' || p.nome AS descricao
             FROM produtos p
             JOIN categorias c ON c.id = p.categoria_id
             WHERE p.empresa_id = $1
               AND p.ativo = TRUE
               AND p.tipo='PRODUTO'
             ORDER BY c.ordem, c.nome, p.ordem, p.nome`,
            [empresaId],
        );
        return res.status(200).json({ tamanhos: resultado.rows });
    } catch (error) {
        console.error('Erro ao listar tamanhos dos sabores:', error);
        return res.status(500).json({
            erro: 'Não foi possível listar os tamanhos.',
            detalhe: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});

router.get('/categorias', async (req,res) => {
    const empresaId=empresaIdAutenticada(req);
    const resultado=await database.query(
      `SELECT id,nome FROM categorias WHERE empresa_id=$1 AND ativo=TRUE ORDER BY ordem,nome`,
      [empresaId]);
    return res.json({categorias:resultado.rows});
});

router.get('/bordas/produtos', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    if (!empresaId) return res.status(400).json({ erro: 'empresaId é obrigatório.' });
    const resultado = await database.query(
        `SELECT p.id, p.nome, c.id AS categoria_id, c.nome || ' - ' || p.nome AS descricao
         FROM produtos p JOIN categorias c ON c.id = p.categoria_id
         WHERE p.empresa_id = $1 AND p.ativo = TRUE AND p.tipo='PRODUTO'
         ORDER BY c.ordem,c.nome,p.ordem,p.nome`, [empresaId]);
    return res.json({ tamanhos: resultado.rows });
});

router.get('/bordas', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const busca = String(req.query.busca ?? '').trim();
    if (!empresaId) return res.status(400).json({ erro: 'empresaId é obrigatório.' });
    const resultado = await database.query(
        `SELECT b.id, b.nome, ''::text AS descricao, b.valor AS valor_adicional,
                b.ordem, b.ativo,
                COALESCE((SELECT jsonb_agg(cb.categoria_id)
                  FROM categoria_bordas cb WHERE cb.borda_id=b.id),'[]'::jsonb) AS categoria_ids,
                (SELECT COUNT(*)::integer FROM produto_bordas pb
                  WHERE pb.borda_id=b.id AND pb.ativo=TRUE) AS quantidade_produtos,
                COALESCE((SELECT jsonb_agg(jsonb_build_object(
                    'produto_id',p.id,'produto_nome',p.nome,'valor',bpp.valor)
                    ORDER BY p.ordem,p.nome)
                  FROM borda_produto_precos bpp JOIN produtos p ON p.id=bpp.produto_id
                  WHERE bpp.borda_id=b.id), '[]'::jsonb) AS precos_tamanho
         FROM bordas b WHERE b.empresa_id=$1
           AND ($2='' OR b.nome ILIKE '%'||$2||'%')
         ORDER BY b.ativo DESC,b.ordem,b.nome`, [empresaId, busca]);
    return res.json({ bordas: resultado.rows, sabores: resultado.rows });
});

async function salvarPrecosBorda(client: PoolClient, bordaId: string,
    empresaId: string, precos: PrecoTamanho[], categoriaId = ''): Promise<void> {
    if (categoriaId) {
        await client.query(
          `DELETE FROM borda_produto_precos bpp USING produtos p
            WHERE bpp.borda_id=$1 AND p.id=bpp.produto_id
              AND p.empresa_id=$2 AND p.categoria_id=$3`,[bordaId,empresaId,categoriaId]);
        await client.query(
          `DELETE FROM produto_bordas pb USING produtos p
            WHERE pb.borda_id=$1 AND p.id=pb.produto_id
              AND p.empresa_id=$2 AND p.categoria_id=$3`,[bordaId,empresaId,categoriaId]);
    } else {
        await client.query('DELETE FROM borda_produto_precos WHERE borda_id=$1', [bordaId]);
        await client.query('DELETE FROM produto_bordas WHERE borda_id=$1', [bordaId]);
    }
    for (const preco of precos) {
        const r = await client.query(
            `INSERT INTO borda_produto_precos(borda_id,produto_id,valor)
             SELECT $1,p.id,$3 FROM produtos p WHERE p.id=$2 AND p.empresa_id=$4
             ON CONFLICT(borda_id,produto_id) DO UPDATE SET valor=EXCLUDED.valor,
             atualizado_em=CURRENT_TIMESTAMP`, [bordaId, preco.produtoId, preco.valor, empresaId]);
        if (!r.rowCount) throw new Error('Produto inválido para a borda.');
        await client.query(
            `INSERT INTO produto_bordas(produto_id,borda_id,ativo,ordem)
             SELECT $1,$2,TRUE,b.ordem FROM bordas b WHERE b.id=$2
             ON CONFLICT(produto_id,borda_id) DO UPDATE SET ativo=TRUE,ordem=EXCLUDED.ordem`,
            [preco.produtoId, bordaId]);
    }
}

router.post('/bordas', async (req, res) => {
    const empresaId=empresaIdAutenticada(req); const nome=String(req.body.nome??'').trim();
    const ordem=Number(req.body.ordem??0); const precos=lerPrecosTamanho(req.body)??[];
    const categoriaIds=lerCategoriaIds(req.body);
    if(!empresaId||!nome) return res.status(400).json({erro:'Nome é obrigatório.'});
    const client=await database.connect();
    try { await client.query('BEGIN'); const r=await client.query(
        `INSERT INTO bordas(empresa_id,nome,valor,ordem,ativo) VALUES($1,$2,$3,$4,TRUE) RETURNING *`,
        [empresaId,nome,precos[0]?.valor??0,ordem]);
      await salvarPrecosBorda(client,r.rows[0].id,empresaId,precos,categoriaIds[0]??'');
      await salvarCategorias(client,'categoria_bordas','borda_id',r.rows[0].id,empresaId,categoriaIds,precos);
      await client.query('COMMIT');
      return res.status(201).json({borda:r.rows[0]});
    } catch(e){await client.query('ROLLBACK'); return res.status(500).json({erro:e instanceof Error?e.message:'Erro ao salvar borda.'});}
    finally{client.release();}
});

router.put('/bordas/:id', async (req,res)=>{
    const empresaId=empresaIdAutenticada(req); const id=String(req.params.id); const nome=String(req.body.nome??'').trim();
    const ordem=Number(req.body.ordem??0); const precos=lerPrecosTamanho(req.body)??[];
    const categoriaIds=lerCategoriaIds(req.body);
    const client=await database.connect(); try{await client.query('BEGIN'); const r=await client.query(
      `UPDATE bordas SET nome=$2,valor=$3,ordem=$4,atualizado_em=CURRENT_TIMESTAMP
       WHERE id=$1 AND empresa_id=$5 RETURNING *`,[id,nome,precos[0]?.valor??0,ordem,empresaId]);
      if(!r.rowCount){await client.query('ROLLBACK');return res.status(404).json({erro:'Borda não encontrada.'});}
      const substituirCategorias = req.body.substituirCategorias === true;
      await salvarPrecosBorda(client,id,empresaId,precos,
        substituirCategorias ? '' : (categoriaIds[0]??''));
      if(substituirCategorias) {
        await client.query('DELETE FROM categoria_bordas WHERE borda_id=$1',[id]);
      }
      await salvarCategorias(client,'categoria_bordas','borda_id',id,empresaId,categoriaIds,precos);
      await client.query('COMMIT');return res.json({borda:r.rows[0]});
    }catch(e){await client.query('ROLLBACK');return res.status(500).json({erro:e instanceof Error?e.message:'Erro ao salvar borda.'});}
    finally{client.release();}
});

router.patch('/bordas/:id/situacao',async(req,res)=>{
 const empresaId=empresaIdAutenticada(req);const r=await database.query(
  `UPDATE bordas SET ativo=$3,atualizado_em=CURRENT_TIMESTAMP WHERE id=$1 AND empresa_id=$2 RETURNING *`,
  [req.params.id,empresaId,Boolean(req.body.ativo)]);
 return r.rowCount?res.json({borda:r.rows[0]}):res.status(404).json({erro:'Borda não encontrada.'});
});

router.post('/', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const nome = String(req.body.nome ?? '').trim();
    const descricao = String(req.body.descricao ?? '').trim();
    const valorAdicional = Number(req.body.valorAdicional ?? 0);
    const ordem = Number(req.body.ordem ?? 0);
    const categoriaIds = lerCategoriaIds(req.body as Record<string, unknown>);
    let precosTamanho: PrecoTamanho[] | null;
    try {
        precosTamanho = lerPrecosTamanho(req.body as Record<string, unknown>);
    } catch (error) {
        return res.status(400).json({ erro: error instanceof Error ? error.message : 'Preços inválidos.' });
    }
    if (!empresaId) return res.status(400).json({ erro: 'empresaId é obrigatório.' });
    if (!nome) return res.status(400).json({ erro: 'Nome é obrigatório.' });
    if (!Number.isFinite(valorAdicional) || valorAdicional < 0) {
        return res.status(400).json({ erro: 'Valor adicional deve ser maior ou igual a zero.' });
    }
    if (!Number.isInteger(ordem) || ordem < 0) {
        return res.status(400).json({ erro: 'Ordem deve ser um número inteiro maior ou igual a zero.' });
    }

    try {
        const duplicado = await database.query(
            'SELECT 1 FROM sabores WHERE empresa_id = $1 AND LOWER(nome) = LOWER($2) LIMIT 1',
            [empresaId, nome],
        );
        if ((duplicado.rowCount ?? 0) > 0) {
            return res.status(409).json({ erro: 'Já existe um sabor com esse nome.' });
        }
        const client = await database.connect();
        try {
          await client.query('BEGIN');
          const resultado = await client.query(
            `INSERT INTO sabores
                (empresa_id, nome, descricao, valor_adicional, ordem, ativo)
             VALUES ($1, $2, NULLIF($3, ''), $4, $5, TRUE)
             RETURNING id, empresa_id, nome, descricao, valor_adicional,
                       ordem, ativo, criado_em, atualizado_em`,
            [empresaId, nome, descricao, valorAdicional, ordem],
          );
          if (precosTamanho) {
              await substituirPrecosTamanho(client, resultado.rows[0].id, empresaId,
                  precosTamanho, categoriaIds[0] ?? '');
          }
          await salvarCategorias(client, 'categoria_sabores', 'sabor_id',
              resultado.rows[0].id, empresaId, categoriaIds, precosTamanho ?? []);
          await client.query('COMMIT');
          return res.status(201).json({ sabor: resultado.rows[0] });
        } catch (error) {
          await client.query('ROLLBACK');
          throw error;
        } finally {
          client.release();
        }
    } catch (error) {
        console.error('Erro ao cadastrar sabor:', error);
        return res.status(500).json({
            erro: 'Não foi possível cadastrar o sabor.',
            detalhe: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});

router.put('/:id', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const saborId = String(req.params.id ?? '').trim();
    const nome = String(req.body.nome ?? '').trim();
    const descricao = String(req.body.descricao ?? '').trim();
    const valorAdicional = Number(req.body.valorAdicional ?? 0);
    const ordem = Number(req.body.ordem ?? 0);
    const categoriaIds = lerCategoriaIds(req.body as Record<string, unknown>);
    let precosTamanho: PrecoTamanho[] | null;
    try {
        precosTamanho = lerPrecosTamanho(req.body as Record<string, unknown>);
    } catch (error) {
        return res.status(400).json({ erro: error instanceof Error ? error.message : 'Preços inválidos.' });
    }
    if (!saborId) return res.status(400).json({ erro: 'Sabor inválido.' });
    if (!nome) return res.status(400).json({ erro: 'Nome é obrigatório.' });
    if (!Number.isFinite(valorAdicional) || valorAdicional < 0) {
        return res.status(400).json({ erro: 'Valor adicional deve ser maior ou igual a zero.' });
    }
    if (!Number.isInteger(ordem) || ordem < 0) {
        return res.status(400).json({ erro: 'Ordem deve ser um número inteiro maior ou igual a zero.' });
    }

    try {
        const duplicado = await database.query(
            `SELECT 1 FROM sabores atual
             JOIN sabores outro ON outro.empresa_id = atual.empresa_id
              AND LOWER(outro.nome) = LOWER($2) AND outro.id <> atual.id
             WHERE atual.id = $1 AND atual.empresa_id = $3 LIMIT 1`,
            [saborId, nome, empresaId],
        );
        if ((duplicado.rowCount ?? 0) > 0) {
            return res.status(409).json({ erro: 'Já existe outro sabor com esse nome.' });
        }
        const client = await database.connect();
        try {
          await client.query('BEGIN');
          const resultado = await client.query(
            `UPDATE sabores
             SET nome = $2, descricao = NULLIF($3, ''), valor_adicional = $4,
                 ordem = $5, atualizado_em = CURRENT_TIMESTAMP
             WHERE id = $1 AND empresa_id = $6
             RETURNING id, empresa_id, nome, descricao, valor_adicional,
                       ordem, ativo, criado_em, atualizado_em`,
            [saborId, nome, descricao, valorAdicional, ordem, empresaId],
          );
          if (resultado.rowCount === 0) {
              await client.query('ROLLBACK');
              return res.status(404).json({ erro: 'Sabor não encontrado.' });
          }
          const substituirCategorias = req.body.substituirCategorias === true;
          if (precosTamanho) {
              await substituirPrecosTamanho(client, saborId, empresaId,
                  precosTamanho, substituirCategorias ? '' : (categoriaIds[0] ?? ''));
          }
          if (substituirCategorias) {
              await client.query('DELETE FROM categoria_sabores WHERE sabor_id=$1', [saborId]);
          }
          await salvarCategorias(client, 'categoria_sabores', 'sabor_id',
              saborId, empresaId, categoriaIds, precosTamanho ?? []);
          await client.query('COMMIT');
          return res.status(200).json({ sabor: resultado.rows[0] });
        } catch (error) {
          await client.query('ROLLBACK');
          throw error;
        } finally {
          client.release();
        }
    } catch (error) {
        console.error('Erro ao editar sabor:', error);
        return res.status(500).json({
            erro: 'Não foi possível editar o sabor.',
            detalhe: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});

router.patch('/:id/situacao', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const saborId = String(req.params.id ?? '').trim();
    if (!saborId || typeof req.body.ativo !== 'boolean') {
        return res.status(400).json({ erro: 'Informe um sabor e a situação.' });
    }
    try {
        const resultado = await database.query(
            `UPDATE sabores SET ativo = $2, atualizado_em = CURRENT_TIMESTAMP
             WHERE id = $1 AND empresa_id = $3
             RETURNING id, empresa_id, nome, descricao, valor_adicional,
                       ordem, ativo, criado_em, atualizado_em`,
            [saborId, req.body.ativo, empresaId],
        );
        if (resultado.rowCount === 0) {
            return res.status(404).json({ erro: 'Sabor não encontrado.' });
        }
        return res.status(200).json({ sabor: resultado.rows[0] });
    } catch (error) {
        console.error('Erro ao alterar situação do sabor:', error);
        return res.status(500).json({
            erro: 'Não foi possível alterar o sabor.',
            detalhe: error instanceof Error ? error.message : 'Erro desconhecido',
        });
    }
});

export default router;
