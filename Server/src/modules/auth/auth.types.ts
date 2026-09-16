export interface LoginInput {
    email: string;
    senha: string;
}

export interface UsuarioLogin {
    id: string;
    nome: string;
    email: string;
    tipo: string;
    empresa_id: string;
    nome_fantasia: string;
}

export interface EmpresaUsuario {
    id: string;
    nome_fantasia: string;
    principal: boolean;
}

export interface TokenPayload {
    usuarioId: string;
    empresaId: string;
    nome: string;
    email: string;
    tipo: string;
    permissoes: string[];
}
