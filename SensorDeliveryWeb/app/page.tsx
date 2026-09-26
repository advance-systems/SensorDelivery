'use client';

import { useEffect, useMemo, useRef, useState } from 'react';
import {
  ArrowLeft,
  ArrowRight,
  Bike,
  Building,
  Check,
  ChevronLeft,
  ChevronRight,
  Clock3,
  Copy,
  CreditCard,
  DollarSign,
  Home,
  Layers,
  Loader2,
  MapPin,
  Menu,
  Minus,
  PackageCheck,
  Phone,
  Plus,
  QrCode,
  RefreshCw,
  Search,
  ShoppingBag,
  Sparkles,
  Store,
  Tag,
  Trash2,
  User,
  UserRound,
  X,
} from 'lucide-react';
import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle } from '@/components/ui/sheet';
import {
  type Adicional,
  type Borda,
  type Categoria,
  type LojaStatus,
  type OpcoesProduto,
  type Produto,
  type Sabor,
  createPedido,
  fetchCategorias,
  fetchEmpresas,
  fetchLojaStatus,
  fetchProdutoOpcoes,
  fetchProdutos,
  formatImageUrl,
} from '@/lib/api';

const money = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });

function formatarTelefone(valor: string): string {
  const digits = valor.replace(/\D/g, '').slice(0, 11);
  if (digits.length <= 2) {
    return digits.length > 0 ? `(${digits}` : '';
  }
  if (digits.length <= 6) {
    return `(${digits.slice(0, 2)}) ${digits.slice(2)}`;
  }
  if (digits.length <= 10) {
    return `(${digits.slice(0, 2)}) ${digits.slice(2, 6)}-${digits.slice(6)}`;
  }
  return `(${digits.slice(0, 2)}) ${digits.slice(2, 7)}-${digits.slice(7, 11)}`;
}

export interface ItemCarrinhoCustomizado {
  idTemp: string;
  produtoId: string;
  produtoNome: string;
  imagemUrl?: string | null;
  precoUnitario: number;
  quantidade: number;
  observacoes?: string;
  sabores?: Array<{ saborId: string; saborNome: string; fracao: string }>;
  borda?: { bordaId: string; bordaNome: string; preco: number };
  adicionais?: Array<{ adicionalId: string; nome: string; quantidade: number; valor: number }>;
  valorTotal: number;
}

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
  if (
    nomeLower.includes('família') ||
    nomeLower.includes('familia') ||
    nomeLower.includes('famiia') ||
    nomeLower.includes('40cm')
  ) {
    return 4;
  }
  if (nomeLower.includes('gigante') || nomeLower.includes('45cm') || nomeLower.includes('50cm')) {
    return 4;
  }
  return 2;
}

