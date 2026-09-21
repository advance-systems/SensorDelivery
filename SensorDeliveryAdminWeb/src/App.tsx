import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import { AdminLayout } from './components/layout/AdminLayout';
import { Login } from './pages/Login';
import { CentralPedidos } from './pages/CentralPedidos';
import { Categorias } from './pages/Categorias';
import { Produtos } from './pages/Produtos';
import { SaboresBordas } from './pages/SaboresBordas';
import { ConfiguracoesLoja } from './pages/ConfiguracoesLoja';
import { Clientes } from './pages/Clientes';
import { Empresas } from './pages/Empresas';

export const App: React.FC = () => {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />

          <Route path="/" element={<AdminLayout />}>
            <Route index element={<CentralPedidos />} />
            <Route path="categorias" element={<Categorias />} />
            <Route path="produtos" element={<Produtos />} />
            <Route path="sabores-bordas" element={<SaboresBordas />} />
            <Route path="configuracoes" element={<ConfiguracoesLoja />} />
            <Route path="clientes" element={<Clientes />} />
            <Route path="empresas" element={<Empresas />} />
            {/* Fallback de rotas complementares */}
            <Route path="dashboard" element={<CentralPedidos />} />
            <Route path="adicionais" element={<SaboresBordas />} />
            <Route path="combos" element={<Produtos />} />
            <Route path="entregadores" element={<Clientes />} />
            <Route path="usuarios" element={<ConfiguracoesLoja />} />
          </Route>

          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
};
export default App;
