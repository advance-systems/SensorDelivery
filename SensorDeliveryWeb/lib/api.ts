const DEFAULT_API_URL = 'https://api-sensordelivery.sistemassensor.com.br/api';

export const API_BASE_URL = (
  (typeof process !== 'undefined' && process.env?.NEXT_PUBLIC_API_URL) ||
  (typeof import.meta !== 'undefined' && import.meta.env?.VITE_API_URL) ||
  DEFAULT_API_URL
).replace(/\/$/, '');

export interface LojaEmpresa {
  id: string;
  nome_fantasia: string;
  razao_social: string;
  logo_url: string | null;
  telefone?: string;
  email?: string;
}

export interface LojaStatus {
  online: boolean;
  aberta: boolean;
  status: 'ABERTA' | 'FECHADA' | 'INDISPONIVEL';
  motivo?: string;
  empresa?: {
    id: string;
    nome: string;
    razaoSocial?: string;
    logoUrl?: string | null;
    telefone?: string;
    email?: string;
    cidade?: string;
  } | null;
  mensagem: string;
  horarioFuncionamento: string;
  tempoEntregaMin: number;
  tempoEntregaMax: number;
  taxaEntregaPadrao: number;
  pedidoMinimo: number;
  pixHabilitado: boolean;
}

export interface Categoria {
  id: string;
  nome: string;
  imagem_url?: string | null;
  ordem?: number;
}

export interface Produto {
  id: string;
  categoria_id: string;
  categoria_nome?: string;
  tipo: string;
  nome: string;
  descricao?: string | null;
  preco: number | string;
  preco_promocional?: number | string | null;
  imagem_url?: string | null;
  codigo_interno?: string | null;
  disponivel: boolean;
  destaque: boolean;
  ordem: number;
}

export interface Variacao {
  id: string;
  nome: string;
  preco: number | string;
  ordem?: number;
}

export interface Sabor {
  id: string;
  nome: string;
  descricao?: string;
  valor_adicional: number | string;
}

export interface Borda {
  id: string;
  nome: string;
  valor: number | string;
}

export interface Adicional {
  id: string;
  nome: string;
  preco: number | string;
  limite?: number;
  obrigatorio?: boolean;
}

export interface OpcoesProduto {
  variacoes: Variacao[];
  sabores: Sabor[];
  bordas: Borda[];
  adicionais: Adicional[];
}

export function formatImageUrl(url?: string | null): string {
  if (!url) return '/pizza-media.jpg';
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  const baseUrl = API_BASE_URL.replace(/\/api$/, '');
  const cleanPath = url.startsWith('/') ? url : `/${url}`;
  return `${baseUrl}${cleanPath}`;
}

export async function fetchEmpresas(): Promise<LojaEmpresa[]> {
  try {
    const res = await fetch(`${API_BASE_URL}/loja/empresas`, {
      headers: { 'Accept': 'application/json' },
    });
    if (!res.ok) return [];
    const data = await res.json();
    return data.empresas || [];
  } catch (err) {
    console.error('Erro ao buscar empresas:', err);
    return [];
  }
}

export async function fetchLojaStatus(empresaId?: string): Promise<LojaStatus | null> {
  try {
    const query = empresaId ? `?empresaId=${encodeURIComponent(empresaId)}` : '';
    const res = await fetch(`${API_BASE_URL}/loja/status${query}`, {
      headers: { 'Accept': 'application/json' },
    });
    if (!res.ok) return null;
    return await res.json();
  } catch (err) {
    console.error('Erro ao buscar status da loja:', err);
    return null;
  }
}

export async function fetchCategorias(empresaId?: string): Promise<Categoria[]> {
  try {
    const query = empresaId ? `?empresaId=${encodeURIComponent(empresaId)}` : '';
    const res = await fetch(`${API_BASE_URL}/produtos/categorias/lista${query}`, {
      headers: { 'Accept': 'application/json' },
    });
    if (!res.ok) return [];
    const data = await res.json();
    return data.categorias || [];
  } catch (err) {
    console.error('Erro ao buscar categorias:', err);
    return [];
  }
}

export async function fetchProdutos(empresaId?: string, categoriaId?: string): Promise<Produto[]> {
  try {
    const params = new URLSearchParams();
    if (empresaId) params.append('empresaId', empresaId);
    if (categoriaId && categoriaId !== 'all') params.append('categoriaId', categoriaId);
    const qs = params.toString() ? `?${params.toString()}` : '';
    const res = await fetch(`${API_BASE_URL}/produtos${qs}`, {
      headers: { 'Accept': 'application/json' },
    });
    if (!res.ok) return [];
    const data = await res.json();
    return data.produtos || [];
  } catch (err) {
    console.error('Erro ao buscar produtos:', err);
    return [];
  }
}

export async function fetchProdutoOpcoes(produtoId: string, empresaId?: string): Promise<OpcoesProduto | null> {
  try {
    const query = empresaId ? `?empresaId=${encodeURIComponent(empresaId)}` : '';
    const res = await fetch(`${API_BASE_URL}/produtos/${produtoId}/opcoes${query}`, {
      headers: { 'Accept': 'application/json' },
    });
    if (!res.ok) return null;
    return await res.json();
  } catch (err) {
    console.error('Erro ao carregar opções do produto:', err);
    return null;
  }
}

export async function createPedido(payload: Record<string, unknown>): Promise<{ sucesso: boolean; pedido?: any; erro?: string; respostaPix?: any }> {
  try {
    const res = await fetch(`${API_BASE_URL}/pedidos`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    const data = await res.json();
    if (!res.ok) {
      return { sucesso: false, erro: data.erro || data.detalhe || 'Erro ao criar pedido.' };
    }
    return { sucesso: true, pedido: data.pedido, respostaPix: data.respostaPix };
  } catch (err) {
    console.error('Erro ao enviar pedido:', err);
    return { sucesso: false, erro: 'Falha de conexão ao enviar o pedido.' };
  }
}

