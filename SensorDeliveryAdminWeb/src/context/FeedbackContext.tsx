import React, { createContext, useContext, useState } from 'react';
import { AlertTriangle, CheckCircle2, Info, X, Trash2 } from 'lucide-react';

type DialogType = 'confirm' | 'danger' | 'info' | 'success';

interface ConfirmOptions {
  title?: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  type?: DialogType;
}

interface FeedbackContextData {
  confirmar: (options: ConfirmOptions) => Promise<boolean>;
  notificar: (message: string, type?: 'success' | 'error' | 'info') => void;
}

const FeedbackContext = createContext<FeedbackContextData>({} as FeedbackContextData);

export const FeedbackProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [dialogOpen, setDialogOpen] = useState(false);
  const [dialogConfig, setDialogConfig] = useState<ConfirmOptions>({ message: '' });
  const [resolver, setResolver] = useState<((val: boolean) => void) | null>(null);

  // Toast
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' | 'info' } | null>(null);

  const notificar = (message: string, type: 'success' | 'error' | 'info' = 'info') => {
    setToast({ message, type });
    setTimeout(() => {
      setToast((prev) => (prev?.message === message ? null : prev));
    }, 4000);
  };

  const confirmar = (options: ConfirmOptions): Promise<boolean> => {
    return new Promise((resolve) => {
      setDialogConfig(options);
      setResolver(() => resolve);
      setDialogOpen(true);
    });
  };

  const fecharDialog = (confirmado: boolean) => {
    setDialogOpen(false);
    if (resolver) {
      resolver(confirmado);
      setResolver(null);
    }
  };

  return (
    <FeedbackContext.Provider value={{ confirmar, notificar }}>
      {children}

      {/* Toast Notification */}
      {toast && (
        <div className="fixed bottom-6 right-6 z-50 flex items-center gap-3 px-4 py-3 bg-[#152439] border border-[#2A405B] shadow-2xl rounded-2xl animate-fade-in backdrop-blur-md">
          {toast.type === 'success' && <CheckCircle2 className="w-5 h-5 text-[#10B981]" />}
          {toast.type === 'error' && <AlertTriangle className="w-5 h-5 text-[#EF4444]" />}
          {toast.type === 'info' && <Info className="w-5 h-5 text-[#8C63FF]" />}
          <span className="text-xs font-semibold text-white">{toast.message}</span>
          <button
            onClick={() => setToast(null)}
            className="p-1 text-[#9CAABC] hover:text-white rounded-lg transition-colors cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      )}

      {/* Dialog Modal Moderno */}
      {dialogOpen && (
        <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-xs flex items-center justify-center p-4 animate-fade-in">
          <div className="bg-[#152439] border border-[#2A405B] rounded-3xl w-full max-w-md overflow-hidden shadow-2xl p-6 text-center transform transition-all">
            <div className="mx-auto w-14 h-14 rounded-2xl flex items-center justify-center mb-4 bg-[#EF4444]/10 text-[#EF4444] border border-[#EF4444]/20">
              {dialogConfig.type === 'danger' || !dialogConfig.type ? (
                <Trash2 className="w-7 h-7 text-[#EF4444]" />
              ) : dialogConfig.type === 'success' ? (
                <CheckCircle2 className="w-7 h-7 text-[#10B981]" />
              ) : (
                <AlertTriangle className="w-7 h-7 text-[#F59E0B]" />
              )}
            </div>

            <h3 className="text-lg font-bold text-white mb-2">
              {dialogConfig.title || 'Confirmar Ação'}
            </h3>

            <p className="text-xs text-[#9CAABC] leading-relaxed mb-6">
              {dialogConfig.message}
            </p>

            <div className="flex items-center justify-center gap-3">
              <button
                onClick={() => fecharDialog(false)}
                className="flex-1 py-2.5 px-4 rounded-xl border border-[#2A405B] text-xs font-bold text-[#9CAABC] hover:text-white hover:bg-[#1E3350] transition-colors cursor-pointer"
              >
                {dialogConfig.cancelText || 'Cancelar'}
              </button>
              <button
                onClick={() => fecharDialog(true)}
                className="flex-1 py-2.5 px-4 rounded-xl bg-gradient-to-r from-[#EF4444] to-[#DC2626] hover:from-[#DC2626] hover:to-[#B91C1C] text-white text-xs font-bold shadow-lg shadow-[#EF4444]/25 transition-all cursor-pointer"
              >
                {dialogConfig.confirmText || 'Sim, Excluir'}
              </button>
            </div>
          </div>
        </div>
      )}
    </FeedbackContext.Provider>
  );
};

export const useFeedback = () => useContext(FeedbackContext);
