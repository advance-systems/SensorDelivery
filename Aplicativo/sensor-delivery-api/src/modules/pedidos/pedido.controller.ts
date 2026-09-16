import type {
    Request,
    Response,
} from 'express';

import type {
    PoolClient,
} from 'pg';

import { pool } from '../../database/pool.js';

import type {
    CriarPedidoBody,
    PedidoItem,
} from './pedido.types.js';


function obterTextoObrigatorio(
    valor: unknown,
    nomeCampo: string,
): string {
    if (
        typeof valor !== 'string' ||
        valor.trim() === ''
    ) {
        throw new Error(
            `O campo ${nomeCampo} é obrigatório.`,
        );
    }

    return valor.trim();
}


function obterNumero(
    valor: unknown,
    nomeCampo: string,
): number {
    const numero = Number(valor);

    if (!Number.isFinite(numero)) {
        throw new Error(
            `O campo ${nomeCampo} possui valor inválido.`,
        );
    }

    return numero;
}


function validarItem(
    item: PedidoItem,
): void {
    if (!item) {
        throw new Error(
            'Foi encontrado um item inválido.',
        );
    }

    obterTextoObrigatorio(
        item.produto_descricao,
        'item.produto_descricao',
    );

    const quantidade = obterNumero(
        item.quantidade,
        'item.quantidade',
    );

    if (
        !Number.isInteger(quantidade) ||
        quantidade <= 0
    ) {
        throw new Error(
            'A quantidade do item deve ser maior que zero.',
        );
    }

    obterNumero(
        item.valor_base,
        'item.valor_base',
    );

    obterNumero(
        item.valor_borda,
        'item.valor_borda',
    );

    obterNumero(
        item.valor_unitario,
        'item.valor_unitario',
    );

    obterNumero(
        item.valor_total,
        'item.valor_total',
    );

    if (!Array.isArray(item.sabores)) {
        throw new Error(
            'A lista de sabores do item é inválida.',
        );
    }
}


function validarPedido(
    body: CriarPedidoBody,
): void {
    if (
        !body ||
        typeof body !== 'object'
    ) {
        throw new Error(
            'Os dados do pedido não foram informados.',
        );
    }

    if (!body.cliente) {
        throw new Error(
            'Os dados do cliente não foram informados.',
        );
    }

    obterTextoObrigatorio(
        body.cliente.nome,
        'cliente.nome',
    );

    obterTextoObrigatorio(
        body.cliente.telefone,
        'cliente.telefone',
    );

    if (
        body.tipo_recebimento !== 'ENTREGA' &&
        body.tipo_recebimento !== 'RETIRADA'
    ) {
        throw new Error(
            'O tipo de recebimento é inválido.',
        );
    }

    if (body.tipo_recebimento === 'ENTREGA') {
        if (!body.endereco) {
            throw new Error(
                'O endereço de entrega não foi informado.',
            );
        }

        obterTextoObrigatorio(
            body.endereco.logradouro,
            'endereco.logradouro',
        );

        obterTextoObrigatorio(
            body.endereco.numero,
            'endereco.numero',
        );

        obterTextoObrigatorio(
            body.endereco.bairro,
            'endereco.bairro',
        );
    }

    if (!body.pagamento) {
        throw new Error(
            'A forma de pagamento não foi informada.',
        );
    }

    obterTextoObrigatorio(
        body.pagamento.forma,
        'pagamento.forma',
    );

    if (!body.valores) {
        throw new Error(
            'Os valores do pedido não foram informados.',
        );
    }

    obterNumero(
        body.valores.subtotal,
        'valores.subtotal',
    );

    obterNumero(
        body.valores.taxa_entrega,
        'valores.taxa_entrega',
    );

    obterNumero(
        body.valores.total,
        'valores.total',
    );

    if (
        !Array.isArray(body.itens) ||
        body.itens.length === 0
    ) {
        throw new Error(
            'O pedido deve possuir pelo menos um item.',
        );
    }

    for (const item of body.itens) {
        validarItem(item);
    }
}


