import React from 'react';
import { NavLink, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { 
  ShoppingBag, 
  UtensilsCrossed, 
  Layers, 
  Sparkles, 
  PlusCircle, 
  Package, 
  Users, 
  Bike, 
  Settings, 
  ShieldCheck, 
  BarChart3, 
  LogOut,
  Building2,
  Store,
  ChevronDown
} from 'lucide-react';

interface SidebarProps {
  aberto: boolean;
  setAberto: (aberto: boolean) => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ aberto }) => {
  const { usuario, empresaAtiva, selecionarEmpresa, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const navItems = [
    {
      titulo: 'Principal',
      itens: [
        { nome: 'Central de Pedidos', path: '/', icone: ShoppingBag, badge: 'Live' },
        { nome: 'Dashboard & Vendas', path: '/dashboard', icone: BarChart3 },
      ]
    },
    {
      titulo: 'Cardápio & Catálogo',
      itens: [
        { nome: 'Categorias', path: '/categorias', icone: Layers },
        { nome: 'Produtos', path: '/produtos', icone: UtensilsCrossed },
        { nome: 'Sabores & Bordas', path: '/sabores-bordas', icone: Sparkles },
        { nome: 'Adicionais / Opcionais', path: '/adicionais', icone: PlusCircle },
        { nome: 'Combos & Promoções', path: '/combos', icone: Package },
      ]
    },
    {
      titulo: 'Operação',
      itens: [
        { nome: 'Clientes', path: '/clientes', icone: Users },
        { nome: 'Entregadores', path: '/entregadores', icone: Bike },
      ]
    },
    {
      titulo: 'Configurações',
      itens: [
        { nome: 'Configurações da Loja', path: '/configuracoes', icone: Store },
        { nome: 'Usuários & Permissões', path: '/usuarios', icone: ShieldCheck },
        { nome: 'Empresas', path: '/empresas', icone: Building2 },
      ]
    }
  ];

  return (
    <aside className={`fixed inset-y-0 left-0 z-40 w-64 bg-[#152439] border-r border-[#2A405B] flex flex-col transition-transform duration-300 ease-in-out ${
      aberto ? 'translate-x-0' : '-translate-x-full md:translate-x-0'
    }`}>
      {/* Topo / Logo */}
      <div className="h-32 flex items-center justify-center px-1.5 py-2 border-b border-[#2A405B] bg-[#0f1b2b] overflow-hidden">
        <img
          src="/logo-admin.png"
          alt="Sensor Delivery - Painel Administrativo"
          className="w-full h-full max-h-28 object-contain scale-125 transition-transform duration-200"
        />
      </div>

      {/* Seletor de Empresa */}
      {usuario?.empresas && usuario.empresas.length > 0 && (
        <div className="p-3 border-b border-[#2A405B] bg-[#121f30]">
          <label className="text-[10px] font-semibold tracking-wider text-[#9CAABC] uppercase px-2 mb-1 block">
            Empresa Ativa
          </label>
          <div className="relative">
            <select
              value={empresaAtiva || ''}
              onChange={(e) => selecionarEmpresa(e.target.value)}
              className="w-full bg-[#0B132B] border border-[#2A405B] text-xs text-white rounded-lg px-3 py-2 pr-12 appearance-none focus:outline-none focus:border-[#8C63FF] transition-colors cursor-pointer"
            >
              {usuario.empresas.map((emp) => (
                <option key={emp.id} value={emp.id}>
                  {emp.nome_fantasia || emp.razao_social}
                </option>
              ))}
            </select>
            <ChevronDown className="w-4 h-4 text-[#9CAABC] absolute right-6 top-1/2 -translate-y-1/2 pointer-events-none" />
          </div>
        </div>
      )}

      {/* Links de Navegação */}
      <div className="flex-1 overflow-y-auto px-3 py-4 space-y-6">
        {navItems.map((grupo, idx) => (
          <div key={idx} className="space-y-1">
            <h3 className="text-[11px] font-bold text-[#64748B] uppercase tracking-wider px-3 mb-2">
              {grupo.titulo}
            </h3>
            {grupo.itens.map((item) => {
              const Icone = item.icone;
              const isActive = location.pathname === item.path;
              return (
                <NavLink
                  key={item.path}
                  to={item.path}
                  className={`flex items-center justify-between px-3 py-2.5 rounded-xl text-sm font-medium transition-all group ${
                    isActive
                      ? 'bg-gradient-to-r from-[#8C63FF] to-[#7847eb] text-white shadow-md shadow-[#8C63FF]/20 font-semibold'
                      : 'text-[#9CAABC] hover:text-white hover:bg-[#1c2e47]'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <Icone className={`w-4 h-4 transition-colors ${isActive ? 'text-white' : 'text-[#8795A8] group-hover:text-white'}`} />
                    <span>{item.nome}</span>
                  </div>
                  {item.badge && (
                    <span className="px-1.5 py-0.5 text-[10px] font-bold bg-[#10B981]/20 text-[#10B981] border border-[#10B981]/30 rounded-full animate-pulse">
                      {item.badge}
                    </span>
                  )}
                </NavLink>
              );
            })}
          </div>
        ))}
      </div>

      {/* Rodapé Usuário & Logout */}
      <div className="p-3 border-t border-[#2A405B] bg-[#0f1b2b] flex items-center justify-between">
        <div className="flex items-center gap-2.5 overflow-hidden">
          <div className="w-8 h-8 rounded-full bg-[#2A405B] flex items-center justify-center text-xs font-bold text-[#8C63FF] shrink-0">
            {usuario?.nome?.charAt(0).toUpperCase() || 'U'}
          </div>
          <div className="overflow-hidden">
            <p className="text-xs font-semibold text-white truncate">{usuario?.nome || 'Usuário'}</p>
            <p className="text-[10px] text-[#9CAABC] truncate">{usuario?.email || ''}</p>
          </div>
        </div>
        <button
          onClick={handleLogout}
          title="Sair do sistema"
          className="p-2 text-[#9CAABC] hover:text-[#EF4444] hover:bg-[#EF4444]/10 rounded-lg transition-colors shrink-0"
        >
          <LogOut className="w-4 h-4" />
        </button>
      </div>
    </aside>
  );
};
