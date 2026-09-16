import { Router } from 'express';
import { database } from '../database/connection.js';
import { autenticarToken, empresaIdAutenticada } from '../middleware/auth.middleware.js';
import { exigirAcessoModulo } from '../middleware/permission.middleware.js';
import { gerarQrCodePix } from '../utils/pix.js';
import { criarPix, normalizarProvedorPix, type ProvedorPix } from '../services/pix-provider.service.js';
import { sincronizarPagamentoPix } from '../services/pix-payment.service.js';

const router = Router();

const statusPermitidos = [
    'RASCUNHO',
    'AGUARDANDO_PAGAMENTO',
    'AGUARDANDO_CONFIRMACAO',
    'CONFIRMADO',
    'EM_PREPARO',
    'PRONTO',
    'SAIU_PARA_ENTREGA',
    'ENTREGUE',
    'CANCELADO',
];

function normalizarFormaPagamento(valor: unknown): string {
    const forma = String(valor ?? '')
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .trim()
        .toUpperCase();

    if (forma === 'PIX') return 'PIX';
    if (forma === 'DINHEIRO') return 'DINHEIRO';
    if (forma.includes('CREDITO')) return 'CARTAO_CREDITO';
    if (forma.includes('DEBITO')) return 'CARTAO_DEBITO';
    if (forma === 'ONLINE') return 'ONLINE';
    return 'OUTRO';
}

router.get('/', autenticarToken, exigirAcessoModulo('pedidos'), async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    try {
        const resultado = await database.query(
            `
            SELECT
              p.id,
              p.numero,
              p.cliente_nome,
              p.cliente_telefone,
              p.tipo_atendimento,
              p.endereco_texto,
              p.status,
              p.subtotal,
              p.taxa_entrega,
              p.desconto,
              p.acrescimo,
              p.valor_total,
              p.observacoes,
              p.criado_em,
              COALESCE(
                (SELECT pg.forma::text FROM pagamentos pg WHERE pg.pedido_id = p.id ORDER BY pg.id DESC LIMIT 1),
                'PIX'
              ) AS forma_pagamento,
              COALESCE(
                (SELECT (pg.dados->>'troco_para')::numeric FROM pagamentos pg WHERE pg.pedido_id = p.id ORDER BY pg.id DESC LIMIT 1),
                0
              ) AS troco_para,

            COALESCE(
              (  
                SELECT string_agg(
                  TRIM(TRAILING '.000' FROM pi.quantidade::text)
                  || 'x '
                  || pi.produto_nome

                  || CASE
                      WHEN EXISTS (
                        SELECT 1
                        FROM pedido_item_sabores pis
                        WHERE pis.pedido_item_id = pi.id
                      )
                    THEN
                      ' ('
                      || (
                          SELECT string_agg(
                              pis.sabor_descricao,
                              ', '
                              ORDER BY pis.id
                          )
                          FROM pedido_item_sabores pis
                          WHERE pis.pedido_item_id = pi.id
                        )
                        || ')'
                    ELSE ''
                    END

                  || CASE
                      WHEN COALESCE(pi.borda_descricao, '') <> ''
                            AND UPPER(pi.borda_descricao) <> 'SEM BORDA'
                     THEN
                        E'\n• Borda: '
                        || pi.borda_descricao
                     ELSE ''
                     END,

                  E'\n'
                  ORDER BY pi.id
                )
              FROM pedido_itens pi
              WHERE pi.pedido_id = p.id
          ),
          ''
        ) AS itens_resumo

            FROM pedidos p
            WHERE p.empresa_id = $1
              AND p.status NOT IN ('CANCELADO', 'AGUARDANDO_PAGAMENTO')
            ORDER BY p.numero DESC
            LIMIT 100
            `,
            [empresaId],
        );

        const resultadoResumo = await database.query(
          `
            SELECT
              COUNT(*) FILTER (
                 WHERE p.status IN (
                    'RASCUNHO',
                    'AGUARDANDO_CONFIRMACAO'
                 )
              ) AS novos,

              COUNT(*) FILTER (
                 WHERE p.status = 'EM_PREPARO'
              ) AS em_preparo,

              COUNT(*) FILTER (
                 WHERE p.status = 'PRONTO'
              ) AS prontos,

              COUNT(*) FILTER (
                 WHERE p.status = 'SAIU_PARA_ENTREGA'
              ) AS em_entrega,

              COUNT(*) FILTER (
                 WHERE p.status = 'ENTREGUE'
                    AND p.criado_em >= CURRENT_DATE
                    AND p.criado_em < CURRENT_DATE + INTERVAL '1 day'
              ) AS finalizados,

              COALESCE(
                  SUM(p.valor_total) FILTER (
                      WHERE p.criado_em >= CURRENT_DATE
                        AND p.criado_em <
                            CURRENT_DATE + INTERVAL '1 day'
                        AND p.status NOT IN (
                            'AGUARDANDO_PAGAMENTO',
                            'RASCUNHO',
                            'AGUARDANDO_CONFIRMACAO',
                            'CANCELADO'
                        )
                  ),
                  0
              ) AS faturamento_hoje

          FROM pedidos p
          WHERE p.empresa_id = $1
          `,
          [empresaId],
        );

        return res.status(200).json({
          pedidos: resultado.rows,
          resumo: resultadoResumo.rows[0],
        });
    } catch (error) {
        console.error(
            'Erro ao listar pedidos:',
            error
        );

        const mensagem =
            error instanceof Error
                ? error.message
                : 'Erro desconhecido';

        return res.status(500).json({
            erro: 'Não foi possível listar os pedidos.',
            detalhe: mensagem,
        });
    }
});

