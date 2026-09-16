import { createHash } from 'node:crypto';
import { Router } from 'express';
import { database } from '../database/connection.js';
import { consultarPix } from '../services/pix-provider.service.js';
import { confirmarPixRecebido } from '../services/pix-payment.service.js';

const router = Router();

router.post('/', async (req, res) => {
    const notificacoes = Array.isArray(req.body?.pix) ? req.body.pix : [];
    if (notificacoes.length === 0) {
        return res.status(200).json({ recebido: true });
    }

    try {
        for (const pix of notificacoes) {
            const txid = String(pix?.txid ?? '').trim();
            if (!txid) continue;

            // O callback é apenas um aviso. A confirmação real sempre é
            // consultada novamente na API autenticada do Sicredi.
            const consulta = await consultarPix('SICREDI', txid);
            if (!consulta.recebido) continue;

            const eventoId = String(pix?.endToEndId ?? '').trim()
                || createHash('sha256').update(JSON.stringify(pix)).digest('hex');
            const inserido = await database.query(
                `INSERT INTO pix_webhook_eventos (provedor, evento_id, payload)
                 VALUES ('SICREDI', $1, $2::jsonb)
                 ON CONFLICT (provedor, evento_id) DO NOTHING
                 RETURNING evento_id`,
                [eventoId, JSON.stringify(pix)],
            );
            if (inserido.rowCount === 0) continue;

            try {
                await confirmarPixRecebido({
                    transacaoId: txid,
                    provedorPagamentoId: consulta.pagamentoId,
                    webhookEventId: eventoId,
                });
            } catch (error) {
                await database.query(
                    `DELETE FROM pix_webhook_eventos
                      WHERE provedor = 'SICREDI' AND evento_id = $1`,
                    [eventoId],
                );
                throw error;
            }
        }
        return res.status(200).json({ recebido: true });
    } catch (error) {
        console.error('Erro ao processar webhook Sicredi:', error);
        return res.status(500).json({ erro: 'Não foi possível processar o evento.' });
    }
});

export default router;

