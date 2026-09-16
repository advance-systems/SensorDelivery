import { Router } from 'express';
import type { PoolClient } from 'pg';
import { database } from '../database/connection.js';
import { empresaIdAutenticada } from '../middleware/auth.middleware.js';

const router = Router();

router.get('/', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    if (!empresaId) return res.status(400).json({ erro: 'empresaId é obrigatório.' });
    try {
        const config = await database.query(
            `SELECT empresa_id, modo_funcionamento, mensagem_fechada,
                    taxa_entrega, pedido_minimo, tempo_entrega_minutos,
                    aceitar_pedidos_automaticamente, imprimir_automaticamente,
                    som_alerta_pedido, pix_chave, pix_nome_recebedor,
                    pix_cidade_recebedor
             FROM loja_configuracao WHERE empresa_id = $1`, [empresaId],
        );
        const horarios = await database.query(
            `SELECT dia_semana, horario_abertura::text, horario_fechamento::text, fechado
             FROM loja_horarios WHERE empresa_id = $1 ORDER BY dia_semana`, [empresaId],
        );
        const configuracao = config.rows[0] ?? {
            empresa_id: empresaId,
            modo_funcionamento: 'AUTOMATICO',
            mensagem_fechada: '',
            taxa_entrega: '0',
            pedido_minimo: '0',
            tempo_entrega_minutos: 45,
            aceitar_pedidos_automaticamente: false,
            imprimir_automaticamente: false,
            som_alerta_pedido: 'NOTIFICACAO',
            pix_chave: '',
            pix_nome_recebedor: '',
            pix_cidade_recebedor: '',
        };
        const horariosLoja = horarios.rowCount === 0
            ? Array.from({ length: 7 }, (_, diaSemana) => ({
                dia_semana: diaSemana,
                horario_abertura: '18:00:00',
                horario_fechamento: '23:00:00',
                fechado: false,
            }))
            : horarios.rows;
        return res.status(200).json({ configuracao, horarios: horariosLoja });
    } catch (error) {
        console.error('Erro ao carregar configurações:', error);
        return res.status(500).json({ erro: 'Não foi possível carregar as configurações.' });
    }
});

function horaValida(valor: string) { return /^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/.test(valor); }

