import {
    Router,
} from 'express';

import {
    criarPedido,
} from './pedido.controller.js';

export const pedidoRoutes =
    Router();

pedidoRoutes.post(
    '/',
    criarPedido,
);