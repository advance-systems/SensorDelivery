import React, { useState, useEffect } from 'react';
import { api } from '../api/client';
import { Store, Clock, DollarSign, MapPin, Save, AlertCircle, Check } from 'lucide-react';

export const ConfiguracoesLoja: React.FC = () => {
  const [carregando, setCarregando] = useState(true);
  const [salvando, setSalvando] = useState(false);
  const [mensagemSucesso, setMensagemSucesso] = useState(false);
  const [erro, setErro] = useState('');

  // Estados
  const [nomeLoja, setNomeLoja] = useState('');
  const [telefone, setTelefone] = useState('');
  const [tempoMinimoEntrega, setTempoMinimoEntrega] = useState('30');
  const [tempoMaximoEntrega, setTempoMaximoEntrega] = useState('50');
  const [pedidoMinimo, setPedidoMinimo] = useState('20,00');
  const [taxaEntregaPadrao, setTaxaEntregaPadrao] = useState('5,00');
  const [lojaAberta, setLojaAberta] = useState(true);

  const carregarConfiguracoes = async () => {
    try {
      setCarregando(true);
      const res = await api.get('/configuracoes');
      const dados = res.data?.configuracoes || res.data || {};
      if (dados.nome_loja) setNomeLoja(dados.nome_loja);
      if (dados.telefone) setTelefone(dados.telefone);
      if (dados.tempo_min_entrega) setTempoMinimoEntrega(String(dados.tempo_min_entrega));
      if (dados.tempo_max_entrega) setTempoMaximoEntrega(String(dados.tempo_max_entrega));
      if (dados.pedido_minimo) setPedidoMinimo(String(dados.pedido_minimo));
      if (dados.taxa_entrega_padrao) setTaxaEntregaPadrao(String(dados.taxa_entrega_padrao));
      if (dados.loja_aberta !== undefined) setLojaAberta(dados.loja_aberta);
    } catch (err) {
      console.error('Erro ao carregar configurações:', err);
    } finally {
      setCarregando(false);
    }
  };

  useEffect(() => {
    carregarConfiguracoes();
  }, []);

  const salvarConfiguracoes = async (e: React.FormEvent) => {
    e.preventDefault();
    setErro('');
    setMensagemSucesso(false);
    setSalvando(true);

    try {
      await api.put('/configuracoes', {
        nome_loja: nomeLoja,
        telefone,
        tempo_min_entrega: Number(tempoMinimoEntrega),
        tempo_max_entrega: Number(tempoMaximoEntrega),
        pedido_minimo: Number(pedidoMinimo.replace(',', '.')) || 0,
        taxa_entrega_padrao: Number(taxaEntregaPadrao.replace(',', '.')) || 0,
        loja_aberta: lojaAberta,
      });

      setMensagemSucesso(true);
      setTimeout(() => setMensagemSucesso(false), 4000);
    } catch (err: any) {
      console.error('Erro ao salvar configurações:', err);
      setErro(err.response?.data?.mensagem || 'Falha ao salvar configurações.');
    } finally {
      setSalvando(false);
    }
  };

  return (
    <div className="space-y-6 max-w-4xl">
      {/* Topo */}
      <div>
        <h2 className="text-2xl font-bold text-white tracking-tight flex items-center gap-2.5">
          <Store className="w-6 h-6 text-[#8C63FF]" />
          Configurações da Loja & Operação
        </h2>
        <p className="text-xs text-[#9CAABC] mt-0.5">
          Defina horários, tempo estimado de entrega, pedido mínimo e taxas
        </p>
      </div>

      {mensagemSucesso && (
        <div className="p-4 bg-[#10B981]/10 border border-[#10B981]/30 rounded-2xl text-[#10B981] text-xs flex items-center gap-2">
          <Check className="w-4 h-4" />
          <span>Configurações atualizadas com sucesso!</span>
        </div>
      )}

      {erro && (
        <div className="p-4 bg-[#EF4444]/10 border border-[#EF4444]/30 rounded-2xl text-[#EF4444] text-xs flex items-center gap-2">
          <AlertCircle className="w-4 h-4" />
          <span>{erro}</span>
        </div>
      )}

      <form onSubmit={salvarConfiguracoes} className="space-y-6">
        {/* Card Status da Loja */}
        <div className="bg-[#152439] border border-[#2A405B] rounded-2xl p-6 shadow-xl flex items-center justify-between">
          <div>
            <h3 className="font-bold text-base text-white">Status de Funcionamento</h3>
            <p className="text-xs text-[#9CAABC] mt-0.5">
              Quando fechada, os clientes não conseguem finalizar novos pedidos no cardápio
            </p>
          </div>

          <label className="relative inline-flex items-center cursor-pointer">
            <input
              type="checkbox"
              checked={lojaAberta}
              onChange={(e) => setLojaAberta(e.target.checked)}
              className="sr-only peer"
            />
            <div className="w-14 h-7 bg-[#2A405B] peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-0.5 after:left-[4px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-6 after:w-6 after:transition-all peer-checked:bg-[#10B981]"></div>
          </label>
        </div>

        {/* Card Informações Básicas */}
        <div className="bg-[#152439] border border-[#2A405B] rounded-2xl p-6 shadow-xl space-y-4">
          <h3 className="font-bold text-base text-white border-b border-[#2A405B] pb-3">
            Identificação & Atendimento
          </h3>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-[#9CAABC] uppercase tracking-wider mb-1.5">
                Nome da Loja / Fantasia
              </label>
              <input
                type="text"
                value={nomeLoja}
                onChange={(e) => setNomeLoja(e.target.value)}
                placeholder="Ex: Pizzaria Sensor Gourmet"
                className="w-full bg-[#0B132B] border border-[#2A405B] focus:border-[#8C63FF] text-white rounded-xl px-4 py-2.5 text-xs focus:outline-none transition-colors"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#9CAABC] uppercase tracking-wider mb-1.5">
                WhatsApp / Telefone de Contato
              </label>
              <input
                type="text"
                value={telefone}
                onChange={(e) => setTelefone(e.target.value)}
                placeholder="(00) 00000-0000"
                className="w-full bg-[#0B132B] border border-[#2A405B] focus:border-[#8C63FF] text-white rounded-xl px-4 py-2.5 text-xs focus:outline-none transition-colors"
              />
            </div>
          </div>
        </div>

        {/* Card Prazos e Taxas */}
        <div className="bg-[#152439] border border-[#2A405B] rounded-2xl p-6 shadow-xl space-y-4">
          <h3 className="font-bold text-base text-white border-b border-[#2A405B] pb-3">
            Prazos & Valores Mínimos
          </h3>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <div>
              <label className="block text-xs font-semibold text-[#9CAABC] uppercase tracking-wider mb-1.5">
                Tempo Mínimo (Minutos)
              </label>
              <input
                type="number"
                value={tempoMinimoEntrega}
                onChange={(e) => setTempoMinimoEntrega(e.target.value)}
                className="w-full bg-[#0B132B] border border-[#2A405B] focus:border-[#8C63FF] text-white rounded-xl px-4 py-2.5 text-xs focus:outline-none transition-colors"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#9CAABC] uppercase tracking-wider mb-1.5">
                Tempo Máximo (Minutos)
              </label>
              <input
                type="number"
                value={tempoMaximoEntrega}
                onChange={(e) => setTempoMaximoEntrega(e.target.value)}
                className="w-full bg-[#0B132B] border border-[#2A405B] focus:border-[#8C63FF] text-white rounded-xl px-4 py-2.5 text-xs focus:outline-none transition-colors"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#9CAABC] uppercase tracking-wider mb-1.5">
                Pedido Mínimo (R$)
              </label>
              <input
                type="text"
                value={pedidoMinimo}
                onChange={(e) => setPedidoMinimo(e.target.value)}
                className="w-full bg-[#0B132B] border border-[#2A405B] focus:border-[#8C63FF] text-white rounded-xl px-4 py-2.5 text-xs focus:outline-none transition-colors"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#9CAABC] uppercase tracking-wider mb-1.5">
                Taxa de Entrega Padrão (R$)
              </label>
              <input
                type="text"
                value={taxaEntregaPadrao}
                onChange={(e) => setTaxaEntregaPadrao(e.target.value)}
                className="w-full bg-[#0B132B] border border-[#2A405B] focus:border-[#8C63FF] text-white rounded-xl px-4 py-2.5 text-xs focus:outline-none transition-colors"
              />
            </div>
          </div>
        </div>

        {/* Botão Salvar */}
        <div className="flex justify-end">
          <button
            type="submit"
            disabled={salvando}
            className="flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-[#8C63FF] to-[#7847eb] hover:from-[#7847eb] hover:to-[#6366F1] text-white font-bold rounded-xl text-xs shadow-lg shadow-[#8C63FF]/30 transition-all cursor-pointer disabled:opacity-50"
          >
            <Save className="w-4 h-4" />
            <span>{salvando ? 'Salvando Configurações...' : 'Salvar Todas as Configurações'}</span>
          </button>
        </div>
      </form>
    </div>
  );
};
