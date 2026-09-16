'use client';

import { useEffect, useMemo, useState } from 'react';
import { ArrowRight, Clock3, Home, Menu, Minus, PackageCheck, Plus, Search, ShoppingBag, Store, UserRound } from 'lucide-react';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle } from '@/components/ui/sheet';

type Product = { id: number; name: string; description: string; price: number; category: string; image: string; badge?: string };

const categories = ['Todos', 'Pizzas', 'Combos', 'Lanches', 'Porções', 'Bebidas'];
const products: Product[] = [
  { id: 1, name: 'Pizza Pequena 25cm', description: 'Até 2 sabores e 6 fatias. Escolha seus sabores favoritos.', price: 40, category: 'Pizzas', image: '/pizza-pequena.jpg', badge: 'Mais pedida' },
  { id: 2, name: 'Pizza Média 30cm', description: 'Até 2 sabores e 8 fatias. Perfeita para compartilhar.', price: 55, category: 'Pizzas', image: '/pizza-media.jpg' },
  { id: 3, name: 'Combo Família', description: 'Pizza Família + Pizza Pequena doce + refrigerante de 2 litros.', price: 121.55, category: 'Combos', image: '/combo-pizzas.jpg', badge: 'Economize' },
  { id: 4, name: 'X-Bacon Gaúcho', description: 'Pão, hambúrguer, bacon, queijo, salada e molho da casa.', price: 32, category: 'Lanches', image: '/x-bacon.jpg' },
  { id: 5, name: 'Porção Mista Pequena', description: 'Fritas, polenta, calabresa e acompanhamentos.', price: 46, category: 'Porções', image: '/porcao-mista.jpg' },
  { id: 6, name: 'Coca-Cola 2L', description: 'Refrigerante gelado para acompanhar o seu pedido.', price: 14, category: 'Bebidas', image: '/coca-cola-2l.png' },
];
const money = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });

