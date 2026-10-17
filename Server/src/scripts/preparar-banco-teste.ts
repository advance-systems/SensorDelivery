import { randomBytes } from 'node:crypto';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { parse } from 'dotenv';
import pg from 'pg';

export const TEST_DATABASE = 'SENSOR_DELIVERY_TESTE';
const TEST_ROLE = 'sensor_delivery_teste';

export function localTestDatabaseUrl(source: string, password: string): URL {
    let url: URL;
    try { url = new URL(source); }
    catch { throw new Error('Configuração local PostgreSQL inválida.'); }
    if (!['postgres:', 'postgresql:'].includes(url.protocol)
        || !['localhost', '127.0.0.1', '[::1]'].includes(url.hostname)) {
        throw new Error('Preparação de testes aceita somente PostgreSQL local.');
    }
    if (!/^[a-f0-9]{64}$/.test(password)) throw new Error('Senha de testes inválida.');
    url.pathname = '/' + TEST_DATABASE;
    url.username = TEST_ROLE;
    url.password = password;
    url.search = '';
    return url;
}

export async function prepararBancoTeste(demo = false): Promise<void> {
    const directory = process.cwd();
    const envPath = path.resolve(directory, '.env.test');
    if (existsSync(envPath)) throw new Error('.env.test já existe; configuração preservada.');
    const localEnv = parse(readFileSync(path.resolve(directory, '.env')));
    const source = localEnv.DATABASE_URL;
    if (!source) throw new Error('DATABASE_URL local não configurada.');
    const password = randomBytes(32).toString('hex');
    const testUrl = localTestDatabaseUrl(source, password);
    const adminUrl = new URL(source);
    adminUrl.pathname = '/postgres';
    const admin = new pg.Client({ connectionString: adminUrl.toString(), ssl: false, connectionTimeoutMillis: 5000 });
    await admin.connect();
    try {
        const existing = await admin.query(
            'SELECT EXISTS(SELECT 1 FROM pg_database WHERE datname=$1) AS database, '
            + 'EXISTS(SELECT 1 FROM pg_roles WHERE rolname=$2) AS role',
            [TEST_DATABASE, TEST_ROLE],
        );
        if (existing.rows[0].database || existing.rows[0].role) {
            throw new Error('Banco ou usuário de testes já existe; nenhuma sobrescrita permitida.');
        }
        // Nomes fixos e senha hexadecimal gerada, nunca entrada livre.
        await admin.query(`CREATE ROLE ${TEST_ROLE} LOGIN PASSWORD '${password}' NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION`);
        await admin.query(`CREATE DATABASE "${TEST_DATABASE}" OWNER ${TEST_ROLE} ENCODING 'UTF8' TEMPLATE template0`);
        await admin.query(`REVOKE ALL ON DATABASE "${TEST_DATABASE}" FROM PUBLIC`);
        const contents = [
            '# Ambiente local de testes. Credenciais exclusivas; não versionar.',
            'DOTENV_CONFIG_PATH=.env.test', 'DOTENV_CONFIG_QUIET=true', 'TSX_DISABLE_CACHE=1',
            'NODE_ENV=test', 'HOST=0.0.0.0', 'PORT=3031',
            'DATABASE_URL=' + testUrl.toString(), 'DATABASE_SSL=false', 'DB_POOL_MAX=5',
            'JWT_SECRET=' + randomBytes(48).toString('hex'),
            'API_PUBLIC_URL=http://localhost:3031', 'HTTPS_ENABLED=false', 'TRUST_PROXY=false',
            'CORS_ORIGIN=http://localhost:3000,http://localhost:5173',
            'UPLOADS_DIR=uploads', 'DOWNLOADS_DIR=downloads',
            'RUN_MIGRATIONS_ON_START=false', 'RUN_SEEDS_ON_START=false',
            'IMPORT_MENU_ON_START=false', 'ALLOW_MENU_IMPORT=false',
            'BACKGROUND_JOBS_ENABLED=false', 'DRAFT_CLEANUP_ENABLED=false',
            'ADMIN_MASTER_ENABLED=false',
            '# Não inserir credenciais bancárias ou iFood de produção neste ambiente.',
            '',
        ].join('\n');
        writeFileSync(envPath, contents, { encoding: 'utf8', flag: 'wx', mode: 0o600 });
    } finally {
        await admin.end();
    }
    const check = new pg.Client({ connectionString: testUrl.toString(), ssl: false });
    await check.connect();
    try {
        const result = await check.query('SELECT current_database() AS name');
        if (result.rows[0].name !== TEST_DATABASE) throw new Error('Destino de testes não confirmado.');
    } finally { await check.end(); }
    if (demo) {
        process.env.DATABASE_URL = testUrl.toString();
        process.env.DATABASE_SSL = 'false';
        process.env.DOTENV_CONFIG_PATH = envPath;
        const { database } = await import('../database/connection.js');
        try {
            const { executarMigrations } = await import('../database/migrate.js');
            const { executarSeeds } = await import('../database/seed.js');
            await executarMigrations();
            await executarSeeds();
        } finally { await database.end(); }
    }
    console.log('Banco local ' + TEST_DATABASE + ' criado com usuário próprio.');
    console.log(demo ? 'Dados demonstrativos carregados.' : 'Banco vazio, reservado para restauração autorizada.');
    console.log('Configuração salva em .env.test; credenciais não exibidas.');
}

if (process.argv[1] && pathToFileURL(path.resolve(process.argv[1])).href === import.meta.url) {
    void prepararBancoTeste(process.argv.includes('--demo')).catch(error => {
        console.error(error instanceof Error ? error.message : 'Preparação local falhou.');
        process.exitCode = 1;
    });
}
