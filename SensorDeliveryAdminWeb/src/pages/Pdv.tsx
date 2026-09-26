import React, { useState, useEffect, useRef, useMemo } from 'react';
import { api } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { useFeedback } from '../context/FeedbackContext';
import {
  Search,
  Filter,
  ShoppingBag,
  Trash2,
  Edit3,
  Plus,
  Minus,
  Check,
  X,
  Printer,
  QrCode,
  DollarSign,
  CreditCard,
  Phone,
  User,
  MapPin,
  FileText,
  Sliders,
  Sparkles,
  RefreshCw,
  Clock,
  ArrowRight,
  Settings,
  ChevronRight,
  Tag,
  MessageSquare,
  Percent,
  CheckCircle2,
  Layers,
  Save,
  Store,
  Bike
} from 'lucide-react';

interface Categoria {
  id: string;
  nome: string;
  ordem?: number;
  promocional?: boolean;
}

interface Produto {
  id: string;
  categoria_id: string;
  categoria_nome?: string;
  tipo: string;
  nome: string;
  descricao?: string;
  preco: number;
  preco_promocional?: number;
  imagem_url?: string;
  codigo_interno?: string;
  disponivel: boolean;
  destaque?: boolean;
  quantidade_sabores?: number;
  max_sabores?: number;
}

interface Sabor {
  id: string;
  nome: string;
  descricao?: string;
  ativo: boolean;
  categoria_id?: string;
}

interface Borda {
  id: string;
  nome: string;
  valor?: number;
  valor_adicional?: number;
  ativo?: boolean;
  precos_tamanho?: Array<{ produto_id: string; produto_nome?: string; valor: number }>;
}

interface Adicional {
  id: string;
  produto_id?: string;
  categoria_id?: string;
  nome: string;
  preco: number;
  limite?: number;
}

interface ItemCarrinho {
  idTemp: string;
  produtoId: string;
  produtoNome: string;
  precoUnitario: number;
  quantidade: number;
  observacoes?: string;
  sabores?: Array<{ saborId: string; saborNome: string; fracao: string }>;
  borda?: { bordaId: string; bordaNome: string; preco: number };
  adicionais?: Array<{ adicionalId: string; nome: string; quantidade: number; valor: number }>;
  valorTotal: number;
}

interface ClienteSuggestion {
  id: string;
  nome: string;
  telefone: string;
  endereco_texto?: string;
}

interface RascunhoPedido {
  id: string;
  criadoEm: string;
  tipoAtendimento: 'BALCAO' | 'DELIVERY' | 'MESA';
  clienteNome: string;
  clienteTelefone: string;
  enderecoTexto: string;
  itens: ItemCarrinho[];
  total: number;
}

// Funções Auxiliares para Pizzas e Bordas
function ehPizzaProduto(prod?: Produto | null, categoriasLista: Categoria[] = []): boolean {
  if (!prod) return false;
  const nomeLower = (prod.nome || '').toLowerCase();
  const cat = categoriasLista.find((c) => c.id === prod.categoria_id);
  const catLower = (cat?.nome || prod.categoria_nome || '').toLowerCase();
  return (
    catLower.includes('pizza') ||
    nomeLower.includes('pizza') ||
    nomeLower.includes('25cm') ||
    nomeLower.includes('30cm') ||
    nomeLower.includes('35cm') ||
    nomeLower.includes('40cm') ||
    nomeLower.includes('45cm') ||
    nomeLower.includes('50cm') ||
    nomeLower.includes('pequena') ||
    nomeLower.includes('méd') ||
    nomeLower.includes('med') ||
    nomeLower.includes('grande') ||
    nomeLower.includes('fam') ||
    nomeLower.includes('gigante') ||
    nomeLower.includes('broto')
  );
}

function obterMaxSaboresPizza(prod?: Produto | null): number {
  if (!prod) return 1;
  if (prod.quantidade_sabores && prod.quantidade_sabores > 0) return prod.quantidade_sabores;
  if (prod.max_sabores && prod.max_sabores > 0) return prod.max_sabores;

  const nomeLower = (prod.nome || '').toLowerCase();
  if (nomeLower.includes('pequena') || nomeLower.includes('25cm') || nomeLower.includes('broto')) {
    return 2;
  }
  if (nomeLower.includes('média') || nomeLower.includes('media') || nomeLower.includes('30cm')) {
    return 2;
  }
  if (nomeLower.includes('grande') || nomeLower.includes('35cm')) {
    return 3;
  }
  if (nomeLower.includes('família') || nomeLower.includes('familia') || nomeLower.includes('famiia') || nomeLower.includes('40cm')) {
    return 4;
  }
  if (nomeLower.includes('gigante') || nomeLower.includes('45cm') || nomeLower.includes('50cm')) {
    return 4;
  }
  return 2;
}

function obterPrecoBordaParaProduto(borda: Borda, produtoId?: string): number {
  if (!borda) return 0;
  if (produtoId && Array.isArray(borda.precos_tamanho)) {
    const pt = borda.precos_tamanho.find((p) => String(p.produto_id) === String(produtoId));
    if (pt && pt.valor !== undefined && pt.valor !== null) {
      return Number(pt.valor);
    }
  }
  return Number(borda.valor_adicional ?? borda.valor ?? 0);
}

