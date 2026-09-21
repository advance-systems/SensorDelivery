import React, { useState, useEffect } from 'react';
import { api } from '../api/client';
import {
  BarChart3,
  DollarSign,
  ShoppingBag,
  Clock,
  Bike,
  TrendingUp,
  CreditCard,
  QrCode,
  Banknote,
  CheckCircle2,
  RefreshCw,
  Calendar,
} from 'lucide-react';

interface ResumoDashboard {
  pedidosHoje: number;
  faturamentoHoje: number;
  emPreparo: number;
  emEntrega: number;
}

interface PedidoRecente {
  id: string;
  numero: number;
  cliente_nome: string;
  valor_total: number;
  forma_pagamento: string;
  status: string;
  criado_em: string;
}

export const Dashboard: React.FC = () => {
  const [resumo, setResumo] = useState<ResumoDashboard>({
    pedidosHoje: 0,
    faturamentoHoje: 0,
    emPreparo: 0,
    emEntrega: 0,
  });
  const [pedidosRecentes, setPedidosRecentes] = useState<PedidoRecente[]>([]);
  const [carregando, setCarregando] = useState(true);

  const carregarDashboard = async () => {
    try {
      setCarregando(true);
      const [resResumo, resPedidos] = await Promise.all([
        api.get('/dashboard/resumo').catch(() => ({ data: null })),
        api.get('/pedidos').catch(() => ({ data: { pedidos: [] } })),
      ]);

      if (resResumo.data) {
        setResumo(resResumo.data);
      }

      const lista = resPedidos.data?.pedidos || (Array.isArray(resPedidos.data) ? resPedidos.data : []);
      setPedidosRecentes(lista.slice(0, 8));
    } catch (err) {
      console.error('Erro ao carregar dados do dashboard:', err);
    } finally {
      setCarregando(false);
    }
  };

  useEffect(() => {
    carregarDashboard();
    const interval = setInterval(carregarDashboard, 30000);
    return () => clearInterval(interval);
  }, []);

  const formatarMoeda = (valor: number) => {
    return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(valor || 0);
  };

  const ticketMedio = resumo.pedidosHoje > 0 ? resumo.faturamentoHoje / resumo.pedidosHoje : 0;

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'ENTREGUE':
        return { label: 'Entregue', bg: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' };
      case 'EM_PREPARO':
        return { label: 'Em Preparo', bg: 'bg-amber-500/10 text-amber-400 border-amber-500/20' };
      case 'SAIU_PARA_ENTREGA':
        return { label: 'Em Entrega', bg: 'bg-indigo-500/10 text-indigo-400 border-indigo-500/20' };
      case 'CANCELADO':
        return { label: 'Cancelado', bg: 'bg-red-500/10 text-red-400 border-red-500/20' };
      default:
        return { label: status, bg: 'bg-slate-700/40 text-slate-300 border-slate-600' };
    }
  };

  const getFormaPagamentoBadge = (forma: string) => {
    const f = forma?.toUpperCase() || '';
    if (f.includes('PIX')) {
      return (
        <span className="inline-flex items-center gap-1 text-xs text-emerald-400 font-medium">
          <QrCode className="w-3.5 h-3.5" /> PIX
        </span>
      );
    }
    if (f.includes('CARTAO') || f.includes('CREDITO') || f.includes('DEBITO')) {
      return (
        <span className="inline-flex items-center gap-1 text-xs text-indigo-400 font-medium">
          <CreditCard className="w-3.5 h-3.5" /> Cartão
        </span>
      );
    }
    return (
      <span className="inline-flex items-center gap-1 text-xs text-amber-400 font-medium">
        <Banknote className="w-3.5 h-3.5" /> Dinheiro
      </span>
    );
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white flex items-center gap-2">
            <BarChart3 className="w-7 h-7 text-indigo-400" />
            Dashboard & Vendas
          </h1>
          <p className="text-sm text-slate-400">
            Acompanhe em tempo real o desempenho de vendas, faturamento e fluxo de pedidos
          </p>
        </div>
        <button
          onClick={carregarDashboard}
          disabled={carregando}
          className="inline-flex items-center justify-center gap-2 px-4 py-2.5 bg-[#152439] hover:bg-[#1e324d] text-slate-300 font-medium rounded-xl border border-[#2A405B] transition-colors"
        >
          <RefreshCw className={`w-4 h-4 ${carregando ? 'animate-spin text-indigo-400' : ''}`} />
          Atualizar Dados
        </button>
      </div>

      {/* Cards de Métricas Principais */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        {/* Faturamento Hoje */}
        <div className="bg-[#152439] p-5 rounded-2xl border border-[#2A405B] shadow-xl relative overflow-hidden group">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
              Faturamento Hoje
            </span>
            <div className="w-10 h-10 rounded-xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center text-emerald-400">
              <DollarSign className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl font-black text-white">
              {formatarMoeda(resumo.faturamentoHoje)}
            </div>
            <div className="flex items-center gap-1.5 mt-1.5 text-xs text-emerald-400">
              <TrendingUp className="w-3.5 h-3.5" />
              <span>Receita líquida confirmada</span>
            </div>
          </div>
        </div>

        {/* Total de Pedidos Hoje */}
        <div className="bg-[#152439] p-5 rounded-2xl border border-[#2A405B] shadow-xl relative overflow-hidden group">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
              Pedidos Hoje
            </span>
            <div className="w-10 h-10 rounded-xl bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-indigo-400">
              <ShoppingBag className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl font-black text-white">
              {resumo.pedidosHoje} {resumo.pedidosHoje === 1 ? 'pedido' : 'pedidos'}
            </div>
            <div className="mt-1.5 text-xs text-slate-400">
              Ticket médio: <strong className="text-indigo-300">{formatarMoeda(ticketMedio)}</strong>
            </div>
          </div>
        </div>

        {/* Em Preparo */}
        <div className="bg-[#152439] p-5 rounded-2xl border border-[#2A405B] shadow-xl relative overflow-hidden group">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
              Na Cozinha
            </span>
            <div className="w-10 h-10 rounded-xl bg-amber-500/10 border border-amber-500/20 flex items-center justify-center text-amber-400">
              <Clock className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl font-black text-white">
              {resumo.emPreparo}
            </div>
            <div className="mt-1.5 text-xs text-amber-400">
              {resumo.emPreparo === 1 ? 'Pedido em preparo' : 'Pedidos em preparo'}
            </div>
          </div>
        </div>

        {/* Em Entrega */}
        <div className="bg-[#152439] p-5 rounded-2xl border border-[#2A405B] shadow-xl relative overflow-hidden group">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
              Em Entrega
            </span>
            <div className="w-10 h-10 rounded-xl bg-blue-500/10 border border-blue-500/20 flex items-center justify-center text-blue-400">
              <Bike className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl font-black text-white">
              {resumo.emEntrega}
            </div>
            <div className="mt-1.5 text-xs text-blue-400">
              {resumo.emEntrega === 1 ? 'Entregador em trânsito' : 'Entregadores em trânsito'}
            </div>
          </div>
        </div>
      </div>

      {/* Tabela de Vendas e Pedidos Recentes */}
      <div className="bg-[#152439] rounded-2xl border border-[#2A405B] overflow-hidden shadow-xl">
        <div className="px-6 py-4 border-b border-[#2A405B] flex items-center justify-between bg-[#0B132B]/50">
          <h2 className="text-base font-bold text-white flex items-center gap-2">
            <Calendar className="w-4 h-4 text-indigo-400" />
            Últimas Vendas Realizadas
          </h2>
          <span className="text-xs text-slate-400">Atualizado automaticamente</span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-slate-300">
            <thead className="bg-[#0B132B]/80 text-xs uppercase text-slate-400 font-semibold border-b border-[#2A405B]">
              <tr>
                <th className="px-6 py-4">Pedido</th>
                <th className="px-6 py-4">Cliente</th>
                <th className="px-6 py-4">Data / Hora</th>
                <th className="px-6 py-4">Pagamento</th>
                <th className="px-6 py-4">Valor Total</th>
                <th className="px-6 py-4">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#2A405B]">
              {carregando && pedidosRecentes.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-slate-400">
                    <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-500"></div>
                    <p className="mt-2">Carregando dados de vendas...</p>
                  </td>
                </tr>
              ) : pedidosRecentes.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-slate-400">
                    <ShoppingBag className="w-12 h-12 mx-auto text-slate-600 mb-2" />
                    <p className="text-base font-medium text-slate-300">Nenhum pedido registrado hoje</p>
                    <p className="text-xs text-slate-500 mt-1">
                      Os novos pedidos recebidos aparecerão aqui automaticamente.
                    </p>
                  </td>
                </tr>
              ) : (
                pedidosRecentes.map((ped) => {
                  const badge = getStatusBadge(ped.status);
                  return (
                    <tr key={ped.id} className="hover:bg-[#1e324d]/40 transition-colors">
                      <td className="px-6 py-4 font-bold text-white">
                        #{ped.numero}
                      </td>
                      <td className="px-6 py-4 text-slate-200">
                        {ped.cliente_nome || 'Cliente Balcão'}
                      </td>
                      <td className="px-6 py-4 text-xs text-slate-400">
                        {new Date(ped.criado_em).toLocaleTimeString('pt-BR', {
                          hour: '2-digit',
                          minute: '2-digit',
                        })}
                      </td>
                      <td className="px-6 py-4">
                        {getFormaPagamentoBadge(ped.forma_pagamento)}
                      </td>
                      <td className="px-6 py-4 font-semibold text-emerald-400">
                        {formatarMoeda(Number(ped.valor_total || 0))}
                      </td>
                      <td className="px-6 py-4">
                        <span className={`inline-block px-2.5 py-0.5 rounded-full text-xs font-semibold border ${badge.bg}`}>
                          {badge.label}
                        </span>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
