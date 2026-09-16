const ASAAS_TIMEOUT_MS = 15000;

interface AsaasErroItem {
    description?: string;
}

interface AsaasErroResposta {
    errors?: AsaasErroItem[];
}

interface AsaasQrCodeResposta {
    id?: string;
    payload?: string;
    encodedImage?: string;
    expirationDate?: string;
}

interface AsaasPagamento {
    id?: string;
    status?: string;
    pixQrCodeId?: string;
    value?: number;
}

interface AsaasListaPagamentos {
    data?: AsaasPagamento[];
}

export interface PixAsaasCriado {
    id: string;
    payload: string;
    imagemBase64: string;
    expiraEm: Date;
}

function apiUrl(): string {
    return (process.env.ASAAS_API_URL?.trim()
        || 'https://api-sandbox.asaas.com/v3').replace(/\/$/, '');
}

function apiKey(): string {
    const chave = process.env.ASAAS_API_KEY?.trim();
    if (!chave) {
        throw new Error('ASAAS_API_KEY não foi configurada no servidor.');
    }
    return chave;
}

async function requisicaoAsaas<T>(
    caminho: string,
    init: RequestInit = {},
): Promise<T> {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), ASAAS_TIMEOUT_MS);
    try {
        const resposta = await fetch(`${apiUrl()}${caminho}`, {
            ...init,
            signal: controller.signal,
            headers: {
                accept: 'application/json',
                access_token: apiKey(),
                'content-type': 'application/json',
                'user-agent': 'SensorDelivery/1.0',
                ...(init.headers ?? {}),
            },
        });
        const texto = await resposta.text();
        const dados = texto ? JSON.parse(texto) : {};
        if (!resposta.ok) {
            const erro = dados as AsaasErroResposta;
            const detalhe = erro.errors?.map((item) => item.description)
                .filter(Boolean).join('; ') || `HTTP ${resposta.status}`;
            throw new Error(`Asaas: ${detalhe}`);
        }
        return dados as T;
    } catch (error) {
        if (error instanceof Error && error.name === 'AbortError') {
            throw new Error('O Asaas não respondeu dentro do tempo esperado.');
        }
        throw error;
    } finally {
        clearTimeout(timeout);
    }
}

export async function criarQrCodePixAsaas(params: {
    chavePix: string;
    pedidoId: string;
    numeroPedido: number;
    valor: number;
    expiracaoSegundos?: number;
}): Promise<PixAsaasCriado> {
    const expiracaoSegundos = params.expiracaoSegundos ?? 300;
    const resposta = await requisicaoAsaas<AsaasQrCodeResposta>(
        '/pix/qrCodes/static',
        {
            method: 'POST',
            body: JSON.stringify({
                addressKey: params.chavePix,
                description: `Sensor Delivery - Pedido #${params.numeroPedido}`,
                value: Number(params.valor.toFixed(2)),
                format: 'ALL',
                expirationSeconds: expiracaoSegundos,
                allowsMultiplePayments: false,
                externalReference: params.pedidoId,
            }),
        },
    );

    const id = String(resposta.id ?? '').trim();
    const payload = String(resposta.payload ?? '').trim();
    if (!id || !payload) {
        throw new Error('O Asaas não retornou o identificador e o código PIX.');
    }

    const expiraEm = resposta.expirationDate
        ? new Date(resposta.expirationDate)
        : new Date(Date.now() + expiracaoSegundos * 1000);

    return {
        id,
        payload,
        imagemBase64: String(resposta.encodedImage ?? '').trim(),
        expiraEm: Number.isNaN(expiraEm.getTime())
            ? new Date(Date.now() + expiracaoSegundos * 1000)
            : expiraEm,
    };
}

export async function consultarPagamentoQrCodeAsaas(
    qrCodeId: string,
): Promise<AsaasPagamento | null> {
    const resposta = await requisicaoAsaas<AsaasListaPagamentos>(
        `/payments?pixQrCodeId=${encodeURIComponent(qrCodeId)}&limit=10`,
    );
    const pagamentos = Array.isArray(resposta.data) ? resposta.data : [];
    return pagamentos.find((item) => item.status === 'RECEIVED') ?? null;
}

export function tokenWebhookAsaas(): string {
    return process.env.ASAAS_WEBHOOK_TOKEN?.trim() ?? '';
}

