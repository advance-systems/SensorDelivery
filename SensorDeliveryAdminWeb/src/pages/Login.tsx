import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { api } from '../api/client';
import { Lock, Mail, Store, AlertCircle, ArrowRight, Eye, EyeOff } from 'lucide-react';

export const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [senha, setSenha] = useState('');
  const [mostrarSenha, setMostrarSenha] = useState(false);
  const [erro, setErro] = useState('');
  const [carregando, setCarregando] = useState(false);

  const { login } = useAuth();
  const navigate = useNavigate();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setErro('');
    setCarregando(true);

    try {
      const response = await api.post('/auth/login', {
        email,
        senha,
      });

      const { token, usuario } = response.data;
      login(token, usuario);
      navigate('/');
    } catch (err: any) {
      console.error('Erro de autenticação:', err);
      if (err.response?.data?.mensagem) {
        setErro(err.response.data.mensagem);
      } else if (err.response?.data?.error) {
        setErro(err.response.data.error);
      } else {
        setErro('Falha na comunicação com a API. Verifique se o servidor está ativo.');
      }
    } finally {
      setCarregando(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#0B132B] flex flex-col justify-center items-center px-4 relative overflow-hidden">
      {/* Luzes de fundo decorativas */}
      <div className="absolute -top-40 -left-40 w-96 h-96 bg-[#8C63FF]/15 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute -bottom-40 -right-40 w-96 h-96 bg-[#3B82F6]/15 rounded-full blur-3xl pointer-events-none" />

      <div className="w-full max-w-md">
        {/* Card Principal */}
        <div className="bg-[#152439] border border-[#2A405B] rounded-2xl p-8 shadow-2xl relative z-10 backdrop-blur-xl">
          {/* Logo / Título */}
          <div className="text-center mb-8">
            <img
              src="/logo-admin.png"
              alt="Sensor Delivery - Painel Administrativo"
              className="h-16 w-auto max-w-full object-contain mx-auto mb-3"
            />
            <p className="text-xs text-[#9CAABC] font-medium">Acesse o painel de gestão do seu delivery</p>
          </div>

          {/* Mensagem de Erro */}
          {erro && (
            <div className="mb-6 p-4 rounded-xl bg-[#EF4444]/10 border border-[#EF4444]/30 flex items-start gap-3 text-[#EF4444] text-xs">
              <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
              <span>{erro}</span>
            </div>
          )}

          {/* Formulário */}
          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-[#9CAABC] uppercase tracking-wider mb-2">
                E-mail ou Usuário
              </label>
              <div className="relative">
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@sistemassensor.com.br"
                  className="w-full bg-[#0B132B] border border-[#2A405B] focus:border-[#8C63FF] text-white rounded-xl px-4 py-3 pl-11 text-sm focus:outline-none transition-colors"
                />
                <Mail className="w-4 h-4 text-[#64748B] absolute left-4 top-1/2 -translate-y-1/2" />
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#9CAABC] uppercase tracking-wider mb-2">
                Senha
              </label>
              <div className="relative">
                <input
                  type={mostrarSenha ? 'text' : 'password'}
                  required
                  value={senha}
                  onChange={(e) => setSenha(e.target.value)}
                  placeholder="••••••••"
                  className="w-full bg-[#0B132B] border border-[#2A405B] focus:border-[#8C63FF] text-white rounded-xl px-4 py-3 pl-11 pr-11 text-sm focus:outline-none transition-colors"
                />
                <Lock className="w-4 h-4 text-[#64748B] absolute left-4 top-1/2 -translate-y-1/2 pointer-events-none" />
                <button
                  type="button"
                  onClick={() => setMostrarSenha((prev) => !prev)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 z-10 text-[#9CAABC] hover:text-white p-1.5 rounded-lg hover:bg-[#2A405B] transition-all focus:outline-none cursor-pointer flex items-center justify-center"
                  title={mostrarSenha ? 'Ocultar senha' : 'Ver senha'}
                >
                  {mostrarSenha ? (
                    <EyeOff className="w-5 h-5" />
                  ) : (
                    <Eye className="w-5 h-5" />
                  )}
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={carregando}
              className="w-full mt-2 bg-gradient-to-r from-[#8C63FF] to-[#7847eb] hover:from-[#7847eb] hover:to-[#6366F1] text-white font-semibold py-3.5 px-4 rounded-xl text-sm shadow-lg shadow-[#8C63FF]/25 hover:shadow-[#8C63FF]/40 transition-all flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
            >
              {carregando ? (
                <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
              ) : (
                <>
                  <span>Entrar no Painel</span>
                  <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>
          </form>
        </div>

        {/* Rodapé da Tela de Login */}
        <div className="text-center mt-6 text-xs text-[#64748B]">
          <p>Sistemas Sensor &copy; 2026 &bull; Versão 1.3.0</p>
        </div>
      </div>
    </div>
  );
};
