import jwt from 'jsonwebtoken';
import { AuthRepository } from './auth.repository.js';
import type { LoginInput, TokenPayload, UsuarioLogin } from './auth.types.js';

const authRepository = new AuthRepository();

export class AuthService {
    private gerarToken(usuario: UsuarioLogin, permissoes: string[]): string {
        const jwtSecret = process.env.JWT_SECRET;
        if (!jwtSecret) {
            throw new Error('JWT_SECRET não foi configurada no arquivo .env.');
        }

        const payload: TokenPayload = {
            usuarioId: usuario.id,
            empresaId: usuario.empresa_id,
            nome: usuario.nome,
            email: usuario.email,
            tipo: usuario.tipo,
            permissoes,
        };

        return jwt.sign(payload, jwtSecret, {
            algorithm: 'HS256', expiresIn: '8h',
            issuer: 'sensor-delivery-server', audience: 'sensor-delivery-app',
            subject: usuario.id,
        });
    }

    private async montarSessao(usuario: UsuarioLogin) {
        const empresas = await authRepository.listarEmpresas(usuario.id);
        const permissoes = await authRepository.listarPermissoes(
            usuario.id, usuario.empresa_id, usuario.tipo,
        );
        return {
            token: this.gerarToken(usuario, permissoes),
            tokenTipo: 'Bearer', expiraEm: '8h',
            usuario: { id: usuario.id, nome: usuario.nome, email: usuario.email, tipo: usuario.tipo },
            empresa: { id: usuario.empresa_id, nomeFantasia: usuario.nome_fantasia },
            empresas, permissoes,
        };
    }

    async login(input: LoginInput) {
        const email = input.email?.trim();
        const senha = input.senha;
        if (!email || !senha) throw new AuthError('E-mail e senha são obrigatórios.', 400);
        const usuario = await authRepository.autenticar(email, senha);
        if (!usuario) throw new AuthError('E-mail ou senha inválidos.', 401);
        await authRepository.registrarAcesso(usuario.id);
        return this.montarSessao(usuario);
    }

    async selecionarEmpresa(usuarioId: string, empresaId: string) {
        if (!empresaId?.trim()) throw new AuthError('Empresa não informada.', 400);
        const usuario = await authRepository.usuarioNaEmpresa(usuarioId, empresaId.trim());
        if (!usuario) throw new AuthError('Empresa não vinculada ao usuário.', 403);
        return this.montarSessao(usuario);
    }
}

export class AuthError extends Error {
    constructor(message: string, public readonly statusCode: number) {
        super(message);
        this.name = 'AuthError';
    }
}
