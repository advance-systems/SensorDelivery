import React, { useState, useEffect } from 'react';
import { api } from '../api/client';
import { Sparkles, Plus, Edit2, Search, AlertCircle, X, Check } from 'lucide-react';

interface Sabor {
  id: number;
  nome: string;
  descricao?: string;
  categoria_id: number;
  categoria_nome?: string;
  ativo: boolean;
  preco_adicional?: number;
}

interface Borda {
  id: number;
  nome: string;
  preco: number;
  ativo: boolean;
}

export const SaboresBordas: React.FC = () => {
  const [abaAtiva, setAbaAtiva] = useState<'sabores' | 'bordas'>('sabores');
  const [sabores, setSabores] = useState<Sabor[]>([]);
  const [bordas, setBordas] = useState<Borda[]>([]);
  const [carregando, setCarregando] = useState(true);
  const [busca, setBusca] = useState('');

  // Modal Sabores
  const [modalSaborAberto, setModalSaborAberto] = useState(false);
  const [saborEditando, setSaborEditando] = useState<Sabor | null>(null);
  const [saborNome, setSaborNome] = useState('');
  const [saborDescricao, setSaborDescricao] = useState('');
  const [saborPreco, setSaborPreco] = useState('');
  const [saborAtivo, setSaborAtivo] = useState(true);

  // Modal Bordas
  const [modalBordaAberto, setModalBordaAberto] = useState(false);
  const [bordaEditando, setBordaEditando] = useState<Borda | null>(null);
  const [bordaNome, setBordaNome] = useState('');
  const [bordaPreco, setBordaPreco] = useState('');
  const [bordaAtivo, setBordaAtivo] = useState(true);

  const carregarDados = async () => {
    try {
      setCarregando(true);
      const resSabores = await api.get('/sabores');
      setSabores(Array.isArray(resSabores.data) ? resSabores.data : resSabores.data?.sabores || []);
    } catch (err) {
      console.error('Erro ao carregar sabores/bordas:', err);
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

  const abrirModalNovoSabor = () => {
    setSaborEditando(null);
    setSaborNome('');
    setSaborDescricao('');
    setSaborPreco('');
    setSaborAtivo(true);
    setModalSaborAberto(true);
  };

  const salvarSabor = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const payload = {
        nome: saborNome,
        descricao: saborDescricao,
        preco_adicional: Number(saborPreco.replace(',', '.')) || 0,
        ativo: saborAtivo,
      };

      if (saborEditando) {
        await api.put(`/sabores/${saborEditando.id}`, payload);
      } else {
        await api.post('/sabores', payload);
      }

      setModalSaborAberto(false);
      carregarDados();
    } catch (err) {
      alert('Falha ao salvar sabor.');
    }
  };

  return (
    <div className="space-y-6">
      {/* Topo */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white tracking-tight flex items-center gap-2.5">
            <Sparkles className="w-6 h-6 text-[#8C63FF]" />
            Sabores & Bordas Recheadas
          </h2>
          <p className="text-xs text-[#9CAABC] mt-0.5">
            Gerencie opções para produtos com sabores múltiplos (Pizzas, Pastéis) e bordas
          </p>
        </div>

        <div className="flex items-center gap-2">
          {abaAtiva === 'sabores' ? (
            <button
              onClick={abrirModalNovoSabor}
              className="flex items-center gap-2 px-4 py-2.5 bg-gradient-to-r from-[#8C63FF] to-[#7847eb] text-white rounded-xl text-xs font-bold shadow-md shadow-[#8C63FF]/20 cursor-pointer"
            >
              <Plus className="w-4 h-4" />
              <span>Novo Sabor</span>
            </button>
          ) : (
            <button
              onClick={() => {
                setBordaEditando(null);
                setBordaNome('');
                setBordaPreco('');
                setBordaAtivo(true);
                setModalBordaAberto(true);
              }}
              className="flex items-center gap-2 px-4 py-2.5 bg-gradient-to-r from-[#8C63FF] to-[#7847eb] text-white rounded-xl text-xs font-bold shadow-md shadow-[#8C63FF]/20 cursor-pointer"
            >
              <Plus className="w-4 h-4" />
              <span>Nova Borda</span>
            </button>
          )}
        </div>
      </div>

      {/* Navegação de Abas */}
      <div className="flex items-center gap-2 border-b border-[#2A405B] pb-2">
        <button
          onClick={() => setAbaAtiva('sabores')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-colors ${
            abaAtiva === 'sabores'
              ? 'bg-[#8C63FF] text-white shadow-md shadow-[#8C63FF]/20'
              : 'text-[#9CAABC] hover:text-white hover:bg-[#152439]'
          }`}
        >
          Sabores de Pizzas / Pastéis ({sabores.length})
        </button>
        <button
          onClick={() => setAbaAtiva('bordas')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-colors ${
            abaAtiva === 'bordas'
              ? 'bg-[#8C63FF] text-white shadow-md shadow-[#8C63FF]/20'
              : 'text-[#9CAABC] hover:text-white hover:bg-[#152439]'
          }`}
        >
          Bordas Recheadas
        </button>
      </div>

      {/* Conteúdo Aba Sabores */}
      {abaAtiva === 'sabores' && (
        <div className="bg-[#152439] border border-[#2A405B] rounded-2xl overflow-hidden shadow-xl">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="border-b border-[#2A405B] bg-[#0f1b2b] text-[#9CAABC] uppercase font-bold text-[10px] tracking-wider">
                <th className="py-3 px-4">Nome do Sabor</th>
                <th className="py-3 px-4">Ingredientes / Descrição</th>
                <th className="py-3 px-4">Adicional (R$)</th>
                <th className="py-3 px-4">Status</th>
                <th className="py-3 px-4 text-right">Ações</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#2A405B]/60 text-white">
              {carregando ? (
                <tr>
                  <td colSpan={5} className="text-center py-8 text-[#9CAABC]">
                    Carregando sabores...
                  </td>
                </tr>
              ) : sabores.length === 0 ? (
                <tr>
                  <td colSpan={5} className="text-center py-8 text-[#64748B]">
                    Nenhum sabor cadastrado
                  </td>
                </tr>
              ) : (
                sabores.map((sabor) => (
                  <tr key={sabor.id} className="hover:bg-[#1c2e47] transition-colors">
                    <td className="py-3 px-4 font-bold text-sm text-white">
                      {sabor.nome}
                    </td>
                    <td className="py-3 px-4 text-[#9CAABC] max-w-sm truncate">
                      {sabor.descricao || 'Sem descrição cadastrada'}
                    </td>
                    <td className="py-3 px-4 font-bold text-[#10B981]">
                      {sabor.preco_adicional ? formatarMoeda(sabor.preco_adicional) : 'Incluso'}
                    </td>
                    <td className="py-3 px-4">
                      <span className={`px-2 py-0.5 rounded-md text-[10px] font-bold border ${
                        sabor.ativo
                          ? 'bg-[#10B981]/20 text-[#10B981] border-[#10B981]/30'
                          : 'bg-[#64748B]/20 text-[#64748B] border-[#64748B]/30'
                      }`}>
                        {sabor.ativo ? 'Ativo' : 'Inativo'}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-right">
                      <button
                        onClick={() => {
                          setSaborEditando(sabor);
                          setSaborNome(sabor.nome);
                          setSaborDescricao(sabor.descricao || '');
                          setSaborPreco(sabor.preco_adicional ? String(sabor.preco_adicional) : '');
                          setSaborAtivo(sabor.ativo);
                          setModalSaborAberto(true);
                        }}
                        className="p-1.5 text-[#9CAABC] hover:text-[#8C63FF] hover:bg-[#8C63FF]/10 rounded-lg transition-colors"
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
      )}

      {/* Modal Sabor */}
      {modalSaborAberto && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-[#152439] border border-[#2A405B] rounded-2xl w-full max-w-md overflow-hidden shadow-2xl">
            <div className="p-4 border-b border-[#2A405B] flex items-center justify-between bg-[#121f30]">
              <h3 className="font-bold text-sm text-white">
                {saborEditando ? 'Editar Sabor' : 'Novo Sabor'}
              </h3>
              <button onClick={() => setModalSaborAberto(false)} className="text-[#9CAABC] hover:text-white">
                <X className="w-5 h-5" />
              </button>
            </div>
            <form onSubmit={salvarSabor} className="p-4 space-y-3">
              <div>
                <label className="block text-xs font-semibold text-[#9CAABC] uppercase mb-1">Nome *</label>
                <input
                  type="text"
                  required
                  value={saborNome}
                  onChange={(e) => setSaborNome(e.target.value)}
                  placeholder="Ex: Frango com Catupiry, 4 Queijos"
                  className="w-full bg-[#0B132B] border border-[#2A405B] text-white rounded-xl px-3 py-2 text-xs focus:outline-none focus:border-[#8C63FF]"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-[#9CAABC] uppercase mb-1">Ingredientes</label>
                <textarea
                  value={saborDescricao}
                  onChange={(e) => setSaborDescricao(e.target.value)}
                  rows={2}
                  placeholder="Molho de tomate especial, mussarela, frango desfiado e catupiry original"
                  className="w-full bg-[#0B132B] border border-[#2A405B] text-white rounded-xl px-3 py-2 text-xs focus:outline-none focus:border-[#8C63FF]"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-[#9CAABC] uppercase mb-1">Preço Adicional (R$)</label>
                  <input
                    type="text"
                    value={saborPreco}
                    onChange={(e) => setSaborPreco(e.target.value)}
                    onFocus={(e) => e.target.select()}
                    onBlur={() => {
                      if (!saborPreco.trim()) setSaborPreco('0,00');
                    }}
                    placeholder="0,00"
                    className="w-full bg-[#0B132B] border border-[#2A405B] text-white rounded-xl px-3 py-2 text-xs focus:outline-none focus:border-[#8C63FF]"
                  />
                </div>
                <div className="flex items-center pt-5">
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={saborAtivo}
                      onChange={(e) => setSaborAtivo(e.target.checked)}
                      className="w-4 h-4 accent-[#8C63FF] rounded"
                    />
                    <span className="text-xs font-semibold text-white">Sabor Ativo</span>
                  </label>
                </div>
              </div>

              <div className="pt-3 flex items-center justify-end gap-2 border-t border-[#2A405B]">
                <button
                  type="button"
                  onClick={() => setModalSaborAberto(false)}
                  className="px-3 py-2 text-xs font-semibold text-[#9CAABC] hover:text-white"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-[#8C63FF] hover:bg-[#7847eb] text-white text-xs font-bold rounded-xl shadow-md"
                >
                  Salvar
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
