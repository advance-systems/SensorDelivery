import 'dotenv/config';

import express from 'express';
import cors from 'cors';
import { readFileSync } from 'node:fs';
import { createServer as createHttpsServer, type ServerOptions } from 'node:https';
import type { Server } from 'node:http';
import path from 'node:path';
import { setTimeout as delay } from 'node:timers/promises';

import { runtimeConfig } from './config/env.js';
import { database } from './database/connection.js';
import { executarMigrations } from './database/migrate.js';
import { executarSeeds } from './database/seed.js';
import { importarCardapioAnotaAi } from './scripts/importar-cardapio-anota-ai.js';
import { routes } from './routes/index.js';
import pedidosRoutes from './routes/pedidos.routes.js';
import lojaRoutes from './routes/loja.routes.js';
import { cancelarPixExpirados } from './services/pix-payment.service.js';
import { verificarEExcluirRascunhosPrimeiraExecucaoDoDia } from './services/pedidos-cleanup.service.js';
import { IFoodService } from './services/ifood.service.js';

const config = runtimeConfig(process.env);
const app = express();
let server: Server | undefined;
let monitor: ReturnType<typeof setInterval> | undefined;
let shuttingDown = false;
let monitorRunning = false;

app.use(cors({
    origin: config.origins.includes('*') ? '*' : config.origins,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Empresa-ID', 'Accept'],
    credentials: !config.origins.includes('*'),
}));
if (config.trustProxy) app.set('trust proxy', 1);
app.use(express.json({ limit: '2mb' }));

const uploadOptions = {
    maxAge: 0,
    setHeaders: (res: express.Response) => {
        res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    },
};
app.use('/uploads', express.static(config.directories.uploads, uploadOptions));
app.use('/api/uploads', express.static(config.directories.uploads, uploadOptions));
app.use('/downloads', express.static(config.directories.downloads, {
    fallthrough: false,
    setHeaders: (response, filePath) => {
        if (filePath.toLowerCase().endsWith('.apk')) {
            response.setHeader('Content-Disposition', `attachment; filename="${path.basename(filePath)}"`);
            response.setHeader('Content-Type', 'application/vnd.android.package-archive');
        }
    },
}));

app.use('/api', routes);
app.use('/api/pedidos', pedidosRoutes);
app.use('/api/loja', lojaRoutes);
app.use('/pedidos', pedidosRoutes);
app.use('/loja', lojaRoutes);

async function verificarBancoPreparado(): Promise<void> {
    const result = await database.query(
        "SELECT to_regclass('usuarios') AS usuarios, to_regclass('produtos') AS produtos, "
        + "to_regclass('pedidos') AS pedidos, to_regclass('loja_configuracao') AS loja",
    );
    if (!Object.values(result.rows[0] ?? {}).every(Boolean) || !result.rows[0]) {
        throw new Error('Banco sem estrutura necessária. Execute migrations e restaure os dados autorizados.');
    }
}

app.get('/health', async (_request, response) => {
    try {
        if (shuttingDown) throw new Error('Encerramento em andamento.');
        await verificarBancoPreparado();
        return response.json({
            status: 'online', sistema: 'Sensor Delivery', banco: 'conectado',
            horario: new Date().toISOString(),
        });
    } catch {
        return response.status(503).json({
            status: 'indisponivel', sistema: 'Sensor Delivery', banco: 'desconectado',
        });
    }
});

function carregarConfiguracaoHttps(): ServerOptions | null {
    if (!config.httpsEnabled) return null;
    const chave = process.env.TLS_KEY_PATH?.trim();
    const certificado = process.env.TLS_CERT_PATH?.trim();
    if (!chave || !certificado) {
        throw new Error('HTTPS exige TLS_KEY_PATH e TLS_CERT_PATH.');
    }
    const options: ServerOptions = {
        key: readFileSync(path.resolve(chave)), cert: readFileSync(path.resolve(certificado)),
    };
    if (process.env.TLS_CA_PATH?.trim()) options.ca = readFileSync(path.resolve(process.env.TLS_CA_PATH));
    if (process.env.TLS_KEY_PASSPHRASE) options.passphrase = process.env.TLS_KEY_PASSPHRASE;
    return options;
}

async function executarMonitor(): Promise<void> {
    if (monitorRunning || shuttingDown) return;
    monitorRunning = true;
    try {
        const tasks: Promise<unknown>[] = [];
        if (config.backgroundJobs) {
            tasks.push(cancelarPixExpirados(), IFoodService.executarPollingTodasLojas());
        }
        if (config.cleanupDrafts) tasks.push(verificarEExcluirRascunhosPrimeiraExecucaoDoDia());
        const results = await Promise.allSettled(tasks);
        results.forEach(result => {
            if (result.status === 'rejected') console.error('Falha em rotina automática.');
        });
    } finally {
        monitorRunning = false;
    }
}

async function iniciar(): Promise<void> {
    for (let attempt = 1; ; attempt++) {
        if (shuttingDown) return;
        try { await database.query('SELECT 1'); break; }
        catch {
            if (attempt >= config.databaseAttempts) throw new Error('PostgreSQL indisponível após as tentativas de conexão.');
            console.warn(`Aguardando PostgreSQL: tentativa ${attempt}/${config.databaseAttempts}.`);
            await delay(1000);
        }
    }
    if (shuttingDown) return;
    if (config.runMigrations) await executarMigrations();
    if (config.runSeeds) await executarSeeds();
    if (config.importMenu) {
        const result = await database.query('SELECT COUNT(*)::int AS total FROM produtos');
        if (result.rows[0]?.total === 0) await importarCardapioAnotaAi();
    }
    await verificarBancoPreparado();
    if (shuttingDown) return;
    const https = carregarConfiguracaoHttps();
    server = https ? createHttpsServer(https, app) : app.listen(config.port, config.host);
    if (https) server.listen(config.port, config.host);
    server.on('error', () => {
        console.error('Não foi possível manter o servidor HTTP ativo.');
        void shutdown(1);
    });
    server.once('listening', () => {
        console.log(`Sensor Delivery em ${config.publicUrl || `http://${config.host}:${config.port}`}`);
        if (config.backgroundJobs || config.cleanupDrafts) {
            monitor = setInterval(() => { void executarMonitor(); }, 15000);
        }
    });
}

async function shutdown(exitCode = 0): Promise<void> {
    if (shuttingDown) return;
    shuttingDown = true;
    if (monitor) clearInterval(monitor);
    const timeout = setTimeout(() => process.exit(1), 10000);
    timeout.unref();
    if (server?.listening) {
        await new Promise<void>(resolve => { server!.close(() => resolve()); });
    }
    await database.end();
    clearTimeout(timeout);
    process.exit(exitCode);
}

process.on('SIGINT', () => { void shutdown(); });
process.on('SIGTERM', () => { void shutdown(); });
void iniciar().catch(() => {
    console.error('Inicialização falhou. Verifique banco, migrations e configurações.');
    void shutdown(1);
});