export default function HomePage() {
  const [category, setCategory] = useState('Todos');
  const [search, setSearch] = useState('');
  const [selected, setSelected] = useState<Product | null>(null);
  const [cartOpen, setCartOpen] = useState(false);
  const [cart, setCart] = useState<Record<number, number>>({});
  const filtered = useMemo(() => {
    const term = search.trim().toLocaleLowerCase('pt-BR');
    return products.filter((p) => (category === 'Todos' || p.category === category) && (!term || p.name.toLocaleLowerCase('pt-BR').includes(term) || p.description.toLocaleLowerCase('pt-BR').includes(term)));
  }, [category, search]);
  const cartItems = products.filter((p) => cart[p.id]).map((p) => ({ ...p, quantity: cart[p.id] }));
  const cartCount = cartItems.reduce((sum, item) => sum + item.quantity, 0);
  const cartTotal = cartItems.reduce((sum, item) => sum + item.price * item.quantity, 0);

  function changeQuantity(product: Product, difference: number) {
    setCart((current) => {
      const next = Math.max(0, (current[product.id] ?? 0) + difference);
      const updated = { ...current };
      if (next === 0) delete updated[product.id]; else updated[product.id] = next;
      return updated;
    });
  }

  useEffect(() => {
    const modelContext = (document as Document & { modelContext?: { registerTool: (tool: object, options?: { signal?: AbortSignal }) => void | Promise<void> } }).modelContext;
    if (!modelContext?.registerTool) return;
    const lifecycle = new AbortController();
    const register = (tool: object) => {
      try { void Promise.resolve(modelContext.registerTool(tool, { signal: lifecycle.signal })).catch(() => undefined); } catch { /* WebMCP is optional in unsupported browsers. */ }
    };

    register({
      name: 'list_delivery_products',
      title: 'Listar produtos',
      description: 'Lista os produtos visíveis do cardápio, considerando a busca e a categoria selecionada.',
      inputSchema: { type: 'object', properties: {}, additionalProperties: false },
      annotations: { readOnlyHint: true, untrustedContentHint: false },
      execute: () => ({ category, search, products: filtered.map(({ id, name, description, price, category: productCategory }) => ({ id, name, description, price, category: productCategory })) }),
    });
    register({
      name: 'add_delivery_product_to_cart',
      title: 'Adicionar produto ao carrinho',
      description: 'Adiciona uma quantidade de um produto do cardápio ao carrinho e abre o carrinho na tela.',
      inputSchema: { type: 'object', properties: { productId: { type: 'integer' }, quantity: { type: 'integer', minimum: 1, maximum: 20 } }, required: ['productId'], additionalProperties: false },
      annotations: { readOnlyHint: false, untrustedContentHint: false },
      execute: (input: unknown) => {
        const value = input as { productId?: number; quantity?: number };
        const product = products.find((item) => item.id === value.productId);
        const quantity = value.quantity ?? 1;
        if (!product || !Number.isInteger(quantity) || quantity < 1 || quantity > 20) throw new Error('Produto ou quantidade inválida.');
        const nextQuantity = (cart[product.id] ?? 0) + quantity;
        setCart((current) => ({ ...current, [product.id]: (current[product.id] ?? 0) + quantity }));
        setCartOpen(true);
        return { productId: product.id, name: product.name, quantity: nextQuantity, status: 'added' };
      },
    });
    register({
      name: 'read_delivery_cart',
      title: 'Consultar carrinho',
      description: 'Consulta os itens, quantidades e o total atual do carrinho.',
      inputSchema: { type: 'object', properties: {}, additionalProperties: false },
      annotations: { readOnlyHint: true, untrustedContentHint: false },
      execute: () => ({ items: cartItems.map(({ id, name, price, quantity }) => ({ id, name, price, quantity })), count: cartCount, total: cartTotal }),
    });

    return () => lifecycle.abort();
  }, [cart, cartCount, cartItems, cartTotal, category, filtered, search]);

  return (
    <main className="min-h-screen pb-24 text-[#202332]">
      <header className="sticky top-0 z-40 border-b border-black/5 bg-white/92 backdrop-blur-xl">
        <div className="mx-auto flex h-20 max-w-6xl items-center gap-4 px-4 sm:px-6">
          <button className="grid size-11 place-items-center rounded-2xl bg-[#fff1eb] text-[#ff4b0a] sm:hidden" aria-label="Abrir menu"><Menu className="size-5" /></button>
          <img src="/logo-sensor-delivery.png" alt="Sensor Delivery" className="h-14 w-auto object-contain" />
          <SearchBox value={search} onChange={setSearch} desktop />
          <button onClick={() => setCartOpen(true)} className="relative ml-auto grid size-12 place-items-center rounded-2xl bg-[#ff4b0a] text-white shadow-[0_8px_22px_rgba(255,75,10,.28)]" aria-label={`Abrir carrinho com ${cartCount} itens`}>
            <ShoppingBag className="size-5" />
            {cartCount > 0 && <span className="absolute -right-1.5 -top-1.5 min-w-6 rounded-full bg-[#6c55e8] px-1.5 text-center text-xs font-bold leading-6">{cartCount}</span>}
          </button>
        </div>
      </header>

      <section className="mx-auto max-w-6xl px-4 pb-8 pt-5 sm:px-6 sm:pt-8">
        <div className="store-banner overflow-hidden rounded-[28px] px-6 py-6 text-white sm:px-9 sm:py-8">
          <div className="relative z-10 flex flex-col justify-between gap-7 sm:flex-row sm:items-end">
            <div><div className="mb-3 inline-flex items-center gap-2 rounded-full bg-white/16 px-3 py-1.5 text-sm font-semibold backdrop-blur"><span className="size-2 rounded-full bg-[#57e38e]" />Aberto agora</div><p className="text-sm font-medium text-white/75">Bombinhas · SC</p><h1 className="mt-1 text-3xl font-extrabold tracking-[-0.03em] sm:text-4xl">O que você quer pedir hoje?</h1><p className="mt-2 max-w-xl text-[15px] leading-6 text-white/80">Escolha seus favoritos e receba tudo quentinho onde estiver.</p></div>
            <div className="flex items-center gap-3 rounded-2xl bg-white/12 px-4 py-3 backdrop-blur"><Clock3 className="size-5 text-[#ffd0bd]" /><div><p className="text-xs text-white/65">Entrega estimada</p><p className="font-bold">35–50 min</p></div></div>
          </div>
        </div>

        <SearchBox value={search} onChange={setSearch} />
        <nav className="no-scrollbar mt-7 flex gap-2 overflow-x-auto pb-2" aria-label="Categorias">
          {categories.map((item) => <button key={item} onClick={() => setCategory(item)} className={`shrink-0 rounded-full px-5 py-2.5 text-sm font-bold transition ${category === item ? 'bg-[#ff4b0a] text-white shadow-[0_7px_16px_rgba(255,75,10,.2)]' : 'border border-[#ebe7e4] bg-white text-[#666a76] hover:border-[#ff4b0a]/35 hover:text-[#ff4b0a]'}`}>{item}</button>)}
        </nav>

        <div className="mb-5 mt-7 flex items-end justify-between"><div><p className="text-sm font-semibold text-[#ff4b0a]">Cardápio</p><h2 className="text-2xl font-extrabold tracking-[-0.02em]">Peça do seu jeito</h2></div><span className="text-sm text-[#858894]">{filtered.length} itens</span></div>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {filtered.map((product) => <article key={product.id} className="product-card group overflow-hidden rounded-[24px] border border-[#eee9e6] bg-white">
            <button onClick={() => setSelected(product)} className="block w-full text-left" aria-label={`Ver ${product.name}`}>
              <div className="relative h-44 overflow-hidden bg-[#fff2ec]"><img src={product.image} alt="" className="h-full w-full object-cover transition duration-500 group-hover:scale-105" />{product.badge && <span className="absolute left-3 top-3 rounded-full bg-white/92 px-3 py-1.5 text-xs font-bold text-[#ff4b0a] shadow-sm">{product.badge}</span>}</div>
              <div className="p-5 pb-3"><h3 className="text-[17px] font-extrabold leading-6">{product.name}</h3><p className="mt-2 min-h-11 text-sm leading-[1.55] text-[#747783]">{product.description}</p></div>
            </button>
            <div className="flex items-center justify-between px-5 pb-5"><div><span className="block text-xs text-[#9a9ca5]">A partir de</span><strong className="text-lg text-[#ff4b0a]">{money.format(product.price)}</strong></div><button onClick={() => changeQuantity(product, 1)} className="grid size-11 place-items-center rounded-2xl bg-[#ff4b0a] text-white hover:bg-[#ec3f00]" aria-label={`Adicionar ${product.name}`}><Plus className="size-5" /></button></div>
          </article>)}
        </div>
        {filtered.length === 0 && <div className="rounded-[24px] border border-dashed border-[#ddd6d2] bg-white px-6 py-14 text-center"><Search className="mx-auto mb-3 size-7 text-[#bbb4b0]" /><h3 className="font-bold">Nenhum item encontrado</h3></div>}
      </section>

      <nav className="fixed inset-x-0 bottom-0 z-40 border-t border-black/5 bg-white/95 px-4 pb-[max(10px,env(safe-area-inset-bottom))] pt-2 backdrop-blur-xl sm:hidden" aria-label="Navegação principal"><div className="mx-auto grid max-w-md grid-cols-4">{[{ label: 'Início', icon: Home, active: true }, { label: 'Cardápio', icon: Store }, { label: 'Pedidos', icon: PackageCheck }, { label: 'Conta', icon: UserRound }].map(({ label, icon: Icon, active }) => <button key={label} className={`flex flex-col items-center gap-1 py-1 text-[11px] font-semibold ${active ? 'text-[#ff4b0a]' : 'text-[#777a86]'}`}><Icon className="size-5" />{label}</button>)}</div></nav>

      <Dialog open={Boolean(selected)} onOpenChange={(open) => !open && setSelected(null)}>{selected && <DialogContent className="overflow-hidden rounded-[26px] p-0 sm:max-w-lg"><div className="h-56 bg-[#fff2ec]"><img src={selected.image} alt={selected.name} className="h-full w-full object-cover" /></div><div className="p-6"><DialogHeader><DialogTitle className="text-2xl font-extrabold">{selected.name}</DialogTitle><DialogDescription className="text-[15px] leading-6">{selected.description}</DialogDescription></DialogHeader><div className="mt-5 rounded-2xl bg-[#f8f6f4] p-4"><p className="text-sm font-bold">Personalize no próximo passo</p><p className="mt-1 text-sm text-[#777a86]">Escolha tamanho, sabores, borda e adicionais.</p></div><button onClick={() => { changeQuantity(selected, 1); setSelected(null); setCartOpen(true); }} className="mt-5 flex h-13 w-full items-center justify-between rounded-2xl bg-[#ff4b0a] px-5 font-bold text-white"><span>Adicionar ao carrinho</span><span>{money.format(selected.price)}</span></button></div></DialogContent>}</Dialog>

      <Sheet open={cartOpen} onOpenChange={setCartOpen}><SheetContent className="w-full gap-0 p-0 sm:max-w-md"><SheetHeader className="border-b border-[#eee9e6] p-6"><SheetTitle className="text-2xl font-extrabold">Meu carrinho</SheetTitle><SheetDescription>{cartCount ? `${cartCount} ${cartCount === 1 ? 'item' : 'itens'} no pedido` : 'Seu carrinho está vazio'}</SheetDescription></SheetHeader><div className="flex-1 overflow-y-auto p-5">{cartItems.map((item) => <div key={item.id} className="mb-3 flex gap-3 rounded-2xl border border-[#eee9e6] p-3"><img src={item.image} alt="" className="size-20 rounded-xl object-cover" /><div className="min-w-0 flex-1"><p className="truncate font-bold">{item.name}</p><p className="mt-1 text-sm font-semibold text-[#ff4b0a]">{money.format(item.price * item.quantity)}</p><div className="mt-2 flex items-center gap-3"><button onClick={() => changeQuantity(item, -1)} className="grid size-7 place-items-center rounded-lg bg-[#fff0e9] text-[#ff4b0a]" aria-label="Diminuir"><Minus className="size-4" /></button><span className="text-sm font-bold">{item.quantity}</span><button onClick={() => changeQuantity(item, 1)} className="grid size-7 place-items-center rounded-lg bg-[#fff0e9] text-[#ff4b0a]" aria-label="Aumentar"><Plus className="size-4" /></button></div></div></div>)}</div><div className="border-t border-[#eee9e6] bg-white p-5 pb-7"><div className="mb-4 flex items-center justify-between"><span className="text-[#777a86]">Total</span><strong className="text-xl">{money.format(cartTotal)}</strong></div><button disabled={!cartCount} className="flex h-13 w-full items-center justify-between rounded-2xl bg-[#ff4b0a] px-5 font-bold text-white disabled:opacity-40"><span>Continuar pedido</span><ArrowRight className="size-5" /></button></div></SheetContent></Sheet>
    </main>
  );
}

function SearchBox({ value, onChange, desktop = false }: { value: string; onChange: (value: string) => void; desktop?: boolean }) {
  return <div className={`relative ${desktop ? 'ml-auto hidden w-full max-w-md sm:block' : 'mt-5 sm:hidden'}`}><Search className="absolute left-4 top-1/2 size-5 -translate-y-1/2 text-[#8a8d98]" /><input value={value} onChange={(event) => onChange(event.target.value)} placeholder="Buscar pizza, lanche ou bebida" className="h-13 w-full rounded-2xl border border-[#ebe7e4] bg-white pl-12 pr-4 text-[15px] outline-none transition focus:border-[#ff4b0a] focus:ring-4 focus:ring-[#ff4b0a]/10" /></div>;
}