router.get('/historico', async (req, res) => {
    const empresaId = String(
        req.query.empresaId ?? ''
    ).trim();

    const telefone = String(
        req.query.telefone ?? ''
    ).trim();

    const diasInformados = Number(
        req.query.dias ?? 30
    );

    const dias = Math.min(
        Math.max(
            Number.isFinite(diasInformados)
                ? Math.trunc(diasInformados)
                : 30,
            1
        ),
        365
    );

    if (!empresaId) {
        return res.status(400).json({
            erro: 'empresaId é obrigatório.',
        });
    }

    if (!telefone) {
        return res.status(400).json({
            erro: 'telefone é obrigatório.',
        });
    }

    try {
        const resultadoPedidos =
            await database.query(
                `
                SELECT
                    p.id,
                    p.numero,
                    p.status,
                    p.tipo_atendimento,
                    p.subtotal,
                    p.taxa_entrega,
                    p.desconto,
                    p.acrescimo,
                    p.valor_total,
                    p.observacoes,
                    p.criado_em
                FROM pedidos p
                WHERE p.empresa_id = $1
                  AND p.cliente_telefone = $2
                  AND p.criado_em >=
                      CURRENT_TIMESTAMP -
                      ($3 * INTERVAL '1 day')
                ORDER BY p.criado_em DESC
                LIMIT 100
                `,
                [
                    empresaId,
                    telefone,
                    dias,
                ]
            );

        const pedidos = [];

        for (const pedido of resultadoPedidos.rows) {
            const resultadoItens =
                await database.query(
                    `
                    SELECT
                      pi.id,
                      pi.produto_id,

                      pi.produto_nome
                        AS produto_descricao,

                      pi.variacao_id
                        AS tamanho_id,

                      pi.variacao_nome
                        AS tamanho_descricao,

                      pi.quantidade,
                      pi.valor_unitario,
                      pi.valor_adicionais,
                      pi.valor_total,
                      pi.observacoes,
                      pi.borda_id,
                      pi.borda_descricao,
                      pi.valor_borda
                    FROM pedido_itens pi
                    WHERE pi.pedido_id = $1
                    ORDER BY pi.criado_em, pi.id
                    `,
                    [pedido.id]
                );

            const itens = [];

            for (const item of resultadoItens.rows) {
                const resultadoSabores =
                    await database.query(
                        `
                        SELECT
                            pis.sabor_id AS id,
                            pis.sabor_descricao AS descricao,
                            pis.valor
                        FROM pedido_item_sabores pis
                        WHERE pis.pedido_item_id = $1
                        ORDER BY pis.id
                        `,
                        [item.id]
                    );

                itens.push({
                    ...item,
                    sabores: resultadoSabores.rows,
                });
            }

            const totalItens = itens.reduce(
              (total, item) =>
                  total + Number(item.valor_total ?? 0), 0
            );

            const taxaEntregaHistorico = Number(pedido.taxa_entrega ?? 0);

            const subtotalHistorico = Number(pedido.subtotal ?? 0) > 0
              ? Number(pedido.subtotal)
              : totalItens;

            const valorTotalHistorico =
              Number(pedido.valor_total ?? 0) > 0
                  ? Number(pedido.valor_total)
                  : subtotalHistorico +
                    taxaEntregaHistorico;

            pedidos.push({
                ...pedido,
                subtotal: subtotalHistorico,
                valor_total: valorTotalHistorico,
                itens,
            });
        }

        return res.status(200).json({
            periodo_dias: dias,
            pedidos,
        });
    } catch (error) {
        console.error(
            'Erro ao carregar histórico de pedidos:',
            error
        );

        const mensagem =
            error instanceof Error
                ? error.message
                : 'Erro desconhecido';

        return res.status(500).json({
            erro:
                'Não foi possível carregar o histórico de pedidos.',
            detalhe: mensagem,
        });
    }
});

