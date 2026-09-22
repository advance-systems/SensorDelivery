import { database } from '../database/connection.js';

/**
 * Verifica se é a primeira execução do dia para as empresas configuradas.
 * Se a opção `cancelar_rascunhos_antigos` estiver ativa e ainda não tiver sido executada hoje
 * (`data_ultimo_cleanup_rascunhos IS NULL OR data_ultimo_cleanup_rascunhos < CURRENT_DATE`),
 * exclui permanentemente todos os pedidos com status 'RASCUNHO' criados em dias anteriores
 * e marca a data atual em `data_ultimo_cleanup_rascunhos`.
 */
export async function verificarEExcluirRascunhosPrimeiraExecucaoDoDia(empresaIdEspecifica?: string): Promise<number> {
    try {
        const filtroEmpresa = empresaIdEspecifica ? 'AND lc.empresa_id = $1' : '';
        const params = empresaIdEspecifica ? [empresaIdEspecifica] : [];

        // 1. Identificar empresas que possuem a opção ativa e ainda não executaram o cleanup hoje
        const empresasElegiveis = await database.query(
            `SELECT lc.empresa_id
             FROM loja_configuracao lc
             WHERE lc.cancelar_rascunhos_antigos = TRUE
               AND (lc.data_ultimo_cleanup_rascunhos IS NULL OR lc.data_ultimo_cleanup_rascunhos < CURRENT_DATE)
               ${filtroEmpresa}`,
            params
        );

        if (empresasElegiveis.rowCount === 0) {
            return 0;
        }

        const idsEmpresas = empresasElegiveis.rows.map((r: { empresa_id: string }) => r.empresa_id);

        // 2. Excluir os pedidos em status 'RASCUNHO' de dias anteriores dessas empresas (cascata limpa itens e pagamentos)
        const resultadoDelete = await database.query(
            `DELETE FROM pedidos
             WHERE empresa_id = ANY($1::uuid[])
               AND status = 'RASCUNHO'
               AND criado_em < CURRENT_DATE
             RETURNING id`,
            [idsEmpresas]
        );

        // 3. Registrar que o cleanup do dia foi concluído para estas empresas
        await database.query(
            `UPDATE loja_configuracao
             SET data_ultimo_cleanup_rascunhos = CURRENT_DATE,
                 atualizado_em = CURRENT_TIMESTAMP
             WHERE empresa_id = ANY($1::uuid[])`,
            [idsEmpresas]
        );

        const totalExcluidos = resultadoDelete.rowCount ?? 0;
        if (totalExcluidos > 0) {
            console.log(`[Pedidos Cleanup] Primeira execução do dia: ${totalExcluidos} pedido(s) em rascunho de dias anteriores foram excluídos.`);
        }

        return totalExcluidos;
    } catch (error) {
        console.error('Erro ao verificar e excluir rascunhos na primeira execução do dia:', error);
        return 0;
    }
}
