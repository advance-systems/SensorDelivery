import fs from 'fs';
import path from 'path';
import { database } from '../database/connection.js';

export async function importarCardapioAnotaAi(): Promise<void> {
  const client = await database.connect();

  try {
    const jsonPaths = [
      path.resolve(process.cwd(), 'cardapio_completo.json'),
      path.resolve(process.cwd(), '..', 'cardapio_completo.json'),
      'H:/Projetos/SensorDelivery/cardapio_completo.json',
    ];

    let rawData = '';
    for (const p of jsonPaths) {
      if (fs.existsSync(p)) {
        rawData = fs.readFileSync(p, 'utf8');
        console.log(`[Importação] Arquivo encontrado em: ${p}`);
        break;
      }
    }

    if (!rawData) {
      throw new Error('Arquivo cardapio_completo.json não foi localizado.');
    }

    const data = JSON.parse(rawData);

    // 1. Obter a empresa principal
    const empresaRes = await client.query('SELECT id, nome_fantasia FROM empresas LIMIT 1');
    if (empresaRes.rowCount === 0) {
      throw new Error('Nenhuma empresa encontrada no banco de dados. Execute os seeds primeiro.');
    }
    const empresaId = empresaRes.rows[0].id;
    console.log(`\nImportando para Empresa: ${empresaRes.rows[0].nome_fantasia} (${empresaId})`);

    const categories = data.menu?.menu?.menu || [];
    const gruposAuxiliares = data.menu?.menu?.menu_aux || [];

    console.log(`Total de Categorias a processar: ${categories.length}`);
    console.log(`Total de Grupos Auxiliares (Sabores/Adicionais/Bordas): ${gruposAuxiliares.length}\n`);

    await client.query('BEGIN');

    let totalCategoriasInseridas = 0;
    let totalCategoriasAtualizadas = 0;
    let totalProdutosInseridos = 0;
    let totalProdutosAtualizados = 0;
    let totalSaboresInseridos = 0;
    let totalBordasInseridas = 0;
    let totalAdicionaisInseridos = 0;
    let totalVariacoesInseridas = 0;

    // Mapa de Categoria Nome -> ID no banco
    const mapCategorias = new Map<string, string>();
    const produtosCriados: { id: string; nome: string; catId: string; catNome: string }[] = [];

    // Tabela de precos padrao / fallback para tamanhos de pizza se vier 0
    const precosTamanhosPizza: Record<string, { preco: number; fatias: number; maxSabores: number; sigla: string }> = {
      'pequena': { preco: 35.0, fatias: 4, maxSabores: 2, sigla: 'P' },
      'pequena 25cm': { preco: 35.0, fatias: 4, maxSabores: 2, sigla: 'P' },
      'média': { preco: 48.0, fatias: 6, maxSabores: 2, sigla: 'M' },
      'media': { preco: 48.0, fatias: 6, maxSabores: 2, sigla: 'M' },
      'média 30cm': { preco: 48.0, fatias: 6, maxSabores: 2, sigla: 'M' },
      'media 30cm': { preco: 48.0, fatias: 6, maxSabores: 2, sigla: 'M' },
      'grande': { preco: 62.0, fatias: 8, maxSabores: 3, sigla: 'G' },
      'grande 35cm': { preco: 62.0, fatias: 8, maxSabores: 3, sigla: 'G' },
      'familia': { preco: 78.0, fatias: 12, maxSabores: 4, sigla: 'GG' },
      'família': { preco: 78.0, fatias: 12, maxSabores: 4, sigla: 'GG' },
      'famiia 40cm': { preco: 78.0, fatias: 12, maxSabores: 4, sigla: 'GG' },
      'gigante': { preco: 92.0, fatias: 16, maxSabores: 4, sigla: 'XG' },
      'gigante 45cm': { preco: 92.0, fatias: 16, maxSabores: 4, sigla: 'XG' },
    };

    // 2. Processar e Inserir Categorias
    for (let cIdx = 0; cIdx < categories.length; cIdx++) {
      const cat = categories[cIdx];
      const nomeCat = String(cat.title || cat.name || `Categoria ${cIdx + 1}`).trim();
      const descCat = String(cat.description || cat.desc || '').trim();
      const imagemCat = String(cat.image || cat.photo || '').trim();
      const ordemCat = cIdx + 1;

      const catExistente = await client.query(
        'SELECT id FROM categorias WHERE empresa_id = $1 AND nome ILIKE $2',
        [empresaId, nomeCat]
      );

      let catId: string;
      if (catExistente.rowCount && catExistente.rowCount > 0) {
        catId = catExistente.rows[0].id;
        await client.query(
          `UPDATE categorias
              SET ordem = $1, descricao = COALESCE(NULLIF($2, ''), descricao),
                  imagem_url = COALESCE(NULLIF($3, ''), imagem_url), ativo = TRUE
            WHERE id = $4`,
          [ordemCat, descCat, imagemCat, catId]
        );
        totalCategoriasAtualizadas++;
      } else {
        const novaCat = await client.query(
          `INSERT INTO categorias (empresa_id, nome, descricao, imagem_url, ordem, ativo)
           VALUES ($1, $2, $3, $4, $5, TRUE)
           RETURNING id`,
          [empresaId, nomeCat, descCat || null, imagemCat || null, ordemCat]
        );
        catId = novaCat.rows[0].id;
        totalCategoriasInseridas++;
      }

      mapCategorias.set(nomeCat, catId);

      // 3. Processar Itens / Produtos da Categoria
      const itens = cat.itens || cat.items || [];
      for (let pIdx = 0; pIdx < itens.length; pIdx++) {
        const item = itens[pIdx];
        const nomeProd = String(item.title || item.name || '').trim();
        const descProd = String(item.description || item.desc || '').trim();
        let precoProd = item.price !== undefined ? Number(item.price) : 0;
        const imagemProd = String(item.image || item.photo || '').trim();
        const disponivel = !item.paused;
        const ordemProd = pIdx + 1;
        const tipoProd = cat.type === 'combo' || nomeProd.toLowerCase().startsWith('combo') ? 'COMBO' : 'PRODUTO';

        if (!nomeProd) continue;

        // Se o preço for 0 e for pizza, busca se há minimal_price ou fallback
        if (precoProd === 0) {
          const nomeLower = nomeProd.toLowerCase();
          for (const [key, val] of Object.entries(precosTamanhosPizza)) {
            if (nomeLower.includes(key)) {
              precoProd = val.preco;
              break;
            }
          }
          if (precoProd === 0 && item.minimal_price) {
            precoProd = Number(item.minimal_price);
          }
        }

        const prodExistente = await client.query(
          'SELECT id FROM produtos WHERE empresa_id = $1 AND categoria_id = $2 AND nome ILIKE $3',
          [empresaId, catId, nomeProd]
        );

        let prodId: string;
        if (prodExistente.rowCount && prodExistente.rowCount > 0) {
          prodId = prodExistente.rows[0].id;
          await client.query(
            `UPDATE produtos
                SET descricao = $1, preco = $2, imagem_url = COALESCE(NULLIF($3, ''), imagem_url),
                    disponivel = $4, ordem = $5, ativo = TRUE
              WHERE id = $6`,
            [descProd || null, precoProd, imagemProd, disponivel, ordemProd, prodId]
          );
          totalProdutosAtualizados++;
        } else {
          const novoProd = await client.query(
            `INSERT INTO produtos
               (empresa_id, categoria_id, tipo, nome, descricao, preco, imagem_url, disponivel, ordem, ativo)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, TRUE)
             RETURNING id`,
            [empresaId, catId, tipoProd, nomeProd, descProd || null, precoProd, imagemProd || null, disponivel, ordemProd]
          );
          prodId = novoProd.rows[0].id;
          totalProdutosInseridos++;
        }

        produtosCriados.push({ id: prodId, nome: nomeProd, catId, catNome: nomeCat });

        // Se for pizza, criar as variações de tamanho para o produto
        const ehPizza = nomeCat.toLowerCase().includes('pizza') || nomeProd.toLowerCase().includes('pizza') || nomeProd.toLowerCase().includes('cm');
        if (ehPizza) {
          // Criar a própria variação correspondente ao tamanho do produto
          const nomeLower = nomeProd.toLowerCase();
          let fatias = 8;
          let maxSabores = 2;
          for (const [k, v] of Object.entries(precosTamanhosPizza)) {
            if (nomeLower.includes(k)) {
              fatias = v.fatias;
              maxSabores = v.maxSabores;
              break;
            }
          }

          await client.query(
            `INSERT INTO produto_variacoes (produto_id, nome, preco, ordem, disponivel, ativo)
             VALUES ($1, $2, $3, 1, TRUE, TRUE)
             ON CONFLICT (produto_id, nome)
             DO UPDATE SET preco = EXCLUDED.preco, ativo = TRUE`,
            [prodId, nomeProd, precoProd]
          );
          totalVariacoesInseridas++;
        }
      }
    }

    // 4. Processar Grupos Auxiliares (Sabores, Bordas e Adicionais)
    const saboresCadastrados: { id: string; nome: string; valor: number }[] = [];
    const bordasCadastradas: { id: string; nome: string; valor: number }[] = [];
    const adicionaisCadastrados: { nome: string; preco: number }[] = [];

    for (let gIdx = 0; gIdx < gruposAuxiliares.length; gIdx++) {
      const grupo = gruposAuxiliares[gIdx];
      const grupoNome = String(grupo.title || grupo.name || '').trim();
      const itensGrupo = grupo.itens || grupo.items || [];
      const nomeLower = grupoNome.toLowerCase();
      const ehBorda = nomeLower.includes('borda');
      const ehAdicional = nomeLower.includes('adicionais') || nomeLower.includes('ingredientes');
      const ehSabor = !ehBorda && !ehAdicional && (nomeLower.includes('sabor') || nomeLower.includes('pizza') || nomeLower.includes('sabores'));

      for (let sIdx = 0; sIdx < itensGrupo.length; sIdx++) {
        const sub = itensGrupo[sIdx];
        const nomeSub = String(sub.title || sub.name || '').trim();
        const descSub = String(sub.description || sub.desc || '').trim();
        const precoSub = sub.price !== undefined ? Number(sub.price) : 0;
        const ordemSub = sIdx + 1;

        if (!nomeSub) continue;

        if (ehBorda) {
          // Inserir ou atualizar na tabela bordas
          const bordaExist = await client.query(
            'SELECT id FROM bordas WHERE empresa_id = $1 AND nome ILIKE $2',
            [empresaId, nomeSub]
          );

          let bordaId: string;
          if (bordaExist.rowCount && bordaExist.rowCount > 0) {
            bordaId = bordaExist.rows[0].id;
            await client.query(
              `UPDATE bordas SET valor = $1, ordem = $2, ativo = TRUE WHERE id = $3`,
              [precoSub, ordemSub, bordaId]
            );
          } else {
            const resBorda = await client.query(
              `INSERT INTO bordas (empresa_id, nome, valor, ordem, ativo)
               VALUES ($1, $2, $3, $4, TRUE) RETURNING id`,
              [empresaId, nomeSub, precoSub, ordemSub]
            );
            bordaId = resBorda.rows[0].id;
            totalBordasInseridas++;
          }
          bordasCadastradas.push({ id: bordaId, nome: nomeSub, valor: precoSub });
        } else if (ehSabor) {
          // Inserir ou atualizar na tabela sabores
          const saborExist = await client.query(
            'SELECT id FROM sabores WHERE empresa_id = $1 AND nome ILIKE $2',
            [empresaId, nomeSub]
          );

          let saborId: string;
          if (saborExist.rowCount && saborExist.rowCount > 0) {
            saborId = saborExist.rows[0].id;
            await client.query(
              `UPDATE sabores
                  SET descricao = COALESCE(NULLIF($1, ''), descricao),
                      valor_adicional = $2, ordem = $3, ativo = TRUE
                WHERE id = $4`,
              [descSub, precoSub, ordemSub, saborId]
            );
          } else {
            const resSabor = await client.query(
              `INSERT INTO sabores (empresa_id, nome, descricao, valor_adicional, ordem, ativo)
               VALUES ($1, $2, $3, $4, $5, TRUE) RETURNING id`,
              [empresaId, nomeSub, descSub || null, precoSub, ordemSub]
            );
            saborId = resSabor.rows[0].id;
            totalSaboresInseridos++;
          }
          saboresCadastrados.push({ id: saborId, nome: nomeSub, valor: precoSub });
        } else if (ehAdicional) {
          adicionaisCadastrados.push({ nome: nomeSub, preco: precoSub });
        }
      }
    }

    // 5. Vincular Sabores e Bordas às categorias e produtos de Pizzas
    const catPizzaRes = await client.query(
      `SELECT id FROM categorias WHERE empresa_id = $1 AND LOWER(nome) LIKE '%pizza%'`,
      [empresaId]
    );

    for (const catRow of catPizzaRes.rows) {
      const cId = catRow.id;

      // Vincular Sabores à Categoria
      for (const sab of saboresCadastrados) {
        await client.query(
          `INSERT INTO categoria_sabores (categoria_id, sabor_id)
           VALUES ($1, $2) ON CONFLICT DO NOTHING`,
          [cId, sab.id]
        );
      }

      // Vincular Bordas à Categoria
      for (const bor of bordasCadastradas) {
        await client.query(
          `INSERT INTO categoria_bordas (categoria_id, borda_id)
           VALUES ($1, $2) ON CONFLICT DO NOTHING`,
          [cId, bor.id]
        );
      }

      // Vincular também aos produtos dessa categoria de Pizza
      const prodsPizza = await client.query(
        `SELECT id, nome, preco FROM produtos WHERE categoria_id = $1 AND ativo = TRUE`,
        [cId]
      );

      for (const pRow of prodsPizza.rows) {
        // Assegurar que cada pizza tenha variações
        const varExist = await client.query(
          `SELECT id FROM produto_variacoes WHERE produto_id = $1`,
          [pRow.id]
        );
        if (varExist.rowCount === 0) {
          await client.query(
            `INSERT INTO produto_variacoes (produto_id, nome, preco, ordem, disponivel, ativo)
             VALUES ($1, $2, $3, 1, TRUE, TRUE)
             ON CONFLICT (produto_id, nome) DO NOTHING`,
            [pRow.id, pRow.nome, pRow.preco || 40]
          );
          totalVariacoesInseridas++;
        }

        for (const sab of saboresCadastrados) {
          await client.query(
            `INSERT INTO produto_sabores (produto_id, sabor_id, ativo)
             VALUES ($1, $2, TRUE) ON CONFLICT DO NOTHING`,
            [pRow.id, sab.id]
          );
        }
        for (const bor of bordasCadastradas) {
          await client.query(
            `INSERT INTO produto_bordas (produto_id, borda_id, ativo)
             VALUES ($1, $2, TRUE) ON CONFLICT DO NOTHING`,
            [pRow.id, bor.id]
          );
        }
      }
    }

    // 6. Vincular Adicionais aos Lanches, Pastéis e Porções
    const catLanchesRes = await client.query(
      `SELECT id FROM categorias WHERE empresa_id = $1 AND (LOWER(nome) LIKE '%lanche%' OR LOWER(nome) LIKE '%x -%' OR LOWER(nome) LIKE '%past%' OR LOWER(nome) LIKE '%porç%')`,
      [empresaId]
    );

    for (const catRow of catLanchesRes.rows) {
      const prodsCat = await client.query(
        `SELECT id FROM produtos WHERE categoria_id = $1 AND ativo = TRUE`,
        [catRow.id]
      );

      for (const pRow of prodsCat.rows) {
        for (let aIdx = 0; aIdx < adicionaisCadastrados.length; aIdx++) {
          const ad = adicionaisCadastrados[aIdx];
          if (!ad) continue;
          await client.query(
            `INSERT INTO produto_adicionais (produto_id, nome, preco, limite, obrigatorio, ordem, ativo)
             VALUES ($1, $2, $3, 5, FALSE, $4, TRUE)
             ON CONFLICT (produto_id, nome)
             DO UPDATE SET preco = EXCLUDED.preco, ativo = TRUE`,
            [pRow.id, ad.nome, ad.preco, aIdx + 1]
          );
          totalAdicionaisInseridos++;
        }
      }
    }

    await client.query('COMMIT');

    console.log(`\n==============================================`);
    console.log(`✅ IMPORTAÇÃO DO ANOTA AÍ CONCLUÍDA COM SUCESSO!`);
    console.log(`==============================================`);
    console.log(`- Categorias: ${totalCategoriasInseridas} criadas | ${totalCategoriasAtualizadas} atualizadas`);
    console.log(`- Produtos: ${totalProdutosInseridos} criados | ${totalProdutosAtualizados} atualizados`);
    console.log(`- Variações de Tamanho (Pizzas): ${totalVariacoesInseridas} criadas`);
    console.log(`- Sabores de Pizza: ${totalSaboresInseridos} cadastrados (${saboresCadastrados.length} total)`);
    console.log(`- Bordas Recheadas: ${totalBordasInseridas} cadastradas (${bordasCadastradas.length} total)`);
    console.log(`- Adicionais vinculados: ${totalAdicionaisInseridos}`);
    console.log(`==============================================\n`);

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Erro na importação:', error);
    throw error;
  } finally {
    client.release();
  }
}

if (process.argv[1]?.endsWith('importar-cardapio-anota-ai.ts') || process.argv[1]?.endsWith('importar-cardapio-anota-ai.js')) {
  importarCardapioAnotaAi()
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
}
