import https from 'https';
import fs from 'fs';

const slug = 'italian-pizza-lanches-porcoes-e-pastel';

function fetchUrl(url: string, headers: any = {}): Promise<{ status?: number; data: string }> {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36', ...headers } }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ status: res.statusCode, data }));
    }).on('error', reject);
  });
}

async function main() {
  const page = await fetchUrl(`https://pedido.anota.ai/loja/${slug}`);
  console.log('Page status:', page.status);
  fs.writeFileSync('page.html', page.data);
  
  // Vamos buscar id da loja se tiver no html
  const regexId = /"id":"([a-zA-Z0-9_-]{10,})"/g;
  let match;
  while ((match = regexId.exec(page.data)) !== null) {
    console.log('Match ID:', match[1]);
  }
}

main().catch(console.error);