async function obterEmpresaId(
    client: PoolClient,
    empresaIdInformado?: number,
): Promise<number> {
    if (
        empresaIdInformado !== undefined &&
        Number.isInteger(Number(empresaIdInformado)) &&
        Number(empresaIdInformado) > 0
    ) {
        const empresaResult = await client.query<{
            id: string;
        }>(
            `
        SELECT id
        FROM empresas
        WHERE id = $1
          AND ativo = TRUE
        LIMIT 1
      `,
            [Number(empresaIdInformado)],
        );

        if (empresaResult.rows.length === 0) {
            throw new Error(
                'A empresa informada não foi encontrada.',
            );
        }

        return Number(
            empresaResult.rows[0].id,
        );
    }

    const empresaResult = await client.query<{
        id: string;
    }>(
        `
      SELECT id
      FROM empresas
      WHERE ativo = TRUE
      ORDER BY id
      LIMIT 1
    `,
    );

    if (empresaResult.rows.length === 0) {
        throw new Error(
            'Nenhuma empresa ativa foi encontrada.',
        );
    }

    return Number(
        empresaResult.rows[0].id,
    );
}


async function obterFormaPagamentoId(
    client: PoolClient,
    empresaId: number,
    descricao: string,
): Promise<number | null> {
    const result = await client.query<{
        id: string;
    }>(
        `
      SELECT id
      FROM formas_pagamento
      WHERE empresa_id = $1
        AND LOWER(descricao) = LOWER($2)
        AND ativo = TRUE
      LIMIT 1
    `,
        [
            empresaId,
            descricao,
        ],
    );

    if (result.rows.length === 0) {
        return null;
    }

    return Number(result.rows[0].id);
}


