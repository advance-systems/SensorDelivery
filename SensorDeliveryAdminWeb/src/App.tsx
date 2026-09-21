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
import { Adicionais } from './pages/Adicionais';
import { Combos } from './pages/Combos';
import { Dashboard } from './pages/Dashboard';

export const App: React.FC = () => {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />

          <Route path="/" element={<AdminLayout />}>
            <Route index element={<CentralPedidos />} />
            <Route path="dashboard" element={<Dashboard />} />
            <Route path="categorias" element={<Categorias />} />
            <Route path="produtos" element={<Produtos />} />
            <Route path="sabores-bordas" element={<SaboresBordas />} />
            <Route path="adicionais" element={<Adicionais />} />
            <Route path="combos" element={<Combos />} />
            <Route path="configuracoes" element={<ConfiguracoesLoja />} />
            <Route path="clientes" element={<Clientes />} />
            <Route path="empresas" element={<Empresas />} />
            {/* Fallback de rotas complementares */}
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
