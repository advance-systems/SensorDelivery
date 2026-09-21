import React, { useState, useEffect, useRef } from 'react';
import { api } from '../api/client';
import { Layers, Plus, Edit2, Trash2, Check, X, Search, AlertCircle } from 'lucide-react';

interface Categoria {
  id: number;
  nome: string;
  descricao?: string;
  ativo: boolean;
  ordem?: number;
  permite_sabores?: boolean;
  max_sabores?: number;
}

export const Categorias: React.FC = () => {
  const [categorias, setCategorias] = useState<Categoria[]>([]);
  const [carregando, setCarregando] = useState(true);
  const [modalAberto, setModalAberto] = useState(false);
  const [salvando, setSalvando] = useState(false);
  const [erro, setErro] = useState('');
  const [busca, setBusca] = useState('');

  // Formulário
  const [editandoId, setEditandoId] = useState<number | null>(null);
  const [nome, setNome] = useState('');
  const [descricao, setDescricao] = useState('');
  const [ativo, setAtivo] = useState(true);
  const [ordem, setOrdem] = useState(0);
  const [permiteSabores, setPermiteSabores] = useState(false);
  const [maxSabores, setMaxSabores] = useState(1);

  const inputNomeRef = useRef<HTMLInputElement>(null);

  const focarPrimeiroCampo = () => {
    setTimeout(() => {
      inputNomeRef.current?.focus();
    }, 50);
  };

  const carregarCategorias = async () => {
    try {
      setCarregando(true);
      const response = await api.get('/categorias');
      if (Array.isArray(response.data)) {
        setCategorias(response.data);
      } else if (response.data?.categorias) {
        setCategorias(response.data.categorias);
      }
    } catch (err) {
      console.error('Erro ao carregar categorias:', err);
    } finally {
      setCarregando(false);
    }
  };

  useEffect(() => {
    carregarCategorias();
  }, []);

  const abrirModalNovo = () => {
    setEditandoId(null);
    setNome('');
    setDescricao('');
    setAtivo(true);
    setOrdem(categorias.length + 1);
    setPermiteSabores(false);
    setMaxSabores(1);
    setErro('');
    setModalAberto(true);
    focarPrimeiroCampo();
  };

  const abrirModalEditar = (cat: Categoria) => {
    setEditandoId(cat.id);
    setNome(cat.nome);
    setDescricao(cat.descricao || '');
    setAtivo(cat.ativo);
    setOrdem(cat.ordem || 0);
    setPermiteSabores(!!cat.permite_sabores);
    setMaxSabores(cat.max_sabores || 1);
    setErro('');
    setModalAberto(true);
    focarPrimeiroCampo();
  };

  const salvarCategoria = async (e: React.FormEvent) => {
    e.preventDefault();
    setErro('');
    setSalvando(true);

    try {
      const payload = {
        nome,
        descricao,
        ativo,
        ordem: Number(ordem),
        permite_sabores: permiteSabores,
        max_sabores: permiteSabores ? Number(maxSabores) : 1,
      };

      if (editandoId) {
        await api.put(`/categorias/${editandoId}`, payload);
      } else {
        await api.post('/categorias', payload);
      }

      setModalAberto(false);
      carregarCategorias();
    } catch (err: any) {
      console.error('Erro ao salvar categoria:', err);
      setErro(err.response?.data?.mensagem || 'Falha ao salvar a categoria.');
    } finally {
      setSalvando(false);
    }
  };

  const alternarStatus = async (cat: Categoria) => {
    try {
      await api.patch(`/categorias/${cat.id}/status`, { ativo: !cat.ativo });
      setCategorias((prev) =>
        prev.map((c) => (c.id === cat.id ? { ...c, ativo: !c.ativo } : c))
      );
    } catch (err) {
      console.error('Erro ao alterar status:', err);
    }
  };

  const categoriasFiltradas = categorias.filter((c) =>
    c.nome.toLowerCase().includes(busca.toLowerCase())
  );

  return (
    <div className="space-y-6">
      {/* Topo: Título e Botão Nova Categoria */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white tracking-tight flex items-center gap-2.5">
            <Layers className="w-6 h-6 text-[#8C63FF]" />
            Categorias do Cardápio
          </h2>
          <p className="text-xs text-[#9CAABC] mt-0.5">
            Organize os grupos de produtos (Pizzas, Lanches, Bebidas, etc.)
          </p>
        </div>

        <button
          onClick={abrirModalNovo}
          className="flex items-center gap-2 px-4 py-2.5 bg-gradient-to-r from-[#8C63FF] to-[#7847eb] hover:from-[#7847eb] hover:to-[#6366F1] text-white rounded-xl text-xs font-bold shadow-lg shadow-[#8C63FF]/25 transition-all cursor-pointer"
        >
          <Plus className="w-4 h-4" />
          <span>Nova Categoria</span>
        </button>
      </div>

      {/* Barra de Busca */}
      <div className="relative max-w-md">
        <input
          type="text"
          value={busca}
          onChange={(e) => setBusca(e.target.value)}
          placeholder="Buscar categoria..."
          className="w-full bg-[#152439] border border-[#2A405B] focus:border-[#8C63FF] text-white rounded-xl px-4 py-2.5 pl-10 text-xs focus:outline-none transition-colors"
        />
        <Search className="w-4 h-4 text-[#64748B] absolute left-3.5 top-1/2 -translate-y-1/2" />
      </div>

      {/* Tabela de Categorias */}
      <div className="bg-[#152439] border border-[#2A405B] rounded-2xl overflow-hidden shadow-xl">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="border-b border-[#2A405B] bg-[#0f1b2b] text-[#9CAABC] uppercase font-bold text-[10px] tracking-wider">
                <th className="py-3 px-4">Ordem</th>
                <th className="py-3 px-4">Nome da Categoria</th>
                <th className="py-3 px-4">Sabores Múltiplos</th>
                <th className="py-3 px-4">Status</th>
                <th className="py-3 px-4 text-right">Ações</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#2A405B]/60 text-white">
              {carregando ? (
                <tr>
                  <td colSpan={5} className="text-center py-8 text-[#9CAABC]">
                    <div className="w-6 h-6 border-2 border-[#8C63FF] border-t-transparent rounded-full animate-spin mx-auto mb-2" />
                    Carregando categorias...
                  </td>
                </tr>
              ) : categoriasFiltradas.length === 0 ? (
                <tr>
                  <td colSpan={5} className="text-center py-8 text-[#64748B]">
                    Nenhuma categoria encontrada
                  </td>
                </tr>
              ) : (
                categoriasFiltradas.map((cat) => (
                  <tr key={cat.id} className="hover:bg-[#1c2e47] transition-colors">
                    <td className="py-3 px-4 font-bold text-[#8C63FF]">
                      #{cat.ordem || cat.id}
                    </td>
                    <td className="py-3 px-4">
                      <p className="font-bold text-sm text-white">{cat.nome}</p>
                      {cat.descricao && (
                        <p className="text-[11px] text-[#9CAABC] truncate max-w-xs">{cat.descricao}</p>
                      )}
                    </td>
                    <td className="py-3 px-4">
                      {cat.permite_sabores ? (
                        <span className="px-2 py-0.5 rounded-md bg-[#8C63FF]/20 text-[#8C63FF] border border-[#8C63FF]/30 font-semibold text-[11px]">
                          Sim (Até {cat.max_sabores || 2} sabores)
                        </span>
                      ) : (
                        <span className="text-[#64748B]">Não</span>
                      )}
                    </td>
                    <td className="py-3 px-4">
                      <button
                        onClick={() => alternarStatus(cat)}
                        className={`px-2.5 py-1 rounded-full text-[11px] font-bold border transition-colors ${
                          cat.ativo
                            ? 'bg-[#10B981]/20 text-[#10B981] border-[#10B981]/30 hover:bg-[#10B981]/30'
                            : 'bg-[#64748B]/20 text-[#64748B] border-[#64748B]/30 hover:bg-[#64748B]/30'
                        }`}
                      >
                        {cat.ativo ? 'Ativo' : 'Inativo'}
                      </button>
                    </td>
                    <td className="py-3 px-4 text-right">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => abrirModalEditar(cat)}
                          className="p-1.5 text-[#9CAABC] hover:text-[#8C63FF] hover:bg-[#8C63FF]/10 rounded-lg transition-colors"
                          title="Editar Categoria"
                        >
                          <Edit2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal de Criação / Edição */}
      {modalAberto && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-[#152439] border border-[#2A405B] rounded-2xl w-full max-w-lg overflow-hidden shadow-2xl">
            {/* Header Modal */}
            <div className="p-4 md:p-5 border-b border-[#2A405B] flex items-center justify-between bg-[#121f30]">
              <h3 className="font-bold text-base text-white">
                {editandoId ? 'Editar Categoria' : 'Nova Categoria'}
              </h3>
              <button
                onClick={() => setModalAberto(false)}
                className="p-1 text-[#9CAABC] hover:text-white rounded-lg transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Form */}
            <form onSubmit={salvarCategoria} className="p-4 md:p-6 space-y-4">
              {erro && (
                <div className="p-3 bg-[#EF4444]/10 border border-[#EF4444]/30 rounded-xl text-[#EF4444] text-xs flex items-center gap-2">
                  <AlertCircle className="w-4 h-4 shrink-0" />
                  <span>{erro}</span>
                </div>
              )}

              <div>
                <label className="block text-xs font-semibold text-[#9CAABC] uppercase tracking-wider mb-1.5">
                  Nome da Categoria *
                </label>
                <input
                  ref={inputNomeRef}
                  type="text"
                  required
                  value={nome}
                  onChange={(e) => setNome(e.target.value)}
                  placeholder="Ex: Pizzas Tradicionais, Bebidas, Lanches"
                  className="w-full bg-[#0B132B] border border-[#2A405B] focus:border-[#8C63FF] text-white rounded-xl px-4 py-2.5 text-xs focus:outline-none transition-colors"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-[#9CAABC] uppercase tracking-wider mb-1.5">
                  Descrição (Opcional)
                </label>
                <textarea
                  value={descricao}
                  onChange={(e) => setDescricao(e.target.value)}
                  rows={2}
                  placeholder="Breve descrição que aparece no cardápio"
                  className="w-full bg-[#0B132B] border border-[#2A405B] focus:border-[#8C63FF] text-white rounded-xl px-4 py-2 text-xs focus:outline-none transition-colors"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-[#9CAABC] uppercase tracking-wider mb-1.5">
                    Ordem de Exibição
                  </label>
                  <input
                    type="number"
                    value={ordem}
                    onChange={(e) => setOrdem(Number(e.target.value))}
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
                    <span className="text-xs font-semibold text-white">Categoria Ativa</span>
                  </label>
                </div>
              </div>

              {/* Seção de Sabores */}
              <div className="p-3 bg-[#0B132B] border border-[#2A405B] rounded-xl space-y-3">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={permiteSabores}
                    onChange={(e) => setPermiteSabores(e.target.checked)}
                    className="w-4 h-4 accent-[#8C63FF] rounded cursor-pointer"
                  />
                  <span className="text-xs font-bold text-white">Permitir divisão em múltiplos sabores (Pizzas/Pastéis)</span>
                </label>

                {permiteSabores && (
                  <div className="pt-2 pl-6">
                    <label className="block text-[11px] font-semibold text-[#9CAABC] mb-1">
                      Limite Máximo de Sabores (ex: 2 para 1/2 e 1/2, 4 para 4 sabores)
                    </label>
                    <input
                      type="number"
                      min={2}
                      max={6}
                      value={maxSabores}
                      onChange={(e) => setMaxSabores(Number(e.target.value))}
                      className="w-24 bg-[#152439] border border-[#2A405B] text-white rounded-lg px-3 py-1.5 text-xs focus:outline-none focus:border-[#8C63FF]"
                    />
                  </div>
                )}
              </div>

              {/* Footer Form */}
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
                  {salvando ? 'Salvando...' : 'Salvar Categoria'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
