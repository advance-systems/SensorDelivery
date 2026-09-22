import React, { createContext, useContext, useState, useEffect } from 'react';
import { api } from '../api/client';

export interface Usuario {
  id: string | number;
  nome: string;
  email: string;
  tipo?: string;
  admin?: boolean;
  empresa_id?: string | number;
  empresas?: Array<{
    id: string | number;
    nome_fantasia: string;
    razao_social?: string;
    cnpj?: string;
    principal?: boolean;
  }>;
  permissoes?: string[];
}

interface AuthContextType {
  usuario: Usuario | null;
  empresaAtiva: string | null;
  token: string | null;
  estaAutenticado: boolean;
  carregando: boolean;
  login: (token: string, usuario: Usuario, empresas?: any[], permissoes?: string[]) => void;
  logout: () => void;
  selecionarEmpresa: (empresaId: string) => void;
  temPermissao: (permissao: string) => boolean;
}

const AuthContext = createContext<AuthContextType>({} as AuthContextType);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [usuario, setUsuario] = useState<Usuario | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [empresaAtiva, setEmpresaAtiva] = useState<string | null>(null);
  const [carregando, setCarregando] = useState(true);

  useEffect(() => {
    try {
      const savedToken = localStorage.getItem('@SensorDelivery:token');
      const savedUser = localStorage.getItem('@SensorDelivery:usuario');
      const savedEmpresa = localStorage.getItem('@SensorDelivery:empresaId');

      if (savedToken && savedUser) {
        setToken(savedToken);
        const parsedUser = JSON.parse(savedUser);
        setUsuario(parsedUser);

        if (savedEmpresa) {
          setEmpresaAtiva(String(savedEmpresa));
        } else if (parsedUser.empresa_id) {
          setEmpresaAtiva(String(parsedUser.empresa_id));
        }
      }
    } catch (e) {
      console.error('Erro ao restaurar sessão:', e);
    } finally {
      setCarregando(false);
    }
  }, []);

  const login = (newToken: string, novoUsuario: Usuario, empresas?: any[], permissoes?: string[]) => {
    const usuarioCompleto: Usuario = {
      ...novoUsuario,
      empresas: empresas || novoUsuario.empresas || [],
      permissoes: permissoes || novoUsuario.permissoes || [],
    };

    localStorage.setItem('@SensorDelivery:token', newToken);
    localStorage.setItem('@SensorDelivery:usuario', JSON.stringify(usuarioCompleto));

    setToken(newToken);
    setUsuario(usuarioCompleto);

    const empId =
      usuarioCompleto.empresa_id ||
      (usuarioCompleto.empresas && usuarioCompleto.empresas[0]?.id) ||
      null;

    if (empId) {
      setEmpresaAtiva(String(empId));
      localStorage.setItem('@SensorDelivery:empresaId', String(empId));
    }
  };

  const logout = () => {
    localStorage.removeItem('@SensorDelivery:token');
    localStorage.removeItem('@SensorDelivery:usuario');
    localStorage.removeItem('@SensorDelivery:empresaId');
    setToken(null);
    setUsuario(null);
    setEmpresaAtiva(null);
  };

  const selecionarEmpresa = (empresaId: string) => {
    setEmpresaAtiva(empresaId);
    localStorage.setItem('@SensorDelivery:empresaId', String(empresaId));
    window.location.reload(); // Recarrega para reinicializar dados da empresa
  };

  const temPermissao = (permissao: string): boolean => {
    if (!usuario) return false;
    if (usuario.tipo === 'ADMIN' || usuario.admin) return true;
    if (!usuario.permissoes) return false;
    if (Array.isArray(usuario.permissoes)) {
      return usuario.permissoes.includes(permissao);
    }
    return Boolean((usuario.permissoes as Record<string, boolean>)[permissao]);
  };

  return (
    <AuthContext.Provider
      value={{
        usuario,
        empresaAtiva,
        token,
        estaAutenticado: !!token,
        carregando,
        login,
        logout,
        selecionarEmpresa,
        temPermissao,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
