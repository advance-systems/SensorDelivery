import AsyncStorage from '@react-native-async-storage/async-storage';
import { Empresa, LojaStatus, Categoria, Produto, TamanhoPizza, SaborPizza, BordaPizza, PedidoPayload, PedidoResponse } from '../types';

const STORAGE_KEYS = {
  API_URL: '@SensorDelivery:apiUrl',
  EMPRESA_ID: '@SensorDelivery:empresaId',
  CLIENTE_INFO: '@SensorDelivery:clienteInfo',
  CLIENTE_ENDERECO: '@SensorDelivery:clienteEndereco',
  CARRINHO: '@SensorDelivery:carrinho',
  HISTORICO_PEDIDOS: '@SensorDelivery:historicoPedidos',
};

export const DEFAULT_API_URL = 'https://sensordelivery-production.up.railway.app';
export const DEFAULT_EMPRESA_ID = 'a24167b2-21e4-4b66-b3ff-38827d4a45ea'; // Sensor Delivery

export class ApiService {
  private static async getBaseUrl(): Promise<string> {
    try {
      const stored = await AsyncStorage.getItem(STORAGE_KEYS.API_URL);
      if (stored && stored.trim().length > 0) {
        return stored.trim().replace(/\/+$/, '');
      }
    } catch {
      // Fallback
    }
    return DEFAULT_API_URL;
  }

  public static async setBaseUrl(url: string): Promise<void> {
    await AsyncStorage.setItem(STORAGE_KEYS.API_URL, url.trim().replace(/\/+$/, ''));
  }

  public static async getStoredEmpresaId(): Promise<string> {
    try {
      const stored = await AsyncStorage.getItem(STORAGE_KEYS.EMPRESA_ID);
      if (stored) return stored;
    } catch {
      // Fallback
    }
    return DEFAULT_EMPRESA_ID;
  }

  public static async setStoredEmpresaId(id: string): Promise<void> {
    await AsyncStorage.setItem(STORAGE_KEYS.EMPRESA_ID, id);
  }

