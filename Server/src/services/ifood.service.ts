import { database } from '../database/connection.js';

export interface IFoodConfig {
    empresa_id: string;
    ativo: boolean;
    client_id: string | null;
    client_secret: string | null;
    merchant_id: string | null;
    authorization_code: string | null;
    authorization_code_verifier: string | null;
    access_token: string | null;
    refresh_token: string | null;
    token_expira_em: Date | null;
    auto_confirmar_pedidos: boolean;
    polling_ativo: boolean;
    ultimo_polling_em: Date | null;
    ultimo_erro: string | null;
}

export interface IFoodEvent {
    id: string;
    code: string;
    fullCode?: string;
    orderId: string;
    merchantId: string;
    createdAt: string;
    metadata?: Record<string, unknown>;
}

export interface IFoodItem {
    id: string;
    name: string;
    quantity: number;
    unitPrice: number;
    totalPrice: number;
    externalCode?: string;
    observations?: string;
    options?: Array<{
        name: string;
        quantity: number;
        unitPrice: number;
        totalPrice: number;
        externalCode?: string;
    }>;
}

export interface IFoodOrderDetails {
    id: string;
    displayId: string;
    createdAt: string;
    orderType: string;
    orderTiming?: string;
    delivery?: {
        deliveryAddress?: {
            formattedAddress?: string;
            streetName?: string;
            streetNumber?: string;
            neighborhood?: string;
            complement?: string;
            reference?: string;
            postalCode?: string;
            city?: string;
            state?: string;
        };
    };
    customer: {
        id: string;
        name: string;
        phone?: {
            number?: string;
            extension?: string;
        };
        documentNumber?: string;
    };
    items: IFoodItem[];
    payments: {
        prepaid: number;
        pending: number;
        methods: Array<{
            value: number;
            currency: string;
            type: string; // ONLINE, PENDING
            method: string; // CREDIT, DEBIT, PIX, CASH, etc.
            cash?: {
                changeFor?: number;
            };
        }>;
    };
    total: {
        subTotal: number;
        deliveryFee: number;
        benefits: number;
        additionalFees: number;
        orderAmount: number;
    };
    extraInfo?: string;
}

const IFOOD_API_BASE = 'https://merchant-api.ifood.com.br';

export class IFoodService {
    /**
     * Obtém as configurações do iFood de uma empresa
     */
    static async obterConfiguracao(empresaId: string): Promise<IFoodConfig | null> {
        const resultado = await database.query(
            `SELECT * FROM ifood_configuracao WHERE empresa_id = $1 LIMIT 1`,
            [empresaId]
        );
        return (resultado.rows[0] as IFoodConfig) || null;
    }

    /**
     * Salva ou atualiza as configurações do iFood
     */
    static async salvarConfiguracao(
        empresaId: string,
        dados: Partial<IFoodConfig>
    ): Promise<IFoodConfig> {
        const resultado = await database.query(
            `
            INSERT INTO ifood_configuracao (
                empresa_id,
                ativo,
                client_id,
                client_secret,
                merchant_id,
                auto_confirmar_pedidos,
                polling_ativo,
                atualizado_em
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, CURRENT_TIMESTAMP)
            ON CONFLICT (empresa_id) DO UPDATE SET
                ativo = COALESCE(EXCLUDED.ativo, ifood_configuracao.ativo),
                client_id = COALESCE(EXCLUDED.client_id, ifood_configuracao.client_id),
                client_secret = COALESCE(EXCLUDED.client_secret, ifood_configuracao.client_secret),
                merchant_id = COALESCE(EXCLUDED.merchant_id, ifood_configuracao.merchant_id),
                auto_confirmar_pedidos = COALESCE(EXCLUDED.auto_confirmar_pedidos, ifood_configuracao.auto_confirmar_pedidos),
                polling_ativo = COALESCE(EXCLUDED.polling_ativo, ifood_configuracao.polling_ativo),
                atualizado_em = CURRENT_TIMESTAMP
            RETURNING *
            `,
            [
                empresaId,
                dados.ativo ?? false,
                dados.client_id?.trim() || null,
                dados.client_secret?.trim() || null,
                dados.merchant_id?.trim() || null,
                dados.auto_confirmar_pedidos ?? false,
                dados.polling_ativo ?? false,
            ]
        );
        return resultado.rows[0] as IFoodConfig;
    }

