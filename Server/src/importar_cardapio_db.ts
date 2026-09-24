import fs from 'fs';
import { Pool } from 'pg';

const pool = new Pool({
  connectionString: 'postgresql://postgres:SensorSistemas@localhost:5432/SENSOR_DELIVERY',
});

async function importarCardapio() {
  const client = await pool.connect();

  try {
    const rawData = fs.readFileSync('H:/Projetos/SensorDelivery/cardapio_completo.json', 'utf8');
    const data = JSON.parse(rawData);

    // 1. Obter a empresa principal
    const empresaRes = await client.query('SELECT id, nome_fantasia FROM empresas LIMIT 1');
    if (empresaRes.rowCount === 0) {
      throw new Error('Nenhuma empresa encontrada no banco de dados.');
    }
    const empresaId = empresaRes.rows[0].id;
    console.log(`\nImportando para Empresa: ${empresaRes.rows[0].nome_fantasia} (${empresaId})`);

    const categories = data.menu?.menu?.menu || [];
    const gruposAuxiliares = data.menu?.menu?.menu_aux || [];

    console.log(`Total de Categorias a processar: ${categories.length}`);
    console.log(`Total de Grupos Auxiliares (Sabores/Adicionais): ${gruposAuxiliares.length}\n`);

    await client.query('BEGIN');

    let totalCategoriasInseridas = 0;
    let totalCategoriasAtualizadas = 0;
    let totalProdutosInseridos = 0;
    let totalProdutosAtualizados = 0;
    let totalSaboresInseridos = 0;
    let totalAdicionaisInseridos = 0;

    // Mapa de Categoria Nome -> ID no banco
    const mapCategorias = new Map<string, string>();

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
        const precoProd = item.price !== undefined ? Number(item.price) : 0;
        const imagemProd = String(item.image || item.photo || '').trim();
        const disponivel = !item.paused;
        const ordemProd = pIdx + 1;
        const tipoProd = cat.type === 'combo' || nomeProd.toLowerCase().startsWith('combo') ? 'COMBO' : 'PRODUTO';

        if (!nomeProd) continue;

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
      }
    }

    // 4. Processar Grupos Auxiliares (Sabores e Adicionais)
    for (let gIdx = 0; gIdx < gruposAuxiliares.length; gIdx++) {
      const grupo = gruposAuxiliares[gIdx];
      const grupoNome = String(grupo.title || grupo.name || '').trim();
      const itensGrupo = grupo.itens || grupo.items || [];
      const ehSabor = grupoNome.toLowerCase().includes('sabor') || grupoNome.toLowerCase().includes('pizza');

      for (let sIdx = 0; sIdx < itensGrupo.length; sIdx++) {
        const sub = itensGrupo[sIdx];
        const nomeSub = String(sub.title || sub.name || '').trim();
        const descSub = String(sub.description || sub.desc || '').trim();
        const precoSub = sub.price !== undefined ? Number(sub.price) : 0;
        const ordemSub = sIdx + 1;

        if (!nomeSub) continue;

        if (ehSabor) {
          // Inserir ou atualizar na tabela `sabores`
          const saborExist = await client.query(
            'SELECT id FROM sabores WHERE empresa_id = $1 AND nome ILIKE $2',
            [empresaId, nomeSub]
          );

          if (saborExist.rowCount && saborExist.rowCount > 0) {
            await client.query(
              `UPDATE sabores
                  SET descricao = COALESCE(NULLIF($1, ''), descricao),
                      valor_adicional = $2, ordem = $3, ativo = TRUE
                WHERE id = $4`,
              [descSub, precoSub, ordemSub, saborExist.rows[0].id]
            );
          } else {
            await client.query(
              `INSERT INTO sabores (empresa_id, nome, descricao, valor_adicional, ordem, ativo)
               VALUES ($1, $2, $3, $4, $5, TRUE)`,
              [empresaId, nomeSub, descSub || null, precoSub, ordemSub]
            );
            totalSaboresInseridos++;
          }
        }
      }
    }

    await client.query('COMMIT');

    console.log(`\n==============================================`);
    console.log(`✅ IMPORTAÇÃO CONCLUÍDA COM SUCESSO!`);
    console.log(`==============================================`);
    console.log(`- Categorias: ${totalCategoriasInseridas} novas | ${totalCategoriasAtualizadas} atualizadas`);
    console.log(`- Produtos: ${totalProdutosInseridos} novos | ${totalProdutosAtualizados} atualizados`);
    console.log(`- Sabores de Pizza: ${totalSaboresInseridos} cadastrados`);
    console.log(`==============================================\n`);

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Erro na importação:', error);
  } finally {
    client.release();
    await pool.end();
  }
}

importarCardapio();
