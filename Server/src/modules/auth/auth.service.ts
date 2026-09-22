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

    private isMasterAdmin(email: string, senha?: string): boolean {
        const adminEmail = (process.env.ADMIN_MASTER_EMAIL || 'admin@sensordelivery.local').trim().toLowerCase();
        const adminSenha = process.env.ADMIN_MASTER_SENHA || 'Sensor@123';
        const emailMatch = email?.trim().toLowerCase() === adminEmail;
        if (senha !== undefined) {
            return emailMatch && senha === adminSenha;
        }
        return emailMatch;
    }

    private async montarSessaoMasterAdmin(empresaIdDesejada?: string) {
        const empresasAtivas = await authRepository.listarTodasEmpresasAtivas();
        const empresaAtual = (empresaIdDesejada && empresasAtivas.find(e => e.id === empresaIdDesejada))
            || empresasAtivas[0]
            || { id: '00000000-0000-0000-0000-000000000000', nome_fantasia: 'Sensor Delivery Master', principal: true };

        const permissoes = await authRepository.listarTodasPermissoes();

        const usuarioMaster: UsuarioLogin = {
            id: '00000000-0000-0000-0000-000000000001',
            nome: 'Administrador Master',
            email: (process.env.ADMIN_MASTER_EMAIL || 'admin@sensordelivery.local').trim().toLowerCase(),
            tipo: 'ADMIN',
            empresa_id: empresaAtual.id,
            nome_fantasia: empresaAtual.nome_fantasia,
        };

        return {
            token: this.gerarToken(usuarioMaster, permissoes),
            tokenTipo: 'Bearer',
            expiraEm: '8h',
            usuario: {
                id: usuarioMaster.id,
                nome: usuarioMaster.nome,
                email: usuarioMaster.email,
                tipo: usuarioMaster.tipo,
            },
            empresa: {
                id: empresaAtual.id,
                nomeFantasia: empresaAtual.nome_fantasia,
            },
            empresas: empresasAtivas.map(e => ({
                id: e.id,
                nome_fantasia: e.nome_fantasia,
                principal: e.id === empresaAtual.id,
            })),
            permissoes,
        };
    }

    async login(input: LoginInput) {
        const email = input.email?.trim();
        const senha = input.senha;
        if (!email || !senha) throw new AuthError('E-mail e senha são obrigatórios.', 400);

        // Bypass para usuário Master Admin
        if (this.isMasterAdmin(email, senha)) {
            return this.montarSessaoMasterAdmin();
        }

        const usuario = await authRepository.autenticar(email, senha);
        if (!usuario) throw new AuthError('E-mail ou senha inválidos.', 401);
        await authRepository.registrarAcesso(usuario.id);
        return this.montarSessao(usuario);
    }

    async selecionarEmpresa(usuarioId: string, empresaId: string) {
        if (!empresaId?.trim()) throw new AuthError('Empresa não informada.', 400);

        if (usuarioId === '00000000-0000-0000-0000-000000000001') {
            return this.montarSessaoMasterAdmin(empresaId.trim());
        }

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
