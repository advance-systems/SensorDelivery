import AsyncStorage from '@react-native-async-storage/async-storage';

export const STORAGE_KEYS = {
  API_URL: '@SensorDelivery:apiUrl',
  EMPRESA_ID: '@SensorDelivery:empresaId',
  CLIENTE_INFO: '@SensorDelivery:clienteInfo',
  CLIENTE_ENDERECO: '@SensorDelivery:clienteEndereco',
  USER_DATA: '@SensorDelivery:userData',
  LAST_ADDRESS: '@SensorDelivery:lastAddress',
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
        let errorMsg = errorText || response.statusText;
        try {
          const parsed = JSON.parse(errorText);
          errorMsg = parsed.erro || parsed.detalhe || parsed.mensagem || parsed.message || errorMsg;
        } catch {}
        throw new Error(errorMsg);
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
      const lista = Array.isArray(res) ? res : (res.empresas || []);
      return lista.map((e) => ({
        id: e.id,
        nome: e.nome_fantasia || e.razao_social || 'Sensor Delivery',
        razaoSocial: e.razao_social,
        logoUrl: e.logo_url,
        telefone: e.telefone,
        email: e.email,
      }));
    } catch {
      return [];
    }
  }

  static async getStatusLoja(empresaId) {
    try {
      return await this.request(`/api/loja/status?empresaId=${empresaId}`);
    } catch {
      return {
        online: false,
        aberta: false,
        status: 'INDISPONIVEL',
        horarioFuncionamento: '',
        tempoEntregaMin: null,
        tempoEntregaMax: null,
        taxaEntregaPadrao: 0,
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
      return [];
    }
  }

  static async getProdutos(empresaId, categoriaId) {
    try {
      let query = `/api/produtos?empresaId=${empresaId}`;
      if (categoriaId && categoriaId !== 'all') {
        query += `&categoriaId=${categoriaId}`;
      }
      const res = await this.request(query);
      const lista = Array.isArray(res) ? res : (res.produtos || []);
      return lista.map((p) => ({
        id: p.id,
        categoriaId: p.categoria_id,
        nome: p.nome,
        descricao: p.descricao,
        preco: Number(p.preco || 0),
        precoPromocional: p.preco_promocional ? Number(p.preco_promocional) : null,
        imagemUrl: p.imagem_url,
        disponivel: p.disponivel,
        destaque: p.destaque,
      }));
    } catch {
      return [];
    }
  }

  static async getSaboresTamanhos(produtoId) {
    try {
      const empresaId = await this.getStoredEmpresaId();
      const res = await this.request(`/api/produtos/${produtoId}/opcoes?empresaId=${empresaId}`);
      return {
        tamanhos: (res.variacoes || []).map((v) => ({
          id: v.id,
          nome: v.nome,
          precoBase: Number(v.preco || 0),
          maxSabores: v.max_sabores || 2,
        })),
        sabores: (res.sabores || []).map((s) => ({
          id: s.id,
          nome: s.nome,
          descricao: s.descricao,
          precoAdicional: Number(s.valor_adicional || 0),
        })),
      };
    } catch {
      return {
        tamanhos: [],
        sabores: [],
      };
    }
  }

  static async getBordas(produtoId) {
    try {
      const empresaId = await this.getStoredEmpresaId();
      const res = await this.request(`/api/produtos/${produtoId}/opcoes?empresaId=${empresaId}`);
      return (res.bordas || []).map((b) => ({
        id: b.id,
        nome: b.nome,
        preco: Number(b.valor || 0),
      }));
    } catch {
      return [];
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

  static async getHistorico(empresaId, telefone) {
    try {
      const cleanPhone = String(telefone || '').replace(/\D/g, '');
      if (!empresaId || !cleanPhone) return [];
      const res = await this.request(`/api/pedidos/historico?empresaId=${empresaId}&telefone=${cleanPhone}`);
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
