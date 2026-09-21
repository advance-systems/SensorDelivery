import 'dotenv/config';

import express from 'express';
import cors from 'cors';
import { readFileSync } from 'node:fs';
import { createServer as createHttpsServer, type ServerOptions } from 'node:https';
import path from 'node:path';

import { database } from './database/connection.js';
import { routes } from './routes/index.js';
import pedidosRoutes from './routes/pedidos.routes.js';
import lojaRoutes from './routes/loja.routes.js';
import { cancelarPixExpirados } from './services/pix-payment.service.js';

const app = express();
const port = Number(process.env.PORT ?? 3001);
const host = process.env.HOST?.trim() || '0.0.0.0';

const corsOrigin = process.env.CORS_ORIGIN?.trim();
const origensPermitidas = corsOrigin
    ? (corsOrigin.includes(',') ? corsOrigin.split(',').map(o => o.trim()) : corsOrigin)
    : '*';

app.use(
    cors({
        origin: origensPermitidas,
        methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
        allowedHeaders: ['Content-Type', 'Authorization', 'X-Empresa-ID', 'Accept'],
        credentials: true,
    })
);

function carregarConfiguracaoHttps(): ServerOptions | null {
    const chave = process.env.TLS_KEY_PATH?.trim();
    const certificado = process.env.TLS_CERT_PATH?.trim();
    const valorHttps = process.env.HTTPS_ENABLED?.trim().toLowerCase();
    const habilitado = valorHttps === 'true'
        || (!valorHttps && Boolean(chave && certificado));

    if (!habilitado) {
        return null;
    }
    if (!chave || !certificado) {
        throw new Error(
            'HTTPS habilitado, mas TLS_KEY_PATH e TLS_CERT_PATH não foram configurados.',
        );
    }

    const opcoes: ServerOptions = {
        key: readFileSync(path.resolve(process.cwd(), chave)),
        cert: readFileSync(path.resolve(process.cwd(), certificado)),
    };
    const cadeia = process.env.TLS_CA_PATH?.trim();
    const senha = process.env.TLS_KEY_PASSPHRASE;
    if (cadeia) {
        opcoes.ca = readFileSync(path.resolve(process.cwd(), cadeia));
    }
    if (senha) {
        opcoes.passphrase = senha;
    }
    return opcoes;
}

if (process.env.TRUST_PROXY?.trim().toLowerCase() === 'true') {
    app.set('trust proxy', 1);
}

app.use(
    express.json({
        limit: '2mb',
    }),
);

// Arquivos estáticos públicos (uploads de imagens e downloads de APK)
app.use('/uploads', express.static(path.resolve(process.cwd(), 'uploads')));
app.use('/api/uploads', express.static(path.resolve(process.cwd(), 'uploads')));
app.use(
    '/downloads',
    express.static(path.resolve(process.cwd(), 'downloads'), {
        fallthrough: false,
        setHeaders: (response, filePath) => {
            if (filePath.toLowerCase().endsWith('.apk')) {
                response.setHeader(
                    'Content-Disposition',
                    `attachment; filename="${path.basename(filePath)}"`,
                );
                response.setHeader(
                    'Content-Type',
                    'application/vnd.android.package-archive',
                );
            }
        },
    }),
);

app.use('/api', routes);
app.use('/api/pedidos', pedidosRoutes);
app.use('/api/loja', lojaRoutes);

// Suporte para requisições diretas sem prefixo /api
app.use('/pedidos', pedidosRoutes);
app.use('/loja', lojaRoutes);

app.get('/health', async (_request, response) => {
    try {
        await database.query('SELECT 1');

        return response.json({
            status: 'online',
            sistema: 'Sensor Delivery',
            banco: 'conectado',
            horario: new Date().toISOString(),
        });
    } catch (error) {
        console.error('Erro no health check:', error);

        return response.status(503).json({
            status: 'indisponivel',
            sistema: 'Sensor Delivery',
            banco: 'desconectado',
        });
    }
});

const configuracaoHttps = carregarConfiguracaoHttps();
const protocolo = configuracaoHttps ? 'https' : 'http';
const servidorBase = configuracaoHttps
    ? createHttpsServer(configuracaoHttps, app)
    : app;
const server = servidorBase.listen(port, host, () => {
    const publicUrl = process.env.API_PUBLIC_URL?.trim() ||
        `${protocolo}://${host}:${port}`;
    console.log(
        `Sensor Delivery em ${publicUrl}`,
    );
});

const monitorPix = setInterval(() => {
    cancelarPixExpirados().catch((error) => {
        console.error('Erro no monitor de pagamentos PIX:', error);
    });
}, 15000);
// O monitor permanece referenciado para também manter a API ativa em ambientes
// do Windows nos quais o listener HTTP não sustenta sozinho o event loop.

async function shutdown(): Promise<void> {
    console.log('Encerrando o Sensor Delivery...');

    clearInterval(monitorPix);

    server.close(async () => {
        await database.end();
        process.exit(0);
    });
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
