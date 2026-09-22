import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import { FeedbackProvider } from './context/FeedbackContext';
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
import { Usuarios } from './pages/Usuarios';
import { RotaProtegida } from './components/auth/RotaProtegida';

export const App: React.FC = () => {
  return (
    <AuthProvider>
      <FeedbackProvider>
        <BrowserRouter>
          <Routes>
            <Route path="/login" element={<Login />} />

          <Route path="/" element={<AdminLayout />}>
            <Route index element={<RotaProtegida permissao="dashboard.visualizar"><CentralPedidos /></RotaProtegida>} />
            <Route path="dashboard" element={<RotaProtegida permissao="pedidos.visualizar"><Dashboard /></RotaProtegida>} />
            <Route path="categorias" element={<RotaProtegida permissao="categorias.visualizar"><Categorias /></RotaProtegida>} />
            <Route path="produtos" element={<RotaProtegida permissao="cardapio.visualizar"><Produtos /></RotaProtegida>} />
            <Route path="sabores-bordas" element={<RotaProtegida permissao="sabores.visualizar"><SaboresBordas /></RotaProtegida>} />
            <Route path="adicionais" element={<RotaProtegida permissao="cardapio.visualizar"><Adicionais /></RotaProtegida>} />
            <Route path="combos" element={<RotaProtegida permissao="combos.visualizar"><Combos /></RotaProtegida>} />
            <Route path="configuracoes" element={<RotaProtegida permissao="configuracoes.visualizar"><ConfiguracoesLoja /></RotaProtegida>} />
            <Route path="clientes" element={<RotaProtegida permissao="clientes.visualizar"><Clientes /></RotaProtegida>} />
            <Route path="empresas" element={<RotaProtegida permissao="empresas.visualizar"><Empresas /></RotaProtegida>} />
            <Route path="usuarios" element={<RotaProtegida permissao="usuarios.visualizar"><Usuarios /></RotaProtegida>} />
            {/* Fallback de rotas complementares */}
            <Route path="entregadores" element={<RotaProtegida permissao="entregadores.visualizar"><Clientes /></RotaProtegida>} />
          </Route>

          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
      </FeedbackProvider>
    </AuthProvider>
  );
};
export default App;
