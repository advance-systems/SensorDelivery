import { database } from '../database/connection.js';

/**
 * Cancela automaticamente pedidos com status 'RASCUNHO' criados em datas anteriores
 * para empresas que possuem a opção `cancelar_rascunhos_antigos = TRUE`.
 */
export async function cancelarRascunhosAntigos(): Promise<number> {
    try {
        const resultado = await database.query(
            `UPDATE pedidos p
             SET status = 'CANCELADO',
                 motivo_cancelamento = COALESCE(p.motivo_cancelamento, 'Cancelamento automático: rascunho de data anterior.'),
                 atualizado_em = CURRENT_TIMESTAMP
             FROM loja_configuracao lc
             WHERE p.empresa_id = lc.empresa_id
               AND lc.cancelar_rascunhos_antigos = TRUE
               AND p.status = 'RASCUNHO'
               AND p.criado_em < CURRENT_DATE
             RETURNING p.id`
        );

        if ((resultado.rowCount ?? 0) > 0) {
            console.log(`[Pedidos Cleanup] ${resultado.rowCount} pedido(s) em rascunho de dias anteriores foram cancelados automaticamente.`);
        }

        return resultado.rowCount ?? 0;
    } catch (error) {
        console.error('Erro ao executar cancelamento automático de rascunhos antigos:', error);
        return 0;
    }
}