router.post('/', async (req, res) => {
    const client = await database.connect();

    try {
         const {
            empresaId,
            clienteId,
            clienteNome,
            clienteTelefone,
            tipoAtendimento,
            endereco = {},
            observacao,
            valores = {},
            pagamento = {},
            itens,
        } = req.body;

        let respostaPix: {
            copiaCola: string;
            qrCodeBase64: string;
            valor: number;
            txid: string;
            expiraEm: string;
        } | null = null;

        const subtotal = Number(
            valores.subtotal ?? 0
        );

        const taxaEntrega = Number(
            valores.taxa_entrega ?? 0
        );

        const desconto = Number(
            valores.desconto ?? 0
        );

        const acrescimo = Number(
            valores.acrescimo ?? 0
        );

        const valorTotal = Number(
            valores.total ?? 0
        );

        const observacoes =
            String(observacao ?? '').trim() ||
            null;

        const enderecoTexto =
            String(
                tipoAtendimento ?? ''
            ).toUpperCase() === 'ENTREGA'
                ? [
                      endereco.logradouro,
                      endereco.numero,
                      endereco.bairro,
                      endereco.complemento,
                      endereco.referencia,
                      endereco.cep,
                  ]
                      .filter(Boolean)
                      .join(', ')
                : null;


        // =========================================================
        // VALIDAÇÕES
        // =========================================================

        if (!empresaId) {
            return res.status(400).json({
                erro: 'empresaId é obrigatório.',
            });
        }

        if (!String(clienteNome ?? '').trim()) {
            return res.status(400).json({
                erro: 'clienteNome é obrigatório.',
            });
        }

        if (!String(clienteTelefone ?? '').trim()) {
            return res.status(400).json({
                erro: 'clienteTelefone é obrigatório.',
            });
        }

        if (
            !['ENTREGA', 'RETIRADA'].includes(
                String(tipoAtendimento ?? '').toUpperCase()
            )
        ) {
            return res.status(400).json({
                erro: 'tipoAtendimento inválido.',
            });
        }

        if (!Array.isArray(itens) || itens.length === 0) {
            return res.status(400).json({
                erro: 'O pedido precisa possuir pelo menos um item.',
            });
        }

        const formaPagamento = normalizarFormaPagamento(pagamento.forma);
        let configuracaoPix: {
            pix_chave: string;
            pix_provedor: string;
        } | null = null;

        if (formaPagamento === 'PIX') {
            const resultadoPix = await client.query(
                `SELECT lc.pix_chave, e.pix_provedor
                   FROM loja_configuracao lc
                   JOIN empresas e ON e.id = lc.empresa_id
                  WHERE lc.empresa_id = $1
                  LIMIT 1`,
                [empresaId],
            );
            configuracaoPix = resultadoPix.rows[0] ?? null;
            if (!configuracaoPix?.pix_chave) {
                return res.status(400).json({
                    erro: 'O PIX ainda não foi configurado para esta empresa.',
                });
            }
        }

        // =========================================================
        // INICIA A TRANSAÇÃO
        // =========================================================

        await client.query('BEGIN');

        let clienteIdFinal = clienteId || null;

        if (!clienteIdFinal) {
            const clienteExistente = await client.query(
                `
        SELECT id
        FROM clientes
        WHERE empresa_id = $1
          AND telefone = $2
        LIMIT 1
        `,
                [
                    empresaId,
                    String(clienteTelefone).trim(),
                ],
            );

            if ((clienteExistente.rowCount ?? 0) > 0) {
                clienteIdFinal = clienteExistente.rows[0].id;
            } else {
                const novoCliente = await client.query(
                    `
            INSERT INTO clientes (
                empresa_id,
                nome,
                telefone
            )
            VALUES (
                $1,
                $2,
                $3
            )
            RETURNING id
            `,
                    [
                        empresaId,
                        String(clienteNome).trim(),
                        String(clienteTelefone).trim(),
                    ],
                );

                clienteIdFinal = novoCliente.rows[0].id;
            }
        }

        // =========================================================
        // PEDIDO
        // =========================================================

        const resultadoPedido = await client.query(
            `
            INSERT INTO pedidos (
                empresa_id,
                cliente_id,
                cliente_nome,
                cliente_telefone,
                tipo_atendimento,
                endereco_texto,
                observacoes,
                subtotal,
                taxa_entrega,
                desconto,
                acrescimo,
                valor_total,
                status
            )
            VALUES (
                $1,
                $2,
                $3,
                $4,
                $5,
                $6,
                $7,
                $8,
                $9,
                $10,
                $11,
                $12,
                $13::status_pedido
            )
            RETURNING
                id,
                numero,
                status,
                criado_em
            `,
            [
                empresaId,
                clienteIdFinal,
                String(clienteNome).trim(),
                String(clienteTelefone).trim(),
                String(tipoAtendimento).toUpperCase(),
                enderecoTexto || null,
                observacoes || null,
                Number(subtotal || 0),
                Number(taxaEntrega || 0),
                Number(desconto || 0),
                Number(acrescimo || 0),
                Number(valorTotal || 0),
                formaPagamento === 'PIX' ? 'AGUARDANDO_PAGAMENTO' : 'RASCUNHO',
            ],
        );

        const pedido = resultadoPedido.rows[0];

        // =========================================================
        // ITENS DO PEDIDO
        // =========================================================

        for (const item of itens) {
            let valorAdicionais = 0;

            // Calcula o valor total dos adicionais
            if (Array.isArray(item.adicionais)) {
                for (const adicional of item.adicionais) {
                    const quantidadeAdicional = Number(
                        adicional.quantidade || 1
                    );

                    const valorAdicional = Number(
                        adicional.valor || 0
                    );

                    valorAdicionais +=
                        quantidadeAdicional * valorAdicional;
                }
            }

            const resultadoItem = await client.query(
                `
                INSERT INTO pedido_itens (
                    pedido_id,
                    produto_id,
                    variacao_id,
                    produto_nome,
                    variacao_nome,
                    quantidade,
                    valor_unitario,
                    valor_adicionais,
                    valor_total,
                    observacoes,
                    borda_id,
                    borda_descricao,
                    valor_borda
                )
                VALUES (
                    $1,
                    $2,
                    (
                        SELECT pv.id
                          FROM produto_variacoes pv
                         WHERE pv.id = $3
                           AND pv.produto_id = $2
                         LIMIT 1
                    ),
                    $4,
                    $5,
                    $6,
                    $7,
                    $8,
                    $9,
                    $10,
                    $11,
                    $12,
                    $13
                )
                RETURNING id
                `,
                [
                    pedido.id,

                    // produto_id
                    item.produtoId || null,

                    // variacao_id = tamanho
                    item.tamanhoId || null,

                    // produto_nome
                    item.produtoDescricao,

                    // variacao_nome = tamanho
                    item.tamanhoDescricao || null,

                    Number(item.quantidade || 1),

                    Number(item.valorUnitario || 0),

                    valorAdicionais,

                    Number(item.valorTotal || 0),

                    item.observacao || null,

                    item.bordaId || null,

                    item.bordaDescricao || null,

                    Number(item.valorBorda || 0),
                ],
            );

            const pedidoItemId = resultadoItem.rows[0].id;

            // =====================================================
            // SABORES
            // =====================================================

            if (Array.isArray(item.sabores)) {
                for (const sabor of item.sabores) {
                    await client.query(
                        `
                        INSERT INTO pedido_item_sabores (
                            pedido_item_id,
                            sabor_id,
                            sabor_descricao,
                            valor
                        )
                        VALUES (
                            $1,
                            $2,
                            $3,
                            $4
                        )
                        `,
                        [
                            pedidoItemId,
                            sabor.id || null,
                            sabor.descricao,
                            Number(sabor.valor || 0),
                        ],
                    );
                }
            }

            // =====================================================
            // ADICIONAIS
            // =====================================================

            if (Array.isArray(item.adicionais)) {
                for (const adicional of item.adicionais) {
                    const quantidadeAdicional = Number(
                        adicional.quantidade || 1
                    );

                    const valorUnitarioAdicional = Number(
                        adicional.valor || 0
                    );

                    const valorTotalAdicional =
                        quantidadeAdicional *
                        valorUnitarioAdicional;

                    await client.query(
                        `
            INSERT INTO pedido_item_adicionais (
                pedido_item_id,
                adicional_id,
                adicional_nome,
                quantidade,
                valor_unitario,
                valor_total
            )
            VALUES (
                $1,
                $2,
                $3,
                $4,
                $5,
                $6
            )
            `,
                        [
                            pedidoItemId,
                            adicional.id || null,
                            adicional.descricao,
                            quantidadeAdicional,
                            valorUnitarioAdicional,
                            valorTotalAdicional,
                        ],
                    );
                }
            }
        }

        let transacaoId: string | null = null;
        let dadosPagamento: Record<string, unknown> = {
            forma_original: String(pagamento.forma ?? ''),
            troco_para: Number(pagamento.troco_para ?? 0),
        };

        if (formaPagamento === 'PIX' && configuracaoPix) {
            const provedor = normalizarProvedorPix(
                configuracaoPix.pix_provedor,
            ) as ProvedorPix;
            const pixProvedor = await criarPix({
                provedor,
                chavePix: configuracaoPix.pix_chave,
                pedidoId: pedido.id,
                numeroPedido: pedido.numero,
                valor: valorTotal,
                expiracaoSegundos: 300,
            });
            transacaoId = pixProvedor.id;
            const qrCodeBase64 = pixProvedor.imagemBase64
                ? (pixProvedor.imagemBase64.startsWith('data:')
                    ? pixProvedor.imagemBase64
                    : `data:image/png;base64,${pixProvedor.imagemBase64}`)
                : await gerarQrCodePix(pixProvedor.payload);
            respostaPix = {
                copiaCola: pixProvedor.payload,
                qrCodeBase64,
                valor: valorTotal,
                txid: transacaoId,
                expiraEm: pixProvedor.expiraEm.toISOString(),
            };
            dadosPagamento = {
                ...dadosPagamento,
                provedor,
                provedor_transacao_id: transacaoId,
                pix_copia_cola: pixProvedor.payload,
                pix_expira_em: pixProvedor.expiraEm.toISOString(),
            };
        }

        await client.query(
            `INSERT INTO pagamentos
                (pedido_id, forma, status, valor, transacao_id, dados)
             VALUES ($1, $2::forma_pagamento, 'PENDENTE', $3, $4, $5::jsonb)`,
            [pedido.id, formaPagamento, valorTotal, transacaoId,
             JSON.stringify(dadosPagamento)],
        );

        // =========================================================
        // FINALIZA TRANSAÇÃO
        // =========================================================

        await client.query('COMMIT');

        return res.status(201).json({
            mensagem: 'Pedido criado com sucesso.',
            pedido: {
                id: pedido.id,
                numero: pedido.numero,
                status: pedido.status,
                criadoEm: pedido.criado_em,
            },
            pix: respostaPix,
        });
    } catch (error) {
        // =========================================================
        // ERRO - DESFAZ TODA A OPERAÇÃO
        // =========================================================

        await client.query('ROLLBACK');

        console.error('Erro ao criar pedido:', error);

        const mensagem =
            error instanceof Error
                ? error.message
                : 'Erro desconhecido';

        return res.status(500).json({
            erro: 'Não foi possível criar o pedido.',
            detalhe: mensagem,
        });
    } finally {
        client.release();
    }
});

