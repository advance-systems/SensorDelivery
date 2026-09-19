import React, { createContext, useContext, useState, useEffect } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { STORAGE_KEYS } from '../services/api';

const CartContext = createContext({});

export const CartProvider = ({ children }) => {
  const [itens, setItens] = useState([]);

  useEffect(() => {
    carregarCarrinho();
  }, []);

  useEffect(() => {
    salvarCarrinho();
  }, [itens]);

  const carregarCarrinho = async () => {
    try {
      const data = await AsyncStorage.getItem(STORAGE_KEYS.CARRINHO);
      if (data) {
        setItens(JSON.parse(data));
      }
    } catch (error) {
      console.warn('Erro ao carregar carrinho:', error);
    }
  };

  const salvarCarrinho = async () => {
    try {
      await AsyncStorage.setItem(STORAGE_KEYS.CARRINHO, JSON.stringify(itens));
    } catch (error) {
      console.warn('Erro ao salvar carrinho:', error);
    }
  };

  const adicionarItem = (novoItem) => {
    const itemComId = {
      ...novoItem,
      id: `${Date.now()}_${Math.random().toString(36).substring(2, 9)}`,
    };
    setItens((prev) => [...prev, itemComId]);
  };

  const removerItem = (id) => {
    setItens((prev) => prev.filter((item) => item.id !== id));
  };

  const atualizarQuantidade = (id, delta) => {
    setItens((prev) =>
      prev
        .map((item) => {
          if (item.id === id) {
            const novaQtd = item.quantidade + delta;
            return novaQtd > 0 ? { ...item, quantidade: novaQtd } : null;
          }
          return item;
        })
        .filter(Boolean)
    );
  };

  const limparCarrinho = () => {
    setItens([]);
  };

  const subtotal = itens.reduce((sum, item) => sum + item.precoUnitario * item.quantidade, 0);
  const totalItens = itens.reduce((sum, item) => sum + item.quantidade, 0);

  return (
    <CartContext.Provider
      value={{
        itens,
        adicionarItem,
        removerItem,
        atualizarQuantidade,
        limparCarrinho,
        subtotal,
        totalItens,
      }}
    >
      {children}
    </CartContext.Provider>
  );
};

export const useCart = () => useContext(CartContext);
