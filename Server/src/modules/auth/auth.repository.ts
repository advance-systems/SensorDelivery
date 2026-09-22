import { query } from '../../database/connection.js';
import type { EmpresaUsuario, UsuarioLogin } from './auth.types.js';

export class AuthRepository {
    async autenticar(email: string, senha: string): Promise<UsuarioLogin | null> {
        const usuarios = await query<UsuarioLogin>(
            `SELECT u.id, u.nome, u.email, u.tipo::TEXT AS tipo,
                    ue.empresa_id, e.nome_fantasia
             FROM usuarios u
             INNER JOIN usuario_empresas ue ON ue.usuario_id = u.id
             INNER JOIN empresas e ON e.id = ue.empresa_id
             WHERE LOWER(u.email) = LOWER($1)
               AND u.senha_hash = crypt($2, u.senha_hash)
               AND u.ativo = TRUE AND e.ativo = TRUE
             ORDER BY ue.principal DESC, e.nome_fantasia
             LIMIT 1`,
            [email, senha],
        );
        return usuarios[0] ?? null;
    }

    async registrarAcesso(usuarioId: string): Promise<void> {
        await query(
            'UPDATE usuarios SET ultimo_acesso = CURRENT_TIMESTAMP WHERE id = $1',
            [usuarioId],
        );
    }

    async listarEmpresas(usuarioId: string): Promise<EmpresaUsuario[]> {
        return query<EmpresaUsuario>(
            `SELECT e.id, e.nome_fantasia, ue.principal
             FROM usuario_empresas ue
             INNER JOIN empresas e ON e.id = ue.empresa_id
             WHERE ue.usuario_id = $1 AND e.ativo = TRUE
             ORDER BY ue.principal DESC, e.nome_fantasia`,
            [usuarioId],
        );
    }

    async usuarioNaEmpresa(usuarioId: string, empresaId: string): Promise<UsuarioLogin | null> {
        const usuarios = await query<UsuarioLogin>(
            `SELECT u.id, u.nome, u.email, u.tipo::TEXT AS tipo,
                    e.id AS empresa_id, e.nome_fantasia
             FROM usuarios u
             INNER JOIN usuario_empresas ue ON ue.usuario_id = u.id
             INNER JOIN empresas e ON e.id = ue.empresa_id
             WHERE u.id = $1 AND e.id = $2
               AND u.ativo = TRUE AND e.ativo = TRUE
             LIMIT 1`,
            [usuarioId, empresaId],
        );
        return usuarios[0] ?? null;
    }

    async listarTodasEmpresasAtivas(): Promise<EmpresaUsuario[]> {
        return query<EmpresaUsuario>(
            `SELECT id, nome_fantasia, FALSE AS principal
             FROM empresas
             WHERE ativo = TRUE
             ORDER BY nome_fantasia`,
        );
    }

    async listarTodasPermissoes(): Promise<string[]> {
        const todas = await query<{ codigo: string }>(
            'SELECT codigo FROM permissoes ORDER BY ordem, codigo',
        );
        return todas.map((item) => item.codigo);
    }

    async listarPermissoes(usuarioId: string, empresaId: string, tipo: string): Promise<string[]> {
        if (tipo === 'ADMIN') {
            return this.listarTodasPermissoes();
        }

        const permissoes = await query<{ codigo: string }>(
            `SELECT permissao_codigo AS codigo
             FROM usuario_permissoes
             WHERE usuario_id = $1 AND empresa_id = $2
             ORDER BY permissao_codigo`,
            [usuarioId, empresaId],
        );
        return permissoes.map((item) => item.codigo);
    }
}