export const Pdv: React.FC = () => {
  const { empresaAtiva } = useAuth();
  const { notificar } = useFeedback();

  // Dados do Cardápio
  const [categorias, setCategorias] = useState<Categoria[]>([]);
  const [produtos, setProdutos] = useState<Produto[]>([]);
  const [sabores, setSabores] = useState<Sabor[]>([]);
  const [bordas, setBordas] = useState<Borda[]>([]);
  const [adicionais, setAdicionais] = useState<Adicional[]>([]);
  const [carregandoDados, setCarregandoDados] = useState(true);

  // Filtros de Produtos
  const [categoriaSelecionada, setCategoriaSelecionada] = useState<string>('TODOS');
  const [buscaTexto, setBuscaTexto] = useState('');
  const [filtroApenasDestaques, setFiltroApenasDestaques] = useState(false);
  const [modalFiltrosAberto, setModalFiltrosAberto] = useState(false);

  // Modo de Venda (Tabs Superiores)
  const [tipoAtendimento, setTipoAtendimento] = useState<'DELIVERY' | 'BALCAO' | 'MESA'>('DELIVERY');
  const [mesaNumero, setMesaNumero] = useState('');

  // Carrinho / Itens do Pedido
  const [itensCarrinho, setItensCarrinho] = useState<ItemCarrinho[]>([]);
  const [itemSelecionadoId, setItemSelecionadoId] = useState<string | null>(null);

  // Dados do Cliente
  const [clienteTelefone, setClienteTelefone] = useState('');
  const [clienteNome, setClienteNome] = useState('');
  const [enderecoTexto, setEnderecoTexto] = useState('');
  const [cpfCnpj, setCpfCnpj] = useState('');
  const [observacaoPedido, setObservacaoPedido] = useState('');
  const [sugestoesClientes, setSugestoesClientes] = useState<ClienteSuggestion[]>([]);
  const [mostrarSugestoes, setMostrarSugestoes] = useState(false);

  // Valores Financeiros
  const [taxaEntrega, setTaxaEntrega] = useState<number>(0);
  const [desconto, setDesconto] = useState<number>(0);
  const [acrescimo, setAcrescimo] = useState<number>(0);

  // Pagamento
  const [formaPagamento, setFormaPagamento] = useState<'PIX' | 'DINHEIRO' | 'CARTAO_CREDITO' | 'CARTAO_DEBITO' | 'OUTRO'>('PIX');
  const [trocoPara, setTrocoPara] = useState<string>('');

  // Modais de Ação
  const [modalProdutoAberto, setModalProdutoAberto] = useState(false);
  const [produtoConfigurando, setProdutoConfigurando] = useState<Produto | null>(null);
  const [itemEditandoId, setItemEditandoId] = useState<string | null>(null);
  const [quantConfig, setQuantConfig] = useState(1);
  const [obsConfig, setObsConfig] = useState('');
  const [saboresEscolhidos, setSaboresEscolhidos] = useState<Array<{ saborId: string; saborNome: string; fracao: string }>>([]);
  const [bordaEscolhida, setBordaEscolhida] = useState<{ bordaId: string; bordaNome: string; preco: number } | null>(null);
  const [adicionaisEscolhidos, setAdicionaisEscolhidos] = useState<Array<{ adicionalId: string; nome: string; quantidade: number; valor: number }>>([]);
  const [numFracoesPizza, setNumFracoesPizza] = useState<number>(1);
  const [buscaSaborModal, setBuscaSaborModal] = useState('');

  // Modais Auxiliares
  const [modalObsPedidoAberto, setModalObsPedidoAberto] = useState(false);
  const [modalCpfAberto, setModalCpfAberto] = useState(false);
  const [modalAjusteAberto, setModalAjusteAberto] = useState(false);
  const [modalOutrosPagamentosAberto, setModalOutrosPagamentosAberto] = useState(false);
  const [modalRascunhosAberto, setModalRascunhosAberto] = useState(false);
  const [modalSucessoAberto, setModalSucessoAberto] = useState(false);
  const [pedidoGerado, setPedidoGerado] = useState<any>(null);

  // Rascunhos salvos localmente
  const [rascunhos, setRascunhos] = useState<RascunhoPedido[]>(() => {
    try {
      const salvas = localStorage.getItem('@SensorDelivery:rascunhos_pdv');
      return salvas ? JSON.parse(salvas) : [];
    } catch {
      return [];
    }
  });

  const [gerandoPedido, setGerandoPedido] = useState(false);
  const searchInputRef = useRef<HTMLInputElement>(null);
  const telefoneInputRef = useRef<HTMLInputElement>(null);

  // Carrega Cardápio Completo
  const carregarCardapio = async () => {
    try {
      setCarregandoDados(true);
      const [resCat, resProd, resSab, resBord, resAdic, resConf] = await Promise.allSettled([
        api.get('/cardapio/categorias'),
        api.get('/cardapio'),
        api.get('/sabores'),
        api.get('/sabores/bordas'),
        api.get('/adicionais'),
        api.get('/configuracoes'),
      ]);

      if (resCat.status === 'fulfilled' && resCat.value.data?.categorias) {
        setCategorias(resCat.value.data.categorias);
      }
      if (resProd.status === 'fulfilled' && resProd.value.data?.produtos) {
        setProdutos(resProd.value.data.produtos);
      }
      if (resSab.status === 'fulfilled' && resSab.value.data?.sabores) {
        setSabores(resSab.value.data.sabores);
      }
      if (resBord.status === 'fulfilled') {
        const dadosBordas = resBord.value.data?.bordas || resBord.value.data?.sabores || [];
        setBordas(dadosBordas);
      }
      if (resAdic.status === 'fulfilled' && resAdic.value.data?.adicionais) {
        setAdicionais(resAdic.value.data.adicionais);
      }
      if (resConf.status === 'fulfilled' && resConf.value.data?.configuracao) {
        const taxa = Number(resConf.value.data.configuracao.taxa_entrega || 0);
        if (taxa > 0 && tipoAtendimento === 'DELIVERY') {
          setTaxaEntrega(taxa);
        }
      }
    } catch (error) {
      console.error('Erro ao carregar dados do PDV:', error);
      notificar('Falha ao carregar cardápio para o PDV.', 'error');
    } finally {
      setCarregandoDados(false);
    }
  };

  useEffect(() => {
    carregarCardapio();
  }, [empresaAtiva]);

  // Busca rápida de clientes pelo telefone ou nome
  useEffect(() => {
    if (!clienteTelefone && !clienteNome) {
      setSugestoesClientes([]);
      return;
    }
    const timer = setTimeout(async () => {
      try {
        const query = (clienteTelefone || clienteNome).trim();
        if (query.length < 2) return;
        const res = await api.get(`/clientes?busca=${encodeURIComponent(query)}`);
        if (res.data?.clientes) {
          setSugestoesClientes(res.data.clientes);
        }
      } catch (err) {
        // Silencioso
      }
    }, 300);
    return () => clearTimeout(timer);
  }, [clienteTelefone, clienteNome]);

  // Atualiza taxa de entrega de acordo com o tipo de atendimento
  useEffect(() => {
    if (tipoAtendimento === 'BALCAO' || tipoAtendimento === 'MESA') {
      setTaxaEntrega(0);
    }
  }, [tipoAtendimento]);

  // Salva rascunhos no localStorage
  useEffect(() => {
    try {
      localStorage.setItem('@SensorDelivery:rascunhos_pdv', JSON.stringify(rascunhos));
    } catch (e) {
      console.error('Erro ao salvar rascunhos:', e);
    }
  }, [rascunhos]);

  // Atalhos Globais de Teclado
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement;
      const isInput = target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.tagName === 'SELECT';

      // CTRL+X: Rascunhos
      if (e.ctrlKey && e.key.toLowerCase() === 'x') {
        e.preventDefault();
        setModalRascunhosAberto(true);
        return;
      }

      // ENTER sem modal: Gerar Pedido
      if ((e.key === 'Enter' && !isInput) || (e.ctrlKey && e.key === 'Enter')) {
        if (!modalProdutoAberto && !modalSucessoAberto && !modalRascunhosAberto) {
          e.preventDefault();
          handleGerarPedido();
        }
      }

      if (isInput) return;

      const key = e.key.toLowerCase();
      if (key === 'd') {
        e.preventDefault();
        setTipoAtendimento('DELIVERY');
      } else if (key === 'm') {
        e.preventDefault();
        setTipoAtendimento('MESA');
      } else if (key === 'b') {
        e.preventDefault();
        setTipoAtendimento('BALCAO');
      } else if (key === 'p') {
        e.preventDefault();
        searchInputRef.current?.focus();
      } else if (key === 'f') {
        e.preventDefault();
        setModalFiltrosAberto((prev) => !prev);
      } else if (key === 'x') {
        e.preventDefault();
        setFormaPagamento('PIX');
      } else if (key === 'r') {
        e.preventDefault();
        setModalOutrosPagamentosAberto(true);
      } else if (key === 'e') {
        e.preventDefault();
        setTipoAtendimento((prev) => (prev === 'DELIVERY' ? 'BALCAO' : 'DELIVERY'));
      } else if (key === 't') {
        e.preventDefault();
        setModalCpfAberto(true);
      } else if (key === 'y') {
        e.preventDefault();
        setModalAjusteAberto(true);
      } else if (key === 'o') {
        e.preventDefault();
        setModalObsPedidoAberto(true);
      } else if (key === 'w' && itemSelecionadoId) {
        e.preventDefault();
        removerItemCarrinho(itemSelecionadoId);
      } else if (key === 'q' && itemSelecionadoId) {
        e.preventDefault();
        const item = itensCarrinho.find((it) => it.idTemp === itemSelecionadoId);
        if (item) abrirModalConfiguracao(item);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [modalProdutoAberto, modalSucessoAberto, modalRascunhosAberto, itemSelecionadoId, itensCarrinho, tipoAtendimento]);

  // Cálculos Financeiros
  const subtotal = useMemo(() => {
    return itensCarrinho.reduce((acc, it) => acc + it.valorTotal, 0);
  }, [itensCarrinho]);

  const total = useMemo(() => {
    const val = subtotal + taxaEntrega + acrescimo - desconto;
    return val > 0 ? val : 0;
  }, [subtotal, taxaEntrega, acrescimo, desconto]);

  const formatarMoeda = (val: number) => {
    return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0);
  };

  // Filtragem de Produtos
  const produtosFiltrados = useMemo(() => {
    return produtos.filter((p) => {
      if (!p.disponivel) return false;
      if (filtroApenasDestaques && !p.destaque) return false;
      if (categoriaSelecionada !== 'TODOS' && p.categoria_id !== categoriaSelecionada) {
        return false;
      }
      if (buscaTexto) {
        const b = buscaTexto.toLowerCase();
        const matchNome = p.nome.toLowerCase().includes(b);
        const matchDesc = p.descricao?.toLowerCase().includes(b);
        const matchCod = p.codigo_interno?.toLowerCase().includes(b);
        if (!matchNome && !matchDesc && !matchCod) return false;
      }
      return true;
    });
  }, [produtos, categoriaSelecionada, buscaTexto, filtroApenasDestaques]);

  // Agrupamento de Produtos por Categoria para exibição
  const gruposProdutos = useMemo(() => {
    if (categoriaSelecionada !== 'TODOS') {
      const cat = categorias.find((c) => c.id === categoriaSelecionada);
      return [{
        categoria: cat || { id: categoriaSelecionada, nome: 'Produtos' },
        produtos: produtosFiltrados,
      }];
    }

    const mapa = new Map<string, { categoria: Categoria; produtos: Produto[] }>();
    categorias.forEach((cat) => {
      mapa.set(cat.id, { categoria: cat, produtos: [] });
    });

    produtosFiltrados.forEach((prod) => {
      if (mapa.has(prod.categoria_id)) {
        mapa.get(prod.categoria_id)!.produtos.push(prod);
      } else {
        const fallbackCat: Categoria = { id: prod.categoria_id, nome: prod.categoria_nome || 'Outros' };
        mapa.set(prod.categoria_id, { categoria: fallbackCat, produtos: [prod] });
      }
    });

    return Array.from(mapa.values()).filter((g) => g.produtos.length > 0);
  }, [categorias, produtosFiltrados, categoriaSelecionada]);

  // Abrir Modal de Configuração de Produto
  const abrirModalConfiguracao = (prodOrItem: Produto | ItemCarrinho) => {
    setBuscaSaborModal('');
    if ('idTemp' in prodOrItem) {
      // Editando item existente
      const prod = produtos.find((p) => p.id === prodOrItem.produtoId) || {
        id: prodOrItem.produtoId,
        categoria_id: '',
        nome: prodOrItem.produtoNome,
        preco: prodOrItem.precoUnitario,
        tipo: 'PRODUTO',
        disponivel: true,
      };
      setProdutoConfigurando(prod);
      setItemEditandoId(prodOrItem.idTemp);
      setQuantConfig(prodOrItem.quantidade);
      setObsConfig(prodOrItem.observacoes || '');
      setSaboresEscolhidos(prodOrItem.sabores || []);
      setBordaEscolhida(prodOrItem.borda || null);
      setAdicionaisEscolhidos(prodOrItem.adicionais || []);
      setNumFracoesPizza(prodOrItem.sabores?.length || 1);
    } else {
      // Novo item
      setProdutoConfigurando(prodOrItem);
      setItemEditandoId(null);
      setQuantConfig(1);
      setObsConfig('');
      setSaboresEscolhidos([]);
      setBordaEscolhida(null);
      setAdicionaisEscolhidos([]);
      setNumFracoesPizza(1);
    }
    setModalProdutoAberto(true);
  };

  // Preço total do item configurando
  const precoCalculadoConfig = useMemo(() => {
    if (!produtoConfigurando) return 0;
    let base = Number(produtoConfigurando.preco_promocional || produtoConfigurando.preco || 0);
    let extraBorda = bordaEscolhida?.preco || 0;
    let extraAdic = adicionaisEscolhidos.reduce((acc, a) => acc + a.valor * a.quantidade, 0);
    return (base + extraBorda + extraAdic) * quantConfig;
  }, [produtoConfigurando, quantConfig, bordaEscolhida, adicionaisEscolhidos]);

  // Salvar Item Configurado no Carrinho
  const salvarItemNoCarrinho = () => {
    if (!produtoConfigurando) return;

    const novoItem: ItemCarrinho = {
      idTemp: itemEditandoId || `${Date.now()}-${Math.random().toString(36).substr(2, 5)}`,
      produtoId: produtoConfigurando.id,
      produtoNome: produtoConfigurando.nome,
      precoUnitario: Number(produtoConfigurando.preco_promocional || produtoConfigurando.preco || 0),
      quantidade: quantConfig,
      observacoes: obsConfig.trim() || undefined,
      sabores: saboresEscolhidos.length > 0 ? saboresEscolhidos : undefined,
      borda: bordaEscolhida || undefined,
      adicionais: adicionaisEscolhidos.length > 0 ? adicionaisEscolhidos : undefined,
      valorTotal: precoCalculadoConfig,
    };

    if (itemEditandoId) {
      setItensCarrinho((prev) => prev.map((it) => (it.idTemp === itemEditandoId ? novoItem : it)));
      notificar('Item atualizado no pedido.', 'success');
    } else {
      setItensCarrinho((prev) => [...prev, novoItem]);
      notificar(`${produtoConfigurando.nome} adicionado!`, 'success');
    }

    setModalProdutoAberto(false);
    setProdutoConfigurando(null);
    setItemEditandoId(null);
  };

  const removerItemCarrinho = (idTemp: string) => {
    setItensCarrinho((prev) => prev.filter((it) => it.idTemp !== idTemp));
    if (itemSelecionadoId === idTemp) setItemSelecionadoId(null);
  };

  // Salvar como Rascunho
  const salvarRascunhoAtual = () => {
    if (itensCarrinho.length === 0) {
      notificar('Adicione pelo menos um item para salvar o rascunho.', 'info');
      return;
    }

    const rascunho: RascunhoPedido = {
      id: `${Date.now()}`,
      criadoEm: new Date().toISOString(),
      tipoAtendimento,
      clienteNome: clienteNome || 'Cliente Balcão',
      clienteTelefone,
      enderecoTexto,
      itens: itensCarrinho,
      total,
    };

    setRascunhos((prev) => [rascunho, ...prev]);
    limparFormulario();
    notificar('Pedido salvo como rascunho com sucesso!', 'success');
  };

  // Restaurar Rascunho
  const restaurarRascunho = (rascunho: RascunhoPedido) => {
    setTipoAtendimento(rascunho.tipoAtendimento);
    setClienteNome(rascunho.clienteNome);
    setClienteTelefone(rascunho.clienteTelefone);
    setEnderecoTexto(rascunho.enderecoTexto);
    setItensCarrinho(rascunho.itens);
    setRascunhos((prev) => prev.filter((r) => r.id !== rascunho.id));
    setModalRascunhosAberto(false);
    notificar('Rascunho restaurado para o PDV!', 'success');
  };

  // Limpar formulário do PDV
  const limparFormulario = () => {
    setItensCarrinho([]);
    setClienteNome('');
    setClienteTelefone('');
    setEnderecoTexto('');
    setCpfCnpj('');
    setObservacaoPedido('');
    setDesconto(0);
    setAcrescimo(0);
    setTrocoPara('');
    setItemSelecionadoId(null);
  };

  // Gerar Pedido / Enviar para a API
  const handleGerarPedido = async () => {
    if (itensCarrinho.length === 0) {
      notificar('O carrinho está vazio! Adicione itens ao pedido.', 'error');
      return;
    }

    if (tipoAtendimento === 'DELIVERY' && !clienteNome.trim() && !clienteTelefone.trim()) {
      notificar('Informe o telefone ou nome do cliente para entrega.', 'error');
      telefoneInputRef.current?.focus();
      return;
    }

    try {
      setGerandoPedido(true);

      const payload = {
        clienteNome: clienteNome.trim() || 'Cliente Balcão',
        clienteTelefone: clienteTelefone.trim() || '00000000000',
        tipoAtendimento: tipoAtendimento === 'MESA' ? `MESA ${mesaNumero || '1'}` : tipoAtendimento,
        formaPagamento,
        trocoPara: trocoPara ? Number(trocoPara) : undefined,
        enderecoTexto: tipoAtendimento === 'DELIVERY' ? enderecoTexto.trim() : undefined,
        observacoes: [observacaoPedido, cpfCnpj ? `CPF/CNPJ na Nota: ${cpfCnpj}` : ''].filter(Boolean).join(' | ') || undefined,
        subtotal,
        taxaEntrega: tipoAtendimento === 'DELIVERY' ? taxaEntrega : 0,
        desconto,
        acrescimo,
        valorTotal: total,
        itens: itensCarrinho.map((item) => ({
          produtoId: item.produtoId,
          produtoNome: item.produtoNome,
          quantidade: item.quantidade,
          valorUnitario: item.precoUnitario,
          valorTotal: item.valorTotal,
          observacoes: item.observacoes,
          bordaId: item.borda?.bordaId,
          bordaDescricao: item.borda?.bordaNome,
          valorBorda: item.borda?.preco,
          sabores: item.sabores?.map((s) => ({
            saborId: s.saborId,
            saborDescricao: s.saborNome,
            fracao: s.fracao,
          })),
          adicionais: item.adicionais?.map((a) => ({
            adicionalId: a.adicionalId,
            adicionalDescricao: a.nome,
            quantidade: a.quantidade,
            valor: a.valor,
          })),
        })),
      };

      const res = await api.post('/pedidos', payload);
      const pedidoCriado = res.data?.pedido || { ...payload, id: res.data?.id || Date.now(), numero: res.data?.numero || '#NOVO' };
      setPedidoGerado(pedidoCriado);
      setModalSucessoAberto(true);
      limparFormulario();
      notificar('Pedido gerado com sucesso!', 'success');
    } catch (error: any) {
      console.error('Erro ao gerar pedido:', error);
      notificar(error.response?.data?.erro || 'Não foi possível gerar o pedido. Verifique os dados.', 'error');
    } finally {
      setGerandoPedido(false);
    }
  };

  const isPizzaAtual = ehPizzaProduto(produtoConfigurando, categorias);
  const maxSaboresPizzaAtual = isPizzaAtual ? obterMaxSaboresPizza(produtoConfigurando) : 1;

  // Sabores filtrados pela busca interna do modal
  const saboresFiltradosModal = useMemo(() => {
    return sabores.filter((s) => {
      if (!s.ativo) return false;
      if (buscaSaborModal) {
        return s.nome.toLowerCase().includes(buscaSaborModal.toLowerCase()) ||
          (s.descricao && s.descricao.toLowerCase().includes(buscaSaborModal.toLowerCase()));
      }
      return true;
    });
  }, [sabores, buscaSaborModal]);

  return (
    <div className="flex flex-col h-[calc(100vh-5.5rem)] select-none text-[#F4F7FB] -m-4 md:-m-8">
      {/* 1. BARRA SUPERIOR (HEADER PDV) */}
      <div className="bg-[#121f30] border-b border-[#2A405B] px-4 py-2.5 flex items-center justify-between gap-4 shrink-0">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-lg bg-[#8C63FF]/20 border border-[#8C63FF]/30 flex items-center justify-center text-[#8C63FF]">
            <Store className="w-4 h-4" />
          </div>
          <div>
            <h1 className="text-base font-extrabold text-white tracking-wide flex items-center gap-2">
              Pedidos balcão (PDV)
            </h1>
          </div>
        </div>

        {/* Botões de Seleção de Modo: Delivery / Balcão / Mesas */}
        <div className="flex items-center gap-2 bg-[#0B132B] p-1 rounded-xl border border-[#2A405B]">
          <button
            onClick={() => setTipoAtendimento('DELIVERY')}
            className={`flex items-center gap-2 px-4 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer ${
              tipoAtendimento === 'DELIVERY'
                ? 'bg-[#0EA5E9] text-white shadow-md'
                : 'text-[#9CAABC] hover:text-white hover:bg-[#152439]'
            }`}
          >
            <Bike className="w-3.5 h-3.5" />
            <span>[ D ] Delivery e Balcão</span>
          </button>

          <button
            onClick={() => setTipoAtendimento('MESA')}
            className={`flex items-center gap-2 px-4 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer ${
              tipoAtendimento === 'MESA'
                ? 'bg-[#8C63FF] text-white shadow-md'
                : 'text-[#9CAABC] hover:text-white hover:bg-[#152439]'
            }`}
          >
            <Layers className="w-3.5 h-3.5" />
            <span>[ M ] Mesas e Comandas</span>
          </button>
        </div>

        {/* Indicador de Rascunhos Rápido */}
        <div className="flex items-center gap-2">
          <button
            onClick={() => setModalRascunhosAberto(true)}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#0B132B] border border-[#2A405B] text-xs font-semibold text-[#9CAABC] hover:text-white hover:border-[#8C63FF] transition-all cursor-pointer"
          >
            <span className="text-[#0EA5E9] font-bold">[ CTRL+X ]</span>
            <span>Rascunhos</span>
            <span className="px-1.5 py-0.2 bg-[#0EA5E9]/20 text-[#0EA5E9] rounded-full text-[10px] font-bold">
              {rascunhos.length}
            </span>
          </button>
        </div>
      </div>

      {/* 2. CORPO PRINCIPAL (DIVIDIDO: ESQUERDA CATÁLOGO / DIREITA CARRINHO) */}
      <div className="flex-1 flex overflow-hidden">
        {/* ======================================================== */}
        {/* COLUNA ESQUERDA + CENTRO: CATÁLOGO DE PRODUTOS */}
        {/* ======================================================== */}
        <div className="flex-1 flex flex-col min-w-0 border-r border-[#2A405B] bg-[#0B132B]">
          {/* Barra de Filtros e Pesquisa */}
          <div className="p-3 border-b border-[#2A405B] bg-[#121f30]/60 flex items-center gap-3">
            <button
              onClick={() => setModalFiltrosAberto(!modalFiltrosAberto)}
              className={`flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-bold border transition-all cursor-pointer ${
                filtroApenasDestaques || modalFiltrosAberto
                  ? 'bg-[#8C63FF] text-white border-[#8C63FF]'
                  : 'bg-[#0B132B] border-[#2A405B] text-[#9CAABC] hover:text-white hover:border-[#8C63FF]'
              }`}
            >
              <Filter className="w-3.5 h-3.5" />
              <span>[ F ] Filtros</span>
            </button>

            <div className="flex-1 relative">
              <input
                ref={searchInputRef}
                type="text"
                value={buscaTexto}
                onChange={(e) => setBuscaTexto(e.target.value)}
                placeholder="[ P ] Pesquisar por nome, descrição ou código..."
                className="w-full bg-[#0B132B] border border-[#2A405B] text-xs text-white rounded-xl pl-9 pr-8 py-2 focus:outline-none focus:border-[#8C63FF] transition-all placeholder-[#64748B]"
              />
              <Search className="w-4 h-4 text-[#64748B] absolute left-3 top-1/2 -translate-y-1/2" />
              {buscaTexto && (
                <button
                  onClick={() => setBuscaTexto('')}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-[#64748B] hover:text-white"
                >
                  <X className="w-3.5 h-3.5" />
                </button>
              )}
            </div>

            <div className="hidden lg:flex items-center gap-3 text-[11px] text-[#64748B]">
              <span className="flex items-center gap-1">
                <kbd className="px-1.5 py-0.5 bg-[#152439] border border-[#2A405B] rounded text-[#9CAABC]">ENTER</kbd>
                Selecionar item
              </span>
            </div>
          </div>

          {/* Área de Categorias (Sidebar Lateral Esquerda) + Grid de Produtos */}
          <div className="flex-1 flex overflow-hidden">
            {/* Lista Lateral de Categorias */}
            <div className="w-44 lg:w-52 border-r border-[#2A405B] bg-[#121f30]/40 flex flex-col overflow-y-auto p-2 space-y-1.5 shrink-0">
              <div className="px-2 py-1 text-[10px] uppercase font-bold text-[#64748B] tracking-wider flex items-center gap-1">
                <span>[ N ] Navegar</span>
              </div>

              <button
                onClick={() => setCategoriaSelecionada('TODOS')}
                className={`w-full text-left px-3 py-2.5 rounded-xl text-xs font-bold transition-all cursor-pointer flex items-center justify-between ${
                  categoriaSelecionada === 'TODOS'
                    ? 'bg-gradient-to-r from-[#0EA5E9] to-[#0284C7] text-white shadow-md'
                    : 'text-[#9CAABC] hover:bg-[#152439] hover:text-white'
                }`}
              >
                <span>TODOS</span>
                <span className="text-[10px] opacity-80">{produtos.length}</span>
              </button>

              {categorias.map((cat) => {
                const isActive = categoriaSelecionada === cat.id;
                const totalCat = produtos.filter((p) => p.categoria_id === cat.id).length;
                const isPromo = cat.nome.toUpperCase().includes('COMBO') || cat.nome.toUpperCase().includes('PROMO');

                return (
                  <button
                    key={cat.id}
                    onClick={() => setCategoriaSelecionada(cat.id)}
                    className={`w-full text-left px-3 py-2.5 rounded-xl text-xs font-bold transition-all cursor-pointer flex flex-col gap-1 relative overflow-hidden ${
                      isActive
                        ? 'bg-gradient-to-r from-[#0EA5E9] to-[#0284C7] text-white shadow-md'
                        : 'text-[#9CAABC] hover:bg-[#152439] hover:text-white'
                    }`}
                  >
                    <div className="flex items-center justify-between w-full">
                      <span className="truncate uppercase">{cat.nome}</span>
                      <span className="text-[10px] opacity-70 ml-1">{totalCat}</span>
                    </div>

                    {isPromo && (
                      <span className="inline-flex items-center gap-0.5 px-1.5 py-0.2 bg-[#3B82F6]/30 text-[#60A5FA] border border-[#3B82F6]/40 rounded text-[9px] font-semibold w-fit">
                        <Percent className="w-2.5 h-2.5" /> Promo
                      </span>
                    )}
                  </button>
                );
              })}
            </div>

            {/* Grid Central de Produtos */}
            <div className="flex-1 overflow-y-auto p-4 space-y-6">
              {carregandoDados ? (
                <div className="h-full flex flex-col items-center justify-center text-[#9CAABC] space-y-3">
                  <RefreshCw className="w-8 h-8 text-[#8C63FF] animate-spin" />
                  <p className="text-xs">Carregando catálogo...</p>
                </div>
              ) : gruposProdutos.length === 0 ? (
                <div className="h-full flex flex-col items-center justify-center text-center p-8 text-[#64748B]">
                  <ShoppingBag className="w-12 h-12 mb-3 text-[#2A405B]" />
                  <p className="text-sm font-semibold text-white">Nenhum produto encontrado</p>
                  <p className="text-xs mt-1">Tente ajustar o termo de pesquisa ou a categoria.</p>
                </div>
              ) : (
                gruposProdutos.map((grupo) => (
                  <div key={grupo.categoria.id} className="space-y-3">
                    <div className="flex items-center gap-2 pb-1 border-b border-[#2A405B]/60">
                      <h3 className="font-extrabold text-sm text-white uppercase tracking-wider">
                        {grupo.categoria.nome}
                      </h3>
                      {(grupo.categoria.nome.toUpperCase().includes('COMBO') || grupo.categoria.promocional) && (
                        <span className="px-2 py-0.5 bg-[#0EA5E9]/20 border border-[#0EA5E9]/30 text-[#0EA5E9] text-[10px] font-bold rounded-full">
                          Categoria promocional
                        </span>
                      )}
                    </div>

                    <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-3">
                      {grupo.produtos.map((prod) => (
                        <div
                          key={prod.id}
                          onClick={() => abrirModalConfiguracao(prod)}
                          className="bg-[#152439] hover:bg-[#1c2e47] border border-[#2A405B] hover:border-[#0EA5E9] rounded-2xl overflow-hidden cursor-pointer transition-all duration-150 flex flex-col justify-between shadow-md hover:shadow-lg hover:shadow-[#0EA5E9]/10 group"
                        >
                          {/* Imagem do Produto */}
                          <div className="h-28 w-full bg-[#0B132B] relative overflow-hidden flex items-center justify-center">
                            {prod.imagem_url ? (
                              <img
                                src={prod.imagem_url}
                                alt={prod.nome}
                                className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                              />
                            ) : (
                              <div className="text-center p-3">
                                <ShoppingBag className="w-8 h-8 mx-auto text-[#2A405B] group-hover:text-[#0EA5E9] transition-colors" />
                              </div>
                            )}

                            {prod.preco_promocional && prod.preco_promocional < prod.preco && (
                              <span className="absolute top-2 left-2 px-1.5 py-0.5 bg-[#EF4444] text-white font-bold text-[9px] rounded-md shadow">
                                OFERTA
                              </span>
                            )}
                          </div>

                          {/* Info Produto */}
                          <div className="p-3 flex-1 flex flex-col justify-between">
                            <div>
                              <h4 className="font-bold text-xs text-white line-clamp-2 leading-snug group-hover:text-[#0EA5E9] transition-colors">
                                {prod.nome}
                              </h4>
                              {prod.descricao && (
                                <p className="text-[10px] text-[#9CAABC] line-clamp-1 mt-0.5">
                                  {prod.descricao}
                                </p>
                              )}
                            </div>

                            <div className="mt-2.5 pt-2 border-t border-[#2A405B]/60 flex items-center justify-between">
                              <span className="font-extrabold text-xs text-[#10B981]">
                                {formatarMoeda(prod.preco_promocional || prod.preco)}
                              </span>
                              <div className="w-6 h-6 rounded-lg bg-[#0EA5E9]/20 text-[#0EA5E9] flex items-center justify-center group-hover:bg-[#0EA5E9] group-hover:text-white transition-all">
                                <Plus className="w-3.5 h-3.5" />
                              </div>
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>

        {/* ======================================================== */}
        {/* COLUNA DIREITA: COMANDA / CARRINHO / CHECKOUT PDV */}
        {/* ======================================================== */}
        <div className="w-80 md:w-96 lg:w-[420px] bg-[#121f30] flex flex-col justify-between shrink-0 shadow-2xl">
          {/* Header Comanda */}
          <div className="p-3 border-b border-[#2A405B] flex items-center justify-between bg-[#0f1b2b]">
            <div className="flex items-center gap-2">
              <span className="text-xs font-extrabold text-white uppercase tracking-wider">
                Itens do pedido
              </span>
              <span className="px-2 py-0.5 bg-[#8C63FF]/20 text-[#8C63FF] border border-[#8C63FF]/30 rounded-full text-[10px] font-bold">
                {itensCarrinho.reduce((a, b) => a + b.quantidade, 0)} un
              </span>
            </div>

            <div className="flex items-center gap-1">
              {itemSelecionadoId && (
                <>
                  <button
                    onClick={() => {
                      const item = itensCarrinho.find((it) => it.idTemp === itemSelecionadoId);
                      if (item) abrirModalConfiguracao(item);
                    }}
                    title="[ Q ] Editar item selecionado"
                    className="p-1.5 text-[#9CAABC] hover:text-white bg-[#152439] hover:bg-[#2A405B] rounded-lg text-xs transition-colors cursor-pointer"
                  >
                    <Edit3 className="w-3.5 h-3.5" />
                  </button>
                  <button
                    onClick={() => removerItemCarrinho(itemSelecionadoId)}
                    title="[ W ] Excluir item selecionado"
                    className="p-1.5 text-[#EF4444] hover:text-white bg-[#EF4444]/10 hover:bg-[#EF4444] rounded-lg text-xs transition-colors cursor-pointer"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </>
              )}
              <button
                onClick={limparFormulario}
                title="Limpar pedido"
                className="p-1.5 text-[#64748B] hover:text-white hover:bg-[#152439] rounded-lg transition-colors cursor-pointer"
              >
                <Settings className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>

          {/* Lista de Itens do Carrinho */}
          <div className="flex-1 overflow-y-auto p-3 space-y-2 bg-[#0B132B]/50">
            {itensCarrinho.length === 0 ? (
              <div className="h-full flex flex-col items-center justify-center text-center p-6 text-[#64748B]">
                <div className="w-12 h-12 rounded-2xl bg-[#152439] border border-[#2A405B] flex items-center justify-center mb-3">
                  <ShoppingBag className="w-6 h-6 text-[#64748B]" />
                </div>
                <p className="text-xs font-semibold text-[#9CAABC]">
                  Finalize o item ao lado, ele vai aparecer aqui
                </p>
                <p className="text-[11px] text-[#64748B] mt-1">
                  Pressione <kbd className="px-1 bg-[#152439] border border-[#2A405B] rounded text-white font-mono">ENTER</kbd> para selecionar rapidamente
                </p>
              </div>
            ) : (
              itensCarrinho.map((item) => {
                const isSelected = itemSelecionadoId === item.idTemp;
                return (
                  <div
                    key={item.idTemp}
                    onClick={() => setItemSelecionadoId(isSelected ? null : item.idTemp)}
                    className={`p-2.5 rounded-xl border transition-all cursor-pointer ${
                      isSelected
                        ? 'bg-[#1c2e47] border-[#0EA5E9] shadow-md shadow-[#0EA5E9]/10'
                        : 'bg-[#152439] border-[#2A405B] hover:border-[#8C63FF]/50'
                    }`}
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div className="flex-1">
                        <div className="flex items-center gap-1.5">
                          <span className="px-1.5 py-0.2 bg-[#0EA5E9]/20 text-[#0EA5E9] rounded text-[11px] font-bold">
                            {item.quantidade}x
                          </span>
                          <span className="font-bold text-xs text-white">{item.produtoNome}</span>
                        </div>

                        {/* Detalhes de Sabores */}
                        {item.sabores && item.sabores.length > 0 && (
                          <p className="text-[11px] text-[#9CAABC] mt-1 ml-5">
                            Sabores: {item.sabores.map((s) => `${s.saborNome} (${s.fracao})`).join(', ')}
                          </p>
                        )}

                        {/* Detalhes de Borda */}
                        {item.borda && (
                          <p className="text-[11px] text-[#9CAABC] ml-5">
                            Borda: {item.borda.bordaNome} (+{formatarMoeda(item.borda.preco)})
                          </p>
                        )}

                        {/* Detalhes de Adicionais */}
                        {item.adicionais && item.adicionais.length > 0 && (
                          <p className="text-[11px] text-[#9CAABC] ml-5">
                            Adicionais: {item.adicionais.map((a) => `${a.quantidade}x ${a.nome}`).join(', ')}
                          </p>
                        )}

                        {/* Observação */}
                        {item.observacoes && (
                          <p className="text-[10px] text-[#F59E0B] italic mt-0.5 ml-5">
                            Obs: {item.observacoes}
                          </p>
                        )}
                      </div>

                      <div className="text-right shrink-0">
                        <span className="font-extrabold text-xs text-[#10B981]">
                          {formatarMoeda(item.valorTotal)}
                        </span>
                      </div>
                    </div>
                  </div>
                );
              })
            )}
          </div>

          {/* Botão de Observação Geral */}
          <div className="px-3 py-1.5 bg-[#0f1b2b] border-t border-[#2A405B]">
            <button
              onClick={() => setModalObsPedidoAberto(true)}
              className="w-full text-left text-[11px] text-[#0EA5E9] hover:text-[#38BDF8] flex items-center justify-between font-semibold cursor-pointer"
            >
              <span className="flex items-center gap-1.5">
                <MessageSquare className="w-3.5 h-3.5" />
                <span>[ O ] Observação do pedido</span>
              </span>
              {observacaoPedido && (
                <span className="text-[10px] text-[#9CAABC] truncate max-w-[160px]">
                  "{observacaoPedido}"
                </span>
              )}
            </button>
          </div>

          {/* Resumo Financeiro */}
          <div className="p-3 bg-[#152439] border-t border-[#2A405B] space-y-1.5 text-xs">
            <div className="flex justify-between text-[#9CAABC]">
              <span>Subtotal</span>
              <span>{formatarMoeda(subtotal)}</span>
            </div>

            {tipoAtendimento === 'DELIVERY' && (
              <div className="flex justify-between text-[#9CAABC]">
                <span>Entrega</span>
                <span className={taxaEntrega === 0 ? 'text-[#10B981] font-bold' : ''}>
                  {taxaEntrega === 0 ? 'Grátis' : formatarMoeda(taxaEntrega)}
                </span>
              </div>
            )}

            {desconto > 0 && (
              <div className="flex justify-between text-[#EF4444]">
                <span>Desconto</span>
                <span>-{formatarMoeda(desconto)}</span>
              </div>
            )}

            {acrescimo > 0 && (
              <div className="flex justify-between text-[#F59E0B]">
                <span>Acréscimo</span>
                <span>+{formatarMoeda(acrescimo)}</span>
              </div>
            )}

            <div className="flex justify-between text-base font-extrabold text-white pt-2 border-t border-[#2A405B]">
              <span>Total</span>
              <span className="text-[#10B981]">{formatarMoeda(total)}</span>
            </div>
          </div>

          {/* Inputs do Cliente (Telefone + Nome + Autocomplete) */}
          <div className="p-3 bg-[#121f30] border-t border-[#2A405B] space-y-2 relative">
            <div className="grid grid-cols-2 gap-2">
              <div className="relative">
                <input
                  ref={telefoneInputRef}
                  type="text"
                  value={clienteTelefone}
                  onChange={(e) => {
                    setClienteTelefone(e.target.value);
                    setMostrarSugestoes(true);
                  }}
                  onFocus={() => setMostrarSugestoes(true)}
                  placeholder="(XX) X XXXX-XXXX"
                  className="w-full bg-[#0B132B] border border-[#0EA5E9] text-xs text-white rounded-xl px-3 py-2 focus:outline-none focus:ring-1 focus:ring-[#0EA5E9] font-medium"
                />
              </div>

              <div className="relative">
                <input
                  type="text"
                  value={clienteNome}
                  onChange={(e) => {
                    setClienteNome(e.target.value);
                    setMostrarSugestoes(true);
                  }}
                  onFocus={() => setMostrarSugestoes(true)}
                  placeholder="Nome do cliente"
                  className="w-full bg-[#0B132B] border border-[#0EA5E9] text-xs text-white rounded-xl px-3 py-2 focus:outline-none focus:ring-1 focus:ring-[#0EA5E9] font-medium"
                />
              </div>
            </div>

            {/* Se for Delivery, mostra campo de endereço */}
            {tipoAtendimento === 'DELIVERY' && (
              <div className="relative">
                <input
                  type="text"
                  value={enderecoTexto}
                  onChange={(e) => setEnderecoTexto(e.target.value)}
                  placeholder="Rua, número, bairro e complemento..."
                  className="w-full bg-[#0B132B] border border-[#2A405B] text-xs text-white rounded-xl px-3 py-1.5 focus:outline-none focus:border-[#8C63FF]"
                />
              </div>
            )}

            {/* Se for Mesa, mostra número da mesa */}
            {tipoAtendimento === 'MESA' && (
              <div className="relative">
                <input
                  type="text"
                  value={mesaNumero}
                  onChange={(e) => setMesaNumero(e.target.value)}
                  placeholder="Número da Mesa / Comanda (ex: 12)"
                  className="w-full bg-[#0B132B] border border-[#8C63FF] text-xs text-white rounded-xl px-3 py-1.5 focus:outline-none focus:ring-1 focus:ring-[#8C63FF]"
                />
              </div>
            )}

            {/* Dropdown de Sugestões de Clientes */}
            {mostrarSugestoes && sugestoesClientes.length > 0 && (
              <div className="absolute left-3 right-3 bottom-full mb-1 bg-[#152439] border border-[#2A405B] rounded-xl shadow-2xl max-h-48 overflow-y-auto z-40 divide-y divide-[#2A405B]">
                <div className="p-2 bg-[#0f1b2b] flex items-center justify-between text-[10px] text-[#9CAABC]">
                  <span>Clientes encontrados ({sugestoesClientes.length})</span>
                  <button onClick={() => setMostrarSugestoes(false)} className="text-[#64748B] hover:text-white">
                    <X className="w-3 h-3" />
                  </button>
                </div>
                {sugestoesClientes.map((cli) => (
                  <div
                    key={cli.id}
                    onClick={() => {
                      setClienteNome(cli.nome);
                      setClienteTelefone(cli.telefone);
                      if (cli.endereco_texto) setEnderecoTexto(cli.endereco_texto);
                      setMostrarSugestoes(false);
                    }}
                    className="p-2.5 hover:bg-[#1c2e47] cursor-pointer transition-colors"
                  >
                    <p className="font-bold text-xs text-white">{cli.nome}</p>
                    <p className="text-[11px] text-[#0EA5E9]">{cli.telefone}</p>
                    {cli.endereco_texto && (
                      <p className="text-[10px] text-[#9CAABC] truncate">{cli.endereco_texto}</p>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Seleção Rápida de Formas de Pagamento */}
          <div className="p-3 bg-[#0f1b2b] border-t border-[#2A405B] space-y-2">
            <div className="grid grid-cols-2 gap-2">
              <button
                onClick={() => setFormaPagamento('PIX')}
                className={`py-2 px-3 rounded-xl text-xs font-bold transition-all border flex items-center justify-center gap-1.5 cursor-pointer ${
                  formaPagamento === 'PIX'
                    ? 'bg-[#0EA5E9] text-white border-[#0EA5E9] shadow-md shadow-[#0EA5E9]/20'
                    : 'bg-[#152439] border-[#2A405B] text-[#9CAABC] hover:text-white hover:bg-[#1c2e47]'
                }`}
              >
                <QrCode className="w-3.5 h-3.5" />
                <span>❖ [ X ] Pix</span>
              </button>

              <button
                onClick={() => setModalOutrosPagamentosAberto(true)}
                className={`py-2 px-3 rounded-xl text-xs font-bold transition-all border flex items-center justify-center gap-1.5 cursor-pointer ${
                  formaPagamento !== 'PIX'
                    ? 'bg-[#8C63FF] text-white border-[#8C63FF] shadow-md shadow-[#8C63FF]/20'
                    : 'bg-[#152439] border-[#2A405B] text-[#9CAABC] hover:text-white hover:bg-[#1c2e47]'
                }`}
              >
                <CreditCard className="w-3.5 h-3.5" />
                <span>[ R ] Outros pagamentos</span>
              </button>
            </div>

            {/* Botões Auxiliares: [ E ] Entrega | [ T ] CPF/CNPJ | [ Y ] Ajustar R$ */}
            <div className="grid grid-cols-3 gap-2">
              <button
                onClick={() => setTipoAtendimento((prev) => (prev === 'DELIVERY' ? 'BALCAO' : 'DELIVERY'))}
                className={`py-1.5 px-2 rounded-xl text-[11px] font-bold border transition-all text-center cursor-pointer ${
                  tipoAtendimento === 'DELIVERY'
                    ? 'border-[#0EA5E9]/50 text-[#0EA5E9] bg-[#0EA5E9]/10'
                    : 'border-[#2A405B] text-[#9CAABC] hover:text-white'
                }`}
              >
                [ E ] {tipoAtendimento === 'DELIVERY' ? 'Entrega' : 'Balcão'}
              </button>

              <button
                onClick={() => setModalCpfAberto(true)}
                className={`py-1.5 px-2 rounded-xl text-[11px] font-bold border transition-all text-center cursor-pointer ${
                  cpfCnpj
                    ? 'border-[#0EA5E9] text-[#0EA5E9] bg-[#0EA5E9]/10'
                    : 'border-[#2A405B] text-[#9CAABC] hover:text-white'
                }`}
              >
                [ T ] CPF/CNPJ
              </button>

              <button
                onClick={() => setModalAjusteAberto(true)}
                className={`py-1.5 px-2 rounded-xl text-[11px] font-bold border transition-all text-center cursor-pointer ${
                  desconto > 0 || acrescimo > 0
                    ? 'border-[#F59E0B] text-[#F59E0B] bg-[#F59E0B]/10'
                    : 'border-[#2A405B] text-[#9CAABC] hover:text-white'
                }`}
              >
                [ Y ] Ajustar R$
              </button>
            </div>

            {/* BOTÃO PRINCIPAL: [ ENTER ] GERAR PEDIDO + SALVAR RASCUNHO */}
            <div className="flex items-center gap-2 pt-1">
              <button
                disabled={gerandoPedido || itensCarrinho.length === 0}
                onClick={handleGerarPedido}
                className="flex-1 py-3 px-4 bg-gradient-to-r from-[#0EA5E9] via-[#0284C7] to-[#0369A1] hover:from-[#38BDF8] hover:to-[#0EA5E9] text-white font-extrabold text-sm rounded-xl transition-all shadow-lg shadow-[#0EA5E9]/25 flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
              >
                {gerandoPedido ? (
                  <RefreshCw className="w-5 h-5 animate-spin" />
                ) : (
                  <>
                    <span>[ ENTER ] Gerar pedido</span>
                    <ArrowRight className="w-4 h-4" />
                  </>
                )}
              </button>

              <button
                onClick={salvarRascunhoAtual}
                title="Salvar como Rascunho"
                className="p-3 bg-[#152439] hover:bg-[#1c2e47] border border-[#2A405B] hover:border-[#8C63FF] rounded-xl text-[#9CAABC] hover:text-white transition-all cursor-pointer shadow-md"
              >
                <Save className="w-5 h-5 text-[#8C63FF]" />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* ======================================================== */}
      {/* MODAL DE CONFIGURAÇÃO DE PRODUTO / PIZZA / ADICIONAIS */}
      {/* ======================================================== */}
      {modalProdutoAberto && produtoConfigurando && (
        <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-xs flex items-center justify-center p-4 animate-in fade-in duration-200">
          <div className="bg-[#152439] border border-[#2A405B] rounded-2xl w-full max-w-xl max-h-[92vh] flex flex-col shadow-2xl overflow-hidden animate-in zoom-in-95 duration-200">
            {/* Topo Modal */}
            <div className="p-4 border-b border-[#2A405B] flex items-center justify-between bg-[#121f30]">
              <div>
                <h3 className="text-base font-extrabold text-white">{produtoConfigurando.nome}</h3>
                <p className="text-xs text-[#10B981] font-bold mt-0.5">
                  Base: {formatarMoeda(produtoConfigurando.preco_promocional || produtoConfigurando.preco)}
                </p>
              </div>
              <button
                onClick={() => setModalProdutoAberto(false)}
                className="p-1.5 text-[#9CAABC] hover:text-white rounded-lg hover:bg-[#1c2e47]"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Conteúdo Modal com Scroll */}
            <div className="p-4 overflow-y-auto space-y-4 flex-1">
              {/* Quantidade */}
              <div className="flex items-center justify-between bg-[#0B132B] p-3 rounded-xl border border-[#2A405B]">
                <span className="text-xs font-bold text-white">Quantidade</span>
                <div className="flex items-center gap-3">
                  <button
                    type="button"
                    onClick={() => setQuantConfig((q) => Math.max(1, q - 1))}
                    className="w-8 h-8 rounded-lg bg-[#152439] border border-[#2A405B] flex items-center justify-center text-white hover:bg-[#2A405B] cursor-pointer"
                  >
                    <Minus className="w-4 h-4" />
                  </button>
                  <span className="font-extrabold text-sm text-white w-6 text-center">{quantConfig}</span>
                  <button
                    type="button"
                    onClick={() => setQuantConfig((q) => q + 1)}
                    className="w-8 h-8 rounded-lg bg-[#152439] border border-[#2A405B] flex items-center justify-center text-white hover:bg-[#2A405B] cursor-pointer"
                  >
                    <Plus className="w-4 h-4" />
                  </button>
                </div>
              </div>

              {/* Se for Pizza: Seleção de Sabores */}
              {isPizzaAtual && sabores.length > 0 && (
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <label className="text-xs font-bold text-white uppercase tracking-wider flex items-center gap-1.5">
                      <Sparkles className="w-3.5 h-3.5 text-[#8C63FF]" />
                      Escolher Sabores (Máx {maxSaboresPizzaAtual})
                    </label>

                    {/* Botões de Fração gerados dinamicamente com base no tamanho da Pizza */}
                    <div className="flex gap-1">
                      {Array.from({ length: maxSaboresPizzaAtual }, (_, i) => i + 1).map((n) => (
                        <button
                          key={n}
                          type="button"
                          onClick={() => {
                            setNumFracoesPizza(n);
                            setSaboresEscolhidos([]);
                          }}
                          className={`px-2.5 py-1 rounded-lg text-[11px] font-bold border transition-all cursor-pointer ${
                            numFracoesPizza === n
                              ? 'bg-[#8C63FF] text-white border-[#8C63FF] shadow-sm'
                              : 'bg-[#0B132B] border-[#2A405B] text-[#9CAABC] hover:text-white'
                          }`}
                        >
                          {n} Sabor{n > 1 ? 'es' : ''}
                        </button>
                      ))}
                    </div>
                  </div>

                  {/* Campo de Busca Rápida de Sabores */}
                  <div className="relative">
                    <input
                      type="text"
                      value={buscaSaborModal}
                      onChange={(e) => setBuscaSaborModal(e.target.value)}
                      placeholder="Buscar sabor..."
                      className="w-full bg-[#0B132B] border border-[#2A405B] text-xs text-white rounded-xl pl-8 pr-3 py-1.5 focus:outline-none focus:border-[#8C63FF]"
                    />
                    <Search className="w-3.5 h-3.5 text-[#64748B] absolute left-2.5 top-1/2 -translate-y-1/2" />
                  </div>

                  {/* Grid de Sabores */}
                  <div className="max-h-40 overflow-y-auto border border-[#2A405B] rounded-xl p-2 grid grid-cols-2 gap-1.5 bg-[#0B132B]">
                    {saboresFiltradosModal.map((sab) => {
                      const selecionado = saboresEscolhidos.some((s) => s.saborId === sab.id);
                      return (
                        <button
                          key={sab.id}
                          type="button"
                          onClick={() => {
                            if (selecionado) {
                              setSaboresEscolhidos((prev) => prev.filter((s) => s.saborId !== sab.id));
                            } else {
                              if (saboresEscolhidos.length >= numFracoesPizza) {
                                notificar(`Você selecionou o modo de ${numFracoesPizza} sabor(es).`, 'info');
                                return;
                              }
                              const fracao = numFracoesPizza === 1 ? '1/1' : `1/${numFracoesPizza}`;
                              setSaboresEscolhidos((prev) => [...prev, { saborId: sab.id, saborNome: sab.nome, fracao }]);
                            }
                          }}
                          className={`p-2 rounded-lg text-left text-xs font-semibold border transition-all flex items-center justify-between cursor-pointer ${
                            selecionado
                              ? 'bg-[#8C63FF]/20 border-[#8C63FF] text-white font-bold'
                              : 'bg-[#152439] border-[#2A405B] text-[#9CAABC] hover:text-white'
                          }`}
                        >
                          <span className="truncate">{sab.nome}</span>
                          {selecionado && <Check className="w-3.5 h-3.5 text-[#8C63FF] shrink-0" />}
                        </button>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* Se for Pizza: Seleção de Bordas Recheadas */}
              {isPizzaAtual && (
                <div className="space-y-2">
                  <label className="text-xs font-bold text-white uppercase tracking-wider flex items-center gap-1.5">
                    <Tag className="w-3.5 h-3.5 text-[#0EA5E9]" />
                    Borda Recheada
                  </label>
                  <div className="grid grid-cols-2 gap-2 max-h-36 overflow-y-auto">
                    <button
                      type="button"
                      onClick={() => setBordaEscolhida(null)}
                      className={`p-2.5 rounded-xl text-left text-xs font-semibold border transition-all cursor-pointer ${
                        !bordaEscolhida
                          ? 'bg-[#0EA5E9]/20 border-[#0EA5E9] text-white font-bold shadow-sm'
                          : 'bg-[#0B132B] border-[#2A405B] text-[#9CAABC] hover:text-white'
                      }`}
                    >
                      Sem Borda
                    </button>
                    {bordas.map((b) => {
                      const precoBorda = obterPrecoBordaParaProduto(b, produtoConfigurando.id);
                      const selecionada = bordaEscolhida?.bordaId === b.id;
                      return (
                        <button
                          key={b.id}
                          type="button"
                          onClick={() => setBordaEscolhida({ bordaId: b.id, bordaNome: b.nome, preco: precoBorda })}
                          className={`p-2.5 rounded-xl text-left text-xs font-semibold border transition-all flex items-center justify-between cursor-pointer ${
                            selecionada
                              ? 'bg-[#0EA5E9]/20 border-[#0EA5E9] text-white font-bold shadow-sm'
                              : 'bg-[#0B132B] border-[#2A405B] text-[#9CAABC] hover:text-white'
                          }`}
                        >
                          <span className="truncate">{b.nome}</span>
                          <span className="text-[10px] text-[#10B981] font-bold shrink-0 ml-1">
                            +{formatarMoeda(precoBorda)}
                          </span>
                        </button>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* Adicionais / Opcionais */}
              {adicionais.length > 0 && !isPizzaAtual && (
                <div className="space-y-2">
                  <label className="text-xs font-bold text-white uppercase tracking-wider flex items-center gap-1.5">
                    <Plus className="w-3.5 h-3.5 text-[#10B981]" />
                    Adicionais e Opcionais
                  </label>
                  <div className="grid grid-cols-2 gap-2 max-h-36 overflow-y-auto">
                    {adicionais.map((ad) => {
                      const adicItem = adicionaisEscolhidos.find((a) => a.adicionalId === ad.id);
                      const selecionado = !!adicItem;
                      return (
                        <button
                          key={ad.id}
                          type="button"
                          onClick={() => {
                            if (selecionado) {
                              setAdicionaisEscolhidos((prev) => prev.filter((a) => a.adicionalId !== ad.id));
                            } else {
                              setAdicionaisEscolhidos((prev) => [...prev, { adicionalId: ad.id, nome: ad.nome, quantidade: 1, valor: Number(ad.preco || 0) }]);
                            }
                          }}
                          className={`p-2.5 rounded-xl text-left text-xs font-semibold border transition-all flex items-center justify-between cursor-pointer ${
                            selecionado
                              ? 'bg-[#10B981]/20 border-[#10B981] text-white font-bold shadow-sm'
                              : 'bg-[#0B132B] border-[#2A405B] text-[#9CAABC] hover:text-white'
                          }`}
                        >
                          <span className="truncate">{ad.nome}</span>
                          <span className="text-[10px] text-[#10B981] font-bold shrink-0 ml-1">
                            +{formatarMoeda(ad.preco)}
                          </span>
                        </button>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* Observação do Item */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-white uppercase tracking-wider">
                  Observações do Item
                </label>
                <input
                  type="text"
                  value={obsConfig}
                  onChange={(e) => setObsConfig(e.target.value)}
                  placeholder="Ex: Sem cebola, massa fina, bem assada..."
                  className="w-full bg-[#0B132B] border border-[#2A405B] text-xs text-white rounded-xl px-3 py-2.5 focus:outline-none focus:border-[#8C63FF]"
                />
              </div>
            </div>

            {/* Footer Modal */}
            <div className="p-4 border-t border-[#2A405B] bg-[#121f30] flex items-center justify-between gap-3">
              <div>
                <span className="text-[10px] text-[#9CAABC] uppercase font-bold block">Total do Item</span>
                <span className="text-base font-extrabold text-[#10B981]">
                  {formatarMoeda(precoCalculadoConfig)}
                </span>
              </div>

              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={() => setModalProdutoAberto(false)}
                  className="px-4 py-2 bg-[#152439] hover:bg-[#2A405B] border border-[#2A405B] text-white text-xs font-semibold rounded-xl transition-all cursor-pointer"
                >
                  Cancelar
                </button>

                <button
                  type="button"
                  onClick={salvarItemNoCarrinho}
                  className="px-6 py-2 bg-gradient-to-r from-[#0EA5E9] to-[#0284C7] hover:from-[#38BDF8] hover:to-[#0EA5E9] text-white text-xs font-bold rounded-xl transition-all shadow-md shadow-[#0EA5E9]/20 cursor-pointer"
                >
                  {itemEditandoId ? 'Atualizar Item' : 'Adicionar ao Pedido'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* MODAL 2: OUTROS PAGAMENTOS (DINHEIRO, CARTÃO CRÉDITO/DÉBITO) */}
      {modalOutrosPagamentosAberto && (
        <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-[#152439] border border-[#2A405B] rounded-2xl w-full max-w-sm overflow-hidden shadow-2xl p-5 space-y-4">
            <h3 className="text-sm font-extrabold text-white flex items-center gap-2">
              <CreditCard className="w-4 h-4 text-[#8C63FF]" />
              Forma de Pagamento
            </h3>

            <div className="space-y-2">
              {[
                { id: 'PIX', label: 'PIX (Chave ou QR Code)' },
                { id: 'DINHEIRO', label: 'Dinheiro' },
                { id: 'CARTAO_CREDITO', label: 'Cartão de Crédito' },
                { id: 'CARTAO_DEBITO', label: 'Cartão de Débito' },
                { id: 'OUTRO', label: 'Outro / Vale Refeição' },
              ].map((f) => (
                <button
                  key={f.id}
                  onClick={() => setFormaPagamento(f.id as any)}
                  className={`w-full p-3 rounded-xl text-left text-xs font-bold border transition-all flex items-center justify-between cursor-pointer ${
                    formaPagamento === f.id
                      ? 'bg-[#8C63FF] text-white border-[#8C63FF] shadow-md'
                      : 'bg-[#0B132B] border-[#2A405B] text-[#9CAABC] hover:text-white'
                  }`}
                >
                  <span>{f.label}</span>
                  {formaPagamento === f.id && <Check className="w-4 h-4" />}
                </button>
              ))}
            </div>

            {formaPagamento === 'DINHEIRO' && (
              <div className="pt-2 border-t border-[#2A405B] space-y-1">
                <label className="text-[11px] font-bold text-[#9CAABC]">Troco para quanto?</label>
                <input
                  type="number"
                  step="0.50"
                  value={trocoPara}
                  onChange={(e) => setTrocoPara(e.target.value)}
                  placeholder="Ex: 50.00 (Deixe vazio se não precisar)"
                  className="w-full bg-[#0B132B] border border-[#2A405B] text-xs text-white rounded-xl px-3 py-2 focus:outline-none focus:border-[#8C63FF]"
                />
              </div>
            )}

            <button
              onClick={() => setModalOutrosPagamentosAberto(false)}
              className="w-full py-2.5 bg-[#8C63FF] hover:bg-[#7847eb] text-white font-bold text-xs rounded-xl transition-all cursor-pointer shadow-md"
            >
              Confirmar Pagamento
            </button>
          </div>
        </div>
      )}

      {/* MODAL 3: AJUSTAR R$ (DESCONTO / ACRÉSCIMO / TAXA ENTREGA) */}
      {modalAjusteAberto && (
        <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-[#152439] border border-[#2A405B] rounded-2xl w-full max-w-sm overflow-hidden shadow-2xl p-5 space-y-4">
            <h3 className="text-sm font-extrabold text-white flex items-center gap-2">
              <DollarSign className="w-4 h-4 text-[#F59E0B]" />
              Ajustar Valores do Pedido
            </h3>

            <div className="space-y-3">
              <div>
                <label className="text-[11px] font-bold text-[#9CAABC] block mb-1">Desconto (R$)</label>
                <input
                  type="number"
                  step="0.50"
                  value={desconto || ''}
                  onChange={(e) => setDesconto(Number(e.target.value) || 0)}
                  placeholder="0.00"
                  className="w-full bg-[#0B132B] border border-[#2A405B] text-xs text-white rounded-xl px-3 py-2 focus:outline-none focus:border-[#EF4444]"
                />
              </div>

              <div>
                <label className="text-[11px] font-bold text-[#9CAABC] block mb-1">Acréscimo / Outros (R$)</label>
                <input
                  type="number"
                  step="0.50"
                  value={acrescimo || ''}
                  onChange={(e) => setAcrescimo(Number(e.target.value) || 0)}
                  placeholder="0.00"
                  className="w-full bg-[#0B132B] border border-[#2A405B] text-xs text-white rounded-xl px-3 py-2 focus:outline-none focus:border-[#F59E0B]"
                />
              </div>

              {tipoAtendimento === 'DELIVERY' && (
                <div>
                  <label className="text-[11px] font-bold text-[#9CAABC] block mb-1">Taxa de Entrega (R$)</label>
                  <input
                    type="number"
                    step="0.50"
                    value={taxaEntrega || ''}
                    onChange={(e) => setTaxaEntrega(Number(e.target.value) || 0)}
                    placeholder="0.00"
                    className="w-full bg-[#0B132B] border border-[#2A405B] text-xs text-white rounded-xl px-3 py-2 focus:outline-none focus:border-[#0EA5E9]"
                  />
                </div>
              )}
            </div>

            <button
              onClick={() => setModalAjusteAberto(false)}
              className="w-full py-2.5 bg-[#0EA5E9] hover:bg-[#0284C7] text-white font-bold text-xs rounded-xl transition-all cursor-pointer shadow-md"
            >
              Salvar Ajustes
            </button>
          </div>
        </div>
      )}

      {/* MODAL 4: CPF / CNPJ NA NOTA */}
      {modalCpfAberto && (
        <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-[#152439] border border-[#2A405B] rounded-2xl w-full max-w-sm overflow-hidden shadow-2xl p-5 space-y-4">
            <h3 className="text-sm font-extrabold text-white flex items-center gap-2">
              <FileText className="w-4 h-4 text-[#0EA5E9]" />
              CPF / CNPJ na Nota
            </h3>

            <div>
              <label className="text-[11px] font-bold text-[#9CAABC] block mb-1">Informe o documento</label>
              <input
                type="text"
                value={cpfCnpj}
                onChange={(e) => setCpfCnpj(e.target.value)}
                placeholder="000.000.000-00"
                className="w-full bg-[#0B132B] border border-[#2A405B] text-xs text-white rounded-xl px-3 py-2 focus:outline-none focus:border-[#0EA5E9]"
              />
            </div>

            <div className="flex gap-2">
              <button
                onClick={() => {
                  setCpfCnpj('');
                  setModalCpfAberto(false);
                }}
                className="flex-1 py-2 bg-[#152439] border border-[#2A405B] text-[#9CAABC] hover:text-white font-semibold text-xs rounded-xl transition-all cursor-pointer"
              >
                Limpar
              </button>
              <button
                onClick={() => setModalCpfAberto(false)}
                className="flex-1 py-2 bg-[#0EA5E9] hover:bg-[#0284C7] text-white font-bold text-xs rounded-xl transition-all shadow-md cursor-pointer"
              >
                Confirmar
              </button>
            </div>
          </div>
        </div>
      )}

      {/* MODAL 5: OBSERVAÇÃO GERAL DO PEDIDO */}
      {modalObsPedidoAberto && (
        <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-[#152439] border border-[#2A405B] rounded-2xl w-full max-w-md overflow-hidden shadow-2xl p-5 space-y-4">
            <h3 className="text-sm font-extrabold text-white flex items-center gap-2">
              <MessageSquare className="w-4 h-4 text-[#0EA5E9]" />
              Observações Gerais do Pedido
            </h3>

            <textarea
              rows={3}
              value={observacaoPedido}
              onChange={(e) => setObservacaoPedido(e.target.value)}
              placeholder="Ex: Entregar após as 20h, interfone 102, levar máquina de cartão..."
              className="w-full bg-[#0B132B] border border-[#2A405B] text-xs text-white rounded-xl p-3 focus:outline-none focus:border-[#0EA5E9]"
            />

            <div className="flex justify-end gap-2">
              <button
                onClick={() => setModalObsPedidoAberto(false)}
                className="px-4 py-2 bg-[#0EA5E9] text-white font-bold text-xs rounded-xl shadow-md cursor-pointer"
              >
                Concluir
              </button>
            </div>
          </div>
        </div>
      )}

      {/* MODAL 6: LISTA DE RASCUNHOS SALVOS */}
      {modalRascunhosAberto && (
        <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-[#152439] border border-[#2A405B] rounded-2xl w-full max-w-lg max-h-[80vh] flex flex-col shadow-2xl overflow-hidden">
            <div className="p-4 border-b border-[#2A405B] flex items-center justify-between bg-[#121f30]">
              <h3 className="text-sm font-extrabold text-white flex items-center gap-2">
                <Save className="w-4 h-4 text-[#0EA5E9]" />
                Rascunhos Salvos ({rascunhos.length})
              </h3>
              <button onClick={() => setModalRascunhosAberto(false)} className="text-[#9CAABC] hover:text-white">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-4 overflow-y-auto space-y-2 flex-1">
              {rascunhos.length === 0 ? (
                <div className="py-12 text-center text-xs text-[#64748B]">
                  Nenhum rascunho salvo no momento.
                </div>
              ) : (
                rascunhos.map((rasc) => (
                  <div
                    key={rasc.id}
                    className="bg-[#0B132B] border border-[#2A405B] p-3.5 rounded-xl flex items-center justify-between gap-3 hover:border-[#0EA5E9] transition-all"
                  >
                    <div>
                      <p className="font-bold text-xs text-white">{rasc.clienteNome}</p>
                      <p className="text-[11px] text-[#9CAABC]">
                        {rasc.itens.length} itens • {formatarMoeda(rasc.total)} • {new Date(rasc.criadoEm).toLocaleTimeString('pt-BR')}
                      </p>
                    </div>

                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => restaurarRascunho(rasc)}
                        className="px-3 py-1.5 bg-[#0EA5E9] hover:bg-[#0284C7] text-white font-bold text-xs rounded-lg transition-colors cursor-pointer"
                      >
                        Restaurar
                      </button>
                      <button
                        onClick={() => setRascunhos((prev) => prev.filter((r) => r.id !== rasc.id))}
                        className="p-1.5 text-[#EF4444] hover:bg-[#EF4444]/10 rounded-lg transition-colors"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      )}

      {/* MODAL 7: SUCESSO DO PEDIDO GERADO */}
      {modalSucessoAberto && pedidoGerado && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-[#152439] border border-[#2A405B] rounded-2xl w-full max-w-md shadow-2xl p-6 text-center space-y-4 animate-in zoom-in-95 duration-200">
            <div className="w-16 h-16 rounded-full bg-[#10B981]/20 border border-[#10B981]/30 flex items-center justify-center mx-auto text-[#10B981]">
              <CheckCircle2 className="w-8 h-8" />
            </div>

            <div>
              <h3 className="text-lg font-extrabold text-white">Pedido Gerado com Sucesso!</h3>
              <p className="text-xs text-[#9CAABC] mt-1">
                Número do Pedido: <strong className="text-white text-sm">#{pedidoGerado.numero || pedidoGerado.id}</strong>
              </p>
              <p className="text-xs text-[#10B981] font-bold mt-1">
                Total: {formatarMoeda(pedidoGerado.valorTotal || pedidoGerado.total)}
              </p>
            </div>

            <div className="pt-2 border-t border-[#2A405B] flex flex-col gap-2">
              <button
                onClick={() => {
                  window.print();
                }}
                className="w-full py-2.5 bg-[#152439] hover:bg-[#1c2e47] border border-[#2A405B] text-white font-semibold text-xs rounded-xl flex items-center justify-center gap-2 transition-all cursor-pointer"
              >
                <Printer className="w-4 h-4 text-[#8C63FF]" />
                <span>Imprimir Comanda</span>
              </button>

              <button
                onClick={() => setModalSucessoAberto(false)}
                className="w-full py-3 bg-gradient-to-r from-[#0EA5E9] to-[#0284C7] text-white font-bold text-xs rounded-xl shadow-lg shadow-[#0EA5E9]/20 transition-all cursor-pointer"
              >
                Iniciar Novo Pedido
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