  private static async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    const baseUrl = await this.getBaseUrl();
    const url = `${baseUrl}${endpoint.startsWith('/') ? endpoint : `/${endpoint}`}`;
    
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 12000);

    try {
      const response = await fetch(url, {
        ...options,
        signal: controller.signal,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...(options.headers || {}),
        },
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Erro ${response.status}: ${errorText || response.statusText}`);
      }

      return await response.json();
    } catch (error: any) {
      clearTimeout(timeoutId);
      console.warn(`[API] Erro ao chamar ${endpoint}:`, error.message);
      throw error;
    }
  }

  // --- Endpoints Loja / Empresa ---
  public static async getEmpresas(): Promise<Empresa[]> {
    try {
      const res = await this.request<{ empresas?: Empresa[] } | Empresa[]>('/api/loja/empresas');
      if (Array.isArray(res)) return res;
      return res.empresas || [];
    } catch {
      // Retornar fallback seguro para a loja padrão
      return [{
        id: DEFAULT_EMPRESA_ID,
        nome: 'Sensor Delivery',
        cidade: 'Bombinhas',
        uf: 'SC',
        endereco: 'Bombinhas - SC',
      }];
    }
  }

  public static async getStatusLoja(empresaId: string): Promise<LojaStatus> {
    try {
      const res = await this.request<LojaStatus>(`/api/loja/status?empresaId=${empresaId}`);
      return res;
    } catch {
      return {
        aberta: true,
        horarioFuncionamento: '18:00 às 23:30',
        tempoEntregaMin: 35,
        tempoEntregaMax: 50,
        taxaEntregaPadrao: 5.0,
      };
    }
  }

  // --- Endpoints Produtos & Categorias ---
  public static async getCategorias(empresaId: string): Promise<Categoria[]> {
    try {
      const res = await this.request<{ categorias?: Categoria[] } | Categoria[]>(`/api/produtos/categorias/lista?empresaId=${empresaId}`);
      if (Array.isArray(res)) return res;
      return res.categorias || [];
    } catch {
      return [
        { id: 'all', nome: 'Todos' },
        { id: 'pizza', nome: 'Pizzas' },
        { id: 'bebida', nome: 'Bebidas' },
        { id: 'sobremesa', nome: 'Sobremesas' },
      ];
    }
  }

  public static async getProdutos(empresaId: string, categoriaId?: string): Promise<Produto[]> {
    try {
      let query = `/api/produtos?empresaId=${empresaId}`;
      if (categoriaId && categoriaId !== 'all') {
        query += `&categoriaId=${categoriaId}`;
      }
      const res = await this.request<{ produtos?: Produto[] } | Produto[]>(query);
      if (Array.isArray(res)) return res;
      return res.produtos || [];
    } catch {
      return [];
    }
  }

  public static async getSaboresTamanhos(produtoId: string): Promise<{ tamanhos: TamanhoPizza[]; sabores: SaborPizza[] }> {
    try {
      const res = await this.request<{ tamanhos: TamanhoPizza[]; sabores: SaborPizza[] }>(`/api/produtos/${produtoId}/sabores-tamanhos`);
      return res;
    } catch {
      return {
        tamanhos: [
          { id: 'p', nome: 'Pequena (4 fatias)', sigla: 'P', fatias: 4, maxSabores: 1, precoBase: 35 },
          { id: 'm', nome: 'Média (6 fatias)', sigla: 'M', fatias: 6, maxSabores: 2, precoBase: 48 },
          { id: 'g', nome: 'Grande (8 fatias)', sigla: 'G', fatias: 8, maxSabores: 3, precoBase: 62 },
          { id: 'gg', nome: 'Família (12 fatias)', sigla: 'GG', fatias: 12, maxSabores: 4, precoBase: 78 },
        ],
        sabores: [
          { id: '1', nome: 'Calabresa', descricao: 'Molho de tomate, mussarela fatiada e calabresa com orégano' },
          { id: '2', nome: 'Mussarela', descricao: 'Molho especial da casa e camada dupla de queijo mussarela' },
          { id: '3', nome: 'Frango com Catupiry', descricao: 'Peito de frango desfiado com autêntico Catupiry' },
          { id: '4', nome: 'Quatro Queijos', descricao: 'Mussarela, provolone, parmesão e catupiry' },
          { id: '5', nome: 'Portuguesa', descricao: 'Presunto cozido, ovos, cebola, ervilha e azeitonas pretas' },
        ],
      };
    }
  }

  public static async getBordas(produtoId: string): Promise<BordaPizza[]> {
    try {
      const res = await this.request<{ bordas?: BordaPizza[] } | BordaPizza[]>(`/api/produtos/${produtoId}/bordas`);
      if (Array.isArray(res)) return res;
      return res.bordas || [];
    } catch {
      return [
        { id: 'sem_borda', nome: 'Sem Borda Recheada', preco: 0 },
        { id: 'catupiry', nome: 'Borda de Catupiry', preco: 8.0 },
        { id: 'cheddar', nome: 'Borda de Cheddar Cremoso', preco: 8.0 },
        { id: 'chocolate', nome: 'Borda de Chocolate ao Leite', preco: 10.0 },
      ];
    }
  }

  // --- Endpoints Pedidos ---
  public static async criarPedido(payload: PedidoPayload): Promise<PedidoResponse> {
    return await this.request<PedidoResponse>('/api/pedidos', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  }

  public static async getStatusPedido(pedidoId: string): Promise<PedidoResponse> {
    return await this.request<PedidoResponse>(`/api/pedidos/${pedidoId}/status`);
  }

  public static async getHistorico(telefone: string): Promise<PedidoResponse[]> {
    try {
      const cleanPhone = telefone.replace(/\D/g, '');
      const res = await this.request<{ pedidos?: PedidoResponse[] } | PedidoResponse[]>(`/api/pedidos/historico?telefone=${cleanPhone}`);
      if (Array.isArray(res)) return res;
      return res.pedidos || [];
    } catch {
      return [];
    }
  }

  // --- CEP (ViaCEP) ---
  public static async buscarCep(cep: string): Promise<any> {
    const cleanCep = cep.replace(/\D/g, '');
    if (cleanCep.length !== 8) return null;
    try {
      const response = await fetch(`https://viacep.com.br/ws/${cleanCep}/json/`);
      const data = await response.json();
      if (data.erro) return null;
      return data;
    } catch {
      return null;
    }
  }
}
export { STORAGE_KEYS };
