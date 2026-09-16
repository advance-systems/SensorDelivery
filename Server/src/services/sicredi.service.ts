const SICREDI_TIMEOUT_MS = 15000;

interface SicrediTokenResposta {
    access_token?: string;
    expires_in?: number;
}

interface SicrediCobranca {
    txid?: string;
    status?: string;
    pixCopiaECola?: string;
    calendario?: {
        criacao?: string;
        expiracao?: number;
    };
    pix?: Array<{
        endToEndId?: string;
        valor?: string;
        horario?: string;
    }>;
}

interface SicrediErro {
    title?: string;
    detail?: string;
    violacoes?: Array<{ razao?: string }>;
}

export interface PixSicrediCriado {
    id: string;
    payload: string;
    expiraEm: Date;
}

let tokenCache = '';
let tokenExpiraEm = 0;

function variavelObrigatoria(nome: string): string {
    const valor = process.env[nome]?.trim();
    if (!valor) {
        throw new Error(`${nome} não foi configurada no servidor.`);
    }
    return valor;
}

function authUrl(): string {
    return variavelObrigatoria('SICREDI_AUTH_URL').replace(/\/$/, '');
}

function apiUrl(): string {
    return variavelObrigatoria('SICREDI_API_URL').replace(/\/$/, '');
}

async function obterToken(): Promise<string> {
    if (tokenCache && Date.now() < tokenExpiraEm) {
        return tokenCache;
    }

    const clientId = variavelObrigatoria('SICREDI_CLIENT_ID');
    const clientSecret = variavelObrigatoria('SICREDI_CLIENT_SECRET');
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), SICREDI_TIMEOUT_MS);
    try {
        const resposta = await fetch(authUrl(), {
            method: 'POST',
            signal: controller.signal,
            headers: {
                accept: 'application/json',
                authorization: `Basic ${Buffer.from(`${clientId}:${clientSecret}`).toString('base64')}`,
                'content-type': 'application/x-www-form-urlencoded',
            },
            body: new URLSearchParams({
                grant_type: 'client_credentials',
                scope: 'cob.write cob.read pix.read webhook.write webhook.read',
            }),
        });
        const texto = await resposta.text();
        const dados = texto ? JSON.parse(texto) as SicrediTokenResposta : {};
        if (!resposta.ok || !dados.access_token) {
            throw new Error(`Sicredi OAuth2: HTTP ${resposta.status}.`);
        }
        const duracao = Math.max(120, Number(dados.expires_in ?? 3600));
        tokenCache = dados.access_token;
        tokenExpiraEm = Date.now() + (duracao - 60) * 1000;
        return tokenCache;
    } catch (error) {
        if (error instanceof Error && error.name === 'AbortError') {
            throw new Error('O Sicredi não respondeu durante a autenticação.');
        }
        throw error;
    } finally {
        clearTimeout(timeout);
    }
}

async function requisicaoSicredi<T>(
    caminho: string,
    init: RequestInit = {},
): Promise<T> {
    const token = await obterToken();
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), SICREDI_TIMEOUT_MS);
    try {
        const resposta = await fetch(`${apiUrl()}${caminho}`, {
            ...init,
            signal: controller.signal,
            headers: {
                accept: 'application/json',
                authorization: `Bearer ${token}`,
                'content-type': 'application/json',
                ...(init.headers ?? {}),
            },
        });
        const texto = await resposta.text();
        let dados: unknown = {};
        try {
            dados = texto ? JSON.parse(texto) : {};
        } catch {
            dados = {};
        }
        if (!resposta.ok) {
            const erro = dados as SicrediErro;
            const violacoes = erro.violacoes?.map((item) => item.razao)
                .filter(Boolean).join('; ');
            const detalhe = violacoes || erro.detail || erro.title
                || `HTTP ${resposta.status}`;
            throw new Error(`Sicredi: ${detalhe}`);
        }
        return dados as T;
    } catch (error) {
        if (error instanceof Error && error.name === 'AbortError') {
            throw new Error('O Sicredi não respondeu dentro do tempo esperado.');
        }
        throw error;
    } finally {
        clearTimeout(timeout);
    }
}

export async function criarCobrancaPixSicredi(params: {
    chavePix: string;
    numeroPedido: number;
    valor: number;
    expiracaoSegundos?: number;
}): Promise<PixSicrediCriado> {
    const expiracaoSegundos = params.expiracaoSegundos ?? 300;
    const resposta = await requisicaoSicredi<SicrediCobranca>('/cob', {
        method: 'POST',
        body: JSON.stringify({
            calendario: { expiracao: expiracaoSegundos },
            valor: { original: params.valor.toFixed(2) },
            chave: params.chavePix,
            solicitacaoPagador: `Sensor Delivery - Pedido #${params.numeroPedido}`,
        }),
    });

    const txid = String(resposta.txid ?? '').trim();
    const payload = String(resposta.pixCopiaECola ?? '').trim();
    if (!txid || !payload) {
        throw new Error('O Sicredi não retornou o txid e o código PIX.');
    }
    const criacao = resposta.calendario?.criacao
        ? new Date(resposta.calendario.criacao)
        : new Date();
    const expiraEm = new Date(
        (Number.isNaN(criacao.getTime()) ? Date.now() : criacao.getTime())
        + Number(resposta.calendario?.expiracao ?? expiracaoSegundos) * 1000,
    );
    return { id: txid, payload, expiraEm };
}

export async function consultarCobrancaPixSicredi(
    txid: string,
): Promise<{ recebido: boolean; pagamentoId?: string }> {
    const resposta = await requisicaoSicredi<SicrediCobranca>(
        `/cob/${encodeURIComponent(txid)}`,
    );
    const recebido = String(resposta.status ?? '').toUpperCase() === 'CONCLUIDA';
    return {
        recebido,
        pagamentoId: recebido ? String(resposta.pix?.[0]?.endToEndId ?? '') : undefined,
    };
}

export async function configurarWebhookSicredi(
    chavePix: string,
    webhookUrl: string,
): Promise<void> {
    await requisicaoSicredi(`/webhook/${encodeURIComponent(chavePix)}`, {
        method: 'PUT',
        body: JSON.stringify({ webhookUrl }),
    });
}

