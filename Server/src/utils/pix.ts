import QRCode from 'qrcode';

export type DadosCobrancaPix = {
    chave: string;
    nomeRecebedor: string;
    cidadeRecebedor: string;
    valor: number;
    txid: string;
};

function campo(id: string, valor: string): string {
    const tamanho = Buffer.byteLength(valor, 'utf8');
    if (tamanho > 99) throw new Error(`Campo PIX ${id} excede o tamanho permitido.`);
    return `${id}${String(tamanho).padStart(2, '0')}${valor}`;
}

function textoPix(valor: string, tamanho: number): string {
    return valor
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .toUpperCase()
        .replace(/[^A-Z0-9 ]/g, ' ')
        .replace(/\s+/g, ' ')
        .trim()
        .slice(0, tamanho);
}

function crc16(payload: string): string {
    let crc = 0xffff;
    for (const byte of Buffer.from(payload, 'utf8')) {
        crc ^= byte << 8;
        for (let bit = 0; bit < 8; bit += 1) {
            crc = (crc & 0x8000) !== 0
                ? ((crc << 1) ^ 0x1021) & 0xffff
                : (crc << 1) & 0xffff;
        }
    }
    return crc.toString(16).toUpperCase().padStart(4, '0');
}

export function gerarPayloadPix(dados: DadosCobrancaPix): string {
    const chave = dados.chave.trim();
    const nome = textoPix(dados.nomeRecebedor, 25);
    const cidade = textoPix(dados.cidadeRecebedor, 15);
    const txid = textoPix(dados.txid, 25).replace(/ /g, '') || '***';

    if (!chave || !nome || !cidade) {
        throw new Error('A configuração PIX da empresa está incompleta.');
    }
    if (!Number.isFinite(dados.valor) || dados.valor <= 0) {
        throw new Error('O valor da cobrança PIX é inválido.');
    }

    const conta = campo('00', 'BR.GOV.BCB.PIX') + campo('01', chave);
    const adicionais = campo('05', txid);
    const semCrc =
        campo('00', '01') +
        campo('01', '11') +
        campo('26', conta) +
        campo('52', '0000') +
        campo('53', '986') +
        campo('54', dados.valor.toFixed(2)) +
        campo('58', 'BR') +
        campo('59', nome) +
        campo('60', cidade) +
        campo('62', adicionais) +
        '6304';

    return semCrc + crc16(semCrc);
}

export async function gerarQrCodePix(payload: string): Promise<string> {
    return QRCode.toDataURL(payload, {
        errorCorrectionLevel: 'M',
        type: 'image/png',
        width: 420,
        margin: 2,
        color: { dark: '#111827', light: '#FFFFFF' },
    });
}
