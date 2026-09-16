import { query } from '../../database/connection.js';
import type { DashboardResumo } from './dashboard.types.js';

interface DashboardResumoRow {
    pedidos_hoje: string;
    faturamento_hoje: string;
    em_preparo: string;
    em_entrega: string;
}

export class DashboardRepository {
    async obterResumo(
        empresaId: string,
    ): Promise<DashboardResumo> {
        const rows = await query<DashboardResumoRow>(
            `
        SELECT
          COUNT(*) FILTER (
            WHERE
              p.criado_em >= CURRENT_DATE
              AND p.criado_em < CURRENT_DATE + INTERVAL '1 day'
              AND p.status NOT IN ('CANCELADO', 'AGUARDANDO_PAGAMENTO')
          ) AS pedidos_hoje,

          COALESCE(
            SUM(p.valor_total) FILTER (
              WHERE
                p.criado_em >= CURRENT_DATE
                AND p.criado_em < CURRENT_DATE + INTERVAL '1 day'
                AND p.status NOT IN (
                  'AGUARDANDO_PAGAMENTO',
                  'RASCUNHO',
                  'AGUARDANDO_CONFIRMACAO',
                  'CANCELADO'
                )
            ),
            0
          ) AS faturamento_hoje,

          COUNT(*) FILTER (
            WHERE p.status = 'EM_PREPARO'
          ) AS em_preparo,

          COUNT(*) FILTER (
            WHERE p.status = 'SAIU_PARA_ENTREGA'
          ) AS em_entrega

        FROM pedidos p
        WHERE p.empresa_id = $1
      `,
            [empresaId],
        );

        const resumo = rows[0];

        return {
            pedidosHoje: Number(resumo?.pedidos_hoje ?? 0),
            faturamentoHoje: Number(
                resumo?.faturamento_hoje ?? 0,
            ),
            emPreparo: Number(resumo?.em_preparo ?? 0),
            emEntrega: Number(resumo?.em_entrega ?? 0),
        };
    }
}
