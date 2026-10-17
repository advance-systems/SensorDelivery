import assert from 'node:assert/strict';
import { test } from 'node:test';
import path from 'node:path';
import { once } from 'node:events';
import express from 'express';
import jwt from 'jsonwebtoken';
import { booleanEnv, databaseConfig, masterCredentials, runtimeConfig, storageDirectories } from '../src/config/env.ts';

function production(overrides = {}) {
    return {
        NODE_ENV: 'production',
        DATABASE_URL: 'postgresql://user:password@postgres.railway.internal:5432/railway',
        JWT_SECRET: 'a'.repeat(48),
        API_PUBLIC_URL: 'https://api.pizzaria.test',
        CORS_ORIGIN: 'https://cardapio.pizzaria.test',
        ...overrides,
    };
}

test('produção não modifica dados ao iniciar nem ativa rotinas do piloto', () => {
    const config = runtimeConfig(production());
    assert.equal(config.runMigrations, false);
    assert.equal(config.runSeeds, false);
    assert.equal(config.importMenu, false);
    assert.equal(config.backgroundJobs, false);
    assert.equal(config.cleanupDrafts, false);
    for (const flag of ['RUN_MIGRATIONS_ON_START', 'RUN_SEEDS_ON_START', 'IMPORT_MENU_ON_START']) {
        assert.throws(() => runtimeConfig(production({ [flag]: 'true' })));
    }
});

test('produção rejeita configurações inseguras e exemplos sem revelar valores', () => {
    for (const overrides of [
        { JWT_SECRET: 'short' }, { JWT_SECRET: 'troque-por-uma-chave-com-mais-de-trinta-e-dois' },
        { API_PUBLIC_URL: 'http://api.pizzaria.test' },
        { API_PUBLIC_URL: 'https://user:secret@api.pizzaria.test' },
        { API_PUBLIC_URL: 'https://api.pizzaria.test/api' },
        { CORS_ORIGIN: '*' }, { CORS_ORIGIN: '' },
        { CORS_ORIGIN: 'https://cardapio.pizzaria.test/path' },
        { PORT: '0' }, { PORT: '65536' }, { DB_POOL_MAX: '1.5' },
        { DATABASE_URL: 'mysql://user:password@host/database' },
    ]) assert.throws(() => runtimeConfig(production(overrides)));
    const sensitive = 'postgresql://user:private-password@';
    assert.throws(() => databaseConfig({ DATABASE_URL: sensitive }), error => !error.message.includes(sensitive));
    assert.throws(() => booleanEnv({ TEST: 'yes' }, 'TEST'));
});

test('pool distingue rede privada, TLS externo e mantém verificação do certificado', () => {
    assert.equal(databaseConfig(production()).ssl, false);
    assert.equal(databaseConfig(production()).max, 5);
    const external = production({ DATABASE_URL: 'postgresql://user:password@database.test:5432/store' });
    assert.equal(databaseConfig(external).ssl.rejectUnauthorized, true);
    assert.equal(databaseConfig({ ...external, DATABASE_SSL: 'false' }).ssl, false);
    assert.throws(() => databaseConfig({ ...external, DATABASE_SSL: 'false', DATABASE_URL: external.DATABASE_URL + '?sslmode=require' }));
    assert.throws(() => databaseConfig({ ...external, DATABASE_URL: external.DATABASE_URL + '?sslmode=require' }));
    assert.equal(databaseConfig({ ...external, DATABASE_SSL_CA: 'first\\nsecond' }).ssl.ca, 'first\nsecond');
});

test('uploads e downloads no Railway precisam estar dentro do volume', () => {
    const mount = path.resolve('test-volume');
    const env = production({
        RAILWAY_ENVIRONMENT_ID: 'pilot',
        RAILWAY_VOLUME_MOUNT_PATH: mount,
        UPLOADS_DIR: path.join(mount, 'uploads'),
        DOWNLOADS_DIR: path.join(mount, 'downloads'),
    });
    assert.equal(runtimeConfig(env).directories.uploads, path.join(mount, 'uploads'));
    assert.throws(() => runtimeConfig({ ...env, RAILWAY_VOLUME_MOUNT_PATH: '' }));
    assert.throws(() => runtimeConfig({ ...env, UPLOADS_DIR: path.resolve('outside-volume') }));
    assert.throws(() => runtimeConfig({ ...env, UPLOADS_DIR: path.join(mount + '-other', 'uploads') }));
    assert.throws(() => runtimeConfig({ ...env, HTTPS_ENABLED: 'true' }));
    assert.equal(storageDirectories({}, '/app').uploads, path.resolve('/app', 'uploads'));
});

