import React, { createContext, useContext, useState, useEffect } from 'react';
import { Empresa, LojaStatus } from '../types';
import { ApiService, DEFAULT_EMPRESA_ID } from '../services/api';

interface StoreContextData {
  empresa: Empresa | null;
  statusLoja: LojaStatus | null;
  carregando: boolean;
  erro: string | null;
  recarregarStatus: () => Promise<void>;
  selecionarEmpresa: (empresa: Empresa) => void;
}

const StoreContext = createContext<StoreContextData>({} as StoreContextData);

export const StoreProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [empresa, setEmpresa] = useState<Empresa | null>(null);
  const [statusLoja, setStatusLoja] = useState<LojaStatus | null>(null);
  const [carregando, setCarregando] = useState(true);
  const [erro, setErro] = useState<string | null>(null);

  const carregarEmpresaEStatus = async () => {
    setCarregando(true);
    setErro(null);
    try {
      const empresas = await ApiService.getEmpresas();
      const storedId = await ApiService.getStoredEmpresaId();
      const ativa = empresas.find((e) => e.id === storedId) || empresas[0] || {
        id: DEFAULT_EMPRESA_ID,
        nome: 'Sensor Delivery',
        cidade: 'Bombinhas',
        uf: 'SC',
        endereco: 'Bombinhas - SC',
      };
      setEmpresa(ativa);

      const status = await ApiService.getStatusLoja(ativa.id);
      setStatusLoja(status);
    } catch (err: any) {
      console.warn('Erro ao carregar dados da loja:', err);
      setErro('Não foi possível conectar ao servidor. Mostrando dados locais.');
      setEmpresa({
        id: DEFAULT_EMPRESA_ID,
        nome: 'Sensor Delivery',
        cidade: 'Bombinhas',
        uf: 'SC',
        endereco: 'Bombinhas - SC',
      });
      setStatusLoja({
        aberta: true,
        horarioFuncionamento: '18:00 às 23:30',
        tempoEntregaMin: 35,
        tempoEntregaMax: 50,
      });
    } finally {
      setCarregando(false);
    }
  };

  useEffect(() => {
    carregarEmpresaEStatus();
  }, []);

  const selecionarEmpresa = (novaEmpresa: Empresa) => {
    setEmpresa(novaEmpresa);
    ApiService.setStoredEmpresaId(novaEmpresa.id);
    ApiService.getStatusLoja(novaEmpresa.id).then(setStatusLoja).catch(console.warn);
  };

  return (
    <StoreContext.Provider
      value={{
        empresa,
        statusLoja,
        carregando,
        erro,
        recarregarStatus: carregarEmpresaEStatus,
        selecionarEmpresa,
      }}
    >
      {children}
    </StoreContext.Provider>
  );
};

export const useStore = () => useContext(StoreContext);
