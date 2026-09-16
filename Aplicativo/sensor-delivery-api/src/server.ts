import 'dotenv/config';

import cors from 'cors';
import express from 'express';
import { readFileSync } from 'node:fs';
import { createServer as createHttpsServer, type ServerOptions } from 'node:https';
import path from 'node:path';

import {
    pool,
} from './database/pool.js';

import {
    pedidoRoutes,
} from './modules/pedidos/pedido.routes.js';


const app = express();


app.use(cors());

app.use(
    express.json({
        limit: '2mb',
    }),
);


app.get(
    '/',
    (_req, res) => {
        res.json({
            sucesso: true,
            mensagem:
                'Sensor Delivery API online.',
        });
    },
);


app.get(
    '/health',
    async (_req, res) => {
        try {
            const result = await pool.query(
                `
          SELECT
            CURRENT_TIMESTAMP AS agora
        `,
            );

            res.json({
                sucesso: true,
                banco: 'conectado',
                agora: result.rows[0].agora,
            });
        } catch (error) {
            console.error(
                'Erro ao testar o banco:',
                error,
            );

            res.status(500).json({
                sucesso: false,
                banco: 'desconectado',

                mensagem:
                    error instanceof Error
                        ? error.message
                        : 'Erro ao conectar com o banco.',
            });
        }
    },
);


app.use(
    '/pedidos',
    pedidoRoutes,
);


app.use(
    (_req, res) => {
        res.status(404).json({
            sucesso: false,
            mensagem:
                'Rota não encontrada.',
        });
    },
);


const port = Number(
    process.env.PORT ?? 3000,
);
const host = process.env.HOST?.trim() || '0.0.0.0';

function carregarConfiguracaoHttps(): ServerOptions | null {
    const chave = process.env.TLS_KEY_PATH?.trim();
    const certificado = process.env.TLS_CERT_PATH?.trim();
    const habilitado = process.env.HTTPS_ENABLED?.trim().toLowerCase() === 'true'
        || Boolean(chave || certificado);

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


const configuracaoHttps = carregarConfiguracaoHttps();
const protocolo = configuracaoHttps ? 'https' : 'http';
const servidorBase = configuracaoHttps
    ? createHttpsServer(configuracaoHttps, app)
    : app;

servidorBase.listen(
    port,
    host,
    () => {
        const publicUrl = process.env.API_PUBLIC_URL?.trim() ||
            `${protocolo}://${host}:${port}`;
        console.log(
            `Sensor Delivery API executando em ${publicUrl}`,
        );
    },
);
