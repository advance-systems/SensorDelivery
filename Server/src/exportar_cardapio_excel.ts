import fs from 'fs';
import path from 'path';

const data = JSON.parse(fs.readFileSync('H:/Projetos/SensorDelivery/cardapio_completo.json', 'utf8'));
const categories = data.menu.menu.menu;

console.log('Total Categorias:', categories.length);

const rows: any[] = [];

categories.forEach((cat: any, cIdx: number) => {
  const catNome = cat.title || cat.name || `Categoria ${cIdx + 1}`;
  const itens = cat.itens || cat.items || [];
  
  console.log(`\n[${cIdx + 1}] Categoria: ${catNome} (${itens.length} itens)`);

  itens.forEach((item: any, iIdx: number) => {
    const nome = item.title || item.name || '';
    const desc = (item.description || item.desc || '').replace(/[\r\n]+/g, ' ');
    const preco = item.price !== undefined ? Number(item.price) : 0;
    const precoFormatado = preco.toFixed(2).replace('.', ',');
    const foto = item.image || item.photo || '';
    const disponivel = item.paused ? 'Não' : 'Sim';

    // Sabores ou complementos se houver
    const gruposAdicionais = (item.subitems || item.item_categories || []).map((g: any) => g.title || g.name).join('; ');

    rows.push({
      Categoria: catNome,
      Produto: nome,
      Descricao: desc,
      Preco: precoFormatado,
      Disponivel: disponivel,
      Complementos_Grupos: gruposAdicionais,
      Foto_URL: foto
    });

    if (iIdx < 3) {
      console.log(`   - ${nome}: R$ ${precoFormatado}`);
    }
  });
});

console.log(`\nTotal de Produtos extraídos: ${rows.length}`);

// Gerar CSV formatado para Excel (separador ponto e vírgula e BOM UTF-8)
function escapeCsv(str: any) {
  const s = String(str ?? '').replace(/"/g, '""');
  return `"${s}"`;
}

const headers = ['Categoria', 'Produto', 'Descrição', 'Preço (R$)', 'Disponível', 'Grupos / Adicionais', 'Foto URL'];
const csvContent = [
  headers.join(';'),
  ...rows.map(r => [
    escapeCsv(r.Categoria),
    escapeCsv(r.Produto),
    escapeCsv(r.Descricao),
    escapeCsv(r.Preco),
    escapeCsv(r.Disponivel),
    escapeCsv(r.Complementos_Grupos),
    escapeCsv(r.Foto_URL)
  ].join(';'))
].join('\r\n');

// BOM UTF-8 (\uFEFF) para abrir com acentuação perfeita no Excel
const filePathCsv = 'H:/Projetos/SensorDelivery/Cardapio_Italian_Pizza_AnotaAI.csv';
fs.writeFileSync(filePathCsv, '\uFEFF' + csvContent, 'utf8');

console.log('\n✅ Planilha gerada com sucesso em:', filePathCsv);
