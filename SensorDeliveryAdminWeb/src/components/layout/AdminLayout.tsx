import React, { useState } from 'react';
import { Outlet, Navigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { Sidebar } from './Sidebar';
import { Menu, Bell, RefreshCw, Volume2, VolumeX, Store } from 'lucide-react';

export const AdminLayout: React.FC = () => {
  const { estaAutenticado, carregando } = useAuth();
  const [sidebarAberto, setSidebarAberto] = useState(false);
  const [somHabilitado, setSomHabilitado] = useState(true);

  if (carregando) {
    return (
      <div className="min-h-screen bg-[#0B132B] flex flex-col items-center justify-center text-white">
        <div className="w-10 h-10 border-4 border-[#8C63FF] border-t-transparent rounded-full animate-spin mb-4" />
        <p className="text-sm text-[#9CAABC]">Carregando painel...</p>
      </div>
    );
  }

  if (!estaAutenticado) {
    return <Navigate to="/login" replace />;
  }

  return (
    <div className="min-h-screen bg-[#0B132B] text-[#F4F7FB] flex">
      {/* Sidebar Desktop e Mobile */}
      <Sidebar aberto={sidebarAberto} setAberto={setSidebarAberto} />

      {/* Backdrop Mobile */}
      {sidebarAberto && (
        <div
          onClick={() => setSidebarAberto(false)}
          className="fixed inset-0 z-30 bg-black/60 backdrop-blur-xs md:hidden"
        />
      )}

      {/* Área Principal */}
      <div className="flex-1 flex flex-col min-w-0 md:pl-64">
        {/* Header Superior */}
        <header className="h-16 bg-[#152439]/80 backdrop-blur-md border-b border-[#2A405B] sticky top-0 z-20 flex items-center justify-between px-4 md:px-8">
          <div className="flex items-center gap-3">
            <button
              onClick={() => setSidebarAberto(!sidebarAberto)}
              className="p-2 text-[#9CAABC] hover:text-white hover:bg-[#1c2e47] rounded-lg md:hidden transition-colors"
            >
              <Menu className="w-5 h-5" />
            </button>
            <div className="hidden sm:flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-[#10B981] animate-ping" />
              <span className="text-xs font-semibold text-[#10B981]">Loja Aberta para Pedidos</span>
            </div>
          </div>

          {/* Ações Rápidas Header */}
          <div className="flex items-center gap-2">
            <button
              onClick={() => setSomHabilitado(!somHabilitado)}
              title={somHabilitado ? 'Som ativado' : 'Som desativado'}
              className={`p-2 rounded-lg border transition-colors ${
                somHabilitado 
                  ? 'border-[#8C63FF]/30 bg-[#8C63FF]/10 text-[#8C63FF]' 
                  : 'border-[#2A405B] text-[#64748B] hover:text-white'
              }`}
            >
              {somHabilitado ? <Volume2 className="w-4 h-4" /> : <VolumeX className="w-4 h-4" />}
            </button>

            <button
              onClick={() => window.location.reload()}
              title="Atualizar dados"
              className="p-2 text-[#9CAABC] hover:text-white hover:bg-[#1c2e47] rounded-lg border border-[#2A405B] transition-colors"
            >
              <RefreshCw className="w-4 h-4" />
            </button>

            <div className="h-6 w-px bg-[#2A405B] mx-1" />

            <a
              href="https://sensor-delivery-web.espa-o-de-tr-7844.chatgpt.site"
              target="_blank"
              rel="noreferrer"
              className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-[#2A405B]/60 hover:bg-[#2A405B] text-xs font-semibold text-white transition-all border border-[#2A405B]"
            >
              <Store className="w-3.5 h-3.5 text-[#8C63FF]" />
              <span className="hidden sm:inline">Ver Cardápio Web</span>
            </a>
          </div>
        </header>

        {/* Conteúdo Dinâmico da Rota */}
        <main className="flex-1 p-4 md:p-8 overflow-y-auto">
          <Outlet />
        </main>
      </div>
    </div>
  );
};
