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
      const ativa = (empresas && empresas.length > 0)
        ? (empresas.find((e) => e.id === storedId) || empresas[0])
        : null;

      setEmpresa(ativa);

      if (ativa?.id) {
        const status = await ApiService.getStatusLoja(ativa.id);
        setStatusLoja(status);
      } else {
        setStatusLoja(null);
      }
    } catch (err) {
      console.warn('Erro ao carregar dados da loja:', err);
      setErro('Não foi possível carregar os dados da loja.');
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
