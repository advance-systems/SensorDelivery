import type { NextFunction, Response } from 'express';
import type { AuthenticatedRequest } from './auth.middleware.js';

export function exigirPermissao(codigo: string) {
    return (
        request: AuthenticatedRequest,
        response: Response,
        next: NextFunction,
    ): void => {
        const usuario = request.usuario;

        if (!usuario) {
            response.status(401).json({ erro: 'Usuário não autenticado.' });
            return;
        }

        if (usuario.tipo === 'ADMIN' || usuario.permissoes.includes(codigo)) {
            next();
            return;
        }

        response.status(403).json({
            erro: 'Você não possui permissão para esta operação.',
            permissao: codigo,
        });
    };
}

export function exigirAcessoModulo(modulo: string) {
    return (
        request: AuthenticatedRequest,
        response: Response,
        next: NextFunction,
    ): void => {
        const metodo = request.method.toUpperCase();
        const alteracaoDeSituacao = metodo === 'PATCH'
            && /\/situacao\/?$/i.test(request.path);
        const operacaoPorMetodo: Record<string, string> = {
            GET: 'visualizar',
            HEAD: 'visualizar',
            OPTIONS: 'visualizar',
            POST: 'incluir',
            PUT: 'alterar',
            PATCH: 'alterar',
            DELETE: 'excluir',
        };
        const operacao = alteracaoDeSituacao
            ? 'excluir'
            : (operacaoPorMetodo[metodo] ?? 'alterar');
        exigirPermissao(`${modulo}.${operacao}`)(request, response, next);
    };
}

export function exigirUmaPermissao(codigos: string[]) {
    return (
        request: AuthenticatedRequest,
        response: Response,
        next: NextFunction,
    ): void => {
        const usuario = request.usuario;
        if (!usuario) {
            response.status(401).json({ erro: 'Usuário não autenticado.' });
            return;
        }
        if (usuario.tipo === 'ADMIN' || codigos.some((codigo) => usuario.permissoes.includes(codigo))) {
            next();
            return;
        }
        response.status(403).json({ erro: 'Você não possui permissão para esta operação.' });
    };
}

export function exigirAcessoEmpresas(
    request: AuthenticatedRequest,
    response: Response,
    next: NextFunction,
): void {
    const metodo = request.method.toUpperCase();
    if (['GET', 'HEAD', 'OPTIONS'].includes(metodo)) {
        exigirUmaPermissao([
            'empresas.visualizar',
            'usuarios.visualizar',
            'permissoes.visualizar',
        ])(request, response, next);
        return;
    }

    exigirAcessoModulo('empresas')(request, response, next);
}
