import { Router } from 'express';

import { authRoutes } from '../modules/auth/auth.routes.js';
import { profileRoutes } from '../modules/auth/profile.routes.js';
import { dashboardRoutes } from '../modules/dashboard/dashboard.routes.js';
import produtosRoutes from './produtos.routes.js';
import clientesRoutes from './clientes.routes.js';
import categoriasRoutes from './categorias.routes.js';
import saboresRoutes from './sabores.routes.js';
import adicionaisRoutes from './adicionais.routes.js';
import cardapioRoutes from './cardapio.routes.js';
import entregadoresRoutes from './entregadores.routes.js';
import combosRoutes from './combos.routes.js';
import empresasRoutes from './empresas.routes.js';
import uploadsRoutes from './uploads.routes.js';
import configuracoesRoutes from './configuracoes.routes.js';
import usuariosRoutes from './usuarios.routes.js';
import permissoesRoutes from './permissoes.routes.js';
import asaasWebhookRoutes from './asaas-webhook.routes.js';
import sicrediWebhookRoutes from './sicredi-webhook.routes.js';
import ifoodRoutes from './ifood.routes.js';
import { autenticarToken } from '../middleware/auth.middleware.js';
import {
    exigirAcessoEmpresas,
    exigirAcessoModulo,
    exigirUmaPermissao,
} from '../middleware/permission.middleware.js';

import { importarCardapioAnotaAi } from '../scripts/importar-cardapio-anota-ai.js';
import { database } from '../database/connection.js';

export const routes = Router();

routes.get('/importar-anota-ai', async (req, res) => {
    try {
        await importarCardapioAnotaAi();
        const totalCategorias = await database.query('SELECT COUNT(*)::int AS total FROM categorias');
        const totalProdutos = await database.query('SELECT COUNT(*)::int AS total FROM produtos');
        const totalSabores = await database.query('SELECT COUNT(*)::int AS total FROM sabores');
        const totalBordas = await database.query('SELECT COUNT(*)::int AS total FROM bordas');
        return res.json({
            status: 'sucesso',
            mensagem: 'Cardápio Anota Aí importado com sucesso!',
            resumo: {
                categorias: totalCategorias.rows[0]?.total,
                produtos: totalProdutos.rows[0]?.total,
                sabores: totalSabores.rows[0]?.total,
                bordas: totalBordas.rows[0]?.total
            }
        });
    } catch (error) {
        return res.status(500).json({
            status: 'erro',
            mensagem: error instanceof Error ? error.message : String(error)
        });
    }
});

routes.use('/ifood', ifoodRoutes);
routes.use('/auth', authRoutes);
routes.use('/auth', profileRoutes);
routes.use('/webhooks/asaas', asaasWebhookRoutes);
routes.use('/webhooks/sicredi', sicrediWebhookRoutes);
routes.use('/dashboard', dashboardRoutes);
routes.use('/produtos', produtosRoutes);
routes.use('/clientes', autenticarToken, exigirAcessoModulo('clientes'), clientesRoutes);
routes.use('/categorias', autenticarToken, exigirAcessoModulo('categorias'), categoriasRoutes);
routes.use('/sabores', autenticarToken, exigirAcessoModulo('sabores'), saboresRoutes);
routes.use('/adicionais', autenticarToken, exigirAcessoModulo('cardapio'), adicionaisRoutes);
routes.use('/cardapio', autenticarToken, exigirAcessoModulo('cardapio'), cardapioRoutes);
routes.use('/entregadores', autenticarToken, exigirAcessoModulo('entregadores'), entregadoresRoutes);
routes.use('/combos', autenticarToken, exigirAcessoModulo('combos'), combosRoutes);
routes.use('/empresas', autenticarToken, exigirAcessoEmpresas, empresasRoutes);
routes.use('/uploads', autenticarToken, exigirUmaPermissao([
    'cardapio.incluir', 'cardapio.alterar',
    'categorias.incluir', 'categorias.alterar',
    'sabores.incluir', 'sabores.alterar',
    'combos.incluir', 'combos.alterar',
    'empresas.incluir', 'empresas.alterar',
    'configuracoes.alterar',
]), uploadsRoutes);
routes.use('/configuracoes', autenticarToken, exigirAcessoModulo('configuracoes'), configuracoesRoutes);
routes.use('/usuarios', usuariosRoutes);
routes.use('/permissoes', permissoesRoutes);
