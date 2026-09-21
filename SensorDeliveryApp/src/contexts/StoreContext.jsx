import React, { createContext, useContext, useState, useEffect } from 'react';
import { ApiService, DEFAULT_EMPRESA_ID } from '../services/api';

const StoreContext = createContext({});

export const StoreProvider = ({ children }) => {
  const [empresa, setEmpresa] = useState(null);
  const [statusLoja, setStatusLoja] = useState(null);
  const [carregando, setCarregando] = useState(true);
  const [erro, setErro] = useState(null);

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
    } catch (err) {
      console.warn('Erro ao carregar dados da loja:', err);
      setErro('Mostrando dados locais.');
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
    // Timer a cada 30 segundos para alternar Aberto/Fechado no momento exato do relógio
    const timer = setInterval(() => {
      if (empresa?.id) {
        ApiService.getStatusLoja(empresa.id).then(setStatusLoja).catch(console.warn);
      }
    }, 30000);
    return () => clearInterval(timer);
  }, [empresa?.id]);

  const selecionarEmpresa = (novaEmpresa) => {
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
