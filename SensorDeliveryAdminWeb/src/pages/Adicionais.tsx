import React, { useState, useEffect } from 'react';
import { api } from '../api/client';
import { PlusCircle, Plus, Edit2, Search, AlertCircle, X, Check, Trash2 } from 'lucide-react';

interface ProdutoOpcao {
  id: string;
  nome: string;
  categoria_nome?: string;
}

interface Adicional {
  id: string;
  produto_id: string;
  produto_nome?: string;
  categoria_nome?: string;
  nome: string;
  preco: number;
  limite: number;
  obrigatorio: boolean;
  ordem: number;
  ativo: boolean;
}

export const Adicionais: React.FC = () => {
  const [adicionais, setAdicionais] = useState<Adicional[]>([]);
  const [produtos, setProdutos] = useState<ProdutoOpcao[]>([]);
  const [carregando, setCarregando] = useState(true);
  const [modalAberto, setModalAberto] = useState(false);
  const [salvando, setSalvando] = useState(false);
  const [erro, setErro] = useState('');
  const [busca, setBusca] = useState('');
  const [produtoFiltro, setProdutoFiltro] = useState<string>('todos');

  // Form
  const [editandoId, setEditandoId] = useState<string | null>(null);
  const [produtoId, setProdutoId] = useState<string>('');
  const [nome, setNome] = useState('');
  const [preco, setPreco] = useState('');
  const [limite, setLimite] = useState('1');
  const [obrigatorio, setObrigatorio] = useState(false);
  const [ordem, setOrdem] = useState('0');
  const [ativo, setAtivo] = useState(true);

  const carregarDados = async () => {
    try {
      setCarregando(true);
      const [resAdicionais, resProdutos] = await Promise.all([
        api.get('/adicionais'),
        api.get('/adicionais/produtos'),
      ]);

      setAdicionais(resAdicionais.data?.adicionais || (Array.isArray(resAdicionais.data) ? resAdicionais.data : []));
      const listaProds = resProdutos.data?.produtos || (Array.isArray(resProdutos.data) ? resProdutos.data : []);
      setProdutos(listaProds);
      if (listaProds.length > 0 && !produtoId) {
        setProdutoId(listaProds[0].id);
      }
    } catch (err: any) {
      console.error('Erro ao carregar adicionais:', err);
    } finally {
      setCarregando(false);
    }
  };

  useEffect(() => {
    carregarDados();
  }, []);

  const formatarMoeda = (valor: number) => {
    return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(valor || 0);
  };

  const abrirModalNovo = () => {
    setEditandoId(null);
    if (produtos.length > 0) {
      setProdutoId(produtos[0].id);
    }
    setNome('');
    setPreco('0,00');
    setLimite('1');
    setObrigatorio(false);
    setOrdem('0');
    setAtivo(true);
    setErro('');
    setModalAberto(true);
  };

  const abrirModalEditar = (item: Adicional) => {
    setEditandoId(item.id);
    setProdutoId(item.produto_id);
    setNome(item.nome);
    setPreco(Number(item.preco || 0).toFixed(2).replace('.', ','));
    setLimite(String(item.limite || 1));
    setObrigatorio(Boolean(item.obrigatorio));
    setOrdem(String(item.ordem || 0));
    setAtivo(Boolean(item.ativo));
    setErro('');
    setModalAberto(true);
  };

  const fecharModal = () => {
    setModalAberto(false);
    setEditandoId(null);
    setErro('');
  };

  const salvarAdicional = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!nome.trim()) {
      setErro('Nome do adicional é obrigatório.');
      return;
    }
    if (!produtoId) {
      setErro('Selecione um produto.');
      return;
    }

    try {
      setSalvando(true);
      setErro('');

      const precoNum = Number(preco.replace(/\./g, '').replace(',', '.')) || 0;
      const payload = {
        produtoId,
        nome: nome.trim(),
        preco: precoNum,
        limite: parseInt(limite, 10) || 1,
        obrigatorio,
        ordem: parseInt(ordem, 10) || 0,
        ativo,
      };

      if (editandoId) {
        await api.put(`/adicionais/${editandoId}`, payload);
      } else {
        await api.post('/adicionais', payload);
      }

      fecharModal();
      carregarDados();
    } catch (err: any) {
      console.error('Erro ao salvar adicional:', err);
      setErro(err.response?.data?.erro || 'Erro ao salvar adicional.');
    } finally {
      setSalvando(false);
    }
  };

  const alternarAtivo = async (item: Adicional) => {
    try {
      await api.patch(`/adicionais/${item.id}/situacao`, { ativo: !item.ativo });
      setAdicionais((prev) =>
        prev.map((a) => (a.id === item.id ? { ...a, ativo: !a.ativo } : a))
      );
    } catch (err: any) {
      console.error('Erro ao alternar status do adicional:', err);
      alert(err.response?.data?.erro || 'Não foi possível alterar a situação.');
    }
  };

  const adicionaisFiltrados = adicionais.filter((item) => {
    const correspondeBusca =
      item.nome.toLowerCase().includes(busca.toLowerCase()) ||
      (item.produto_nome && item.produto_nome.toLowerCase().includes(busca.toLowerCase())) ||
      (item.categoria_nome && item.categoria_nome.toLowerCase().includes(busca.toLowerCase()));
    const correspondeProduto =
      produtoFiltro === 'todos' || item.produto_id === produtoFiltro;
    return correspondeBusca && correspondeProduto;
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white flex items-center gap-2">
            <PlusCircle className="w-7 h-7 text-indigo-400" />
            Adicionais & Opcionais
          </h1>
          <p className="text-sm text-slate-400">
            Cadastre acompanhamentos, molhos extras e complementos vinculados a cada produto
          </p>
        </div>
        <button
          onClick={abrirModalNovo}
          className="inline-flex items-center justify-center gap-2 px-4 py-2.5 bg-indigo-600 hover:bg-indigo-500 text-white font-medium rounded-xl transition-colors shadow-lg shadow-indigo-600/20"
        >
          <Plus className="w-5 h-5" />
          Novo Adicional
        </button>
      </div>

      {/* Filtros e Busca */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="md:col-span-2 bg-[#152439] p-4 rounded-2xl border border-[#2A405B] flex items-center gap-3">
          <Search className="w-5 h-5 text-slate-400" />
          <input
            type="text"
            placeholder="Buscar por adicional ou produto vinculado..."
            value={busca}
            onChange={(e) => setBusca(e.target.value)}
            className="bg-transparent border-none outline-none text-white w-full placeholder-slate-500 text-sm"
          />
          {busca && (
            <button onClick={() => setBusca('')} className="text-slate-400 hover:text-white">
              <X className="w-4 h-4" />
            </button>
          )}
        </div>

        <div className="bg-[#152439] p-2.5 rounded-2xl border border-[#2A405B] flex items-center">
          <select
            value={produtoFiltro}
            onChange={(e) => setProdutoFiltro(e.target.value)}
            className="bg-transparent text-slate-300 text-sm w-full outline-none px-2 cursor-pointer"
          >
            <option value="todos" className="bg-[#152439] text-white">Todos os Produtos</option>
            {produtos.map((p) => (
              <option key={p.id} value={p.id} className="bg-[#152439] text-white">
                {p.nome}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Tabela de Adicionais */}
      <div className="bg-[#152439] rounded-2xl border border-[#2A405B] overflow-hidden shadow-xl">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-slate-300">
            <thead className="bg-[#0B132B]/80 text-xs uppercase text-slate-400 font-semibold border-b border-[#2A405B]">
              <tr>
                <th className="px-6 py-4">Adicional / Opcional</th>
                <th className="px-6 py-4">Produto Vinculado</th>
                <th className="px-6 py-4">Preço Extra</th>
                <th className="px-6 py-4">Limite Máx.</th>
                <th className="px-6 py-4">Obrigatório</th>
                <th className="px-6 py-4">Status</th>
                <th className="px-6 py-4 text-right">Ações</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#2A405B]">
              {carregando ? (
                <tr>
                  <td colSpan={7} className="px-6 py-12 text-center text-slate-400">
                    <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-500"></div>
                    <p className="mt-2">Carregando adicionais...</p>
                  </td>
                </tr>
              ) : adicionaisFiltrados.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-6 py-12 text-center text-slate-400">
                    <PlusCircle className="w-12 h-12 mx-auto text-slate-600 mb-2" />
                    <p className="text-base font-medium text-slate-300">Nenhum adicional encontrado</p>
                    <p className="text-xs text-slate-500 mt-1">
                      {busca || produtoFiltro !== 'todos'
                        ? 'Tente ajustar os filtros da busca.'
                        : 'Clique em "Novo Adicional" para cadastrar.'}
                    </p>
                  </td>
                </tr>
              ) : (
                adicionaisFiltrados.map((item) => (
                  <tr key={item.id} className="hover:bg-[#1e324d]/40 transition-colors">
                    <td className="px-6 py-4 font-semibold text-white">
                      {item.nome}
                    </td>
                    <td className="px-6 py-4 text-xs text-indigo-300">
                      <span className="px-2.5 py-1 bg-[#0B132B] rounded-lg border border-[#2A405B]">
                        {item.produto_nome || 'Todos'}
                      </span>
                    </td>
                    <td className="px-6 py-4 font-medium text-emerald-400">
                      {item.preco > 0 ? formatarMoeda(item.preco) : 'Grátis'}
                    </td>
                    <td className="px-6 py-4 text-slate-300">
                      Até {item.limite}x
                    </td>
                    <td className="px-6 py-4">
                      <span
                        className={`inline-block px-2.5 py-0.5 rounded-full text-xs font-semibold ${
                          item.obrigatorio
                            ? 'bg-amber-500/10 text-amber-400 border border-amber-500/20'
                            : 'bg-slate-700/30 text-slate-400'
                        }`}
                      >
                        {item.obrigatorio ? 'Sim' : 'Não'}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <button
                        onClick={() => alternarAtivo(item)}
                        className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium border transition-colors ${
                          item.ativo
                            ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20 hover:bg-emerald-500/20'
                            : 'bg-red-500/10 text-red-400 border-red-500/20 hover:bg-red-500/20'
                        }`}
                      >
                        {item.ativo ? (
                          <>
                            <Check className="w-3.5 h-3.5" />
                            Ativo
                          </>
                        ) : (
                          <>
                            <X className="w-3.5 h-3.5" />
                            Inativo
                          </>
                        )}
                      </button>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <button
                        onClick={() => abrirModalEditar(item)}
                        className="p-2 text-slate-400 hover:text-indigo-400 hover:bg-indigo-500/10 rounded-lg transition-colors"
                        title="Editar Adicional"
                      >
                        <Edit2 className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal de Cadastro / Edição */}
      {modalAberto && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-[#152439] border border-[#2A405B] w-full max-w-lg rounded-2xl shadow-2xl overflow-hidden max-h-[90vh] flex flex-col">
            {/* Modal Header */}
            <div className="px-6 py-4 border-b border-[#2A405B] flex items-center justify-between bg-[#0B132B]/50">
              <h2 className="text-lg font-bold text-white flex items-center gap-2">
                <PlusCircle className="w-5 h-5 text-indigo-400" />
                {editandoId ? 'Editar Adicional' : 'Novo Adicional'}
              </h2>
              <button
                onClick={fecharModal}
                className="text-slate-400 hover:text-white p-1 rounded-lg hover:bg-[#2A405B]/50 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Body */}
            <form onSubmit={salvarAdicional} className="flex-1 overflow-y-auto p-6 space-y-4">
              {erro && (
                <div className="p-3 bg-red-500/10 border border-red-500/20 rounded-xl flex items-center gap-3 text-red-400 text-sm">
                  <AlertCircle className="w-5 h-5 shrink-0" />
                  <span>{erro}</span>
                </div>
              )}

              <div className="space-y-1.5">
                <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400">
                  Produto Vinculado <span className="text-red-400">*</span>
                </label>
                <select
                  required
                  value={produtoId}
                  onChange={(e) => setProdutoId(e.target.value)}
                  className="w-full px-3.5 py-2.5 bg-[#0B132B] border border-[#2A405B] rounded-xl text-white text-sm focus:border-indigo-500 focus:outline-none transition-colors"
                >
                  {produtos.map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.nome} {p.categoria_nome ? `(${p.categoria_nome})` : ''}
                    </option>
                  ))}
                </select>
              </div>

              <div className="space-y-1.5">
                <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400">
                  Nome do Adicional / Opcional <span className="text-red-400">*</span>
                </label>
                <input
                  type="text"
                  required
                  placeholder="Ex: Bacon Crocante, Molho Especial, Queijo Extra"
                  value={nome}
                  onChange={(e) => setNome(e.target.value)}
                  className="w-full px-3.5 py-2.5 bg-[#0B132B] border border-[#2A405B] rounded-xl text-white placeholder-slate-500 text-sm focus:border-indigo-500 focus:outline-none transition-colors"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400">
                    Preço Adicional (R$)
                  </label>
                  <input
                    type="text"
                    placeholder="0,00"
                    value={preco}
                    onChange={(e) => setPreco(e.target.value)}
                    onFocus={(e) => e.target.select()}
                    onBlur={() => {
                      if (!preco.trim()) setPreco('0,00');
                    }}
                    className="w-full px-3.5 py-2.5 bg-[#0B132B] border border-[#2A405B] rounded-xl text-white placeholder-slate-500 text-sm focus:border-indigo-500 focus:outline-none transition-colors"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400">
                    Limite Máximo
                  </label>
                  <input
                    type="number"
                    min="1"
                    max="99"
                    value={limite}
                    onChange={(e) => setLimite(e.target.value)}
                    className="w-full px-3.5 py-2.5 bg-[#0B132B] border border-[#2A405B] rounded-xl text-white placeholder-slate-500 text-sm focus:border-indigo-500 focus:outline-none transition-colors"
                  />
                </div>
              </div>

              <div className="flex items-center gap-6 pt-2">
                <label className="flex items-center gap-2.5 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={obrigatorio}
                    onChange={(e) => setObrigatorio(e.target.checked)}
                    className="w-4 h-4 rounded text-indigo-600 focus:ring-indigo-500 bg-[#0B132B] border-[#2A405B]"
                  />
                  <span className="text-sm text-slate-300 font-medium">Obrigatório</span>
                </label>

                <label className="flex items-center gap-2.5 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={ativo}
                    onChange={(e) => setAtivo(e.target.checked)}
                    className="w-4 h-4 rounded text-indigo-600 focus:ring-indigo-500 bg-[#0B132B] border-[#2A405B]"
                  />
                  <span className="text-sm text-slate-300 font-medium">Ativo no Cardápio</span>
                </label>
              </div>

              {/* Modal Footer */}
              <div className="pt-4 border-t border-[#2A405B] flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={fecharModal}
                  className="px-4 py-2 bg-transparent hover:bg-[#2A405B]/40 text-slate-300 text-sm font-medium rounded-xl transition-colors"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  disabled={salvando}
                  className="inline-flex items-center gap-2 px-5 py-2.5 bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 text-white text-sm font-semibold rounded-xl transition-colors shadow-lg shadow-indigo-600/20"
                >
                  {salvando ? (
                    <>
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                      Salvando...
                    </>
                  ) : (
                    <>
                      <Check className="w-4 h-4" />
                      Salvar Adicional
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Adicionais;
