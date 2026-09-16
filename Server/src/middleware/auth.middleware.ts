import type {
    NextFunction,
    Request,
    Response,
} from 'express';

import jwt from 'jsonwebtoken';

import type { TokenPayload } from '../modules/auth/auth.types.js';

export interface AuthenticatedRequest extends Request {
    usuario?: TokenPayload;
}

export function empresaIdAutenticada(request: Request): string {
    return (request as AuthenticatedRequest).usuario?.empresaId ?? '';
}

export function autenticarToken(
    request: AuthenticatedRequest,
    response: Response,
    next: NextFunction,
): void {
    const authorization = request.headers.authorization;

    if (!authorization) {
        response.status(401).json({
            erro: 'Token de acesso não informado.',
        });

        return;
    }

    const [tipo, token] = authorization.split(' ');

    if (tipo !== 'Bearer' || !token) {
        response.status(401).json({
            erro: 'Formato do token inválido.',
        });

        return;
    }

    const jwtSecret = process.env.JWT_SECRET;

    if (!jwtSecret) {
        console.error('JWT_SECRET não configurada.');

        response.status(500).json({
            erro: 'Falha na configuração de autenticação.',
        });

        return;
    }

    try {
        const payload = jwt.verify(token, jwtSecret, {
            algorithms: ['HS256'],
            issuer: 'sensor-delivery-server',
            audience: 'sensor-delivery-app',
        }) as TokenPayload;

        payload.permissoes = Array.isArray(payload.permissoes)
            ? payload.permissoes
            : [];
        request.usuario = payload;

        next();
    } catch {
        response.status(401).json({
            erro: 'Token inválido ou expirado.',
        });
    }
}