router.get('/parametros/novo-pedido', autenticarToken, exigirAcessoModulo('pedidos'), async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    try {
        const resultado = await database.query(
            `SELECT COALESCE(taxa_entrega, 0) AS taxa_entrega
             FROM loja_configuracao
             WHERE empresa_id = $1
             LIMIT 1`,
            [empresaId],
        );
        return res.status(200).json({
            taxa_entrega: resultado.rows[0]?.taxa_entrega ?? 0,
        });
    } catch (error) {
        console.error('Erro ao carregar parâmetros do novo pedido:', error);
        return res.status(500).json({ erro: 'Não foi possível carregar os parâmetros do pedido.' });
    }
});

router.get('/:id/pagamento-pix', async (req, res) => {
    const pedidoId = String(req.params.id ?? '').trim();
    if (!pedidoId) {
        return res.status(400).json({ erro: 'Pedido inválido.' });
    }
    try {
        const pagamento = await sincronizarPagamentoPix(pedidoId);
        return res.status(200).json({ pagamento });
    } catch (error) {
        const mensagem = error instanceof Error ? error.message : 'Erro desconhecido';
        if (mensagem === 'Pagamento PIX não encontrado.') {
            return res.status(404).json({ erro: mensagem });
        }
        console.error('Erro ao consultar pagamento PIX:', error);
        return res.status(500).json({
            erro: 'Não foi possível consultar o pagamento PIX.',
            detalhe: mensagem,
        });
    }
});

