import React, { useState, useEffect, useRef, useMemo } from 'react';
import { api } from '../api/client';
import { useFeedback } from '../context/FeedbackContext';
import {
  Users,
  UserPlus,
  ShieldCheck,
  ShieldAlert,
  Search,
  Edit2,
  Lock,
  Mail,
  Building2,
  Check,
  CheckCircle2,
  X,
  AlertCircle,
  Eye,
  EyeOff,
  UserCheck,
  UserX,
  KeyRound,
  Filter,
  Layers,
  ChevronDown,
  Loader2
} from 'lucide-react';

interface EmpresaVinculo {
  id: string;
  nome_fantasia?: string;
  razao_social?: string;
  principal: boolean;
}

interface Usuario {
  id: string;
  nome: string;
  email: string;
  tipo: 'ADMIN' | 'GERENTE' | 'ATENDENTE' | 'COZINHA' | 'ENTREGADOR';
  ativo: boolean;
  ultimo_acesso?: string;
  criado_em: string;
  empresas: EmpresaVinculo[];
}

interface PermissaoCatalogo {
  codigo: string;
  nome: string;
  modulo: string;
  ordem: number;
}

interface EmpresaItem {
  id: string;
  nome_fantasia?: string;
  razao_social?: string;
}

const TIPOS_USUARIO = [
  { valor: 'ADMIN', label: 'Administrador', cor: 'bg-[#8C63FF]/20 text-[#A78BFA] border-[#8C63FF]/30' },
  { valor: 'GERENTE', label: 'Gerente', cor: 'bg-[#3B82F6]/20 text-[#60A5FA] border-[#3B82F6]/30' },
  { valor: 'ATENDENTE', label: 'Atendente', cor: 'bg-[#10B981]/20 text-[#34D399] border-[#10B981]/30' },
  { valor: 'COZINHA', label: 'Cozinha', cor: 'bg-[#F59E0B]/20 text-[#FBBF24] border-[#F59E0B]/30' },
  { valor: 'ENTREGADOR', label: 'Entregador', cor: 'bg-[#EC4899]/20 text-[#F472B6] border-[#EC4899]/30' },
];

