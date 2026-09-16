import React, { useState, useEffect, useRef } from 'react';
import { api } from '../api/client';
import { 
  ShoppingBag, 
  Clock, 
  CheckCircle2, 
  Truck, 
  XCircle, 
  AlertTriangle, 
  Printer, 
  Eye, 
  Phone, 
  MapPin, 
  DollarSign, 
  ChevronRight,
  Filter,
  Search,
  RefreshCw,
  X
} from 'lucide-react';

export interface PedidoItem {
  id: number | string;
  produto_nome: string;
  quantidade: number;
  preco_unitario: number;
  preco_total: number;
  observacoes?: string;
  sabores?: Array<{ sabor_nome: string; fracao?: string }>;
  adicionais?: Array<{ adicional_nome: string; quantidade: number; valor_unitario: number }>;
  borda_nome?: string;
}

export interface Pedido {
  id: string | number;
  numero_pedido?: string;
  cliente_nome: string;
  cliente_telefone: string;
  tipo_entrega: 'entrega' | 'retirada' | 'mesa';
  status: 'novo' | 'em_preparo' | 'saiu_entrega' | 'entregue' | 'cancelado';
  forma_pagamento: string;
  subtotal: number;
  taxa_entrega: number;
  desconto: number;
  total: number;
  troco_para?: number;
  endereco_rua?: string;
  endereco_numero?: string;
  endereco_bairro?: string;
  endereco_complemento?: string;
  itens_resumo?: string;
  criado_em: string;
  itens?: PedidoItem[];
}

function formatarFormaPagamento(forma?: string, trocoPara?: number): string {
  if (!forma) return 'PIX';
  const f = String(forma).toUpperCase();
  if (f === 'DINHEIRO') {
    if (trocoPara && trocoPara > 0) {
      return `Dinheiro (Troco p/ ${new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(trocoPara)})`;
    }
    return 'Dinheiro';
  }
  if (f === 'CARTAO_CREDITO' || f.includes('CREDITO')) return 'Cartão Crédito';
  if (f === 'CARTAO_DEBITO' || f.includes('DEBITO')) return 'Cartão Débito';
  if (f === 'ONLINE') return 'Online';
  return forma;
}

function normalizarStatus(statusDb?: string): Pedido['status'] {
  const s = String(statusDb || '').toUpperCase();
  if (['RASCUNHO', 'AGUARDANDO_CONFIRMACAO', 'CONFIRMADO', 'NOVO'].includes(s)) return 'novo';
  if (['EM_PREPARO', 'PRONTO'].includes(s)) return 'em_preparo';
  if (['SAIU_PARA_ENTREGA', 'EM_ENTREGA', 'SAIU_ENTREGA'].includes(s)) return 'saiu_entrega';
  if (['ENTREGUE', 'FINALIZADO'].includes(s)) return 'entregue';
  if (['CANCELADO'].includes(s)) return 'cancelado';
  return 'novo';
}

function normalizarPedido(raw: any): Pedido {
  return {
    id: raw.id,
    numero_pedido: String(raw.numero || raw.numero_pedido || raw.id),
    cliente_nome: raw.cliente_nome || 'Cliente',
    cliente_telefone: raw.cliente_telefone || '',
    tipo_entrega: String(raw.tipo_atendimento || raw.tipo_entrega || 'entrega').toLowerCase().includes('retirada') ? 'retirada' : 'entrega',
    status: normalizarStatus(raw.status),
    forma_pagamento: raw.forma_pagamento || raw.forma || 'PIX',
    subtotal: Number(raw.subtotal || raw.valor_total || 0),
    taxa_entrega: Number(raw.taxa_entrega || 0),
    desconto: Number(raw.desconto || 0),
    total: Number(raw.valor_total || raw.total || 0),
    troco_para: raw.troco_para ? Number(raw.troco_para) : (raw.dados?.troco_para ? Number(raw.dados.troco_para) : undefined),
    endereco_rua: raw.endereco_texto || raw.endereco_rua || '',
    endereco_numero: raw.endereco_numero || '',
    endereco_bairro: raw.endereco_bairro || '',
    endereco_complemento: raw.endereco_complemento || '',
    itens_resumo: raw.itens_resumo || '',
    criado_em: raw.criado_em || new Date().toISOString(),
    itens: raw.itens?.map((it: any) => ({
      id: it.id,
      produto_nome: it.produto_nome || it.produto_descricao || 'Produto',
      quantidade: Number(it.quantidade || 1),
      preco_unitario: Number(it.valor_unitario || it.preco_unitario || 0),
      preco_total: Number(it.valor_total || it.preco_total || 0),
      observacoes: it.observacoes,
      sabores: it.sabores?.map((sb: any) => ({
        sabor_nome: sb.sabor_descricao || sb.descricao || sb.sabor_nome || '',
        fracao: sb.fracao || ''
      })),
      adicionais: it.adicionais?.map((ad: any) => ({
        adicional_nome: ad.adicional_nome || ad.descricao || '',
        quantidade: Number(ad.quantidade || 1),
        valor_unitario: Number(ad.valor_unitario || ad.valor || 0)
      })),
      borda_nome: it.borda_descricao || it.borda_nome || ''
    }))
  };
}

