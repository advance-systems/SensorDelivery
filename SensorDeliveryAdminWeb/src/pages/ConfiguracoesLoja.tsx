import React, { useState, useEffect } from 'react';
import { api } from '../api/client';
import { Store, Clock, DollarSign, MapPin, Save, AlertCircle, Check, Calendar, FileText } from 'lucide-react';

interface HorarioItem {
  diaSemana: number;
  horarioAbertura: string;
  horarioFechamento: string;
  fechado: boolean;
}

const NOMES_DIAS = [
  'Domingo',
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
];

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
  const [modoFuncionamento, setModoFuncionamento] = useState<'AUTOMATICO' | 'ABERTO' | 'FECHADO'>('AUTOMATICO');
  const [mensagemFechada, setMensagemFechada] = useState('');
  const [cancelarRascunhosAntigos, setCancelarRascunhosAntigos] = useState(true);

  // Horários de Domingo a Sábado (0 a 6)
  const [horarios, setHorarios] = useState<HorarioItem[]>(
    Array.from({ length: 7 }, (_, diaSemana) => ({
      diaSemana,
      horarioAbertura: '18:00',
      horarioFechamento: '23:30',
      fechado: false,
    }))
  );

  const carregarConfiguracoes = async () => {
    try {
      setCarregando(true);
      const res = await api.get('/configuracoes');
      const dados = res.data?.configuracao || res.data?.configuracoes || res.data || {};
      const listaHorarios = res.data?.horarios || [];

      if (dados.nome_loja) setNomeLoja(dados.nome_loja);
      if (dados.telefone) setTelefone(dados.telefone);
      if (dados.tempo_min_entrega) setTempoMinimoEntrega(String(dados.tempo_min_entrega));
      if (dados.tempo_entrega_minutos) setTempoMaximoEntrega(String(dados.tempo_entrega_minutos));
      if (dados.pedido_minimo) setPedidoMinimo(String(dados.pedido_minimo));
      if (dados.taxa_entrega) setTaxaEntregaPadrao(String(dados.taxa_entrega));
      if (dados.modo_funcionamento) setModoFuncionamento(dados.modo_funcionamento);
      if (dados.mensagem_fechada) setMensagemFechada(dados.mensagem_fechada);
      if (dados.cancelar_rascunhos_antigos !== undefined) {
        setCancelarRascunhosAntigos(Boolean(dados.cancelar_rascunhos_antigos));
      }

      if (Array.isArray(listaHorarios) && listaHorarios.length > 0) {
        const preenchidos = Array.from({ length: 7 }, (_, dia) => {
          const encontrado = listaHorarios.find((h: any) => Number(h.dia_semana ?? h.diaSemana) === dia);
          return {
            diaSemana: dia,
            horarioAbertura: (encontrado?.horario_abertura ?? encontrado?.horarioAbertura ?? '18:00').slice(0, 5),
            horarioFechamento: (encontrado?.horario_fechamento ?? encontrado?.horarioFechamento ?? '23:30').slice(0, 5),
            fechado: Boolean(encontrado?.fechado),
          };
        });
        setHorarios(preenchidos);
      }
    } catch (err) {
      console.error('Erro ao carregar configurações:', err);
    } finally {
      setCarregando(false);
    }
  };

  useEffect(() => {
    carregarConfiguracoes();
  }, []);

  const handleHorarioChange = (diaSemana: number, campo: keyof HorarioItem, valor: any) => {
    setHorarios((prev) =>
      prev.map((item) => (item.diaSemana === diaSemana ? { ...item, [campo]: valor } : item))
    );
  };

  const aplicarParaTodosOsDias = (diaBase: number) => {
    const base = horarios.find((h) => h.diaSemana === diaBase);
    if (!base) return;
    setHorarios((prev) =>
      prev.map((item) => ({
        ...item,
        horarioAbertura: base.horarioAbertura,
        horarioFechamento: base.horarioFechamento,
        fechado: base.fechado,
      }))
    );
  };

  const salvarConfiguracoes = async (e: React.FormEvent) => {
    e.preventDefault();
    setErro('');
    setMensagemSucesso(false);
    setSalvando(true);

    try {
      const payloadHorarios = horarios.map((h) => ({
        diaSemana: h.diaSemana,
        horarioAbertura: h.horarioAbertura.length === 5 ? `${h.horarioAbertura}:00` : h.horarioAbertura,
        horarioFechamento: h.horarioFechamento.length === 5 ? `${h.horarioFechamento}:00` : h.horarioFechamento,
        fechado: h.fechado,
      }));

      await api.put('/configuracoes', {
        modoFuncionamento,
        mensagemFechada,
        taxaEntrega: Number(taxaEntregaPadrao.replace(',', '.')) || 0,
        pedidoMinimo: Number(pedidoMinimo.replace(',', '.')) || 0,
        tempoEntregaMinutos: Number(tempoMaximoEntrega) || 45,
        cancelarRascunhosAntigos,
        horarios: payloadHorarios,
      });

      setMensagemSucesso(true);
      setTimeout(() => setMensagemSucesso(false), 4000);
    } catch (err: any) {
      console.error('Erro ao salvar configurações:', err);
      setErro(err.response?.data?.erro || err.response?.data?.mensagem || 'Falha ao salvar configurações.');
    } finally {
      setSalvando(false);
    }
  };

  return (
    <div className="space-y-6 max-w-4xl pb-12">
      {/* Topo */}
      <div>
        <h2 className="text-2xl font-bold text-white tracking-tight flex items-center gap-2.5">
          <Store className="w-6 h-6 text-[#8C63FF]" />
          Configurações da Loja & Operação
        </h2>
        <p className="text-xs text-[#9CAABC] mt-0.5">
          Defina horários de domingo a sábado, modo de funcionamento, tempo de entrega e taxas
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
        {/* Card Modo de Funcionamento */}
        <div className="bg-[#152439] border border-[#2A405B] rounded-2xl p-6 shadow-xl space-y-4">
          <h3 className="font-bold text-base text-white border-b border-[#2A405B] pb-3 flex items-center justify-between">
            <span>Modo de Funcionamento</span>
            <span
              className={`text-xs px-2.5 py-1 rounded-full font-bold ${
                modoFuncionamento === 'AUTOMATICO'
                  ? 'bg-[#3B82F6]/20 text-[#60A5FA]'
                  : modoFuncionamento === 'ABERTO'
                  ? 'bg-[#10B981]/20 text-[#34D399]'
                  : 'bg-[#EF4444]/20 text-[#F87171]'
              }`}
            >
              {modoFuncionamento === 'AUTOMATICO'
                ? 'Automático (pelos horários)'
                : modoFuncionamento === 'ABERTO'
                ? 'Forçar Aberto'
                : 'Forçar Fechado'}
            </span>
          </h3>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <button
              type="button"
              onClick={() => setModoFuncionamento('AUTOMATICO')}
              className={`p-3.5 rounded-xl border text-left cursor-pointer transition-all ${
                modoFuncionamento === 'AUTOMATICO'
                  ? 'bg-[#8C63FF]/15 border-[#8C63FF] text-white shadow-md shadow-[#8C63FF]/20'
                  : 'bg-[#0B132B] border-[#2A405B] text-[#9CAABC] hover:border-[#8C63FF]/50'
              }`}
            >
              <div className="font-bold text-xs text-white">Automático</div>
              <div className="text-[11px] mt-1 text-[#9CAABC]">Abre e fecha conforme a grade semanal</div>
            </button>

            <button
              type="button"
              onClick={() => setModoFuncionamento('ABERTO')}
              className={`p-3.5 rounded-xl border text-left cursor-pointer transition-all ${
                modoFuncionamento === 'ABERTO'
                  ? 'bg-[#10B981]/15 border-[#10B981] text-white shadow-md shadow-[#10B981]/20'
                  : 'bg-[#0B132B] border-[#2A405B] text-[#9CAABC] hover:border-[#10B981]/50'
              }`}
            >
              <div className="font-bold text-xs text-white">Forçar Aberto</div>
              <div className="text-[11px] mt-1 text-[#9CAABC]">Permite pedidos independente do horário</div>
            </button>

            <button
              type="button"
              onClick={() => setModoFuncionamento('FECHADO')}
              className={`p-3.5 rounded-xl border text-left cursor-pointer transition-all ${
                modoFuncionamento === 'FECHADO'
                  ? 'bg-[#EF4444]/15 border-[#EF4444] text-white shadow-md shadow-[#EF4444]/20'
                  : 'bg-[#0B132B] border-[#2A405B] text-[#9CAABC] hover:border-[#EF4444]/50'
              }`}
            >
              <div className="font-bold text-xs text-white">Forçar Fechado</div>
              <div className="text-[11px] mt-1 text-[#9CAABC]">Pausa o recebimento de novos pedidos</div>
            </button>
          </div>

          {modoFuncionamento === 'FECHADO' && (
            <div className="pt-2">
              <label className="block text-xs font-semibold text-[#9CAABC] uppercase tracking-wider mb-1.5">
                Mensagem quando a loja estiver fechada
              </label>
              <input
                type="text"
                value={mensagemFechada}
                onChange={(e) => setMensagemFechada(e.target.value)}
                placeholder="Ex: Estamos fechados para manutenção. Retornaremos às 18h."
                className="w-full bg-[#0B132B] border border-[#2A405B] focus:border-[#8C63FF] text-white rounded-xl px-4 py-2.5 text-xs focus:outline-none transition-colors"
              />
            </div>
          )}
        </div>

        {/* Card Grade de Horários de Domingo a Sábado */}
        <div className="bg-[#152439] border border-[#2A405B] rounded-2xl p-6 shadow-xl space-y-4">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between border-b border-[#2A405B] pb-3 gap-2">
            <div>
              <h3 className="font-bold text-base text-white flex items-center gap-2">
                <Clock className="w-5 h-5 text-[#8C63FF]" />
                Horário de Funcionamento (Domingo a Sábado)
              </h3>
              <p className="text-xs text-[#9CAABC] mt-0.5">
                Defina os horários de abertura e fechamento para cada dia da semana
              </p>
            </div>
            <button
              type="button"
              onClick={() => aplicarParaTodosOsDias(0)}
              className="text-[11px] text-[#8C63FF] hover:text-[#a78bfa] underline cursor-pointer self-start sm:self-auto"
            >
              Copiar domingo p/ todos os dias
            </button>
          </div>

          <div className="space-y-3">
            {horarios.map((item) => (
              <div
                key={item.diaSemana}
                className={`flex flex-col sm:flex-row sm:items-center justify-between p-3.5 rounded-xl border transition-colors gap-3 ${
                  item.fechado
                    ? 'bg-[#0B132B]/50 border-[#2A405B]/60 opacity-70'
                    : 'bg-[#0B132B] border-[#2A405B]'
                }`}
              >
                <div className="w-36 font-semibold text-xs text-white flex items-center gap-2">
                  <span className="w-2 h-2 rounded-full bg-[#8C63FF]"></span>
                  <span>{NOMES_DIAS[item.diaSemana]}</span>
                </div>

                <div className="flex items-center gap-3 flex-1 flex-wrap sm:flex-nowrap">
                  <div className="flex items-center gap-2">
                    <span className="text-xs text-[#9CAABC]">Abertura:</span>
                    <input
                      type="time"
                      disabled={item.fechado}
                      value={item.horarioAbertura}
                      onChange={(e) => handleHorarioChange(item.diaSemana, 'horarioAbertura', e.target.value)}
                      className="bg-[#152439] border border-[#2A405B] text-white rounded-lg px-2.5 py-1.5 text-xs focus:outline-none focus:border-[#8C63FF] disabled:opacity-40"
                    />
                  </div>

                  <div className="flex items-center gap-2">
                    <span className="text-xs text-[#9CAABC]">Fechamento:</span>
                    <input
                      type="time"
                      disabled={item.fechado}
                      value={item.horarioFechamento}
                      onChange={(e) => handleHorarioChange(item.diaSemana, 'horarioFechamento', e.target.value)}
                      className="bg-[#152439] border border-[#2A405B] text-white rounded-lg px-2.5 py-1.5 text-xs focus:outline-none focus:border-[#8C63FF] disabled:opacity-40"
                    />
                  </div>
                </div>

                <label className="flex items-center gap-2 cursor-pointer select-none">
                  <input
                    type="checkbox"
                    checked={item.fechado}
                    onChange={(e) => handleHorarioChange(item.diaSemana, 'fechado', e.target.checked)}
                    className="rounded border-[#2A405B] text-[#EF4444] focus:ring-[#EF4444] bg-[#152439]"
                  />
                  <span className={`text-xs font-semibold ${item.fechado ? 'text-[#EF4444]' : 'text-[#9CAABC]'}`}>
                    Fechado neste dia
                  </span>
                </label>
              </div>
            ))}
          </div>
        </div>

        {/* Card Prazos e Taxas */}
        <div className="bg-[#152439] border border-[#2A405B] rounded-2xl p-6 shadow-xl space-y-4">
          <h3 className="font-bold text-base text-white border-b border-[#2A405B] pb-3">
            Prazos & Valores Mínimos
          </h3>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label className="block text-xs font-semibold text-[#9CAABC] uppercase tracking-wider mb-1.5">
                Tempo de Entrega (Minutos)
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

        {/* Card Regras de Pedidos & Rascunhos */}
        <div className="bg-[#152439] border border-[#2A405B] rounded-2xl p-6 shadow-xl space-y-4">
          <h3 className="font-bold text-base text-white border-b border-[#2A405B] pb-3 flex items-center gap-2">
            <FileText className="w-5 h-5 text-[#8C63FF]" />
            Regras de Pedidos & Rascunhos
          </h3>

          <div className="flex flex-col sm:flex-row sm:items-center justify-between p-4 rounded-xl bg-[#0B132B] border border-[#2A405B] gap-4">
            <div className="space-y-1 max-w-xl">
              <div className="font-semibold text-sm text-white flex items-center gap-2">
                <span>Cancelar rascunhos de dias anteriores automaticamente</span>
                {cancelarRascunhosAntigos ? (
                  <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#10B981]/20 text-[#34D399] border border-[#10B981]/30">
                    Ativado
                  </span>
                ) : (
                  <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#EF4444]/20 text-[#F87171] border border-[#EF4444]/30">
                    Desativado
                  </span>
                )}
              </div>
              <p className="text-xs text-[#9CAABC] leading-relaxed">
                Quando ativado, pedidos que permanecerem com o status de <strong>Rascunho</strong> de um dia para o outro serão cancelados automaticamente pelo sistema.
              </p>
            </div>

            <label className="relative inline-flex items-center cursor-pointer shrink-0">
              <input
                type="checkbox"
                checked={cancelarRascunhosAntigos}
                onChange={(e) => setCancelarRascunhosAntigos(e.target.checked)}
                className="sr-only peer"
              />
              <div className="w-11 h-6 bg-[#2A405B] peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#8C63FF]"></div>
            </label>
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