router.get('/:id/detalhes', autenticarToken, exigirAcessoModulo('pedidos'), async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const pedidoId = String(
        req.params.id ?? ''
    ).trim();

    if (!pedidoId) {
        return res.status(400).json({
            erro: 'Pedido inválido.',
        });
    }

    try {
        const resultadoPedido =
            await database.query(
                `
                SELECT
                    p.id,
                    p.numero,
                    p.cliente_nome,
                    p.cliente_telefone,
                    p.tipo_atendimento,
                    p.endereco_texto,
                    p.status,
                    p.subtotal,
                    p.taxa_entrega,
                    p.desconto,
                    p.acrescimo,
                    p.valor_total,
                    p.observacoes,
                    p.criado_em,
                    COALESCE(
                        (SELECT pg.forma::text FROM pagamentos pg WHERE pg.pedido_id = p.id ORDER BY pg.id DESC LIMIT 1),
                        'PIX'
                    ) AS forma_pagamento,
                    COALESCE(
                        (SELECT (pg.dados->>'troco_para')::numeric FROM pagamentos pg WHERE pg.pedido_id = p.id ORDER BY pg.id DESC LIMIT 1),
                        0
                    ) AS troco_para
                FROM pedidos p
                WHERE p.id = $1 AND p.empresa_id = $2
                `,
                [pedidoId, empresaId]
            );

        if (resultadoPedido.rowCount === 0) {
            return res.status(404).json({
                erro: 'Pedido não encontrado.',
            });
        }

        const resultadoItens =
            await database.query(
                `
                SELECT
                    pi.id,
                    pi.produto_id,
                    pi.produto_nome
                        AS produto_descricao,
                    pi.variacao_id
                        AS tamanho_id,
                    pi.variacao_nome
                        AS tamanho_descricao,
                    pi.quantidade,
                    pi.valor_unitario,
                    pi.valor_adicionais,
                    pi.valor_total,
                    pi.observacoes,
                    pi.borda_id,
                    pi.borda_descricao,
                    pi.valor_borda
                FROM pedido_itens pi
                WHERE pi.pedido_id = $1
                ORDER BY pi.id
                `,
                [pedidoId]
            );

        const itens = [];

        for (const item of resultadoItens.rows) {
            const resultadoSabores =
                await database.query(
                    `
                    SELECT
                        pis.sabor_id AS id,
                        pis.sabor_descricao
                            AS descricao,
                        pis.valor
                    FROM pedido_item_sabores pis
                    WHERE pis.pedido_item_id = $1
                    ORDER BY pis.id
                    `,
                    [item.id]
                );

            itens.push({
                ...item,
                sabores: resultadoSabores.rows,
            });
        }

        return res.status(200).json({
            pedido: {
                ...resultadoPedido.rows[0],
                itens,
            },
        });
    } catch (error) {
        console.error(
            'Erro ao carregar detalhes do pedido:',
            error
        );

        const mensagem =
            error instanceof Error
                ? error.message
                : 'Erro desconhecido';

        return res.status(500).json({
            erro:
                'Não foi possível carregar os detalhes do pedido.',
            detalhe: mensagem,
        });
    }
});

