import React from 'react';
import { useAuth } from '../../context/AuthContext';
import { ShieldAlert } from 'lucide-react';

interface RotaProtegidaProps {
  permissao: string;
  children: React.ReactNode;
}

export const RotaProtegida: React.FC<RotaProtegidaProps> = ({ permissao, children }) => {
  const { temPermissao, carregando } = useAuth();

  if (carregando) return null;

  if (!temPermissao(permissao)) {
    return (
      <div className="flex flex-col items-center justify-center py-20 text-center px-4">
        <div className="w-16 h-16 rounded-2xl bg-[#EF4444]/15 border border-[#EF4444]/30 flex items-center justify-center text-[#EF4444] mb-4 shadow-lg shadow-[#EF4444]/10">
          <ShieldAlert className="w-8 h-8" />
        </div>
        <h2 className="text-xl font-bold text-white mb-1">Acesso Restrito</h2>
        <p className="text-xs text-[#9CAABC] max-w-sm">
          Seu perfil de usuário não possui permissão (<code className="font-mono text-[#8C63FF] bg-[#121E2D] px-1.5 py-0.5 rounded">{permissao}</code>) para acessar este recurso.
        </p>
      </div>
    );
  }

  return <>{children}</>;
};
