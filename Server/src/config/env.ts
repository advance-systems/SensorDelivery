import path from 'node:path';

type Environment = Record<string, string | undefined>;

export function booleanEnv(env: Environment, name: string, fallback = false): boolean {
    const value = env[name]?.trim().toLowerCase();
    if (!value) return fallback;
    if (value === 'true') return true;
    if (value === 'false') return false;
    throw new Error(`${name} deve ser true ou false.`);
}

function integerEnv(env: Environment, name: string, fallback: number, maximum: number): number {
    const raw = env[name]?.trim();
    const value = raw ? Number(raw) : fallback;
    if (!Number.isInteger(value) || value < 1 || value > maximum) {
        throw new Error(`${name} deve ser um inteiro entre 1 e ${maximum}.`);
    }
    return value;
}

function secretIsExample(value: string): boolean {
    return /troque|sua[_ -]?senha|seu[_ -]?token|example|change.?me/i.test(value);
}

export function masterCredentials(env: Environment): { email: string; password: string } | null {
    if (!booleanEnv(env, 'ADMIN_MASTER_ENABLED')) return null;
    const email = env.ADMIN_MASTER_EMAIL?.trim().toLowerCase();
    const password = env.ADMIN_MASTER_SENHA;
    if (!email || !password || password.length < 16 || secretIsExample(password)) {
        throw new Error('Acesso mestre exige e-mail e senha própria com pelo menos 16 caracteres.');
    }
    return { email, password };
}

export function databaseConfig(env: Environment) {
    const connectionString = env.DATABASE_URL?.trim();
    if (!connectionString) throw new Error('DATABASE_URL não foi configurada.');
    let url: URL;
    try {
        url = new URL(connectionString);
    } catch {
        throw new Error('DATABASE_URL inválida.');
    }
    if (!['postgres:', 'postgresql:'].includes(url.protocol) || !url.hostname || url.pathname === '/') {
        throw new Error('DATABASE_URL deve identificar um banco PostgreSQL.');
    }
    const privateHost = ['localhost', '127.0.0.1', '[::1]'].includes(url.hostname)
        || url.hostname.endsWith('.railway.internal');
    const sslEnabled = booleanEnv(env, 'DATABASE_SSL', env.NODE_ENV === 'production' && !privateHost);
    // Evita que parâmetros na URL sobrescrevam silenciosamente a política TLS do pg.
    if (['sslmode', 'sslcert', 'sslkey', 'sslrootcert'].some(key => url.searchParams.has(key))) {
        throw new Error('Configure SSL pelas variáveis DATABASE_SSL, não pelos parâmetros TLS da URL.');
    }
    return {
        connectionString,
        max: integerEnv(env, 'DB_POOL_MAX', 5, 100),
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: integerEnv(env, 'DB_CONNECT_TIMEOUT_MS', 5000, 60000),
        ssl: sslEnabled ? {
            rejectUnauthorized: booleanEnv(env, 'DATABASE_SSL_REJECT_UNAUTHORIZED', true),
            ...(env.DATABASE_SSL_CA ? { ca: env.DATABASE_SSL_CA.replace(/\\n/g, '\n') } : {}),
        } : false as const,
    };
}

export function storageDirectories(env: Environment, cwd = process.cwd()) {
    return {
        uploads: path.resolve(cwd, env.UPLOADS_DIR?.trim() || 'uploads'),
        downloads: path.resolve(cwd, env.DOWNLOADS_DIR?.trim() || 'downloads'),
    };
}

export function runtimeConfig(env: Environment) {
    const production = env.NODE_ENV === 'production';
    databaseConfig(env);
    const jwtSecret = env.JWT_SECRET ?? '';
    if (production && (jwtSecret.length < 32 || secretIsExample(jwtSecret))) {
        throw new Error('JWT_SECRET de produção exige uma chave própria com pelo menos 32 caracteres.');
    }
    masterCredentials(env);
    const publicUrl = env.API_PUBLIC_URL?.trim().replace(/\/$/, '');
    if (production) {
        let parsed: URL;
        try { parsed = new URL(publicUrl ?? ''); }
        catch { throw new Error('API_PUBLIC_URL deve ser uma URL HTTPS pública.'); }
        if (parsed.protocol !== 'https:' || parsed.username || parsed.password
            || ['localhost', '127.0.0.1', '[::1]'].includes(parsed.hostname)
            || parsed.pathname !== '/' || parsed.search || parsed.hash) {
            throw new Error('API_PUBLIC_URL deve ser uma URL HTTPS pública sem caminho ou credenciais.');
        }
    }
    const origins = env.CORS_ORIGIN?.trim().split(',').map(value => value.trim()).filter(Boolean) ?? [];
    if (production && (origins.length === 0 || origins.includes('*'))) {
        throw new Error('CORS_ORIGIN deve listar as origens permitidas em produção.');
    }
    for (const origin of origins) {
        if (origin === '*') continue;
        let parsed: URL;
        try { parsed = new URL(origin); }
        catch { throw new Error('CORS_ORIGIN contém uma origem inválida.'); }
        if (!['http:', 'https:'].includes(parsed.protocol) || parsed.origin !== origin) {
            throw new Error('CORS_ORIGIN deve conter origens sem caminho ou barra final.');
        }
    }
    const runMigrations = booleanEnv(env, 'RUN_MIGRATIONS_ON_START');
    const runSeeds = booleanEnv(env, 'RUN_SEEDS_ON_START');
    const importMenu = booleanEnv(env, 'IMPORT_MENU_ON_START');
    if (production && (runMigrations || runSeeds || importMenu)) {
        throw new Error('Produção exige migrations em pré-deploy e não permite seeds/importação automática.');
    }
    const httpsEnabled = booleanEnv(env, 'HTTPS_ENABLED',
        Boolean(env.TLS_KEY_PATH?.trim() && env.TLS_CERT_PATH?.trim()));
    if (env.RAILWAY_ENVIRONMENT_ID && httpsEnabled) {
        throw new Error('No Railway, use HTTPS_ENABLED=false; o HTTPS termina na plataforma.');
    }
    const directories = storageDirectories(env);
    if (env.RAILWAY_ENVIRONMENT_ID) {
        const volume = env.RAILWAY_VOLUME_MOUNT_PATH?.trim();
        if (!volume) throw new Error('O serviço Railway exige volume persistente para uploads e downloads.');
        for (const directory of Object.values(directories)) {
            const relative = path.relative(path.resolve(volume), directory);
            if (relative === '..' || relative.startsWith('..' + path.sep) || path.isAbsolute(relative)) {
                throw new Error('UPLOADS_DIR e DOWNLOADS_DIR devem estar dentro do volume Railway.');
            }
        }
    }
    return {
        production, publicUrl,
        host: env.HOST?.trim() || '0.0.0.0',
        port: integerEnv(env, 'PORT', 3001, 65535),
        origins: origins.length ? origins : ['*'],
        trustProxy: booleanEnv(env, 'TRUST_PROXY'),
        httpsEnabled, directories,
        runMigrations, runSeeds, importMenu,
        backgroundJobs: booleanEnv(env, 'BACKGROUND_JOBS_ENABLED', !production),
        cleanupDrafts: booleanEnv(env, 'DRAFT_CLEANUP_ENABLED', !production),
        databaseAttempts: integerEnv(env, 'DB_STARTUP_ATTEMPTS', 10, 60),
    };
}
