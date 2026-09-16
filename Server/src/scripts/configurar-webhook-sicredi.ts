import 'dotenv/config';
import { database } from '../database/connection.js';
import { configurarWebhookSicredi } from '../services/sicredi.service.js';

interface EmpresaSicredi {
    id: string;
    nome_fantasia: string;
    pix_chave: string;
}

async function executar(): Promise<void> {
    const publicUrl = process.env.API_PUBLIC_URL?.trim().replace(/\/$/, '');
    if (!publicUrl || !publicUrl.startsWith('https://')) {
        throw new Error('API_PUBLIC_URL deve ser uma URL HTTPS pública.');
    }
    const resultado = await database.query<EmpresaSicredi>(
        `SELECT e.id, e.nome_fantasia, lc.pix_chave
           FROM empresas e
           JOIN loja_configuracao lc ON lc.empresa_id = e.id
          WHERE e.ativo = TRUE
            AND e.pix_provedor = 'SICREDI'
            AND NULLIF(TRIM(lc.pix_chave), '') IS NOT NULL
          ORDER BY e.nome_fantasia`,
    );
    if (resultado.rowCount === 0) {
        console.log('Nenhuma empresa ativa com PIX Sicredi configurado.');
        return;
    }
    const webhookUrl = `${publicUrl}/api/webhooks/sicredi`;
    for (const empresa of resultado.rows) {
        await configurarWebhookSicredi(empresa.pix_chave, webhookUrl);
        console.log(`Webhook Sicredi configurado para ${empresa.nome_fantasia}.`);
    }
}

executar()
    .catch((error) => {
        console.error('Falha ao configurar webhook Sicredi:', error);
        process.exitCode = 1;
    })
    .finally(async () => {
        await database.end();
    });

