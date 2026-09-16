import { Router } from 'express';

import { autenticarToken } from '../../middleware/auth.middleware.js';
import { exigirPermissao } from '../../middleware/permission.middleware.js';
import { DashboardController } from './dashboard.controller.js';

export const dashboardRoutes = Router();

const dashboardController = new DashboardController();

dashboardRoutes.get(
    '/resumo',
    autenticarToken,
    exigirPermissao('dashboard.visualizar'),
    dashboardController.resumo.bind(dashboardController),
);