    /**
     * Garante um token de acesso válido para a empresa
     */
    static async obterTokenValido(empresaId: string): Promise<string> {
        const config = await this.obterConfiguracao(empresaId);
        if (!config || !config.ativo || !config.client_id || !config.client_secret) {
            throw new Error('Configurações do iFood incompletas ou inativas.');
        }

        // Se tem token e ainda não expirou (com margem de 2 minutos)
        if (
            config.access_token &&
            config.token_expira_em &&
            new Date(config.token_expira_em).getTime() > Date.now() + 120000
        ) {
            return config.access_token;
        }

        // Autentica via Client Credentials no iFood Authentication API
        const params = new URLSearchParams();
        params.append('grantType', 'client_credentials');
        params.append('clientId', config.client_id);
        params.append('clientSecret', config.client_secret);

        const response = await fetch(`${IFOOD_API_BASE}/authentication/v1.0/oauth/token`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                Accept: 'application/json',
            },
            body: params.toString(),
        });

        if (!response.ok) {
            const erroTexto = await response.text();
            await database.query(
                `UPDATE ifood_configuracao SET ultimo_erro = $1, atualizado_em = CURRENT_TIMESTAMP WHERE empresa_id = $2`,
                [`Erro ao obter token: ${erroTexto}`, empresaId]
            );
            throw new Error(`Falha na autenticação do iFood: ${erroTexto}`);
        }

        const data = (await response.json()) as {
            accessToken: string;
            refreshToken?: string;
            expiresIn: number;
        };

        const expiraEm = new Date(Date.now() + (data.expiresIn - 60) * 1000);

        await database.query(
            `
            UPDATE ifood_configuracao
            SET access_token = $1,
                refresh_token = $2,
                token_expira_em = $3,
                ultimo_erro = NULL,
                atualizado_em = CURRENT_TIMESTAMP
            WHERE empresa_id = $4
            `,
            [data.accessToken, data.refreshToken || null, expiraEm, empresaId]
        );

        return data.accessToken;
    }

    /**
     * Consulta eventos pendentes no iFood (Polling)
     */
    static async consultarEventos(empresaId: string): Promise<IFoodEvent[]> {
        const token = await this.obterTokenValido(empresaId);
        const config = await this.obterConfiguracao(empresaId);

        const url = `${IFOOD_API_BASE}/order/v1.0/events:polling`;
        const headers: Record<string, string> = {
            Authorization: `Bearer ${token}`,
            Accept: 'application/json',
        };

        if (config?.merchant_id) {
            headers['x-merchant-id'] = config.merchant_id;
        }

        const response = await fetch(url, { headers });

        if (response.status === 204) {
            // Nenhum evento novo
            return [];
        }

        if (!response.ok) {
            const erroTexto = await response.text();
            throw new Error(`Erro ao buscar eventos iFood: ${erroTexto}`);
        }

        return (await response.json()) as IFoodEvent[];
    }

    /**
     * Confirma o processamento dos eventos no iFood (Acknowledgment)
     */
    static async confirmarEventos(empresaId: string, eventIds: string[]): Promise<void> {
        if (!eventIds.length) return;

        const token = await this.obterTokenValido(empresaId);
        const response = await fetch(`${IFOOD_API_BASE}/order/v1.0/events/acknowledgment`, {
            method: 'POST',
            headers: {
                Authorization: `Bearer ${token}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(eventIds.map((id) => ({ id }))),
        });

        if (!response.ok) {
            const erroTexto = await response.text();
            console.error(`Erro ao confirmar acknowledgment iFood: ${erroTexto}`);
        }
    }

    /**
     * Busca os detalhes completos de um pedido no iFood
     */
    static async buscarDetalhesPedido(empresaId: string, orderId: string): Promise<IFoodOrderDetails> {
        const token = await this.obterTokenValido(empresaId);
        const response = await fetch(`${IFOOD_API_BASE}/order/v1.0/orders/${orderId}`, {
            headers: {
                Authorization: `Bearer ${token}`,
                Accept: 'application/json',
            },
        });

        if (!response.ok) {
            const erroTexto = await response.text();
            throw new Error(`Erro ao buscar detalhes do pedido ${orderId}: ${erroTexto}`);
        }

        return (await response.json()) as IFoodOrderDetails;
    }

    /**
     * Importa e salva um pedido do iFood na base do Sensor Delivery
     */
    static async importarPedidoIFood(empresaId: string, orderId: string): Promise<{ pedidoId: string; numero: number }> {
        const detalhes = await this.buscarDetalhesPedido(empresaId, orderId);

        // Verifica se o pedido já existe
        const pedidoExistente = await database.query(
            `SELECT id, numero FROM pedidos WHERE empresa_id = $1 AND ifood_order_id = $2 LIMIT 1`,
            [empresaId, orderId]
        );

        if ((pedidoExistente.rowCount ?? 0) > 0) {
            return {
                pedidoId: pedidoExistente.rows[0].id,
                numero: pedidoExistente.rows[0].numero,
            };
        }

        const client = await database.connect();
        try {
            await client.query('BEGIN');

            const clienteNome = detalhes.customer.name || 'Cliente iFood';
            const clienteTelefone = detalhes.customer.phone?.number || '00000000000';

            // Localiza ou cria o cliente
            let clienteId: string;
            const clienteRes = await client.query(
                `SELECT id FROM clientes WHERE empresa_id = $1 AND (telefone = $2 OR nome = $3) LIMIT 1`,
                [empresaId, clienteTelefone, clienteNome]
            );

            if ((clienteRes.rowCount ?? 0) > 0) {
                clienteId = clienteRes.rows[0].id;
            } else {
                const novoCliente = await client.query(
                    `INSERT INTO clientes (empresa_id, nome, telefone) VALUES ($1, $2, $3) RETURNING id`,
                    [empresaId, clienteNome, clienteTelefone]
                );
                clienteId = novoCliente.rows[0].id;
            }

            // Endereço formatado
            const end = detalhes.delivery?.deliveryAddress;
            const enderecoTexto = end
                ? [end.streetName, end.streetNumber, end.neighborhood, end.complement, end.city, end.postalCode]
                      .filter(Boolean)
                      .join(', ')
                : 'Retirada / Balcão';

            const tipoAtendimento = detalhes.orderType === 'TAKEOUT' || detalhes.orderType === 'INDOOR' ? 'RETIRADA' : 'ENTREGA';

            const subtotal = detalhes.total?.subTotal || 0;
            const taxaEntrega = detalhes.total?.deliveryFee || 0;
            const desconto = detalhes.total?.benefits || 0;
            const valorTotal = detalhes.total?.orderAmount || (subtotal + taxaEntrega - desconto);

            const obsGeral = [
                detalhes.extraInfo,
                `Pedido iFood #${detalhes.displayId}`,
            ]
                .filter(Boolean)
                .join(' | ');

            // Cria o pedido
            const resPedido = await client.query(
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
                    status,
                    canal_origem,
                    ifood_order_id,
                    ifood_order_code,
                    ifood_payload
                )
                VALUES (
                    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, 'AGUARDANDO_CONFIRMACAO', 'IFOOD', $13, $14, $15
                )
                RETURNING id, numero
                `,
                [
                    empresaId,
                    clienteId,
                    clienteNome,
                    clienteTelefone,
                    tipoAtendimento,
                    enderecoTexto,
                    obsGeral,
                    subtotal,
                    taxaEntrega,
                    desconto,
                    0,
                    valorTotal,
                    orderId,
                    detalhes.displayId,
                    JSON.stringify(detalhes),
                ]
            );

            const pedidoId = resPedido.rows[0].id;
            const numero = resPedido.rows[0].numero;

            // Insere os itens
            for (const item of detalhes.items || []) {
                const valorAdicionais = (item.options || []).reduce(
                    (s, opt) => s + (opt.totalPrice || opt.unitPrice * opt.quantity || 0),
                    0
                );

                const resItem = await client.query(
                    `
                    INSERT INTO pedido_itens (
                        pedido_id,
                        produto_nome,
                        quantidade,
                        valor_unitario,
                        valor_adicionais,
                        valor_total,
                        observacoes
                    )
                    VALUES ($1, $2, $3, $4, $5, $6, $7)
                    RETURNING id
                    `,
                    [
                        pedidoId,
                        item.name,
                        item.quantity || 1,
                        item.unitPrice || 0,
                        valorAdicionais,
                        item.totalPrice || (item.unitPrice * item.quantity + valorAdicionais),
                        item.observations || null,
                    ]
                );

                const itemId = resItem.rows[0].id;

                // Insere opções/adicionais do item
                for (const opt of item.options || []) {
                    await client.query(
                        `
                        INSERT INTO pedido_item_adicionais (
                            pedido_item_id,
                            adicional_nome,
                            quantidade,
                            valor_unitario,
                            valor_total
                        )
                        VALUES ($1, $2, $3, $4, $5)
                        `,
                        [
                            itemId,
                            opt.name,
                            opt.quantity || 1,
                            opt.unitPrice || 0,
                            opt.totalPrice || (opt.unitPrice * (opt.quantity || 1)),
                        ]
                    );
                }
            }

            // Pagamento
            const metodo = detalhes.payments?.methods?.[0];
            const forma = metodo?.type === 'ONLINE' ? 'ONLINE' : (metodo?.method === 'PIX' ? 'PIX' : (metodo?.method === 'CASH' ? 'DINHEIRO' : 'CARTAO_CREDITO'));
            await client.query(
                `
                INSERT INTO pagamentos (
                    pedido_id,
                    forma,
                    status,
                    valor,
                    dados
                )
                VALUES ($1, $2::forma_pagamento, $3::status_pagamento, $4, $5)
                `,
                [
                    pedidoId,
                    forma,
                    metodo?.type === 'ONLINE' ? 'APROVADO' : 'PENDENTE',
                    valorTotal,
                    JSON.stringify(detalhes.payments || {}),
                ]
            );

            await client.query('COMMIT');
            return { pedidoId, numero };
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }

    /**
     * Envia comandos de status ao iFood (Confirmar, Despachar, etc.)
     */
    static async enviarAcao(empresaId: string, orderId: string, acao: 'confirm' | 'dispatch' | 'readyToPickup' | 'requestCancellation'): Promise<void> {
        const token = await this.obterTokenValido(empresaId);
        const response = await fetch(`${IFOOD_API_BASE}/order/v1.0/orders/${orderId}/${acao}`, {
            method: 'POST',
            headers: {
                Authorization: `Bearer ${token}`,
                Accept: 'application/json',
            },
        });

        if (!response.ok && response.status !== 202) {
            const erroTexto = await response.text();
            throw new Error(`Falha ao executar ${acao} no iFood: ${erroTexto}`);
        }
    }

    /**
     * Executa ciclo de polling para todas as empresas ativas
     */
    static async executarPollingTodasLojas(): Promise<void> {
        const resultado = await database.query(
            `SELECT empresa_id FROM ifood_configuracao WHERE ativo = TRUE AND polling_ativo = TRUE`
        );

        for (const { empresa_id } of resultado.rows) {
            try {
                const eventos = await this.consultarEventos(empresa_id);
                if (!eventos.length) continue;

                const eventIdsConfirmar: string[] = [];

                for (const ev of eventos) {
                    try {
                        // Registra log
                        await database.query(
                            `
                            INSERT INTO ifood_eventos_log (
                                empresa_id, event_id, order_id, code, full_code, created_at_ifood, payload
                            )
                            VALUES ($1, $2, $3, $4, $5, $6, $7)
                            ON CONFLICT (empresa_id, event_id) DO NOTHING
                            `,
                            [
                                empresa_id,
                                ev.id,
                                ev.orderId,
                                ev.code,
                                ev.fullCode || null,
                                ev.createdAt ? new Date(ev.createdAt) : null,
                                JSON.stringify(ev),
                            ]
                        );

                        // Pedido Realizado no iFood
                        if (ev.code === 'PLC' || ev.fullCode === 'PLACED') {
                            const { numero } = await this.importarPedidoIFood(empresa_id, ev.orderId);
                            console.log(`[iFood] Pedido #${numero} (iFood: ${ev.orderId}) importado com sucesso para empresa ${empresa_id}!`);

                            // Auto confirmar se configurado
                            const config = await this.obterConfiguracao(empresa_id);
                            if (config?.auto_confirmar_pedidos) {
                                await this.enviarAcao(empresa_id, ev.orderId, 'confirm').catch((err) =>
                                    console.error(`[iFood] Erro auto confirmando pedido ${ev.orderId}:`, err)
                                );
                            }
                        }

                        // Pedido Cancelado no iFood
                        if (ev.code === 'CAN' || ev.fullCode === 'CANCELLED') {
                            await database.query(
                                `UPDATE pedidos SET status = 'CANCELADO', cancelado_em = CURRENT_TIMESTAMP WHERE empresa_id = $1 AND ifood_order_id = $2`,
                                [empresa_id, ev.orderId]
                            );
                        }

                        eventIdsConfirmar.push(ev.id);
                    } catch (errEv) {
                        console.error(`[iFood] Erro processando evento ${ev.id}:`, errEv);
                    }
                }

                if (eventIdsConfirmar.length > 0) {
                    await this.confirmarEventos(empresa_id, eventIdsConfirmar);
                }

                await database.query(
                    `UPDATE ifood_configuracao SET ultimo_polling_em = CURRENT_TIMESTAMP, ultimo_erro = NULL WHERE empresa_id = $1`,
                    [empresa_id]
                );
            } catch (err) {
                console.error(`[iFood] Erro no ciclo de polling da empresa ${empresa_id}:`, err);
                const msg = err instanceof Error ? err.message : String(err);
                await database.query(
                    `UPDATE ifood_configuracao SET ultimo_erro = $1, atualizado_em = CURRENT_TIMESTAMP WHERE empresa_id = $2`,
                    [msg, empresa_id]
                ).catch(() => undefined);
            }
        }
    }
}