router.put('/', async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const modo = String(req.body.modoFuncionamento ?? '').trim().toUpperCase();
    const mensagem = String(req.body.mensagemFechada ?? '').trim();
    const taxa = Number(req.body.taxaEntrega ?? 0);
    const minimo = Number(req.body.pedidoMinimo ?? 0);
    const tempo = Number(req.body.tempoEntregaMinutos ?? 45);
    const aceitar = Boolean(req.body.aceitarPedidosAutomaticamente);
    const imprimir = Boolean(req.body.imprimirAutomaticamente);
    const somAlerta = String(req.body.somAlertaPedido ?? 'NOTIFICACAO').trim().toUpperCase();
    const pixChave = String(req.body.pixChave ?? '').trim();
    const pixNomeRecebedor = String(req.body.pixNomeRecebedor ?? '').trim();
    const pixCidadeRecebedor = String(req.body.pixCidadeRecebedor ?? '').trim();
    const horarios = Array.isArray(req.body.horarios) ? req.body.horarios : [];
    if (!empresaId) return res.status(400).json({ erro: 'empresaId é obrigatório.' });
    if (!['AUTOMATICO','ABERTO','FECHADO'].includes(modo)) return res.status(400).json({ erro: 'Modo de funcionamento inválido.' });
    if (!Number.isFinite(taxa) || taxa < 0 || !Number.isFinite(minimo) || minimo < 0) return res.status(400).json({ erro: 'Valores financeiros inválidos.' });
    if (!Number.isInteger(tempo) || tempo <= 0) return res.status(400).json({ erro: 'Tempo de entrega inválido.' });
    if (!['NOTIFICACAO','EXCLAMACAO','ASTERISCO','ERRO','SEM_SOM'].includes(somAlerta)) {
        return res.status(400).json({ erro: 'Som do alerta de pedido inválido.' });
    }
    if ((pixChave || pixNomeRecebedor || pixCidadeRecebedor)
        && (!pixChave || !pixNomeRecebedor || !pixCidadeRecebedor)) {
        return res.status(400).json({
            erro: 'Para habilitar o PIX, informe a chave, o nome do recebedor e a cidade.',
        });
    }
    if (pixNomeRecebedor.length > 25 || pixCidadeRecebedor.length > 15) {
        return res.status(400).json({
            erro: 'O nome PIX aceita até 25 caracteres e a cidade até 15 caracteres.',
        });
    }
    if (horarios.length !== 7 || horarios.some((h: any) =>
        !Number.isInteger(Number(h.diaSemana)) || Number(h.diaSemana) < 0 || Number(h.diaSemana) > 6 ||
        !horaValida(String(h.horarioAbertura ?? '')) || !horaValida(String(h.horarioFechamento ?? '')))) {
        return res.status(400).json({ erro: 'Informe horários válidos para os sete dias.' });
    }
    const client: PoolClient = await database.connect();
    try {
        await client.query('BEGIN');
        await client.query(
            `INSERT INTO loja_configuracao
                (empresa_id, modo_funcionamento, mensagem_fechada, taxa_entrega,
                 pedido_minimo, tempo_entrega_minutos,
                 aceitar_pedidos_automaticamente, imprimir_automaticamente,
                 som_alerta_pedido, pix_chave, pix_nome_recebedor,
                 pix_cidade_recebedor)
             VALUES ($1,$2,NULLIF($3,''),$4,$5,$6,$7,$8,$9,
                     NULLIF($10,''),NULLIF($11,''),NULLIF($12,''))
             ON CONFLICT (empresa_id) DO UPDATE SET
                 modo_funcionamento=EXCLUDED.modo_funcionamento,
                 mensagem_fechada=EXCLUDED.mensagem_fechada,
                 taxa_entrega=EXCLUDED.taxa_entrega, pedido_minimo=EXCLUDED.pedido_minimo,
                 tempo_entrega_minutos=EXCLUDED.tempo_entrega_minutos,
                 aceitar_pedidos_automaticamente=EXCLUDED.aceitar_pedidos_automaticamente,
                 imprimir_automaticamente=EXCLUDED.imprimir_automaticamente,
                 som_alerta_pedido=EXCLUDED.som_alerta_pedido,
                 pix_chave=EXCLUDED.pix_chave,
                 pix_nome_recebedor=EXCLUDED.pix_nome_recebedor,
                 pix_cidade_recebedor=EXCLUDED.pix_cidade_recebedor,
                 atualizado_em=CURRENT_TIMESTAMP`,
            [empresaId, modo, mensagem, taxa, minimo, tempo, aceitar, imprimir,
             somAlerta, pixChave, pixNomeRecebedor, pixCidadeRecebedor],
        );
        for (const h of horarios) {
            await client.query(
                `INSERT INTO loja_horarios
                    (empresa_id,dia_semana,horario_abertura,horario_fechamento,fechado)
                 VALUES ($1,$2,$3::time,$4::time,$5)
                 ON CONFLICT (empresa_id,dia_semana) DO UPDATE SET
                    horario_abertura=EXCLUDED.horario_abertura,
                    horario_fechamento=EXCLUDED.horario_fechamento, fechado=EXCLUDED.fechado`,
                [empresaId, Number(h.diaSemana), String(h.horarioAbertura),
                 String(h.horarioFechamento), Boolean(h.fechado)],
            );
        }
        await client.query('COMMIT');
        return res.status(200).json({ mensagem: 'Configurações salvas com sucesso.' });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Erro ao salvar configurações:', error);
        return res.status(500).json({ erro: 'Não foi possível salvar as configurações.' });
    } finally { client.release(); }
});

export default router;
