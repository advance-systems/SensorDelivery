import { DashboardRepository } from './dashboard.repository.js';
import type { DashboardResumo } from './dashboard.types.js';

const dashboardRepository = new DashboardRepository();

export class DashboardService {
    async obterResumo(
        empresaId: string,
    ): Promise<DashboardResumo> {
        if (!empresaId) {
            throw new Error(
                'A empresa do usuário não foi identificada.',
            );
        }

        return dashboardRepository.obterResumo(empresaId);
    }
}