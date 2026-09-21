import AsyncStorage from '@react-native-async-storage/async-storage';

export const STORAGE_KEYS = {
  API_URL: '@SensorDelivery:apiUrl',
  EMPRESA_ID: '@SensorDelivery:empresaId',
  CLIENTE_INFO: '@SensorDelivery:clienteInfo',
  CLIENTE_ENDERECO: '@SensorDelivery:clienteEndereco',
  CARRINHO: '@SensorDelivery:carrinho',
};

export const DEFAULT_API_URL = 'https://api-sensordelivery.sistemassensor.com.br';
export const DEFAULT_EMPRESA_ID = 'a24167b2-21e4-4b66-b3ff-38827d4a45ea'; // Sensor Delivery

export class ApiService {
  static async getBaseUrl() {
    try {
      const stored = await AsyncStorage.getItem(STORAGE_KEYS.API_URL);
      if (stored && stored.trim().length > 0) {
        return stored.trim().replace(/\/+$/, '');
      }
    } catch (e) {
      // Fallback
    }
    return DEFAULT_API_URL;
  }

  static async setBaseUrl(url) {
    await AsyncStorage.setItem(STORAGE_KEYS.API_URL, url.trim().replace(/\/+$/, ''));
  }

  static async getStoredEmpresaId() {
    try {
      const stored = await AsyncStorage.getItem(STORAGE_KEYS.EMPRESA_ID);
      if (stored) return stored;
    } catch (e) {
      // Fallback
    }
    return DEFAULT_EMPRESA_ID;
  }

  static async setStoredEmpresaId(id) {
    await AsyncStorage.setItem(STORAGE_KEYS.EMPRESA_ID, id);
  }

  static async request(endpoint, options = {}) {
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
    } catch (error) {
      clearTimeout(timeoutId);
      console.warn(`[API] Erro em ${endpoint}:`, error.message);
      throw error;
    }
  }

  // --- Loja & Status ---
  static async getEmpresas() {
    try {
      const res = await this.request('/api/loja/empresas');
      if (Array.isArray(res)) return res;
      return res.empresas || [];
    } catch {
      return [{
        id: DEFAULT_EMPRESA_ID,
        nome: 'Sensor Delivery',
        cidade: 'Bombinhas',
        uf: 'SC',
        endereco: 'Bombinhas - SC',
      }];
    }
  }

  static async getStatusLoja(empresaId) {
    try {
      return await this.request(`/api/loja/status?empresaId=${empresaId}`);
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

  // --- Produtos & Categorias ---
  static async getCategorias(empresaId) {
    try {
      const res = await this.request(`/api/produtos/categorias/lista?empresaId=${empresaId}`);
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

  static async getProdutos(empresaId, categoriaId) {
    try {
      let query = `/api/produtos?empresaId=${empresaId}`;
      if (categoriaId && categoriaId !== 'all') {
        query += `&categoriaId=${categoriaId}`;
      }
      const res = await this.request(query);
      if (Array.isArray(res)) return res;
      return res.produtos || [];
    } catch {
      return [];
    }
  }

  static async getSaboresTamanhos(produtoId) {
    try {
      return await this.request(`/api/produtos/${produtoId}/sabores-tamanhos`);
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

  static async getBordas(produtoId) {
    try {
      const res = await this.request(`/api/produtos/${produtoId}/bordas`);
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

  // --- Pedidos ---
  static async criarPedido(payload) {
    return await this.request('/api/pedidos', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  }

  static async getStatusPedido(pedidoId) {
    return await this.request(`/api/pedidos/${pedidoId}/status`);
  }

  static async getHistorico(telefone) {
    try {
      const cleanPhone = telefone.replace(/\D/g, '');
      const res = await this.request(`/api/pedidos/historico?telefone=${cleanPhone}`);
      if (Array.isArray(res)) return res;
      return res.pedidos || [];
    } catch {
      return [];
    }
  }

  // --- CEP ---
  static async buscarCep(cep) {
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