export const CentralPedidos: React.FC = () => {
  const [pedidos, setPedidos] = useState<Pedido[]>([]);
  const [carregando, setCarregando] = useState(true);
  const [filtroTexto, setFiltroTexto] = useState('');
  const [pedidoSelecionado, setPedidoSelecionado] = useState<Pedido | null>(null);
  const [modalDetalhesAberto, setModalDetalhesAberto] = useState(false);
  const [carregandoDetalhes, setCarregandoDetalhes] = useState(false);
  const [atualizandoStatus, setAtualizandoStatus] = useState<string | number | null>(null);

  const carregarPedidos = async () => {
    try {
      setCarregando(true);
      const response = await api.get('/pedidos');
      let listaRaw: any[] = [];
      if (Array.isArray(response.data)) {
        listaRaw = response.data;
      } else if (response.data?.pedidos && Array.isArray(response.data.pedidos)) {
        listaRaw = response.data.pedidos;
      }
      setPedidos(listaRaw.map(normalizarPedido));
    } catch (error) {
      console.error('Erro ao carregar pedidos:', error);
    } finally {
      setCarregando(false);
    }
  };

  useEffect(() => {
    carregarPedidos();
    const interval = setInterval(carregarPedidos, 10000); // Polling a cada 10s
    return () => clearInterval(interval);
  }, []);

  const abrirDetalhes = async (pedido: Pedido) => {
    setPedidoSelecionado(pedido);
    setModalDetalhesAberto(true);
    try {
      setCarregandoDetalhes(true);
      const res = await api.get(`/pedidos/${pedido.id}/detalhes`);
      if (res.data?.pedido) {
        setPedidoSelecionado(normalizarPedido(res.data.pedido));
      }
    } catch (error) {
      console.error('Erro ao carregar detalhes do pedido:', error);
    } finally {
      setCarregandoDetalhes(false);
    }
  };

  const alterarStatus = async (pedidoId: string | number, novoStatus: Pedido['status']) => {
    try {
      setAtualizandoStatus(pedidoId);
      await api.patch(`/pedidos/${pedidoId}/status`, { status: novoStatus });
      setPedidos((prev) =>
        prev.map((p) => (p.id === pedidoId ? { ...p, status: novoStatus } : p))
      );
      if (pedidoSelecionado && pedidoSelecionado.id === pedidoId) {
        setPedidoSelecionado({ ...pedidoSelecionado, status: novoStatus });
      }
    } catch (error) {
      console.error('Erro ao atualizar status:', error);
      alert('Não foi possível alterar o status do pedido.');
    } finally {
      setAtualizandoStatus(null);
    }
  };

  const colunas = [
    {
      id: 'novo',
      titulo: 'Novos / Pendentes',
      corBadge: 'bg-[#EF4444]/20 text-[#EF4444] border-[#EF4444]/30',
      icone: AlertTriangle,
      status: 'novo' as const,
      proximoStatus: 'em_preparo' as const,
      acaoTexto: 'Aceitar & Preparar',
    },
    {
      id: 'em_preparo',
      titulo: 'Em Preparo',
      corBadge: 'bg-[#F59E0B]/20 text-[#F59E0B] border-[#F59E0B]/30',
      icone: Clock,
      status: 'em_preparo' as const,
      proximoStatus: 'saiu_entrega' as const,
      acaoTexto: 'Despachar / Pronto',
    },
    {
      id: 'saiu_entrega',
      titulo: 'Saiu p/ Entrega',
      corBadge: 'bg-[#0EA5E9]/20 text-[#0EA5E9] border-[#0EA5E9]/30',
      icone: Truck,
      status: 'saiu_entrega' as const,
      proximoStatus: 'entregue' as const,
      acaoTexto: 'Concluir Entrega',
    },
    {
      id: 'entregue',
      titulo: 'Concluídos',
      corBadge: 'bg-[#10B981]/20 text-[#10B981] border-[#10B981]/30',
      icone: CheckCircle2,
      status: 'entregue' as const,
      proximoStatus: null,
      acaoTexto: null,
    },
  ];

  const pedidosFiltrados = pedidos.filter((p) => {
    if (!filtroTexto) return true;
    const busca = filtroTexto.toLowerCase();
    return (
      (p.numero_pedido && p.numero_pedido.toLowerCase().includes(busca)) ||
      p.id.toString().toLowerCase().includes(busca) ||
      p.cliente_nome?.toLowerCase().includes(busca) ||
      p.cliente_telefone?.includes(busca) ||
      p.endereco_bairro?.toLowerCase().includes(busca) ||
      p.endereco_rua?.toLowerCase().includes(busca)
    );
  });

  const formatarMoeda = (valor: number) => {
    return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(valor || 0);
  };

  const formatarHora = (dataIso: string) => {
    try {
      const d = new Date(dataIso);
      return d.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
    } catch {
      return '--:--';
    }
  };

  return (
    <div className="space-y-6">
      {/* Topo: Título e Controles */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white tracking-tight flex items-center gap-2.5">
            <ShoppingBag className="w-6 h-6 text-[#8C63FF]" />
            Central de Pedidos
          </h2>
          <p className="text-xs text-[#9CAABC] mt-0.5">
            Acompanhe o fluxo da cozinha e entregas em tempo real
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="relative flex-1 md:w-72">
            <input
              type="text"
              value={filtroTexto}
              onChange={(e) => setFiltroTexto(e.target.value)}
              placeholder="Buscar por cliente, nº ou bairro..."
              className="w-full bg-[#152439] border border-[#2A405B] focus:border-[#8C63FF] text-white rounded-xl px-4 py-2 pl-10 text-xs focus:outline-none transition-colors"
            />
            <Search className="w-3.5 h-3.5 text-[#64748B] absolute left-3.5 top-1/2 -translate-y-1/2" />
          </div>

          <button
            onClick={carregarPedidos}
            className="flex items-center gap-2 px-3 py-2 bg-[#152439] hover:bg-[#1c2e47] border border-[#2A405B] text-xs font-semibold text-white rounded-xl transition-colors cursor-pointer"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${carregando ? 'animate-spin' : ''}`} />
            <span>Atualizar</span>
          </button>
        </div>
      </div>

      {/* Kanban Board */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5 items-start">
        {colunas.map((coluna) => {
          const pedidosColuna = pedidosFiltrados.filter((p) => p.status === coluna.status);
          const ColunaIcone = coluna.icone;

          return (
            <div
              key={coluna.id}
              className="bg-[#152439]/60 border border-[#2A405B] rounded-2xl flex flex-col max-h-[calc(100vh-180px)] overflow-hidden shadow-lg"
            >
              {/* Header da Coluna */}
              <div className="p-4 border-b border-[#2A405B] bg-[#152439] flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <ColunaIcone className="w-4 h-4 text-[#8C63FF]" />
                  <h3 className="font-bold text-sm text-white">{coluna.titulo}</h3>
                </div>
                <span className={`px-2 py-0.5 text-xs font-bold rounded-full border ${coluna.corBadge}`}>
                  {pedidosColuna.length}
                </span>
              </div>

              {/* Lista de Cards da Coluna */}
              <div className="p-3 overflow-y-auto space-y-3 flex-1">
                {pedidosColuna.length === 0 ? (
                  <div className="py-8 text-center text-xs text-[#64748B]">
                    Nenhum pedido nesta etapa
                  </div>
                ) : (
                  pedidosColuna.map((pedido) => (
                    <div
                      key={pedido.id}
                      className="bg-[#152439] hover:bg-[#1c2e47] border border-[#2A405B] rounded-xl p-3.5 transition-all shadow-md hover:border-[#8C63FF]/50 flex flex-col gap-3 group"
                    >
                      {/* Topo do Card */}
                      <div className="flex items-center justify-between">
                        <span className="font-extrabold text-sm text-white flex items-center gap-1.5">
                          #{pedido.numero_pedido || pedido.id}
                          <span className="text-[10px] font-medium text-[#9CAABC] bg-[#0B132B] px-1.5 py-0.5 rounded border border-[#2A405B]">
                            {pedido.tipo_entrega === 'entrega' ? 'Entrega' : 'Retirada'}
                          </span>
                        </span>
                        <span className="text-[11px] font-semibold text-[#9CAABC] flex items-center gap-1">
                          <Clock className="w-3 h-3" />
                          {formatarHora(pedido.criado_em)}
                        </span>
                      </div>

                      {/* Dados do Cliente & Endereço */}
                      <div>
                        <p className="font-bold text-xs text-white truncate">{pedido.cliente_nome}</p>
                        {pedido.tipo_entrega === 'entrega' && (pedido.endereco_bairro || pedido.endereco_rua) && (
                          <p className="text-[11px] text-[#9CAABC] flex items-center gap-1 truncate mt-0.5">
                            <MapPin className="w-3 h-3 text-[#64748B] shrink-0" />
                            {pedido.endereco_bairro ? `${pedido.endereco_bairro} ` : ''}
                            {pedido.endereco_rua ? `- ${pedido.endereco_rua}` : ''}
                          </p>
                        )}
                        {pedido.itens_resumo && (
                          <p className="text-[11px] text-[#8C63FF] line-clamp-2 mt-1 whitespace-pre-line bg-[#0B132B]/60 p-1.5 rounded border border-[#2A405B]/50">
                            {pedido.itens_resumo}
                          </p>
                        )}
                      </div>

                      {/* Total & Forma de Pagamento */}
                      <div className="flex items-center justify-between pt-2 border-t border-[#2A405B]/60 text-xs">
                        <span className="text-[11px] text-[#9CAABC] font-semibold bg-[#0B132B] px-2 py-0.5 rounded border border-[#2A405B]">
                          {formatarFormaPagamento(pedido.forma_pagamento, pedido.troco_para)}
                        </span>
                        <span className="font-extrabold text-sm text-[#10B981]">
                          {formatarMoeda(pedido.total)}
                        </span>
                      </div>

                      {/* Botões de Ação */}
                      <div className="flex items-center gap-2 pt-1">
                        <button
                          onClick={() => abrirDetalhes(pedido)}
                          className="p-2 text-[#9CAABC] hover:text-white bg-[#0B132B] hover:bg-[#2A405B] border border-[#2A405B] rounded-lg text-xs font-semibold transition-colors cursor-pointer"
                          title="Ver detalhes do pedido"
                        >
                          <Eye className="w-3.5 h-3.5" />
                        </button>

                        {coluna.proximoStatus && (
                          <button
                            disabled={atualizandoStatus === pedido.id}
                            onClick={() => alterarStatus(pedido.id, coluna.proximoStatus!)}
                            className="flex-1 py-1.5 px-3 bg-gradient-to-r from-[#8C63FF] to-[#7847eb] hover:from-[#7847eb] hover:to-[#6366F1] text-white rounded-lg text-xs font-bold transition-all shadow-md shadow-[#8C63FF]/20 flex items-center justify-center gap-1 cursor-pointer disabled:opacity-50"
                          >
                            {atualizandoStatus === pedido.id ? (
                              <div className="w-3 h-3 border-2 border-white border-t-transparent rounded-full animate-spin" />
                            ) : (
                              <>
                                <span>{coluna.acaoTexto}</span>
                                <ChevronRight className="w-3.5 h-3.5" />
                              </>
                            )}
                          </button>
                        )}
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          );
        })}
      </div>

      {/* Modal de Detalhes do Pedido */}
      {modalDetalhesAberto && pedidoSelecionado && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-[#152439] border border-[#2A405B] rounded-2xl w-full max-w-2xl max-h-[90vh] flex flex-col shadow-2xl overflow-hidden">
            {/* Header Modal */}
            <div className="p-4 md:p-6 border-b border-[#2A405B] flex items-center justify-between bg-[#121f30]">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-[#8C63FF]/20 border border-[#8C63FF]/30 flex items-center justify-center text-[#8C63FF] font-bold">
                  #{pedidoSelecionado.numero_pedido || pedidoSelecionado.id}
                </div>
                <div>
                  <h3 className="text-lg font-bold text-white">Detalhes do Pedido #{pedidoSelecionado.numero_pedido || pedidoSelecionado.id}</h3>
                  <p className="text-xs text-[#9CAABC]">
                    Criado em {new Date(pedidoSelecionado.criado_em).toLocaleString('pt-BR')}
                  </p>
                </div>
              </div>

              <button
                onClick={() => setModalDetalhesAberto(false)}
                className="p-2 text-[#9CAABC] hover:text-white rounded-lg hover:bg-[#1c2e47] transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Conteúdo Modal */}
            <div className="p-4 md:p-6 overflow-y-auto space-y-6">
              {/* Info Cliente */}
              <div className="bg-[#0B132B] border border-[#2A405B] rounded-xl p-4 grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <span className="text-[10px] uppercase font-bold text-[#64748B]">Cliente</span>
                  <p className="font-bold text-sm text-white">{pedidoSelecionado.cliente_nome}</p>
                  <p className="text-xs text-[#9CAABC] flex items-center gap-1 mt-1">
                    <Phone className="w-3.5 h-3.5 text-[#8C63FF]" />
                    {pedidoSelecionado.cliente_telefone || 'Não informado'}
                  </p>
                </div>

                <div>
                  <span className="text-[10px] uppercase font-bold text-[#64748B]">Entrega / Endereço</span>
                  <p className="font-bold text-sm text-white capitalize">{pedidoSelecionado.tipo_entrega}</p>
                  {pedidoSelecionado.endereco_rua && (
                    <p className="text-xs text-[#9CAABC] mt-1">
                      {pedidoSelecionado.endereco_rua}
                      {pedidoSelecionado.endereco_numero ? `, ${pedidoSelecionado.endereco_numero}` : ''}
                      {pedidoSelecionado.endereco_bairro ? ` - ${pedidoSelecionado.endereco_bairro}` : ''}
                    </p>
                  )}
                </div>
              </div>

              {/* Itens do Pedido */}
              <div>
                <h4 className="font-bold text-sm text-white mb-3 flex items-center gap-2">
                  <ShoppingBag className="w-4 h-4 text-[#8C63FF]" />
                  Itens do Pedido
                </h4>

                <div className="border border-[#2A405B] rounded-xl divide-y divide-[#2A405B] overflow-hidden bg-[#0B132B]">
                  {carregandoDetalhes ? (
                    <div className="p-6 text-center text-xs text-[#9CAABC] flex items-center justify-center gap-2">
                      <RefreshCw className="w-4 h-4 animate-spin text-[#8C63FF]" />
                      <span>Carregando itens...</span>
                    </div>
                  ) : pedidoSelecionado.itens && pedidoSelecionado.itens.length > 0 ? (
                    pedidoSelecionado.itens.map((item, idx) => (
                      <div key={idx} className="p-3.5 flex items-start justify-between gap-4">
                        <div>
                          <div className="flex items-center gap-2">
                            <span className="px-2 py-0.5 bg-[#8C63FF]/20 text-[#8C63FF] text-xs font-bold rounded">
                              {item.quantidade}x
                            </span>
                            <span className="font-bold text-sm text-white">{item.produto_nome}</span>
                          </div>

                          {item.sabores && item.sabores.length > 0 && (
                            <p className="text-xs text-[#9CAABC] mt-1 ml-8">
                              Sabores: {item.sabores.map((s) => `${s.sabor_nome}${s.fracao ? ` (${s.fracao})` : ''}`).join(', ')}
                            </p>
                          )}

                          {item.borda_nome && (
                            <p className="text-xs text-[#9CAABC] ml-8">
                              Borda: {item.borda_nome}
                            </p>
                          )}

                          {item.adicionais && item.adicionais.length > 0 && (
                            <p className="text-xs text-[#9CAABC] ml-8">
                              Adicionais: {item.adicionais.map((a) => `${a.quantidade}x ${a.adicional_nome}`).join(', ')}
                            </p>
                          )}

                          {item.observacoes && (
                            <p className="text-xs text-[#F59E0B] italic mt-1 ml-8">
                              Obs: {item.observacoes}
                            </p>
                          )}
                        </div>

                        <span className="font-bold text-sm text-white shrink-0">
                          {formatarMoeda(item.preco_total)}
                        </span>
                      </div>
                    ))
                  ) : pedidoSelecionado.itens_resumo ? (
                    <div className="p-4 text-xs text-white whitespace-pre-line">
                      {pedidoSelecionado.itens_resumo}
                    </div>
                  ) : (
                    <div className="p-4 text-center text-xs text-[#64748B]">
                      Nenhum item detalhado
                    </div>
                  )}
                </div>
              </div>

              {/* Totais */}
              <div className="bg-[#0B132B] border border-[#2A405B] rounded-xl p-4 space-y-2 text-xs">
                <div className="flex justify-between text-[#9CAABC]">
                  <span>Forma de Pagamento</span>
                  <span className="font-bold text-white">
                    {formatarFormaPagamento(pedidoSelecionado.forma_pagamento, pedidoSelecionado.troco_para)}
                  </span>
                </div>
                <div className="flex justify-between text-[#9CAABC]">
                  <span>Subtotal</span>
                  <span>{formatarMoeda(pedidoSelecionado.subtotal || pedidoSelecionado.total)}</span>
                </div>
                {pedidoSelecionado.taxa_entrega > 0 && (
                  <div className="flex justify-between text-[#9CAABC]">
                    <span>Taxa de Entrega</span>
                    <span>{formatarMoeda(pedidoSelecionado.taxa_entrega)}</span>
                  </div>
                )}
                {pedidoSelecionado.desconto > 0 && (
                  <div className="flex justify-between text-[#EF4444]">
                    <span>Desconto</span>
                    <span>-{formatarMoeda(pedidoSelecionado.desconto)}</span>
                  </div>
                )}
                <div className="flex justify-between text-base font-extrabold text-white pt-2 border-t border-[#2A405B]">
                  <span>Total</span>
                  <span className="text-[#10B981]">{formatarMoeda(pedidoSelecionado.total)}</span>
                </div>
              </div>
            </div>

            {/* Footer Modal / Ações de Impressão e Status */}
            <div className="p-4 border-t border-[#2A405B] bg-[#121f30] flex items-center justify-between gap-3">
              <button
                onClick={() => window.print()}
                className="flex items-center gap-2 px-4 py-2.5 bg-[#0B132B] hover:bg-[#1c2e47] border border-[#2A405B] text-xs font-semibold text-white rounded-xl transition-colors cursor-pointer"
              >
                <Printer className="w-4 h-4 text-[#8C63FF]" />
                <span>Imprimir Comanda</span>
              </button>

              <div className="flex items-center gap-2">
                {pedidoSelecionado.status !== 'cancelado' && (
                  <button
                    onClick={() => {
                      if (confirm('Deseja realmente cancelar este pedido?')) {
                        alterarStatus(pedidoSelecionado.id, 'cancelado');
                        setModalDetalhesAberto(false);
                      }
                    }}
                    className="px-3 py-2 text-xs font-semibold text-[#EF4444] hover:bg-[#EF4444]/10 rounded-xl transition-colors cursor-pointer"
                  >
                    Cancelar Pedido
                  </button>
                )}
                <button
                  onClick={() => setModalDetalhesAberto(false)}
                  className="px-4 py-2.5 bg-[#2A405B] hover:bg-[#3B82F6] text-white text-xs font-bold rounded-xl transition-colors cursor-pointer"
                >
                  Fechar
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
