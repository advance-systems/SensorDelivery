import React, { useState, useEffect } from 'react';
import { api } from '../api/client';
import { UtensilsCrossed, Plus, Edit2, Search, AlertCircle, Image as ImageIcon, X } from 'lucide-react';

interface Produto {
  id: string;
  categoria_id: string;
  categoria_nome?: string;
  nome: string;
  descricao?: string;
  preco: number;
  preco_promocional?: number | null;
  imagem_url?: string;
  ativo: boolean;
  disponivel?: boolean;
}

interface Categoria {
  id: string;
  nome: string;
}

export const Produtos: React.FC = () => {
  const [produtos, setProdutos] = useState<Produto[]>([]);
  const [categorias, setCategorias] = useState<Categoria[]>([]);
  const [carregando, setCarregando] = useState(true);
  const [modalAberto, setModalAberto] = useState(false);
  const [salvando, setSalvando] = useState(false);
  const [erro, setErro] = useState('');
  const [busca, setBusca] = useState('');
  const [categoriaFiltro, setCategoriaFiltro] = useState<string | 'todas'>('todas');

  // Form
  const [editandoId, setEditandoId] = useState<string | null>(null);
  const [categoriaId, setCategoriaId] = useState<string>('');
  const [nome, setNome] = useState('');
  const [descricao, setDescricao] = useState('');
  const [preco, setPreco] = useState('');
  const [imagemUrl, setImagemUrl] = useState('');
  const [ativo, setAtivo] = useState(true);

  const carregarDados = async () => {
    try {
      setCarregando(true);
      const [resProd, resCat] = await Promise.all([
        api.get('/cardapio'),
        api.get('/cardapio/categorias'),
      ]);

      const listaProd = resProd.data?.produtos || (Array.isArray(resProd.data) ? resProd.data : []);
      const listaCat = resCat.data?.categorias || (Array.isArray(resCat.data) ? resCat.data : []);

      setProdutos(listaProd);
      setCategorias(listaCat);
      if (listaCat.length > 0 && !categoriaId) {
        setCategoriaId(listaCat[0].id);
      }
    } catch (err) {
      console.error('Erro ao carregar produtos/categorias:', err);
    } finally {
      setCarregando(false);
    }
  };

  useEffect(() => {
    carregarDados();
  }, []);

  const abrirModalNovo = () => {
    setEditandoId(null);
    setNome('');
    setDescricao('');
    setPreco('');
    setImagemUrl('');
    setAtivo(true);
    if (categorias.length > 0) setCategoriaId(categorias[0].id);
    setErro('');
    setModalAberto(true);
  };

  const abrirModalEditar = (prod: Produto) => {
    setEditandoId(prod.id);
    setCategoriaId(prod.categoria_id);
    setNome(prod.nome);
    setDescricao(prod.descricao || '');
    setPreco(prod.preco ? String(prod.preco) : '');
    setImagemUrl(prod.imagem_url || '');
    setAtivo(prod.ativo);
    setErro('');
    setModalAberto(true);
  };

  const salvarProduto = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!categoriaId) {
      setErro('Selecione uma categoria.');
      return;
    }
    setErro('');
    setSalvando(true);

    try {
      const payload = {
        categoriaId: categoriaId,
        nome: nome.trim(),
        descricao: descricao.trim(),
        preco: Number(preco.replace(',', '.')) || 0,
        imagemUrl: imagemUrl.trim(),
        tipo: 'PRODUTO',
        disponivel: true,
      };

      if (editandoId) {
        await api.put(`/cardapio/${editandoId}`, payload);
      } else {
        await api.post('/cardapio', payload);
      }

      setModalAberto(false);
      carregarDados();
    } catch (err: any) {
      console.error('Erro ao salvar produto:', err);
      setErro(err.response?.data?.erro || err.response?.data?.mensagem || 'Falha ao salvar produto.');
    } finally {
      setSalvando(false);
    }
  };

  const alternarStatus = async (prod: Produto) => {
    try {
      await api.patch(`/cardapio/${prod.id}/situacao`, { ativo: !prod.ativo });
      setProdutos((prev) =>
        prev.map((p) => (p.id === prod.id ? { ...p, ativo: !p.ativo } : p))
      );
    } catch (err) {
      console.error('Erro ao alterar status:', err);
    }
  };

  const formatarMoeda = (valor: number) => {
    return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(valor || 0);
  };

  const produtosFiltrados = produtos.filter((p) => {
    const bateTexto = p.nome.toLowerCase().includes(busca.toLowerCase()) ||
                      p.descricao?.toLowerCase().includes(busca.toLowerCase());
    const bateCategoria = categoriaFiltro === 'todas' || p.categoria_id === categoriaFiltro;
    return bateTexto && bateCategoria;
  });

  return (
    <div className="space-y-6">
      {/* Topo */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white tracking-tight flex items-center gap-2.5">
            <UtensilsCrossed className="w-6 h-6 text-[#8C63FF]" />
            Produtos do Cardápio
          </h2>
          <p className="text-xs text-[#9CAABC] mt-0.5">
            Cadastre os itens, preços, descrições e fotos
          </p>
        </div>

        <button
          onClick={abrirModalNovo}
          className="flex items-center gap-2 px-4 py-2.5 bg-gradient-to-r from-[#8C63FF] to-[#7847eb] hover:from-[#7847eb] hover:to-[#6366F1] text-white rounded-xl text-xs font-bold shadow-lg shadow-[#8C63FF]/25 transition-all cursor-pointer"
        >
          <Plus className="w-4 h-4" />
          <span>Novo Produto</span>
        </button>
      </div>

      {/* Filtros e Busca */}
      <div className="flex flex-col sm:flex-row items-center gap-3">
        <div className="relative flex-1 w-full">
          <input
            type="text"
            value={busca}
            onChange={(e) => setBusca(e.target.value)}
            placeholder="Buscar produto por nome ou descrição..."
            className="w-full bg-[#152439] border border-[#2A405B] focus:border-[#8C63FF] text-white rounded-xl px-4 py-2.5 pl-10 text-xs focus:outline-none transition-colors"
          />
          <Search className="w-4 h-4 text-[#64748B] absolute left-3.5 top-1/2 -translate-y-1/2" />
        </div>

        <select
          value={categoriaFiltro}
          onChange={(e) => setCategoriaFiltro(e.target.value)}
          className="w-full sm:w-56 bg-[#152439] border border-[#2A405B] text-xs text-white rounded-xl px-3 py-2.5 focus:outline-none focus:border-[#8C63FF]"
        >
          <option value="todas">Todas as Categorias</option>
          {categorias.map((cat) => (
            <option key={cat.id} value={cat.id}>
              {cat.nome}
            </option>
          ))}
        </select>
      </div>

      {/* Grid de Cards de Produtos */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
        {carregando ? (
          <div className="col-span-full text-center py-12 text-[#9CAABC]">
            <div className="w-8 h-8 border-2 border-[#8C63FF] border-t-transparent rounded-full animate-spin mx-auto mb-3" />
            Carregando catálogo de produtos...
          </div>
        ) : produtosFiltrados.length === 0 ? (
          <div className="col-span-full text-center py-12 text-[#64748B] bg-[#152439] rounded-2xl border border-[#2A405B]">
            Nenhum produto cadastrado com estes filtros
          </div>
        ) : (
          produtosFiltrados.map((prod) => (
            <div
              key={prod.id}
              className="bg-[#152439] border border-[#2A405B] rounded-2xl overflow-hidden shadow-lg hover:border-[#8C63FF]/50 transition-all flex flex-col group"
            >
              {/* Imagem do Produto */}
              <div className="h-40 bg-[#0B132B] relative overflow-hidden flex items-center justify-center">
                {prod.imagem_url ? (
                  <img
                    src={prod.imagem_url}
                    alt={prod.nome}
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                    onError={(e) => {
                      (e.target as HTMLElement).style.display = 'none';
                    }}
                  />
                ) : (
                  <div className="text-[#64748B] flex flex-col items-center gap-1">
                    <ImageIcon className="w-8 h-8 opacity-40" />
                    <span className="text-[10px]">Sem foto</span>
                  </div>
                )}
                <span className="absolute top-2 left-2 px-2 py-0.5 rounded-md bg-[#0B132B]/80 backdrop-blur-xs text-[10px] font-bold text-white border border-[#2A405B]">
                  {prod.categoria_nome || 'Geral'}
                </span>
              </div>

              {/* Detalhes */}
              <div className="p-4 flex-1 flex flex-col justify-between">
                <div>
                  <h3 className="font-bold text-sm text-white line-clamp-1">{prod.nome}</h3>
                  <p className="text-[11px] text-[#9CAABC] line-clamp-2 mt-1 min-h-[32px]">
                    {prod.descricao || 'Sem descrição cadastrada.'}
                  </p>
                </div>

                <div className="pt-3 border-t border-[#2A405B]/60 flex items-center justify-between mt-3">
                  <span className="font-extrabold text-base text-[#10B981]">
                    {formatarMoeda(prod.preco)}
                  </span>

                  <div className="flex items-center gap-1.5">
                    <button
                      onClick={() => alternarStatus(prod)}
                      className={`px-2 py-0.5 rounded-md text-[10px] font-bold border transition-colors ${
                        prod.ativo
                          ? 'bg-[#10B981]/20 text-[#10B981] border-[#10B981]/30'
                          : 'bg-[#64748B]/20 text-[#64748B] border-[#64748B]/30'
                      }`}
                    >
                      {prod.ativo ? 'Ativo' : 'Inativo'}
                    </button>

                    <button
                      onClick={() => abrirModalEditar(prod)}
                      className="p-1.5 text-[#9CAABC] hover:text-[#8C63FF] hover:bg-[#8C63FF]/10 rounded-lg transition-colors"
                      title="Editar"
                    >
                      <Edit2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Modal Novo / Editar Produto */}
      {modalAberto && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-[#152439] border border-[#2A405B] rounded-2xl w-full max-w-lg overflow-hidden shadow-2xl">
            {/* Header Modal */}
            <div className="p-4 md:p-5 border-b border-[#2A405B] flex items-center justify-between bg-[#121f30]">
              <h3 className="font-bold text-base text-white">
                {editandoId ? 'Editar Produto' : 'Novo Produto'}
              </h3>
              <button
                onClick={() => setModalAberto(false)}
                className="p-1 text-[#9CAABC] hover:text-white rounded-lg transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Form */}
            <form onSubmit={salvarProduto} className="p-4 md:p-6 space-y-4">
              {erro && (
                <div className="p-3 bg-[#EF4444]/10 border border-[#EF4444]/30 rounded-xl text-[#EF4444] text-xs flex items-center gap-2">
                  <AlertCircle className="w-4 h-4 shrink-0" />
                  <span>{erro}</span>
                </div>
              )}

              <div>
                <label className="block text-xs font-semibold text-[#9CAABC] uppercase tracking-wider mb-1.5">
                  Categoria *
                </label>
                <select
                  value={categoriaId}
                  onChange={(e) => setCategoriaId(e.target.value)}
                  className="w-full bg-[#0B132B] border border-[#2A405B] focus:border-[#8C63FF] text-white rounded-xl px-4 py-2.5 text-xs focus:outline-none transition-colors"
                >
                  {categorias.map((cat) => (
                    <option key={cat.id} value={cat.id}>
                      {cat.nome}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold text-[#9CAABC] uppercase tracking-wider mb-1.5">
                  Nome do Produto *
                </label>
                <input
                  type="text"
                  required
                  value={nome}
                  onChange={(e) => setNome(e.target.value)}
                  placeholder="Ex: X-Salada Especial, Pizza Calabresa Grande"
                  className="w-full bg-[#0B132B] border border-[#2A405B] focus:border-[#8C63FF] text-white rounded-xl px-4 py-2.5 text-xs focus:outline-none transition-colors"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-[#9CAABC] uppercase tracking-wider mb-1.5">
                  Descrição / Ingredientes
                </label>
                <textarea
                  value={descricao}
                  onChange={(e) => setDescricao(e.target.value)}
                  rows={2}
                  placeholder="Pão brioche, hambúrguer 160g, queijo prato, alface, tomate e maionese artesanal"
                  className="w-full bg-[#0B132B] border border-[#2A405B] focus:border-[#8C63FF] text-white rounded-xl px-4 py-2 text-xs focus:outline-none transition-colors"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-[#9CAABC] uppercase tracking-wider mb-1.5">
                    Preço (R$)
                  </label>
                  <input
                    type="text"
                    required
                    value={preco}
                    onChange={(e) => setPreco(e.target.value)}
                    placeholder="0,00"
                    className="w-full bg-[#0B132B] border border-[#2A405B] focus:border-[#8C63FF] text-white rounded-xl px-4 py-2.5 text-xs focus:outline-none transition-colors"
                  />
                </div>

                <div className="flex items-center pt-6">
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={ativo}
                      onChange={(e) => setAtivo(e.target.checked)}
                      className="w-4 h-4 accent-[#8C63FF] rounded cursor-pointer"
                    />
                    <span className="text-xs font-semibold text-white">Produto Ativo</span>
                  </label>
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-[#9CAABC] uppercase tracking-wider mb-1.5">
                  URL da Imagem (Opcional)
                </label>
                <input
                  type="text"
                  value={imagemUrl}
                  onChange={(e) => setImagemUrl(e.target.value)}
                  placeholder="https://..."
                  className="w-full bg-[#0B132B] border border-[#2A405B] focus:border-[#8C63FF] text-white rounded-xl px-4 py-2.5 text-xs focus:outline-none transition-colors"
                />
              </div>

              {/* Footer */}
              <div className="pt-4 flex items-center justify-end gap-3 border-t border-[#2A405B]">
                <button
                  type="button"
                  onClick={() => setModalAberto(false)}
                  className="px-4 py-2.5 text-xs font-semibold text-[#9CAABC] hover:text-white rounded-xl transition-colors"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  disabled={salvando}
                  className="px-5 py-2.5 bg-gradient-to-r from-[#8C63FF] to-[#7847eb] hover:from-[#7847eb] hover:to-[#6366F1] text-white text-xs font-bold rounded-xl shadow-md shadow-[#8C63FF]/20 transition-all cursor-pointer disabled:opacity-50"
                >
                  {salvando ? 'Salvando...' : 'Salvar Produto'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
