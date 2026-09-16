import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { api } from '../api/client';
import { Lock, Mail, Store, AlertCircle, ArrowRight } from 'lucide-react';

export const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [senha, setSenha] = useState('');
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
            <div className="w-14 h-14 bg-gradient-to-tr from-[#8C63FF] to-[#6366F1] rounded-2xl mx-auto flex items-center justify-center text-white shadow-xl shadow-[#8C63FF]/30 font-bold text-2xl mb-4">
              S
            </div>
            <h1 className="text-2xl font-extrabold text-white tracking-tight">Sensor Delivery</h1>
            <p className="text-sm text-[#9CAABC] mt-1 font-medium">Acesse o painel de gestão do seu delivery</p>
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
                  type="password"
                  required
                  value={senha}
                  onChange={(e) => setSenha(e.target.value)}
                  placeholder="••••••••"
                  className="w-full bg-[#0B132B] border border-[#2A405B] focus:border-[#8C63FF] text-white rounded-xl px-4 py-3 pl-11 text-sm focus:outline-none transition-colors"
                />
                <Lock className="w-4 h-4 text-[#64748B] absolute left-4 top-1/2 -translate-y-1/2" />
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