test('mestre não possui fallback de credenciais e exige ativação explícita', () => {
    assert.equal(masterCredentials({}), null);
    assert.equal(masterCredentials({ ADMIN_MASTER_EMAIL: 'master@test', ADMIN_MASTER_SENHA: 'x'.repeat(32) }), null);
    assert.throws(() => masterCredentials({ ADMIN_MASTER_ENABLED: 'true' }));
    assert.throws(() => masterCredentials({
        ADMIN_MASTER_ENABLED: 'true', ADMIN_MASTER_EMAIL: 'master@test', ADMIN_MASTER_SENHA: 'short',
    }));
    assert.deepEqual(masterCredentials({
        ADMIN_MASTER_ENABLED: 'true', ADMIN_MASTER_EMAIL: 'MASTER@Test ', ADMIN_MASTER_SENHA: 'x'.repeat(32),
    }), { email: 'master@test', password: 'x'.repeat(32) });
});

test('rota de importação bloqueia visitantes e usuários sem permissão, sem consultar banco', async () => {
    // Todas as dependências da rota recebem uma URL inválida para conexão real.
    process.env.DATABASE_URL = 'postgresql://test:test@127.0.0.1:1/never_connect';
    process.env.DATABASE_SSL = 'false';
    process.env.JWT_SECRET = 'b'.repeat(48);
    process.env.ADMIN_MASTER_ENABLED = 'false';
    process.env.ALLOW_MENU_IMPORT = 'false';
    const { database } = await import('../src/database/connection.ts');
    const originalQuery = database.query;
    let databaseCalls = 0;
    database.query = async () => { databaseCalls++; throw new Error('Banco não pode ser consultado neste teste.'); };
    const { routes } = await import('../src/routes/index.ts');
    const app = express();
    app.use('/api', routes);
    const server = app.listen(0, '127.0.0.1');
    await once(server, 'listening');
    const url = 'http://127.0.0.1:' + server.address().port + '/api/importar-anota-ai';
    const token = tipo => jwt.sign({
        usuarioId: 'user', empresaId: 'company', tipo, permissoes: [],
    }, process.env.JWT_SECRET, {
        algorithm: 'HS256', issuer: 'sensor-delivery-server', audience: 'sensor-delivery-app',
    });
    try {
        assert.equal((await fetch(url, { method: 'POST' })).status, 401);
        assert.equal((await fetch(url, { method: 'POST', headers: { Authorization: 'Bearer ' + token('OPERADOR') } })).status, 403);
        assert.equal((await fetch(url, { method: 'POST', headers: { Authorization: 'Bearer ' + token('ADMIN') } })).status, 404);
        assert.equal((await fetch(url)).status, 404);
        assert.equal(databaseCalls, 0);
        process.env.DRAFT_CLEANUP_ENABLED = 'false';
        const { verificarEExcluirRascunhosPrimeiraExecucaoDoDia } = await import('../src/services/pedidos-cleanup.service.ts');
        assert.equal(await verificarEExcluirRascunhosPrimeiraExecucaoDoDia('company'), 0);
        assert.equal(databaseCalls, 0);
        const { AuthService } = await import('../src/modules/auth/auth.service.ts');
        await assert.rejects(
            new AuthService().selecionarEmpresa('00000000-0000-0000-0000-000000000001', 'company'),
            error => error.statusCode === 403,
        );
        assert.equal(databaseCalls, 0);
    } finally {
        server.closeAllConnections();
        await new Promise(resolve => server.close(resolve));
        database.query = originalQuery;
        await database.end();
    }
});

test('preparação local recusa host remoto e fixa destino e usuário de testes', async () => {
    const { localTestDatabaseUrl, TEST_DATABASE } = await import('../src/scripts/preparar-banco-teste.ts');
    const password = 'a'.repeat(64);
    const url = localTestDatabaseUrl('postgresql://admin:private@localhost:5432/SENSOR_DELIVERY', password);
    assert.equal(url.pathname, '/' + TEST_DATABASE);
    assert.equal(url.username, 'sensor_delivery_teste');
    assert.throws(() => localTestDatabaseUrl('postgresql://admin:private@remote.test:5432/railway', password));
    assert.throws(() => localTestDatabaseUrl('postgresql://admin:private@localhost:5432/source', 'invalid'));
});