export async function criarPedido(
    req: Request,
    res: Response,
): Promise<void> {
    const body =
        req.body as CriarPedidoBody;

    try {
        validarPedido(body);
    } catch (error) {
        res.status(400).json({
            sucesso: false,

            mensagem:
                error instanceof Error
                    ? error.message
                    : 'Dados do pedido inválidos.',
        });

        return;
    }

    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        const empresaId = await obterEmpresaId(
            client,
            body.empresa_id,
        );

        const endereco =
            body.endereco ?? {};

        const subtotal = Number(
            body.valores.subtotal,
        );

        const desconto = Number(
            body.valores.desconto ?? 0,
        );

        const taxaEntrega = Number(
            body.valores.taxa_entrega,
        );

        const acrescimo = Number(
            body.valores.acrescimo ?? 0,
        );

        const total = Number(
            body.valores.total,
        );

        const totalCalculado =
            subtotal -
            desconto +
            taxaEntrega +
            acrescimo;

        if (
            Math.abs(totalCalculado - total) > 0.01
        ) {
            throw new Error(
                'O total do pedido não corresponde aos valores informados.',
            );
        }

        const pedidoResult = await client.query<{
            id: string;
            numero_pedido: string;
        }>(
            `
        INSERT INTO pedidos (
          empresa_id,
          origem,
          status,
          tipo_recebimento,

          cliente_nome,
          cliente_telefone,

          cep,
          logradouro,
          numero,
          complemento,
          bairro,
          cidade,
          uf,
          referencia,

          observacao,

          subtotal,
          desconto,
          taxa_entrega,
          acrescimo,
          total
        )
        VALUES (
          $1,
          'APP',
          'PENDENTE',
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

          $13,

          $14,
          $15,
          $16,
          $17,
          $18
        )
        RETURNING
          id,
          numero_pedido
      `,
            [
                empresaId,
                body.tipo_recebimento,

                body.cliente.nome.trim(),
                body.cliente.telefone.trim(),

                endereco.cep?.trim() || null,
                endereco.logradouro?.trim() || null,
                endereco.numero?.trim() || null,
                endereco.complemento?.trim() || null,
                endereco.bairro?.trim() || null,
                endereco.cidade?.trim() || null,
                endereco.uf?.trim().toUpperCase() || null,
                endereco.referencia?.trim() || null,

                body.observacao?.trim() || null,

                subtotal,
                desconto,
                taxaEntrega,
                acrescimo,
                total,
            ],
        );

        const pedidoId = Number(
            pedidoResult.rows[0].id,
        );

        const numeroPedido =
            pedidoResult.rows[0].numero_pedido;

        for (const item of body.itens) {
            const itemResult = await client.query<{
                id: string;
            }>(
                `
          INSERT INTO pedido_itens (
            pedido_id,

            produto_id,
            identificador,
            produto_descricao,
            tipo_produto,

            tamanho_id,
            tamanho_descricao,
            valor_base,

            borda_id,
            borda_descricao,
            valor_borda,

            quantidade,
            observacao,

            valor_unitario,
            valor_total
          )
          VALUES (
            $1,

            (
              SELECT id
              FROM produtos
              WHERE id = $2
                AND empresa_id = $3
              LIMIT 1
            ),

            $4,
            $5,
            'PIZZA',

            (
              SELECT id
              FROM pizza_tamanhos
              WHERE id = $6
                AND empresa_id = $3
              LIMIT 1
            ),

            $7,
            $8,

            (
              SELECT id
              FROM pizza_bordas
              WHERE id = $9
                AND empresa_id = $3
              LIMIT 1
            ),

            $10,
            $11,

            $12,
            $13,

            $14,
            $15
          )
          RETURNING id
        `,
                [
                    pedidoId,

                    item.produto_id
                        ? Number(item.produto_id)
                        : null,

                    empresaId,

                    item.identificador || null,
                    item.produto_descricao.trim(),

                    item.tamanho_id
                        ? Number(item.tamanho_id)
                        : null,

                    item.tamanho_descricao?.trim() || null,
                    Number(item.valor_base),

                    item.borda_id
                        ? Number(item.borda_id)
                        : null,

                    item.borda_descricao?.trim() || null,
                    Number(item.valor_borda),

                    Number(item.quantidade),
                    item.observacao?.trim() || null,

                    Number(item.valor_unitario),
                    Number(item.valor_total),
                ],
            );

            const pedidoItemId = Number(
                itemResult.rows[0].id,
            );

            for (const sabor of item.sabores) {
                await client.query(
                    `
            INSERT INTO pedido_item_sabores (
              pedido_item_id,
              sabor_id,
              descricao,
              valor
            )
            VALUES (
              $1,

              (
                SELECT id
                FROM pizza_sabores
                WHERE id = $2
                  AND empresa_id = $3
                LIMIT 1
              ),

              $4,
              $5
            )
          `,
                    [
                        pedidoItemId,

                        sabor.id
                            ? Number(sabor.id)
                            : null,

                        empresaId,

                        sabor.descricao.trim(),
                        Number(sabor.valor),
                    ],
                );
            }
        }

        const formaDescricao =
            body.pagamento.forma.trim();

        const formaPagamentoId =
            await obterFormaPagamentoId(
                client,
                empresaId,
                formaDescricao,
            );

        const trocoPara = Number(
            body.pagamento.troco_para ?? 0,
        );

        const troco =
            trocoPara > total
                ? trocoPara - total
                : 0;

        await client.query(
            `
        INSERT INTO pedido_pagamentos (
          pedido_id,
          forma_pagamento_id,
          forma_descricao,
          valor,
          troco_para,
          troco,
          status
        )
        VALUES (
          $1,
          $2,
          $3,
          $4,
          $5,
          $6,
          'PENDENTE'
        )
      `,
            [
                pedidoId,
                formaPagamentoId,
                formaDescricao,
                total,
                trocoPara,
                troco,
            ],
        );

        await client.query('COMMIT');

        res.status(201).json({
            sucesso: true,
            mensagem:
                'Pedido realizado com sucesso.',

            pedido_id:
                pedidoId,

            numero_pedido:
                numeroPedido,

            status:
                'PENDENTE',
        });
    } catch (error) {
        await client.query('ROLLBACK');

        console.error(
            'Erro ao criar pedido:',
            error,
        );

        res.status(500).json({
            sucesso: false,

            mensagem:
                error instanceof Error
                    ? error.message
                    : 'Erro interno ao criar o pedido.',
        });
    } finally {
        client.release();
    }
}