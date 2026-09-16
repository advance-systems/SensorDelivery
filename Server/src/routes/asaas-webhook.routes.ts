import { timingSafeEqual } from 'node:crypto';
import { Router } from 'express';
import { database } from '../database/connection.js';
import { tokenWebhookAsaas } from '../services/asaas.service.js';
import { confirmarPixRecebido } from '../services/pix-payment.service.js';

const router = Router();

function tokenValido(recebido: string, esperado: string): boolean {
    const a = Buffer.from(recebido);
    const b = Buffer.from(esperado);
    return a.length === b.length && timingSafeEqual(a, b);
}

router.post('/', async (req, res) => {
    const esperado = tokenWebhookAsaas();
    const recebido = String(req.header('asaas-access-token') ?? '');
    if (!esperado) {
        console.error('ASAAS_WEBHOOK_TOKEN não foi configurado.');
        return res.status(503).json({ erro: 'Webhook não configurado.' });
    }
    if (!tokenValido(recebido, esperado)) {
        return res.status(401).json({ erro: 'Token do webhook inválido.' });
    }

    const eventoId = String(req.body?.id ?? '').trim();
    const tipo = String(req.body?.event ?? '').trim().toUpperCase();
    if (!eventoId || !tipo) {
        return res.status(400).json({ erro: 'Evento inválido.' });
    }

    const client = await database.connect();
    try {
        await client.query('BEGIN');
        const inserido = await client.query(
            `INSERT INTO asaas_webhook_eventos (evento_id, tipo, payload)
             VALUES ($1, $2, $3::jsonb)
             ON CONFLICT (evento_id) DO NOTHING
             RETURNING evento_id`,
            [eventoId, tipo, JSON.stringify(req.body)],
        );
        await client.query('COMMIT');
        if (inserido.rowCount === 0) {
            return res.status(200).json({ recebido: true, duplicado: true });
        }
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Erro ao registrar webhook Asaas:', error);
        return res.status(500).json({ erro: 'Não foi possível registrar o evento.' });
    } finally {
        client.release();
    }

    try {
        if (tipo === 'PAYMENT_RECEIVED') {
            const qrCodeId = String(req.body?.payment?.pixQrCodeId ?? '').trim();
            const paymentId = String(req.body?.payment?.id ?? '').trim();
            if (qrCodeId) {
                await confirmarPixRecebido({
                    transacaoId: qrCodeId,
                    provedorPagamentoId: paymentId,
                    webhookEventId: eventoId,
                });
            }
        }
        return res.status(200).json({ recebido: true });
    } catch (error) {
        console.error('Erro ao processar webhook Asaas:', error);
        await database.query(
            'DELETE FROM asaas_webhook_eventos WHERE evento_id = $1',
            [eventoId],
        );
        return res.status(500).json({ erro: 'Não foi possível processar o evento.' });
    }
});

export default router;
