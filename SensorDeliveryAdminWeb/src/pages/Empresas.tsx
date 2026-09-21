import React, { useState, useEffect, useRef } from 'react';
import { api } from '../api/client';
import { Building2, Plus, Edit2, Check, X, Search, AlertCircle, Upload, Image as ImageIcon, Phone, Mail, Globe, Shield } from 'lucide-react';

interface Empresa {
  id: string;
  razao_social: string;
  nome_fantasia: string;
  logo_url?: string | null;
  telefone?: string | null;
  email?: string | null;
  timezone?: string;
  pix_provedor?: 'ASAAS' | 'SICREDI' | string;
  ativo: boolean;
  criado_em?: string;
  atualizado_em?: string;
}

export const Empresas: React.FC = () => {
  const [empresas, setEmpresas] = useState<Empresa[]>([]);
  const [carregando, setCarregando] = useState(true);
  const [modalAberto, setModalAberto] = useState(false);
  const [salvando, setSalvando] = useState(false);
  const [enviandoLogo, setEnviandoLogo] = useState(false);
  const [erro, setErro] = useState('');
  const [busca, setBusca] = useState('');

  // Formulário
  const [editandoId, setEditandoId] = useState<string | null>(null);
  const [razaoSocial, setRazaoSocial] = useState('');
  const [nomeFantasia, setNomeFantasia] = useState('');
  const [telefone, setTelefone] = useState('');
  const [email, setEmail] = useState('');
  const [timezone, setTimezone] = useState('America/Sao_Paulo');
  const [pixProvedor, setPixProvedor] = useState<'ASAAS' | 'SICREDI'>('ASAAS');
  const [logoUrl, setLogoUrl] = useState('');

  const inputFileRef = useRef<HTMLInputElement>(null);

  const carregarEmpresas = async (termoBusca = busca) => {
    try {
      setCarregando(true);
      const response = await api.get('/empresas', {
        params: termoBusca ? { busca: termoBusca } : undefined,
      });
      if (Array.isArray(response.data)) {
        setEmpresas(response.data);
      } else if (response.data?.empresas) {
        setEmpresas(response.data.empresas);
      }
    } catch (err: any) {
      console.error('Erro ao carregar empresas:', err);
    } finally {
      setCarregando(false);
    }
  };

  useEffect(() => {
    carregarEmpresas();
  }, []);

  const abrirModalNovo = () => {
    setEditandoId(null);
    setRazaoSocial('');
    setNomeFantasia('');
    setTelefone('');
    setEmail('');
    setTimezone('America/Sao_Paulo');
    setPixProvedor('ASAAS');
    setLogoUrl('');
    setErro('');
    setModalAberto(true);
  };

  const abrirModalEditar = (emp: Empresa) => {
    setEditandoId(emp.id);
    setRazaoSocial(emp.razao_social || '');
    setNomeFantasia(emp.nome_fantasia || '');
    setTelefone(emp.telefone || '');
    setEmail(emp.email || '');
    setTimezone(emp.timezone || 'America/Sao_Paulo');
    setPixProvedor((emp.pix_provedor as 'ASAAS' | 'SICREDI') || 'ASAAS');
    setLogoUrl(emp.logo_url || '');
    setErro('');
    setModalAberto(true);
  };

  const fecharModal = () => {
    setModalAberto(false);
    setEditandoId(null);
    setErro('');
  };

  const handleUploadLogo = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Validar tipo
    if (!['image/jpeg', 'image/png', 'image/webp', 'image/gif'].includes(file.type)) {
      setErro('Selecione uma imagem válida (JPG, PNG, WEBP ou GIF).');
      return;
    }

    // Validar tamanho (máx 8MB)
    if (file.size > 8 * 1024 * 1024) {
      setErro('A imagem não pode ultrapassar 8MB.');
      return;
    }

    try {
      setEnviandoLogo(true);
      setErro('');

      const buffer = await file.arrayBuffer();
      const response = await api.post('/uploads/imagens', buffer, {
        headers: {
          'Content-Type': file.type,
        },
      });

      if (response.data?.url) {
        setLogoUrl(response.data.url);
      }
    } catch (err: any) {
      console.error('Erro ao enviar logotipo:', err);
      setErro(err.response?.data?.erro || 'Erro ao enviar a imagem do logotipo.');
    } finally {
      setEnviandoLogo(false);
      if (inputFileRef.current) {
        inputFileRef.current.value = '';
      }
    }
  };

  const salvarEmpresa = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!razaoSocial.trim()) {
      setErro('Razão Social é obrigatória.');
      return;
    }
    if (!nomeFantasia.trim()) {
      setErro('Nome Fantasia é obrigatório.');
      return;
    }

    try {
      setSalvando(true);
      setErro('');

      const dados = {
        razaoSocial: razaoSocial.trim(),
        nomeFantasia: nomeFantasia.trim(),
        telefone: telefone.trim(),
        email: email.trim(),
        timezone: timezone.trim(),
        pixProvedor: pixProvedor,
        logoUrl: logoUrl.trim(),
      };

      if (editandoId) {
        await api.put(`/empresas/${editandoId}`, dados);
      } else {
        await api.post('/empresas', dados);
      }

      fecharModal();
      carregarEmpresas();
    } catch (err: any) {
      console.error('Erro ao salvar empresa:', err);
      setErro(err.response?.data?.erro || 'Erro ao salvar a empresa. Verifique os dados.');
    } finally {
      setSalvando(false);
    }
  };

  const alternarSituacao = async (emp: Empresa) => {
    try {
      await api.patch(`/empresas/${emp.id}/situacao`, { ativo: !emp.ativo });
      setEmpresas(empresas.map((item) => (item.id === emp.id ? { ...item, ativo: !item.ativo } : item)));
    } catch (err: any) {
      console.error('Erro ao alternar status da empresa:', err);
      alert(err.response?.data?.erro || 'Não foi possível alterar a situação da empresa.');
    }
  };

  const empresasFiltradas = empresas.filter((emp) => {
    const termo = busca.toLowerCase();
    return (
      emp.nome_fantasia?.toLowerCase().includes(termo) ||
      emp.razao_social?.toLowerCase().includes(termo) ||
      emp.email?.toLowerCase().includes(termo) ||
      emp.telefone?.toLowerCase().includes(termo)
    );
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white flex items-center gap-2">
            <Building2 className="w-7 h-7 text-indigo-400" />
            Empresas
          </h1>
          <p className="text-sm text-slate-400">
            Gerencie as empresas, configurações básicas e logotipos cadastrados no sistema
          </p>
        </div>
        <button
          onClick={abrirModalNovo}
          className="inline-flex items-center justify-center gap-2 px-4 py-2.5 bg-indigo-600 hover:bg-indigo-500 text-white font-medium rounded-xl transition-colors shadow-lg shadow-indigo-600/20"
        >
          <Plus className="w-5 h-5" />
          Nova Empresa
        </button>
      </div>

      {/* Busca */}
      <div className="bg-[#152439] p-4 rounded-2xl border border-[#2A405B] flex items-center gap-3">
        <Search className="w-5 h-5 text-slate-400" />
        <input
          type="text"
          placeholder="Buscar por Razão Social, Nome Fantasia, E-mail ou Telefone..."
          value={busca}
          onChange={(e) => {
            setBusca(e.target.value);
          }}
          className="bg-transparent border-none outline-none text-white w-full placeholder-slate-500 text-sm"
        />
        {busca && (
          <button onClick={() => setBusca('')} className="text-slate-400 hover:text-white">
            <X className="w-4 h-4" />
          </button>
        )}
      </div>

      {/* Tabela de Empresas */}
      <div className="bg-[#152439] rounded-2xl border border-[#2A405B] overflow-hidden shadow-xl">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-slate-300">
            <thead className="bg-[#0B132B]/80 text-xs uppercase text-slate-400 font-semibold border-b border-[#2A405B]">
              <tr>
                <th className="px-6 py-4">Empresa</th>
                <th className="px-6 py-4">Contato</th>
                <th className="px-6 py-4">Provedor PIX</th>
                <th className="px-6 py-4">Status</th>
                <th className="px-6 py-4 text-right">Ações</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#2A405B]">
              {carregando ? (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-slate-400">
                    <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-500"></div>
                    <p className="mt-2">Carregando empresas...</p>
                  </td>
                </tr>
              ) : empresasFiltradas.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-slate-400">
                    <Building2 className="w-12 h-12 mx-auto text-slate-600 mb-2" />
                    <p className="text-base font-medium text-slate-300">Nenhuma empresa encontrada</p>
                    <p className="text-xs text-slate-500 mt-1">
                      {busca ? 'Tente ajustar os termos da busca.' : 'Clique em "Nova Empresa" para cadastrar a primeira.'}
                    </p>
                  </td>
                </tr>
              ) : (
                empresasFiltradas.map((emp) => (
                  <tr key={emp.id} className="hover:bg-[#1e324d]/40 transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-12 h-12 rounded-xl bg-[#0B132B] border border-[#2A405B] overflow-hidden flex items-center justify-center shrink-0">
                          {emp.logo_url ? (
                            <img
                              src={emp.logo_url}
                              alt={emp.nome_fantasia}
                              className="w-full h-full object-cover"
                            />
                          ) : (
                            <Building2 className="w-6 h-6 text-slate-500" />
                          )}
                        </div>
                        <div>
                          <div className="font-semibold text-white text-base">
                            {emp.nome_fantasia || 'Sem nome fantasia'}
                          </div>
                          <div className="text-xs text-slate-400">
                            {emp.razao_social}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="space-y-1">
                        {emp.telefone ? (
                          <div className="flex items-center gap-1.5 text-xs text-slate-300">
                            <Phone className="w-3.5 h-3.5 text-indigo-400" />
                            {emp.telefone}
                          </div>
                        ) : (
                          <span className="text-xs text-slate-500">Sem telefone</span>
                        )}
                        {emp.email && (
                          <div className="flex items-center gap-1.5 text-xs text-slate-400">
                            <Mail className="w-3.5 h-3.5 text-slate-500" />
                            {emp.email}
                          </div>
                        )}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span className="inline-flex items-center px-2.5 py-1 rounded-lg text-xs font-semibold bg-[#0B132B] border border-[#2A405B] text-indigo-300">
                        {emp.pix_provedor || 'ASAAS'}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <button
                        onClick={() => alternarSituacao(emp)}
                        className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium border transition-colors ${
                          emp.ativo
                            ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20 hover:bg-emerald-500/20'
                            : 'bg-red-500/10 text-red-400 border-red-500/20 hover:bg-red-500/20'
                        }`}
                        title="Clique para alternar o status"
                      >
                        {emp.ativo ? (
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
                        onClick={() => abrirModalEditar(emp)}
                        className="p-2 text-slate-400 hover:text-indigo-400 hover:bg-indigo-500/10 rounded-lg transition-colors"
                        title="Editar Empresa"
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
          <div className="bg-[#152439] border border-[#2A405B] w-full max-w-2xl rounded-2xl shadow-2xl overflow-hidden max-h-[90vh] flex flex-col">
            {/* Modal Header */}
            <div className="px-6 py-4 border-b border-[#2A405B] flex items-center justify-between bg-[#0B132B]/50">
              <h2 className="text-lg font-bold text-white flex items-center gap-2">
                <Building2 className="w-5 h-5 text-indigo-400" />
                {editandoId ? 'Editar Empresa' : 'Nova Empresa'}
              </h2>
              <button
                onClick={fecharModal}
                className="text-slate-400 hover:text-white p-1 rounded-lg hover:bg-[#2A405B]/50 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Body */}
            <form onSubmit={salvarEmpresa} className="flex-1 overflow-y-auto p-6 space-y-6">
              {erro && (
                <div className="p-4 bg-red-500/10 border border-red-500/20 rounded-xl flex items-center gap-3 text-red-400 text-sm">
                  <AlertCircle className="w-5 h-5 shrink-0" />
                  <span>{erro}</span>
                </div>
              )}

              {/* Logotipo da Empresa */}
              <div className="space-y-2">
                <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400">
                  Logotipo da Empresa
                </label>
                <div className="flex items-center gap-5 p-4 rounded-xl bg-[#0B132B] border border-[#2A405B]">
                  <div className="w-20 h-20 rounded-xl bg-[#152439] border border-[#2A405B] overflow-hidden flex items-center justify-center shrink-0 relative group">
                    {logoUrl ? (
                      <img src={logoUrl} alt="Preview do Logo" className="w-full h-full object-cover" />
                    ) : (
                      <ImageIcon className="w-8 h-8 text-slate-600" />
                    )}
                    {enviandoLogo && (
                      <div className="absolute inset-0 bg-black/60 flex items-center justify-center">
                        <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-indigo-400"></div>
                      </div>
                    )}
                  </div>

                  <div className="space-y-2 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <input
                        type="file"
                        ref={inputFileRef}
                        onChange={handleUploadLogo}
                        accept="image/png,image/jpeg,image/webp,image/gif"
                        className="hidden"
                      />
                      <button
                        type="button"
                        onClick={() => inputFileRef.current?.click()}
                        disabled={enviandoLogo}
                        className="inline-flex items-center gap-2 px-3.5 py-1.5 bg-indigo-600/20 hover:bg-indigo-600/30 text-indigo-400 text-xs font-semibold rounded-lg border border-indigo-500/30 transition-colors"
                      >
                        <Upload className="w-3.5 h-3.5" />
                        {enviandoLogo ? 'Enviando...' : logoUrl ? 'Alterar Logo' : 'Enviar Logo'}
                      </button>

                      {logoUrl && (
                        <button
                          type="button"
                          onClick={() => setLogoUrl('')}
                          className="inline-flex items-center gap-1.5 px-3.5 py-1.5 bg-red-500/10 hover:bg-red-500/20 text-red-400 text-xs font-semibold rounded-lg border border-red-500/20 transition-colors"
                        >
                          <X className="w-3.5 h-3.5" />
                          Remover
                        </button>
                      )}
                    </div>
                    <p className="text-xs text-slate-500">
                      Recomendado: Imagem quadrada (JPG, PNG ou WEBP) de até 8MB.
                    </p>
                  </div>
                </div>
              </div>

              {/* Dados Principais */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400">
                    Razão Social <span className="text-red-400">*</span>
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="Ex: Sensor Sistemas LTDA"
                    value={razaoSocial}
                    onChange={(e) => setRazaoSocial(e.target.value)}
                    className="w-full px-3.5 py-2.5 bg-[#0B132B] border border-[#2A405B] rounded-xl text-white placeholder-slate-500 text-sm focus:border-indigo-500 focus:outline-none transition-colors"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400">
                    Nome Fantasia <span className="text-red-400">*</span>
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="Ex: Sensor Delivery Pizzaria"
                    value={nomeFantasia}
                    onChange={(e) => setNomeFantasia(e.target.value)}
                    className="w-full px-3.5 py-2.5 bg-[#0B132B] border border-[#2A405B] rounded-xl text-white placeholder-slate-500 text-sm focus:border-indigo-500 focus:outline-none transition-colors"
                  />
                </div>
              </div>

              {/* Contato */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400">
                    Telefone / WhatsApp
                  </label>
                  <div className="relative">
                    <Phone className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500" />
                    <input
                      type="text"
                      placeholder="Ex: (44) 99999-9999"
                      value={telefone}
                      onChange={(e) => setTelefone(e.target.value)}
                      className="w-full pl-10 pr-3.5 py-2.5 bg-[#0B132B] border border-[#2A405B] rounded-xl text-white placeholder-slate-500 text-sm focus:border-indigo-500 focus:outline-none transition-colors"
                    />
                  </div>
                </div>

                <div className="space-y-1.5">
                  <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400">
                    E-mail
                  </label>
                  <div className="relative">
                    <Mail className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500" />
                    <input
                      type="email"
                      placeholder="Ex: contato@empresa.com"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      className="w-full pl-10 pr-3.5 py-2.5 bg-[#0B132B] border border-[#2A405B] rounded-xl text-white placeholder-slate-500 text-sm focus:border-indigo-500 focus:outline-none transition-colors"
                    />
                  </div>
                </div>
              </div>

              {/* Integrações / Timezone */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400">
                    Provedor de PIX
                  </label>
                  <div className="relative">
                    <Shield className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500" />
                    <select
                      value={pixProvedor}
                      onChange={(e) => setPixProvedor(e.target.value as 'ASAAS' | 'SICREDI')}
                      className="w-full pl-10 pr-3.5 py-2.5 bg-[#0B132B] border border-[#2A405B] rounded-xl text-white text-sm focus:border-indigo-500 focus:outline-none transition-colors appearance-none"
                    >
                      <option value="ASAAS">Asaas</option>
                      <option value="SICREDI">Sicredi</option>
                    </select>
                  </div>
                </div>

                <div className="space-y-1.5">
                  <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400">
                    Fuso Horário (Timezone)
                  </label>
                  <div className="relative">
                    <Globe className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500" />
                    <input
                      type="text"
                      placeholder="America/Sao_Paulo"
                      value={timezone}
                      onChange={(e) => setTimezone(e.target.value)}
                      className="w-full pl-10 pr-3.5 py-2.5 bg-[#0B132B] border border-[#2A405B] rounded-xl text-white placeholder-slate-500 text-sm focus:border-indigo-500 focus:outline-none transition-colors"
                    />
                  </div>
                </div>
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
                  disabled={salvando || enviandoLogo}
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
                      Salvar Empresa
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

export default Empresas;
