import type { Response } from 'express';

import type { AuthenticatedRequest } from '../../middleware/auth.middleware.js';
import { DashboardService } from './dashboard.service.js';

const dashboardService = new DashboardService();

export class DashboardController {
    async resumo(
        request: AuthenticatedRequest,
        response: Response,
    ): Promise<Response> {
        try {
            const empresaId = request.usuario?.empresaId;

            if (!empresaId) {
                return response.status(401).json({
                    erro: 'Empresa não identificada no token.',
                });
            }

            const resumo = await dashboardService.obterResumo(
                empresaId,
            );

            return response.status(200).json(resumo);
        } catch (error) {
            console.error(
                'Erro ao carregar resumo do dashboard:',
                error,
            );

            return response.status(500).json({
                erro: 'Não foi possível carregar o dashboard.',
            });
        }
    }
}