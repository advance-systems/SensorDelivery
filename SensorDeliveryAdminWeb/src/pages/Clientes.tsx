import React, { useState, useEffect } from 'react';
import { api } from '../api/client';
import { Users, Phone, MapPin, Search, Calendar, DollarSign, ShoppingBag } from 'lucide-react';

interface Cliente {
  id: number;
  nome: string;
  telefone: string;
  email?: string;
  total_pedidos?: number;
  total_gasto?: number;
  ultimo_pedido?: string;
  endereco_padrao?: string;
}

export const Clientes: React.FC = () => {
  const [clientes, setClientes] = useState<Cliente[]>([]);
  const [carregando, setCarregando] = useState(true);
  const [busca, setBusca] = useState('');

  const carregarClientes = async () => {
    try {
      setCarregando(true);
      const res = await api.get('/clientes');
      setClientes(Array.isArray(res.data) ? res.data : res.data?.clientes || []);
    } catch (err) {
      console.error('Erro ao carregar clientes:', err);
    } finally {
      setCarregando(false);
    }
  };

  useEffect(() => {
    carregarClientes();
  }, []);

  const formatarMoeda = (valor: number) => {
    return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(valor || 0);
  };

  const clientesFiltrados = clientes.filter((c) =>
    c.nome.toLowerCase().includes(busca.toLowerCase()) ||
    c.telefone.includes(busca)
  );

  return (
    <div className="space-y-6">
      {/* Topo */}
      <div>
        <h2 className="text-2xl font-bold text-white tracking-tight flex items-center gap-2.5">
          <Users className="w-6 h-6 text-[#8C63FF]" />
          Base de Clientes
        </h2>
        <p className="text-xs text-[#9CAABC] mt-0.5">
          Consulte o histórico de pedidos, contatos e fidelidade dos seus clientes
        </p>
      </div>

      {/* Busca */}
      <div className="relative max-w-md">
        <input
          type="text"
          value={busca}
          onChange={(e) => setBusca(e.target.value)}
          placeholder="Buscar cliente por nome ou telefone..."
          className="w-full bg-[#152439] border border-[#2A405B] focus:border-[#8C63FF] text-white rounded-xl px-4 py-2.5 pl-10 text-xs focus:outline-none transition-colors"
        />
        <Search className="w-4 h-4 text-[#64748B] absolute left-3.5 top-1/2 -translate-y-1/2" />
      </div>

      {/* Tabela de Clientes */}
      <div className="bg-[#152439] border border-[#2A405B] rounded-2xl overflow-hidden shadow-xl">
        <table className="w-full text-left border-collapse text-xs">
          <thead>
            <tr className="border-b border-[#2A405B] bg-[#0f1b2b] text-[#9CAABC] uppercase font-bold text-[10px] tracking-wider">
              <th className="py-3 px-4">Nome do Cliente</th>
              <th className="py-3 px-4">Telefone / WhatsApp</th>
              <th className="py-3 px-4">Total de Pedidos</th>
              <th className="py-3 px-4">Total Gasto (R$)</th>
              <th className="py-3 px-4 text-right">Último Pedido</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[#2A405B]/60 text-white">
            {carregando ? (
              <tr>
                <td colSpan={5} className="text-center py-8 text-[#9CAABC]">
                  Carregando lista de clientes...
                </td>
              </tr>
            ) : clientesFiltrados.length === 0 ? (
              <tr>
                <td colSpan={5} className="text-center py-8 text-[#64748B]">
                  Nenhum cliente encontrado
                </td>
              </tr>
            ) : (
              clientesFiltrados.map((cli) => (
                <tr key={cli.id} className="hover:bg-[#1c2e47] transition-colors">
                  <td className="py-3 px-4">
                    <p className="font-bold text-sm text-white">{cli.nome}</p>
                    {cli.email && <p className="text-[11px] text-[#9CAABC]">{cli.email}</p>}
                  </td>
                  <td className="py-3 px-4 text-[#9CAABC] font-medium">
                    <div className="flex items-center gap-1.5">
                      <Phone className="w-3.5 h-3.5 text-[#8C63FF]" />
                      <span>{cli.telefone || 'Sem telefone'}</span>
                    </div>
                  </td>
                  <td className="py-3 px-4">
                    <span className="px-2 py-0.5 rounded-md bg-[#8C63FF]/20 text-[#8C63FF] border border-[#8C63FF]/30 font-bold text-[11px]">
                      {cli.total_pedidos || 0} pedidos
                    </span>
                  </td>
                  <td className="py-3 px-4 font-bold text-[#10B981]">
                    {formatarMoeda(cli.total_gasto || 0)}
                  </td>
                  <td className="py-3 px-4 text-right text-[#9CAABC]">
                    {cli.ultimo_pedido ? new Date(cli.ultimo_pedido).toLocaleDateString('pt-BR') : 'Sem histórico'}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};