export const Usuarios: React.FC = () => {
  const [usuarios, setUsuarios] = useState<Usuario[]>([]);
  const [empresasDisponiveis, setEmpresasDisponiveis] = useState<EmpresaItem[]>([]);
  const [catalogoPermissoes, setCatalogoPermissoes] = useState<PermissaoCatalogo[]>([]);
  const [carregando, setCarregando] = useState(true);
  const [busca, setBusca] = useState('');
  const [filtroTipo, setFiltroTipo] = useState<string>('TODOS');
  const [filtroStatus, setFiltroStatus] = useState<string>('TODOS');

  // Modal Usuário (Novo / Editar)
  const [modalUsuarioAberto, setModalUsuarioAberto] = useState(false);
  const [editandoId, setEditandoId] = useState<string | null>(null);
  const [formNome, setFormNome] = useState('');
  const [formEmail, setFormEmail] = useState('');
  const [formSenha, setFormSenha] = useState('');
  const [formTipo, setFormTipo] = useState<Usuario['tipo']>('ATENDENTE');
  const [formEmpresas, setFormEmpresas] = useState<string[]>([]);
  const [formPrincipalEmpresaId, setFormPrincipalEmpresaId] = useState<string>('');
  const [mostrarSenha, setMostrarSenha] = useState(false);
  const [salvandoUsuario, setSalvandoUsuario] = useState(false);
  const [erroUsuario, setErroUsuario] = useState('');

  // Modal Permissões
  const [modalPermissoesAberto, setModalPermissoesAberto] = useState(false);
  const [usuarioPermissoes, setUsuarioPermissoes] = useState<Usuario | null>(null);
  const [empresaPermissaoSelecionada, setEmpresaPermissaoSelecionada] = useState<string>('');
  const [permissoesAtivas, setPermissoesAtivas] = useState<string[]>([]);
  const [carregandoPermissoes, setCarregandoPermissoes] = useState(false);
  const [salvandoPermissoes, setSalvandoPermissoes] = useState(false);
  const [erroPermissoes, setErroPermissoes] = useState('');

  const nomeInputRef = useRef<HTMLInputElement>(null);
  const { confirmar, notificar } = useFeedback();

  // Foco no nome ao abrir modal de usuário
  useEffect(() => {
    if (modalUsuarioAberto) {
      setTimeout(() => {
        nomeInputRef.current?.focus();
        nomeInputRef.current?.select?.();
      }, 60);
    }
  }, [modalUsuarioAberto]);

  // Carregar dados iniciais
  const carregarDados = async () => {
    try {
      setCarregando(true);
      const [resUsers, resEmpresas, resPermissoes] = await Promise.all([
        api.get('/usuarios'),
        api.get('/empresas'),
        api.get('/permissoes'),
      ]);

      setUsuarios(resUsers.data?.usuarios || []);
      const listaEmp = resEmpresas.data?.empresas || (Array.isArray(resEmpresas.data) ? resEmpresas.data : []);
      setEmpresasDisponiveis(listaEmp);
      setCatalogoPermissoes(resPermissoes.data?.permissoes || []);
    } catch (err: any) {
      console.error('Erro ao carregar usuários:', err);
      notificar(
        err.response?.data?.erro || 'Não foi possível carregar a lista de usuários.',
        'error'
      );
    } finally {
      setCarregando(false);
    }
  };

  useEffect(() => {
    carregarDados();
  }, []);

  // Abrir Modal de Novo Usuário
  const abrirModalNovo = () => {
    setEditandoId(null);
    setFormNome('');
    setFormEmail('');
    setFormSenha('');
    setFormTipo('ATENDENTE');
    setMostrarSenha(false);
    setErroUsuario('');

    if (empresasDisponiveis.length > 0) {
      setFormEmpresas([empresasDisponiveis[0].id]);
      setFormPrincipalEmpresaId(empresasDisponiveis[0].id);
    } else {
      setFormEmpresas([]);
      setFormPrincipalEmpresaId('');
    }

    setModalUsuarioAberto(true);
  };

  // Abrir Modal de Edição
  const abrirModalEditar = (u: Usuario) => {
    setEditandoId(u.id);
    setFormNome(u.nome);
    setFormEmail(u.email);
    setFormSenha('');
    setFormTipo(u.tipo);
    setMostrarSenha(false);
    setErroUsuario('');

    const idsEmp = u.empresas?.map((e) => e.id) || [];
    const princ = u.empresas?.find((e) => e.principal)?.id || idsEmp[0] || '';
    setFormEmpresas(idsEmp);
    setFormPrincipalEmpresaId(princ);

    setModalUsuarioAberto(true);
  };

  // Toggle seleção de empresa no formulário
  const handleToggleEmpresa = (empresaId: string) => {
    setFormEmpresas((prev) => {
      let novaLista: string[];
      if (prev.includes(empresaId)) {
        if (prev.length === 1) return prev; // Mantém ao menos uma
        novaLista = prev.filter((id) => id !== empresaId);
      } else {
        novaLista = [...prev, empresaId];
      }

      if (!novaLista.includes(formPrincipalEmpresaId)) {
        setFormPrincipalEmpresaId(novaLista[0] || '');
      }
      return novaLista;
    });
  };

  // Navegação por Enter no form de usuário
  const handleFormKeyDown = (e: React.KeyboardEvent<HTMLFormElement>) => {
    if (e.key === 'Enter') {
      const target = e.target as HTMLElement;
      if (target.getAttribute('type') === 'submit' || target.tagName.toLowerCase() === 'button') {
        return;
      }

      const form = e.currentTarget;
      const elementosFocaveis = Array.from(
        form.querySelectorAll<HTMLElement>(
          'input:not([type="hidden"]):not([disabled]), select:not([disabled]), button[type="submit"]:not([disabled])'
        )
      );

      const indexAtual = elementosFocaveis.indexOf(target);
      if (indexAtual > -1 && indexAtual < elementosFocaveis.length - 1) {
        e.preventDefault();
        const proximo = elementosFocaveis[indexAtual + 1];
        proximo.focus();
        if (proximo instanceof HTMLInputElement) {
          proximo.select?.();
        }
      }
    }
  };

  // Salvar Usuário (Criar / Atualizar)
  const salvarUsuario = async (e: React.FormEvent) => {
    e.preventDefault();
    setErroUsuario('');

    if (!formNome.trim()) {
      setErroUsuario('Nome é obrigatório.');
      return;
    }
    if (!formEmail.trim()) {
      setErroUsuario('E-mail é obrigatório.');
      return;
    }
    if (!editandoId && (!formSenha || formSenha.length < 6)) {
      setErroUsuario('A senha inicial deve ter pelo menos 6 caracteres.');
      return;
    }
    if (editandoId && formSenha && formSenha.length < 6) {
      setErroUsuario('A nova senha deve ter pelo menos 6 caracteres.');
      return;
    }
    if (formEmpresas.length === 0) {
      setErroUsuario('Selecione pelo menos uma empresa vinculada.');
      return;
    }

    setSalvandoUsuario(true);
    try {
      const payload = {
        nome: formNome.trim(),
        email: formEmail.trim().toLowerCase(),
        senha: formSenha,
        tipo: formTipo,
        empresas: formEmpresas,
        principalEmpresaId: formPrincipalEmpresaId || formEmpresas[0],
      };

      if (editandoId) {
        await api.put(`/usuarios/${editandoId}`, payload);
        notificar('Usuário atualizado com sucesso!', 'success');
      } else {
        await api.post('/usuarios', payload);
        notificar('Novo usuário criado com sucesso!', 'success');
      }

      setModalUsuarioAberto(false);
      carregarDados();
    } catch (err: any) {
      console.error('Erro ao salvar usuário:', err);
      setErroUsuario(
        err.response?.data?.erro ||
        err.response?.data?.mensagem ||
        'Não foi possível salvar o usuário. Verifique os dados e tente novamente.'
      );
    } finally {
      setSalvandoUsuario(false);
    }
  };

  // Alternar Situação Ativo/Inativo
  const alternarSituacao = async (u: Usuario) => {
    const acao = u.ativo ? 'desativar' : 'ativar';
    const confirmado = await confirmar({
      title: `${u.ativo ? 'Desativar' : 'Ativar'} Usuário`,
      message: `Deseja realmente ${acao} o acesso de "${u.nome}"?`,
      confirmText: u.ativo ? 'Sim, Desativar' : 'Sim, Ativar',
    });

    if (!confirmado) return;

    try {
      await api.patch(`/usuarios/${u.id}/situacao`, { ativo: !u.ativo });
      setUsuarios((prev) =>
        prev.map((item) => (item.id === u.id ? { ...item, ativo: !item.ativo } : item))
      );
      notificar(
        `Usuário ${!u.ativo ? 'ativado' : 'desativado'} com sucesso!`,
        'success'
      );
    } catch (err: any) {
      console.error('Erro ao alternar situação:', err);
      notificar(
        err.response?.data?.erro || 'Erro ao alterar situação do usuário.',
        'error'
      );
    }
  };

  // Abrir Modal de Permissões
  const abrirModalPermissoes = async (u: Usuario) => {
    setUsuarioPermissoes(u);
    setErroPermissoes('');
    const empId = u.empresas?.find((e) => e.principal)?.id || u.empresas?.[0]?.id || empresasDisponiveis[0]?.id || '';
    setEmpresaPermissaoSelecionada(empId);
    setModalPermissoesAberto(true);

    if (empId) {
      await carregarPermissoesDoUsuario(u.id, empId);
    }
  };

  // Carregar permissões específicas
  const carregarPermissoesDoUsuario = async (usuarioId: string, empresaId: string) => {
    setCarregandoPermissoes(true);
    try {
      const res = await api.get(`/permissoes/usuario/${usuarioId}?empresaId=${empresaId}`);
      setPermissoesAtivas(res.data?.permissoes || []);
    } catch (err: any) {
      console.error('Erro ao carregar permissões do usuário:', err);
      setErroPermissoes(err.response?.data?.erro || 'Erro ao carregar permissões.');
    } finally {
      setCarregandoPermissoes(false);
    }
  };

  // Mudar empresa no modal de permissões
  const handleMudarEmpresaPermissao = async (novaEmpresaId: string) => {
    setEmpresaPermissaoSelecionada(novaEmpresaId);
    if (usuarioPermissoes) {
      await carregarPermissoesDoUsuario(usuarioPermissoes.id, novaEmpresaId);
    }
  };

  // Toggle permissão individual
  const handleTogglePermissao = (codigo: string) => {
    setPermissoesAtivas((prev) =>
      prev.includes(codigo) ? prev.filter((c) => c !== codigo) : [...prev, codigo]
    );
  };

  // Toggle todas as permissões de um módulo
  const handleToggleModulo = (modulo: string, todasMarcadas: boolean) => {
    const codigosModulo = catalogoPermissoes.filter((p) => p.modulo === modulo).map((p) => p.codigo);
    if (todasMarcadas) {
      setPermissoesAtivas((prev) => prev.filter((c) => !codigosModulo.includes(c)));
    } else {
      setPermissoesAtivas((prev) => [...new Set([...prev, ...codigosModulo])]);
    }
  };

  // Salvar Permissões
  const salvarPermissoes = async () => {
    if (!usuarioPermissoes || !empresaPermissaoSelecionada) return;

    setSalvandoPermissoes(true);
    setErroPermissoes('');
    try {
      await api.put(`/permissoes/usuario/${usuarioPermissoes.id}`, {
        empresaId: empresaPermissaoSelecionada,
        permissoes: permissoesAtivas,
      });

      notificar('Permissões atualizadas com sucesso!', 'success');
      setModalPermissoesAberto(false);
    } catch (err: any) {
      console.error('Erro ao salvar permissões:', err);
      setErroPermissoes(
        err.response?.data?.erro || err.response?.data?.mensagem || 'Erro ao salvar permissões.'
      );
    } finally {
      setSalvandoPermissoes(false);
    }
  };

  // Agrupar catálogo de permissões por módulo
  const modulosAgrupados = catalogoPermissoes.reduce<Record<string, PermissaoCatalogo[]>>((acc, p) => {
    if (!acc[p.modulo]) acc[p.modulo] = [];
    acc[p.modulo].push(p);
    return acc;
  }, {});

  // Filtragem
  const usuariosFiltrados = useMemo(() => {
    return usuarios.filter((u: Usuario) => {
      // Busca
      const matchBusca =
        !busca ||
        u.nome.toLowerCase().includes(busca.toLowerCase()) ||
        u.email.toLowerCase().includes(busca.toLowerCase());

      // Tipo
      const matchTipo = filtroTipo === 'TODOS' || u.tipo === filtroTipo;

      // Status
      const matchStatus =
        filtroStatus === 'TODOS' ||
        (filtroStatus === 'ATIVO' && u.ativo) ||
        (filtroStatus === 'INATIVO' && !u.ativo);

      return matchBusca && matchTipo && matchStatus;
    });
  }, [usuarios, busca, filtroTipo, filtroStatus]);

  // Estatísticas
  const metricas = useMemo(() => {
    const total = usuarios.length;
    const ativos = usuarios.filter((u) => u.ativo).length;
    const administradores = usuarios.filter((u) => u.tipo === 'ADMIN').length;
    const gerenciaEquipe = usuarios.filter((u) => u.tipo !== 'ADMIN').length;
    return { total, ativos, administradores, gerenciaEquipe };
  }, [usuarios]);

  // Labels de tipos
  const getTipoLabel = (tipo: string) => {
    switch (tipo) {
      case 'ADMIN':
        return { label: 'Administrador', bg: 'bg-[#8C63FF]/15', text: 'text-[#A78BFA]', border: 'border-[#8C63FF]/30' };
      case 'GERENTE':
        return { label: 'Gerente', bg: 'bg-[#3B82F6]/15', text: 'text-[#60A5FA]', border: 'border-[#3B82F6]/30' };
      case 'ATENDENTE':
        return { label: 'Atendente', bg: 'bg-[#10B981]/15', text: 'text-[#34D399]', border: 'border-[#10B981]/30' };
      case 'COZINHA':
        return { label: 'Cozinha', bg: 'bg-[#F59E0B]/15', text: 'text-[#FBBF24]', border: 'border-[#F59E0B]/30' };
      case 'ENTREGADOR':
        return { label: 'Entregador', bg: 'bg-[#EC4899]/15', text: 'text-[#F472B6]', border: 'border-[#EC4899]/30' };
      default:
        return { label: tipo, bg: 'bg-[#2A405B]', text: 'text-[#9CAABC]', border: 'border-[#3b5577]' };
    }
  };

  return (
    <div className="space-y-6 animate-fade-in text-[#CBD5E1]">
      {/* Cabeçalho */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-black text-white flex items-center gap-3">
            <Users className="w-7 h-7 text-[#8C63FF]" />
            Usuários & Permissões
          </h1>
          <p className="text-sm text-[#9CAABC] mt-1">
            Cadastre novos colaboradores, associe lojas e gerencie detalhadamente os acessos por módulo.
          </p>
        </div>

        <button
          onClick={abrirModalNovo}
          className="inline-flex items-center justify-center gap-2 px-5 py-2.5 rounded-xl font-bold text-sm bg-gradient-to-r from-[#8C63FF] to-[#6C42E8] hover:from-[#9D77FF] hover:to-[#7C54FA] text-white shadow-lg shadow-[#8C63FF]/20 transition-all hover:scale-[1.02] active:scale-[0.98] cursor-pointer"
        >
          <UserPlus className="w-4 h-4" />
          Novo Usuário
        </button>
      </div>

      {/* Cards de Métricas */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="bg-[#18283B] border border-[#2A405B] rounded-2xl p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-[#9CAABC] uppercase tracking-wider">Total de Usuários</span>
            <Users className="w-4 h-4 text-[#8C63FF]" />
          </div>
          <div className="text-2xl font-black text-white mt-2">{metricas.total}</div>
        </div>

        <div className="bg-[#18283B] border border-[#2A405B] rounded-2xl p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-[#9CAABC] uppercase tracking-wider">Usuários Ativos</span>
            <CheckCircle2 className="w-4 h-4 text-[#10B981]" />
          </div>
          <div className="text-2xl font-black text-white mt-2">{metricas.ativos}</div>
        </div>

        <div className="bg-[#18283B] border border-[#2A405B] rounded-2xl p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-[#9CAABC] uppercase tracking-wider">Administradores</span>
            <ShieldCheck className="w-4 h-4 text-[#A78BFA]" />
          </div>
          <div className="text-2xl font-black text-white mt-2">{metricas.administradores}</div>
        </div>

        <div className="bg-[#18283B] border border-[#2A405B] rounded-2xl p-4 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-[#9CAABC] uppercase tracking-wider">Gerência & Equipe</span>
            <KeyRound className="w-4 h-4 text-[#F59E0B]" />
          </div>
          <div className="text-2xl font-black text-white mt-2">{metricas.gerenciaEquipe}</div>
        </div>
      </div>

      {/* Barra de Filtros e Busca */}
      <div className="bg-[#18283B] border border-[#2A405B] rounded-2xl p-4 flex flex-col md:flex-row gap-3 items-stretch md:items-center justify-between shadow-sm">
        <div className="relative flex-1">
          <Search className="w-4 h-4 text-[#9CAABC] absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
          <input
            type="text"
            value={busca}
            onChange={(e) => setBusca(e.target.value)}
            placeholder="Buscar por nome ou e-mail..."
            className="w-full pl-10 pr-4 py-2 bg-[#121E2D] border border-[#2A405B] rounded-xl text-sm text-white placeholder-[#64748B] focus:outline-none focus:border-[#8C63FF] transition-all"
          />
        </div>

        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 bg-[#121E2D] border border-[#2A405B] rounded-xl px-3 py-1.5 text-xs">
            <Filter className="w-3.5 h-3.5 text-[#9CAABC]" />
            <span className="text-[#9CAABC]">Perfil:</span>
            <select
              value={filtroTipo}
              onChange={(e) => setFiltroTipo(e.target.value)}
              className="bg-transparent text-white font-semibold focus:outline-none cursor-pointer"
            >
              <option value="TODOS" className="bg-[#18283B]">Todos</option>
              <option value="ADMIN" className="bg-[#18283B]">Administrador</option>
              <option value="GERENTE" className="bg-[#18283B]">Gerente</option>
              <option value="ATENDENTE" className="bg-[#18283B]">Atendente</option>
              <option value="COZINHA" className="bg-[#18283B]">Cozinha</option>
              <option value="ENTREGADOR" className="bg-[#18283B]">Entregador</option>
            </select>
          </div>

          <div className="flex items-center gap-2 bg-[#121E2D] border border-[#2A405B] rounded-xl px-3 py-1.5 text-xs">
            <span className="text-[#9CAABC]">Status:</span>
            <select
              value={filtroStatus}
              onChange={(e) => setFiltroStatus(e.target.value)}
              className="bg-transparent text-white font-semibold focus:outline-none cursor-pointer"
            >
              <option value="TODOS" className="bg-[#18283B]">Todos</option>
              <option value="ATIVO" className="bg-[#18283B]">Ativos</option>
              <option value="INATIVO" className="bg-[#18283B]">Inativos</option>
            </select>
          </div>
        </div>
      </div>

      {/* Tabela de Usuários */}
      <div className="bg-[#18283B] border border-[#2A405B] rounded-2xl overflow-hidden shadow-sm">
        {carregando ? (
          <div className="flex flex-col items-center justify-center py-20 text-[#9CAABC] gap-3">
            <Loader2 className="w-8 h-8 animate-spin text-[#8C63FF]" />
            <p className="text-sm font-medium">Carregando usuários...</p>
          </div>
        ) : usuariosFiltrados.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-[#9CAABC] gap-3">
            <Users className="w-12 h-12 text-[#2A405B]" />
            <p className="text-base font-semibold text-white">Nenhum usuário encontrado</p>
            <p className="text-xs text-[#9CAABC] max-w-sm text-center">
              {busca || filtroTipo !== 'TODOS' || filtroStatus !== 'TODOS'
                ? 'Nenhum usuário coincide com os filtros selecionados.'
                : 'Você ainda não possui usuários cadastrados no sistema.'}
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-[#2A405B] bg-[#121E2D]/60 text-xs font-semibold text-[#9CAABC] uppercase tracking-wider">
                  <th className="py-3.5 px-4">Usuário</th>
                  <th className="py-3.5 px-4">Perfil</th>
                  <th className="py-3.5 px-4">Empresas Associadas</th>
                  <th className="py-3.5 px-4 text-center">Status</th>
                  <th className="py-3.5 px-4 text-right">Ações</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#2A405B]/50 text-sm">
                {usuariosFiltrados.map((u: Usuario) => {
                  const tipoStyle = getTipoLabel(u.tipo);
                  return (
                    <tr key={u.id} className="hover:bg-[#1f344d]/50 transition-colors">
                      {/* Nome e E-mail */}
                      <td className="py-3.5 px-4">
                        <div className="flex items-center gap-3">
                          <div className="w-9 h-9 rounded-full bg-[#2A405B] border border-[#3b5577] flex items-center justify-center text-sm font-bold text-[#8C63FF] shrink-0 shadow-xs">
                            {u.nome.charAt(0).toUpperCase()}
                          </div>
                          <div>
                            <div className="font-bold text-sm text-white flex items-center gap-2">
                              <span>{u.nome}</span>
                              {u.tipo === 'ADMIN' && (
                                <span title="Administrador">
                                  <ShieldCheck className="w-3.5 h-3.5 text-[#8C63FF]" />
                                </span>
                              )}
                            </div>
                            <div className="text-[11px] text-[#9CAABC] flex items-center gap-1.5 mt-0.5">
                              <Mail className="w-3 h-3 opacity-60" />
                              <span>{u.email}</span>
                            </div>
                          </div>
                        </div>
                      </td>

                      {/* Perfil */}
                      <td className="py-3.5 px-4">
                        <span
                          className={`px-2.5 py-1 rounded-full text-[11px] font-bold border ${tipoStyle.bg} ${tipoStyle.text} ${tipoStyle.border}`}
                        >
                          {tipoStyle.label}
                        </span>
                      </td>

                      {/* Empresas */}
                      <td className="py-3.5 px-4">
                        <div className="flex flex-wrap gap-1 max-w-xs">
                          {u.empresas && u.empresas.length > 0 ? (
                            u.empresas.map((emp) => (
                              <span
                                key={emp.id}
                                className={`text-[10px] px-2 py-0.5 rounded-md border flex items-center gap-1 ${
                                  emp.principal
                                    ? 'bg-[#8C63FF]/15 border-[#8C63FF]/40 text-white font-semibold'
                                    : 'bg-[#0B132B] border-[#2A405B] text-[#9CAABC]'
                                }`}
                              >
                                <Building2 className="w-2.5 h-2.5 opacity-60" />
                                <span>{emp.nome_fantasia || emp.razao_social || 'Empresa'}</span>
                                {emp.principal && (
                                  <span className="text-[8px] bg-[#8C63FF] text-white px-1 rounded-xs font-bold uppercase">
                                    Principal
                                  </span>
                                )}
                              </span>
                            ))
                          ) : (
                            <span className="text-[11px] text-[#64748B]">Nenhuma empresa</span>
                          )}
                        </div>
                      </td>

                      {/* Status */}
                      <td className="py-3.5 px-4">
                        <button
                          onClick={() => alternarSituacao(u)}
                          className={`px-2.5 py-1 rounded-full text-[10px] font-bold border transition-all cursor-pointer flex items-center gap-1.5 ${
                            u.ativo
                              ? 'bg-[#10B981]/20 text-[#10B981] border-[#10B981]/30 hover:bg-[#EF4444]/20 hover:text-[#EF4444] hover:border-[#EF4444]/30'
                              : 'bg-[#64748B]/20 text-[#9CAABC] border-[#64748B]/30 hover:bg-[#10B981]/20 hover:text-[#10B981] hover:border-[#10B981]/30'
                          }`}
                          title="Clique para alternar situação"
                        >
                          <span
                            className={`w-1.5 h-1.5 rounded-full ${
                              u.ativo ? 'bg-[#10B981]' : 'bg-[#64748B]'
                            }`}
                          />
                          <span>{u.ativo ? 'Ativo' : 'Inativo'}</span>
                        </button>
                      </td>

                      {/* Ações */}
                      <td className="py-3.5 px-4 text-right">
                        <div className="flex items-center justify-end gap-1.5">
                          {/* Permissões */}
                          <button
                            onClick={() => abrirModalPermissoes(u)}
                            className="p-1.5 text-[#9CAABC] hover:text-[#3B82F6] hover:bg-[#3B82F6]/10 rounded-lg transition-colors cursor-pointer"
                            title="Gerenciar Permissões de Acesso"
                          >
                            <KeyRound className="w-4 h-4" />
                          </button>

                          {/* Editar */}
                          <button
                            onClick={() => abrirModalEditar(u)}
                            className="p-1.5 text-[#9CAABC] hover:text-[#8C63FF] hover:bg-[#8C63FF]/10 rounded-lg transition-colors cursor-pointer"
                            title="Editar Usuário"
                          >
                            <Edit2 className="w-4 h-4" />
                          </button>

                          {/* Alternar Ativo/Inativo */}
                          <button
                            onClick={() => alternarSituacao(u)}
                            className={`p-1.5 rounded-lg transition-colors cursor-pointer ${
                              u.ativo
                                ? 'text-[#9CAABC] hover:text-[#EF4444] hover:bg-[#EF4444]/10'
                                : 'text-[#9CAABC] hover:text-[#10B981] hover:bg-[#10B981]/10'
                            }`}
                            title={u.ativo ? 'Desativar Usuário' : 'Ativar Usuário'}
                          >
                            {u.ativo ? <UserX className="w-4 h-4" /> : <UserCheck className="w-4 h-4" />}
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* ================= MODAL NOVO / EDITAR USUÁRIO ================= */}
      {modalUsuarioAberto && (
        <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-[#152439] border border-[#2A405B] rounded-2xl w-full max-w-lg overflow-hidden shadow-2xl animate-in fade-in zoom-in-95 duration-200">
            {/* Header Modal */}
            <div className="p-4 md:p-5 border-b border-[#2A405B] flex items-center justify-between bg-[#121f30]">
              <div className="flex items-center gap-2">
                <UserPlus className="w-5 h-5 text-[#8C63FF]" />
                <h3 className="font-bold text-base text-white">
                  {editandoId ? 'Editar Usuário' : 'Novo Usuário do Sistema'}
                </h3>
              </div>
              <button
                onClick={() => setModalUsuarioAberto(false)}
                className="p-1 text-[#9CAABC] hover:text-white rounded-lg transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Form */}
            <form onSubmit={salvarUsuario} onKeyDown={handleFormKeyDown} className="p-4 md:p-6 space-y-4 max-h-[80vh] overflow-y-auto">
              {erroUsuario && (
                <div className="p-3 bg-[#EF4444]/10 border border-[#EF4444]/30 rounded-xl text-[#EF4444] text-xs flex items-center gap-2">
                  <AlertCircle className="w-4 h-4 shrink-0" />
                  <span>{erroUsuario}</span>
                </div>
              )}

              {/* Nome */}
              <div>
                <label className="block text-xs font-semibold text-[#9CAABC] uppercase tracking-wider mb-1.5">
                  Nome Completo *
                </label>
                <input
                  ref={nomeInputRef}
                  autoFocus
                  type="text"
                  required
                  value={formNome}
                  onChange={(e) => setFormNome(e.target.value)}
                  placeholder="Ex: Carlos Eduardo Silveira"
                  className="w-full bg-[#0B132B] border border-[#2A405B] focus:border-[#8C63FF] text-white rounded-xl px-4 py-2.5 text-xs focus:outline-none transition-colors"
                />
              </div>

              {/* E-mail */}
              <div>
                <label className="block text-xs font-semibold text-[#9CAABC] uppercase tracking-wider mb-1.5">
                  E-mail de Acesso *
                </label>
                <div className="relative">
                  <input
                    type="email"
                    required
                    value={formEmail}
                    onChange={(e) => setFormEmail(e.target.value)}
                    placeholder="carlos@sistemassensor.com.br"
                    className="w-full bg-[#0B132B] border border-[#2A405B] focus:border-[#8C63FF] text-white rounded-xl px-4 py-2.5 pl-10 text-xs focus:outline-none transition-colors"
                  />
                  <Mail className="w-4 h-4 text-[#64748B] absolute left-3.5 top-1/2 -translate-y-1/2" />
                </div>
              </div>

              {/* Senha */}
              <div>
                <label className="block text-xs font-semibold text-[#9CAABC] uppercase tracking-wider mb-1.5">
                  {editandoId ? 'Nova Senha (deixe em branco para manter a atual)' : 'Senha de Acesso *'}
                </label>
                <div className="relative">
                  <input
                    type={mostrarSenha ? 'text' : 'password'}
                    required={!editandoId}
                    value={formSenha}
                    onChange={(e) => setFormSenha(e.target.value)}
                    placeholder={editandoId ? '••••••••' : 'Mínimo de 6 caracteres'}
                    className="w-full bg-[#0B132B] border border-[#2A405B] focus:border-[#8C63FF] text-white rounded-xl px-4 py-2.5 pl-10 pr-11 text-xs focus:outline-none transition-colors"
                  />
                  <Lock className="w-4 h-4 text-[#64748B] absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                  <button
                    type="button"
                    tabIndex={-1}
                    onClick={() => setMostrarSenha(!mostrarSenha)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 p-1 text-[#9CAABC] hover:text-white rounded-lg transition-colors cursor-pointer"
                    title={mostrarSenha ? 'Ocultar senha' : 'Ver senha'}
                  >
                    {mostrarSenha ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              {/* Perfil de Usuário */}
              <div>
                <label className="block text-xs font-semibold text-[#9CAABC] uppercase tracking-wider mb-1.5">
                  Perfil de Acesso *
                </label>
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                  {TIPOS_USUARIO.map((tipo) => (
                    <button
                      key={tipo.valor}
                      type="button"
                      onClick={() => setFormTipo(tipo.valor as Usuario['tipo'])}
                      className={`p-2.5 rounded-xl border text-center transition-all cursor-pointer ${
                        formTipo === tipo.valor
                          ? 'bg-[#8C63FF]/20 border-[#8C63FF] text-white font-bold shadow-sm shadow-[#8C63FF]/30'
                          : 'bg-[#0B132B] border-[#2A405B] text-[#9CAABC] hover:border-[#8C63FF]/40'
                      }`}
                    >
                      <div className="text-xs">{tipo.label}</div>
                    </button>
                  ))}
                </div>
              </div>

              {/* Vínculo com Empresas */}
              <div>
                <label className="block text-xs font-semibold text-[#9CAABC] uppercase tracking-wider mb-1.5">
                  Empresas com Acesso & Empresa Principal *
                </label>
                <div className="space-y-2 max-h-40 overflow-y-auto bg-[#0B132B] border border-[#2A405B] rounded-xl p-3">
                  {empresasDisponiveis.map((emp) => {
                    const vinculada = formEmpresas.includes(emp.id);
                    const ehPrincipal = formPrincipalEmpresaId === emp.id;

                    return (
                      <div
                        key={emp.id}
                        className={`flex items-center justify-between p-2 rounded-lg border transition-colors ${
                          vinculada ? 'bg-[#152439] border-[#2A405B]' : 'bg-transparent border-transparent opacity-60'
                        }`}
                      >
                        <label className="flex items-center gap-2.5 cursor-pointer text-xs select-none">
                          <input
                            type="checkbox"
                            checked={vinculada}
                            onChange={() => handleToggleEmpresa(emp.id)}
                            className="w-4 h-4 accent-[#8C63FF] rounded cursor-pointer"
                          />
                          <span className="font-semibold text-white">
                            {emp.nome_fantasia || emp.razao_social || 'Empresa'}
                          </span>
                        </label>

                        {vinculada && (
                          <label className="flex items-center gap-1.5 cursor-pointer text-[10px] text-[#9CAABC]">
                            <input
                              type="radio"
                              name="empresaPrincipal"
                              checked={ehPrincipal}
                              onChange={() => setFormPrincipalEmpresaId(emp.id)}
                              className="accent-[#8C63FF] cursor-pointer"
                            />
                            <span className={ehPrincipal ? 'text-[#8C63FF] font-bold' : ''}>
                              Principal
                            </span>
                          </label>
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Rodapé do Modal */}
              <div className="pt-4 flex items-center justify-end gap-3 border-t border-[#2A405B]">
                <button
                  type="button"
                  onClick={() => setModalUsuarioAberto(false)}
                  className="px-4 py-2.5 text-xs font-semibold text-[#9CAABC] hover:text-white rounded-xl transition-colors cursor-pointer"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  disabled={salvandoUsuario}
                  className="px-5 py-2.5 bg-gradient-to-r from-[#8C63FF] to-[#7847eb] hover:from-[#7847eb] hover:to-[#6366F1] text-white text-xs font-bold rounded-xl shadow-md shadow-[#8C63FF]/20 transition-all cursor-pointer disabled:opacity-50"
                >
                  {salvandoUsuario ? 'Salvando...' : editandoId ? 'Atualizar Usuário' : 'Criar Usuário'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ================= MODAL DE PERMISSÕES ================= */}
      {modalPermissoesAberto && usuarioPermissoes && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-[#152439] border border-[#2A405B] rounded-2xl w-full max-w-2xl overflow-hidden shadow-2xl animate-in fade-in zoom-in-95 duration-200 flex flex-col max-h-[90vh]">
            {/* Header Modal */}
            <div className="p-4 md:p-5 border-b border-[#2A405B] flex items-center justify-between bg-[#121f30] shrink-0">
              <div className="flex items-center gap-2.5">
                <KeyRound className="w-5 h-5 text-[#3B82F6]" />
                <div>
                  <h3 className="font-bold text-base text-white">
                    Permissões de Acesso &bull; {usuarioPermissoes.nome}
                  </h3>
                  <p className="text-[11px] text-[#9CAABC]">
                    Perfil: <strong className="text-white">{usuarioPermissoes.tipo}</strong> &bull; {usuarioPermissoes.email}
                  </p>
                </div>
              </div>
              <button
                onClick={() => setModalPermissoesAberto(false)}
                className="p-1 text-[#9CAABC] hover:text-white rounded-lg transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Seletor de Empresa para a Permissão */}
            {usuarioPermissoes.empresas && usuarioPermissoes.empresas.length > 1 && (
              <div className="p-3 bg-[#0B132B] border-b border-[#2A405B] flex items-center justify-between gap-3 shrink-0">
                <span className="text-xs font-semibold text-[#9CAABC]">Configurar permissões para a empresa:</span>
                <select
                  value={empresaPermissaoSelecionada}
                  onChange={(e) => handleMudarEmpresaPermissao(e.target.value)}
                  className="bg-[#152439] border border-[#2A405B] text-xs text-white rounded-lg px-3 py-1.5 focus:outline-none focus:border-[#8C63FF] cursor-pointer"
                >
                  {usuarioPermissoes.empresas.map((emp) => (
                    <option key={emp.id} value={emp.id}>
                      {emp.nome_fantasia || emp.razao_social || 'Empresa'}
                    </option>
                  ))}
                </select>
              </div>
            )}

            {/* Conteúdo com os Módulos de Permissão */}
            <div className="p-4 md:p-6 overflow-y-auto space-y-6 flex-1">
              {erroPermissoes && (
                <div className="p-3 bg-[#EF4444]/10 border border-[#EF4444]/30 rounded-xl text-[#EF4444] text-xs flex items-center gap-2">
                  <AlertCircle className="w-4 h-4 shrink-0" />
                  <span>{erroPermissoes}</span>
                </div>
              )}

              {carregandoPermissoes ? (
                <div className="p-8 flex flex-col items-center justify-center text-[#9CAABC] gap-2">
                  <div className="w-6 h-6 border-2 border-[#3B82F6] border-t-transparent rounded-full animate-spin" />
                  <span className="text-xs">Carregando permissões do usuário...</span>
                </div>
              ) : (
                Object.entries(modulosAgrupados).map(([modulo, permissoes]) => {
                  const todosMarcados = permissoes.every((p) => permissoesAtivas.includes(p.codigo));
                  const algunsMarcados = permissoes.some((p) => permissoesAtivas.includes(p.codigo));

                  return (
                    <div
                      key={modulo}
                      className="bg-[#0B132B] border border-[#2A405B] rounded-xl p-4 space-y-3"
                    >
                      {/* Cabeçalho do Módulo */}
                      <div className="flex items-center justify-between border-b border-[#2A405B]/60 pb-2.5">
                        <div className="font-bold text-xs text-white flex items-center gap-2">
                          <span className="w-2 h-2 rounded-full bg-[#8C63FF]" />
                          <span className="uppercase tracking-wider">{modulo}</span>
                        </div>

                        <button
                          type="button"
                          onClick={() => handleToggleModulo(modulo, todosMarcados)}
                          className="text-[10px] text-[#8C63FF] hover:text-[#a78bfa] underline cursor-pointer"
                        >
                          {todosMarcados ? 'Desmarcar Módulo' : 'Marcar Todos'}
                        </button>
                      </div>

                      {/* Lista de Ações do Módulo */}
                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                        {permissoes.map((perm) => {
                          const ativa = permissoesAtivas.includes(perm.codigo);
                          return (
                            <label
                              key={perm.codigo}
                              className={`flex items-start gap-2.5 p-2 rounded-lg border transition-all cursor-pointer select-none ${
                                ativa
                                  ? 'bg-[#152439] border-[#8C63FF]/50 text-white'
                                  : 'bg-[#152439]/40 border-[#2A405B]/50 text-[#9CAABC] hover:border-[#2A405B]'
                              }`}
                            >
                              <input
                                type="checkbox"
                                checked={ativa}
                                onChange={() => handleTogglePermissao(perm.codigo)}
                                className="w-4 h-4 accent-[#8C63FF] rounded mt-0.5 cursor-pointer"
                              />
                              <div className="leading-tight">
                                <div className="text-xs font-semibold">{perm.nome}</div>
                                <div className="text-[9px] opacity-60 font-mono mt-0.5">{perm.codigo}</div>
                              </div>
                            </label>
                          );
                        })}
                      </div>
                    </div>
                  );
                })
              )}
            </div>

            {/* Footer Modal Permissões */}
            <div className="p-4 bg-[#121f30] border-t border-[#2A405B] flex items-center justify-between shrink-0">
              <div className="text-[11px] text-[#9CAABC]">
                <strong className="text-white">{permissoesAtivas.length}</strong> permissão(ões) ativa(s)
              </div>
              <div className="flex items-center gap-3">
                <button
                  type="button"
                  onClick={() => setModalPermissoesAberto(false)}
                  className="px-4 py-2 text-xs font-semibold text-[#9CAABC] hover:text-white rounded-xl transition-colors cursor-pointer"
                >
                  Cancelar
                </button>
                <button
                  type="button"
                  onClick={salvarPermissoes}
                  disabled={salvandoPermissoes}
                  className="px-5 py-2.5 bg-gradient-to-r from-[#3B82F6] to-[#2563EB] hover:from-[#2563EB] hover:to-[#1D4ED8] text-white text-xs font-bold rounded-xl shadow-md shadow-[#3B82F6]/20 transition-all cursor-pointer disabled:opacity-50 flex items-center gap-2"
                >
                  <Check className="w-4 h-4" />
                  <span>{salvandoPermissoes ? 'Salvando...' : 'Salvar Permissões'}</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
export default Usuarios;