router.patch('/:id/status', autenticarToken, exigirAcessoModulo('pedidos'), async (req, res) => {
    const empresaId = empresaIdAutenticada(req);
    const pedidoId = String(req.params.id ?? '').trim();

    const statusRecebido = String(req.body.status ?? '').trim().toUpperCase();

    const aliasesStatus: Record<string, string> = {
        NOVO: 'RASCUNHO',
        EM_ENTREGA: 'SAIU_PARA_ENTREGA',
        SAIU_ENTREGA: 'SAIU_PARA_ENTREGA',
        FINALIZADO: 'ENTREGUE',
    };

    const status =
        aliasesStatus[statusRecebido] ??
        statusRecebido;

    if (!pedidoId) {
        return res.status(400).json({
            erro: 'Código do pedido inválido.',
        });
    }

    if (
        !statusPermitidos.includes(
            status as (typeof statusPermitidos)[number]
        )
    ) {
        return res.status(400).json({
    erro: 'Status do pedido inválido.',
    status_recebido: statusRecebido,
    status_normalizado: status,
    status_permitidos: statusPermitidos,
});
    }

    try {
        const resultado = await database.query(
            `
        UPDATE pedidos
           SET status = $1
         WHERE id = $2 AND empresa_id = $3
         RETURNING id, status
      `,
            [status, pedidoId, empresaId]
        );

        if (resultado.rowCount === 0) {
            return res.status(404).json({
                erro: 'Pedido não encontrado.',
            });
        }

        return res.status(200).json({
            mensagem: 'Status atualizado com sucesso.',
            pedido: resultado.rows[0],
        });
    } catch (error) {
        console.error('Erro ao atualizar status:', error);

        const mensagem =
            error instanceof Error
                ? error.message
                : 'Erro desconhecido';

        return res.status(500).json({
            erro: 'Não foi possível atualizar o status.',
            detalhe: mensagem,
        });
    }
});

router.get('/:id/status', async (req, res) => {
    const pedidoId = String(req.params.id ?? '').trim();

    if (!pedidoId) {
        return res.status(400).json({
            erro: 'Pedido inválido.',
        });
    }

    try {
        const resultado = await database.query(
            `
            SELECT
                id,
                numero,
                status,
                criado_em
            FROM pedidos
            WHERE id = $1
            LIMIT 1
            `,
            [pedidoId]
        );

        if (resultado.rowCount === 0) {
            return res.status(404).json({
                erro: 'Pedido não encontrado.',
            });
        }

        const pedido = resultado.rows[0];

        return res.status(200).json({
            pedido: {
                id: pedido.id,
                numero: pedido.numero,
                status: pedido.status,
                criadoEm: pedido.criado_em,
            },
        });

    } catch (error) {
        console.error(
            'Erro ao consultar status do pedido:',
            error
        );

        const mensagem =
            error instanceof Error
                ? error.message
                : 'Erro desconhecido';

        return res.status(500).json({
            erro: 'Não foi possível consultar o pedido.',
            detalhe: mensagem,
        });
    }
});

export default router;
