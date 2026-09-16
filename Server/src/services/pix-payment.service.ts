import type { PoolClient } from 'pg';
import { database } from '../database/connection.js';
import { consultarPix, normalizarProvedorPix, type ProvedorPix } from './pix-provider.service.js';

interface PagamentoPixRow {
    pagamento_id: string;
    pedido_id: string;
    pedido_status: string;
    status_pagamento: string;
    transacao_id: string;
    expira_em: string;
    provedor: string;
}

export type SituacaoPix = 'AGUARDANDO' | 'PAGO' | 'CANCELADO';

async function aprovarPagamento(
    client: PoolClient,
    pagamentoId: string,
    pedidoId: string,
    provedorPagamentoId?: string,
    webhookEventId?: string,
): Promise<void> {
    await client.query(
        `UPDATE pagamentos
            SET status = 'APROVADO',
                dados = dados || jsonb_build_object(
                    'provedor_pagamento_id', $2::text,
                    'webhook_event_id', $3::text,
                    'pix_pago_em', CURRENT_TIMESTAMP
                )
          WHERE id = $1
            AND forma = 'PIX'`,
        [pagamentoId, provedorPagamentoId ?? '', webhookEventId ?? ''],
    );
    await client.query(
        `UPDATE pedidos
            SET status = 'RASCUNHO'
          WHERE id = $1
            AND status IN ('AGUARDANDO_PAGAMENTO', 'CANCELADO')`,
        [pedidoId],
    );
}

async function cancelarPagamento(
    client: PoolClient,
    pagamentoId: string,
    pedidoId: string,
): Promise<void> {
    await client.query(
        `UPDATE pagamentos
            SET status = 'CANCELADO',
                dados = dados || jsonb_build_object(
                    'motivo_cancelamento', 'PIX_EXPIRADO',
                    'pix_cancelado_em', CURRENT_TIMESTAMP
                )
          WHERE id = $1
            AND status = 'PENDENTE'`,
        [pagamentoId],
    );
    await client.query(
        `UPDATE pedidos
            SET status = 'CANCELADO'
          WHERE id = $1
            AND status = 'AGUARDANDO_PAGAMENTO'`,
        [pedidoId],
    );
}

async function buscarPorPedido(pedidoId: string): Promise<PagamentoPixRow | null> {
    const resultado = await database.query<PagamentoPixRow>(
        `SELECT pg.id AS pagamento_id,
                pg.pedido_id,
                p.status::text AS pedido_status,
                pg.status::text AS status_pagamento,
                pg.transacao_id,
                pg.dados->>'pix_expira_em' AS expira_em,
                COALESCE(pg.dados->>'provedor', 'ASAAS') AS provedor
           FROM pagamentos pg
           JOIN pedidos p ON p.id = pg.pedido_id
          WHERE pg.pedido_id = $1
            AND pg.forma = 'PIX'
          ORDER BY pg.criado_em DESC
          LIMIT 1`,
        [pedidoId],
    );
    return resultado.rows[0] ?? null;
}

export async function confirmarPixRecebido(params: {
    transacaoId: string;
    provedorPagamentoId?: string;
    webhookEventId?: string;
}): Promise<boolean> {
    const client = await database.connect();
    try {
        await client.query('BEGIN');
        const resultado = await client.query<PagamentoPixRow>(
            `SELECT pg.id AS pagamento_id, pg.pedido_id
               FROM pagamentos pg
              WHERE pg.transacao_id = $1
                AND pg.forma = 'PIX'
              FOR UPDATE`,
            [params.transacaoId],
        );
        const pagamento = resultado.rows[0];
        if (!pagamento) {
            await client.query('ROLLBACK');
            return false;
        }
        await aprovarPagamento(
            client,
            pagamento.pagamento_id,
            pagamento.pedido_id,
            params.provedorPagamentoId,
            params.webhookEventId,
        );
        await client.query('COMMIT');
        return true;
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
}

export async function sincronizarPagamentoPix(
    pedidoId: string,
): Promise<{ situacao: SituacaoPix; expiraEm: string | null; segundosRestantes: number }> {
    const pagamento = await buscarPorPedido(pedidoId);
    if (!pagamento) {
        throw new Error('Pagamento PIX não encontrado.');
    }

    if (pagamento.status_pagamento === 'APROVADO') {
        return { situacao: 'PAGO', expiraEm: pagamento.expira_em, segundosRestantes: 0 };
    }
    if (pagamento.status_pagamento === 'CANCELADO') {
        return { situacao: 'CANCELADO', expiraEm: pagamento.expira_em, segundosRestantes: 0 };
    }

    const expiraEm = new Date(pagamento.expira_em);
    const segundosRestantes = Math.max(
        0,
        Math.ceil((expiraEm.getTime() - Date.now()) / 1000),
    );

    const provedor = normalizarProvedorPix(pagamento.provedor) as ProvedorPix;
    const consulta = await consultarPix(provedor, pagamento.transacao_id);
    if (consulta.recebido) {
        await confirmarPixRecebido({
            transacaoId: pagamento.transacao_id,
            provedorPagamentoId: consulta.pagamentoId,
        });
        return { situacao: 'PAGO', expiraEm: pagamento.expira_em, segundosRestantes: 0 };
    }

    if (segundosRestantes === 0) {
        const client = await database.connect();
        try {
            await client.query('BEGIN');
            await cancelarPagamento(client, pagamento.pagamento_id, pagamento.pedido_id);
            await client.query('COMMIT');
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
        return { situacao: 'CANCELADO', expiraEm: pagamento.expira_em, segundosRestantes: 0 };
    }

    return {
        situacao: 'AGUARDANDO',
        expiraEm: pagamento.expira_em,
        segundosRestantes,
    };
}

export async function cancelarPixExpirados(): Promise<void> {
    const resultado = await database.query<{ pedido_id: string }>(
        `SELECT pg.pedido_id
           FROM pagamentos pg
           JOIN pedidos p ON p.id = pg.pedido_id
          WHERE pg.forma = 'PIX'
            AND pg.status = 'PENDENTE'
            AND p.status = 'AGUARDANDO_PAGAMENTO'
            AND (pg.dados->>'pix_expira_em')::timestamptz <= CURRENT_TIMESTAMP
          ORDER BY pg.criado_em
          LIMIT 50`,
    );
    for (const item of resultado.rows) {
        try {
            await sincronizarPagamentoPix(item.pedido_id);
        } catch (error) {
            console.error(`Erro ao expirar PIX do pedido ${item.pedido_id}:`, error);
        }
    }
}
