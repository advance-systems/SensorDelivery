import fs from 'fs';

const data = JSON.parse(fs.readFileSync('H:/Projetos/SensorDelivery/cardapio_completo.json', 'utf8'));
const categories = data.menu.menu.menu || [];
const gruposAuxiliares = data.menu.menu.menu_aux || [];

console.log('--- GERANDO PLANILHA EXCEL COMPLETA ---');

function escapeCsv(str: any) {
  const s = String(str ?? '').replace(/"/g, '""');
  return `"${s}"`;
}

// 1. Planilha Principal de Produtos
const produtosRows: any[] = [];

categories.forEach((cat: any, cIdx: number) => {
  const catNome = cat.title || cat.name || `Categoria ${cIdx + 1}`;
  const itens = cat.itens || cat.items || [];

  itens.forEach((item: any) => {
    const nome = item.title || item.name || '';
    const desc = (item.description || item.desc || '').replace(/[\r\n]+/g, ' ');
    const preco = item.price !== undefined ? Number(item.price) : 0;
    const precoFormatado = preco.toFixed(2).replace('.', ',');
    const foto = item.image || item.photo || '';
    const disponivel = item.paused ? 'Não' : 'Sim';

    // Identifica grupos de complementos/sabores vinculados
    const vinculosAux = (item.subitems || item.item_categories || []).map((v: any) => {
      const aux = gruposAuxiliares.find((g: any) => g._id === v.item_category_id || g.id === v.item_category_id);
      return aux ? (aux.title || aux.name) : (v.title || v.name);
    }).filter(Boolean).join(' | ');

    produtosRows.push({
      Tipo: 'PRODUTO',
      Categoria: catNome,
      Item: nome,
      Descricao: desc,
      Preco: precoFormatado,
      Disponivel: disponivel,
      Grupos_Vinculados: vinculosAux,
      Foto_URL: foto
    });
  });
});

// 2. Adicionar os Grupos de Sabores e Adicionais (menu_aux)
const adicionaisRows: any[] = [];

gruposAuxiliares.forEach((grupo: any) => {
  const grupoNome = grupo.title || grupo.name || 'Grupo Sem Nome';
  const itens = grupo.itens || grupo.items || [];

  itens.forEach((sub: any) => {
    const nome = sub.title || sub.name || '';
    const desc = (sub.description || sub.desc || '').replace(/[\r\n]+/g, ' ');
    const preco = sub.price !== undefined ? Number(sub.price) : 0;
    const precoFormatado = preco.toFixed(2).replace('.', ',');
    const disponivel = sub.paused ? 'Não' : 'Sim';

    adicionaisRows.push({
      Tipo: 'ADICIONAL / SABOR',
      Categoria: `[GRUPO] ${grupoNome}`,
      Item: nome,
      Descricao: desc,
      Preco: precoFormatado,
      Disponivel: disponivel,
      Grupos_Vinculados: '',
      Foto_URL: sub.image || sub.photo || ''
    });
  });
});

const todasAsLinhas = [...produtosRows, ...adicionaisRows];

const headers = [
  'Tipo',
  'Categoria / Grupo',
  'Nome do Item / Sabor',
  'Descrição',
  'Preço (R$)',
  'Disponível',
  'Grupos Vinculados',
  'Foto URL'
];

const csvContent = [
  headers.join(';'),
  ...todasAsLinhas.map(r => [
    escapeCsv(r.Tipo),
    escapeCsv(r.Categoria),
    escapeCsv(r.Item),
    escapeCsv(r.Descricao),
    escapeCsv(r.Preco),
    escapeCsv(r.Disponivel),
    escapeCsv(r.Grupos_Vinculados),
    escapeCsv(r.Foto_URL)
  ].join(';'))
].join('\r\n');

// 1. Arquivo Completo
const caminhoCompleto = 'H:/Projetos/SensorDelivery/Cardapio_Completo_Italian_Pizza.csv';
fs.writeFileSync(caminhoCompleto, '\uFEFF' + csvContent, 'utf8');

// 2. Arquivo Apenas Produtos
const csvProdutosApenas = [
  ['Categoria', 'Produto', 'Descrição', 'Preço (R$)', 'Disponível', 'Foto URL'].join(';'),
  ...produtosRows.map(r => [
    escapeCsv(r.Categoria),
    escapeCsv(r.Item),
    escapeCsv(r.Descricao),
    escapeCsv(r.Preco),
    escapeCsv(r.Disponivel),
    escapeCsv(r.Foto_URL)
  ].join(';'))
].join('\r\n');
const caminhoProdutos = 'H:/Projetos/SensorDelivery/Cardapio_Produtos_Italian_Pizza.csv';
fs.writeFileSync(caminhoProdutos, '\uFEFF' + csvProdutosApenas, 'utf8');

// 3. Arquivo Apenas Sabores e Adicionais
const csvAdicionaisApenas = [
  ['Grupo de Opções', 'Sabor / Adicional', 'Descrição', 'Preço (R$)', 'Disponível'].join(';'),
  ...adicionaisRows.map(r => [
    escapeCsv(r.Categoria),
    escapeCsv(r.Item),
    escapeCsv(r.Descricao),
    escapeCsv(r.Preco),
    escapeCsv(r.Disponivel)
  ].join(';'))
].join('\r\n');
const caminhoAdicionais = 'H:/Projetos/SensorDelivery/Cardapio_Sabores_e_Adicionais_Italian_Pizza.csv';
fs.writeFileSync(caminhoAdicionais, '\uFEFF' + csvAdicionaisApenas, 'utf8');

console.log(`\n🎉 Extração finalizada com sucesso!`);
console.log(`- Total de Produtos principais: ${produtosRows.length}`);
console.log(`- Total de Sabores/Adicionais/Bordas: ${adicionaisRows.length}`);
console.log(`- Arquivo 1 (Tudo Junto): ${caminhoCompleto}`);
console.log(`- Arquivo 2 (Apenas Produtos): ${caminhoProdutos}`);
console.log(`- Arquivo 3 (Apenas Sabores/Adicionais): ${caminhoAdicionais}`);
