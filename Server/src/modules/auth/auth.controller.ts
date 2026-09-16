import type { Request, Response } from 'express';
import { AuthError, AuthService } from './auth.service.js';
import type { AuthenticatedRequest } from '../../middleware/auth.middleware.js';

const authService = new AuthService();

export class AuthController {
    async login(request: Request, response: Response): Promise<Response> {
        try {
            const resultado = await authService.login({
                email: request.body?.email,
                senha: request.body?.senha,
            });
            return response.status(200).json(resultado);
        } catch (error) {
            if (error instanceof AuthError) {
                return response.status(error.statusCode).json({ erro: error.message });
            }
            console.error('Erro ao realizar login:', error);
            return response.status(500).json({ erro: 'Não foi possível realizar o login.' });
        }
    }

    async selecionarEmpresa(
        request: AuthenticatedRequest,
        response: Response,
    ): Promise<Response> {
        try {
            const resultado = await authService.selecionarEmpresa(
                request.usuario!.usuarioId,
                String(request.body?.empresaId ?? ''),
            );
            return response.status(200).json(resultado);
        } catch (error) {
            if (error instanceof AuthError) {
                return response.status(error.statusCode).json({ erro: error.message });
            }
            console.error('Erro ao selecionar empresa:', error);
            return response.status(500).json({ erro: 'Não foi possível selecionar a empresa.' });
        }
    }
}
