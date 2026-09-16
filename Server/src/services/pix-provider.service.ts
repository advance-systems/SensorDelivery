import { criarQrCodePixAsaas, consultarPagamentoQrCodeAsaas } from './asaas.service.js';
import { criarCobrancaPixSicredi, consultarCobrancaPixSicredi } from './sicredi.service.js';

export type ProvedorPix = 'ASAAS' | 'SICREDI';

export interface PixCriado {
    id: string;
    payload: string;
    imagemBase64: string;
    expiraEm: Date;
}

export function normalizarProvedorPix(valor: unknown): ProvedorPix {
    return String(valor ?? '').trim().toUpperCase() === 'SICREDI'
        ? 'SICREDI'
        : 'ASAAS';
}

export async function criarPix(params: {
    provedor: ProvedorPix;
    chavePix: string;
    pedidoId: string;
    numeroPedido: number;
    valor: number;
    expiracaoSegundos: number;
}): Promise<PixCriado> {
    if (params.provedor === 'SICREDI') {
        const pix = await criarCobrancaPixSicredi(params);
        return { ...pix, imagemBase64: '' };
    }
    return criarQrCodePixAsaas(params);
}

export async function consultarPix(
    provedor: ProvedorPix,
    transacaoId: string,
): Promise<{ recebido: boolean; pagamentoId?: string }> {
    if (provedor === 'SICREDI') {
        return consultarCobrancaPixSicredi(transacaoId);
    }
    const pagamento = await consultarPagamentoQrCodeAsaas(transacaoId);
    return {
        recebido: Boolean(pagamento),
        pagamentoId: pagamento?.id,
    };
}