export default function HomePage() {
  const [empresaId, setEmpresaId] = useState<string>('');
  const [lojaStatus, setLojaStatus] = useState<LojaStatus | null>(null);
  const [categories, setCategories] = useState<Categoria[]>([]);
  const [products, setProducts] = useState<Produto[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [category, setCategory] = useState('Todos');
  const [search, setSearch] = useState('');
  const [cartOpen, setCartOpen] = useState(false);
  const [cartItems, setCartItems] = useState<ItemCarrinhoCustomizado[]>([]);

  // Estado da Tela/Modal de Montagem
  const [produtoConfigurando, setProdutoConfigurando] = useState<Produto | null>(null);
  const [carregandoOpcoes, setCarregandoOpcoes] = useState(false);
  const [opcoesProduto, setOpcoesProduto] = useState<OpcoesProduto | null>(null);
  const [quantConfig, setQuantConfig] = useState(1);
  const [obsConfig, setObsConfig] = useState('');
  const [saboresEscolhidos, setSaboresEscolhidos] = useState<Array<{ saborId: string; saborNome: string; fracao: string }>>([]);
  const [bordaEscolhida, setBordaEscolhida] = useState<{ bordaId: string; bordaNome: string; preco: number } | null>(null);
  const [adicionaisEscolhidos, setAdicionaisEscolhidos] = useState<
    Array<{ adicionalId: string; nome: string; quantidade: number; valor: number }>
  >([]);
  const [numFracoesPizza, setNumFracoesPizza] = useState<number>(1);
  const [buscaSaborModal, setBuscaSaborModal] = useState('');

  // ==========================================
  // ESTADO DO CHECKOUT (ENTREGA / RETIRADA)
  // ==========================================
  const [modalCheckoutAberto, setModalCheckoutAberto] = useState(false);
  const [checkoutStep, setCheckoutStep] = useState<'TIPO' | 'DADOS' | 'PAGAMENTO' | 'CONFIRMACAO'>('TIPO');
  const [tipoAtendimento, setTipoAtendimento] = useState<'ENTREGA' | 'BALCAO'>('ENTREGA');

  // Dados do Cliente & Endereço
  const [clienteNome, setClienteNome] = useState('');
  const [clienteTelefone, setClienteTelefone] = useState('');
  const [enderecoLogradouro, setEnderecoLogradouro] = useState('');
  const [enderecoNumero, setEnderecoNumero] = useState('');
  const [enderecoBairro, setEnderecoBairro] = useState('');
  const [enderecoComplemento, setEnderecoComplemento] = useState('');
  const [observacaoPedido, setObservacaoPedido] = useState('');

  // Pagamento
  const [formaPagamento, setFormaPagamento] = useState<'PIX' | 'CARTAO_CREDITO' | 'CARTAO_DEBITO' | 'DINHEIRO'>('PIX');
  const [trocoPara, setTrocoPara] = useState('');
  const [enviandoPedido, setEnviandoPedido] = useState(false);
  const [pedidoRealizado, setPedidoRealizado] = useState<any>(null);
  const [pixDados, setPixDados] = useState<any>(null);
  const [copiadoPix, setCopiadoPix] = useState(false);

  const categoriesRef = useRef<HTMLDivElement | null>(null);
  const [canScrollLeft, setCanScrollLeft] = useState(false);
  const [canScrollRight, setCanScrollRight] = useState(true);

  const checkCategoryScroll = () => {
    const el = categoriesRef.current;
    if (!el) return;
    setCanScrollLeft(el.scrollLeft > 10);
    setCanScrollRight(el.scrollLeft < el.scrollWidth - el.clientWidth - 10);
  };

  const scrollCategories = (direction: 'left' | 'right') => {
    const el = categoriesRef.current;
    if (!el) return;
    const scrollAmount = 280;
    el.scrollBy({
      left: direction === 'left' ? -scrollAmount : scrollAmount,
      behavior: 'smooth',
    });
  };

  useEffect(() => {
    const el = categoriesRef.current;
    if (!el) return;
    checkCategoryScroll();
    el.addEventListener('scroll', checkCategoryScroll);
    window.addEventListener('resize', checkCategoryScroll);
    return () => {
      el.removeEventListener('scroll', checkCategoryScroll);
      window.removeEventListener('resize', checkCategoryScroll);
    };
  }, [categories]);

  // Carregar dados iniciais da API
  const carregarDados = async () => {
    setLoading(true);
    setError(null);
    try {
      const empresas = await fetchEmpresas();
      const currentEmpresaId = empresas.length > 0 ? empresas[0].id : '';
      setEmpresaId(currentEmpresaId);

      const [statusRes, catRes, prodRes] = await Promise.all([
        fetchLojaStatus(currentEmpresaId),
        fetchCategorias(currentEmpresaId),
        fetchProdutos(currentEmpresaId),
      ]);

      setLojaStatus(statusRes);
      setCategories(catRes);
      setProducts(prodRes);
    } catch (err) {
      console.error('Erro ao carregar cardápio da API:', err);
      setError('Não foi possível carregar os dados do cardápio.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    carregarDados();
  }, []);

  // Lista de categorias com "Todos" na primeira posição
  const categoryNames = useMemo(() => {
    return ['Todos', ...categories.map((c) => c.nome)];
  }, [categories]);

  // Produtos filtrados por categoria e busca
  const filtered = useMemo(() => {
    const term = search.trim().toLocaleLowerCase('pt-BR');
    return products.filter((p) => {
      const matchCategory =
        category === 'Todos' ||
        p.categoria_nome === category ||
        categories.find((c) => c.id === p.categoria_id)?.nome === category;

      const pNome = (p.nome || '').toLocaleLowerCase('pt-BR');
      const pDesc = (p.descricao || '').toLocaleLowerCase('pt-BR');
      const matchSearch = !term || pNome.includes(term) || pDesc.includes(term);

      return matchCategory && matchSearch;
    });
  }, [category, search, products, categories]);

  // Totais do carrinho e taxas
  const cartCount = cartItems.reduce((sum, item) => sum + item.quantidade, 0);
  const subtotalCart = cartItems.reduce((sum, item) => sum + item.valorTotal, 0);
  const taxaEntregaValor = tipoAtendimento === 'ENTREGA' ? (lojaStatus?.taxaEntregaPadrao ?? 5) : 0;
  const totalPedidoFinal = subtotalCart + taxaEntregaValor;

  function alterarQuantidadeItemCarrinho(idTemp: string, diferenca: number) {
    setCartItems((prev) =>
      prev
        .map((it) => {
          if (it.idTemp === idTemp) {
            const novaQuant = it.quantidade + diferenca;
            if (novaQuant <= 0) return null;
            const precoUnit = it.valorTotal / it.quantidade;
            return {
              ...it,
              quantidade: novaQuant,
              valorTotal: precoUnit * novaQuant,
            };
          }
          return it;
        })
        .filter(Boolean) as ItemCarrinhoCustomizado[]
    );
  }

  function removerItemCarrinho(idTemp: string) {
    setCartItems((prev) => prev.filter((it) => it.idTemp !== idTemp));
  }

  // Abrir Tela de Montagem do Produto
  const abrirMontagemProduto = async (product: Produto) => {
    setProdutoConfigurando(product);
    setQuantConfig(1);
    setObsConfig('');
    setSaboresEscolhidos([]);
    setBordaEscolhida(null);
    setAdicionaisEscolhidos([]);
    setNumFracoesPizza(1);
    setBuscaSaborModal('');
    setCarregandoOpcoes(true);

    try {
      const opcoes = await fetchProdutoOpcoes(product.id, empresaId);
      setOpcoesProduto(opcoes);
    } catch (err) {
      console.error('Erro ao buscar opções de montagem do produto:', err);
      setOpcoesProduto(null);
    } finally {
      setCarregandoOpcoes(false);
    }
  };

  const isPizzaAtual = useMemo(() => {
    return ehPizzaProduto(produtoConfigurando, categories);
  }, [produtoConfigurando, categories]);

  const maxSaboresPizzaAtual = useMemo(() => {
    return obterMaxSaboresPizza(produtoConfigurando);
  }, [produtoConfigurando]);

  const saboresFiltrados = useMemo(() => {
    if (!opcoesProduto?.sabores) return [];
    const term = buscaSaborModal.trim().toLowerCase();
    if (!term) return opcoesProduto.sabores;
    return opcoesProduto.sabores.filter(
      (s) => s.nome.toLowerCase().includes(term) || (s.descricao && s.descricao.toLowerCase().includes(term))
    );
  }, [opcoesProduto, buscaSaborModal]);

  // Preço calculado da montagem
  const precoCalculadoItem = useMemo(() => {
    if (!produtoConfigurando) return 0;
    const base =
      Number(
        produtoConfigurando.preco_promocional && Number(produtoConfigurando.preco_promocional) > 0
          ? produtoConfigurando.preco_promocional
          : produtoConfigurando.preco
      ) || 0;
    const extraBorda = bordaEscolhida?.preco || 0;
    const extraAdicionais = adicionaisEscolhidos.reduce((acc, a) => acc + a.valor * a.quantidade, 0);
    return (base + extraBorda + extraAdicionais) * quantConfig;
  }, [produtoConfigurando, quantConfig, bordaEscolhida, adicionaisEscolhidos]);

  // Salvar Produto Montado no Carrinho
  const salvarMontagemNoCarrinho = () => {
    if (!produtoConfigurando) return;

    const baseUnit =
      Number(
        produtoConfigurando.preco_promocional && Number(produtoConfigurando.preco_promocional) > 0
          ? produtoConfigurando.preco_promocional
          : produtoConfigurando.preco
      ) || 0;

    const novoItem: ItemCarrinhoCustomizado = {
      idTemp: `${Date.now()}-${Math.random().toString(36).substring(2, 7)}`,
      produtoId: produtoConfigurando.id,
      produtoNome: produtoConfigurando.nome,
      imagemUrl: produtoConfigurando.imagem_url,
      precoUnitario: baseUnit,
      quantidade: quantConfig,
      observacoes: obsConfig.trim() || undefined,
      sabores: saboresEscolhidos.length > 0 ? saboresEscolhidos : undefined,
      borda: bordaEscolhida || undefined,
      adicionais: adicionaisEscolhidos.length > 0 ? adicionaisEscolhidos : undefined,
      valorTotal: precoCalculadoItem,
    };

    setCartItems((prev) => [...prev, novoItem]);
    setProdutoConfigurando(null);
    setCartOpen(true);
  };

  // Iniciar Checkout a partir do carrinho
  const iniciarCheckout = () => {
    setCartOpen(false);
    setCheckoutStep('TIPO');
    setModalCheckoutAberto(true);
  };

  // Avançar da etapa de Dados para Pagamento
  const avancarParaPagamento = () => {
    if (!clienteNome.trim() || !clienteTelefone.trim()) {
      alert('Por favor, informe seu nome e telefone.');
      return;
    }
    if (tipoAtendimento === 'ENTREGA' && (!enderecoLogradouro.trim() || !enderecoBairro.trim())) {
      alert('Por favor, informe a rua e o bairro de entrega.');
      return;
    }
    setCheckoutStep('PAGAMENTO');
  };

  // Finalizar e Enviar Pedido
  const finalizarPedidoOnline = async () => {
    if (!clienteNome.trim() || !clienteTelefone.trim()) {
      alert('Por favor, informe seu nome e telefone.');
      setCheckoutStep('DADOS');
      return;
    }

    if (tipoAtendimento === 'ENTREGA' && (!enderecoLogradouro.trim() || !enderecoBairro.trim())) {
      alert('Por favor, preencha o endereço completo de entrega.');
      setCheckoutStep('DADOS');
      return;
    }

    setEnviandoPedido(true);

    const payloadItens = cartItems.map((it) => ({
      produto_id: it.produtoId,
      produto_nome: it.produtoNome,
      quantidade: it.quantidade,
      preco_unitario: it.precoUnitario,
      valor_total: it.valorTotal,
      observacoes: it.observacoes,
      sabores: it.sabores?.map((s) => ({ sabor_id: s.saborId, nome: s.saborNome, fracao: s.fracao })),
      borda: it.borda ? { borda_id: it.borda.bordaId, nome: it.borda.bordaNome, preco: it.borda.preco } : undefined,
      adicionais: it.adicionais?.map((a) => ({ adicional_id: a.adicionalId, nome: a.nome, quantidade: a.quantidade, valor: a.valor })),
    }));

    const payload = {
      empresaId,
      clienteNome: clienteNome.trim(),
      clienteTelefone: clienteTelefone.trim(),
      tipoAtendimento,
      endereco: {
        logradouro: enderecoLogradouro.trim(),
        numero: enderecoNumero.trim(),
        bairro: enderecoBairro.trim(),
        complemento: enderecoComplemento.trim(),
      },
      observacao: observacaoPedido.trim() || undefined,
      formaPagamento,
      trocoPara: formaPagamento === 'DINHEIRO' && trocoPara ? Number(trocoPara) : undefined,
      subtotal: subtotalCart,
      taxaEntrega: taxaEntregaValor,
      total: totalPedidoFinal,
      itens: payloadItens,
    };

    const res = await createPedido(payload);
    setEnviandoPedido(false);

    if (res.sucesso) {
      setPedidoRealizado(res.pedido);
      setPixDados(res.respostaPix);
      setCartItems([]);
      setCheckoutStep('CONFIRMACAO');
    } else {
      alert(res.erro || 'Não foi possível registrar o pedido.');
    }
  };

  const copiarCodigoPix = () => {
    if (!pixDados?.copiaCola) return;
    navigator.clipboard.writeText(pixDados.copiaCola);
    setCopiadoPix(true);
    setTimeout(() => setCopiadoPix(false), 3000);
  };

  const nomeLoja = lojaStatus?.empresa?.nome || 'Sensor Delivery';
  const cidadeLoja = lojaStatus?.empresa?.cidade || 'Bombinhas · SC';
  const isAberta = lojaStatus?.aberta ?? true;
  const tempoMin = lojaStatus?.tempoEntregaMin ?? 35;
  const tempoMax = lojaStatus?.tempoEntregaMax ?? 50;

  return (
    <main className="min-h-screen pb-24 text-[#202332]">
      {/* Header */}
      <header className="sticky top-0 z-40 border-b border-black/5 bg-white/92 backdrop-blur-xl">
        <div className="mx-auto flex h-20 max-w-6xl items-center gap-4 px-4 sm:px-6">
          <button
            className="grid size-11 place-items-center rounded-2xl bg-[#fff1eb] text-[#ff4b0a] sm:hidden"
            aria-label="Abrir menu"
          >
            <Menu className="size-5" />
          </button>
          <div className="flex items-center gap-3">
            <img
              src={lojaStatus?.empresa?.logoUrl ? formatImageUrl(lojaStatus.empresa.logoUrl) : '/logo-sensor-delivery.png'}
              alt={nomeLoja}
              className="h-12 w-auto max-w-[160px] object-contain"
            />
          </div>
          <SearchBox value={search} onChange={setSearch} desktop />
          <button
            onClick={() => setCartOpen(true)}
            className="relative ml-auto grid size-12 place-items-center rounded-2xl bg-[#ff4b0a] text-white shadow-[0_8px_22px_rgba(255,75,10,.28)] transition hover:bg-[#e03f04] cursor-pointer"
            aria-label={`Abrir carrinho com ${cartCount} itens`}
          >
            <ShoppingBag className="size-5" />
            {cartCount > 0 && (
              <span className="absolute -right-1.5 -top-1.5 min-w-6 rounded-full bg-[#6c55e8] px-1.5 text-center text-xs font-bold leading-6">
                {cartCount}
              </span>
            )}
          </button>
        </div>
      </header>

      {/* Main Section */}
      <section className="mx-auto max-w-6xl px-4 pb-8 pt-5 sm:px-6 sm:pt-8">
        {/* Store Banner */}
        <div className="store-banner overflow-hidden rounded-[28px] px-6 py-6 text-white sm:px-9 sm:py-8">
          <div className="relative z-10 flex flex-col justify-between gap-7 sm:flex-row sm:items-end">
            <div>
              <div className="mb-3 inline-flex items-center gap-2 rounded-full bg-white/16 px-3 py-1.5 text-sm font-semibold backdrop-blur">
                <span className={`size-2 rounded-full ${isAberta ? 'bg-[#57e38e]' : 'bg-[#ff6b6b]'}`} />
                {isAberta ? 'Aberto agora' : 'Fechado no momento'}
              </div>
              <p className="text-sm font-medium text-white/75">{cidadeLoja}</p>
              <h1 className="mt-1 text-3xl font-extrabold tracking-[-0.03em] sm:text-4xl">
                O que você quer pedir hoje?
              </h1>
              <p className="mt-2 max-w-xl text-[15px] leading-6 text-white/80">
                {lojaStatus?.mensagem || 'Escolha seus favoritos e receba tudo quentinho onde estiver.'}
              </p>
            </div>
            <div className="flex items-center gap-3 rounded-2xl bg-white/12 px-4 py-3 backdrop-blur">
              <Clock3 className="size-5 text-[#ffd0bd]" />
              <div>
                <p className="text-xs text-white/65">Entrega estimada</p>
                <p className="font-bold">
                  {tempoMin}–{tempoMax} min
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Mobile Search Box */}
        <SearchBox value={search} onChange={setSearch} />

        {/* Categories Bar */}
        <div className="mt-7 flex items-center gap-2">
          <button
            type="button"
            onClick={() => scrollCategories('left')}
            disabled={!canScrollLeft}
            className={`grid size-10 shrink-0 place-items-center rounded-full border border-[#ebe7e4] bg-white text-[#202332] shadow-sm transition active:scale-95 ${
              canScrollLeft
                ? 'cursor-pointer text-[#ff4b0a] hover:border-[#ff4b0a]/40 hover:bg-[#fff5f0]'
                : 'cursor-not-allowed opacity-30 text-[#9a9ca5]'
            }`}
            aria-label="Rolar categorias para a esquerda"
          >
            <ChevronLeft className="size-5" />
          </button>

          <nav
            ref={categoriesRef}
            className="no-scrollbar flex flex-1 gap-2 overflow-x-auto scroll-smooth py-1"
            aria-label="Categorias"
          >
            {categoryNames.map((item) => (
              <button
                key={item}
                onClick={() => setCategory(item)}
                className={`shrink-0 rounded-full px-5 py-2.5 text-sm font-bold transition ${
                  category === item
                    ? 'bg-[#ff4b0a] text-white shadow-[0_7px_16px_rgba(255,75,10,.2)]'
                    : 'border border-[#ebe7e4] bg-white text-[#666a76] hover:border-[#ff4b0a]/35 hover:text-[#ff4b0a]'
                }`}
              >
                {item}
              </button>
            ))}
          </nav>

          <button
            type="button"
            onClick={() => scrollCategories('right')}
            disabled={!canScrollRight}
            className={`grid size-10 shrink-0 place-items-center rounded-full border border-[#ebe7e4] bg-white text-[#202332] shadow-sm transition active:scale-95 ${
              canScrollRight
                ? 'cursor-pointer text-[#ff4b0a] hover:border-[#ff4b0a]/40 hover:bg-[#fff5f0]'
                : 'cursor-not-allowed opacity-30 text-[#9a9ca5]'
            }`}
            aria-label="Rolar categorias para a direita"
          >
            <ChevronRight className="size-5" />
          </button>
        </div>

        {/* Header List */}
        <div className="mb-5 mt-7 flex items-end justify-between">
          <div>
            <p className="text-sm font-semibold text-[#ff4b0a]">Cardápio</p>
            <h2 className="text-2xl font-extrabold tracking-[-0.02em]">
              {category === 'Todos' ? 'Peça do seu jeito' : category}
            </h2>
          </div>
          <span className="text-sm text-[#858894]">
            {filtered.length} {filtered.length === 1 ? 'item' : 'itens'}
          </span>
        </div>

        {/* Loading State */}
        {loading && (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            <Loader2 className="size-9 animate-spin text-[#ff4b0a]" />
            <p className="mt-3 text-sm font-semibold text-[#747783]">Carregando cardápio...</p>
          </div>
        )}

        {/* Error State */}
        {!loading && error && (
          <div className="rounded-[24px] border border-[#fecaca] bg-[#fff5f5] p-8 text-center">
            <p className="font-bold text-[#b91c1c]">{error}</p>
            <button
              onClick={carregarDados}
              className="mt-4 inline-flex items-center gap-2 rounded-xl bg-[#ff4b0a] px-5 py-2.5 text-sm font-bold text-white shadow-sm"
            >
              <RefreshCw className="size-4" /> Tentar novamente
            </button>
          </div>
        )}

        {/* Products Grid */}
        {!loading && !error && (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {filtered.map((product) => {
              const precoFinal =
                Number(
                  product.preco_promocional && Number(product.preco_promocional) > 0
                    ? product.preco_promocional
                    : product.preco
                ) || 0;

              return (
                <article
                  key={product.id}
                  className="product-card group overflow-hidden rounded-[24px] border border-[#eee9e6] bg-white transition hover:shadow-md"
                >
                  <button
                    onClick={() => abrirMontagemProduto(product)}
                    className="block w-full text-left cursor-pointer"
                    aria-label={`Ver e montar ${product.nome}`}
                  >
                    <div className="relative h-44 overflow-hidden bg-[#fff2ec]">
                      <img
                        src={formatImageUrl(product.imagem_url)}
                        alt={product.nome}
                        className="h-full w-full object-cover transition duration-500 group-hover:scale-105"
                        onError={(e) => {
                          (e.target as HTMLImageElement).src = '/pizza-media.jpg';
                        }}
                      />
                      {product.destaque && (
                        <span className="absolute left-3 top-3 rounded-full bg-white/92 px-3 py-1.5 text-xs font-bold text-[#ff4b0a] shadow-sm">
                          Destaque
                        </span>
                      )}
                      {product.preco_promocional && Number(product.preco_promocional) > 0 && (
                        <span className="absolute right-3 top-3 rounded-full bg-[#22c55e] px-3 py-1 text-xs font-bold text-white shadow-sm">
                          Promoção
                        </span>
                      )}
                    </div>
                    <div className="p-5 pb-3">
                      <h3 className="text-[17px] font-extrabold leading-6">{product.nome}</h3>
                      <p className="mt-2 min-h-11 line-clamp-2 text-sm leading-[1.55] text-[#747783]">
                        {product.descricao || 'Delicioso item preparado com ingredientes frescos e selecionados.'}
                      </p>
                    </div>
                  </button>
                  <div className="flex items-center justify-between px-5 pb-5">
                    <div>
                      <span className="block text-xs text-[#9a9ca5]">A partir de</span>
                      <strong className="text-lg text-[#ff4b0a]">{money.format(precoFinal)}</strong>
                    </div>
                    <button
                      onClick={() => abrirMontagemProduto(product)}
                      className="grid size-11 place-items-center rounded-2xl bg-[#ff4b0a] text-white transition hover:bg-[#ec3f00] cursor-pointer shadow-sm active:scale-95"
                      aria-label={`Montar e adicionar ${product.nome}`}
                    >
                      <Plus className="size-5" />
                    </button>
                  </div>
                </article>
              );
            })}
          </div>
        )}

        {!loading && !error && filtered.length === 0 && (
          <div className="rounded-[24px] border border-dashed border-[#ddd6d2] bg-white px-6 py-14 text-center">
            <Search className="mx-auto mb-3 size-7 text-[#bbb4b0]" />
            <h3 className="font-bold">Nenhum item encontrado</h3>
            <p className="mt-1 text-sm text-[#747783]">Tente buscar por outro termo ou selecione outra categoria.</p>
          </div>
        )}
      </section>

      {/* Bottom Nav Mobile */}
      <nav
        className="fixed inset-x-0 bottom-0 z-40 border-t border-black/5 bg-white/95 px-4 pb-[max(10px,env(safe-area-inset-bottom))] pt-2 backdrop-blur-xl sm:hidden"
        aria-label="Navegação principal"
      >
        <div className="mx-auto grid max-w-md grid-cols-4">
          {[
            { label: 'Início', icon: Home, active: true },
            { label: 'Cardápio', icon: Store },
            { label: 'Pedidos', icon: PackageCheck },
            { label: 'Conta', icon: UserRound },
          ].map(({ label, icon: Icon, active }) => (
            <button
              key={label}
              className={`flex flex-col items-center gap-1 py-1 text-[11px] font-semibold ${
                active ? 'text-[#ff4b0a]' : 'text-[#777a86]'
              }`}
            >
              <Icon className="size-5" />
              {label}
            </button>
          ))}
        </div>
      </nav>

      {/* ======================================================== */}
      {/* TELA / MODAL DE MONTAGEM E PERSONALIZAÇÃO DO PRODUTO */}
      {/* ======================================================== */}
      {produtoConfigurando && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-black/60 backdrop-blur-xs animate-in fade-in duration-200">
          <div className="relative w-full max-w-lg max-h-[90vh] flex flex-col overflow-hidden rounded-[28px] bg-white shadow-2xl animate-in zoom-in-95 duration-200">
            {/* Header com Imagem e Botão Fechar */}
            <div className="relative h-44 shrink-0 bg-[#fff2ec]">
              <img
                src={formatImageUrl(produtoConfigurando.imagem_url)}
                alt={produtoConfigurando.nome}
                className="h-full w-full object-cover"
                onError={(e) => {
                  (e.target as HTMLImageElement).src = '/pizza-media.jpg';
                }}
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/75 via-black/20 to-transparent flex items-end p-5">
                <div className="text-white">
                  <span className="inline-flex items-center gap-1 rounded-full bg-[#ff4b0a] px-2.5 py-0.5 text-xs font-bold text-white mb-1 shadow">
                    {isPizzaAtual ? 'Montagem de Pizza' : 'Personalizar Item'}
                  </span>
                  <h2 className="text-xl font-extrabold leading-tight text-white drop-shadow-sm">
                    {produtoConfigurando.nome}
                  </h2>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setProdutoConfigurando(null)}
                className="absolute top-3 right-3 grid size-9 place-items-center rounded-full bg-black/50 text-white backdrop-blur hover:bg-black/75 transition cursor-pointer"
                aria-label="Fechar"
              >
                <X className="size-5" />
              </button>
            </div>

            {/* Conteúdo com Scroll */}
            <div className="flex-1 overflow-y-auto p-5 space-y-4">
              {/* Descrição do Produto */}
              {produtoConfigurando.descricao && (
                <p className="text-sm text-[#747783] leading-relaxed bg-[#faf8f6] p-3.5 rounded-2xl border border-[#f0ece9]">
                  {produtoConfigurando.descricao}
                </p>
              )}

              {/* Quantidade */}
              <div className="flex items-center justify-between rounded-2xl border border-[#eee9e6] bg-[#fdfcfb] p-3.5">
                <div>
                  <span className="block text-sm font-extrabold text-[#202332]">Quantidade</span>
                  <span className="text-xs text-[#9a9ca5]">Selecione quantas unidades</span>
                </div>
                <div className="flex items-center gap-3">
                  <button
                    type="button"
                    onClick={() => setQuantConfig((q) => Math.max(1, q - 1))}
                    className="grid size-8 place-items-center rounded-xl border border-[#eee9e6] bg-white text-[#202332] shadow-sm transition hover:bg-[#fff0e9] hover:text-[#ff4b0a] cursor-pointer"
                  >
                    <Minus className="size-4" />
                  </button>
                  <span className="w-6 text-center text-base font-extrabold text-[#202332]">
                    {quantConfig}
                  </span>
                  <button
                    type="button"
                    onClick={() => setQuantConfig((q) => q + 1)}
                    className="grid size-8 place-items-center rounded-xl border border-[#eee9e6] bg-white text-[#202332] shadow-sm transition hover:bg-[#fff0e9] hover:text-[#ff4b0a] cursor-pointer"
                  >
                    <Plus className="size-4" />
                  </button>
                </div>
              </div>

              {/* Indicador de carregamento das opções */}
              {carregandoOpcoes && (
                <div className="flex items-center justify-center gap-2 py-6 text-sm font-semibold text-[#ff4b0a]">
                  <Loader2 className="size-5 animate-spin" /> Carregando opções de montagem...
                </div>
              )}

              {/* SE FOR PIZZA: Escolha de Sabores e Frações */}
              {!carregandoOpcoes && isPizzaAtual && (opcoesProduto?.sabores?.length ?? 0) > 0 && (
                <div className="rounded-2xl border border-[#eee9e6] bg-white p-4 space-y-3">
                  <div className="flex items-center justify-between">
                    <label className="text-xs font-extrabold uppercase tracking-wider text-[#ff4b0a] flex items-center gap-1.5">
                      <Sparkles className="size-4 text-[#ff4b0a]" />
                      Escolher Sabores (Máx {maxSaboresPizzaAtual})
                    </label>

                    {/* Botões de Fração */}
                    <div className="flex gap-1">
                      {Array.from({ length: maxSaboresPizzaAtual }, (_, i) => i + 1).map((n) => (
                        <button
                          key={n}
                          type="button"
                          onClick={() => {
                            setNumFracoesPizza(n);
                            setSaboresEscolhidos([]);
                          }}
                          className={`px-2.5 py-1 rounded-lg text-xs font-bold border transition cursor-pointer ${
                            numFracoesPizza === n
                              ? 'bg-[#ff4b0a] text-white border-[#ff4b0a] shadow-sm'
                              : 'bg-white border-[#eee9e6] text-[#747783] hover:text-[#202332]'
                          }`}
                        >
                          {n} Sabor{n > 1 ? 'es' : ''}
                        </button>
                      ))}
                    </div>
                  </div>

                  <p className="text-xs text-[#9a9ca5]">
                    {saboresEscolhidos.length} de {numFracoesPizza} sabor(es) selecionado(s)
                  </p>

                  {/* Busca de Sabores */}
                  <div className="relative">
                    <Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-[#9a9ca5]" />
                    <input
                      type="text"
                      value={buscaSaborModal}
                      onChange={(e) => setBuscaSaborModal(e.target.value)}
                      placeholder="Buscar sabor de pizza..."
                      className="w-full rounded-xl border border-[#eee9e6] bg-[#faf8f6] py-2 pl-9 pr-3 text-xs outline-none focus:border-[#ff4b0a] focus:bg-white"
                    />
                  </div>

                  {/* Grid de Sabores */}
                  <div className="max-h-48 overflow-y-auto space-y-1.5 pr-1">
                    {saboresFiltrados.map((sab) => {
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
                                setSaboresEscolhidos((prev) => {
                                  const fracao = numFracoesPizza === 1 ? '1/1' : `1/${numFracoesPizza}`;
                                  return [...prev.slice(0, numFracoesPizza - 1), { saborId: sab.id, saborNome: sab.nome, fracao }];
                                });
                                return;
                              }
                              const fracao = numFracoesPizza === 1 ? '1/1' : `1/${numFracoesPizza}`;
                              setSaboresEscolhidos((prev) => [
                                ...prev,
                                { saborId: sab.id, saborNome: sab.nome, fracao },
                              ]);
                            }
                          }}
                          className={`w-full p-2.5 rounded-xl text-left text-xs font-semibold border transition flex items-center justify-between cursor-pointer ${
                            selecionado
                              ? 'bg-[#fff0e9] border-[#ff4b0a] text-[#ff4b0a] font-bold shadow-xs'
                              : 'bg-white border-[#eee9e6] text-[#202332] hover:border-[#ff4b0a]/30'
                          }`}
                        >
                          <div className="min-w-0 flex-1 pr-2">
                            <span className="block truncate font-bold">{sab.nome}</span>
                            {sab.descricao && (
                              <span className="block truncate text-[11px] text-[#858894] font-normal">
                                {sab.descricao}
                              </span>
                            )}
                          </div>
                          {selecionado ? (
                            <div className="grid size-5 shrink-0 place-items-center rounded-full bg-[#ff4b0a] text-white">
                              <Check className="size-3.5" />
                            </div>
                          ) : (
                            <div className="size-5 shrink-0 rounded-full border border-[#ddd6d2]" />
                          )}
                        </button>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* SE FOR PIZZA: Escolha de Bordas */}
              {!carregandoOpcoes && isPizzaAtual && (opcoesProduto?.bordas?.length ?? 0) > 0 && (
                <div className="rounded-2xl border border-[#eee9e6] bg-white p-4 space-y-2.5">
                  <label className="text-xs font-extrabold uppercase tracking-wider text-[#202332] flex items-center gap-1.5">
                    <Tag className="size-4 text-[#ff4b0a]" />
                    Borda Recheada
                  </label>
                  <div className="max-h-48 overflow-y-auto space-y-2 pr-1">
                    <button
                      type="button"
                      onClick={() => setBordaEscolhida(null)}
                      className={`w-full p-3 rounded-xl text-left text-xs font-semibold border transition flex items-center justify-between cursor-pointer ${
                        !bordaEscolhida
                          ? 'bg-[#fff0e9] border-[#ff4b0a] text-[#ff4b0a] font-bold shadow-xs'
                          : 'bg-white border-[#eee9e6] text-[#666a76] hover:border-[#ff4b0a]/30'
                      }`}
                    >
                      <span>Sem Borda</span>
                      {!bordaEscolhida && (
                        <div className="grid size-5 shrink-0 place-items-center rounded-full bg-[#ff4b0a] text-white">
                          <Check className="size-3.5" />
                        </div>
                      )}
                    </button>
                    {opcoesProduto?.bordas.map((b) => {
                      const precoBorda = Number(b.valor) || 0;
                      const selecionada = bordaEscolhida?.bordaId === b.id;
                      return (
                        <button
                          key={b.id}
                          type="button"
                          onClick={() =>
                            setBordaEscolhida({ bordaId: b.id, bordaNome: b.nome, preco: precoBorda })
                          }
                          className={`w-full p-3 rounded-xl text-left text-xs font-semibold border transition flex items-center justify-between gap-2 cursor-pointer ${
                            selecionada
                              ? 'bg-[#fff0e9] border-[#ff4b0a] text-[#ff4b0a] font-bold shadow-xs'
                              : 'bg-white border-[#eee9e6] text-[#202332] hover:border-[#ff4b0a]/30'
                          }`}
                        >
                          <span className="font-bold flex-1 leading-snug break-words">{b.nome}</span>
                          <div className="flex items-center gap-2 shrink-0">
                            <span className="text-xs text-[#22c55e] font-extrabold">
                              +{money.format(precoBorda)}
                            </span>
                            {selecionada ? (
                              <div className="grid size-5 place-items-center rounded-full bg-[#ff4b0a] text-white">
                                <Check className="size-3.5" />
                              </div>
                            ) : (
                              <div className="size-5 rounded-full border border-[#ddd6d2]" />
                            )}
                          </div>
                        </button>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* ADICIONAIS E OPCIONAIS */}
              {!carregandoOpcoes && (opcoesProduto?.adicionais?.length ?? 0) > 0 && (
                <div className="rounded-2xl border border-[#eee9e6] bg-white p-4 space-y-2.5">
                  <label className="text-xs font-extrabold uppercase tracking-wider text-[#202332] flex items-center gap-1.5">
                    <Layers className="size-4 text-[#ff4b0a]" />
                    Adicionais e Opcionais
                  </label>
                  <div className="space-y-2 max-h-40 overflow-y-auto">
                    {opcoesProduto?.adicionais.map((ad) => {
                      const valorAdic = Number(ad.preco) || 0;
                      const existente = adicionaisEscolhidos.find((a) => a.adicionalId === ad.id);
                      const quant = existente ? existente.quantidade : 0;

                      return (
                        <div
                          key={ad.id}
                          className="flex items-center justify-between rounded-xl border border-[#eee9e6] p-2.5 bg-[#fdfcfb]"
                        >
                          <div>
                            <span className="block text-xs font-bold text-[#202332]">{ad.nome}</span>
                            <span className="text-[11px] font-bold text-[#22c55e]">
                              +{money.format(valorAdic)}
                            </span>
                          </div>
                          <div className="flex items-center gap-2">
                            {quant > 0 && (
                              <button
                                type="button"
                                onClick={() => {
                                  setAdicionaisEscolhidos((prev) =>
                                    prev
                                      .map((a) =>
                                        a.adicionalId === ad.id ? { ...a, quantidade: a.quantidade - 1 } : a
                                      )
                                      .filter((a) => a.quantidade > 0)
                                  );
                                }}
                                className="grid size-7 place-items-center rounded-lg bg-[#fff0e9] text-[#ff4b0a] transition hover:bg-[#ffe3d6] cursor-pointer"
                              >
                                <Minus className="size-3.5" />
                              </button>
                            )}
                            {quant > 0 && (
                              <span className="w-5 text-center text-xs font-bold">{quant}</span>
                            )}
                            <button
                              type="button"
                              onClick={() => {
                                setAdicionaisEscolhidos((prev) => {
                                  const item = prev.find((a) => a.adicionalId === ad.id);
                                  if (item) {
                                    return prev.map((a) =>
                                      a.adicionalId === ad.id ? { ...a, quantidade: a.quantidade + 1 } : a
                                    );
                                  }
                                  return [
                                    ...prev,
                                    { adicionalId: ad.id, nome: ad.nome, quantidade: 1, valor: valorAdic },
                                  ];
                                });
                              }}
                              className="grid size-7 place-items-center rounded-lg bg-[#ff4b0a] text-white transition hover:bg-[#e03f04] cursor-pointer"
                            >
                              <Plus className="size-3.5" />
                            </button>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* Observações do Item */}
              <div className="rounded-2xl border border-[#eee9e6] bg-white p-4 space-y-2">
                <label className="text-xs font-extrabold uppercase tracking-wider text-[#202332]">
                  Observações
                </label>
                <textarea
                  value={obsConfig}
                  onChange={(e) => setObsConfig(e.target.value)}
                  placeholder="Ex: sem cebola, ponto da carne, caprichar no molho..."
                  rows={2}
                  className="w-full rounded-xl border border-[#eee9e6] bg-[#faf8f6] p-3 text-xs outline-none focus:border-[#ff4b0a] focus:bg-white resize-none"
                />
              </div>
            </div>

            {/* Rodapé com Preço Total e Botão de Adicionar */}
            <div className="border-t border-[#eee9e6] bg-white p-4">
              <button
                type="button"
                onClick={salvarMontagemNoCarrinho}
                className="flex h-13 w-full items-center justify-between rounded-2xl bg-[#ff4b0a] px-5 font-extrabold text-white shadow-[0_8px_20px_rgba(255,75,10,.25)] transition hover:bg-[#e03f04] cursor-pointer active:scale-98"
              >
                <span>Adicionar ao carrinho</span>
                <span className="text-base">{money.format(precoCalculadoItem)}</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Gaveta do Carrinho (Drawer Lateral Direto) */}
      {cartOpen && (
        <div className="fixed inset-0 z-50 flex justify-end bg-black/60 backdrop-blur-xs animate-in fade-in duration-200">
          <div
            className="fixed inset-0"
            onClick={() => setCartOpen(false)}
            aria-hidden="true"
          />
          <div className="relative z-10 flex h-full w-full max-w-md flex-col bg-white shadow-2xl animate-in slide-in-from-right duration-200">
            {/* Header Carrinho */}
            <div className="flex items-center justify-between border-b border-[#eee9e6] p-5">
              <div>
                <h3 className="text-2xl font-extrabold text-[#202332]">Meu carrinho</h3>
                <p className="text-xs text-[#747783] mt-0.5">
                  {cartCount ? `${cartCount} ${cartCount === 1 ? 'item' : 'itens'} no pedido` : 'Seu carrinho está vazio'}
                </p>
              </div>
              <button
                type="button"
                onClick={() => setCartOpen(false)}
                className="grid size-9 place-items-center rounded-full bg-[#faf8f6] text-[#747783] hover:text-[#202332] hover:bg-[#eee9e6] transition cursor-pointer"
                aria-label="Fechar carrinho"
              >
                <X className="size-5" />
              </button>
            </div>

            {/* Lista de Itens */}
            <div className="flex-1 overflow-y-auto p-5">
              {cartItems.length === 0 ? (
                <div className="py-20 text-center text-[#9a9ca5]">
                  <ShoppingBag className="mx-auto size-12 opacity-30 mb-3" />
                  <p className="font-bold text-base text-[#202332]">Seu carrinho está vazio</p>
                  <p className="text-xs mt-1">Adicione itens deliciosos para começar seu pedido.</p>
                </div>
              ) : (
                cartItems.map((item) => (
                  <div key={item.idTemp} className="mb-3 rounded-2xl border border-[#eee9e6] p-3.5 bg-white shadow-xs">
                    <div className="flex gap-3">
                      <img
                        src={formatImageUrl(item.imagemUrl)}
                        alt={item.produtoNome}
                        className="size-16 rounded-xl object-cover shrink-0"
                        onError={(e) => {
                          (e.target as HTMLImageElement).src = '/pizza-media.jpg';
                        }}
                      />
                      <div className="min-w-0 flex-1">
                        <div className="flex items-start justify-between gap-1">
                          <p className="font-bold text-sm leading-tight text-[#202332]">{item.produtoNome}</p>
                          <button
                            onClick={() => removerItemCarrinho(item.idTemp)}
                            className="text-[#9a9ca5] hover:text-[#ef4444] p-0.5 cursor-pointer"
                            aria-label="Remover item"
                          >
                            <Trash2 className="size-4" />
                          </button>
                        </div>

                        {/* Sabores */}
                        {item.sabores && item.sabores.length > 0 && (
                          <p className="text-[11px] text-[#ff4b0a] font-semibold mt-1 leading-snug">
                            Sabores: {item.sabores.map((s) => `${s.saborNome} (${s.fracao})`).join(', ')}
                          </p>
                        )}

                        {/* Borda */}
                        {item.borda && (
                          <p className="text-[11px] text-[#747783] mt-0.5">
                            Borda: {item.borda.bordaNome} (+{money.format(item.borda.preco)})
                          </p>
                        )}

                        {/* Adicionais */}
                        {item.adicionais && item.adicionais.length > 0 && (
                          <p className="text-[11px] text-[#747783] mt-0.5">
                            Adicionais: {item.adicionais.map((a) => `${a.quantidade}x ${a.nome}`).join(', ')}
                          </p>
                        )}

                        {/* Observações */}
                        {item.observacoes && (
                          <p className="text-[11px] text-[#f59e0b] italic mt-0.5">
                            Obs: {item.observacoes}
                          </p>
                        )}

                        <div className="mt-3 flex items-center justify-between">
                          <p className="text-sm font-extrabold text-[#ff4b0a]">
                            {money.format(item.valorTotal)}
                          </p>
                          <div className="flex items-center gap-2">
                            <button
                              onClick={() => alterarQuantidadeItemCarrinho(item.idTemp, -1)}
                              className="grid size-7 place-items-center rounded-lg bg-[#fff0e9] text-[#ff4b0a] transition hover:bg-[#ffe3d6] cursor-pointer"
                              aria-label="Diminuir"
                            >
                              <Minus className="size-4" />
                            </button>
                            <span className="w-5 text-center text-xs font-bold text-[#202332]">{item.quantidade}</span>
                            <button
                              onClick={() => alterarQuantidadeItemCarrinho(item.idTemp, 1)}
                              className="grid size-7 place-items-center rounded-lg bg-[#fff0e9] text-[#ff4b0a] transition hover:bg-[#ffe3d6] cursor-pointer"
                              aria-label="Aumentar"
                            >
                              <Plus className="size-4" />
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                ))
              )}
            </div>

            {/* Rodapé Carrinho */}
            <div className="border-t border-[#eee9e6] bg-white p-5 pb-7 space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-[#777a86] font-medium">Subtotal</span>
                <strong className="text-xl text-[#202332]">{money.format(subtotalCart)}</strong>
              </div>

              <div className="flex flex-col gap-2.5">
                <button
                  type="button"
                  disabled={!cartCount}
                  onClick={iniciarCheckout}
                  className="flex h-13 w-full items-center justify-between rounded-2xl bg-[#ff4b0a] px-5 font-bold text-white transition hover:bg-[#e03f04] disabled:opacity-40 cursor-pointer shadow-[0_8px_20px_rgba(255,75,10,.25)] active:scale-98"
                >
                  <span>Finalizar Pedido</span>
                  <ArrowRight className="size-5" />
                </button>

                <button
                  type="button"
                  onClick={() => setCartOpen(false)}
                  className="flex h-11 w-full items-center justify-center gap-2 rounded-xl border border-[#eee9e6] bg-[#faf8f6] px-4 font-bold text-xs text-[#202332] hover:bg-[#fff0e9] hover:text-[#ff4b0a] hover:border-[#ff4b0a]/30 transition cursor-pointer active:scale-98"
                >
                  <Plus className="size-4 text-[#ff4b0a]" />
                  <span>Adicionar mais itens</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ======================================================== */}
      {/* MODAL DE CHECKOUT: ETAPA 1 (ENTREGA/RETIRADA) -> ETAPA 2 (DADOS) -> ETAPA 3 (PAGAMENTO) */}
      {/* ======================================================== */}
      {modalCheckoutAberto && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-black/65 backdrop-blur-xs animate-in fade-in duration-200">
          <div className="relative w-full max-w-lg max-h-[92vh] flex flex-col overflow-hidden rounded-[28px] bg-white shadow-2xl animate-in zoom-in-95 duration-200">
            {/* Header do Checkout */}
            <div className="p-5 border-b border-[#eee9e6] flex items-center justify-between bg-[#faf8f6]">
              <div className="flex items-center gap-3">
                {checkoutStep !== 'TIPO' && checkoutStep !== 'CONFIRMACAO' && (
                  <button
                    type="button"
                    onClick={() => {
                      if (checkoutStep === 'DADOS') setCheckoutStep('TIPO');
                      if (checkoutStep === 'PAGAMENTO') setCheckoutStep('DADOS');
                    }}
                    className="grid size-9 place-items-center rounded-xl bg-white border border-[#eee9e6] text-[#202332] hover:bg-[#fff0e9] hover:text-[#ff4b0a] cursor-pointer"
                  >
                    <ArrowLeft className="size-4" />
                  </button>
                )}
                <div>
                  <h3 className="text-lg font-extrabold text-[#202332]">
                    {checkoutStep === 'TIPO' && 'Como deseja receber?'}
                    {checkoutStep === 'DADOS' && (tipoAtendimento === 'ENTREGA' ? 'Endereço e Contato' : 'Seus Dados')}
                    {checkoutStep === 'PAGAMENTO' && 'Forma de Pagamento'}
                    {checkoutStep === 'CONFIRMACAO' && 'Pedido Confirmado! 🎉'}
                  </h3>
                  <p className="text-xs text-[#747783] mt-0.5">
                    {checkoutStep === 'TIPO' && 'Selecione se prefere entrega ou retirar na loja'}
                    {checkoutStep === 'DADOS' && 'Preencha para identificarmos seu pedido'}
                    {checkoutStep === 'PAGAMENTO' && 'Escolha como deseja pagar seu pedido'}
                    {checkoutStep === 'CONFIRMACAO' && `Pedido #${pedidoRealizado?.numero || 'recebido'}`}
                  </p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setModalCheckoutAberto(false)}
                className="grid size-8 place-items-center rounded-full bg-[#eee9e6] text-[#747783] hover:text-[#202332] hover:bg-[#ddd6d2] cursor-pointer"
              >
                <X className="size-4" />
              </button>
            </div>

            {/* Conteúdo com Scroll das Etapas */}
            <div className="flex-1 overflow-y-auto p-5 space-y-4">
              {/* ETAPA 1: SELEÇÃO DE TIPO (ENTREGA OU RETIRADA) */}
              {checkoutStep === 'TIPO' && (
                <div className="space-y-4">
                  <div className="grid grid-cols-2 gap-3">
                    <button
                      type="button"
                      onClick={() => setTipoAtendimento('ENTREGA')}
                      className={`p-5 rounded-2xl border-2 text-left transition flex flex-col justify-between gap-3 cursor-pointer ${
                        tipoAtendimento === 'ENTREGA'
                          ? 'border-[#ff4b0a] bg-[#fff0e9] shadow-sm'
                          : 'border-[#eee9e6] bg-white hover:border-[#ff4b0a]/30'
                      }`}
                    >
                      <div className="flex items-center justify-between">
                        <div className={`grid size-11 place-items-center rounded-2xl ${tipoAtendimento === 'ENTREGA' ? 'bg-[#ff4b0a] text-white' : 'bg-[#faf8f6] text-[#ff4b0a]'}`}>
                          <Bike className="size-6" />
                        </div>
                        {tipoAtendimento === 'ENTREGA' && (
                          <div className="grid size-5 place-items-center rounded-full bg-[#ff4b0a] text-white">
                            <Check className="size-3.5" />
                          </div>
                        )}
                      </div>
                      <div>
                        <span className="block font-extrabold text-base text-[#202332]">Entrega</span>
                        <span className="text-xs text-[#747783] mt-0.5 block">
                          Receba no seu endereço (+{money.format(lojaStatus?.taxaEntregaPadrao ?? 5)})
                        </span>
                      </div>
                    </button>

                    <button
                      type="button"
                      onClick={() => setTipoAtendimento('BALCAO')}
                      className={`p-5 rounded-2xl border-2 text-left transition flex flex-col justify-between gap-3 cursor-pointer ${
                        tipoAtendimento === 'BALCAO'
                          ? 'border-[#ff4b0a] bg-[#fff0e9] shadow-sm'
                          : 'border-[#eee9e6] bg-white hover:border-[#ff4b0a]/30'
                      }`}
                    >
                      <div className="flex items-center justify-between">
                        <div className={`grid size-11 place-items-center rounded-2xl ${tipoAtendimento === 'BALCAO' ? 'bg-[#ff4b0a] text-white' : 'bg-[#faf8f6] text-[#ff4b0a]'}`}>
                          <Store className="size-6" />
                        </div>
                        {tipoAtendimento === 'BALCAO' && (
                          <div className="grid size-5 place-items-center rounded-full bg-[#ff4b0a] text-white">
                            <Check className="size-3.5" />
                          </div>
                        )}
                      </div>
                      <div>
                        <span className="block font-extrabold text-base text-[#202332]">Retirada</span>
                        <span className="text-xs text-[#747783] mt-0.5 block">
                          Buscar na loja (Sem taxa)
                        </span>
                      </div>
                    </button>
                  </div>

                  {/* Resumo do Tempo */}
                  <div className="rounded-2xl bg-[#faf8f6] border border-[#f0ece9] p-4 flex items-center gap-3">
                    <Clock3 className="size-5 text-[#ff4b0a]" />
                    <div className="text-xs">
                      <p className="font-bold text-[#202332]">
                        Tempo estimado: {tempoMin} a {tempoMax} minutos
                      </p>
                      <p className="text-[#747783]">
                        {tipoAtendimento === 'ENTREGA' ? 'Preparado e entregue quentinho.' : 'Retire no balcão da loja.'}
                      </p>
                    </div>
                  </div>
                </div>
              )}

              {/* ETAPA 2: DADOS DO CLIENTE & ENDEREÇO */}
              {checkoutStep === 'DADOS' && (
                <div className="space-y-3.5">
                  {/* Nome e Telefone */}
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <div>
                      <label className="block text-xs font-bold text-[#202332] mb-1.5 flex items-center gap-1.5">
                        <User className="size-3.5 text-[#ff4b0a]" /> Seu Nome *
                      </label>
                      <input
                        id="input-cliente-nome"
                        type="text"
                        value={clienteNome}
                        onChange={(e) => setClienteNome(e.target.value)}
                        onKeyDown={(e) => {
                          if (e.key === 'Enter') {
                            e.preventDefault();
                            document.getElementById('input-cliente-telefone')?.focus();
                          }
                        }}
                        placeholder="Ex: João da Silva"
                        className="w-full h-11 px-3.5 rounded-xl border border-[#eee9e6] bg-[#faf8f6] text-xs outline-none focus:border-[#ff4b0a] focus:bg-white"
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-bold text-[#202332] mb-1.5 flex items-center gap-1.5">
                        <Phone className="size-3.5 text-[#ff4b0a]" /> WhatsApp / Telefone *
                      </label>
                      <input
                        id="input-cliente-telefone"
                        type="tel"
                        value={clienteTelefone}
                        onChange={(e) => setClienteTelefone(formatarTelefone(e.target.value))}
                        maxLength={15}
                        onKeyDown={(e) => {
                          if (e.key === 'Enter') {
                            e.preventDefault();
                            if (tipoAtendimento === 'ENTREGA') {
                              document.getElementById('input-endereco-logradouro')?.focus();
                            } else {
                              document.getElementById('input-observacao-pedido')?.focus();
                            }
                          }
                        }}
                        placeholder="(XX) 99999-9999"
                        className="w-full h-11 px-3.5 rounded-xl border border-[#eee9e6] bg-[#faf8f6] text-xs outline-none focus:border-[#ff4b0a] focus:bg-white"
                      />
                    </div>
                  </div>

                  {/* Se for Entrega: Endereço completo */}
                  {tipoAtendimento === 'ENTREGA' && (
                    <div className="space-y-3 pt-2 border-t border-[#eee9e6]">
                      <span className="block text-xs font-extrabold uppercase tracking-wider text-[#ff4b0a] flex items-center gap-1.5">
                        <MapPin className="size-4" /> Endereço de Entrega
                      </span>
                      <div className="grid grid-cols-3 gap-2">
                        <div className="col-span-2">
                          <label className="block text-[11px] font-bold text-[#747783] mb-1">Rua / Logradouro *</label>
                          <input
                            id="input-endereco-logradouro"
                            type="text"
                            value={enderecoLogradouro}
                            onChange={(e) => setEnderecoLogradouro(e.target.value)}
                            onKeyDown={(e) => {
                              if (e.key === 'Enter') {
                                e.preventDefault();
                                document.getElementById('input-endereco-numero')?.focus();
                              }
                            }}
                            placeholder="Nome da rua ou avenida"
                            className="w-full h-11 px-3.5 rounded-xl border border-[#eee9e6] bg-[#faf8f6] text-xs outline-none focus:border-[#ff4b0a] focus:bg-white"
                          />
                        </div>
                        <div>
                          <label className="block text-[11px] font-bold text-[#747783] mb-1">Número *</label>
                          <input
                            id="input-endereco-numero"
                            type="text"
                            value={enderecoNumero}
                            onChange={(e) => setEnderecoNumero(e.target.value)}
                            onKeyDown={(e) => {
                              if (e.key === 'Enter') {
                                e.preventDefault();
                                document.getElementById('input-endereco-bairro')?.focus();
                              }
                            }}
                            placeholder="123"
                            className="w-full h-11 px-3.5 rounded-xl border border-[#eee9e6] bg-[#faf8f6] text-xs outline-none focus:border-[#ff4b0a] focus:bg-white"
                          />
                        </div>
                      </div>

                      <div className="grid grid-cols-2 gap-2">
                        <div>
                          <label className="block text-[11px] font-bold text-[#747783] mb-1">Bairro *</label>
                          <input
                            id="input-endereco-bairro"
                            type="text"
                            value={enderecoBairro}
                            onChange={(e) => setEnderecoBairro(e.target.value)}
                            onKeyDown={(e) => {
                              if (e.key === 'Enter') {
                                e.preventDefault();
                                document.getElementById('input-endereco-complemento')?.focus();
                              }
                            }}
                            placeholder="Ex: Centro"
                            className="w-full h-11 px-3.5 rounded-xl border border-[#eee9e6] bg-[#faf8f6] text-xs outline-none focus:border-[#ff4b0a] focus:bg-white"
                          />
                        </div>
                        <div>
                          <label className="block text-[11px] font-bold text-[#747783] mb-1">Complemento / Ref.</label>
                          <input
                            id="input-endereco-complemento"
                            type="text"
                            value={enderecoComplemento}
                            onChange={(e) => setEnderecoComplemento(e.target.value)}
                            onKeyDown={(e) => {
                              if (e.key === 'Enter') {
                                e.preventDefault();
                                document.getElementById('input-observacao-pedido')?.focus();
                              }
                            }}
                            placeholder="Apto 101, casa azul"
                            className="w-full h-11 px-3.5 rounded-xl border border-[#eee9e6] bg-[#faf8f6] text-xs outline-none focus:border-[#ff4b0a] focus:bg-white"
                          />
                        </div>
                      </div>
                    </div>
                  )}

                  {/* Observação Geral */}
                  <div className="pt-2 border-t border-[#eee9e6]">
                    <label className="block text-xs font-bold text-[#202332] mb-1">Observações do Pedido</label>
                    <textarea
                      id="input-observacao-pedido"
                      value={observacaoPedido}
                      onChange={(e) => setObservacaoPedido(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter' && !e.shiftKey) {
                          e.preventDefault();
                          avancarParaPagamento();
                        }
                      }}
                      placeholder="Ex: Campainha não funciona, ligar ao chegar..."
                      rows={2}
                      className="w-full p-3 rounded-xl border border-[#eee9e6] bg-[#faf8f6] text-xs outline-none focus:border-[#ff4b0a] focus:bg-white resize-none"
                    />
                  </div>
                </div>
              )}

              {/* ETAPA 3: FORMA DE PAGAMENTO */}
              {checkoutStep === 'PAGAMENTO' && (
                <div className="space-y-3">
                  <span className="block text-xs font-extrabold uppercase tracking-wider text-[#ff4b0a]">
                    Como prefere pagar?
                  </span>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                    {[
                      { id: 'PIX', label: 'PIX (Instantâneo)', icon: QrCode },
                      { id: 'CARTAO_CREDITO', label: 'Cartão de Crédito', icon: CreditCard },
                      { id: 'CARTAO_DEBITO', label: 'Cartão de Débito', icon: CreditCard },
                      { id: 'DINHEIRO', label: 'Dinheiro', icon: DollarSign },
                    ].map(({ id, label, icon: Icon }) => (
                      <button
                        key={id}
                        type="button"
                        onClick={() => setFormaPagamento(id as any)}
                        className={`p-3.5 rounded-2xl border-2 text-left transition flex items-center justify-between cursor-pointer ${
                          formaPagamento === id
                            ? 'border-[#ff4b0a] bg-[#fff0e9] font-bold text-[#ff4b0a] shadow-xs'
                            : 'border-[#eee9e6] bg-white text-[#202332] hover:border-[#ff4b0a]/30'
                        }`}
                      >
                        <div className="flex items-center gap-2.5">
                          <Icon className="size-5" />
                          <span className="text-xs">{label}</span>
                        </div>
                        {formaPagamento === id && (
                          <div className="grid size-5 place-items-center rounded-full bg-[#ff4b0a] text-white">
                            <Check className="size-3.5" />
                          </div>
                        )}
                      </button>
                    ))}
                  </div>

                  {formaPagamento === 'DINHEIRO' && (
                    <div className="rounded-2xl bg-[#faf8f6] border border-[#eee9e6] p-3.5 space-y-1.5">
                      <label className="block text-xs font-bold text-[#202332]">Precisa de troco para quanto?</label>
                      <input
                        type="number"
                        value={trocoPara}
                        onChange={(e) => setTrocoPara(e.target.value)}
                        placeholder="Ex: 50 ou 100"
                        className="w-full h-10 px-3 rounded-xl border border-[#eee9e6] bg-white text-xs outline-none focus:border-[#ff4b0a]"
                      />
                    </div>
                  )}

                  {/* Resumo Financeiro */}
                  <div className="rounded-2xl border border-[#eee9e6] bg-[#faf8f6] p-4 space-y-2 mt-4">
                    <div className="flex justify-between text-xs text-[#747783]">
                      <span>Subtotal ({cartCount} itens)</span>
                      <span>{money.format(subtotalCart)}</span>
                    </div>
                    {tipoAtendimento === 'ENTREGA' && (
                      <div className="flex justify-between text-xs text-[#747783]">
                        <span>Taxa de Entrega</span>
                        <span>{money.format(taxaEntregaValor)}</span>
                      </div>
                    )}
                    <div className="flex justify-between text-sm font-extrabold text-[#202332] pt-2 border-t border-[#eee9e6]">
                      <span>Total a Pagar</span>
                      <span className="text-base text-[#ff4b0a]">{money.format(totalPedidoFinal)}</span>
                    </div>
                  </div>
                </div>
              )}

              {/* ETAPA 4: CONFIRMAÇÃO & QR CODE PIX */}
              {checkoutStep === 'CONFIRMACAO' && (
                <div className="text-center py-4 space-y-4">
                  <div className="grid size-16 place-items-center rounded-full bg-[#dcfce7] text-[#16a34a] mx-auto shadow-sm">
                    <Check className="size-8" />
                  </div>

                  <div>
                    <h4 className="text-xl font-extrabold text-[#202332]">Pedido Enviado com Sucesso!</h4>
                    <p className="text-xs text-[#747783] mt-1">
                      A loja já recebeu seu pedido e iniciará o preparo em instantes.
                    </p>
                  </div>

                  {/* PIX QR CODE SE FOR PIX */}
                  {formaPagamento === 'PIX' && pixDados?.qrCodeBase64 && (
                    <div className="rounded-2xl border border-[#eee9e6] bg-[#faf8f6] p-4 space-y-3">
                      <p className="text-xs font-bold text-[#ff4b0a]">Pague com o PIX Copia e Cola / QR Code:</p>
                      <img
                        src={`data:image/png;base64,${pixDados.qrCodeBase64}`}
                        alt="QR Code PIX"
                        className="size-44 mx-auto bg-white p-2 rounded-xl border border-[#eee9e6]"
                      />
                      {pixDados.copiaCola && (
                        <button
                          type="button"
                          onClick={copiarCodigoPix}
                          className="inline-flex items-center gap-2 rounded-xl bg-[#ff4b0a] px-4 py-2 text-xs font-bold text-white transition hover:bg-[#e03f04] cursor-pointer"
                        >
                          <Copy className="size-4" />
                          {copiadoPix ? 'Código PIX Copiado!' : 'Copiar Código PIX'}
                        </button>
                      )}
                    </div>
                  )}

                  <div className="rounded-2xl border border-[#eee9e6] bg-[#fdfcfb] p-3.5 text-xs text-left space-y-1">
                    <p><strong>Número:</strong> #{pedidoRealizado?.numero}</p>
                    <p><strong>Cliente:</strong> {clienteNome}</p>
                    <p><strong>Tipo:</strong> {tipoAtendimento === 'ENTREGA' ? 'Entrega em domicílio' : 'Retirada na loja'}</p>
                    <p><strong>Total:</strong> {money.format(totalPedidoFinal)} ({formaPagamento})</p>
                  </div>
                </div>
              )}
            </div>

            {/* Rodapé com Ações do Checkout */}
            <div className="p-4 border-t border-[#eee9e6] bg-white">
              {checkoutStep === 'TIPO' && (
                <button
                  type="button"
                  onClick={() => setCheckoutStep('DADOS')}
                  className="flex h-13 w-full items-center justify-between rounded-2xl bg-[#ff4b0a] px-5 font-bold text-white shadow-[0_8px_20px_rgba(255,75,10,.25)] transition hover:bg-[#e03f04] cursor-pointer"
                >
                  <span>Continuar para Dados</span>
                  <ArrowRight className="size-5" />
                </button>
              )}

              {checkoutStep === 'DADOS' && (
                <button
                  type="button"
                  onClick={avancarParaPagamento}
                  className="flex h-13 w-full items-center justify-between rounded-2xl bg-[#ff4b0a] px-5 font-bold text-white shadow-[0_8px_20px_rgba(255,75,10,.25)] transition hover:bg-[#e03f04] cursor-pointer"
                >
                  <span>Ir para Pagamento</span>
                  <ArrowRight className="size-5" />
                </button>
              )}

              {checkoutStep === 'PAGAMENTO' && (
                <button
                  type="button"
                  disabled={enviandoPedido}
                  onClick={finalizarPedidoOnline}
                  className="flex h-13 w-full items-center justify-between rounded-2xl bg-[#22c55e] px-5 font-bold text-white shadow-[0_8px_20px_rgba(34,197,94,.3)] transition hover:bg-[#16a34a] cursor-pointer disabled:opacity-50"
                >
                  {enviandoPedido ? (
                    <span className="flex items-center gap-2 mx-auto">
                      <Loader2 className="size-5 animate-spin" /> Processando pedido...
                    </span>
                  ) : (
                    <>
                      <span>Confirmar e Enviar Pedido</span>
                      <span>{money.format(totalPedidoFinal)}</span>
                    </>
                  )}
                </button>
              )}

              {checkoutStep === 'CONFIRMACAO' && (
                <button
                  type="button"
                  onClick={() => setModalCheckoutAberto(false)}
                  className="flex h-13 w-full items-center justify-center rounded-2xl bg-[#ff4b0a] px-5 font-bold text-white transition hover:bg-[#e03f04] cursor-pointer"
                >
                  Voltar ao Cardápio
                </button>
              )}
            </div>
          </div>
        </div>
      )}
    </main>
  );
}

function SearchBox({
  value,
  onChange,
  desktop = false,
}: {
  value: string;
  onChange: (value: string) => void;
  desktop?: boolean;
}) {
  return (
    <div className={`relative ${desktop ? 'ml-auto hidden w-full max-w-md sm:block' : 'mt-5 sm:hidden'}`}>
      <Search className="absolute left-4 top-1/2 size-5 -translate-y-1/2 text-[#8a8d98]" />
      <input
        value={value}
        onChange={(event) => onChange(event.target.value)}
        placeholder="Buscar pizza, lanche ou bebida"
        className="h-13 w-full rounded-2xl border border-[#ebe7e4] bg-white pl-12 pr-4 text-[15px] outline-none transition focus:border-[#ff4b0a] focus:ring-4 focus:ring-[#ff4b0a]/10"
      />
    </div>
  );
}
